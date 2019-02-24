module regfile(clk, write, wrAddr, wrData, rdAddrA, rdDataA, rdAddrB, rdDataB);
	input clk;
	input write;
	input [4:0] wrAddr;
	input [31:0] wrData;
	input [4:0] rdAddrA;
	output [31:0] rdDataA;
	input [4:0] rdAddrB;
	output [31:0] rdDataB;
	
	//register file, 32 x 32-bit registers 
	reg[31:0] regfile[31:0];
	
	//buffer to store address at each positive clock edge
	reg [4:0] rdAddrA_buf;
	reg [4:0] rdAddrB_buf;
	
	//registers for forwarding
	reg[31:0] regDatA;
	reg[31:0] regDatB;
	reg[31:0] wrAddr_buf;
	reg[31:0] wrData_buf;
	reg write_buf;
	
	//Sets register 0 to 0
	initial begin
		regfile[0] = 32'b0;
	end
	
	always @(posedge clk) begin
		if(write==1'b1 && wrAddr!=5'b0) begin
			regfile[wrAddr] <= wrData;
		end
		wrAddr_buf <= wrAddr;
		write_buf <= write;
		wrData_buf <= wrData;
		rdAddrA_buf <= rdAddrA;
		rdAddrB_buf <= rdAddrB;
		regDatA <= regfile[rdAddrA];
		regDatB <= regfile[rdAddrB];
	end
	
	assign rdDataA = ((wrAddr_buf==rdAddrA_buf) & write_buf & wrAddr_buf!=32'b0) ? wrData_buf : regDatA;
	assign rdDataB = ((wrAddr_buf==rdAddrB_buf) & write_buf & wrAddr_buf!=32'b0) ? wrData_buf : regDatB;
	
endmodule
