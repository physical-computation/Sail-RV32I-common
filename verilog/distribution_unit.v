//distribution logic unit

module distribution_unit(
		input clk,
		input DUCtrl,
		input[31:0] rs1,
		input[255:0] DU_input,
		output reg[255:0] DU_result,
		output reg du_clk_stall
	);
	
	parameter IDLE = 0;
	parameter READSSR = 1;
	parameter DATA_OUT = 2;
	
	integer state = 0;
	
	//internal registers
	reg[255:0] dist_buffer;
	
	//test distribution, acting as placeholder
	reg[255:0] distribution = 256'h000200140024000400502208111C12C0DC02A009001000000000000000000000;
	
	/*initial begin
		$readmemh("verilog/distribution.hex", distribution);
	end*/
	
	//state machine
	always @(posedge clk) begin
		case (state)
			IDLE: begin
				du_clk_stall <= 1'b0;
				if(DUCtrl) begin
					du_clk_stall <= 1'b1;
					state <= READSSR;
				end
			end
			
			READSSR: begin
				//connect to SPI module, retrive data
				dist_buffer <= distribution;
				state <= DATA_OUT;
			end
			
			DATA_OUT: begin
				DU_result <= dist_buffer;
				du_clk_stall <= 1'b0;
				state <= IDLE;
			end
			
			default: begin
				//Illegal state, return to IDLE
				state <= IDLE;
			end
		endcase
	end
	
endmodule

