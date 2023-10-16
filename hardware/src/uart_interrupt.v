`include "timescale.vs"

module uart_interrupt #(
    parameter TX_FIFO_DEPTH = 32,
    parameter RX_FIFO_DEPTH = 32
) (
    input wire clk_i,
    input wire arst_i,

    // registers
    input wire [2:0] IER_i,  // interrupt enable register
    input wire       RDA_i,  // receiver data available
    input wire       CTI_i,  // character timeout indication

    // control logic
    input wire                           error_i,
    input wire [$clog2(RX_FIFO_DEPTH):0] rx_elements_i,
    input wire [$clog2(TX_FIFO_DEPTH):0] tx_elements_i,
    input wire [                    1:0] trigger_level_i,

    input wire [3:0] clr_int_i,  // one hot

    output wire       interrupt_o,
    output wire [3:0] IIR_o
);

  reg [3:0] iir_n, iir_q;
  reg trigger_level_reached;

  always @(*) begin
    trigger_level_reached = 1'b0;
    case (trigger_level_i)
      2'b00: if ($unsigned(rx_elements_i) == 1) trigger_level_reached = 1'b1;
      2'b01: if ($unsigned(rx_elements_i) == 4) trigger_level_reached = 1'b1;
      2'b10: if ($unsigned(rx_elements_i) == 8) trigger_level_reached = 1'b1;
      2'b11: if ($unsigned(rx_elements_i) == 14) trigger_level_reached = 1'b1;
      default:  /* default */;
    endcase
  end

  always @(*) begin

    if (clr_int_i == 4'b0) iir_n = iir_q;
    else iir_n = iir_q & ~(clr_int_i);

    // Receiver line status interrupt on: Overrun error, parity error, framing error or break interrupt
    if (IER_i[2] & error_i) iir_n = 4'b1100;
    // Received data available or trigger level reached in FIFO mode
    else if (IER_i[0] & (trigger_level_reached | RDA_i)) iir_n = 4'b1000;
    // Character timeout indication
    else if (IER_i[0] & CTI_i) iir_n = 4'b1000;
    // Transmitter holding register empty
    else if (IER_i[1] & tx_elements_i == 0) iir_n = 4'b0100;
  end

  assign IIR_o = iir_n;
  assign interrupt_o = ~iir_q[0];

endmodule

