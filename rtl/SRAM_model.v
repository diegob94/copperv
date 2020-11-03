module SRAM_model (
        CLK,
        ADDR, 
        DIN,
        EN,
        WEN,
        DOUT
    );
    parameter FILENAME      = "Verilog_SRAM_model.hex";
    parameter ADDRESS_WIDTH = 10;
    parameter DATA_WIDTH    = 8;
    parameter NWORDS        = (1 << ADDRESS_WIDTH);
    input                       CLK;
    input  [ADDRESS_WIDTH-1:0]  ADDR;
    input  [DATA_WIDTH-1:0]     DIN;
    input                       EN;
    input                       WEN;
    output [DATA_WIDTH-1:0]     DOUT;
    reg [DATA_WIDTH-1:0] mem [NWORDS-1:0];
    reg [DATA_WIDTH-1:0] out_buf;
    assign DOUT = out_buf;

    `ifdef BSV_NO_INITIAL_BLOCKS
    `else // not BSV_NO_INITIAL_BLOCKS
       // synopsys translate_off
       initial
           $readmemh(FILENAME, mem, 0, NWORDS - 1);
       // synopsys translate_on
    `endif // BSV_NO_INITIAL_BLOCKS
    
    always @(posedge CLK) begin
        if(EN && WEN) begin
            mem[ADDR] <= DIN;
        end
    end
    
    always @(posedge CLK) begin
        if(EN && !WEN) begin
            out_buf <= mem[ADDR];
        end
    end

endmodule
