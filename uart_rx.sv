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

  localparam int CLKS_PER_SAMPLE = ClK_FREQ / (BAUD_RATE * OVERSAMPLE);

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
  logic sample;
  logic [$clog2(OVERSAMPLE)-1:0] sample_count;
  logic mid_bit;

  // Data ---
  logic [$clog2(DATA_WIDTH)-1:0] bit_count;


endmodule: uart_rx

module rx_datapath #(
  parameter 
)
();

  // Counter for clk_count
  Counter #($clog2(CLKS_PER_SAMPLE)) (
    .D(),
    .en(clk_en),
    .clear(clk_clr),
    .load(),
    .up(1'b1),
    .Q(clk_count)
  );

  // Counter for sample_count
  Counter #($clog2(OVERSAMPLE)) (
    .D(),
    .en(sample_en),
    .clear(sample_clr),
    .load(),
    .up(1'b1),
    .Q(sample_count)
  );

  // Counter for bit_count
  Counter #($clog2(DATA_WIDTH)) (
    .D(),
    .en(bit_en),
    .clear(bit_clr),
    .load(),
    .up(1'b1),
    .Q(bit_count)
  );

  // Logic for sample and mid_bit
  assign sample = (clk_count == CLKS_PER_SAMPLE - 1);
  assign mid_bit = (sample_count == (OVERSAMPLE/2) - 1);

endmodule: rx_datapath

module rx_fsm ();

  enum logic [1:0] {
    IDLE, START, DATA, STOP
  } state, nextState;




  always_ff @(posedge clock, posedge reset)
endmodule: rx_fsm