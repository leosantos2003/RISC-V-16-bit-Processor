# RISC-V - 16-bit Processor

**INF01175 - Sistemas Digitais para Computadores - UFRGS - 2025/2**

## About

This repository contains the VHDL implementation of a RISC-V architecture-based processor, simplified to 16 bits and 16 instructions. The project was developed through three main versions, aiming to explore different techniques of digital design, FPGA synthesis, and computer organization.

## Project versions

* **Version 1:** `risc_v.vhd`. Monolithic version with internal memory. Initial and simplest version of the processor.
   
* **Version 2:** `risc_v_bram`: Version with BRAM support. This version adapts the processor for efficient synthesis in FPGAs, using Block RAMs (BRAM).
   * BRAMs are dedicated and efficient memory blocks embedded in the FPGA structure, used to store larger volumes of data without consuming the chip's main logic resources (LUTs).

* **Version 3:** `risc_v_pc_po`: PC/PO Version - Control and Operation. This version focuses on structural organization and good RTL design practices, explicitly separating the hardware into two large blocks.
   * Datapath (PO): Contains the storage and processing elements. All the combinational logic of the ALU and the sequential logic of the registers reside here.
   * Controller (PC): Contains only the State Machine (FSM). It generates the control signals that command the Datapath.

## Supported instructions

