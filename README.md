# Asynchronous FIFO with Clock Domain Crossing (CDC)

## 1. Project Overview

This project implements an asynchronous First-In, First-Out (FIFO) buffer using Verilog HDL.

An asynchronous FIFO allows data to be written using one clock domain and read using another independent clock domain. It is commonly used to transfer data between hardware blocks operating at different clock frequencies.

The design was developed and simulated using Verilog/SystemVerilog testbenches and synthesized and implemented using AMD Xilinx Vivado 2024.2.

## 2. Project Objectives

- Design an asynchronous FIFO using Verilog HDL.
- Support independent write and read clocks.
- Implement binary and Gray-coded pointers.
- Use two-stage synchronizers for pointer clock-domain crossings.
- Generate full and empty status flags.
- Verify FIFO boundary conditions.
- Analyze FPGA resource utilization.
- Inspect the synthesized schematic and implementation timing reports.

## 3. Design Specifications

| Parameter | Value |
|---|---|
| HDL | Verilog HDL |
| Data width | 8 bits |
| Address width | 3 bits |
| FIFO depth | 8 words |
| Total storage capacity | 64 bits |
| Write clock | `wr_clk` |
| Read clock | `rd_clk` |
| Reset | Active-low `rst_n` |
| Full indicator | `full` |
| Empty indicator | `empty` |
| FPGA development tool | AMD Xilinx Vivado 2024.2 |

## 4. Architecture

The FIFO consists of the following components:

### Binary Pointers

The write and read binary pointers track the memory locations used for writing and reading.

### Gray-Code Conversion

The binary pointers are converted to Gray code to support safer pointer transfers between asynchronous clock domains.

### Clock Domain Crossing Synchronizers

Two-stage synchronizer registers transfer the Gray-coded read pointer into the write-clock domain and the Gray-coded write pointer into the read-clock domain.

### Full and Empty Detection

The full flag prevents writes when the FIFO is full. The empty flag prevents reads when the FIFO is empty.

### FIFO Memory

The memory stores the input data words until they are read from the FIFO.

## 5. Repository Structure

```text
asynchronous-fifo-cdc/
├── README.md
├── .gitignore
├── rtl/
│   └── Async_fifo.v
├── testbench/
│   ├── Asyncfifo_tb.v
│   ├── Async_fifo_tb.sv
│   └── fifobehavio_tb.sv
├── constraints/
│   └── Async_fifo.xdc
├── reports/
│   ├── Async_fifo_clock_utilization_routed.rpt
│   └── Async_fifo_timing_summary_routed.rpt
|   |___ Async_fifo_utilization_placed.rpt
└── screenshots/
    ├── Simulation1_verilog.png
    ├── Simulation2_SV.png
    ├── Sim3_boundbehav_SV.png
    ├── Implemented_device.png
    └── Timing_summary.png
    |__ Sim_result1.png
    |__ Sim_result2_bound.png
    |__ Synth_Utilization1.png
    |__ Synth_Utilization2.png
    |__ Synthesized_Schematic.png
```

The filenames and folder contents should match the files actually included in the repository.

## 6. Verification

The project includes testbenches for functional and boundary-condition verification.

Reported tests include:

- Reset and initial flag checks.
- Attempted read while the FIFO is empty.
- Full-flag assertion.
- Attempted write while the FIFO is full.
- FIFO draining.
- Pointer wraparound.
- Randomized read/write testing.

Reported randomized testing completed with 882 writes, 882 reads, and zero errors.

Refer to the uploaded testbenches and simulation logs for the corresponding test implementations and results.

## 7. Synthesis Results

The reported Vivado synthesis utilization is:

| FPGA Resource | Used |
|---|---:|
| Total LUTs | 26 |
| Logic LUTs | 18 |
| LUTRAMs | 8 |
| SRLs | 0 |
| Flip-flops | 32 |
| RAMB36 | 0 |
| RAMB18 | 0 |
| DSP blocks | 0 |

The synthesis results indicate that the small FIFO memory was implemented using distributed RAM resources rather than block RAM.

These values represent the reported synthesis results; they should not be interpreted as post-implementation utilization unless separately verified.

## 8. Implementation and Timing Analysis

The design was implemented using Vivado 2024.2 for the target device `xc7a35tcpg236-1`.

The current implementation timing summary reports:

| Timing Parameter | Result |
|---|---:|
| Worst Negative Slack (WNS) | -0.416 ns |
| Total Negative Slack (TNS) | -2.150 ns |
| Failing setup endpoints | 8 |
| Worst Hold Slack (WHS) | +0.067 ns |
| Failing hold endpoints | 0 |

The current implementation has setup timing violations, primarily on paths between the read and write clock domains.

The clock constraints and CDC timing treatment require further review. Timing closure has not yet been achieved.

The detailed timing-path report is included for analysis and future improvement.

## 9. Tools Used

- Verilog HDL
- SystemVerilog
- AMD Xilinx Vivado 2024.2
- Vivado behavioral simulation
- FPGA synthesis and implementation reports

## 10. Screenshots

Screenshots of the simulation results, synthesis utilization, synthesized schematic, implemented design, and timing analysis can be added to the `screenshots/` directory.

## 11. Future Improvements

- Review and refine the clock constraints.
- Verify the CDC implementation and synchronizer placement.
- Investigate the failing setup paths.
- Re-run implementation after correcting the constraints.
- Re-evaluate timing and resource utilization.
- Explore alternative memory inference styles for larger FIFO configurations.

## 12. Conclusion

This project demonstrates an asynchronous FIFO RTL implementation, Gray-coded pointer synchronization, functional boundary testing, and FPGA synthesis and implementation analysis.

The current timing violations are documented as part of the project's ongoing verification and timing-closure work.
