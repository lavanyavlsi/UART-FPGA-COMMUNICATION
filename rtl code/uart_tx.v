
module uart_tx #(
    parameter integer CLKS_PER_BIT = 10416
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx_serial,
    output reg        tx_busy,
    output reg        tx_done
);

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0]  state;
    reg [7:0]  data_reg;
    reg [2:0]  bit_index;
    reg [31:0] clock_count;

    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            tx_serial   <= 1'b1;
            tx_busy     <= 1'b0;
            tx_done     <= 1'b0;
            data_reg    <= 8'h00;
            bit_index   <= 3'd0;
            clock_count <= 32'd0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                IDLE: begin
                    tx_serial   <= 1'b1;
                    tx_busy     <= 1'b0;
                    clock_count <= 32'd0;
                    bit_index   <= 3'd0;

                    if (tx_start && !tx_busy) begin
                        data_reg    <= tx_data;
                        tx_busy     <= 1'b1;
                        tx_serial   <= 1'b0;
                        clock_count <= 32'd0;
                        state       <= START;
                    end
                end

                START: begin
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        clock_count <= 32'd0;
                        bit_index   <= 3'd0;
                        tx_serial   <= data_reg[0];
                        state       <= DATA;
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        clock_count <= 32'd0;

                        if (bit_index == 3'd7) begin
                            tx_serial <= 1'b1;
                            state     <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx_serial <= data_reg[bit_index + 1'b1];
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        clock_count <= 32'd0;
                        tx_serial   <= 1'b1;
                        tx_busy     <= 1'b0;
                        tx_done     <= 1'b1;
                        state       <= IDLE;
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                default: begin
                    state       <= IDLE;
                    tx_serial   <= 1'b1;
                    tx_busy     <= 1'b0;
                    tx_done     <= 1'b0;
                    clock_count <= 32'd0;
                    bit_index   <= 3'd0;
                end
            endcase
        end
    end

endmodule
