module rx_datapath #(
  parameter CLK_FREQ = 100_000_000, // 100 MHZ
            BAUD_RATE = 115200,
            DATA_WIDTH = 8,
            OVERSAMPLE = 16
)
(
  input  logic clock,
  input  controlPoints_t cPts,
  input  logic data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  output logic [$clog2(CLKS_PER_SAMPLE)-1:0] clk_count,
  output logic [$clog2(OVERSAMPLE)-1:0] sample_count,
  output logic [$clog2(DATA_WIDTH)-1:0] bit_count,
  output logic sample, mid_bit, full_bit, done
);

  localparam int CLKS_PER_SAMPLE = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

  // Control points
  logic clk_en, clk_clr, sample_en, sample_clr,
        bit_en, bit_clr, data_en, data_clr;

  assign {clk_en, clk_clr} = cPts.clk_ctrl;
  assign {sample_en, sample_clr} = cPts.sample_ctrl;
  assign {bit_en, bit_clr} = cPts.bit_ctrl;
  assign {data_en, data_clr} = cPts.data_ctrl;

  // Counter for clk_count
  Counter #($clog2(CLKS_PER_SAMPLE)) clk_counter
  (
    .D(),
    .en(clk_en),
    .clear(clk_clr),
    .load(),
    .up(1'b1),
    .Q(clk_count),
    .clock
  );

  // Counter for sample_count
  Counter #($clog2(OVERSAMPLE)) sample_counter
  (
    .D(),
    .en(sample_en),
    .clear(sample_clr),
    .load(),
    .up(1'b1),
    .Q(sample_count),
    .clock
  );

  // Counter for bit_count
  Counter #($clog2(DATA_WIDTH)) bit_counter
  (
    .D(),
    .en(bit_en),
    .clear(bit_clr),
    .load(),
    .up(1'b1),
    .Q(bit_count),
    .clock
  );

  // SIPO register for rx
  ShiftRegisterSIPO #(DATA_WIDTH) data_register
  (
    .en(data_en),
    .reset(data_clr),
    .serial(data_in),
    .Q(data_out),
    .left(1'b1), // LSB first
    .clock
  ); 

  // Logic for sample and mid_bit
  localparam int CLK_CNT_W    = $clog2(CLKS_PER_SAMPLE);
  localparam int SAMPLE_CNT_W = $clog2(OVERSAMPLE);

  assign sample =
      (clk_count == CLK_CNT_W'((CLKS_PER_SAMPLE - 1)));

  assign mid_bit =
      (sample_count == SAMPLE_CNT_W'((OVERSAMPLE/2) - 1));
  
  assign full_bit =
      (sample_count == SAMPLE_CNT_W'(OVERSAMPLE - 1));

  assign done =
      (bit_count == $clog2(DATA_WIDTH)'(DATA_WIDTH - 1));


endmodule: rx_datapath