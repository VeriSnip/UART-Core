/*
UART module
*/
`include "timescale.vs"

module myuart_tb;

  parameter integer CLKfrequency = 100e6; //100 MHz
  parameter integer BaudRate = 1e6; //high value to speed sim
  parameter integer CLKper = 1e9/CLKfrequency;

  // CORE SIGNALS
  reg  arst;
  reg  clk;
  wire cke;
  //system clock
  always #(CLKper/2) clk = ~clk;
  assign cke = 1'b1;

  `include "myuart_tb_wires.vs"
  `include "instantiate_myuart_rcv.vs"
  `include "instantiate_myuart_snd.vs"

endmodule
