
module uart_rx #(
    parameter integer CLKS_PER_BIT = 10416
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_serial,
    output reg  [7:0] rx_data,
    output reg        rx_valid
);

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0] state;
    reg [31:0] clock_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            clock_count <= 0;
            bit_index   <= 0;
            data_reg    <= 0;
            rx_data     <= 0;
            rx_valid    <= 0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                IDLE: begin
                    clock_count <= 0;
                    bit_index   <= 0;

                    if (rx_serial == 1'b0) begin
                        state       <= START;
                        clock_count <= 0;
                    end
                end

                START: begin
                    // Sample the start bit near its center.
                    if (clock_count == (CLKS_PER_BIT / 2) - 1) begin
                        clock_count <= 0;

                        if (rx_serial == 1'b0) begin
                            state <= DATA;
                        end else begin
                            // False start: line returned high.
                            state <= IDLE;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                DATA: begin
                    // Sample each data bit at its center.
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        clock_count <= 0;
                        data_reg[bit_index] <= rx_serial;

                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        clock_count <= 0;
                        state <= IDLE;

                        if (rx_serial == 1'b1) begin
                            rx_data  <= data_reg;
                            rx_valid <= 1'b1;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                default: begin
                    state       <= IDLE;
                    clock_count <= 0;
                    bit_index   <= 0;
                end
            endcase
        end
    end
endmodule