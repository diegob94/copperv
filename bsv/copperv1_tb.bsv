package copperv1_tb;

  import ClientServer :: *;
  import Connectable :: *;
  import FIFO :: *;

  import copperv1 :: *;
  import copperv1_pkg :: *;

  interface Mem_if;
    interface Server#(Bus_r_req,Bus_r_resp) bus_r;
    interface Server#(Bus_w_req,Bus_w_resp) bus_w;
  endinterface: Mem_if
  module mkMemory(Mem_if);
    FIFO#(Bus_r_req) bus_r_req <- mkFIFO;
    FIFO#(Bus_r_resp) bus_r_resp <- mkFIFO;

    rule receive;
      let req = bus_r_req.first; bus_r_req.deq;
      $display("memory: received:",req.addr);
      if(req.addr > 20) $finish;
    endrule

    rule send;
      bus_r_resp.enq(Bus_r_resp { data: 1313 });
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
