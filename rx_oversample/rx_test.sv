module rx_test();
  // Clock = 100 Hz → period = 10 ms
  // Baud = 2 Hz → bit time = 0.5 s = 500 ms

  // UART interface signals
  logic clock, rst;
  logic rx;
  logic [7:0] rx_data;
  logic       rx_valid;

  // Instantiate UART DUT
  uart_rx 
  #(
    .CLK_FREQ(100),      // 100 Hz
    .BAUD_RATE(2),       // 2 bps
    .DATA_WIDTH(8),
    .OVERSAMPLE(16)
  )
  DUT
  (
    .clock     (clock),
    .reset     (rst),
    .rx        (rx),
    .rx_data   (rx_data),
    .rx_valid  (rx_valid)
  );

  // Store received data
  logic [7:0] received_data;
  always_ff @(posedge clock)
    if (rx_valid)
      received_data <= rx_data;

  // Generate 100 Hz clock → period = 10 ms → half-period = 5 ms
  initial begin
    clock = 0;
    forever #5000_000 clock = ~clock; // 5,000,000 ns = 5 ms
  end

  // Bit time in clock cycles
  localparam integer BIT_TIME_CLKS = 50; // 500 ms / 10 ms per clock = 50 clocks per UART bit

  // UART sender task using clock cycles
  task send_uart_byte(input byte b);
    integer i, j;
    begin
      // Start bit
      rx = 0;
      for (j = 0; j < BIT_TIME_CLKS; j = j + 1) @(posedge clock);

      // Data bits
      for (i = 0; i < 8; i = i + 1) begin
        rx = b[i];
        for (j = 0; j < BIT_TIME_CLKS; j = j + 1) @(posedge clock);
      end

      // Stop bit
      rx = 1;
      for (j = 0; j < BIT_TIME_CLKS; j = j + 1) @(posedge clock);
    end
  endtask

  // Test sequence
  initial begin
    rst = 1;
    rx  = 1;       // Idle state
    @(posedge clock);
    rst = 0;

    // Monitor UART signals
    $monitor("Time: %0t | rx:%b | rx_data: %b | rx_valid: %b | received_data: %h",
              $time, rx, rx_data, rx_valid, received_data);

    // Send bytes
    send_uart_byte(8'hA5); // 10100101
    send_uart_byte(8'h3C); // 00111100

    // Finish simulation
    #1000;
    $finish;
  end

endmodule
