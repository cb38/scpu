package cpu_pkg;
  typedef logic [15:0] word_t;
  typedef logic [7:0]  addr_t;
  typedef logic [7:0]  opcode_t;
  
  // Opcodes
  localparam ADD  = 8'h01;
  localparam SUB  = 8'h02;
  localparam BRNZ = 8'h03;
  localparam STR  = 8'h06;
  localparam LD   = 8'h07;
  localparam LDI  = 8'h08;
  localparam EXIT = 8'hFF;
  
 
  
endpackage
