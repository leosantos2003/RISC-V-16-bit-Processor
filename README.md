# RISC-V - 16-bit Processor

**INF01175 - Sistemas Digitais para Computadores - UFRGS - 2025/2**

## About

This repository contains the VHDL implementation of a RISC-V architecture-based processor, simplified to 16 bits and 16 instructions. The project was developed through three main versions, aiming to explore different techniques of digital design, FPGA synthesis, and computer organization.

## Project versions

* **Version 1:** `risc_v.vhd`. Monolithic version with internal memory. Initial and simplest version of the processor.
   
* **Version 2:** `risc_v_bram.vhd`. Version with BRAM support. This version adapts the processor for efficient synthesis in FPGAs, using Block RAMs (BRAM).
   * BRAMs are dedicated and efficient memory blocks embedded in the FPGA structure, used to store larger volumes of data without consuming the chip's main logic resources (LUTs).

* **Version 3:** `risc_v_pc_po.vhd`. Version with Datapath/Controller division. This version focuses on structural organization and good RTL design practices, explicitly separating the hardware into two large blocks.
   * Datapath: Contains the storage and processing elements. All the combinational logic of the ALU and the sequential logic of the registers reside here.
   * Controller: Contains only the State Machine (FSM). It generates the control signals that command the Datapath.

## Supported instructions

| Mnemonic | Type | Opcode | Function |
| :--- | :---: | :---: | :---: |
| ADD | R | 0000 | Sum between registers |
| SUB | R | 0001 | Subtraction between registers |
| AND | R | 0010 | Logical AND (bitwise) |
| OR | R | 0011 | Logical OR (bitwise) |
| XOR | R | 0100 | Logical Exclusive OR |
| ADDI | I | 0101 | Sum with immediate |
| ANDI | I | 0110 | AND with immediate |
| ORI | I | 1000 | OR with immediate |
| LW | I | 100 | Load Word (Memory -> Reg) |
| SW | S | 1001 | Store Word (Memory -> Reg) |
| BEQ | B | 1010 | Branch if Equal |
| BNE | B | 1011 | Branch if Not Equal |
| JAL | J | 1100 | Jump and Link |
| LUI | U | 1101 | Load Upper Immediate |
| NOP | N | 1110 | No Operation |
| HLT | N | 1111 | Halt (Stops the processor) |

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## Contact

Leonardo Santos - <leorsantos2003@gmail.com>
