
function `STRING reg_name;
input [`REG_WIDTH-1:0] arg;
begin
    case (arg)
        5'd0:
            reg_name = "zero";
        5'd1:
            reg_name = "ra";
        5'd2:
            reg_name = "sp";
        5'd3:
            reg_name = "gp";
        5'd4:
            reg_name = "tp";
        5'd5:
            reg_name = "t0";
        5'd6:
            reg_name = "t1";
        5'd7:
            reg_name = "t2";
        5'd8:
            reg_name = "s0/fp";
        5'd9:
            reg_name = "s1";
        5'd10:
            reg_name = "a0";
        5'd11:
            reg_name = "a1";
        5'd12:
            reg_name = "a2";
        5'd13:
            reg_name = "a3";
        5'd14:
            reg_name = "a4";
        5'd15:
            reg_name = "a5";
        5'd16:
            reg_name = "a6";
        5'd17:
            reg_name = "a7";
        5'd18:
            reg_name = "s2";
        5'd19:
            reg_name = "s3";
        5'd20:
            reg_name = "s4";
        5'd21:
            reg_name = "s5";
        5'd22:
            reg_name = "s6";
        5'd23:
            reg_name = "s7";
        5'd24:
            reg_name = "s8";
        5'd25:
            reg_name = "s9";
        5'd26:
            reg_name = "s10";
        5'd27:
            reg_name = "s11";
        5'd28:
            reg_name = "t3";
        5'd29:
            reg_name = "t4";
        5'd30:
            reg_name = "t5";
        5'd31:
            reg_name = "t6";
        default:
            reg_name = "UNKNOWN";
    endcase
end
endfunction

