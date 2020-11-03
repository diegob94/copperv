package SRAM_wrapper;

  interface SRAM_Ifc #(type addr_t, type data_t);
    method Action request(addr_t addr, data_t data, Bool write_not_read);
    method data_t read_response();
  endinterface: SRAM_Ifc

  import "BVI" mkVerilog_SRAM_model =
    module mkSRAM_wrapper #(String filename) (SRAM_Ifc #(addr_t, data_t))
      provisos(Bits#(addr_t, addr_width),Bits#(data_t, data_width));
        parameter FILENAME      = filename;
        parameter ADDRESS_WIDTH = valueOf(addr_width);
        parameter DATA_WIDTH    = valueof(data_width);
        method request (v_in_address, v_in_data, v_in_write_not_read) enable (v_in_enable);
        method v_out_data read_response;
        default_clock clk(clk, (*unused*) clk_gate);
        default_reset no_reset;
        schedule (read_response) SB (request);
        schedule (request) C (request);
        schedule (read_response) CF (read_response);
  endmodule

endpackage: SRAM_wrapper
