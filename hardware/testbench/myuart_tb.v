/*
UART testbench
*/
`include "timescale.vs"

module myuart_tb;

  parameter integer FREQ = 100e6;  //100 MHz
  parameter integer BaudRate = 115200;  //high value to speed sim
  parameter integer CLKper = 1e9 / FREQ;
  parameter integer ADDR_WIDTH = 16;
  parameter integer DATA_WIDTH = 32;

  // Declare an event to signal the completion of the reset sequence
  event reset_done;

  // CORE SIGNALS
  reg rst = 0;
  reg clk = 0;
  wire cke;
  reg [15:0] div = FREQ / (16 * BaudRate);

  `include "wires_myuart_tb.vs"

  //system clock
  always #(CLKper / 2) clk = ~clk;
  assign cke = 1'b1;

  assign rcv_rx = snd_tx;
  assign snd_rx = rcv_tx;

`ifdef VCD
  initial begin
    $dumpfile("output.vcd");
    $dumpvars(0, myuart_tb);
  end
`endif

  // Reset sequence
  integer i;
  initial begin
    rst = 1'b1;
    for (i = 0; i < 10; i = i + 1) @(posedge clk);
    rst = 1'b0;
    ->reset_done;
  end

  // Send data
  reg [7:0] snd_lcr = 0;
  reg [7:0] snd_lsr = 0;
  reg [8:0] snd_counter = 0;
  initial begin
    @(reset_done);
    // initialize sender UART
    read_snd('d3, snd_lcr);
    write_snd('d3, (snd_lcr | 8'h80));
    write_snd('d1, div[15:8]);
    write_snd('d0, div[7:0]);
    write_snd('d3, (snd_lcr & 8'h7f));
    write_snd('d2, 8'hc0);
    write_snd('d1, 8'h03);

    // send all possible bytes
    snd_counter = 0;
    while (snd_counter < 2 ** 8) begin
      read_snd('d5, snd_lsr);
      if (snd_lsr & 8'h40) begin
        write_snd('d0, snd_counter);
        snd_counter = snd_counter + 1;
      end
    end
  end

  // Receive data
  reg [7:0] rcv_lcr = 0;
  reg [7:0] rcv_lsr = 0;
  reg [7:0] rcv_data = 0;
  reg [8:0] rcv_counter = 0;
  reg [7:0] rcv_error_counter = 0;
  initial begin
    @(reset_done);
    $display("TestBench started.");
    // initialize receiver UART
    // initialize sender UART
    read_rcv('d3, rcv_lcr);
    write_rcv('d3, (rcv_lcr | 8'h80));
    write_rcv('d1, div[15:8]);
    write_rcv('d0, div[7:0]);
    write_rcv('d3, (rcv_lcr & 8'h7f));
    write_rcv('d2, 8'hc0);
    write_rcv('d1, 8'h03);

    // receive all possible bytes
    rcv_counter = 0;
    while (rcv_counter < 2 ** 8) begin
      read_rcv('d5, rcv_lsr);
      if (rcv_lsr & 8'h01) begin
        read_rcv('d0, rcv_data);
        if (rcv_counter != rcv_data) begin
          $display("Data received: %x; Expected: %x", rcv_data, rcv_counter);
          rcv_error_counter = rcv_error_counter + 1;
        end
        rcv_counter = rcv_counter + 1;
      end
    end

    if (!rcv_error_counter) $display("Test successful.");
    else $display("Test failled.");
    $finish();
  end

  `include "instantiate_myuart_rcv.vs"  // clk_i=clk arst_i=rst cke_i=cke
  `include "instantiate_myuart_snd.vs"  // clk_i=clk arst_i=rst cke_i=cke

  task automatic write_snd(input reg [ADDR_WIDTH-1:0] address, input reg [7:0] data);
    begin
      snd_AXIL_awvalid = 1'b1;
      snd_AXIL_awaddr  = address;
      snd_AXIL_wvalid  = 1'b1;
      snd_AXIL_wdata   = {{DATA_WIDTH - 8{1'b0}}, data};
      snd_AXIL_bready  = 1'b1;
      @(posedge clk);
      while (~snd_AXIL_awready & ~snd_AXIL_wready) @(posedge clk);
      snd_AXIL_awvalid = 1'b0;
      snd_AXIL_wvalid  = 1'b0;
      while (~snd_AXIL_bvalid) @(posedge clk);
    end
  endtask

  task automatic read_snd(input reg [ADDR_WIDTH-1:0] address, output reg [7:0] data);
    begin
      snd_AXIL_arvalid = 1'b1;
      snd_AXIL_araddr  = address;
      snd_AXIL_rready  = 1'b1;
      @(posedge clk);
      while (~snd_AXIL_arready) @(posedge clk);
      snd_AXIL_arvalid = 1'b0;
      while (~snd_AXIL_rvalid) @(posedge clk);
      data = snd_AXIL_rdata[7:0];
    end
  endtask

  task automatic write_rcv(input reg [ADDR_WIDTH-1:0] address, input reg [7:0] data);
    begin
      rcv_AXIL_awvalid = 1'b1;
      rcv_AXIL_awaddr  = address;
      rcv_AXIL_wvalid  = 1'b1;
      rcv_AXIL_wdata   = {{DATA_WIDTH - 8{1'b0}}, data};
      rcv_AXIL_bready  = 1'b1;
      @(posedge clk);
      while (~rcv_AXIL_awready & ~rcv_AXIL_wready) @(posedge clk);
      rcv_AXIL_awvalid = 1'b0;
      rcv_AXIL_wvalid  = 1'b0;
      while (~rcv_AXIL_bvalid) @(posedge clk);
    end
  endtask

  task automatic read_rcv(input reg [ADDR_WIDTH-1:0] address, output reg [7:0] data);
    begin
      rcv_AXIL_arvalid = 1'b1;
      rcv_AXIL_araddr  = address;
      rcv_AXIL_rready  = 1'b1;
      @(posedge clk);
      while (~rcv_AXIL_arready) @(posedge clk);
      rcv_AXIL_arvalid = 1'b0;
      while (~rcv_AXIL_rvalid) @(posedge clk);
      data = rcv_AXIL_rdata[7:0];
    end
  endtask
endmodule
