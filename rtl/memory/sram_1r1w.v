module sram_1r1w #(
    parameter data_width = 32, // fixed
    parameter addr_width = 8, // dynamic
    parameter mask_width = data_width/8 // fixed
) (
    input                    clock,
    input                    wen,
    input                    en,
    input  [mask_width-1:0]  wmask,
    input  [addr_width-1:0]  addr,
    input  [data_width-1:0]  din,
    output [data_width-1:0]  dout
);
    parameter length = 1 << addr_width;

    `ifdef FORMAL
        `include "formal/sram_32_sp.v"
    `endif

    reg [data_width-1:0] mem [length-1:0];
    reg [data_width-1:0] dout;

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
