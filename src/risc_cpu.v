`default_nettype none
module risc_cpu(
    input wire        i_clk,
    input wire        i_rstn,
    output wire [7:0] o_bus_address,
    output wire [7:0] o_bus_data,
    input wire [7:0]  i_bus_data,
    output wire       o_bus_read,
    output wire       o_bus_write);

  localparam [1:0] OP2 = 2'b00;
  localparam [1:0] OP1 = 2'b01;
  localparam [1:0] OP3 = 2'b10;
  localparam [1:0] OP0 = 2'b11;

  wire [3:0] rs1_addr;
  wire [3:0] rs2_addr;
  reg [3:0]  rd_addr, n_rd_addr;
  reg       rd_write, n_rd_write;
  wire [7:0] rs1;
  wire [7:0] rs2;
  reg [7:0]  rd, n_rd;
  reg [11:0] pc, n_pc;
  wire [15:0] opcode;
  reg [11:0]  call_stack, n_call_stack;
  reg         zero, n_zero;
  reg [0:0]   state, n_state;
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

  risc_rom prog0 (
    .clk(i_clk),
    .address(pc[7:0]),
    .data(opcode));

  always @(*) begin
    n_rd         = rd;
    n_pc         = pc;
    n_call_stack = call_stack;
    n_zero       = zero;
    n_rd_write   = rd_write;
    n_rd_addr    = rd_addr;
    n_state      = state;
    n_bus_write  = 1'b0;
    n_bus_read   = 1'b0;

    case (state)
      1'b0: n_state = 1'b1;
      1'b1: n_state = 1'b0;
      default:;
    endcase // case (state)

    if (state == 1'b0) begin
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
              n_rd_addr  = opcode[12:8];
              n_rd       = opcode[7:0];
              n_rd_write = 1'b1;
            end
            2'b01: begin // i/o write
              n_bus_write   = 1'b1;
            end
            2'b10: begin // i/o read
              n_bus_read    = 1'b1;
            end
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
    end // if (state == 1'b0)
    else if (state == 1'b1) begin
    end
  end // always @ (*)

  assign o_bus_address = rs1;
  assign o_bus_data    = rs2;
endmodule
`default_nettype wire
