
/* ID/EX distribution pipeline register */
module id_ex_dregs (clk, data_in, data_out);
	input			clk;
	input [259:0]		data_in;
	output reg[259:0]	data_out;

	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule


module ex_mem_dregs (clk, data_in, data_out);
	input			clk;
	input [257:0]		data_in;
	output reg[257:0]	data_out;

	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule

