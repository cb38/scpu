// CPU Package - Pure Verilog

// Type definitions
`define WORD_WIDTH 16
`define ADDR_WIDTH 8
`define OPCODE_WIDTH 8

// Opcodes
`define ADD  8'h01
`define SUB  8'h02
`define BRNZ 8'h03
`define STR  8'h06
`define LD   8'h07
`define LDI  8'h08
`define EXIT 8'hFF
