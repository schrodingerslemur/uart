module uart_full_tb;

  // Parameters
  localparam CLOCK_FREQ = 50_000_000;
  localparam BAUD_RATE  = 9600;
  localparam DATA_BITS  = 8;

  localparam CLK_PERIOD = 20;  // 50 MHz clock

  // DUT signals
  logic clock, reset;

  logic [DATA_BITS-1:0] tx_data;
  logic                  tx_send;
  logic                  tx_busy;

  logic [DATA_BITS-1:0] rx_data;
  logic                  rx_valid;

  // UART pins (loopback)
  wire tx;
  wire rx = tx;

  // Instantiate DUT
  uart #(
    .BAUD_RATE  (BAUD_RATE),
    .CLOCK_FREQ (CLOCK_FREQ),
    .DATA_BITS  (DATA_BITS)
  ) dut (
    .clock    (clock),
    .reset    (reset),
    .tx_data  (tx_data),
    .tx_send  (tx_send),
    .tx_busy  (tx_busy),
    .rx_data  (rx_data),
    .rx_valid (rx_valid),
    .rx       (rx),
    .tx       (tx)
  );

  // Clock generation
  initial begin
    $monitor("rx_valid=%b rx_data=0x%0h", rx_valid, rx_data);
    // $monitor("Time: %0t | reset=%b | tx_send=%b | tx_busy=%b | rx_valid=%b | tx_data=0x%0h | rx_data=0x%0h | tx_state=%s | rx_state=%s", 
            //   $time, reset, tx_send, tx_busy,  rx_valid, tx_data, rx_data, dut.tx_inst.state.name() , dut.rx_inst.state.name() );
    clock = 0;
    forever #(CLK_PERIOD/2) clock = ~clock;
  end

  // Task to send a byte and verify loopback
  task send_and_check(input [7:0] b);
    begin
      @(posedge clock);
      tx_data = b;
      tx_send = 1;

      @(posedge clock);
      tx_send = 0;

      // Wait for TX to finish
      $display("Sending byte: 0x%0h", b);
      wait (tx_busy);
      // Wait for RX to assert valid
      $display("Waiting for RX valid...");
      wait (rx_valid == 1);
      $display("TX busy...");
      wait (!tx_busy);




      $display("Received byte: 0x%0h", rx_data);

      if (rx_data == b)
        $display("PASS: Sent 0x%0h, Received 0x%0h", b, rx_data);
      else
        $display("FAIL: Sent 0x%0h, Received 0x%0h", b, rx_data);
    end
  endtask

  // Main test
  initial begin
    $display("=== UART Full Loopback Test Start ===");

    // Reset
    reset     = 1;
    tx_send = 0;
    tx_data = 0;

    #200;
    reset = 0;

    // Send a set of bytes
    send_and_check(8'h55);

    $display("=== UART Full Loopback Test Complete ===");
    #10000;
    $finish;
  end

endmodule
