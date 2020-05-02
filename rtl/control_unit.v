`timescale 1ns/1ps
`include "copperv_h.v"

module control_unit ( 
    input clk,
    input rst,
    input [`INST_TYPE_WIDTH-1:0] inst_type,
    output inst_fetch,
    output rd_en,
    output rs1_en,
    output rs2_en,
    output [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel
);
reg [`STATE_WIDTH-1:0] state;
reg [`STATE_WIDTH-1:0] state_next;
reg inst_fetch;
reg rd_en;
reg rs1_en;
reg rs2_en;
reg [`RD_DIN_SEL_WIDTH-1:0] rd_din_sel;
always @(posedge clk) begin
    if(!rst)
        state <= `FETCH_S;
    else
        state <= state_next;
end
// Next state logic
always @(*) begin
    state_next = `FETCH_S;
    case (state)
        `FETCH_S: begin
            state_next = `LOAD_S;
        end
        `LOAD_S: begin
        end
        `EXEC_S: begin
        end
        `MEM_S: begin
        end
    endcase
end
// Output logic
always @(*) begin
    inst_fetch = 0;
    rd_en = 0;
    rs1_en = 0;
    rs2_en = 0;
    case (state)
        `FETCH_S: begin
            inst_fetch = 1;
        end
        `LOAD_S: begin
            case (inst_type)
                `INST_TYPE_IMM: begin
                    rd_en = 1;
                    rd_din_sel = `RD_DIN_SEL_IMM;
                end
                `INST_TYPE_INT_IMM: begin
                    rs1_en = 1;
                end
            endcase
        end
        `EXEC_S: begin
        end
        `MEM_S: begin
        end
    endcase
end
endmodule
