`timescale 1ns / 1ps
/**
 * @file irs_block_readout_addr_v3b.v Contains irs_block_readout_addr_v3b module.
 */

//% @brief Module for selecting the IRS block readout address.
//%
//% The IRS read address interface begins when raddr_stb_i   
//% is asserted. For the IRS1-2, this places "raddr_i" on RD 
//% and then issues raddr_reached_o.                           
//%
//% For the IRS3B, this begins operating the read address 
//% input shift register. Once the read address has been
//% reached, raddr_reached_o is asserted.
//%
//% The timing diagram for this (in the parent module) is (note that 'state' here
//% refers to the parent module's state)
//% @drawtiming{-w30 -f16}
//% raddr_i=X, raddr_stb_i=0, raddr_ack_o=0, state="IDLE", RD0=0, RD1=0,current_block=X,irs_raddr_ack=0.
//% raddr_i=4.
//% raddr_stb_i=1.
//% state="ADDRESS",current_block=4,RD0=1.
//% RD0=0.
//% RD0=1.
//% RD0=0.
//% RD0=1.
//% RD0=0.
//% RD0=1.
//% RD0=0,irs_raddr_ack=1.
//% state="CLEAR".
//% state="CLEAR".
//% state="RAMP".
//% state="RAMP".
//% state="READOUT",irs_raddr_ack=0,raddr_ack_o=1.
//% raddr_stb_i=0.
//% raddr_i=5,raddr_ack_o=0.
//% raddr_stb_i=1.
//% RD0=1.
//% RD0=0,irs_raddr_ack=1.
//% state="A..",current_block=5.
//% state="CLEAR".
//% state="CLEAR".
//% state="RAMP".
//% state="RAMP".
//% state="READOUT",irs_raddr_ack=0,raddr_ack_o=1.
//% raddr_stb_i=0,raddr_i=X,raddr_ack_o=0.
//% @enddrawtiming
//%
//% Notes: "raddr_stb_i" is not checked until the clock cycle after raddr_ack_o is
//%        asserted. 
//%
//%        This module only uses the direct shift-in version of the read address.
//%        for the IRS3B. 
//% Note that only one of irs_rd_o or the IRS3B control pins are valid, depending on mode.
module irs_block_readout_addr_v3b(
		input clk_i, 							//% System clock.
		input rst_i,							//% Local reset.
//		output rst_ack_o,						//% Reset acknowledge.

//		input irs_mode_i,						//% If '1', this is an IRS3. If '0' this is an IRS1-2.

		input [8:0] raddr_i,					//% Address that we're selecting.
		input raddr_stb_i,					//% If '1', go to "raddr_i" address
//		output raddr_ack_o,					//% If '1', we have reached and done Wilkinson on "raddr_i"
//		input ramp_done_i,					//% If '1', Wilkinson ramp completed
		output raddr_reached_o,				//% If '1', we have reached "raddr_i" (but no Wilkinson)

//		output [8:0] irs_rd_o,				//% RD[8:0] outputs, for an IRS2.
		output irs_rd_sclk_o,				//% RD_SCLK output, for an IRS3
		output irs_rd_dir_o,					//% RD_DIR output, for an IRS3
		output irs_rd_sin_o				//% RD_SIN output, for an IRS3
		
//		output irs_rdaddr_clr_o,			//% Request clear of read address counter // LM supposes one sycle is sufficient for CLR
//		input irs_rdaddr_clr_ack_i,		//% Acknowledge.
		
//		output [5:0] debug
    );

	//% Indicates an IRS3B.
	localparam IRS3 = 1;

	//% IRS3B shift counter. Can count up to 16. Need 10 bits.
	reg [3:0] irs_shift_counter = {4{1'b0}};
	
	//% IRS3B shift register.
	reg [8:0] irs_shift_register = {9{1'b0}};
	
	//% General-purpose waiting counter.
	reg [7:0] counter = {8{1'b0}};

	//% Indicates whether or not ramp_done_i was seen
//	reg ramp_done_seen = 0; //no need ton wait for RAMP done in this FW
	
	//% Number of cycles, minus 1, from read address on RD[8:0] to raddr_reached_o asserted.
	localparam [7:0] ASSERT_SETUP = 10;
	//% Number of cycles, minus 1, from asserting RD_DIR to first assertion of RD_SCLK.
	localparam [7:0] RD_DIR_SETUP = 10;
	//% Number of cycles, minus 1, from last SCLK low period to REACHED state.
	localparam [7:0] RD_SHIFT_HOLD = 10;
	
	// We need the top 3 bits of the counter for the shift counter.
	// The bottom 5 bits we use to divide the main clock down. That is, if it's 0
	// (the default) we move from LOW to HIGH when counter[RD_SCLK_DIV] is high.
	// Then we move from HIGH to LOW when counter[RD_SCLK_DIV] is low.
	//% Log2 of SCLK divider+1. That is, SCLK is (clk_i/(2^(1+RD_SCLK_DIV))). MUST BE 0-4!
	localparam [2:0] RD_SCLK_DIV = 0;
	//% Bit 0 of the bit counter.
	localparam [2:0] BIT_COUNT = RD_SCLK_DIV+1;

	//% Number of cycles, minus 1, that RD_SCLK is high.
	localparam [4:0] RD_SCLK_HIGH = 10;
	//% Number of cycles, minus 1, that RD_SCLK is low.
	localparam [4:0] RD_SCLK_LOW = 10;
	//% Number of shifts to perform.
	localparam [3:0] RD_NUM_SHIFTS = 9;
	
	`include "clogb2.vh"
	//% Number of bits in the state machine.
	localparam FSM_BITS = clogb2(8);
	//% State machine is idle.
	localparam [FSM_BITS-1:0] IDLE = 0;
	//% State machine has asserted RD_DIR
	localparam [FSM_BITS-1:0] SHIFT_START = 1;
	//% State machine has asserted RD_SCLK.
	localparam [FSM_BITS-1:0] SHIFT_HIGH = 2;
	//% State machine has deasserted RD_SCLK.
	localparam [FSM_BITS-1:0] SHIFT_LOW = 3;
	//% State machine has reached the final step.
	localparam [FSM_BITS-1:0] SHIFT_DONE = 4;
	//% State machine has asserted RD[8:0]
	localparam [FSM_BITS-1:0] ASSERT = 5;
	//% State machine has reached the destination address.
	localparam [FSM_BITS-1:0] REACHED = 6;
	//% Resetting.
	localparam [FSM_BITS-1:0] RESETTING = 7;
	//% Waiting for rst_i to clear.
	localparam [FSM_BITS-1:0] RESET_WAIT = 8;
	//% State variable. Begins in IDLE.
	reg [FSM_BITS-1:0] state = IDLE;
	
	wire do_reset = (rst_i && (state != RESETTING) && (state != RESET_WAIT));
	reg in_reset = 0;
	assign irs_mode_i  = 1;
	//% FSM logic. For the IRS3 this resets the counter and advances each time. Will improve later.
	always @(posedge clk_i) begin : FSM
		if (do_reset) state <= RESETTING;
		else begin
			case(state)
				IDLE: if (raddr_stb_i) begin
					if (irs_mode_i == IRS3) state <= SHIFT_START;
					else state <= ASSERT;
				end
				ASSERT: if (counter == ASSERT_SETUP) state <= REACHED;
				SHIFT_START: if (counter == RD_DIR_SETUP) state <= SHIFT_LOW;
				SHIFT_HIGH: if (counter == RD_SCLK_HIGH) state <= SHIFT_LOW;
				SHIFT_LOW: if (counter == RD_SCLK_LOW) begin
					if (irs_shift_counter == RD_NUM_SHIFTS) state <= SHIFT_DONE;
					else state <= SHIFT_HIGH;
				end
				SHIFT_DONE: if (counter == RD_SHIFT_HOLD) state <= REACHED;
//				RESETTING: if (irs_rdaddr_clr_ack_i) state <= RESET_WAIT; // No reset wait presently
				RESETTING:  state <= RESET_WAIT;
				RESET_WAIT: if (!rst_i) state <= IDLE;
//				REACHED: if (ramp_done_seen) state <= IDLE; //no wait for RAMP
				REACHED: state <= IDLE;
				default: state <= IDLE;
			endcase
		end
	end
	
	//% @brief Reset logic. in_reset=1 when rst_i is high, 0 when in RESET_WAIT and rst_i is low.
	always @(posedge clk_i) begin : IN_RESET_LOGIC
		if (do_reset) in_reset <= 1;
		else if (!rst_i && (state == RESET_WAIT)) in_reset <= 0;
   end
	
	//% @brief Counter logic. Counts up to the various delays.
	always @(posedge clk_i) begin : COUNTER_LOGIC
		if (state == ASSERT) begin
			if (counter == ASSERT_SETUP) counter <= {8{1'b0}};
			else counter <= counter + 1;
		end else if (state == SHIFT_START) begin
			if (counter == RD_DIR_SETUP) counter <= {8{1'b0}};
			else counter <= counter + 1;
		end else if (state == SHIFT_HIGH) begin
			if (counter == RD_SCLK_HIGH) counter <= {8{1'b0}};
			else counter <= counter + 1;
		end else if (state == SHIFT_LOW) begin
			if (counter == RD_SCLK_LOW) counter <= {8{1'b0}};
			else counter <= counter + 1;
		end else if (state == SHIFT_DONE) begin
			if (counter == RD_SHIFT_HOLD) counter <= {8{1'b0}};
			else counter <= counter + 1;
		end else 
			counter <= {8{1'b0}};
	end
	
	//% @brief Shift register logic.
	always @(posedge clk_i) begin : ADDRESS_LOGIC
		if (state == ASSERT || state == SHIFT_START)
			irs_shift_register <= raddr_i;
		else if (state == SHIFT_HIGH && counter == RD_SCLK_HIGH)
			irs_shift_register <= {irs_shift_register[7:0],1'b0};
		else if (state == RESETTING)
			irs_shift_register <= {9{1'b0}};
	end
	//% @brief Shift register counter.
	always @(posedge clk_i) begin : SHREG_COUNT_LOGIC
		if (state == SHIFT_HIGH && counter == RD_SCLK_HIGH)
			irs_shift_counter <= irs_shift_counter + 1;
		else if (state == IDLE)
			irs_shift_counter <= {4{1'b0}};
	end
	
	//% ramp_done rising edge flag
//	wire ramp_done_flag;
	
	//% ramp_done_i rising edge detector.
	parameter latency = 1;
//	SYNCEDGE #(.EDGE("RISING"),.LATENCY(latency),.POLARITY("POSITIVE"),.CLKEDGE("RISING")) //LM: no wait for ramp here
//		ramp_done_det(.I(ramp_done_i),.O(ramp_done_flag),.CLK(clk_i));

	//% Ramp done seen logic.
//	always @(posedge clk_i) begin : RAMP_DONE_SEEN_LOGIC //LM no wait for ramp_done
//		if (state == IDLE) ramp_done_seen <= 0;
//		else if (ramp_done_flag) ramp_done_seen <= 1;
//	end
//	
	assign raddr_reached_o = (state == REACHED);
//	assign raddr_ack_o = (state == REACHED && ramp_done_seen);	//LM no need for this ack
//	assign rst_ack_o = (state == RESET_WAIT); //LM No need here

	assign irs_rd_sclk_o = (state == SHIFT_HIGH);
	assign irs_rd_dir_o = 1'b1;
	assign irs_rd_sin_o = irs_shift_register[8];
	assign irs_rdaddr_clr_o = (state == RESETTING);

//	assign irs_rd_o = irs_shift_register;
	
//	assign debug[4:0] = state;
//	assign debug[5] = raddr_reached_o;
	
endmodule
