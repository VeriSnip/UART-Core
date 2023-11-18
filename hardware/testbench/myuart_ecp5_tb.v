/*
UART testbench for ECP5 FPGA wrapper module
*/
`include "timescale.vs"

module myuart_ecp5_tb;

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

  reg  test_AXIL_awvalid;
  wire test_AXIL_awready;
  reg  [ADDR_WIDTH-1:0] test_AXIL_awaddr;
  wire [2:0] test_AXIL_awprot;
  reg  test_AXIL_wvalid;
  wire test_AXIL_wready;
  reg  [DATA_WIDTH-1:0] test_AXIL_wdata;
  reg  [DATA_WIDTH/8-1:0] test_AXIL_wstrb;
  wire test_AXIL_bvalid;
  reg  test_AXIL_bready;
  wire [1:0] test_AXIL_bresp;
  reg  test_AXIL_arvalid;
  wire test_AXIL_arready;
  reg  [ADDR_WIDTH-1:0] test_AXIL_araddr;
  wire [2:0] test_AXIL_arprot;
  wire test_AXIL_rvalid;
  reg  test_AXIL_rready;
  wire [DATA_WIDTH-1:0] test_AXIL_rdata;
  wire [1:0] test_AXIL_rresp;
  wire test_rx;
  wire test_tx;
  wire test_interrupt;

  wire uut_rx;
  wire uut_tx;

  //system clock
  always #(CLKper / 2) clk = ~clk;
  assign cke = 1'b1;

  assign test_rx = uut_tx;
  assign uut_rx = test_tx;

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

  // Receive data
  reg [7:0] test_lcr = 0;
  reg [7:0] test_lsr = 0;
  reg [7:0] test_data = 0;
  reg [8:0] test_counter = 0;
  reg [7:0] test_error_counter = 0;
  initial begin
    @(reset_done);
    $display("TestBench started.");
    // initialize receiver UART
    // initialize sender UART
    read_uart('d3, test_lcr);
    write_uart('d3, (test_lcr | 8'h80));
    write_uart('d1, div[15:8]);
    write_uart('d0, div[7:0]);
    write_uart('d3, (test_lcr & 8'h7f));
    write_uart('d2, 8'hc0);
    write_uart('d1, 8'h03);

    // receive all possible bytes
    test_counter = 0;
    while (test_counter < 2 ** 8) begin
      read_uart('d5, test_lsr);
      if (test_lsr & 8'h40) begin
        write_uart('d0, test_counter);
        test_counter = test_counter + 1;
      end
      if (test_lsr & 8'h01) begin
        read_uart('d0, test_data);
        if (test_counter != test_data) begin
          $display("Data received: %x; Expected: %x", test_data, test_counter);
          test_error_counter = test_error_counter + 1;
        end
        test_counter = test_counter + 1;
      end
    end

    if (!test_error_counter) $display("Test successful.");
    else $display("Test failled.");
    $finish();
  end

  `include "instantiate_myuart_test.vs"  // clk_i=clk arst_i=rst cke_i=cke
  `include "instantiate_myuart_ecp5_uut.vs"  // clk_i=clk arst_i=rst cke_i=cke

  task automatic write_uart(input reg [ADDR_WIDTH-1:0] address, input reg [7:0] data);
    begin
      test_AXIL_awvalid = 1'b1;
      test_AXIL_awaddr  = address;
      test_AXIL_wvalid  = 1'b1;
      test_AXIL_wdata   = {{DATA_WIDTH - 8{1'b0}}, data};
      test_AXIL_bready  = 1'b1;
      @(posedge clk);
      while (~test_AXIL_awready & ~test_AXIL_wready) @(posedge clk);
      test_AXIL_awvalid = 1'b0;
      test_AXIL_wvalid  = 1'b0;
      while (~test_AXIL_bvalid) @(posedge clk);
    end
  endtask

  task automatic read_uart(input reg [ADDR_WIDTH-1:0] address, output reg [7:0] data);
    begin
      test_AXIL_arvalid = 1'b1;
      test_AXIL_araddr  = address;
      test_AXIL_rready  = 1'b1;
      @(posedge clk);
      while (~test_AXIL_arready) @(posedge clk);
      test_AXIL_arvalid = 1'b0;
      while (~test_AXIL_rvalid) @(posedge clk);
      data = test_AXIL_rdata[7:0];
    end
  endtask
endmodule
