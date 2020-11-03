module mkVerilog_SRAM_model (
        clk,
        v_in_address, 
        v_in_data,
        v_in_write_not_read,
        v_in_enable,
        v_out_data
    );
    parameter FILENAME      = "Verilog_SRAM_model.hex";
    parameter ADDRESS_WIDTH = 10;
    parameter DATA_WIDTH    = 8;
    parameter NWORDS        = (1 << ADDRESS_WIDTH);
    input                       clk;
    input  [ADDRESS_WIDTH-1:0]  v_in_address;
    input  [DATA_WIDTH-1:0]     v_in_data;
    input                       v_in_write_not_read;
    input                       v_in_enable;
    output [DATA_WIDTH-1:0]     v_out_data;
    reg [DATA_WIDTH-1:0] mem [NWORDS-1:0];
    reg [DATA_WIDTH-1:0] out_buf;
    assign v_out_data = out_buf;

    `ifdef BSV_NO_INITIAL_BLOCKS
    `else // not BSV_NO_INITIAL_BLOCKS
       // synopsys translate_off
       initial
           $readmemh(FILENAME, mem, 0, NWORDS - 1);
       // synopsys translate_on
    `endif // BSV_NO_INITIAL_BLOCKS
    
    always @(posedge clk) begin
        if(v_in_enable) begin
            mem[v_in_address] <= v_in_data;
        end
    end
    
    always @(posedge clk) begin
        if(!v_in_write_not_read) begin
            out_buf <= mem[v_in_address];
        end
    end

endmodule
