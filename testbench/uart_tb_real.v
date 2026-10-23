
`timescale 1ns/1ps

module uart_tb_real;

    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;

    wire tx_serial;
    wire tx_busy;
    wire tx_done;
    wire [7:0] rx_data;
    wire rx_valid;

    integer pass_count;
    integer fail_count;

    uart_top #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(9600)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_serial(tx_serial),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // 100 MHz clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task send_and_check;
        input [7:0] test_byte;
        integer cycles;
        reg received;
        begin
            received = 1'b0;
            cycles = 0;

            wait (tx_busy == 1'b0);

            @(negedge clk);
            tx_data = test_byte;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            // Wait for receiver with a per-byte timeout.
            while ((received == 1'b0) && (cycles < 120000)) begin
                @(negedge clk);
                cycles = cycles + 1;

                if (rx_valid === 1'b1) begin
                    received = 1'b1;

                    if (rx_data === test_byte) begin
                        $display("PASS: Sent=%02h Received=%02h",
                                 test_byte, rx_data);
                        pass_count = pass_count + 1;
                    end else begin
                        $display("FAIL: Sent=%02h Received=%02h",
                                 test_byte, rx_data);
                        fail_count = fail_count + 1;
                    end
                end
            end

            if (received == 1'b0) begin
                $display("TIMEOUT: Byte %02h was not received",
                         test_byte);
                fail_count = fail_count + 1;
            end

            repeat (5) @(negedge clk);
        end
    endtask

    initial begin
        rst = 1'b1;
        tx_start = 1'b0;
        tx_data = 8'h00;
        pass_count = 0;
        fail_count = 0;

        // Reset
        repeat (5) @(negedge clk);
        rst = 1'b0;

        // Test five different data patterns
        send_and_check(8'hA5);
        send_and_check(8'h3C);
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'h81);

        $display("====================================");
        $display("REAL SETTINGS UART TEST SUMMARY");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);

        if ((pass_count == 5) && (fail_count == 0))
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $display("====================================");
        $finish;
    end

    // Global timeout
    initial begin
        #70000000;
        $display("ERROR: Global simulation timeout");
        $finish;
    end

endmodule
