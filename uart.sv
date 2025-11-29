module uart #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input  logic        clock,
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
  logic rx_en, rx_rst,
        rx_count_up, rx_count_clr;
  logic [3:0] rx_count;

  rx_datapath rx_dp (.*);
  rx_control rx_c (.*);

endmodule: uart

module rx_control
  (input  logic rx, clock, rst,
   input  logic [3:0] rx_count,
   output logic rx_en, rx_valid, rx_rst,
                rx_count_up, rx_count_clr
  );

  enum logic [1:0] {
    IDLE,
    START,
    DATA
  } state, nextState;

  // states
  // 1. Waiting for start bit,
  // 2. read 8 times

endmodule: rx_control

module rx_datapath
  (input  logic rx_en, rx,
                rx_rst,
                rx_count_up,
                rx_count_clr,
                clock,
   output logic [7:0] rx_data,
   output logic [3:0] rx_count);

  // 1 if MSB first, 0 if LSB first
  logic left;
  assign left = 1'b0; // change if required

  ShiftRegisterSIPO #(8) data (
    .en(rx_en),
    .serial(rx), // rx_in
    .Q(rx_data),
    .left,
    .clock,
    .reset(rx_rst)
  );

  logic up, load;
  assign {up, load} = {1'b1, 1'b0};

  Counter #(4) count (
    .en(rx_count_up),
    .clear(rx_count_clr),
    .up,
    .load,
    .clock,
    .D(),
    .Q(rx_count)
  );

endmodule: rx_datapath