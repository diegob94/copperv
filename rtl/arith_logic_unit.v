module arith_logic_unit #(
    parameter data_width = 32,
    parameter funct_width = 4
) (
    input [data_width-1:0] alu_din1,
    input [data_width-1:0] alu_din2,
    input [funct_width-1:0] funct,
    output [data_width-1:0] alu_dout
);
parameter ADD = 0;
reg [data_width-1:0] alu_dout;
always @(*) begin
    case (funct)
        ADD: alu_dout = alu_din1 + alu_din2;
    endcase
end
endmodule
