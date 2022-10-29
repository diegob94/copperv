from pathlib import Path

from cocotb_bus.monitors import Monitor
from cocotb.log import SimLog
from elftools.elf.elffile import ELFFile

from regfile import RegFileWriteTransaction
from bus import BusWriteTransaction, BusReadTransaction
from cocotb_utils import run, to_bytes
from cocotb.triggers import Edge
from elftools.elf.elffile import ELFFile

sim_dir = Path(__file__).resolve().parent
linker_script = sim_dir/'tests/common/linker.ld'

def read_elf(test_elf,sections=['.text']):
    test_elf = Path(test_elf)
    log = SimLog(__name__+'.read_elf')
    with test_elf.open('rb') as file:
        elffile = ELFFile(file)
        elf = {}
        for spec in sections:
            section = elffile.get_section_by_name(spec)
            log.debug('read_elf %s spec: %s',test_elf,spec)
            if section is not None:
                elf[spec] = dict(
                    addr = section['sh_addr'],
                    data = section.data(),
                )
    #log.debug(f"elf: {elf}")
    return elf

def elf_to_memory(elf):
    instruction_memory = {}
    for elf_section in elf.values():
        section_start = elf_section['addr']
        section_data = elf_section['data']
        section_size = len(section_data)
        for addr in range(section_size):
            instruction_memory[section_start+addr] = section_data[addr]
    return instruction_memory

def compile_test(instructions):
    log = SimLog(__name__+".compile_test")
    test_s = Path('test').with_suffix('.S')
    test_elf = Path('test').with_suffix('.elf')
    test_s.write_text('\n'.join(crt0 + instructions) + '\n')
    cmd = f"riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -Wl,-T,{linker_script},-Bstatic -nostartfiles -ffreestanding -g {test_s} -o {test_elf}"
    run(cmd)
    elf = read_elf(test_elf)
    return elf

def compile_riscv_test(asm_path):
    log = SimLog(__name__+".compile_riscv_test")
    test_s = asm_path
    crt0_s = sim_dir/'tests/common/crt0.S'
    crt0_obj = Path(crt0_s.name).with_suffix('.o')
    test_obj = Path(test_s.name).with_suffix('.o')
    test_elf = Path(test_s.name).with_suffix('.elf')
    common_dir = sim_dir/'tests/common'
    macros_dir = sim_dir/'tests/isa/macros/scalar'
    cmd_crt0 = f"riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -I{common_dir} -I{macros_dir} -g -DENTRY_POINT={test_s.stem} -c {crt0_s} -o {crt0_obj}"
    cmd_test = f"riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -I{common_dir} -I{macros_dir} -g -DTEST_NAME={test_s.stem} -c {test_s} -o {test_obj}"
    cmd_link = f"riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -I{common_dir} -I{macros_dir} -Wl,-T,{linker_script},-Bstatic -nostartfiles -ffreestanding -g {crt0_obj} {test_obj} -o {test_elf}" 
    run(cmd_crt0)
    run(cmd_test)
    run(cmd_link)
    return process_elf(test_elf)

def process_elf(test_elf):
    log = SimLog(__name__+".process_elf")
    i_elf = read_elf(test_elf,
        sections=['.init','.text'])
    d_elf = read_elf(test_elf,
        sections=['.data','.rodata'])
    instruction_memory = elf_to_memory(i_elf)
    data_memory = elf_to_memory(d_elf)
    return instruction_memory,data_memory

crt0 = [
    ".global _start",
    "_start:",
]

def compile_instructions(instructions):
    elf = compile_test(instructions)
    instruction_memory = elf_to_memory(elf)
    return instruction_memory

def parse_data_memory(params_data_memory):
    data_memory = {}
    for t in params_data_memory:
        t = BusReadTransaction.from_string(t)
        for i in range(4):
            data_memory[t.addr+i] = to_bytes(t.data)[i]
    return data_memory

class StackMonitor:
    def __init__(self,regfile_write_monitor: Monitor, pc_monitor: Monitor, elf_path = None):
        self.log = SimLog('cocotb.'+__name__+'.'+self.__class__.__name__)
        regfile_write_monitor.add_callback(self.regfile_callback)
        pc_monitor.add_callback(self.pc_callback)
        self.stack_pointer = None
        self.skip = 2
        self.stack = []
        self.direction = 'in'
        self.pc = None
        self.symbols = None
        if elf_path is not None:
            with Path(elf_path).open('rb') as file:
                elffile = ELFFile(file)
                self.symbols = [(symbol.name,symbol.entry['st_value'],symbol.entry['st_info']['type']) for symbol in elffile.get_section_by_name(".symtab").iter_symbols()]
    def get_symbol_name(self,addr):
        addr = f'0x{addr:X}'
        if self.symbols is not None:
            name = [row[0] for row in self.symbols if row[1] == int(addr,0) and row[2] == 'STT_FUNC'][0]
            return f"{addr}({name})"
        return addr
    def stack_push(self,new):
        if len(self.stack) == 0 or new != self.stack[-1]:
            self.log.debug('Stack push: [%s] %s',self.stack_string(),self.get_symbol_name(new))
            self.stack.append(new)
    def stack_pop(self):
        old = self.stack.pop()
        self.log.debug('Stack pop:  [%s] %s',self.stack_string(),self.get_symbol_name(old))
    def stack_string(self):
        return ', '.join([self.get_symbol_name(i) for i in self.stack])
    def pc_callback(self, value: int):
        self.pc = value
    def regfile_callback(self,transaction: RegFileWriteTransaction):
        if transaction.reg_name == 'sp':
            if self.skip > 0:
                self.skip -= 1
            else:
                if self.stack_pointer is not None:
                    self.direction = 'in' if self.stack_pointer > transaction.data else 'out'
                #self.log.debug('stackmonitor regfile %s %s',transaction,self.direction)
                self.stack_pointer = transaction.data
                if self.direction == 'out':
                    self.stack_pop()
                elif self.direction == 'in':
                    self.stack_push(self.pc)

class PcMonitor(Monitor):
    def __init__(self,name,pc,callback=None,event=None):
        self.name = name
        self.log = SimLog(f"cocotb.{self.name}")
        self.pc = pc
        super().__init__(callback=callback,event=event)
    async def _monitor_recv(self):
        while True:
            await Edge(self.pc)
            value = int(self.pc.value)
            self.log.debug("Recv: 0x%X", value)
            self._recv(value)

