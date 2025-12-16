module CpuID 
  import cpu_pkg::*;
#(
  parameter int MEM_SIZE = 256
)
(
  input   logic          clk,
  input   logic          rst,
  output  addr_t         io_pc, 
  output  word_t         io_out,
  output  logic          io_exit
  
);
  // Memory control signals
  logic [7:0] imem_addr, dmem_addr;
  logic [15:0] imem_dout, dmem_din, dmem_dout;
  logic dmem_we;

  // SRAM instances
  sram #(
    .MEM_SIZE(MEM_SIZE)
  ) imem_inst (
    .clk(clk),
    .addr(imem_addr),
    .din(16'b0),
    .dout(imem_dout),
    .we(1'b0),
    .cs(1'b1)
  );

  sram #(
    .MEM_SIZE(MEM_SIZE)
  ) dmem_inst (
    .clk(clk),
    .addr(dmem_addr),
    .din(dmem_din),
    .dout(dmem_dout),
    .we(dmem_we),
    .cs(1'b1)
  );

  // Pipeline registers
  typedef struct packed {
    logic    valid; 
    word_t   instr;
    addr_t   pc;
  } pipe_reg_t;

  
  pipe_reg_t fetch_reg, decode_reg, execute_reg;
  
  // Control signals
  logic flush;
  logic stall;
  word_t accu;

  // Decode flags
  typedef struct packed {
    logic is_add;
    logic is_sub; 
    logic is_brnz;
    logic is_str;
    logic is_ld;
    logic is_ldi;
    logic is_exit;
  } decode_flags_t;

  decode_flags_t decode_flags;
  decode_flags_t execute_flags;
  
  // Instruction decode
  always_comb begin
    decode_flags = '0;
    if (decode_reg.valid) begin 
      case(decode_reg.instr[7:0])
        cpu_pkg::ADD:  decode_flags.is_add  = 1'b1;
        cpu_pkg::SUB:  decode_flags.is_sub  = 1'b1;
        cpu_pkg::BRNZ: decode_flags.is_brnz = 1'b1;
        cpu_pkg::STR:  decode_flags.is_str  = 1'b1;
        cpu_pkg::LD:   decode_flags.is_ld   = 1'b1;
        cpu_pkg::LDI:  decode_flags.is_ldi  = 1'b1;
        cpu_pkg::EXIT: decode_flags.is_exit = 1'b1;
        default: begin end
      endcase
    end
  end

  always_comb begin
    imem_addr = fetch_reg.pc;
    io_pc = execute_reg.pc;
    io_out = accu;
  end

  // Pipeline control
  always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
      fetch_reg <= '0;
      decode_reg <= '0;
      execute_reg <= '0;
      accu <= '0;
      io_exit <= 1'b0;
      flush <= 1'b0;
      stall <= 1'b0;
    end else begin
      // Fetch stage - read from imem and increment PC
      if(!flush && !stall) begin
        
        fetch_reg.instr <= imem_dout;
        fetch_reg.pc <= fetch_reg.pc + 1'b1;
        fetch_reg.valid <= 1'b1;
      end 
      if (flush) begin
          fetch_reg.valid <= 1'b0;  
      end 
      if (stall) begin
          fetch_reg.instr <= imem_dout; 
      end
    
 
      if(!flush && !stall) begin
        // Pipeline stage transfers
        decode_reg <= fetch_reg;
        execute_reg <= decode_reg;
        execute_flags <= decode_flags;
        
        // Execute stage
        if(execute_reg.valid) begin
          unique case(1'b1)
            execute_flags.is_add:  accu <= accu + {8'h0,execute_reg.instr[15:8]};
            execute_flags.is_sub:  accu <= accu - {8'h0,execute_reg.instr[15:8]};
            execute_flags.is_brnz: if(accu != 0) begin
                                   fetch_reg.pc <= execute_reg.instr[15:8];
                                   flush <= 1'b1;
                                 end
            execute_flags.is_ld:   begin
                                   stall <= 1'b1;
                                   dmem_addr <= execute_reg.instr[15:8];
                                   dmem_we <= 1'b0;
                                 end
            execute_flags.is_ldi:  accu <= {8'h0, execute_reg.instr[15:8]};
            execute_flags.is_str:  begin
                                   dmem_addr <= execute_reg.instr[15:8];
                                   dmem_din <= accu;
                                   dmem_we <= 1'b1;
                                 end
            execute_flags.is_exit: io_exit <= 1'b1;
           
            default: begin end
          endcase
          
        end
      end else begin
        // On flush, invalidate decode and execute stages
        if (flush) begin
          decode_reg.valid <= '0;
          execute_reg.valid <= '0;
          flush <= 1'b0;
        end
        // Handle load stall
        if (stall) begin         
            accu <= dmem_dout;
            stall <= 1'b0;
          
        end
      end
    end
  end



endmodule
