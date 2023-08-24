  // CORE SIGNALS
  reg  arst;
  reg  clk;
  wire cke;

  //iterator
  integer i, fd;

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

