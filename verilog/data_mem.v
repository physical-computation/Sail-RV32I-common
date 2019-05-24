/*
	Authored 2018-2019, Ryan Voo.

	All rights reserved.
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:

	*	Redistributions of source code must retain the above
		copyright notice, this list of conditions and the following
		disclaimer.

	*	Redistributions in binary form must reproduce the above
		copyright notice, this list of conditions and the following
		disclaimer in the documentation and/or other materials
		provided with the distribution.

	*	Neither the name of the author nor the names of its
		contributors may be used to endorse or promote products
		derived from this software without specific prior written
		permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
*/



//Data cache

module data_mem (clk, addr, write_data, memwrite, memread, sign_mask, read_data, led, clk_stall, dist_in, dist_out, DMemRead, DMemWrite);
	input			clk;
	input [31:0]		addr;
	input [31:0]		write_data;
	input			memwrite;
	input			memread;
	input [3:0]		sign_mask;
	output reg [31:0]	read_data;
	output [7:0]		led;
	output reg		clk_stall;	//Sets the clock high
	
	//New interface signals
	input DMemRead;
	input DMemWrite;
	input[255:0] dist_in;
	output reg[255:0] dist_out; //TODO

	/*
	 *	led register
	 */
	reg [31:0]		led_reg;

	/*
	 *	Current state
	 */
	integer			state = 0;

	/*
	 *	Possible states
	 */
	parameter		IDLE = 0;
	parameter		READ_BUFFER = 1;
	parameter		READ = 2;
	parameter		WRITE = 3;

	/*
	 *	Line buffer
	 */
	reg [255:0]		line_buf; //TODO
	
	/*
	 *	Buffer to store distribution input
	 */
	reg [255:0]		dist_in_buf;
	
	/*
	 *	word buffer, selected from line buffer
	 */
	wire[31:0]		word_buf;
	
	/*
	 *	Read buffer
	 */
	wire [31:0]		read_buf;

	/*
	 *	Buffer to identify read or write operation
	 */
	reg			memread_buf;
	reg			memwrite_buf;
	reg			DMemWrite_buf;
	reg			DMemRead_buf;

	/*
	 *	Buffers to store write data
	 */
	reg [31:0]		write_data_buffer;

	/*
	 *	Buffer to store address
	 */
	reg [31:0]		addr_buf;

	/*
	 *	Sign_mask buffer
	 */
	reg [3:0]		sign_mask_buf;

	/*
	 *	Block memory registers
	 */
	//reg [31:0]		data_block[0:1023]; //TODO
	reg[255:0] data_block[0:127];

	/*
	 *	wire assignments
	 */
	wire [6:0]		addr_buf_block_addr;
	wire [2:0]		addr_buf_word_offset; //TODO
	wire [1:0]		addr_buf_byte_offset;
	
	wire [31:0]		replacement_word;

	assign			addr_buf_block_addr	= addr_buf[11:5]; //TODO
	assign			addr_buf_word_offset = addr_buf[4:2]; //TODO
	assign			addr_buf_byte_offset	= addr_buf[1:0];

	/*
	 *	Multiplexers to select word from line buffer //TODO
	 */
	wire[31:0] wbufmuxout1;
	wire[31:0] wbufmuxout2;
	wire[31:0] wbufmuxout3;
	wire[31:0] wbufmuxout4;
	wire[31:0] wbufmuxout5;
	wire[31:0] wbufmuxout6;
	
	assign wbufmuxout1 = addr_buf_word_offset[0] ? line_buf[63:32] : line_buf[31:0];
	assign wbufmuxout2 = addr_buf_word_offset[0] ? line_buf[127:96] : line_buf[95:64];
	assign wbufmuxout3 = addr_buf_word_offset[0] ? line_buf[191:160] : line_buf[159:128];
	assign wbufmuxout4 = addr_buf_word_offset[0] ? line_buf[255:224] : line_buf[223:192];
	
	assign wbufmuxout5 = addr_buf_word_offset[1] ? wbufmuxout2 : wbufmuxout1;
	assign wbufmuxout6 = addr_buf_word_offset[1] ? wbufmuxout4 : wbufmuxout3;
	
	assign word_buf = addr_buf_word_offset[2] ? wbufmuxout6 : wbufmuxout5;

	/*
	 *	Regs for multiplexer output
	 */
	wire [7:0]		buf0;
	wire [7:0]		buf1;
	wire [7:0]		buf2;
	wire [7:0]		buf3;

	assign 			buf0	= word_buf[7:0];
	assign 			buf1	= word_buf[15:8];
	assign 			buf2	= word_buf[23:16];
	assign 			buf3	= word_buf[31:24];

	/*
	 *	Byte select decoder
	 */
	wire bdec_sig0;
	wire bdec_sig1;
	wire bdec_sig2;
	wire bdec_sig3;

	assign bdec_sig0 = (~addr_buf_byte_offset[1]) & (~addr_buf_byte_offset[0]);
	assign bdec_sig1 = (~addr_buf_byte_offset[1]) & (addr_buf_byte_offset[0]);
	assign bdec_sig2 = (addr_buf_byte_offset[1]) & (~addr_buf_byte_offset[0]);
	assign bdec_sig3 = (addr_buf_byte_offset[1]) & (addr_buf_byte_offset[0]);


	/*
	 *	Constructing the word to be replaced for write byte
	 */
	wire[7:0] byte_r0;
	wire[7:0] byte_r1;
	wire[7:0] byte_r2;
	wire[7:0] byte_r3;
 
	assign byte_r0 = (bdec_sig0==1'b1) ? write_data_buffer[7:0] : buf0;
	assign byte_r1 = (bdec_sig1==1'b1) ? write_data_buffer[7:0] : buf1;
	assign byte_r2 = (bdec_sig2==1'b1) ? write_data_buffer[7:0] : buf2;
	assign byte_r3 = (bdec_sig3==1'b1) ? write_data_buffer[7:0] : buf3;

	/*
	 *	For write halfword
	 */
	wire[15:0] halfword_r0;
	wire[15:0] halfword_r1;

	assign halfword_r0 = (addr_buf_byte_offset[1]==1'b1) ? {buf1, buf0} : write_data_buffer[15:0];
	assign halfword_r1 = (addr_buf_byte_offset[1]==1'b1) ? write_data_buffer[15:0] : {buf3, buf2};

	/* a is sign_mask_buf[2], b is sign_mask_buf[1], c is sign_mask_buf[0] */
	wire write_select0;
	wire write_select1;
	
	wire[31:0] write_out1;
	wire[31:0] write_out2;
	
	assign write_select0 = ~sign_mask_buf[2] & sign_mask_buf[1];
	assign write_select1 = sign_mask_buf[2];
	
	assign write_out1 = (write_select0) ? {halfword_r1, halfword_r0} : {byte_r3, byte_r2, byte_r1, byte_r0};
	assign write_out2 = (write_select0) ? 32'b0 : write_data_buffer;
	
	assign replacement_word = (write_select1) ? write_out2 : write_out1;
	
	
	/*
	 *	Logic to generate replacement block for write instructions//TODO
	 */
	/*
	 *	Word select decoder
	 */
	wire wdec_sig0;
	wire wdec_sig1;
	wire wdec_sig2;
	wire wdec_sig3;
	wire wdec_sig4;
	wire wdec_sig5;
	wire wdec_sig6;
	wire wdec_sig7;

	assign wdec_sig0 = (~addr_buf_word_offset[2]) & (~addr_buf_word_offset[1]) & (~addr_buf_word_offset[0]);
	assign wdec_sig1 = (~addr_buf_word_offset[2]) & (~addr_buf_word_offset[1]) & (addr_buf_word_offset[0]);
	assign wdec_sig2 = (~addr_buf_word_offset[2]) & (addr_buf_word_offset[1]) & (~addr_buf_word_offset[0]);
	assign wdec_sig3 = (~addr_buf_word_offset[2]) & (addr_buf_word_offset[1]) & (addr_buf_word_offset[0]);
	assign wdec_sig4 = (addr_buf_word_offset[2]) & (~addr_buf_word_offset[1]) & (~addr_buf_word_offset[0]);
	assign wdec_sig5 = (addr_buf_word_offset[2]) & (~addr_buf_word_offset[1]) & (addr_buf_word_offset[0]);
	assign wdec_sig6 = (addr_buf_word_offset[2]) & (addr_buf_word_offset[1]) & (~addr_buf_word_offset[0]);
	assign wdec_sig7 = (addr_buf_word_offset[2]) & (addr_buf_word_offset[1]) & (addr_buf_word_offset[0]);
	
	wire[31:0] w0;
	wire[31:0] w1;
	wire[31:0] w2;
	wire[31:0] w3;
	wire[31:0] w4;
	wire[31:0] w5;
	wire[31:0] w6;
	wire[31:0] w7;

	assign w0 = (wdec_sig0==1'b1) ? replacement_word : line_buf[31:0];
	assign w1 = (wdec_sig1==1'b1) ? replacement_word : line_buf[63:32];
	assign w2 = (wdec_sig2==1'b1) ? replacement_word : line_buf[95:64];
	assign w3 = (wdec_sig3==1'b1) ? replacement_word : line_buf[127:96];
	assign w4 = (wdec_sig4==1'b1) ? replacement_word : line_buf[159:128];
	assign w5 = (wdec_sig5==1'b1) ? replacement_word : line_buf[191:160];
	assign w6 = (wdec_sig6==1'b1) ? replacement_word : line_buf[223:192];
	assign w7 = (wdec_sig7==1'b1) ? replacement_word : line_buf[255:224];
	
	
	/*
	 *	Combinational logic for generating 32-bit read data
	 */
	
	wire select0;
	wire select1;
	wire select2;
	
	wire[31:0] out1;
	wire[31:0] out2;
	wire[31:0] out3;
	wire[31:0] out4;
	wire[31:0] out5;
	wire[31:0] out6;
	/* a is sign_mask_buf[2], b is sign_mask_buf[1], c is sign_mask_buf[0]
	 * d is addr_buf_byte_offset[1], e is addr_buf_byte_offset[0]
	 */
	
	assign select0 = (~sign_mask_buf[2] & ~sign_mask_buf[1] & ~addr_buf_byte_offset[1] & addr_buf_byte_offset[0]) | (~sign_mask_buf[2] & addr_buf_byte_offset[1] & addr_buf_byte_offset[0]) | (~sign_mask_buf[2] & sign_mask_buf[1] & addr_buf_byte_offset[1]); //~a~b~de + ~ade + ~abd
	assign select1 = (~sign_mask_buf[2] & ~sign_mask_buf[1] & addr_buf_byte_offset[1]) | (sign_mask_buf[2] & sign_mask_buf[1]); // ~a~bd + ab
	assign select2 = sign_mask_buf[1]; //b
	
	assign out1 = (select0) ? ((sign_mask_buf[3]==1'b1) ? {{24{buf1[7]}}, buf1} : {24'b0, buf1}) : ((sign_mask_buf[3]==1'b1) ? {{24{buf0[7]}}, buf0} : {24'b0, buf0});
	assign out2 = (select0) ? ((sign_mask_buf[3]==1'b1) ? {{24{buf3[7]}}, buf3} : {24'b0, buf3}) : ((sign_mask_buf[3]==1'b1) ? {{24{buf2[7]}}, buf2} : {24'b0, buf2}); 
	assign out3 = (select0) ? ((sign_mask_buf[3]==1'b1) ? {{16{buf3[7]}}, buf3, buf2} : {16'b0, buf3, buf2}) : ((sign_mask_buf[3]==1'b1) ? {{16{buf1[7]}}, buf1, buf0} : {16'b0, buf1, buf0});
	assign out4 = (select0) ? 32'b0 : {buf3, buf2, buf1, buf0};
	
	assign out5 = (select1) ? out2 : out1;
	assign out6 = (select1) ? out4 : out3;
	
	assign read_buf = (select2) ? out6 : out5;
	
	/*
	 *	This uses Yosys's support for nonzero initial values:
	 *
	 *		https://github.com/YosysHQ/yosys/commit/0793f1b196df536975a044a4ce53025c81d00c7f
	 *
	 *	Rather than using this simulation construct (`initial`),
	 *	the design should instead use a reset signal going to
	 *	modules in the design.
	 */
	initial begin
		$readmemh("verilog/data.hex", data_block);
		clk_stall = 0;
	end

	/*
	 *	LED register interfacing with I/O
	 */
	always @(posedge clk) begin
		if(memwrite == 1'b1 && addr == 32'h2000) begin
			led_reg <= write_data;
		end
	end

	/*
	 *	State machine
	 */
	always @(posedge clk) begin
		case (state)
			IDLE: begin
				clk_stall <= 0;
				memread_buf <= memread;
				memwrite_buf <= memwrite;
				write_data_buffer <= write_data;
				addr_buf <= addr;
				sign_mask_buf <= sign_mask;
				DMemWrite_buf <= DMemWrite;
				DMemRead_buf <= DMemRead;
				dist_in_buf <= dist_in;
				if(memwrite==1'b1 || memread==1'b1 || DMemWrite==1'b1 || DMemRead==1'b1) begin
					state <= READ_BUFFER;
					clk_stall <= 1;
				end
			end

			READ_BUFFER: begin
				line_buf <= data_block[addr_buf_block_addr];
				if(memread_buf==1'b1 || DMemRead_buf==1'b1) begin
					state <= READ;
				end
				else if(memwrite_buf == 1'b1 || DMemWrite_buf==1'b1) begin
					state <= WRITE;
				end
			end

			READ: begin
				clk_stall <= 0;
				read_data <= read_buf;
				dist_out <= line_buf;
				state <= IDLE;
			end

			WRITE: begin
				clk_stall <= 0;
				data_block[addr_buf_block_addr] <= DMemWrite_buf ? dist_in_buf : {w7, w6, w5, w4, w3, w2, w1, w0};
				state <= IDLE;
			end

		endcase
	end

	/*
	 *	Test led
	 */
	assign led = led_reg[7:0];
endmodule
