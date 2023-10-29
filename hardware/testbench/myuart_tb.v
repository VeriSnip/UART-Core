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

  initial begin
    clk = 0;
    #5000000 $display("BOOM!");
    $finish();
  end

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
  reg [7:0] snd_counter = 0;
  initial begin
    @(reset_done);
    // initialize sender UART
    snd_AXIL_araddr = 'd3;
    read_axil(snd_AXIL_arvalid, snd_AXIL_arready, snd_AXIL_rvalid, snd_AXIL_rready);
    snd_lcr = snd_AXIL_rdata[7:0];
    snd_AXIL_awaddr = 'd3;
    snd_AXIL_wdata = {{DATA_WIDTH - 8{1'b0}}, (snd_lcr | 8'h80)};
    write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);
    snd_AXIL_awaddr = 'd1;
    snd_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, div[15:8]};
    write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);
    snd_AXIL_awaddr = 'd0;
    snd_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, div[7:0]};
    write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);
    snd_AXIL_awaddr = 'd3;
    snd_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, (snd_lcr & 8'h7f)};
    write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);
    snd_AXIL_awaddr = 'd2;
    snd_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, 8'hc0};
    write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);
    snd_AXIL_awaddr = 'd1;
    snd_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, 8'h03};
    write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);

    // send all possible bytes
    for (snd_counter = 0; snd_counter < 2 ** 8; snd_counter = snd_counter + 1) begin
      snd_AXIL_araddr = 'd5;
      read_axil(snd_AXIL_arvalid, snd_AXIL_arready, snd_AXIL_rvalid, snd_AXIL_rready);
      snd_lsr = snd_AXIL_rdata[7:0];
      if (snd_lsr & 8'h40) begin
        snd_AXIL_awaddr = 'd0;
        snd_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, snd_counter};
        write_axil(snd_AXIL_awvalid, snd_AXIL_awready, snd_AXIL_wvalid, snd_AXIL_wready, snd_AXIL_bvalid, snd_AXIL_bready);
      end
    end
  end

  // Receive data
  reg [7:0] rcv_lcr = 0;
  reg [7:0] rcv_lsr = 0;
  reg [7:0] rcv_counter = 0;
  reg [7:0] rcv_error_counter = 0;
  initial begin
    @(reset_done);
    $display("TestBench started.");
    // initialize receiver UART
    rcv_AXIL_araddr = 'd3;
    read_axil(rcv_AXIL_arvalid, rcv_AXIL_arready, rcv_AXIL_rvalid, rcv_AXIL_rready);
    rcv_lcr = rcv_AXIL_rdata[7:0];
    rcv_AXIL_awaddr = 'd3;
    rcv_AXIL_wdata = {{DATA_WIDTH - 8{1'b0}}, (rcv_lcr | 8'h80)};
    write_axil(rcv_AXIL_awvalid, rcv_AXIL_awready, rcv_AXIL_wvalid, rcv_AXIL_wready, rcv_AXIL_bvalid, rcv_AXIL_bready);
    rcv_AXIL_awaddr = 'd1;
    rcv_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, div[15:8]};
    write_axil(rcv_AXIL_awvalid, rcv_AXIL_awready, rcv_AXIL_wvalid, rcv_AXIL_wready, rcv_AXIL_bvalid, rcv_AXIL_bready);
    rcv_AXIL_awaddr = 'd0;
    rcv_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, div[7:0]};
    write_axil(rcv_AXIL_awvalid, rcv_AXIL_awready, rcv_AXIL_wvalid, rcv_AXIL_wready, rcv_AXIL_bvalid, rcv_AXIL_bready);
    rcv_AXIL_awaddr = 'd3;
    rcv_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, rcv_lcr};
    write_axil(rcv_AXIL_awvalid, rcv_AXIL_awready, rcv_AXIL_wvalid, rcv_AXIL_wready, rcv_AXIL_bvalid, rcv_AXIL_bready);
    rcv_AXIL_awaddr = 'd2;
    rcv_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, 8'hc0};
    write_axil(rcv_AXIL_awvalid, rcv_AXIL_awready, rcv_AXIL_wvalid, rcv_AXIL_wready, rcv_AXIL_bvalid, rcv_AXIL_bready);
    rcv_AXIL_awaddr = 'd1;
    rcv_AXIL_wdata  = {{DATA_WIDTH - 8{1'b0}}, 8'h03};
    write_axil(rcv_AXIL_awvalid, rcv_AXIL_awready, rcv_AXIL_wvalid, rcv_AXIL_wready, rcv_AXIL_bvalid, rcv_AXIL_bready);

    // receive all possible bytes
    for (rcv_counter = 0; rcv_counter < 2 ** 8; rcv_counter = rcv_counter + 1) begin
      rcv_AXIL_araddr = 'd5;
      read_axil(rcv_AXIL_arvalid, rcv_AXIL_arready, rcv_AXIL_rvalid, rcv_AXIL_rready);
      rcv_lsr = rcv_AXIL_rdata[7:0];
      if (rcv_lsr & 8'h01) begin
        rcv_AXIL_awaddr = 'd0;
        read_axil(rcv_AXIL_arvalid, rcv_AXIL_arready, rcv_AXIL_rvalid, rcv_AXIL_rready);
        if (rcv_counter != rcv_AXIL_rdata[7:0]) begin
          $display("Received data was not what expected: %x", rcv_AXIL_rdata[7:0]);
          rcv_error_counter = rcv_error_counter + 1;
        end
      end
    end

    if (~rcv_error_counter) $display("Test successful.");
    else $display("Test failled.");
    $finish();
  end

  `include "instantiate_myuart_rcv.vs"  // clk_i=clk arst_i=rst cke_i=cke
  `include "instantiate_myuart_snd.vs"  // clk_i=clk arst_i=rst cke_i=cke

  task automatic write_axil(output reg awvalid, input reg awready, output reg wvalid,
                            input reg wready, input reg bvalid, output reg bready);
    begin
      awvalid = 1'b1;
      wvalid  = 1'b1;
      bready  = 1'b1;
      @(posedge clk);
      while (~awready & ~wready) @(posedge clk);
      awvalid = 1'b0;
      wvalid  = 1'b0;
      while (~bvalid) @(posedge clk);
    end
  endtask

  task automatic read_axil(output reg arvalid, input reg arready, input reg rvalid,
                           output reg rready);
    begin
      arvalid = 1'b1;
      rready  = 1'b1;
      @(posedge clk);
      while (~arready) @(posedge clk);
      arvalid = 1'b0;
      while (~rvalid) @(posedge clk);
    end
  endtask
endmodule
