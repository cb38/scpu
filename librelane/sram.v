// Simple Synchronous SRAM - Pure Verilog

module sram
#(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 16,
  parameter MEM_SIZE = 256
)
(
  input  wire                   clk,
  input  wire [ADDR_WIDTH-1:0]  addr,
  input  wire [DATA_WIDTH-1:0]  din,
  output wire [DATA_WIDTH-1:0]  dout,
  input  wire                   we,
  input  wire                   cs
);

  reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];
  wire [DATA_WIDTH-1:0] data_out;

  // Synchronous write
  always @(posedge clk) begin
    if (cs && we) begin
      mem[addr] <= din;
    end
  end

  // Asynchronous read
  assign data_out = mem[addr];
  assign dout = data_out;

endmodule
