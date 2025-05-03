`default_nettype none
  module risc_rom #(
    parameter string romfile = "program.hex"
) (
    input wire         clk,
    input wire [7:0]  address,
    output wire [15:0] data);

  reg [15:0] mem [0:255];
  initial begin
    $readmemh(romfile, mem);
  end

  reg [15:0] r;
  always @(posedge clk) begin : read_rom
    r <= mem[address];
  end
  assign data = r;
endmodule
`default_nettype wire
