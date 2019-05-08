
module spi_test_top (miso, mosi, sclk, mscn, trigger, debug_sig);

inout miso,
inout mosi,
inout sclk,
output wire[3:0] mscn

output readssr_req;
input readssr_ack;

input trigger;

output wire[7:0] debug_sig;

//bus interface
reg ipload = 1'b0;
wire ipdone;
reg sbwr_i; //SBWRi
reg sbstb_i; //SBSTBi
reg[7:0] spi_bus_addr;
reg[7:0] tx_data;
reg[7:0] rx_data;
wire sback_o;
wire [1:0] spipirq; //SPIPIRQ

//input clk
wire clk;
reg ENCLKHF = 1'b1; //clock enable
reg CLKHF_POWERUP = 1'b1; //power up the HFOSC circuit

SB_HFOSC #(.CLKHF_DIV("0b00")) OSCInst0 (
	.CLKHFEN(ENCLKHF),
	.CLKHFPU(CLKHF_POWERUP),
	.CLKHF(clk)
);

spi_master spi_master_inst0(
	// Chip Interface
	.SPI2_MISO(miso), 				//inout wire
	.SPI2_MOSI(mosi), 				//inout wire
	.SPI2_SCK(sclk), 					//inout wire
	.SPI2_SCSN(/*open*/), //input wire
	.SPI2_MCSN(mscn), 				//output wire [3:0]
	// Fabric Interface
	.RST(1'b0), //input wire
	// Asynchronous Reset, for Init_SSM
	.IPLOAD(ipload), //input wire
	// Rising Edge triggers Hard IP Configuration
	.IPDONE(ipdone), //output wire
	// 1: Hard IP Configuration is complete
	.SBCLKi(clk), //input wire
	// System bus interface to all 4 Hard IP blocks
	.SBWRi(sbwr_i), //input wire
	//  This bus is available when IPDONE = 1
	.SBSTBi(sbstb_i), //input wire 
	.SBADRi(spi_bus_addr), //input wire [7:0] 
	.SBDATi(tx_data), //input wire [7:0] 
	.SBDATo(rx_data), //output wire [7:0] 
	.SBACKo(sback_o), //output wire 
		  
	.I2CPIRQ(/*open*/), //output wire [1:0] 
	.I2CPWKUP(/*open*/), //output wire [1:0] 
	.SPIPIRQ(spipirq), //output wire [1:0] 
	.SPIPWKUP(/*open*/) //output wire [1:0] 
);

parameter INIT = 0;
parameter CONFIGURE_IP = 1;
parameter WAIT_IPDONE = 2;
parameter IDLE = 3;
parameter REQUEST_READSSR = 4;
parameter ACK_READSSR = 5;
parameter SETUP_FOR_SPI_READ = 6;

integer state = 0;

always @(posedge clk) begin
	case(state)
		INIT: begin
			state <= CONFIGURE_IP;
		end
		
		CONFIGURE_IP: begin
			ipload <= 1'b1;
			state <= WAIT_IPDONE
		end
		
		WAIT_IPDONE: begin
			if(ipdone) begin
				ipload <= 1'b0;
				state <= IDLE;
			end
		end
		
		IDLE: begin
			if(trigger) begin
				state <= REQUEST_READSSR;
			end
		end
		
		REQUEST_READSSR: begin
			state <= ACK_READSSR;
		end

		ACK_READSSR: begin
			state <= SETUP_FOR_SPI_READ;
		end
		
		SETUP_FOR_SPI_READ: begin
			state <= IDLE;
		end
		
		default: begin
			//Illegal state, do nothing
		end	
	endcase
end

endmodule
