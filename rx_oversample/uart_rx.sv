module uart_rx #(
  parameter CLK_FREQ = 100_000_000, // 100 MHZ
            BAUD_RATE = 115200,
            DATA_WIDTH = 8,
            OVERSAMPLE = 16
)(
  input  logic clock, reset, 
  input  logic rx,
  output logic [DATA_WIDTH-1:0] rx_data,
  output logic rx_valid
);

  localparam int CLKS_PER_SAMPLE = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

  // Parameters ---
  /*
  1) clk_count (clock after last sample) up to CLKS_PER_SAMPLE-1
  2) logic sample (1 when sampling) when clk_count == CLKS_PER_SAMPLE-1
  3) sample_count (number of samples) up to OVERSAMPLE - 1
  4) mid_bit when sample == OVERSAMPLE/2 -1 

  5) bit_count (up till 8)
  6) shift_reg (to store received data)
  */

  // Oversampling ---
  logic [$clog2(CLKS_PER_SAMPLE)-1:0] clk_count;
  logic [$clog2(OVERSAMPLE)-1:0] sample_count;
  logic sample, mid_bit, full_bit, done;

  // Data ---
  logic [$clog2(DATA_WIDTH)-1:0] bit_count;

  // Control points
  controlPoints_t cPts;

  rx_datapath #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .DATA_WIDTH(DATA_WIDTH),
    .OVERSAMPLE(OVERSAMPLE)
  ) dp
  (
    .data_in(rx),
    .data_out(rx_data),
    .*
  );

  rx_fsm fsm
  (
    .*
  );

endmodule: uart_rx
