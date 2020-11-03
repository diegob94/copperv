package copperv1;
  import ClientServer :: *;
  import GetPut :: *;
  import FIFO :: *;

  import copperv1_pkg :: *;
  
  interface Copperv1_if;
    interface Client#(Bus_r_req,Bus_r_resp) bus_ir;
    interface Client#(Bus_w_req,Bus_w_resp) bus_iw;
    interface Client#(Bus_r_req,Bus_r_resp) bus_dr;
    interface Client#(Bus_w_req,Bus_w_resp) bus_dw;
  endinterface: Copperv1_if

  (* synthesize *)
  module mkCopperv1(Copperv1_if);
    FIFO#(Bus_r_req) bus_ir_req <- mkFIFO;
    FIFO#(Bus_r_resp) bus_ir_resp <- mkFIFO;
    Reg#(Addr_t) pc <- mkReg(0);

    rule incr_pc;
      pc <= pc + 4;
    endrule

    rule fetch;
      bus_ir_req.enq(Bus_r_req {addr: pc});
    endrule
    rule receive;
      let rec = bus_ir_resp.first; bus_ir_resp.deq;
      $display("copperv1: received:",rec);
    endrule

    interface Client bus_ir = toGPClient(asIfc(bus_ir_req), asIfc(bus_ir_resp));
  endmodule: mkCopperv1

endpackage: copperv1
