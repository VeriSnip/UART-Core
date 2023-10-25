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

    input  wire                awvalid_i,
    output wire                awready_o,
    input  wire [  ADDR_W-1:0] awaddr_i,
    input  wire [         2:0] awprot_i,
    input  wire                wvalid_i,
    output wire                wready_o,
    input  wire [  DATA_W-1:0] wdata_i,
    input  wire [DATA_W/8-1:0] wstrb_i,
    output wire                bvalid_o,
    input  wire                bready_i,
    output wire [         1:0] bresp_o,
    input  wire                arvalid_o,
    output wire                arready_o,
    input  wire [  ADDR_W-1:0] araddr_i,
    input  wire [         2:0] arprot_i,
    output wire                rvalid_o,
    input  wire                rready_o,
    output wire [  DATA_W-1:0] rdata_o,
    output wire [         1:0] rresp_o,

    input  wire rx_i,  // Receiver input
    output wire tx_o,  // Transmitter output

    output wire interrupt_o  // interrupt/event output
);

  // register addresses
  localparam integer RBR = 3'h0, THR = 3'h0, DLL = 3'h0, IER = 3'h1, DLM = 3'h1, IIR = 3'h2,
                     FCR = 3'h2, LCR = 3'h3, MCR = 3'h4, LSR = 3'h5, MSR = 3'h6, SCR = 3'h7;

  `include "generated_wires_myuart.vs"

  wire [                    2:0] register_adr;
  wire [                    1:0] trigger_level;

  // receive buffer register, read only
  wire [                    7:0] rx_data;
  // parity error
  wire                           parity_error;
  wire [                    3:0] IIR_o;
  reg  [                    3:0] clr_int;

  // tx flow control
  wire                           tx_ready;

  // rx flow control
  wire                           apb_rx_ready;
  wire                           rx_valid;


  wire                           fifo_tx_valid;
  wire                           tx_valid;
  wire                           tx_fifo_clr;
  wire [                    8:0] fifo_rx_data;
  wire                           fifo_rx_valid;
  wire                           fifo_rx_ready;
  wire                           rx_ready;
  wire                           rx_fifo_clr;

  wire [                    7:0] tx_data;
  wire [$clog2(TX_FIFO_DEPTH):0] tx_elements;
  wire [$clog2(RX_FIFO_DEPTH):0] rx_elements;


  assign trigger_level = ffc_reg_q[7:6];
  assign tx_fifo_clr   = ffc_reg_q[2];
  assign rx_fifo_clr   = ffc_reg_q[1];
  assign fifo_rx_ready = rbr_reg_sel & read_enable;
  assign fifo_tx_valid = thr_reg_sel & write_enable;

  `include "mmio_myuart.vs"  /*
  rbr_reg_q, 8, 8'h00, , ~lcr_reg_q[7], _n, RBR, R, fifo_rx_data[7:0]
  thr_reg_q, 8, 8'h00, , ~lcr_reg_q[7], fifo_tx_data, THR, W,
  ier_reg_q, 8, 8'h00, , ~lcr_reg_q[7], _n, IER, R/W,
  iir_reg_q, 8, 8'h01, , , _n, IIR, R, {4'h0, IIR_o}
  ffc_reg_q, 8, 8'h00, , , _n, FCR, W, {trigger_level, 6'h00}
  lcr_reg_q, 8, 8'h00, , , _n, LCR, R/W,
  mcr_reg_q, 8, 8'h00, , , _n, MCR, W,
  lsr_reg_q, 8, 8'h60, , , _n, LSR, R, {fifo_rx_valid, 1'b0, fifo_rx_data[8], 2'b00, ~(|tx_elements), (tx_ready) & (~(|tx_elements)), 1'b0}
  msr_reg_q, 8, 8'h00, , , _n, MSR, R,
  scr_reg_q, 8, 8'h00, , , _n, SCR, R/W,
  dlm_reg_q, 8, 8'h00, , lcr_reg_q[7], _n, DLM, R/W,
  dll_reg_q, 8, 8'h00, , lcr_reg_q[7], _n, DLL, R/W,
  */

  always @(*) begin
    clr_int = 4'b0;
    if (rbr_reg_sel) begin
      clr_int = 4'b1000;  // clear Received Data Available interrupt
    end
    if (lsr_reg_sel) begin
      clr_int = 4'b1100;  // clear parrity interrupt error
    end
    if (iir_reg_sel) begin
      clr_int = 4'b0100;  // clear Transmitter Holding Register Empty
    end
  end


  assign arready_o = 1'b1;
  assign awready_o = 1'b1;
  assign wready_o  = 1'b1;

  // TODO: check that stop bits are really not necessary here
  uart_rx uart_rx_i (
      .clk_i          (clk_i),
      .rstn_i         (~arst_i),
      .rx_i           (rx_i),
      .cfg_en_i       (1'b1),
      .cfg_div_i      ({dlm_reg_q, dll_reg_q}),
      .cfg_parity_en_i(lcr_reg_q[3]),
      .cfg_bits_i     (lcr_reg_q[1:0]),
      //.cfg_stop_bits_i(lcr_reg_q[2]),
      .busy_o         (),
      .err_o          (parity_error),
      .err_clr_i      (1'b1),
      .rx_data_o      (rx_data),
      .rx_valid_o     (rx_valid),
      .rx_ready_i     (rx_ready)
  );

  uart_tx uart_tx_i (
      .clk_i          (clk_i),
      .rstn_i         (~arst_i),
      .tx_o           (tx_o),
      .busy_o         (),
      .cfg_en_i       (1'b1),
      .cfg_div_i      ({dlm_reg_q, dll_reg_q}),
      .cfg_parity_en_i(lcr_reg_q[3]),
      .cfg_bits_i     (lcr_reg_q[1:0]),
      .cfg_stop_bits_i(lcr_reg_q[2]),

      .tx_data_i (tx_data),
      .tx_valid_i(tx_valid),
      .tx_ready_o(tx_ready)
  );

  io_generic_fifo #(
      .DATA_WIDTH  (9),
      .BUFFER_DEPTH(RX_FIFO_DEPTH)
  ) uart_rx_fifo_i (
      .clk_i (clk_i),
      .rstn_i(~arst_i),

      .clr_i(rx_fifo_clr),

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
      .rstn_i(~arst_i),

      .clr_i(tx_fifo_clr),

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
      .rstn_i(~arst_i),


      .IER_i(ier_reg_q[2:0]),  // interrupt enable register
      .RDA_i(lsr_reg_n[5]),    // receiver data available
      .CTI_i(1'b0),            // character timeout indication


      .error_i        (lsr_reg_n[2]),
      .rx_elements_i  (rx_elements),
      .tx_elements_i  (tx_elements),
      .trigger_level_i(trigger_level),

      .clr_int_i(clr_int),  // one hot

      .interrupt_o(interrupt_o),
      .IIR_o      (IIR_o)

  );

endmodule
