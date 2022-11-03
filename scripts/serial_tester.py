import sys
from pathlib import Path
sim_dir = (Path(__file__).parent.parent/'sim').resolve()
sys.path.append(str(sim_dir))
import serial
import cocotb_utils as utils
from cocotb_tests import VirtualMemory

def end_test():
    global test_passed
    test_passed = True

test_passed = False
test_name = 'bootloader_test'
utils.run('make',cwd=sim_dir/f'tests/{test_name}')
elf_path = sim_dir/f'tests/{test_name}/{test_name}.elf'
memory_callback = VirtualMemory(elf_path,end_test)

print(memory_callback)
print("Press button B1 to reset")

def receive(ser,count=4):
    data = ser.read(count)
    print("Read bytes:",data)
    data = int.from_bytes(data, byteorder='little', signed=False)
    return data

def send(ser,data,count=4):
    data = data.to_bytes(length=count,byteorder="little")
    print("Send bytes:",data,"",end="")
    count = ser.write(data)
    ser.flush()
    print(count)

with serial.Serial('/dev/ttyUSB0', 115200) as ser:
    while True:
        print("Waiting op")
        op = receive(ser,1)
        address = receive(ser)
        data = None
        sel = None
        if op == 1:
            data = receive(ser)
            sel = receive(ser,1)
        resp = memory_callback(op,address,data,sel)
        info = f"transaction: address = 0x{address:X}"
        if op == 1:
            info = "Write " + info + f" data = 0x{data:X} sel = 0x{sel:X}"
        else:
            info = "Read " + info
        info = info + f" resp = 0x{resp:X}"
        print(info)
        if test_passed:
            print("Test PASSED")
            sys.exit(0)
        send(ser,resp,4 if op == 0 else 1)


