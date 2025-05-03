`default_nettype none
  module risc_regfile (
    input wire        clk,
    input wire [3:0]  rs1_addr,
    input wire [3:0]  rs2_addr,
    input wire [3:0]  rd_addr,
    input wire        rd_write,
    output wire [7:0] rs1,
    output wire [7:0] rs2,
    input wire [7:0]  rd);

  reg [7:0] mem [0:15];

  reg [7:0] r_rs1;
  always @(posedge clk) begin: read_rs1
    r_rs1 <= mem[rs1_addr];
  end
  assign rs1 = r_rs1;

  reg [7:0] r_rs2;
  always @(posedge clk) begin: read_rs2
    r_rs2 <= mem[rs2_addr];
  end
  assign rs2 = r_rs2;

  always @(posedge clk) begin: write_rd
    if (rd_write)
      mem[rd_addr] <= rd;
  end

endmodule
`default_nettype wire
