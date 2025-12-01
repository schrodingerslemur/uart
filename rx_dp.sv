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
  output logic sample, midbit
);

  localparam int CLKS_PER_SAMPLE = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

  // Control points
  assign {clk_en, clk_clr} = cPts.clk_ctrl;
  assign {sample_en, sample_clr} = cPts.sample_ctrl;
  assign {bit_en, bit_clr} = cPts.bit_ctrl;
  assign {data_en, data_clr} = cPts.data_ctrl;

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

  // SIPO register for rx
  ShiftRegisterSIPO #(DATA_WIDTH) (
    .en(data_en),
    .reset(data_clr),
    .serial(data_in),
    .Q(data_out),
    .left(1'b1), // LSB first
    .clock
  );

  // Logic for sample and mid_bit
  assign sample = (clk_count == CLKS_PER_SAMPLE - 1);
  assign mid_bit = (sample_count == (OVERSAMPLE/2) - 1);

endmodule: rx_datapath