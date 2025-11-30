`define FPGA_CLK 100_000_000
`define BAUD 115200
`define OVERSAMPLE 16

module uart
  ( input  logic        clock,
    input  logic        rst,

    // TX user interface
    input  logic [7:0]  tx_data,
    input  logic        tx_send,
    output logic        tx_busy,

    // RX user interface
    output logic [7:0]  rx_data,
    output logic        rx_valid,

    // UART physical pins
    input  logic        rx,     // UART RX pin
    output logic        tx      // UART TX pin
);
  // 8 data bits, no parity, 1 stop bit

  // receiving
  logic rx_en, rx_clr,
        rx_count_up, rx_count_clr,
        sample_count_up, sample_count_clr,
        clock_count_up, clock_count_clr;
  logic sample;
  logic [3:0] rx_count;
  logic [$clog2(`OVERSAMPLE)-1:0] sample_count;

  rx_datapath rx_dp (.*);
  rx_control rx_c (.*);

endmodule: uart

// up, clr
typedef enum logic [1:0] {
  INC_RX = 2'b10,
  NO_RX = 2'b00,
  CLR_RX = 2'b01
} rx_count_t;

typedef enum logic [1:0] {
  INC_CLK = 2'b10,
  NO_CLK = 2'b00,
  CLR_CLK = 2'b01
} clock_count_t;

typedef enum logic [1:0] {
  INC_SMP = 2'b10,
  NO_SMP = 2'b00,
  CLR_SMP = 2'b01
} sample_count_t;

typedef enum logic [1:0] {
  SHIFT_DATA = 2'b10,
  NO_DATA = 2'b00,
  CLR_DATA = 2'b01
} rx_data_t;

typedef enum logic {
  VALID = 1'b1,
  INVALID = 1'b0
} rx_valid_t;

typedef struct packed {
  rx_count_t rx_control;
  clock_count_t clock_control;
  sample_count_t sample_control;
  rx_data_t shift_control;
  rx_valid_t valid_control;
} controlPts;

module rx_control
  (input  logic rx, clock, rst,
   input  logic sample, 
   input  logic [3:0] rx_count,
   input  logic [$clog2(`OVERSAMPLE)-1:0] sample_count,
   output logic rx_en, rx_valid, rx_clr,
                rx_count_up, rx_count_clr,
                clock_count_up, clock_count_clr,
                sample_count_up, sample_count_clr
  );

  enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state, nextState;

  // states
  // sample 16 times per baud
  // 1. Waiting for start bit,
  // 2. read 8 times
  controlPts cPts;
  assign {
    rx_count_up, rx_count_clr,
    clock_count_up, clock_count_clr,
    sample_count_up, sample_count_clr,
    rx_en, rx_clr, rx_valid
  } = cPts;

  // next state
  always_comb begin
    case (state)
      IDLE: begin
        if (rx == 1'b0) begin
          nextState = START;
          cPts = {CLR_RX, CLR_CLK, CLR_SMP, CLR_DATA, INVALID};
        end
        else begin
          nextState = IDLE;
          cPts = {CLR_RX, CLR_CLK, CLR_SMP, CLR_DATA, INVALID};
        end
      end

      START: begin
        if (sample_count == 7) begin
          if (rx == 1'b0) begin
            // No glitch
            nextState = DATA;
            cPts = {CLR_RX, CLR_CLK, CLR_SMP, CLR_DATA, INVALID};
          end
          else begin
            // Glitch
            nextState = IDLE;
            cPts = {CLR_RX, CLR_CLK, CLR_SMP, CLR_DATA, INVALID};
          end
        end

        else if (sample) begin
          nextState = START;
          cPts = {CLR_RX, CLR_CLK, INC_SMP, CLR_DATA, INVALID};
        end

        else begin
          nextState = START;
          cPts = {CLR_RX, INC_CLK, NO_SMP, CLR_DATA, INVALID};
        end
      end

      DATA: begin
        if (rx_count == 8) begin
          nextState = STOP;
          cPts = {CLR_RX, CLR_CLK, CLR_SMP, NO_DATA, INVALID};
        end
        
        else if (sample_count == 15) begin
          nextState = DATA;
          cPts = {INC_RX, CLR_CLK, CLR_SMP, SHIFT_DATA, INVALID};
        end

        else if (sample) begin
          nextState = DATA;
          cPts = {NO_RX, CLR_CLK, INC_SMP, NO_DATA, INVALID};
        end

        else begin
          nextState = DATA;
          cPts = {NO_RX, INC_CLK, NO_SMP, NO_DATA, INVALID};
        end
      end

      STOP: begin
        if (sample_count == 7) begin
          if (rx == 1'b1) begin
            // Valid
            nextState = IDLE;
            cPts = {CLR_RX, CLR_CLK, CLR_SMP, NO_DATA, VALID};
          end
          else begin
            // Invalid
            nextState = IDLE;
            cPts = {CLR_RX, CLR_CLK, CLR_SMP, NO_DATA, INVALID};
          end
        end

        else if (sample) begin
          nextState = STOP;
          cPts = {NO_RX, CLR_CLK, INC_SMP, NO_DATA, INVALID};
        end

        else begin
          nextState = STOP;
          cPts = {NO_RX, INC_CLK, NO_SMP, NO_DATA, INVALID};
        end
      end

    endcase
  end

endmodule: rx_control

module rx_datapath
  (input  logic rx_en, rx,
                rx_clr,
                rx_count_up,
                rx_count_clr,
   input  logic clock_count_up,
                clock_count_clr,
   input  logic sample_count_up,
                sample_count_clr,
   input  logic clock,

   output logic sample,
   output logic [$clog2(`OVERSAMPLE)-1:0] sample_count, 
   output logic [7:0] rx_data,
   output logic [3:0] rx_count);

  // RX data -------------------------------
  localparam LEFT = 1'b0; // 1 if MSB first, 0 if LSB first

  ShiftRegisterSIPO #(8) rx_register (
    .en(rx_en),
    .serial(rx), // rx_in
    .Q(rx_data),
    .left(LEFT),
    .reset(rx_clr),
    .clock
  );

  // RX count -----------------------------
  Counter #(4) rx_counter (
    .en(rx_count_up),
    .clear(rx_count_clr),
    .up(1'b1),
    .load(1'b0),
    .clock,
    .D(),
    .Q(rx_count)
  );


  // RX sample count ----------------------
  localparam OVERSAMPLE = 16;

  Counter #($clog2(OVERSAMPLE)) sample_counter (
    .en(sample_count_up),
    .clear(sample_count_clr),
    .up(1'b1),
    .load(1'b0),
    .clock,
    .D(),
    .Q(sample_count)
  );

  // Clock count --------------------------
  // Counts clock cycles after last sample
  localparam OVERSAMPLE_RATE = `BAUD * OVERSAMPLE;

  int clock_count;

  Counter #(32) clock_counter (
    .en(clock_count_up),
    .clear(clock_count_clr),
    .up(1'b1),
    .load(1'b0),
    .clock,
    .D(),
    .Q(clock_count)
  );

  assign sample = (clock_count == ((`FPGA_CLK/OVERSAMPLE_RATE) - 1));

endmodule: rx_datapath