module cpu_tb;
  import cpu_pkg::*;

  logic clk = 0;
  logic rst;
  logic [15:0] io_out;
  logic io_exit;
  logic [7:0] io_pc;
  int cycle_count = 0;

  // Clock generation
  initial begin
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst = 1'b1;
    repeat(10) @(posedge clk);
    rst = 1'b0;
    $display("Reset released at time %0t", $time);
  end

  // Load instruction memory from hex file
  initial begin
    $readmemh("hw/gen/sim/program.hex", dut.imem_inst.mem);
    $display("Instruction memory loaded from file at time %0t", $time);
  end

  // stop when io_exit is 1
  always @(posedge clk) begin
    if (io_exit) begin
      $display("Exit signal received at time %0t", $time);
      $finish;
    end
  end

  // Monitor io_out and io_pc
  always @(posedge clk) begin
    $display("Cycle %0d: pc=%0h, accu=%0h, instr=%0h", cycle_count, io_pc, io_out , dut.decode_reg.instr[7:0]);
    cycle_count <= cycle_count+1;
  end

  // check ACCU is 0 at the end of simu => PASS 
  final begin
    if (io_out == 16'h0000) begin
      $display("Test PASSED - ACCU is 0");
    end else begin
      $display("Test FAILED - ACCU should be 0, got 0x%04h", io_out);
    end
  end

  // DUT instantiation
  CpuID dut ( 
    .clk(clk),
    .rst(rst),
    .io_out(io_out),
    .io_exit(io_exit),
    .io_pc (io_pc)
  );

endmodule
