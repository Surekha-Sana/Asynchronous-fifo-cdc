`timescale 1ns / 1ps

module Async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                  rst_n,

    // Write clock domain
    input  wire                  wr_clk,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // Read clock domain
    input  wire                  rd_clk,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    // ADDR_WIDTH must be >= 2.
    // FIFO depth = 2**ADDR_WIDTH.
    localparam DEPTH    = (1 << ADDR_WIDTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Dual-clock storage
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary pointers include one extra wrap bit
    reg [PTR_WIDTH-1:0] wbin;
    reg [PTR_WIDTH-1:0] rbin;

    // Gray-coded pointers
    reg [PTR_WIDTH-1:0] wgray;
    reg [PTR_WIDTH-1:0] rgray;

    // Synchronized Gray pointers
    (* ASYNC_REG = "TRUE" *)
    reg [PTR_WIDTH-1:0] rgray_sync1, rgray_sync2;

    (* ASYNC_REG = "TRUE" *)
    reg [PTR_WIDTH-1:0] wgray_sync1, wgray_sync2;

    reg wfull;
    reg rempty;

    assign full  = wfull;
    assign empty = rempty;

    // ------------------------------------------------
    // 1. Next-pointer calculations
    // ------------------------------------------------

    wire [PTR_WIDTH-1:0] wbin_next;
    wire [PTR_WIDTH-1:0] rbin_next;

    wire [PTR_WIDTH-1:0] wgray_next;
    wire [PTR_WIDTH-1:0] rgray_next;

    assign wbin_next =
        wbin + ((wr_en && !wfull) ? 1'b1 : 1'b0);

    assign rbin_next =
        rbin + ((rd_en && !rempty) ? 1'b1 : 1'b0);

    // Binary-to-Gray conversion
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;

    // ------------------------------------------------
    // 2. FIFO memory write operation
    // ------------------------------------------------

    always @(posedge wr_clk) begin
        if (wr_en && !wfull)
            mem[wbin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    // ------------------------------------------------
    // 3. Write pointer and full-flag logic
    // ------------------------------------------------

    wire [PTR_WIDTH-1:0] rgray_full_compare;

    // Invert the two most significant Gray-pointer bits
    assign rgray_full_compare = {
        ~rgray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
         rgray_sync2[PTR_WIDTH-3:0]
    };

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wbin  <= {PTR_WIDTH{1'b0}};
            wgray <= {PTR_WIDTH{1'b0}};
            wfull <= 1'b0;
        end else begin
            wbin  <= wbin_next;
            wgray <= wgray_next;
            wfull <= (wgray_next == rgray_full_compare);
        end
    end

    // ------------------------------------------------
    // 4. Read pointer and empty-flag logic
    // ------------------------------------------------

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rbin   <= {PTR_WIDTH{1'b0}};
            rgray  <= {PTR_WIDTH{1'b0}};
            rempty <= 1'b1;
        end else begin
            rbin   <= rbin_next;
            rgray  <= rgray_next;
            rempty <= (rgray_next == wgray_sync2);
        end
    end

    // ------------------------------------------------
    // 5. Synchronize read pointer into write domain
    // ------------------------------------------------

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rgray_sync1 <= {PTR_WIDTH{1'b0}};
            rgray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    // ------------------------------------------------
    // 6. Synchronize write pointer into read domain
    // ------------------------------------------------

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wgray_sync1 <= {PTR_WIDTH{1'b0}};
            wgray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // ------------------------------------------------
    // 7. Read data
    // ------------------------------------------------

    // Asynchronous read from storage.
    // The current read pointer selects the output word.
    assign rd_data = mem[rbin[ADDR_WIDTH-1:0]];

endmodule
