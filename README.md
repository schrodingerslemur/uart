# UART implementation
UART RX and TX implementation in System Verilog.

Customizable parameters:
1) Hardware clock frequency
2) Baud rate
3) Number of data bits

The implementation assumes no parity bit, a logic-low start bit, and logic-high start bit.

## Usage
Instantiate `uart` module using following description: 
```sverilog
module uart #(
    parameter BAUD_RATE   = 9600,
    parameter CLOCK_FREQ  = 50000000,
    parameter DATA_BITS   = 8
)
(   input  logic        clock,
    input  logic        reset,

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
```

The module uses a READY-VALID handshake protocol
