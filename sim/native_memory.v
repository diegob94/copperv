module native_memory #(
    parameter address_width = 8,
    parameter length = (2**address_width),
    parameter bus_width = 32,
    parameter instruction_memory = 0
) (
    input clk,
    input rst,
    output rdata_valid,
    input raddr_ready,
    output wdata_ready,
    output waddr_ready,
    output [bus_width-1:0] rdata,
    input rdata_ready,
    output raddr_valid,
    input wdata_valid,
    input waddr_valid,
    input [bus_width-1:0] raddr,
    input [bus_width-1:0] wdata,
    input [bus_width-1:0] waddr
);
reg [7:0] memory [length - 1:0];
`STRING fw_file;
initial begin
    $display("%t: %m memory length: %0d", $time, length);
    if (instruction_memory == `TRUE) begin
        if ($value$plusargs("FW_FILE=%s", fw_file)) begin
            $readmemh(fw_file, memory, 0, length - 1);
        end else begin
            $display("%t: Error: No firmware given. Example: vvp sim.vvp +FW_FILE=fw.hex", $time);
            $finish;
        end
    end
end
endmodule
