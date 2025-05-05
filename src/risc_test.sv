`default_nettype none
  module risc_test();

  reg clk  = 1'b0;
  reg rstn = 1'b0;
  wire [7:0] bus_address;
  wire [7:0] bus_data_o;
  reg [7:0]  bus_data_i = 8'h00;
  wire       bus_read;
  wire       bus_write;

  always #(5ns) clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
    rstn = 1'b0;
    #(100ns);
    rstn = 1'b1;
  end

  risc_cpu u0 (
    .i_clk(clk),
    .i_rstn(rstn),
    .o_bus_address(bus_address),
    .o_bus_data(bus_data_o),
    .i_bus_data(bus_data_i),
    .o_bus_read(bus_read),
    .o_bus_write(bus_write));

  always @(posedge clk) begin
    if (bus_write) begin
      if (bus_address == 8'hab) begin
        $display("Stopping with code = %h", bus_data_o);
        $finish();
      end
    end
  end

endmodule
`default_nettype wire
