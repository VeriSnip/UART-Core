  `include "generated_wires_myuart.vs"

  wire [2:0]       register_adr;
  wire [1:0]       trigger_level;

  // receive buffer register, read only
  wire [7:0]       rx_data;
  // parity error
  wire             parity_error;
  wire [3:0]       IIR_o;
  wire [3:0]       clr_int;

  // tx flow control
  wire tx_ready;

  // rx flow control
  wire apb_rx_ready;
  wire rx_valid;

  wire tx_fifo_clr;
  wire rx_fifo_clr;

  wire fifo_tx_valid;
  wire tx_valid;
  wire fifo_rx_valid;
  wire fifo_rx_ready;
  wire rx_ready;

  wire [7:0] tx_data;
  wire [$clog2(TX_FIFO_DEPTH):0] tx_elements;
  wire [$clog2(RX_FIFO_DEPTH):0] rx_elements;
