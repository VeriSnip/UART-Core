module myuart_ecp5 (
    // input hardware clock (25 MHz)
    input  wire clk_i,
    input wire arst_i,
    // UART lines
    output reg  tx_o,
    input  wire rx_i
);

  localparam integer FREQ = 25000000;
  localparam integer BAUD = 115200;
  localparam integer ReadState = 1'b0, WriteState = 1'b1;

  `include "generated_wires_myuart_ecp5.vs"
  wire cke;

  assign cke = 1'b1;

  // Design FSM to control UART and send FeedBack

  `include "instantiate_myuart_uut.vs"  // clk_i=clk arst_i=rst cke_i=cke

endmodule
