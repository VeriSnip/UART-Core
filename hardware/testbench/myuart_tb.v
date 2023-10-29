/*
UART testbench
*/
`include "timescale.vs"

module myuart_tb;

  parameter integer CLKfrequency = 100e6;  //100 MHz
  parameter integer BaudRate = 1e6;  //high value to speed sim
  parameter integer CLKper = 1e9 / CLKfrequency;
  parameter integer ADDR_WIDTH = 16;
  parameter integer DATA_WIDTH = 32;


  // CORE SIGNALS
  reg  rst;
  reg  clk;
  wire cke;

  //iterator
  integer i, fd;

  `include "generated_wires_myuart_tb.vs"

  //system clock
  always #(CLKper / 2) clk = ~clk;
  assign cke = 1'b1;

  assign rcv_rx = snd_tx;
  assign snd_rx = rcv_tx;

`ifdef VCD
  initial begin
    $dumpfile("uut.vcd");
    $dumpvars();
  end
`endif

  initial begin
    clk = 0;
    #50000 $display("BOOM!");
    $finish();
  end


  `include "instantiate_myuart_rcv.vs"  // clk_i=clk arst_i=rst cke_i=cke
  `include "instantiate_myuart_snd.vs"  // clk_i=clk arst_i=rst cke_i=cke

endmodule
