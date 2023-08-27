`include "timescale.vs"

module uart_tx (
    input  wire        clk_i,
    input  wire        arst_i,
    output reg         tx_o,
    output wire        busy_o,
    input  wire        cfg_en_i,
    input  wire [15:0] cfg_div_i,
    input  wire        cfg_parity_en_i,
    input  wire [ 1:0] cfg_bits_i,
    input  wire        cfg_stop_bits_i,
    input  wire [ 7:0] tx_data_i,
    input  wire        tx_valid_i,
    output reg         tx_ready_o
);

  localparam integer IDLE = 3'b000;
  localparam integer START_BIT = 3'b001;
  localparam integer DATA = 3'b010;
  localparam integer SAVE_DATA = 3'b011;
  localparam integer PARITY = 3'b100;
  localparam integer STOP_BIT = 3'b101;

  reg [ 2:0] CS;
  reg [ 2:0] NS;

  reg [ 7:0] reg_data;
  reg [ 7:0] reg_data_next;


  reg [ 2:0] reg_bit_count;
  reg [ 2:0] reg_bit_count_next;

  reg [ 2:0] s_target_bits;

  reg        parity_bit;
  reg        parity_bit_next;

  reg        sampleData;

  reg [15:0] baud_cnt;
  reg        baudgen_en;
  reg        bit_done;

  assign busy_o = (CS != IDLE);

  always @(*) begin
    case (cfg_bits_i)
      2'b00:   s_target_bits = 3'h4;
      2'b01:   s_target_bits = 3'h5;
      2'b10:   s_target_bits = 3'h6;
      default: s_target_bits = 3'h7;
    endcase
  end

  always @(*) begin
    NS = CS;
    tx_o = 1'b1;
    sampleData = 1'b0;
    reg_bit_count_next = reg_bit_count;
    reg_data_next = {1'b1, reg_data[7:1]};
    tx_ready_o = 1'b0;
    baudgen_en = 1'b0;
    parity_bit_next = parity_bit;
    case (CS)
      IDLE: begin
        if (cfg_en_i) tx_ready_o = 1'b1;
        if (tx_valid_i) begin
          NS = START_BIT;
          sampleData = 1'b1;
          reg_data_next = tx_data_i;
        end
      end

      START_BIT: begin
        tx_o = 1'b0;
        parity_bit_next = 1'b0;
        baudgen_en = 1'b1;
        if (bit_done) NS = DATA;
      end

      DATA: begin
        tx_o = reg_data[0];
        baudgen_en = 1'b1;
        parity_bit_next = parity_bit ^ reg_data[0];
        if (bit_done) begin
          if (reg_bit_count == s_target_bits) begin
            reg_bit_count_next = 'h0;
            if (cfg_parity_en_i) begin
              NS = PARITY;
            end else begin
              NS = STOP_BIT_FIRST;
            end
          end else begin
            reg_bit_count_next = reg_bit_count + 1;
            sampleData = 1'b1;
          end
        end
      end

      PARITY: begin
        tx_o = parity_bit;
        baudgen_en = 1'b1;
        if (bit_done) NS = STOP_BIT_FIRST;
      end
      STOP_BIT_FIRST: begin
        tx_o = 1'b1;
        baudgen_en = 1'b1;
        if (bit_done) begin
          if (cfg_stop_bits_i) NS = STOP_BIT_LAST;
          else NS = IDLE;
        end
      end
      STOP_BIT_LAST: begin
        tx_o = 1'b1;
        baudgen_en = 1'b1;
        if (bit_done) begin
          NS = IDLE;
        end
      end
      default: NS = IDLE;
    endcase
  end

  always @(posedge clk_i, posedge arst_i) begin
    if (arst_i == 1'b0) begin
      CS            <= IDLE;
      reg_data      <= 8'hFF;
      reg_bit_count <= 'h0;
      parity_bit    <= 1'b0;
    end else begin
      if (bit_done) begin
        parity_bit <= parity_bit_next;
      end

      if (sampleData) begin
        reg_data <= reg_data_next;
      end

      reg_bit_count <= reg_bit_count_next;
      if (cfg_en_i) CS <= NS;
      else CS <= IDLE;
    end
  end

  always @(posedge clk_i, posedge arst_i) begin
    if (arst_i == 1'b0) begin
      baud_cnt <= 'h0;
      bit_done <= 1'b0;
    end else begin
      if (baudgen_en) begin
        if (baud_cnt == cfg_div_i) begin
          baud_cnt <= 'h0;
          bit_done <= 1'b1;
        end else begin
          baud_cnt <= baud_cnt + 1;
          bit_done <= 1'b0;
        end
      end else begin
        baud_cnt <= 'h0;
        bit_done <= 1'b0;
      end
    end
  end

endmodule
