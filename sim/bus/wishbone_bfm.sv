interface wishbone_bfm(
    input clk,
    input rst
  );

  parameter adr_width = 8;
  parameter dat_width = 8;
  parameter sel_width = 8;
  
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
      $display("wishbone_bfm.wait_read_adr: waiting for address");
      @(negedge clk);
    end while (!stb);
    $display("wishbone_bfm.wait_read_adr: received address 0x%X",adr);
    read_adr = adr;
  endtask : wait_read_adr

  task send_read_dat(input dat_t read_dat);
    @(negedge clk)
    datrd = read_dat;
    ack = 1;
    @(negedge clk)
    ack = 0;
  endtask : send_read_dat
  
endinterface : wishbone_bfm
