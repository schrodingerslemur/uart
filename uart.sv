module uart #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input  logic        clk,
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
  logic rx_en, rx_rst;
  rx_datapath rx_dp (.*);

  rx_control rx_c (.*);

endmodule: uart

module rx_control
  (input  logic rx, clock, rst,
   output logic rx_en, rx_valid, rx_rst
  );

  enum logic [1:0] {}

  // states
  // 1. Waiting for start bit,
  // 2. read 8 
endmodule: rx_control

module rx_datapath
  (input  logic rx_en, rx,
                clock, rx_rst,
   output logic [7:0] rx_data);

  // 1 if MSB first, 0 if LSB first
  assign left = 1'b0; // change if required

  ShiftRegisterSIPO data #(8) (
    .en(rx_en),
    .serial(rx), // rx_in
    .Q(rx_data),
    .left,
    .clock,
    .rx_rst
  );

endmodule: rx_datapath