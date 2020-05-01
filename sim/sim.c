function control_state;
input [2-1:0] s;
begin
    case (s)
        `CPU_INST.control.FETCH_S:
            control_state = "FETCH";
        `CPU_INST.control.LOAD_S:
            control_state = "LOAD";
        `CPU_INST.control.EXEC_S:
            control_state = "EXEC";
        `CPU_INST.control.MEM_S:
            control_state = "MEM";
    endcase
end
endfunction
