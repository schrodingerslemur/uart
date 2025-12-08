module uart_tx #(
    parameter BAUD_RATE = 9600,
    parameter CLOCK_FREQ = 50000000,
    parameter DATA_BITS = 8
)
(
    input  logic clock, reset,
    input  logic [DATA_BITS-1:0] tx_data,
    input  logic tx_send,
    output logic tx_busy,
    output logic tx
);  

    // Local parameters
    localparam int BIT_CYCLES = CLOCK_FREQ / BAUD_RATE;

    // Registers
    int clock_count, bit_count;

    // Status signals
    logic FULL_BIT;
    assign FULL_BIT = (clock_count == BIT_CYCLES);

    logic TX_COMPLETE;
    assign TX_COMPLETE = (bit_count == DATA_BITS-1);

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
        if (reset) begin
            tx_busy <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    clock_count <= 0;
                    bit_count <= 0;
                    tx_busy <= 0;
                    tx <= 1;
                    if (tx_send) 
                        state <= START;
                    else
                        state <= IDLE;
                end

                START: begin
                    tx_busy <= 1;
                    tx <= 0;
                    bit_count <= 0;
                    if (FULL_BIT) begin
                        clock_count <= 0;
                        state <= DATA;
                    end
                    else begin
                        clock_count <= clock_count + 1;
                        state <= START;
                    end
                end

                DATA: begin
                    tx_busy <= 1;
                    if (FULL_BIT) begin
                        clock_count <= 0;
                        tx <= tx_data[bit_count];

                        if (TX_COMPLETE) begin
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
                    tx_busy <= 1;
                    if (FULL_BIT) begin
                        tx <= 1;
                        state <= IDLE;
                    end
                    else begin
                        tx <= 1;
                        clock_count <= clock_count + 1;
                        state <= STOP;
                    end
                end
            endcase
        end
        
    end



endmodule: uart_tx