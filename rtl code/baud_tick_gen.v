
module baud_tick_gen #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input  wire clk,
    input  wire rst,
    output reg  baud_tick
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam integer COUNTER_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    reg [COUNTER_WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter   <= 0;
            baud_tick <= 1'b0;
        end
        else begin
            if (counter == CLKS_PER_BIT - 1) begin
                counter   <= 0;
                baud_tick <= 1'b1;
            end
            else begin
                counter   <= counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
