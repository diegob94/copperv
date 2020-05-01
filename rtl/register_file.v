module register_file #(
    parameter reg_width = 5,
    parameter reg_length = 2**reg_width,
    parameter data_width = 32
) (
    input clk,
    input rd_en,
    input rs1_en,
    input rs2_en,
    input [reg_width-1:0] rd,
    input [reg_width-1:0] rs1,
    input [reg_width-1:0] rs2,
    input [data_width-1:0] rd_din,
    output [data_width-1:0] rs1_dout,
    output [data_width-1:0] rs2_dout
);
reg [data_width-1:0] rs1_dout;
reg [data_width-1:0] rs2_dout;
reg [data_width-1:0] memory [reg_length-1:0];
always @(posedge clk) begin
    if(rd_en) begin
        memory[rd] <= rd_din;
    end else if(rs1_en && rs2_en) begin
        rs1_dout <= rs1 == 0 ? 0 : memory[rs1];
        rs2_dout <= rs2 == 0 ? 0 : memory[rs2];
    end else if(rs1_en) begin
        rs1_dout <= rs1 == 0 ? 0 : memory[rs1];
    end 
end
endmodule
