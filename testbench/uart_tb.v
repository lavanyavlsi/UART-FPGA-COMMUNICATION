
`timescale 1ns/1ps

module uart_tb;

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

    // Fast simulation settings:
    // 1 MHz clock, 10,000 baud = 100 clocks per bit
    uart_top #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(10000)
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

    // Clock period = 1000 ns
    initial clk = 1'b0;
    always #500 clk = ~clk;

    initial begin
        rst = 1'b1;
        tx_start = 1'b0;
        tx_data = 8'h00;
        pass_count = 0;
        fail_count = 0;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        // Test byte 1
        send_byte(8'hA5);

        // Test byte 2
        send_byte(8'h3C);

        // Test byte 3
        send_byte(8'h00);

        // Test byte 4
        send_byte(8'hFF);

        // Test byte 5
        send_byte(8'h81);

        $display("==============================");
        $display("SIMPLE UART TEST SUMMARY");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);

        if ((pass_count == 5) && (fail_count == 0))
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $display("==============================");
        $finish;
    end

    task send_byte;
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

            // Wait for received data, with timeout
            while ((received == 1'b0) && (cycles < 1200)) begin
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
                $display("TIMEOUT: Byte %02h not received", test_byte);
                fail_count = fail_count + 1;
            end

            repeat (5) @(negedge clk);
        end
    endtask

    // Prevent endless simulation
    initial begin
        #100000000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

    // Save waveforms for GTKWave
    initial begin
        $dumpfile("simulation/uart_wave.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule
