module rx_test();

  // UART interface signals
  logic clock, rst;
  logic rx;
  logic [7:0] rx_data;
  logic       rx_valid;

  logic [7:0] tx_data = 0;
  logic       tx_send = 0;
  logic       tx_busy;
  logic       tx;

  // Instantiate UART DUT
  uart_rx DUT (
    .clock     (clock),
    .rst       (rst),
    .rx        (rx),
    .rx_data   (rx_data),
    .rx_valid  (rx_valid)
  );

  // Store received data
  logic [7:0] received_data;
  always_ff @(posedge clock)
    if (rx_valid)
      received_data <= rx_data;

  // Generate 100 MHz clock
  initial begin
    clock = 0;
    forever #5 clock = ~clock; // 10 ns period -> 100 MHz
  end

  // Bit time in clock cycles for 115200 baud at 100 MHz
  localparam integer BIT_TIME_CLKS = 868;

  // UART sender task using clock cycles
  task send_uart_byte(input byte b);
    integer i, j;
    begin
      // Start bit
      rx <= 0;
      for (j = 0; j < BIT_TIME_CLKS; j = j + 1) @(posedge clock);

      // Data bits
      for (i = 0; i < 8; i = i + 1) begin
        rx <= b[i];
        for (j = 0; j < BIT_TIME_CLKS; j = j + 1) @(posedge clock);
      end

      // Stop bit
      rx <= 1;
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
