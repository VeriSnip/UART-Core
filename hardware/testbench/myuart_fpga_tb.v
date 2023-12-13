/*
UART testbench for fpga FPGA wrapper module
*/
`include "timescale.vs"

module myuart_fpga_tb;

  parameter integer FREQ = 25e6;  //25 MHz
  parameter integer BaudRate = 115200;  //high value to speed sim
  parameter integer CLKper = 1e9 / FREQ;
  parameter integer ADDR_WIDTH = 16;
  parameter integer DATA_WIDTH = 32;

  // Declare an event to signal the completion of the reset sequence
  event send_event;
  event receive_event;

  // CORE SIGNALS
  reg rst = 0;
  reg clk = 0;
  wire cke;
  reg [15:0] div = FREQ / (16 * BaudRate);

  reg test_AXIL_awvalid;
  wire test_AXIL_awready;
  reg [ADDR_WIDTH-1:0] test_AXIL_awaddr;
  wire [2:0] test_AXIL_awprot;
  reg test_AXIL_wvalid;
  wire test_AXIL_wready;
  reg [DATA_WIDTH-1:0] test_AXIL_wdata;
  reg [DATA_WIDTH/8-1:0] test_AXIL_wstrb;
  wire test_AXIL_bvalid;
  reg test_AXIL_bready;
  wire [1:0] test_AXIL_bresp;
  reg test_AXIL_arvalid;
  wire test_AXIL_arready;
  reg [ADDR_WIDTH-1:0] test_AXIL_araddr;
  wire [2:0] test_AXIL_arprot;
  wire test_AXIL_rvalid;
  reg test_AXIL_rready;
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
    $dumpvars(0, myuart_fpga_tb);
  end
`endif

  // Reset sequence
  integer i;
  reg [7:0] test_lcr = 0;
  initial begin
    $display("TestBench: Started.");
    rst = 1'b1;
    for (i = 0; i < 10; i = i + 1) @(posedge clk);
    rst = 1'b0;
    // initialize test UART
    read_uart('d3, test_lcr);
    write_uart('d3, (test_lcr | 8'h80));
    write_uart('d1, div[15:8]);
    write_uart('d0, div[7:0]);
    write_uart('d3, (test_lcr & 8'h7f));
    write_uart('d2, 8'hc0);
    write_uart('d1, 8'h03);
    ->send_event;
  end

  // Send data
  reg [7:0] send_lsr = 0;
  reg [8:0] send_counter = 0;
  initial begin
    // send all possible bytes
    @(send_event);
    while (send_counter < 2 ** 8) begin
      read_uart('d5, send_lsr);
      if (send_lsr & 8'h40) begin
        write_uart('d0, send_counter);
        send_counter = send_counter + 1;
        ->receive_event;
        @(send_event);
      end
    end
  end

  // Receive data
  reg [7:0] receive_lsr = 0;
  reg [7:0] receive_data = 0;
  reg [8:0] receive_counter = 0;
  reg [7:0] receive_error_counter = 0;
  initial begin
    @(receive_event);
    while (receive_counter < 2 ** 8) begin
      read_uart('d5, receive_lsr);
      if (receive_lsr & 8'h01) begin
        read_uart('d0, receive_data);
        if (receive_counter != receive_data) begin
          $display("TestBench: Byte received: %x; Expected: %x.", receive_data, receive_counter);
          receive_error_counter = receive_error_counter + 1;
        end
        receive_counter = receive_counter + 1;
        ->send_event;
      end
    end
    if (!receive_error_counter)
      $display("TestBench: Successfully sent and received Bytes from 0 to 255.");
    else $display("TestBench: Failled to receive Bytes from 0 to 255.");
    $finish();
  end

  `include "instantiate_myuart_test.vs"  // clk_i=clk arst_i=rst cke_i=cke
  `include "instantiate_myuart_fpga_uut.vs"  // clk_i=clk arst_i=rst cke_i=cke

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
