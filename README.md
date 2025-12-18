# RISC-V - 16-bit Processor

**INF01175 - Sistemas Digitais para Computadores - UFRGS - 2025/2**

## About

This repository contains the VHDL implementation of a RISC-V architecture-based processor, simplified to 16 bits and 16 instructions. The project was developed through three main versions, aiming to explore different techniques of digital design, FPGA synthesis, and computer organization.

## File structure

The project is divided into three main implementations:

### 1. Basic RTL implementation (array memory)

Initial version described as a single state machine with memory implemented as an array of registers/LUTs.

* `risc_v.vhd`: Processor source code with internal memory initialized in VHDL.
* `risc_v_tb.vhd`: Testbench for simulation.
   
### 2. Implementation with BRAM (synchronous memory)

Adapted version to use the FPGA's Block RAM (BRAM), supporting `.coe` initialization files. The FSM was adjusted to wait for synchronous memory reads (`FETCH_WAIT`, `LW_WAIT`).

* `risc_v_bram.vhd`: Processor with interface to external memory.
* `risc_v_bram_tb.vhd`: Testbench instantiating the processor and the IP Core memory component.
* `Programs (.coe)`: Memory initialization files for synthesis.

### 3. PC-PO implementation (Control Part - Operational Part)
Structured version separating the *Data Path* (ALU, Registers, Muxes) from the *Control Unit* (FSM).

* `risc_v_pc_po.vhd`: Contains the `riscv_datapath_controller` entity with the FSM and explicit operational components.
* `risc_v_pc_po_tb.vhd`: Testbench for the PC-PO version.

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
