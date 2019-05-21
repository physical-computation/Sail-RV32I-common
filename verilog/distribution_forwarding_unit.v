
module DistributionForwardingUnit (
		input[4:0] ID_sourceAddr1,
		input[4:0] ID_sourceAddr2,
		
		input EX_DRegWrite,
		input[4:0] EX_destRegAddr,
		
		input MEM_DRegWrite,
		input[4:0] MEM_destRegAddr,
		
		output EX_DFwdMuxSel1,
		output MEM_DFwdMuxSel1,
		
		output EX_DFwdMuxSel2,
		output MEM_DFwdMuxSel2
	);
	
	assign EX_DFwdMuxSel1 = ((ID_sourceAddr1 == EX_destRegAddr) && EX_DRegWrite);
	assign MEM_DFwdMuxSel1 = ((EX_destRegAddr != MEM_destRegAddr) && (ID_sourceAddr1 == MEM_destRegAddr) && MEM_DRegWrite);
	
	assign EX_DFwdMuxSel2 = ((ID_sourceAddr2 == EX_destRegAddr) && EX_DRegWrite);
	assign MEM_DFwdMuxSel2 = ((EX_destRegAddr != MEM_destRegAddr) && (ID_sourceAddr2 == MEM_destRegAddr) && MEM_DRegWrite);
	
endmodule
