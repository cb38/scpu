module sram
#(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 16,
  parameter int MEM_SIZE = 256
)
(
  input  logic                   clk,
  input  logic [ADDR_WIDTH-1:0]  addr,
  input  logic [DATA_WIDTH-1:0]  din,
  output logic [DATA_WIDTH-1:0]  dout,
  input  logic                   we,
  input  logic                   cs
);

  logic [DATA_WIDTH-1:0] mem [MEM_SIZE];
  logic [DATA_WIDTH-1:0] data_out;

  // Synchronous write
  always_ff @(posedge clk) begin
    if (cs && we) begin
      mem[addr] <= din;
    end
  end

  // ASynchronous read
  always_comb begin
  data_out = mem[addr];
  end 

  assign dout = data_out;

endmodule
