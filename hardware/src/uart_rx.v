`include "timescale.vs"

module uart_rx (
    input  wire        clk_i,
    input  wire        arst_i,
    input  wire        rx_i,
    input  wire [15:0] cfg_div_i,
    input  wire        cfg_en_i,
    input  wire        cfg_parity_en_i,
    input  wire [ 1:0] cfg_bits_i,
    input  wire        cfg_stop_bits_i,
    output wire        busy_o,
    output reg         err_o,
    input  wire        err_clr_i,
    output wire [ 7:0] rx_data_o,
    output reg         rx_valid_o,
    input  wire        rx_ready_i
);


  localparam integer IDLE = 3'b000;
  localparam integer START_BIT = 3'b001;
  localparam integer DATA = 3'b010;
  localparam integer SAVE_DATA = 3'b011;
  localparam integer PARITY = 3'b100;
  localparam integer STOP_BIT = 3'b101;

  reg  [ 2:0] CS;
  reg  [ 2:0] NS;

  reg  [ 7:0] reg_data;
  reg  [ 7:0] reg_data_next;

  reg  [ 2:0] reg_rx_sync;


  reg  [ 2:0] reg_bit_count;
  reg  [ 2:0] reg_bit_count_next;

  reg  [ 2:0] s_target_bits;

  reg         parity_bit;
  reg         parity_bit_next;

  reg         sampleData;

  reg  [15:0] baud_cnt;
  reg         baudgen_en;
  reg         bit_done;

  reg         start_bit;
  reg         set_error;
  wire        s_rx_fall;

  wire        not_started;
  wire        end_receiving;
  wire        not_in_transmission;
  wire        bit_done_r;
  wire        baud_cnt_r;


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
    sampleData = 1'b0;
    reg_bit_count_next = reg_bit_count;
    reg_data_next = reg_data;
    rx_valid_o = 1'b0;
    baudgen_en = 1'b0;
    start_bit = 1'b0;
    parity_bit_next = parity_bit;
    set_error = 1'b0;

    case (CS)
      IDLE: begin
        if (s_rx_fall) begin
          NS = START_BIT;
          baudgen_en = 1'b1;
          start_bit = 1'b1;
        end
      end

      START_BIT: begin
        parity_bit_next = 1'b0;
        baudgen_en = 1'b1;
        start_bit = 1'b1;
        if (bit_done) NS = DATA;
      end

      DATA: begin
        baudgen_en = 1'b1;
        parity_bit_next = parity_bit ^ reg_rx_sync[2];
        case (cfg_bits_i)
          2'b00:   reg_data_next = {3'b000, reg_rx_sync[2], reg_data[4:1]};
          2'b01:   reg_data_next = {2'b00, reg_rx_sync[2], reg_data[5:1]};
          2'b10:   reg_data_next = {1'b0, reg_rx_sync[2], reg_data[6:1]};
          default: reg_data_next = {reg_rx_sync[2], reg_data[7:1]};
        endcase

        if (bit_done) begin
          sampleData = 1'b1;
          if (reg_bit_count == s_target_bits) begin
            reg_bit_count_next = 'h0;
            NS = SAVE_DATA;
          end else begin
            reg_bit_count_next = reg_bit_count + 1;
          end
        end
      end
      SAVE_DATA: begin
        baudgen_en = 1'b1;
        rx_valid_o = 1'b1;
        if (rx_ready_i)
          if (cfg_parity_en_i) NS = PARITY;
          else NS = STOP_BIT;
      end
      PARITY: begin
        baudgen_en = 1'b1;
        if (bit_done) begin
          if (parity_bit != reg_rx_sync[2]) set_error = 1'b1;
          NS = STOP_BIT;
        end
      end
      STOP_BIT: begin
        baudgen_en = 1'b1;
        if (bit_done) begin
          // Should add support for stop bit configuration
          NS = IDLE;
        end
      end
      default: NS = IDLE;
    endcase
  end

//`include "reg_{Reg_name}.vs" // Size, Reset Value, Reg_reset, Reg_enable, Reg_next"
  `include "reg_uart_rx.vs" /*
    parity_bit, 1, 1'b0, , bit_done, _next
    reg_data, 8, 8'hFF, , sampleData, _next
    bit_count, 3, 0, , , _next
    CS, 3, IDLE, ~cfg_en_i, , SNS
  */

  assign s_rx_fall = ~reg_rx_sync[1] & reg_rx_sync[2];
  `include "reg_rx_sync.vs" // 3, 3'b111, ~cfg_en_i, , {reg_rx_sync[1:0],rx_i}

  assign not_started = (~start_bit & (baud_cnt == cfg_div_i));
  assign end_receiving = (start_bit & (baud_cnt == {1'b0, cfg_div_i[15:1]}));
  assign not_in_transmission = not_started | end_receiving;
  assign bit_done_r = baudgen_en & (~not_in_transmission);
  assign baud_cnt_r = baudgen_en & (not_in_transmission);
  `include "reg_bit_done.vs"  // 1, 0, _r, , 1'b1
  `include "reg_baud_cnt.vs"  // 16, 0, _r, , baud_cnt+1

  `include "reg_err_o.vs" // 1, 0, err_clr_i, set_error, 1'b1

  assign rx_data_o = reg_data;

endmodule
