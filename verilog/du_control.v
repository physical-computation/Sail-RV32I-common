//Distribution Unit control

module du_control(
		input[6:0] opcode,
		output DUCtrl
	);
	
	assign DUCtrl = (opcode[6]) & (~opcode[5]);
	
endmodule
