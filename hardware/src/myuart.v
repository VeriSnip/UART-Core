/*
UART module
*/
`include "timescale.vs"

module myuart #(
    parameter integer ADDR_W = 16,
    parameter integer DATA_W = 32,
    parameter integer TX_FIFO_DEPTH = 16,  // in bytes
    parameter integer RX_FIFO_DEPTH = 16  // in bytes
) (
    `include "io_clk_en_rst.vs"

    input  wire                awvalid,
    output wire                awready,
    input  wire [  ADDR_W-1:0] awaddr,
    input  wire [         2:0] awprot,
    input  wire                wvalid,
    output wire                wready,
    input  wire [  DATA_W-1:0] wdata,
    input  wire [DATA_W/8-1:0] wstrb,
    output wire                bvalid,
    input  wire                bready,
    output wire [         1:0] bresp,
    input  wire                arvalid,
    output wire                arready,
    input  wire [  ADDR_W-1:0] araddr,
    input  wire [         2:0] arprot,
    output wire                rvalid,
    input  wire                rready,
    output wire [  DATA_W-1:0] rdata,
    output wire [         1:0] rresp,

    input  wire rx_i,  // Receiver input
    output wire tx_o,  // Transmitter output

    output wire interrupt_o  // interrupt/event output
);

  // register addresses
  localparam integer RBR = 3'h0, THR = 3'h0, DLL = 3'h0, IER = 3'h1, DLM = 3'h1, IIR = 3'h2,
                     FCR = 3'h2, LCR = 3'h3, MCR = 3'h4, LSR = 3'h5, MSR = 3'h6, SCR = 3'h7;

  `include "myuart_wires.vs"

  // TODO: check that stop bits are really not necessary here
  uart_rx uart_rx_i (
      .clk_i          (clk_i),
      .rstn_i         (arst_i),
      .rx_i           (rx_i),
      .cfg_en_i       (1'b1),
      .cfg_div_i      ({regs_q[DLM+'d8], regs_q[DLL+'d8]}),
      .cfg_parity_en_i(regs_q[LCR][3]),
      .cfg_bits_i     (regs_q[LCR][1:0]),
      // .cfg_stop_bits_i    ( regs_q[LCR][2]                ),
      .busy_o         (),
      .err_o          (parity_error),
      .err_clr_i      (1'b1),
      .rx_data_o      (rx_data),
      .rx_valid_o     (rx_valid),
      .rx_ready_i     (rx_ready)
  );

  uart_tx uart_tx_i (
      .clk_i          (clk_i),
      .rstn_i         (arst_i),
      .tx_o           (tx_o),
      .busy_o         (),
      .cfg_en_i       (1'b1),
      .cfg_div_i      ({regs_q[DLM+'d8], regs_q[DLL+'d8]}),
      .cfg_parity_en_i(regs_q[LCR][3]),
      .cfg_bits_i     (regs_q[LCR][1:0]),
      .cfg_stop_bits_i(regs_q[LCR][2]),

      .tx_data_i (tx_data),
      .tx_valid_i(tx_valid),
      .tx_ready_o(tx_ready)
  );

  io_generic_fifo #(
      .DATA_WIDTH  (9),
      .BUFFER_DEPTH(RX_FIFO_DEPTH)
  ) uart_rx_fifo_i (
      .clk_i (clk_i),
      .rstn_i(arst_i),

      .clr_i(rx_fifo_clr_q),

      .elements_o(rx_elements),

      .data_o (fifo_rx_data),
      .valid_o(fifo_rx_valid),
      .ready_i(fifo_rx_ready),

      .valid_i(rx_valid),
      .data_i ({parity_error, rx_data}),
      .ready_o(rx_ready)
  );

  io_generic_fifo #(
      .DATA_WIDTH  (8),
      .BUFFER_DEPTH(TX_FIFO_DEPTH)
  ) uart_tx_fifo_i (
      .clk_i (clk_i),
      .rstn_i(arst_i),

      .clr_i(tx_fifo_clr_q),

      .elements_o(tx_elements),

      .data_o (tx_data),
      .valid_o(tx_valid),
      .ready_i(tx_ready),

      .valid_i(fifo_tx_valid),
      .data_i (fifo_tx_data),
      // not needed since we are getting the status via the fifo population
      .ready_o()
  );

  uart_interrupt #(
      .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
      .RX_FIFO_DEPTH(RX_FIFO_DEPTH)
  ) uart_interrupt_i (
      .clk_i (clk_i),
      .rstn_i(arst_i),


      .IER_i(regs_q[IER][2:0]),  // interrupt enable register
      .RDA_i(regs_n[LSR][5]),    // receiver data available
      .CTI_i(1'b0),              // character timeout indication


      .error_i        (regs_n[LSR][2]),
      .rx_elements_i  (rx_elements),
      .tx_elements_i  (tx_elements),
      .trigger_level_i(trigger_level_q),

      .clr_int_i(clr_int),  // one hot

      .interrupt_o(event_o),
      .IIR_o      (IIR_o)

  );

  `include "myuart_mmio.vs"

endmodule
