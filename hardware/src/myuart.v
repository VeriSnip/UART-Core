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

  `include "myuart_wires.vs"

  // TODO: check that stop bits are really not necessary here
  uart_rx uart_rx_i (
      .clk_i          (clk_i),
      .rstn_i         (arst_i),
      .rx_i           (rx_i),
      .cfg_en_i       (1'b1),
      .cfg_div_i      ({dlm_reg_q, dll_reg_q}),
      .cfg_parity_en_i(lcr_reg_q[3]),
      .cfg_bits_i     (lcr_reg_q[1:0]),
      .cfg_stop_bits_i(lcr_reg_q[2]),
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


      .IER_i(ier_reg_q[2:0]),  // interrupt enable register
      .RDA_i(lsr_reg_n[5]),    // receiver data available
      .CTI_i(1'b0),            // character timeout indication


      .error_i        (lsr_reg_n[2]),
      .rx_elements_i  (rx_elements),
      .tx_elements_i  (tx_elements),
      .trigger_level_i(trigger_level_q),

      .clr_int_i(clr_int),  // one hot

      .interrupt_o(interrupt_o),
      .IIR_o      (IIR_o)

  );

  `include "myuart_mmio.vs"
  // UART Registers
  // rx status, parity error on receiving part has occured, tx status register
  assign lsr_reg_n = {
    fifo_rx_valid,
    1'b0,
    fifo_rx_data[8],
    2'b00,
    ~(|tx_elements),
    (tx_ready) & (~(|tx_elements)),
    1'b0
  };

  // register write and update logic
  always @(*) begin
    ier_reg_n = ier_reg_q;
    iir_reg_n = iir_reg_q;
    lcr_reg_n = lcr_reg_q;
    mcr_reg_n = mcr_reg_q;
    msr_reg_n = msr_reg_q;
    scr_reg_n = scr_reg_q;
    dlm_reg_n = dlm_reg_q;
    dll_reg_n = dll_reg_q;
    trigger_level_n = trigger_level_q;

    fifo_tx_valid = 1'b0;
    tx_fifo_clr_n = 1'b0;  // self clearing
    rx_fifo_clr_n = 1'b0;  // self clearing

    if (wvalid_i) begin
      case (awaddr_i)

        THR: // either THR or DLL
              begin
          if (lcr_reg_q[7]) // Divisor Latch Access Bit (DLAB)
                  begin
            dll_reg_n = wdata_i[7:0];
          end else begin
            fifo_tx_data  = wdata_i[7:0];
            fifo_tx_valid = 1'b1;
          end
        end

        IER: // either IER or DLM
              begin
          if (lcr_reg_q[7])  // Divisor Latch Access Bit (DLAB)
            dlm_reg_n = wdata_i[7:0];
          else ier_reg_n = wdata_i[7:0];
        end

        LCR: lcr_reg_n = wdata_i[7:0];

        FCR: // write only register, fifo control register
              begin
          rx_fifo_clr_n   = wdata_i[1];
          tx_fifo_clr_n   = wdata_i[2];
          trigger_level_n = wdata_i[7:6];
        end

        default: ;
      endcase

    end

  end

  // register read logic
  always @(*) begin
    rdata_o       = 'b0;
    fifo_rx_ready = 1'b0;
    clr_int       = 4'b0;

    if (awread) begin
      case (araddr_i)
        RBR: // either RBR or DLL
              begin
          if (lcr_reg_q[7])  // Divisor Latch Access Bit (DLAB)
            rdata_o = {24'b0, dll_reg_q};
          else begin

            fifo_rx_ready = 1'b1;

            rdata_o = {24'b0, fifo_rx_data[7:0]};

            clr_int = 4'b1000;  // clear Received Data Available interrupt
          end
        end

        LSR: // Line Status Register
              begin
          rdata_o = {24'b0, lsr_reg_q};
          clr_int = 4'b1100;  // clear parrity interrupt error
        end

        LCR:  // Line Control Register
        rdata_o = {24'b0, lcr_reg_q};

        IER: // either IER or DLM
              begin
          if (lcr_reg_q[7])  // Divisor Latch Access Bit (DLAB)
            rdata_o = {24'b0, dlm_reg_q};
          else rdata_o = {24'b0, ier_reg_q};
        end

        IIR: // interrupt identification register read only
              begin
          rdata_o = {24'b0, 1'b1, 1'b1, 2'b0, IIR_o};
          clr_int = 4'b0100;  // clear Transmitter Holding Register Empty
        end

        default: ;
      endcase
    end
  end

  // synchronouse part
  always @(posedge clk_i, posedge arst_i) begin
    if (arst_i) begin
      ier_reg_q <= 8'h00;
      iir_reg_q <= 8'h01;
      lcr_reg_q <= 8'h00;
      mcr_reg_q <= 8'h00;
      lsr_reg_q <= 8'h60;
      msr_reg_q <= 8'h00;
      scr_reg_q <= 8'h00;
      dlm_reg_q <= 8'h00;
      dll_reg_q <= 8'h00;

      trigger_level_q <= 2'b00;
      tx_fifo_clr_q <= 1'b0;
      rx_fifo_clr_q <= 1'b0;
    end else begin
      ier_reg_q <= ier_reg_n;
      iir_reg_q <= iir_reg_n;
      lcr_reg_q <= lcr_reg_n;
      mcr_reg_q <= mcr_reg_n;
      lsr_reg_q <= lsr_reg_n;
      msr_reg_q <= msr_reg_n;
      scr_reg_q <= scr_reg_n;
      dlm_reg_q <= dlm_reg_n;
      dll_reg_q <= dll_reg_n;

      trigger_level_q <= trigger_level_n;
      tx_fifo_clr_q <= tx_fifo_clr_n;
      rx_fifo_clr_q <= rx_fifo_clr_n;
    end
  end

  assign arready_o = 1'b1;
  assign awready_o = 1'b1;
  assign wready_o  = 1'b1;

endmodule
