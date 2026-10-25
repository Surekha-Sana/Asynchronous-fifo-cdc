`timescale 1ns / 1ps

module Asyncfifo_tb;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 3;
    parameter DEPTH = (1 << ADDR_WIDTH);

    reg rst_n;

    reg wr_clk;
    reg rd_clk;

    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] wr_data;

    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;

    integer i;
    reg [DATA_WIDTH-1:0] observed;

    // Device under test
    Async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .rst_n(rst_n),
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    // Write clock: 100 MHz
    initial begin
        wr_clk = 1'b0;
        forever #5 wr_clk = ~wr_clk;
    end

    // Read clock: approximately 71.43 MHz
    initial begin
        rd_clk = 1'b0;
        #1;
        forever #7 rd_clk = ~rd_clk;
    end

    // Write one word
    task write_word;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge wr_clk);
            wr_data = data;
            wr_en = 1'b1;

            @(posedge wr_clk);
            #1;
            wr_en = 1'b0;
        end
    endtask

    // Read one word and check its value
    task read_and_check;
        input [DATA_WIDTH-1:0] expected;
        begin
            // Wait for synchronized write-pointer update
            while (empty)
                @(negedge rd_clk);

            // Sample data before the read pointer advances
            @(negedge rd_clk);
            observed = rd_data;

            if (observed !== expected) begin
                $display(
                    "FAIL: Expected %h, received %h at time %0t",
                    expected, observed, $time
                );
                $finish;
            end

            rd_en = 1'b1;
            @(posedge rd_clk);
            #1;
            rd_en = 1'b0;

            $display(
                "PASS: Read data = %h at time %0t",
                observed, $time
            );
        end
    endtask

    // Test sequence
    initial begin
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = {DATA_WIDTH{1'b0}};

        // Reset
        #20;
        rst_n = 1'b1;

        // Allow reset release and clock activity
        repeat (3) @(negedge wr_clk);

        if (empty !== 1'b1) begin
            $display("FAIL: FIFO should initially be empty");
            $finish;
        end

        $display("PASS: FIFO reset and empty check");

        // Fill the FIFO with eight words
        for (i = 0; i < DEPTH; i = i + 1)
            write_word(i + 8'h10);

        #1;

        if (full !== 1'b1) begin
            $display("FAIL: FIFO did not assert full");
            $finish;
        end

        $display("PASS: FIFO full check");

        // Attempt an extra write while full
        write_word(8'hEE);
        #1;

        if (full !== 1'b1) begin
            $display("FAIL: Full flag unexpectedly cleared");
            $finish;
        end

        $display("PASS: Full protection check");

        // Read and verify all eight original words
        for (i = 0; i < DEPTH; i = i + 1)
            read_and_check(i + 8'h10);

        // Allow empty flag to settle
        repeat (4) @(negedge rd_clk);

        if (empty !== 1'b1) begin
            $display("FAIL: FIFO did not assert empty");
            $finish;
        end

        $display("PASS: FIFO empty check");

        // Attempt a read while empty
        @(negedge rd_clk);
        rd_en = 1'b1;

        @(posedge rd_clk);
        #1;
        rd_en = 1'b0;

        if (empty !== 1'b1) begin
            $display("FAIL: Empty protection check");
            $finish;
        end

        $display("PASS: Empty protection check");
        $display("==================================");
        $display("ALL FIFO TESTS PASSED");
        $display("==================================");

        $finish;
    end

    // Simulation timeout
    initial begin
        #5000;
        $display("FAIL: Simulation timeout");
        $finish;
    end

endmodule
