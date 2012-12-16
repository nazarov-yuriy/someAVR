//MIT License
//Copyright (C) 2012 Nazarov Yuriy

//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
//documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
//the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
//and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
//FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
//ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module myAVR(clk50,reset,porta,portb);
input wire clk50;
input wire reset;

//==== Clock divisor ===
reg [25:0]cnt;
always @(negedge clk50)
begin
	cnt <= cnt + 1;
end

//==== io ==============
output wire [7:0]porta;
output wire [7:0]portb;

//==== opcodes =========
parameter CMD_ADD  = 16'b000011xxxxxxxxxx;
parameter CMD_ADC  = 16'b000111xxxxxxxxxx;
parameter CMD_SUB  = 16'b000110xxxxxxxxxx;
parameter CMD_SBC  = 16'b000010xxxxxxxxxx;

parameter CMD_AND  = 16'b001000xxxxxxxxxx;
parameter CMD_EOR  = 16'b001001xxxxxxxxxx;
parameter CMD_OR   = 16'b001010xxxxxxxxxx;
parameter CMD_MOV  = 16'b001011xxxxxxxxxx;

parameter CMD_CP   = 16'b000101xxxxxxxxxx;
parameter CMD_LSR  = 16'b1001010xxxxx0110;

parameter CMD_LDI  = 16'b1110xxxxxxxxxxxx;

parameter CMD_BREQ = 16'b111100xxxxxxx001;
parameter CMD_BRNE = 16'b111101xxxxxxx001;
parameter CMD_BRCS = 16'b111100xxxxxxx000;
parameter CMD_BRCC = 16'b111101xxxxxxx000;
//======================

//==== prog mem ========
rom prog (ip, cnt[25], opcode);

//==== state ===========
reg [7:0]ip = 0;

reg [7:0]registers[16:31];
//reg [7:0]ioports[0:63];
assign porta = registers[20];
assign portb = registers[21];

reg I,T,H,S,V,N,Z = 0,C = 0;


//==== other wires =====
wire [15:0]opcode;

wire [4:0]src;
assign src = {opcode[9],opcode[3],opcode[2],opcode[1],opcode[0]};

wire [4:0]dest;
assign dest = {opcode[8],opcode[7],opcode[6],opcode[5],opcode[4]};

wire [6:0]k;
assign k = {opcode[9],opcode[8],opcode[7],opcode[6],opcode[5],opcode[4],opcode[3]};

wire [7:0]K;
assign K = {opcode[11],opcode[10],opcode[9],opcode[8],opcode[3],opcode[2],opcode[1],opcode[0]};


wire [7:0]Rs = registers[src[4:0]];
wire [7:0]Rd = registers[dest[4:0]];
wire [7:0]R = Rd + ( opcode[10]&opcode[12]&~C | ~opcode[10]&~opcode[12]&C ? 0 : 1) + ( opcode[10] ? Rs : ~Rs);

always @(negedge cnt[25])
begin

	//==== ADD ==================================================================
	if( opcode[15:10] == CMD_ADD[15:10] )
	begin
		registers[dest[4:0]] <= R;
		Z <= ~|R;
		C <= Rs[7]&~R[7] | Rd[7]&~R[7] | Rs[7]&Rd[7];
	end
	
	//==== ADC ==================================================================
	if( opcode[15:10] == CMD_ADC[15:10] )
	begin
		registers[dest[4:0]] <= R;
		Z <= ~|R;
		C <= Rs[7]&~R[7] | Rd[7]&~R[7] | Rs[7]&Rd[7];
	end
	
	//==== SUB ==================================================================
	if( opcode[15:10] == CMD_SUB[15:10] )
	begin
		registers[dest[4:0]] <= R;
		Z <= ~|R;
		C <= Rs[7]&~Rd[7] | R[7]&~Rd[7] | Rs[7]&R[7];
	end
	
	//==== SBC ==================================================================
	if(  opcode[15:10] == CMD_SBC[15:10] )
	begin
		registers[dest[4:0]] <= R;
		Z <= ~|R;
		C <= Rs[7]&~Rd[7] | R[7]&~Rd[7] | Rs[7]&R[7];
	end
	
	

	//==== AND ==================================================================
	if(opcode[15:10] == CMD_AND[15:10])
	begin
		registers[dest[4:0]] <= registers[dest[4:0]]&registers[src[4:0]];
	end
	
	//==== EOR ==================================================================
	if(opcode[15:10] == CMD_EOR[15:10])
	begin
		registers[dest[4:0]] <= registers[dest[4:0]]^registers[src[4:0]];
	end
	
	//==== OR ==================================================================
	if(opcode[15:10] == CMD_OR[15:10])
	begin
		registers[dest[4:0]] <= registers[dest[4:0]]|registers[src[4:0]];
	end
	
	//==== MOV ==================================================================
	if(opcode[15:10] == CMD_MOV[15:10])
	begin
		registers[dest[4:0]] <= registers[src[4:0]];
	end
	
	
	//==== LDI ==================================================================
	if( opcode[15:12] == CMD_LDI[15:12] )
	begin
		registers[{1'b1,dest[3:0]}] <= {opcode[11],opcode[10],opcode[9],opcode[8],opcode[3],opcode[2],opcode[1],opcode[0]};
	end
	
	
	//==== BREQ =================================================================
	if({opcode[15:10],opcode[2:0]} == {CMD_BREQ[15:10],CMD_BREQ[2:0]})
	begin
		if(Z)
			ip <= ip + {k[6],k};
	end
	
	//==== BRNE =================================================================
	if({opcode[15:10],opcode[2:0]} == {CMD_BRNE[15:10],CMD_BRNE[2:0]})
	begin
		if(~Z)
			ip <= ip + {k[6],k};
	end
	
	//==== BRCS =================================================================
	if({opcode[15:10],opcode[2:0]} == {CMD_BRCS[15:10],CMD_BRCS[2:0]})
	begin
		if(C)
			ip <= ip + {k[6],k};
	end
	
	//==== BRCC =================================================================
	if({opcode[15:10],opcode[2:0]} == {CMD_BRCC[15:10],CMD_BRCC[2:0]})
	begin
		if(~C)
			ip <= ip + {k[6],k};
	end

	ip <= ip + 1'd1;
end

endmodule

