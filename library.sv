//`default_nettype none
module Mux8to1
  #(parameter WIDTH = 10)
  (input  logic [WIDTH-1:0]I0, I1, I2, I3, I4, I5, I6, I7,
          logic [2:0]S,
   output logic [WIDTH-1:0]Y);
  always_comb begin
    case (S)
      3'd0: Y = I0;
      3'd1: Y = I1;
      3'd2: Y = I2;
      3'd3: Y = I3;
      3'd4: Y = I4;
      3'd5: Y = I5;
      3'd6: Y = I6;
      3'd7: Y = I7;
      default: Y = '0;
    endcase
  end
endmodule: Mux8to1

module Mux4to1
  #(parameter WIDTH = 10)
  (input  logic [WIDTH-1:0]I0, I1, I2, I3,
          logic [1:0]S,
   output logic [WIDTH-1:0]Y);
  always_comb begin
    case (S)
      2'd0: Y = I0;
      2'd1: Y = I1;
      2'd2: Y = I2;
      2'd3: Y = I3;
      default: Y = '0;
    endcase
  end
endmodule: Mux4to1

module OffsetCheck
  #(parameter WIDTH=4)
  (input  logic [WIDTH-1:0] val, delta, low,
   output logic is_between);
  
  logic [WIDTH-1:0] high;
  logic cout;

  Adder #(WIDTH) add1 (.A(low), .B(delta), .sum(high), .cin(1'b0), .cout);
  RangeCheck #(WIDTH) range1 (.*);

endmodule: OffsetCheck

module RangeCheck
  #(parameter WIDTH=4)
  (input  logic [WIDTH-1:0] val, high, low,
   output logic is_between);

  always_comb begin
    if ((val >= low) && (val <= high))
      is_between = 1'b1;
    else
      is_between = 1'b0;
  end

endmodule: RangeCheck

module Memory
  #(parameter WIDTH=256, DW=4, AW=$clog2(WIDTH))
  (input  logic re, we, clock,
   input  logic [AW-1:0] addr,
   inout tri [DW-1:0] data);

  logic [DW-1:0] M[WIDTH];
  logic [DW-1:0] rData;

  assign data = (re) ? rData : 'z;

  always_ff @(posedge clock)
    if (we)
      M[addr] <= data;
    
  always_comb
    rData = M[addr];

endmodule: Memory

module BusDriver
  #(parameter WIDTH = 3)
  (input  logic en, 
   input  logic [WIDTH-1:0] data,
   output logic [WIDTH-1:0] buff,
   inout  tri   [WIDTH-1:0] bus);

  assign bus = (en) ? data : 'z;
  assign buff = bus;

endmodule: BusDriver

module BarrelShiftRegister
  #(parameter WIDTH = 8)
  (input  logic en, load, clock,
   input  logic [1:0] by,
   input  logic [WIDTH-1:0] D,
   output logic [WIDTH-1:0] Q);
  
  int by_int;

  always_ff @(posedge clock)
    if (en) begin
      if (load) begin
        Q <= D;
      end
      else begin
        if (by == 0)
          Q <= Q;
        else if (by == 1)
          Q <= {Q[WIDTH-2:0], 1'b0};
        else if (by == 2)
          Q <= {Q[WIDTH-3:0], 2'b0};
        else // by == 3
        Q <= {Q[WIDTH-4:0], 3'b0};
      end
    end
endmodule: BarrelShiftRegister

module ShiftRegisterPIPO
  #(parameter WIDTH = 3)
  (input  logic en, left, load, clock,
   input  logic [WIDTH-1:0] D,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (en) begin
      if (~load) begin
        if (left)
          Q <= {Q[WIDTH-2:0], 1'b0};
        else
          Q <= {1'b0, Q[WIDTH-1:1]};
      end
      else 
        Q <= D;
    end

endmodule: ShiftRegisterPIPO

module ShiftRegisterSIPO
  #(parameter WIDTH = 3)
  (input  logic en, left, serial, clock, reset,
   output logic [WIDTH-1:0] Q);
  
  always_ff @(posedge clock)
    if (reset) begin
      Q <= '0;
    end
    else if (en) begin
      if (left)
        Q <= {Q[WIDTH-2:0], serial};
      else
        Q <= {serial, Q[WIDTH-1:1]};
    end
      
endmodule: ShiftRegisterSIPO

module Synchronizer 
  #(parameter WIDTH = 3)
  (input  logic async, clock,
   output logic sync);
  
  logic inter, reset_L, preset_L;

  assign reset_L = 1'b1;
  assign preset_L = 1'b1;

  DFlipFlop D1 (.D(async), .Q(inter), .* );
  DFlipFlop D2 (.D(inter), .Q(sync), .* );

endmodule: Synchronizer

module Counter
  #(parameter WIDTH = 3)
  (input  logic en, clear, load, up, clock,
   input  logic [WIDTH-1:0] D,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (clear)
      Q <= '0;
    else if (load)
      Q <= D;
    else if (en)
      Q <= (up) ? Q+1 : Q-1;

endmodule: Counter

module Register
  #(parameter WIDTH = 3)
  (input  logic en, clear, clock,
   input  logic [WIDTH-1:0] D,
   output logic [WIDTH-1:0] Q);
  
  always_ff @(posedge clock)
    if (clear)
      Q <= '0;
    else if (en)
      Q <= D;

endmodule: Register

module DFlipFlop
  (input  logic D, clock, reset_L, preset_L,
   output logic Q);

  always_ff @(posedge clock, negedge reset_L, negedge preset_L)
    if (~reset_L)
      Q <= 1'b0;
    else if (~preset_L)
      Q <= 1'b1;
    else
      Q <= D;

endmodule: DFlipFlop

module Adder
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0] A, B, 
   input  logic cin,
   output logic [WIDTH-1:0] sum,
   output logic cout);
  
  logic [WIDTH:0] full_sum;
  
  always_comb begin
    full_sum = A + B + cin;
    sum = full_sum[WIDTH-1:0];
    cout = full_sum[WIDTH];
  end 

endmodule: Adder

module Subtracter
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0] A, B, 
   input  logic bin,
   output logic [WIDTH-1:0] diff,
   output logic bout);
  
  logic [WIDTH:0] full_diff;
  
  always_comb begin
    full_diff = A - B - bin;
    diff = full_diff[WIDTH-1:0];
    bout = full_diff[WIDTH];
  end

endmodule: Subtracter

module Decoder
  #(parameter WIDTH = 8)
  (input  logic [$clog2(WIDTH)-1:0]I, 
          logic en,
   output logic [WIDTH-1:0]D);

  always_comb begin
    D = '0;
    if (en)
      D[I] = 1'b1;
  end

endmodule: Decoder

module Multiplexer
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0]I, 
          logic [$clog2(WIDTH)-1:0]S,
   output logic Y);

  always_comb begin
    Y = I[S];
  end

endmodule: Multiplexer

module Mux2to1
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0]I0, 
          logic [WIDTH-1:0]I1, 
          logic S,
   output logic [WIDTH-1:0]Y);

  always_comb begin
    Y = S ? I1 : I0;
  end

endmodule: Mux2to1

module MagComp
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0]A, [WIDTH-1:0]B,
   output logic AltB, AeqB, AgtB);
  
  always_comb begin
    AltB = 0;
    AeqB = 0;
    AgtB = 0;
    if (A < B) 
      AltB = 1;
    else if (A == B)
      AeqB = 1;
    else
      AgtB = 1;
  end

endmodule: MagComp

module Comparator
  #(parameter WIDTH = 4)
  (input  logic [WIDTH-1:0]A, [WIDTH-1:0]B,
   output logic AeqB);

   always_comb begin
    if (A==B)
      AeqB = 1;
    else
      AeqB = 0;
   end

endmodule: Comparator