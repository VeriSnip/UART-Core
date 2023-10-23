/*
UART testbench
*/
`include "timescale.vs"

module myuart_tb;

  parameter integer CLKfrequency = 100e6; //100 MHz
  parameter integer BaudRate = 1e6; //high value to speed sim
  parameter integer CLKper = 1e9/CLKfrequency;
  parameter integer ADDR_W = 16;
  parameter integer DATA_W = 32;


  // CORE SIGNALS
  reg  rst;
  reg  clk;
  wire cke;

  //iterator
  integer i, fd;

  `include "generated_wires_myuart_tb.vs"

  wire                rcv_awvalid;
  wire                rcv_awready;
  wire [  ADDR_W-1:0] rcv_awaddr;
  wire [         2:0] rcv_awprot;
  wire                rcv_wvalid;
  wire                rcv_wready;
  wire [  DATA_W-1:0] rcv_wdata;
  wire [DATA_W/8-1:0] rcv_wstrb;
  wire                rcv_bvalid;
  wire                rcv_bready;
  wire [         1:0] rcv_bresp;
  wire                rcv_arvalid;
  wire                rcv_arready;
  wire [  ADDR_W-1:0] rcv_araddr;
  wire [         2:0] rcv_arprot;
  wire                rcv_rvalid;
  wire                rcv_rready;
  wire [  DATA_W-1:0] rcv_rdata;
  wire [         1:0] rcv_rresp;
  wire                rcv_rx;
  wire                rcv_tx;
  wire                rcv_interrupt;

  wire                snd_awvalid;
  wire                snd_awready;
  wire [  ADDR_W-1:0] snd_awaddr;
  wire [         2:0] snd_awprot;
  wire                snd_wvalid;
  wire                snd_wready;
  wire [  DATA_W-1:0] snd_wdata;
  wire [DATA_W/8-1:0] snd_wstrb;
  wire                snd_bvalid;
  wire                snd_bready;
  wire [         1:0] snd_bresp;
  wire                snd_arvalid;
  wire                snd_arready;
  wire [  ADDR_W-1:0] snd_araddr;
  wire [         2:0] snd_arprot;
  wire                snd_rvalid;
  wire                snd_rready;
  wire [  DATA_W-1:0] snd_rdata;
  wire [         1:0] snd_rresp;
  wire                snd_rx;
  wire                snd_tx;
  wire                snd_interrupt;


  //system clock
  always #(CLKper/2) clk = ~clk;
  assign cke = 1'b1;

  assign rcv_rx = snd_tx;
  assign snd_rx = rcv_tx;


  initial begin
`ifdef VCD
    $dumpfile("uut.vcd");
    $dumpvars();
`endif

    clk      = 1;
    rst      = 1;

    // deassert hard reset
    #100 @(posedge clk) #1 rst = 0;
    #100 @(posedge clk);


    // write data to send
    for (i = 0; i < 256; i = i + 1) begin

      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
    end  // for (i=0; i < 256; i= i+1)

    $display("Test PASSED");

    fd = $fopen("test.log", "w");
    $fdisplay(fd, "Test passed!");
    $fclose(fd);
    $finish();
  end

  `include "instantiate_myuart_rcv.vs" // clk_i=clk arst_i=rst cke_i=cke
  `include "instantiate_myuart_snd.vs" // clk_i=clk arst_i=rst cke_i=cke

endmodule
