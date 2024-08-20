interface wishbone_bfm (
    input clk,
    input rst,
    wishbone_if vif
  );
  parameter adr_width = vif.adr_width;
  parameter dat_width = vif.dat_width;
  typedef logic [adr_width-1:0] adr_td;
  typedef logic [dat_width-1:0] dat_td;

  task wait_read_adr(output adr_td read_adr);
    do begin
      @(negedge clk);
    end while (!vif.stb);
    $display("%t: %m: receive addr 0x%X",$time,vif.adr);
    read_adr = vif.adr;
  endtask : wait_read_adr

  task send_read_dat(input dat_td read_dat);
    @(negedge clk)
    $display("%t: %m: sending data 0x%X",$time,read_dat);
    vif.datrd = read_dat;
    vif.ack = 1;
    @(negedge clk)
    vif.ack = 0;
  endtask : send_read_dat
  
endinterface : wishbone_bfm
