module control_unit #(
    parameter rd_din_sel_width = 1
) (
    input clk,
    input rst,
    output inst_fetch,
    output rd_en,
    output rs1_en,
    output rs2_en,
    output [rd_din_sel_width-1:0] rd_din_sel
);
parameter state_width = 2;
parameter FETCH_S = 0;
parameter LOAD_S = 1;
parameter EXEC_S = 2;
parameter MEM_S = 3;
reg [state_width-1:0] state;
reg [state_width-1:0] state_next;
reg inst_fetch;
reg rd_en;
reg rs1_en;
reg rs2_en;
reg [rd_din_sel_width-1:0] rd_din_sel;
always @(posedge clk) begin
    if(!rst)
        state <= FETCH_S;
    else
        state <= state_next;
end
// Next state logic
always @(*) begin
    state_next = FETCH_S;
    case (state)
        FETCH_S: begin
            state_next = LOAD_S;
        end
        LOAD_S: begin
        end
        EXEC_S: begin
        end
        MEM_S: begin
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
        FETCH_S: begin
            inst_fetch = 1;
        end
        LOAD_S: begin
            if(type_imm) begin
                rd_en = 1;
                rd_din_sel = copperv.RD_DIN_SEL_IMM;
            end else if(type_int_imm) begin
                rs1_en = 1;
                rd_en = rd_valid;
            end
        end
        EXEC_S: begin
        end
        MEM_S: begin
        end
    endcase
end
endmodule
