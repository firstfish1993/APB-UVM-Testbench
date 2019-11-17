module apbslave(
	input pclk,prst,PWRITE,PSEL,PENABLE, 
	input [31:0] PWDATA,PADDR, 
	output reg PREADY, 
	output reg[31:0] PRDATA);
 
reg [1:0] state,state_next;
parameter IDLE = 2'd0, SEL = 2'd1, EN = 2'd2;

 
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
 if (!PWRITE && PSEL==1 && PENABLE==1) //Stay in this state iff both PSEL and PENABLE are asserted
  begin
    PRDATA =  PADDR;//simply return its address
    PREADY = 1;
    state_next = IDLE;
  end
 else if(PWRITE && PSEL ==1 && PENABLE==1) 
  begin
    PREADY = 1;
    state_next = IDLE;
  end
 else begin 
    state_next = IDLE;
    PREADY = 0; 
 end
endcase
end
 
endmodule
