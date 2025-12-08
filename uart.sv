module uart #(
    parameter BAUD_RATE   = 9600,
    parameter CLOCK_FREQ  = 50000000,
    parameter DATA_BITS   = 8,
)
  ( input  logic        clock,
    input  logic        rst,

    // TX user interface
    input  logic [DATA_BITS-1:0]  tx_data,
    input  logic        tx_send,
    output logic        tx_busy,

    // RX user interface
    output logic [DATA_BITS-1:0]  rx_data,
    output logic        rx_valid,

    // UART physical pins
    input  logic        rx,     // UART RX pin
    output logic        tx      // UART TX pin
);
  // 8 data bits, no parity, 1 stop bit

  uart_rx #(
    .BAUD_RATE   (BAUD_RATE),
    .CLOCK_FREQ  (CLOCK_FREQ),
    .DATA_BITS   (DATA_BITS)
  )
  rx_inst (.*);

  uart_tx #(
    .BAUD_RATE   (BAUD_RATE),
    .CLOCK_FREQ  (CLOCK_FREQ),
    .DATA_BITS   (DATA_BITS)
  ) 
  tx_inst (.*);

endmodule: uart

