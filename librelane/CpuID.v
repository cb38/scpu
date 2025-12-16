// CPU Module - Pure Verilog

`include "cpu_pkg.v"

module CpuID 
#(
  parameter MEM_SIZE = 32
)
(
  input   wire          clk,
  input   wire          rst,
  output  wire [7:0]    io_pc, 
  output  wire [15:0]   io_out,
  output  wire          io_exit
);

  // Memory control signals
  wire [7:0]  imem_addr, dmem_addr;
  wire [15:0] imem_dout, dmem_din, dmem_dout;
  wire dmem_we;

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
  reg fetch_valid, decode_valid, execute_valid;
  reg [15:0] fetch_instr, decode_instr, execute_instr;
  reg [7:0]  fetch_pc, decode_pc, execute_pc;
  
  // Control signals
  reg flush;
  reg stall;
  reg [15:0] accu;

  // Decode flags
  reg is_add, is_sub, is_brnz, is_str, is_ld, is_ldi, is_exit;
  reg decode_is_add, decode_is_sub, decode_is_brnz, decode_is_str;
  reg decode_is_ld, decode_is_ldi, decode_is_exit;
  reg execute_is_add, execute_is_sub, execute_is_brnz, execute_is_str;
  reg execute_is_ld, execute_is_ldi, execute_is_exit;
  
  // Instruction decode
  always @(*) begin
    is_add = 1'b0;
    is_sub = 1'b0;
    is_brnz = 1'b0;
    is_str = 1'b0;
    is_ld = 1'b0;
    is_ldi = 1'b0;
    is_exit = 1'b0;
    
    if (decode_valid) begin 
      case(decode_instr[7:0])
        `ADD:  is_add  = 1'b1;
        `SUB:  is_sub  = 1'b1;
        `BRNZ: is_brnz = 1'b1;
        `STR:  is_str  = 1'b1;
        `LD:   is_ld   = 1'b1;
        `LDI:  is_ldi  = 1'b1;
        `EXIT: is_exit = 1'b1;
        default: begin end
      endcase
    end
  end

  always @(*) begin
    imem_addr = fetch_pc;
    io_pc = execute_pc;
    io_out = accu;
  end

  // Pipeline control
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      fetch_valid <= 1'b0;
      fetch_instr <= 16'b0;
      fetch_pc <= 8'b0;
      
      decode_valid <= 1'b0;
      decode_instr <= 16'b0;
      decode_pc <= 8'b0;
      
      execute_valid <= 1'b0;
      execute_instr <= 16'b0;
      execute_pc <= 8'b0;
      
      accu <= 16'b0;
      io_exit <= 1'b0;
      flush <= 1'b0;
      stall <= 1'b0;
      
      execute_is_add <= 1'b0;
      execute_is_sub <= 1'b0;
      execute_is_brnz <= 1'b0;
      execute_is_str <= 1'b0;
      execute_is_ld <= 1'b0;
      execute_is_ldi <= 1'b0;
      execute_is_exit <= 1'b0;
    end else begin
      // Fetch stage - read from imem and increment PC
      if(!flush && !stall) begin
        fetch_instr <= imem_dout;
        fetch_pc <= fetch_pc + 1'b1;
        fetch_valid <= 1'b1;
      end 
      
      if (flush) begin
        fetch_valid <= 1'b0;  
      end 
      
      if (stall) begin
        fetch_instr <= imem_dout; 
      end
    
      if(!flush && !stall) begin
        // Pipeline stage transfers
        decode_valid <= fetch_valid;
        decode_instr <= fetch_instr;
        decode_pc <= fetch_pc;
        
        execute_valid <= decode_valid;
        execute_instr <= decode_instr;
        execute_pc <= decode_pc;
        
        execute_is_add <= is_add;
        execute_is_sub <= is_sub;
        execute_is_brnz <= is_brnz;
        execute_is_str <= is_str;
        execute_is_ld <= is_ld;
        execute_is_ldi <= is_ldi;
        execute_is_exit <= is_exit;
        
        // Execute stage
        if(execute_valid) begin
          if (execute_is_add) begin
            accu <= accu + {8'h0, execute_instr[15:8]};
          end else if (execute_is_sub) begin
            accu <= accu - {8'h0, execute_instr[15:8]};
          end else if (execute_is_brnz) begin
            if(accu != 0) begin
              fetch_pc <= execute_instr[15:8];
              flush <= 1'b1;
            end
          end else if (execute_is_ld) begin
            stall <= 1'b1;
            dmem_addr <= execute_instr[15:8];
            dmem_we <= 1'b0;
          end else if (execute_is_ldi) begin
            accu <= {8'h0, execute_instr[15:8]};
          end else if (execute_is_str) begin
            dmem_addr <= execute_instr[15:8];
            dmem_din <= accu;
            dmem_we <= 1'b1;
          end else if (execute_is_exit) begin
            io_exit <= 1'b1;
          end
        end
      end else begin
        // On flush, invalidate decode and execute stages
        if (flush) begin
          decode_valid <= 1'b0;
          execute_valid <= 1'b0;
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
