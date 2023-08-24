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


  `include "myuart_tb_wires.vs"


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
    rst_soft = 0;

    rd_en    = 0;
    wr_en    = 0;

    tx_en    = 0;
    rx_en    = 0;

    div      = clk_frequency / baud_rate;

    // deassert hard reset
    #100 @(posedge clk) #1 rst = 0;
    #100 @(posedge clk);

    // assert tx not ready
    if (tx_ready) begin
        $display("ERROR: TX is ready initially");
        $finish();
    end

    // assert rx not ready
    if (rx_ready) begin
        $display("ERROR: RX is ready initially");
        $finish();
    end

    //pulse soft reset
    #1 rst_soft = 1;
    @(posedge clk) #1 rst_soft = 0;


    //enable rx
    @(posedge clk) #1 rx_en = 1;

    //enable tx
    #20000;
    @(posedge clk) #1 tx_en = 1;


    // write data to send
    for (i = 0; i < 256; i = i + 1) begin
      //wait for tx ready 
      do @(posedge clk); while (!tx_ready);

      //write word to send
      @(posedge clk) #1 wr_en = 1;
      tx_data = i;
      @(posedge clk) #1 wr_en = 0;

      //wait for core to receive datarx ready 
      do @(posedge clk); while (!rx_ready);

      //read received word
      @(posedge clk) #1 rd_en = 1;
      rcvd_data = rx_data;
      @(posedge clk) #1 rd_en = 0;


      // check received data
      if (rcvd_data != i) begin
        $display("Test failed: got %x, expected %x", rcvd_data, i);
        fd = $fopen("test.log", "w");
        $fdisplay(fd, "Test failed: got %x, expected %x", rcvd_data, i);
        $fclose(fd);
        $finish();
      end

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

  `include "instantiate_myuart_rcv.vs" // clk_i=clk arst_i=arst cke_i=cke
  `include "instantiate_myuart_snd.vs" // clk_i=clk arst_i=arst cke_i=cke

endmodule
