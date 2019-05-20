
module DistributionForwardingUnit (
		input[4:0] ID_sourceAddr;
		
		input EX_DRegWrite;
		input[4:0] EX_destRegAddr;
		
		input MEM_DRegWrite;
		input[4:0] MEM_destRegAddr;
		
		output EX_DFwdMuxSel;
		output MEM_DFwdMuxSel;
	);
	
	assign EX_DFwdMuxSel = ((ID_sourceAddr == EX_destRegAddr) && EX_DRegWrite);
	assign MEM_DFwdMuxSel = ((EX_destRegAddr != MEM_destRegAddr) && (ID_sourceAddr == MEM_destRegAddr) && MEM_DRegWrite);
	
endmodule
