module rx_fsm (
  input  logic clock, reset,
  input  logic rx,
  input  logic sample, mid_bit, full_bit, done,
  output controlPoints_t cPts,
  output logic rx_valid
);

  enum logic [2:0] {
    IDLE, START, START_BUF, DATA, STOP
  } state, nextState;

  // Control points: cPts, receiving
  // Status points: sample, mid_bit, full_bit, done
  
  always_comb begin
    case (state)
      IDLE: begin
        rx_valid = 0;
        cPts.bit_ctrl = CLR;
        cPts.data_ctrl = RST;
        cPts.clk_ctrl = CLR;
        cPts.sample_ctrl = CLR;

        if (rx == 1'b0) begin
          nextState = START;
        end
        else begin
          nextState = IDLE;
        end
      end

      START: begin
        rx_valid = 0;
        cPts.bit_ctrl = CLR;
        cPts.data_ctrl = RST;

        if (mid_bit) begin
          if (rx == 0) begin
            cPts.clk_ctrl = CLR;
            cPts.sample_ctrl = CLR;
            nextState = DATA;
          end
          else begin
            cPts.clk_ctrl = CLR;
            cPts.sample_ctrl = CLR;
            nextState = IDLE;
          end
        end

        else if (sample) begin
          cPts.clk_ctrl = CLR;
          cPts.sample_ctrl = INC;

          nextState = START;
        end

        else begin
          cPts.clk_ctrl = INC;
          cPts.sample_ctrl = NO;

          nextState = START;
        end
      end

      START_BUF: begin
        rx_valid = 0;
        cPts.bit_ctrl = CLR;
        cPts.data_ctrl = RST;

        if (mid_bit) begin
          cPts.clk_ctrl = CLR;
          cPts.sample_ctrl = CLR;
          nextState = DATA;
        end

        else if (sample) begin
          cPts.clk_ctrl = CLR;
          cPts.sample_ctrl = INC;
          nextState = START_BUF;
        end

        else begin
          cPts.clk_ctrl = INC;
          cPts.sample_ctrl = NO;
          nextState = START_BUF;
        end
      end

      DATA: begin
        rx_valid = 0;

        if (done) begin
          cPts.clk_ctrl = CLR;
          cPts.sample_ctrl = CLR;
          cPts.bit_ctrl = NO;
          cPts.data_ctrl = NONE;
          nextState = STOP;
        end

        else if (sample) begin
          if (mid_bit) begin
            cPts.bit_ctrl = INC;
            cPts.data_ctrl = SHIFT;
          end
          else begin
            cPts.bit_ctrl = NO;
            cPts.data_ctrl = NONE;
          end
          cPts.clk_ctrl = CLR;
          cPts.sample_ctrl = INC;
          nextState = DATA;
        end

        else begin
          cPts.clk_ctrl = INC;
          cPts.sample_ctrl = NO;
          cPts.bit_ctrl = NO;
          cPts.data_ctrl = NONE;
          nextState = DATA;
        end
      end

      STOP: begin
        if (mid_bit) begin
          if (rx == 1'b1) begin
            rx_valid = 1;
            cPts.clk_ctrl = CLR;
            cPts.sample_ctrl = CLR;
            cPts.bit_ctrl = CLR;
            cPts.data_ctrl = NONE;
            nextState = IDLE;
          end
          else begin
            rx_valid = 0;
            cPts.clk_ctrl = CLR;
            cPts.sample_ctrl = CLR;
            cPts.bit_ctrl = CLR;
            cPts.data_ctrl = NONE;
            nextState = IDLE;
          end
        end

        else if (sample) begin
          cPts.clk_ctrl = CLR;
          cPts.sample_ctrl = INC;
          cPts.bit_ctrl = NO;
          cPts.data_ctrl = NONE;
          rx_valid = 0;
          nextState = STOP;
        end

        else begin
          cPts.clk_ctrl = INC;
          cPts.sample_ctrl = NO;
          cPts.bit_ctrl = NO;
          cPts.data_ctrl = NONE;
          rx_valid = 0;
          nextState = STOP;
        end
      end
    
      default: begin
        rx_valid = 0;
        cPts.bit_ctrl = CLR;
        cPts.data_ctrl = RST;
        cPts.clk_ctrl = CLR;
        cPts.sample_ctrl = CLR;
        nextState = IDLE;
      end

    endcase
  end

  always_ff @(posedge clock, posedge reset)
    if (reset) 
      state <= IDLE;
    else 
      state <= nextState;

endmodule: rx_fsm