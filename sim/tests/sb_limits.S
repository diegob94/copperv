
    li t3, 0xFF13       # Data
    li t2, 0x13         # Data LS Byte
    li t4, 1000         # Address
    sw zero, -1(t4)     # Clear address boundary
    sw zero, 0(t4)
    sw zero, 1(t4)
    sb t3, 0(t4)        # Do Store
    lb t5, -4(t4)       # Check boundary
    bne t5, zero, fail
    lb t5, -3(t4)
    bne t5, zero, fail
    lb t5, -2(t4)
    bne t5, zero, fail
    lb t5, -1(t4)
    bne t5, zero, fail
    lb t5, 0(t4)        # Check sb address
    bne t5, t2, fail
    lb t5, 1(t4)        # Continue check boundary
    bne t5, zero, fail
    lb t5, 2(t4)
    bne t5, zero, fail
    lb t5, 3(t4)
    bne t5, zero, fail
    lb t5, 4(t4)
    bne t5, zero, fail
pass:
    li t1, 123456789 # Test passed code
    li t2, 33        # Test result address
    sw t1, 0(t2)     # Output test result
    j loop
fail:
    li t1, 111111111 # Test failed code
    li t2, 33        # Test result address
    sw t1, 0(t2)     # Output test result
loop:
    j loop

