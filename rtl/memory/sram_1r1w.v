module sram_1r1w #(
    parameter data_width = 32, // fixed
    parameter addr_width = 8, // dynamic
    parameter mask_width = data_width/8 // fixed
) (
    input                       clock,
    input                       wen,
    input                       en,
    input      [mask_width-1:0] wmask,
    input      [addr_width-1:0] addr,
    input      [data_width-1:0] din,
    output reg [data_width-1:0] dout
);
    parameter length = 1 << addr_width;
    parameter byte_length = length * 4;

    reg [8-1:0] temp_mem [byte_length-1:0];

    `ifndef SYNTHESIS
        reg [1023:0] hex_file;
        initial begin
            if ($value$plusargs("HEX_FILE=%s", hex_file)) begin
                $display("%t: %m byte_length: %0d", $time, byte_length);
                $readmemh(hex_file, temp_mem, 0, byte_length - 1);
                for(integer i = 0; i < length; i = i + 1)
                    mem[i] = {
                        temp_mem[i+3],
                        temp_mem[i+2],
                        temp_mem[i+1],
                        temp_mem[i+0]
                    };
            end
        end
    `endif

    `ifdef FORMAL
        `include "formal/sram_1r1w.v"
    `endif

    reg [data_width-1:0] mem [length-1:0];

    always @(posedge clock)
        if(en && wen) begin
            if(wmask[0])
                mem[addr][7:0] <= din[7:0];
            if(wmask[1])
                mem[addr][15:8] <= din[15:8];
            if(wmask[2])
                mem[addr][23:16] <= din[23:16];
            if(wmask[3])
                mem[addr][31:24] <= din[31:24];
        end

    always @(posedge clock)
        if(en && !wen)
            dout <= mem[addr];

endmodule
