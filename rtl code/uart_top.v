
module uart_top #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,

    output wire       tx_serial,
    output wire       tx_busy,
    output wire       tx_done,

    output wire [7:0] rx_data,
    output wire       rx_valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_serial(tx_serial),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) receiver (
        .clk(clk),
        .rst(rst),
        .rx_serial(tx_serial),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

endmodule
