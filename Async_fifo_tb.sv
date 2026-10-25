`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 10:19:54 PM
// Design Name: 
// Module Name: Async_fifo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Async_fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 3;
    localparam DEPTH      = (1 << ADDR_WIDTH);
    localparam NUM_CYCLES = 2000;

    reg rst_n = 0;

    reg wr_clk = 0;
    reg rd_clk = 0;

    reg wr_en = 0;
    reg rd_en = 0;
    reg [DATA_WIDTH-1:0] wr_data = 0;

    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;

    integer accepted_writes = 0;
    integer accepted_reads  = 0;
    integer errors          = 0;
  

    // Reference model: expected FIFO contents
    reg [DATA_WIDTH-1:0] expected_q[0:9999];
      integer q_write = 0;
    integer q_read = 0;
    
    Async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .rst_n   (rst_n),
        .wr_clk  (wr_clk),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .full    (full),
        .rd_clk  (rd_clk),
        .rd_en   (rd_en),
        .rd_data (rd_data),
        .empty   (empty)
    );

    // Independent clocks
    always #5 wr_clk = ~wr_clk;  // 100 MHz

    initial begin
        #1;
        forever #7 rd_clk = ~rd_clk; // ~71.43 MHz
    end

    // Release reset away from the active clock edges
    initial begin
        repeat (4) @(negedge wr_clk);
        rst_n = 1;
    end

    // Random write requests and data
    initial begin
        wait (rst_n == 1);

        repeat (NUM_CYCLES) begin
            @(negedge wr_clk);

            wr_en   = ($urandom_range(0, 99) < 65);
            wr_data = $urandom_range(0, 255);
        end

        @(negedge wr_clk);
        wr_en = 0;
    end

    // Random read requests
    initial begin
        wait (rst_n == 1);

        repeat (NUM_CYCLES) begin
            @(negedge rd_clk);

            rd_en = ($urandom_range(0, 99) < 60);
        end

        @(negedge rd_clk);
        rd_en = 0;
    end

    // Scoreboard: record accepted writes
    always @(posedge wr_clk) begin
        if (rst_n && wr_en && !full) begin
            expected_q[q_write] = wr_data;
            q_write = q_write + 1;
            accepted_writes = accepted_writes + 1;
        end
    end

    // Scoreboard: verify accepted reads
    // Compare before the DUT advances its read pointer via NBA.
    always @(posedge rd_clk) begin
    if (rst_n && rd_en && !empty) begin

        if (q_read >= q_write) begin
            $display("FAIL: No expected data available");
            errors = errors + 1;
        end
        else if (rd_data !== expected_q[q_read]) begin
            $display(
                "FAIL: Expected %h, got %h at time %0t",
                expected_q[q_read], rd_data, $time
            );
            errors = errors + 1;
            q_read = q_read + 1;
        end
        else begin
            accepted_reads = accepted_reads + 1;
            q_read = q_read + 1;
        end
    end
end

    // Final drain and result summary
    initial begin
        wait (rst_n == 1);

        repeat (NUM_CYCLES + 20) @(negedge rd_clk);

        // Stop random traffic
        rd_en = 0;
        wr_en = 0;

        // Wait for any outstanding accepted writes to become visible.
        repeat (5) @(negedge rd_clk);

        // Drain remaining data, checking the scoreboard.
        while (!empty) begin
            @(negedge rd_clk);
            rd_en = 1;

            @(posedge rd_clk);
            #1;
        end

        @(negedge rd_clk);
        rd_en = 0;

        repeat (4) @(negedge rd_clk);

        $display("--------------------------------");
        $display("Accepted writes = %0d", accepted_writes);
        $display("Accepted reads  = %0d", accepted_reads);
        $display("Remaining model words = %0d", q_write - q_read);
        $display("Errors = %0d", errors);

        if (errors == 0 && q_write - q_read == 0)
            $display("PASS: RANDOMIZED FIFO TEST");
        else
            $display("FAIL: RANDOMIZED FIFO TEST");

        $finish;
    end

    // Simulation timeout
    initial begin
        #50000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
