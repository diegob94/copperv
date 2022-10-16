reg f_past_valid = 0;
always @(posedge clock) begin
    f_past_valid <= 1;
end

`ifdef COVER_WB_SRAM
    integer i;
    initial
        for(i = 0; i < length; i = i + 1)
            mem[i] = 0;
`endif

(* anyconst *) wire [31:0] f_const_addr;
reg [31:0] f_mem_value;
reg [31:0] f_mem_mask;

initial
    assume(f_mem_value == mem[f_const_addr]);
always @(*)
    assert(mem[f_const_addr] == f_mem_value);

always @(posedge clock) begin
    // Handle writes
    if(en && wen && addr == f_const_addr) begin
        f_mem_mask = {{8{wmask[3]}},{8{wmask[2]}},{8{wmask[1]}},{8{wmask[0]}}};
        f_mem_value = din & f_mem_mask;
    end
    // Handle reads
    if(f_past_valid && $past(en) && !$past(wen) && $past(addr == f_const_addr)) begin
        assert((dout & f_mem_mask) == f_mem_value);
    end
end

