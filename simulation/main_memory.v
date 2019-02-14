module main_memory(clk, block_addr, readmem, writemem, data_write, data_read);
	input clk;
	input[8:0] block_addr; 
	input readmem;
	input writemem;
	input[255:0] data_write;
	output reg[255:0] data_read;
	
	reg[255:0] main_mem[0:511]; //16 KiB main memory
	
	initial begin
		$readmemh("simulation/program.hex", main_mem);
	end
	
	always @(posedge clk) begin
		if(readmem==1'b1) begin
			data_read <= main_mem[block_addr];
		end else if(writemem==1'b1) begin
			main_mem[block_addr] <= data_write;
		end
	end
	
endmodule
