
module distReg(clk, DRegWrite, wrAddr, wrData, rdAddr, rdData);
	input		clk;
	input		DRegWrite;
	input [4:0]	wrAddr;
	input [255:0]	wrData;
	input [4:0]	rdAddr;
	output [255:0]	rdData;

	/*
	 *	Distribution register file, 32 x 256-bit registers
	 */
	reg [255:0]	regfile[31:0];

	/*
	 *	buffer to store address at each positive clock edge
	 */
	reg [4:0]	rdAddr_buf;

	/*
	 *	registers for forwarding
	 */
	reg [255:0]	regDat;
	reg [4:0]	wrAddr_buf;
	reg [255:0]	wrData_buf;
	reg		DRegWrite_buf;

	always @(posedge clk) begin
		if (DRegWrite) begin
			regfile[wrAddr] <= wrData;
		end
		wrAddr_buf	<= wrAddr;
		DRegWrite_buf	<= DRegWrite;
		wrData_buf	<= wrData;
		rdAddr_buf	<= rdAddr;
		regDat		<= regfile[rdAddr];
	end

	assign	rdData = ((wrAddr_buf==rdAddr_buf) & DRegWrite_buf) ? wrData_buf : regDat;
endmodule
