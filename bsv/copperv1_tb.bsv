package copperv1_tb;

  import ClientServer :: *;
  import Connectable :: *;
  import FIFO :: *;
  import RegFile :: * ;

  import copperv1 :: *;
  import copperv1_pkg :: *;
  import SRAM_wrapper :: *;

  interface Mem_if;
    interface Server#(Bus_r_req,Bus_r_resp) bus_r;
//    interface Server#(Bus_w_req,Bus_w_resp) bus_w;
  endinterface: Mem_if

  (* synthesize *)
  module mkMemory(Mem_if);
    FIFO#(Bus_r_req) bus_r_req <- mkFIFO;
    FIFO#(Bus_r_resp) bus_r_resp <- mkFIFO;
    SRAM_Ifc#(UInt#(16), Data_t) mem <- mkSRAM_wrapper(`HEX_FILE);
    Reg#(Bool) pending <- mkReg(False);

    rule read_mem;
      let req = bus_r_req.first; bus_r_req.deq;
      mem.request(truncate(req.addr>>2), 0, False);
      pending <= True;
    endrule

    rule send_response (pending);
      let word = mem.read_response;
      bus_r_resp.enq(Bus_r_resp { data: word });
      pending <= False;
    endrule

    interface Server bus_r = toGPServer(asIfc(bus_r_req), asIfc(bus_r_resp));
  endmodule: mkMemory

  (* synthesize *)
  module mkCopperv1Tb (Empty);
    Copperv1_if cpu <- mkCopperv1;
    Mem_if mem <- mkMemory;
    mkConnection(cpu.bus_ir,mem.bus_r);
  endmodule: mkCopperv1Tb

endpackage: copperv1_tb
