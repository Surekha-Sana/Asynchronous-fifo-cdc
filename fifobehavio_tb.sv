`timescale 1ns / 1ps

module fifo_boundary_tb;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 3;
    localparam DEPTH = 8;

    reg rst_n = 0;
    reg wr_clk = 0;
    reg rd_clk = 0;

    reg wr_en = 0;
    reg rd_en = 0;
    reg [DATA_WIDTH-1:0] wr_data = 0;

    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;

    integer errors = 0;
    integer i;

    reg [DATA_WIDTH-1:0] expected [0:DEPTH-1];

    Async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .rst_n(rst_n),
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    // Independent clocks
    always #5 wr_clk = ~wr_clk;

    initial begin
        #1;
        forever #7 rd_clk = ~rd_clk;
    end

    // Write one word when the FIFO accepts it
    task write_word(input [DATA_WIDTH-1:0] data);
        begin
            @(negedge wr_clk);
            while (full) @(negedge wr_clk);

            wr_data = data;
            wr_en = 1;

            @(posedge wr_clk);
            #1;
            wr_en = 0;
        end
    endtask

    // Read one word and compare with expected data.
    // Assumes rd_data reflects the current head before
    // the active read edge, as in a combinational-read FIFO.
    task read_word(input [DATA_WIDTH-1:0] data);
        begin
            @(negedge rd_clk);
            while (empty) @(negedge rd_clk);

            if (rd_data !== data) begin
                $display(
                    "FAIL: expected=%h actual=%h time=%0t",
                    data, rd_data, $time
                );
                errors = errors + 1;
            end

            rd_en = 1;
            @(posedge rd_clk);
            #1;
            rd_en = 0;
        end
    endtask

    initial begin
        // TEST 1: RESET
        $display("TEST 1: RESET");

        rst_n = 0;
        repeat (4) @(negedge wr_clk);
        #1;

        if (empty !== 1 || full !== 0) begin
            $display("FAIL: reset flags incorrect");
            errors = errors + 1;
        end
        else
            $display("PASS: reset flags");

        rst_n = 1;

        // Allow reset release and pointer synchronization
        repeat (5) @(negedge rd_clk);

        // TEST 2: READ WHILE EMPTY
        $display("TEST 2: READ WHILE EMPTY");

        if (empty !== 1) begin
            $display("FAIL: FIFO should be empty");
            errors = errors + 1;
        end
        else begin
            @(negedge rd_clk);
            rd_en = 1;

            @(posedge rd_clk);
            #1;

            if (empty !== 1) begin
                $display("FAIL: empty read changed empty flag");
                errors = errors + 1;
            end
            else
                $display("PASS: empty read blocked");

            rd_en = 0;
        end

        // TEST 3: FILL FIFO AND TRY AN EXTRA WRITE
        $display("TEST 3: FULL FIFO");

        for (i = 0; i < DEPTH; i = i + 1) begin
            expected[i] = 8'h40 + i;
            write_word(expected[i]);
        end

        // Allow the full flag to settle
        #1;

        if (full !== 1) begin
            $display("FAIL: full flag not asserted");
            errors = errors + 1;
        end
        else
            $display("PASS: full flag asserted");

        // Attempt an extra write while full
        @(negedge wr_clk);
        wr_data = 8'hEE;
        wr_en = 1;

        @(posedge wr_clk);
        #1;
        wr_en = 0;

        if (full !== 1) begin
            $display("FAIL: full flag unexpectedly cleared");
            errors = errors + 1;
        end
        else
            $display("PASS: extra write blocked");

        // TEST 4: READ BACK ALL EIGHT WORDS
        $display("TEST 4: READ BACK DATA");

        for (i = 0; i < DEPTH; i = i + 1)
            read_word(expected[i]);

        // Allow read-pointer synchronization
        repeat (5) @(negedge wr_clk);

        if (empty !== 1) begin
            $display("FAIL: FIFO did not become empty");
            errors = errors + 1;
        end
        else
            $display("PASS: FIFO drained");

        // TEST 5: POINTER WRAPAROUND
        $display("TEST 5: POINTER WRAPAROUND");

        // Write and read 24 words. This exceeds the
        // FIFO depth and repeatedly reuses memory locations.
        for (i = 0; i < 24; i = i + 1) begin
            write_word((8'h80 + i) & 8'hFF);
            read_word((8'h80 + i) & 8'hFF);
        end

        repeat (5) @(negedge rd_clk);

        if (empty !== 1) begin
            $display("FAIL: FIFO not empty after wraparound");
            errors = errors + 1;
        end

        $display("--------------------------------");
        $display("Boundary test errors = %0d", errors);

        if (errors == 0)
            $display("PASS: ALL BOUNDARY TESTS");
        else
            $display("FAIL: BOUNDARY TESTS");

        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL: boundary test timeout");
    end

endmodule
