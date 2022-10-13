import sys
sys.path.append("sim")
import serial
import cocotb_utils as utils
from riscv_utils import process_elf

T_ADDR = 0x80000000
O_ADDR = 0x80000004
TC_ADDR = 0x80000008
T_PASS = 0x01000001
T_FAIL = 0x02000001

test_passed = False
test = "wb2uart_test"
utils.run('make',cwd=f'sim/tests/{test}')
imem,dmem = process_elf(f'sim/tests/{test}/{test}.elf')
memory = {**imem,**dmem}

print("Virtual memory size [bytes]:",len(memory))
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

def resp_callback(op,address,data,sel):
    global test_passed
    if op == 0:
        return utils.from_array(memory,address)
    elif op == 1:
        if address == T_ADDR:
            assert data == T_PASS, "Received test fail from bus"
            test_passed = True
            return 1
        else:
            mask = f"{sel:04b}"
            for i in range(4):
                if int(mask[3-i]):
                    memory[address+i] = utils.to_bytes(data)[i]
            return 1

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
        resp = resp_callback(op,address,data,sel)
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


