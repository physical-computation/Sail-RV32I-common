verilator: toplevel_sim.v required_modules.txt simulator.cpp
	verilator -Wno-fatal --cc toplevel_sim.v -f required_modules.txt --exe simulator.cpp
	cp obj_dir/* .
	make -f Vtoplevel_sim.mk
	rm -f *.o *.d Vtoplevel_sim_* Vtoplevel_sim.*
	rm -r obj_dir
	#
	# To run the verilated simulation, type ./Vtoplevel_sim
	#
