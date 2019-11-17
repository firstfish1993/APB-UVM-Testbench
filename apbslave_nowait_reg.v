module register (rst, clk, in, out, RW, w_en);
input [31:0] in;
input clk, rst, RW, w_en;
output reg [31:0] out;

always @(posedge clk, posedge rst)
begin
  if(rst)
    out <= 0;
  //RW == 1 means write
  else if (RW && w_en)
    out <= in;
  else
    out <= out;
end
endmodule

module reg_array (rst, clk, address, indata, out, RW, w_en);

input clk, rst, RW, w_en;
input [31:0] address;
input [31:0] indata;
output [31:0] out;

reg [15:0] inRW;
reg [31:0] data [0:15];
wire [31:0] out_wire [0:15];

register reg_a_0(.rst(rst), .clk(clk), .in(data[0]), .out(out_wire[0]), .RW(inRW[0]), .w_en(w_en));
register reg_a_1(.rst(rst), .clk(clk), .in(data[1]), .out(out_wire[1]), .RW(inRW[1]), .w_en(w_en));
register reg_a_2(.rst(rst), .clk(clk), .in(data[2]), .out(out_wire[2]), .RW(inRW[2]), .w_en(w_en));
register reg_a_3(.rst(rst), .clk(clk), .in(data[3]), .out(out_wire[3]), .RW(inRW[3]), .w_en(w_en));
register reg_a_4(.rst(rst), .clk(clk), .in(data[4]), .out(out_wire[4]), .RW(inRW[4]), .w_en(w_en));
register reg_a_5(.rst(rst), .clk(clk), .in(data[5]), .out(out_wire[5]), .RW(inRW[5]), .w_en(w_en));
register reg_a_6(.rst(rst), .clk(clk), .in(data[6]), .out(out_wire[6]), .RW(inRW[6]), .w_en(w_en));
register reg_a_7(.rst(rst), .clk(clk), .in(data[7]), .out(out_wire[7]), .RW(inRW[7]), .w_en(w_en));
register reg_a_8(.rst(rst), .clk(clk), .in(data[8]), .out(out_wire[8]), .RW(inRW[8]), .w_en(w_en));
register reg_a_9(.rst(rst), .clk(clk), .in(data[9]), .out(out_wire[9]), .RW(inRW[9]), .w_en(w_en));
register reg_a_10(.rst(rst), .clk(clk), .in(data[10]), .out(out_wire[10]), .RW(inRW[10]), .w_en(w_en));
register reg_a_11(.rst(rst), .clk(clk), .in(data[11]), .out(out_wire[11]), .RW(inRW[11]), .w_en(w_en));
register reg_a_12(.rst(rst), .clk(clk), .in(data[12]), .out(out_wire[12]), .RW(inRW[12]), .w_en(w_en));
register reg_a_13(.rst(rst), .clk(clk), .in(data[13]), .out(out_wire[13]), .RW(inRW[13]), .w_en(w_en));
register reg_a_14(.rst(rst), .clk(clk), .in(data[14]), .out(out_wire[14]), .RW(inRW[14]), .w_en(w_en));
register reg_a_15(.rst(rst), .clk(clk), .in(data[15]), .out(out_wire[15]), .RW(inRW[15]), .w_en(w_en));

always@(*)begin
  case(address)
    32'h0000_0000: begin inRW[0] = RW; data[0] = indata; end
    32'h0000_0001: begin inRW[1] = RW; data[1] = indata; end
    32'h0000_0002: begin inRW[2] = RW; data[2] = indata; end
    32'h0000_0003: begin inRW[3] = RW; data[3] = indata; end
    32'h0000_0004: begin inRW[4] = RW; data[4] = indata; end
    32'h0000_0005: begin inRW[5] = RW; data[5] = indata; end
    32'h0000_0006: begin inRW[6] = RW; data[6] = indata; end
    32'h0000_0007: begin inRW[7] = RW; data[7] = indata; end
    32'h0000_0008: begin inRW[8] = RW; data[8] = indata; end
    32'h0000_0009: begin inRW[9] = RW; data[9] = indata; end
    32'h0000_000A: begin inRW[10] = RW; data[10] = indata; end
    32'h0000_000B: begin inRW[11] = RW; data[11] = indata; end
    32'h0000_000C: begin inRW[12] = RW; data[12] = indata; end
    32'h0000_000D: begin inRW[13] = RW; data[13] = indata; end
    32'h0000_000E: begin inRW[14] = RW; data[14] = indata; end
    default: begin inRW[15] = RW; data[15] = indata; end
  endcase
end

assign out = out_wire[address];

endmodule

module apbslave(
  input pclk,prst,PWRITE,PSEL,PENABLE, 
  input [31:0] PWDATA,PADDR, 
  output reg PREADY, 
  output [31:0] PRDATA);
 
reg [1:0] state,state_next;
parameter IDLE = 0, SEL = 1, EN = 2, EN2 = 3;
reg w_en;

reg_array reg_a(.rst(prst),.clk(pclk),.address(PADDR),.indata(PWDATA),.out(PRDATA),.RW(PWRITE), .w_en(w_en));

always @ (posedge pclk) begin
if (prst) state <= IDLE;
else state <= state_next;
end
 
always @(*) begin
case(state)
IDLE: 
  if (PSEL) begin
    state_next = SEL;
    PREADY = 0;
  end
  else begin 
    state_next = IDLE;
    PREADY = 0;
  end
SEL:
  if (PENABLE) state_next = EN; 
  else state_next = SEL;
EN:
  begin
    PREADY= 0;
    state_next = EN2;
  end
default:
  if (!PWRITE && PSEL==1 && PENABLE==1) //Stay in this state iff both PSEL and PENABLE are asserted
    begin
     PREADY = 1;
     state_next = IDLE;
    end
  else if(PWRITE && PSEL ==1 && PENABLE==1) 
    begin
      PREADY = 1; w_en = 1;
      state_next = IDLE;
    end
  else 
    begin 
      state_next = IDLE;
      PREADY = 0;
    end

endcase
end
 
endmodule

