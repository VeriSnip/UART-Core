module myuart_ecp5 (
    // input hardware clock (25 MHz)
    input  wire clk_i,
    input  wire arst_i,
    // UART lines
    output wire tx_o,
    input  wire rx_i
);

  localparam integer FREQ = 25000000;
  localparam integer BAUD = 115200;
  localparam integer DATA_WIDTH = 32;
  localparam integer ADDR_WIDTH = 16;
  localparam integer NInitSequence = 6;
  localparam integer ReadReadyState = 0, ReadDataState = 1, WriteReadyState = 2, WriteDataState = 3;
  localparam integer InitializingState = 0, FeedBackState = 1;

  `include "generated_wires_myuart_ecp5.vs"
  wire cke;
  wire [DATA_WIDTH-1:0] initSequenceData[NInitSequence];
  wire [ADDR_WIDTH-1:0] initSequenceAddress[NInitSequence];
  wire [15:0] div;
  reg initSequence_q;
  reg initSequence_n;
  reg [1:0] state_q;
  reg [1:0] state_n;
  reg [2:0] counter;
  reg [2:0] counter_n;
  reg uut_AXIL_awvalid_q;
  reg uut_AXIL_awvalid_n;
  reg [ADDR_WIDTH-1:0] uut_AXIL_awaddr_q;
  reg [ADDR_WIDTH-1:0] uut_AXIL_awaddr_n;
  reg uut_AXIL_wvalid_q;
  reg uut_AXIL_wvalid_n;
  reg [DATA_WIDTH-1:0] uut_AXIL_wdata_q;
  reg [DATA_WIDTH-1:0] uut_AXIL_wdata_n;
  reg uut_AXIL_arvalid_q;
  reg uut_AXIL_arvalid_n;
  reg [ADDR_WIDTH-1:0] uut_AXIL_araddr_q;
  reg [ADDR_WIDTH-1:0] uut_AXIL_araddr_n;

  assign initSequenceData[0] = 32'h083;
  assign initSequenceData[1] = {{24{1'b0}}, div[15:8]};
  assign initSequenceData[2] = {{24{1'b0}}, div[7:0]};
  assign initSequenceData[3] = 32'h03;
  assign initSequenceData[4] = 32'h0c0;
  assign initSequenceData[5] = 32'h03;
  assign initSequenceAddress[0] = 32'd3;
  assign initSequenceAddress[1] = 32'd1;
  assign initSequenceAddress[2] = 32'd0;
  assign initSequenceAddress[3] = 32'd3;
  assign initSequenceAddress[4] = 32'd2;
  assign initSequenceAddress[5] = 32'd1;

  assign uut_AXIL_awvalid = uut_AXIL_awvalid_q;
  assign uut_AXIL_awaddr = uut_AXIL_awaddr_q;
  assign uut_AXIL_wvalid = uut_AXIL_wvalid_q;
  assign uut_AXIL_wdata = uut_AXIL_wdata_q;
  assign uut_AXIL_arvalid = uut_AXIL_arvalid_q;
  assign uut_AXIL_araddr = uut_AXIL_araddr_q;

  assign cke = 1'b1;

  assign div = FREQ / (16 * BAUD);
  assign uut_AXIL_rready = 1'b1;

  // Design FSM to control UART and send FeedBack
  always @(*) begin
    state_n = state_q;
    initSequence_n = initSequence_q;
    uut_AXIL_awvalid_n = 1'b0;
    uut_AXIL_awaddr_n = uut_AXIL_awaddr;
    uut_AXIL_wvalid_n = 1'b0;
    uut_AXIL_wdata_n = uut_AXIL_wdata;
    uut_AXIL_arvalid_n = 1'b0;
    uut_AXIL_araddr_n = uut_AXIL_araddr;
    counter_n = 3'b000;

    if (initSequence_q) begin
      if (counter == NInitSequence) initSequence_n = 1'b0;
      else begin
        counter_n = counter + 1'b1;
        uut_AXIL_awvalid_n = 1'b1;
        uut_AXIL_awaddr_n  = initSequenceAddress[counter];
        uut_AXIL_wvalid_n  = 1'b1;
        uut_AXIL_wdata_n   = initSequenceData[counter];
      end
    end else begin
      case (state_q)
        ReadReadyState: begin
          uut_AXIL_arvalid_n = 1'b1;
          uut_AXIL_araddr_n = 32'd5;
          state_n = ReadDataState;
        end
        ReadDataState: begin
          uut_AXIL_arvalid_n = 1'b1;
          uut_AXIL_araddr_n  = 32'd5;
          if (uut_AXIL_rdata[0]) begin
            uut_AXIL_araddr_n = 32'd0;
            state_n = WriteReadyState;
          end
        end
        WriteReadyState: begin
          uut_AXIL_arvalid_n = 1'b1;
          uut_AXIL_araddr_n = 32'd5;
          state_n = WriteDataState;
        end
        WriteDataState: begin
          uut_AXIL_arvalid_n = 1'b1;
          uut_AXIL_araddr_n  = 32'd5;
          if (uut_AXIL_rdata[6]) begin
            uut_AXIL_arvalid_n = 1'b0;
            uut_AXIL_awvalid_n = 1'b1;
            uut_AXIL_awaddr_n = 32'd0;
            uut_AXIL_wvalid_n = 1'b1;
            state_n = ReadReadyState;
          end else begin
            uut_AXIL_wdata_n = uut_AXIL_rdata;
          end
        end
        default;
      endcase
    end
  end

  `include "reg_myuart_ecp5.vs"  /*
  state_q, 2, 0, , , _n
  initSequence_q, 1, 1, , , _n
  uut_AXIL_awvalid_q, 1, 0, , , _n
  uut_AXIL_awaddr_q, ADDR_WIDTH, 0, , , _n
  uut_AXIL_wvalid_q, 1, 0, , , _n
  uut_AXIL_wdata_q, DATA_WIDTH, 0, , , _n
  uut_AXIL_arvalid_q, 1, 0, , , _n
  uut_AXIL_araddr_q, ADDR_WIDTH, 0, , , _n
  counter, 3, 0, , , _n
  */

  `include "instantiate_myuart_uut.vs"  // clk_i=clk_i arst_i=arst_i cke_i=cke rx_i=rx_i tx_o=tx_o

endmodule
