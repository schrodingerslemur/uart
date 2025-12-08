module uart_rx #(
    parameter BAUD_RATE = 9600,
    parameter CLOCK_FREQ = 50000000,
    parameter DATA_BITS = 8
)
(
    input  logic clock, reset,
    input  logic rx,
    output logic [DATA_BITS-1:0] rx_data,
    output logic rx_valid
);

// Local parameters
localparam int BIT_CYCLES = CLOCK_FREQ / BAUD_RATE; // # clock cycles per bit
localparam int HALF_BIT_CYCLES = BIT_CYCLES / 2; // # clock cycles per half bit

// Registers
int clock_count;
int bit_count;

// Status signals
logic HALF_BIT, FULL_BIT;
assign FULL_BIT = (clock_count == BIT_CYCLES);
assign HALF_BIT = (clock_count == HALF_BIT_CYCLES);

logic RX_COMPLETE;
assign RX_COMPLETE = (bit_count == DATA_BITS-1);

// States
typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
} state_t;
state_t state;

// Output and next state logic
always_ff @(posedge clock, posedge reset) begin
    rx_valid <= 0; // default

    if (reset) begin
        state <= IDLE;
    end
    else begin
        case (state) 
            IDLE: begin
                clock_count <= 0;
                bit_count <= 0;
                if (rx == 1'b0) begin
                    state <= START;
                end
                else begin
                    state <= IDLE;
                end
            end

            START: begin
                if (HALF_BIT) begin
                    if (rx == 1'b0) begin
                        clock_count <= 0;
                        bit_count <= 0;
                        state <= DATA;
                    end
                    else begin
                        state <= IDLE; // false start bit
                    end
                end
                else begin
                    clock_count <= clock_count + 1;
                    state <= START;
                end
            end

            DATA: begin
                if (FULL_BIT) begin
                    clock_count <= 0;
                    rx_data[bit_count] <= rx;

                    if (RX_COMPLETE) begin
                        state <= STOP;
                    end
                    else begin
                        bit_count <= bit_count + 1;
                        state <= DATA;
                    end
                end
                else begin
                    clock_count <= clock_count + 1;
                    state <= DATA;
                end
            end

            STOP: begin
                if (FULL_BIT) begin
                    if (rx == 1'b1) begin
                        rx_valid <= 1;
                    end
                    state <= IDLE;
                end
                else begin
                    clock_count <= clock_count + 1;
                    state <= STOP;
                end
            end
        endcase
    end
end

endmodule: uart_rx