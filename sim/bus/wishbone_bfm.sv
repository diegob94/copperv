interface wishbone_bfm(
    input clk,
    input rst
  );

  parameter adr_width = 8;
  parameter dat_width = 8;
  parameter sel_width = 8;
  parameter name = "UNKNOWN";
  
  typedef bit [adr_width-1:0] adr_t;
  typedef bit [dat_width-1:0] dat_t;
  typedef bit [sel_width-1:0] sel_t;
  
  adr_t adr;
  dat_t datwr;
  dat_t datrd;
  sel_t sel;
  bit   we;
  bit   stb;
  bit   ack;
  bit   cyc;

  task wait_read_adr(output adr_t read_adr);
    do begin
      @(negedge clk);
    end while (!stb);
    $display("%t: %s: receive addr 0x%X",$time,name,adr);
    read_adr = adr;
  endtask : wait_read_adr

  task send_read_dat(input dat_t read_dat);
    @(negedge clk)
    $display("%t: %s: sending data 0x%X",$time,name,read_dat);
    datrd = read_dat;
    ack = 1;
    @(negedge clk)
    ack = 0;
  endtask : send_read_dat
  
endinterface : wishbone_bfm
