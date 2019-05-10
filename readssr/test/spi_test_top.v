`define SPICR0_addr 8'b0000_1000
`define SPICR1_addr 8'b0000_1001
`define SPICR2_addr 8'b0000_1010
`define SPIBR_addr 8'b0000_1011
`define SPITXDR_addr 8'b0000_1101
`define SPIRXDR_addr 8'b0000_1110
`define SPICSR_addr 8'b0000_1111
`define SPISR_addr 8'b0000_1100
`define SPIIRQ_addr 8'b0000_0110
`define SPIIRQEN_addr 8'b0000_0111

module spi_test_top (miso, mosi, sclk, mscn, trigger, readssr_req, readssr_ack, led);

inout miso;
inout mosi;
inout sclk;
output mscn; //TODO make it work with spi hard module's chip select

input trigger;

output readssr_req;
input readssr_ack;

output wire[7:0] led;

//bus interface
reg ipload = 1'b0;
wire ipdone;
reg sbwr_i; //SBWRi
reg sbstb_i; //SBSTBi
reg[7:0] bus_addr;
reg[7:0] tx_data;
reg[7:0] rx_data;
wire sback_o;
wire [1:0] spipirq; //SPIPIRQ

wire[3:0] mscn30;

wire spirrdy;
wire spitrdy;

reg[7:0] data_buffer[0:34];

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
	.SPI2_SCSN(1'b1), //input wire //TODO double check this
	.SPI2_MCSN(mscn30), 				//output wire [3:0]
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
	.SBADRi(bus_addr), //input wire [7:0] 
	.SBDATi(tx_data), //input wire [7:0] 
	.SBDATo(rx_data), //output wire [7:0] 
	.SBACKo(sback_o), //output wire 
		  
	.I2CPIRQ(/*open*/), //output wire [1:0] 
	.I2CPWKUP(/*open*/), //output wire [1:0] 
	.SPIPIRQ(spipirq), //output wire [1:0] 
	.SPIPWKUP(/*open*/) //output wire [1:0] 
);

//states
parameter INIT 																				= 0;
parameter CONFIGURE_IP 																= 1;
parameter WAIT_IPDONE 																= 2;
//parameter CONFIGURE_AS_MASTER 												= 3;
//parameter MASTER_CONFIGURE_SBACK 											= 4;
//parameter MASTER_CONFIGURE_SBACK_DEASSERT_WAIT 				= 5;
//parameter ASSERT_MSCN0 																= 6;
//parameter MSCN0_ASSERT_SBACKO 												= 7;
//parameter ENABLE_RX_INTERRUPT = 6;
//parameter RX_INTERRUPT_SBACKO = 7;
//parameter CLEAR_INTERRUPT1 = 8;
parameter IDLE 																				= 3;
parameter REQUEST_READSSR 														= 4;
parameter ACK_READSSR 																= 5;
parameter READ_SPISR 																	= 6;
parameter WAIT_FOR_TRDY 															= 7;
parameter WAIT_SBACKO_BEFORE_TRANSMIT 								= 8;
parameter WRITE_DUMMY_TXDATA													= 9;
parameter WAIT_FOR_RX_INTERRUPT 											= 10;
parameter CLEAR_SPIIRQ 																= 11;
parameter SPIIRQ_SBACKO_AND_INCREMENT_ITERATOR 				= 12;
parameter DEASSERT_READSSR_REQUEST 										= 13;
parameter READSSR_ACK_DEASSERT 												= 14;

integer state = 0;

integer iterator;

always @(posedge clk) begin
	case(state)
		INIT: begin //0
			scsn <= 1'b1;
			mscn <= 1'b1;
			state <= CONFIGURE_IP;
		end
		
		CONFIGURE_IP: begin //1
			ipload <= 1'b1;
			state <= WAIT_IPDONE;
		end
		
		WAIT_IPDONE: begin //2
			if(ipdone) begin
				ipload <= 1'b0;
				state <= IDLE;//CONFIGURE_AS_MASTER;
			end
		end
		
		/*CONFIGURE_AS_MASTER: begin //3
			sbwr_i <= 1'b1;
			sbstb_i <= 1'b1;
			bus_addr <= `SPICR2_addr;
			tx_data <= 8'b10000000;
			state <= MASTER_CONFIGURE_SBACK;//MASTER_CONFIGURE_SBACK;
		end
		
		MASTER_CONFIGURE_SBACK: begin //4
			if(sback_o) begin
				sbwr_i <= 1'b0;
				sbstb_i <= 1'b0;
				bus_addr <= 8'b0;
				tx_data <= 8'b0;
				state <= MASTER_CONFIGURE_SBACK_DEASSERT_WAIT;
			end
		end
		
		MASTER_CONFIGURE_SBACK_DEASSERT_WAIT: begin //5
			sbwr_i <= 1'b0;
			sbstb_i <= 1'b0;
			bus_addr <= 8'b0;
			tx_data <= 8'b0;
			if(!sback_o) begin
				state <= ASSERT_MSCN0;
			end
		end*/
		
		/*ASSERT_MSCN0: begin
			sbwr_i <= 1'b1;
			sbstb_i <= 1'b1;
			bus_addr <= `SPICSR_addr;
			tx_data <= 8'b00000010;
			state <= MSCN0_ASSERT_SBACKO;
		end
		
		MSCN0_ASSERT_SBACKO: begin
			if(sback_o) begin
				sbwr_i <= 1'b0;
				sbstb_i <= 1'b0;
				bus_addr <= 8'b0;
				tx_data <= 8'b0;
				state <= IDLE;
			end
		end*/
		
		/*ENABLE_RX_INTERRUPT: begin //6
			scsn <= 1'b1;
			bus_addr <= `SPIIRQEN_addr;
			sbwri <= 1'b1;
			sbstbi <= 1'b1; //assert to select a specific slave module
			tx_data <= 8'b00001000;
			if(spipirq[0]) begin
				state <= RX_INTERRUPT_SBACKO;
			end
		end
		
		RX_INTERRUPT_SBACKO: begin //7
			scsn <= 1'b1;
			bus_addr <= `SPIIRQ_addr;
			sbwri <= 1'b1;
			sbstbi <= 1'b1; //assert to select a specific slave module
			tx_data <= 8'b00001000;
			state <= RX_INTERRUPT_SBACKO;
			if(sback_o) begin //spipirq[0]
				scsn <= 1'b0;
				sbwri <= 1'b0;
				sbstbi <= 1'b0;
				state <= CLEAR_INTERRUPT1;
			end
		end
		
		CLEAR_INTERRUPT1: begin
			scsn <= 1'b1;
			bus_addr <= `SPIIRQ_addr;
			sbwri <= 1'b1;
			sbstbi <= 1'b1; //assert to select a specific slave module
			tx_data <= 8'b00001000;
			if(!spipirq[0]) begin
				state <= IDLE;
			end
		end*/
		
		IDLE: begin //8
			readssr_req <= 0;
			iterator <= 0;
			mscn <= 1'b1;
			
			if(trigger) begin
				state <= REQUEST_READSSR;
			end
		end
		
		REQUEST_READSSR: begin //9
			readssr_req <= 1'b1;
			state <= ACK_READSSR;
		end

		ACK_READSSR: begin //10
			if(readssr_ack) begin
				state <= WRITE_DUMMY_TXDATA;//READ_SPISR;
			end
		end
		
		/*READ_SPISR: begin //TODO can be done with only WAIT_FOR_TRDY? //11
			sbwr_i <= 1'b0; //0 for read
			sbstb_i <= 1'b1;
			bus_addr <= `SPISR_addr;
			state <= WAIT_FOR_TRDY;
		end
		
		WAIT_FOR_TRDY: begin //12
			sbwr_i <= 1'b0; //0 for read
			sbstb_i <= 1'b1;
			bus_addr <= `SPISR_addr;
			mscn <= 1'b0;
			if(spitrdy) begin
				scsn <= 1'b1;
				state <= WAIT_SBACKO_BEFORE_TRANSMIT;
			end
		end
		
		WAIT_SBACKO_BEFORE_TRANSMIT: begin
			if(sback_o) begin
				state <= WRITE_DUMMY_TXDATA;
			end
		end*/
		
		/*DEASSERT_CSN: begin
			
		end*/
		
		WRITE_DUMMY_TXDATA: begin //13
			sbwr_i <= 1'b1;
			sbstb_i <= 1'b1;
			bus_addr <= `SPITXDR_addr;
			tx_data <= 8'b0;
			state <= WAIT_FOR_RX_INTERRUPT;
		end
		
		WAIT_FOR_RX_INTERRUPT: begin //14
			if(spipirq[0]) begin //RX interrupt
				mscn <= 1'b1;
				sbwr_i <= 1'b0;
				sbstb_i <= 1'b0;
				data_buffer[iterator] <= rx_data;
				state <= CLEAR_SPIIRQ;
			end
		end
		
		CLEAR_SPIIRQ: begin
			sbwr_i <= 1'b1;
			sbstb_i <= 1'b1;
			bus_addr <= `SPIIRQ_addr;
			tx_data <= 8'b00001000;
			state <= SPIIRQ_SBACKO_AND_INCREMENT_ITERATOR;
		end
		
		SPIIRQ_SBACKO_AND_INCREMENT_ITERATOR: begin
			if(sback_o) begin
				sbwr_i <= 1'b0;
				sbstb_i <= 1'b0;
				bus_addr <= 8'b0;
				tx_data <= 8'b0;
				if(iterator < 34) begin
					iterator <= iterator + 1;
					state <= WRITE_DUMMY_TXDATA;
				end
				else begin
					state <= DEASSERT_READSSR_REQUEST;
				end
			end
		end
		
		DEASSERT_READSSR_REQUEST: begin
			readssr_req <= 1'b0;
			state <= READSSR_ACK_DEASSERT;
		end
		
		READSSR_ACK_DEASSERT: begin
			if(!readssr_ack) begin
				state <= IDLE;
			end
		end
		
		default: begin
			//Illegal state, do nothing
		end	
	endcase
end

assign spirrdy = rx_data[3];
assign spitrdy = rx_data[4];

//assign mscn = mscn30[0];

//debug signal
assign led = {sback_o, mscn30[2], state[5:0]};


endmodule
