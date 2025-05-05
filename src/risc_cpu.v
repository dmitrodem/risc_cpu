`default_nettype none
// +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------------------+
// |15   |14   |13   |12   |11   |10   |9    |8    |7    |6    |5    |4    |3    |2    |1    |0    | asm               |
// +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------------------+
// |     |     |  0  |  0  |                                                                       |                   |
// |     |     +-----+-----+                                                                       |                   |
// |     |     |  0  |  1  |                                                                       | reserved          |
// |     |     +-----+-----+                                                                       |                   |
// |     |     |  1  |  0  |                                                                       |                   |
// |     |     +-----+-----+-----------------------+-----+-----+-----+-----+-----------------------+-------------------+
// |     |     |     |     |                       |     |     |  0  |  0  |                       | sll rs1, rd       |
// |  0  |  0  |     |     |                       |     |     +-----+-----+                       +-------------------+
// |     |     |     |     |                       |     |     |  0  |  1  |                       | srl rs1, rd       |
// |     |     |     |     |          rs1          |  0  |  0  +-----+-----+          rd           +-------------------+
// |     |     |  1  |  1  |                       |     |     |  1  |  0  |                       | rol rs1, rd       |
// |     |     |     |     |                       |     |     +-----+-----+                       +-------------------+
// |     |     |     |     |                       |     |     |  1  |  1  |                       | ror rs1, rd       |
// |     |     |     |     +-----------------------+-----+-----+-----+-----+-----------------------+-------------------+
// |     |     |     |     |                       |  1  |  1  |  1  |  1  |                       | ret               |
// +-----+-----+-----+-----+-----------------------+-----+-----+-----+-----+-----------------------+-------------------+
// |     |     |  0  |  0  |                     IMM8                      |                       | ld IMM8, rd       |
// |     |     +-----+-----+-----------------------+-----------------------+                       +-------------------+
// |  0  |  1  |  0  |  1  |                       |                       |                       | out [rs1], rs2    |
// |     |     +-----+-----+                       |                       |                       +-------------------+
// |     |     |  1  |  0  |                       |                       |                       | in [rs1], rd      |
// +-----+-----+-----+-----+                       |                       |                       +-------------------+
// |     |     |  0  |  0  |                       |                       |          rd           | xor rs1, rs2, rd  |
// |     |     +-----+-----+          rs1          |          rs2          |                       +-------------------+
// |     |     |  0  |  1  |                       |                       |                       | or rs1, rs2, rd   |
// |  1  |  0  +-----+-----+                       |                       |                       +-------------------+
// |     |     |  1  |  0  |                       |                       |                       | and rs1, rs2, rd  |
// |     |     +-----+-----+                       |                       |                       +-------------------+
// |     |     |  1  |  1  |                       |                       |                       | add rs1, rs2, rd  |
// +-----+-----+-----+-----+-----------------------+-----------------------+-----------------------+-------------------+
// |     |     |  0  |  0  |                                                                       | call IMM12        |
// |     |     +-----+-----+                                                                       +-------------------+
// |     |     |  0  |  1  |                                                                       | jmp IMM12         |
// |  1  |  1  +-----+-----+                                 IMM12                                 +-------------------+
// |     |     |  1  |  0  |                                                                       | beq IMM12         |
// |     |     +-----+-----+                                                                       +-------------------+
// |     |     |  1  |  1  |                                                                       | bnz IMM12         |
// +-----+-----+-----+-----+-----------------------------------------------------------------------+-------------------+

module risc_cpu #(
  parameter romfile = "romfile.hex"
) (
  input wire        i_clk,
  input wire        i_rstn,
  output wire [7:0] o_bus_address,
  output wire [7:0] o_bus_data,
  input wire [7:0]  i_bus_data,
  output wire       o_bus_read,
  output wire       o_bus_write
);

  localparam [1:0] OP2 = 2'b00;
  localparam [1:0] OP1 = 2'b01;
  localparam [1:0] OP3 = 2'b10;
  localparam [1:0] OP0 = 2'b11;

  wire [3:0] rs1_addr;
  wire [3:0] rs2_addr;
  wire [3:0] rd_addr;
  reg        rd_write, n_rd_write;
  wire [7:0] rs1;
  wire [7:0] rs2;
  reg [7:0]  rd, n_rd;
  reg [11:0] pc, n_pc;
  wire [15:0] opcode;
  reg [11:0]  call_stack, n_call_stack;
  reg         zero, n_zero;
  reg [1:0]   state, n_state;
  reg         bus_write, n_bus_write;
  reg         bus_read, n_bus_read;

  risc_regfile regfile0 (
    .clk(i_clk),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rd_addr(rd_addr),
    .rd_write(rd_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd));

  risc_rom #(
    .romfile(romfile))
  prog0 (
    .clk(i_clk),
    .address(pc[7:0]),
    .data(opcode));

  always @(*) begin
    n_rd         = rd;
    n_pc         = pc;
    n_call_stack = call_stack;
    n_zero       = zero;
    n_rd_write   = 1'b0;
    n_state      = state;
    n_bus_write  = 1'b0;
    n_bus_read   = 1'b0;

    case (state)
      2'b00: n_state = 2'b01;
      2'b01: n_state = 2'b11;
      2'b11: n_state = 2'b10;
      2'b10: n_state = 2'b00;
      default:;
    endcase // case (state)

    if (state == 2'b00) begin
      n_pc = pc + 1;
      case (opcode[15:14])
        OP2: begin // OP2 format
          case (opcode[13:12])
            2'b00:; // not used
            2'b01:; // not used
            2'b10:; // not used
            2'b11: begin
              case (opcode[7:4])
                4'b0000: n_rd = {rs1[6:0], 1'b0}; // shift left
                4'b0001: n_rd = {1'b0, rs1[7:1]}; // shift right
                4'b0010: n_rd = {rs1[6:0], rs1[7]}; // roll left
                4'b0011: n_rd = {rs1[0], rs1[7:1]}; // roll right
                4'b1111: n_pc = call_stack;
                default:;
              endcase
            end
            default:;
          endcase
        end // case: OP2
        OP1: begin
          case (opcode[13:12])
            2'b00: begin // load immediate value
              n_rd       = opcode[11:4];
              n_rd_write = 1'b1;
            end
            2'b01: begin // i/o write
              n_bus_write   = 1'b1;
            end
            2'b10: begin // i/o read
              n_bus_read    = 1'b1;
            end
            default:;
          endcase
        end // case: OP1
        OP3: begin
          case (opcode[13:12])
            2'b00: n_rd = rs1 ^ rs2;
            2'b01: n_rd = rs1 | rs2;
            2'b10: n_rd = rs1 & rs2;
            2'b11: n_rd = rs1 + rs2;
            default:;
          endcase
          n_zero     = | n_rd;
          n_rd_write = 1'b1;
        end // case: OP3
        OP0: begin
          case (opcode[13:12])
            2'b00: begin // JSR
              n_pc         = opcode[11:0];
              n_call_stack = pc + 1;
            end
            2'b01: begin // JMP
              n_pc = opcode[11:0];
            end
            2'b10: begin // BEQ
              if (zero)
                n_pc = opcode[11:0];
            end
            2'b11: begin // BNZ
              if (~zero)
                n_pc = opcode[11:0];
            end
            default:;
          endcase
        end // case: OP0
      endcase
    end // if (state == 2'b00)
    else if (state == 2'b01) begin
      if (bus_read) begin
        n_rd       = i_bus_data;
        n_rd_write = 1'b1;
      end
    end
    if (~i_rstn) begin
      n_rd         = 8'h00;
      n_pc         = 12'h000;
      n_call_stack = 12'h000;
      n_zero       = 1'b0;
      n_rd_write   = 1'b0;
      n_state      = 2'b00;
      n_bus_write  = 1'b0;
      n_bus_read   = 1'b0;
    end
  end // always @ (*)

  always @(posedge i_clk) begin : seq
    rd         <= n_rd;
    pc         <= n_pc;
    call_stack <= n_call_stack;
    zero       <= n_zero;
    rd_write   <= n_rd_write;
    state      <= n_state;
    bus_write  <= n_bus_write;
    bus_read   <= n_bus_read;
  end

  assign rs1_addr = opcode[11:8];
  assign rs2_addr = opcode[7:4];
  assign rd_addr = opcode[3:0];


  assign o_bus_address = rs1;
  assign o_bus_data    = rs2;
  assign o_bus_write   = bus_write;
  assign o_bus_read    = bus_read;
endmodule
`default_nettype wire
