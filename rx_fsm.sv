module rx_fsm ();

  enum logic [1:0] {
    IDLE, START, DATA, STOP
  } state, nextState;

  logic receiving;

  // Control points: cPts, receiving
  // Status points: sample, mid_bit
  
  // FSM for clk_count and sample_count
  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      cPts.clk_ctrl <= CLR;
      cPts.sample_ctrl <= CLR;
    end

    else if (receiving) begin
      if (clk_count == CLKS_PER_SAMPLE - 1) begin
        cPts.clk_ctrl <= CLR;
        cPts.sample_ctrl <= INC;
      end
      else if (sample_count == OVERSAMPLE - 1) begin
        cPts.clk_ctrl <= CLR;
        cPts.sample_ctrl <= CLR;
      end
    end

    else begin
      cPts.clk_ctrl <= INC;
      cPts.sample_ctrl <= NO;
    end
  end

  // FSM for 


//   always_ff @(posedge clock, posedge reset)
endmodule: rx_fsm