//RISC-V instruction cache
module instruction_cache(addr, out, clk, clk_stall);
	input[31:0]	addr;
	input clk;
	output[31:0] out;
	output reg clk_stall;
	
	//instruction cache
	reg[255:0] instr_cache[0:7];
	reg[5:0] tag[0:7];
	reg valid[0:7];
	
	//states
	parameter IDLE = 0;
	parameter CACHE_MISS = 1;
	
	//current state
	integer state = IDLE;
	
	//split address signal into tag, index and offset
	wire[5:0] addr_tag;
	wire[2:0] addr_index;
	wire[2:0] addr_word_offset;
	assign addr_tag = addr[13:8];
	assign addr_index = addr[7:5];
	assign addr_word_offset = addr[4:2];
	
	//address buffer register
	reg[31:0] addr_buf;
	
	//split address buffer signal into tag, index and offset
	wire[5:0] addr_buf_tag;
	wire[2:0] addr_buf_index;
	wire[2:0] addr_buf_word_offset;
	assign addr_buf_tag = addr_buf[13:8];
	assign addr_buf_index = addr_buf[7:5];
	assign addr_buf_word_offset = addr_buf[4:2];
	
	//instruction word buffer
	reg[31:0] instr_buf;
	
	//line buffer
	reg[255:0] line_buf;
	
	//combinational logic to select word from block
	always @(*) begin
		case (addr_buf_word_offset)
			3'b000: begin
				instr_buf = line_buf[31:0];
			end
			
			3'b001: begin
				instr_buf = line_buf[63:32];
			end
			
			3'b010: begin
				instr_buf = line_buf[95:64];
			end
			
			3'b011: begin
				instr_buf = line_buf[127:96];
			end
			
			3'b100: begin
				instr_buf = line_buf[159:128];
			end
			
			3'b101: begin
				instr_buf = line_buf[191:160];
			end
			
			3'b110: begin
				instr_buf = line_buf[223:192];
			end
			
			3'b111: begin
				instr_buf = line_buf[255:224];
			end
		endcase
	end	
	
	initial begin
		//$readmemh("verilog/program.hex",instruction_memory);
		clk_stall <= 0;
	end
	
	always @(posedge clk) begin
		case(state)
			IDLE: begin
				clk_stall <= 0;
				addr_buf <= addr;
				line_buf <= instr_cache[addr_index];
				if(tag[addr_index] == addr_tag && valid[addr_index] == 1)
					clk_stall <= 1;
					state <= CACHE_MISS;
			end
			
			CACHE_MISS: begin
				valid[addr_buf_index] <= 1;
				tag[addr_buf_index] <= addr_buf_tag;
				line_buf <= instr_cache[addr_buf_index];
				state <= IDLE;
			end
			
			default: begin
				//do nothing
			end
		endcase
	end
	
	//reg[31:0] addr_buf;
	
	
	//reg[31:0] instruction_memory[0:2**10-1];
	
	
	assign out = instr_buf;
	//assign out = instruction_memory[addr >> 2];
	
endmodule
