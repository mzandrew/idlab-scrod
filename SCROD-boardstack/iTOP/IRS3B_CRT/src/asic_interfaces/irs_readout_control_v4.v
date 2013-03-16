`timescale 1ns / 1ps
/**
 * @file irs_readout_control_v3.v Contains irs_readout_control_v3 module.
 */

//% @brief IRS readout control module.
//%
//% IRS readout control module. This module handles the readout of data
//% (and *only* the readout of data) from an IRS. The various timing parameters
//% for data settling are contained here as well.
module irs_readout_control_v4(
		input clk_i, 							//% System clock
		input clk_en,                    //% Kurtis added a clock enable to sync with the digitizing block
		input rst_i, 							//% Local reset
//		input test_mode_i,					//% Bypass input data, replace with test pattern (STACK,CH,SMP)
		input start_i,							//% Signal to begin readout.
		input increment,						// LM: increment =1 - just increments the address, 0 sets the input
		
		output new_sample_address_reached, //LM new to indicate end of shreg
//		output [11:0] dat_o,					//% The output data
//		output valid_o,						//% Output data is valid
//		output done_o,							//% Output data is complete (asserted with valid_o on last data)
		
//		input [7:0] ch_sel_i,		   	//% Channel select for this block readout.
		input [2:0]	sel_channel,				//channel select for exclusive reading
		
//		output [5:0] irs_smp_o,				//% SMP[5:0] outputs
//		output [2:0] irs_ch_o,				//% CH[2:0] outputs
		output DO_DIR,
		output DO_SIN,
		output  DO_SCLK
//		output irs_smpall_o,					//% Data output enable.
//		input [11:0] irs_dat_i				//% DAT[11:0] inputs
		
//		output [12:0] debug
    );
	
	parameter [1:0] STACK_NUMBER = 2'b00;
	
	// These parameters should be tuned to be the minimum needed for stable data.
	// This can easily be checked by reading out the same data with these parameters
	// changed inbetween.

	localparam COUNTER_WIDTH = 4;

	//% Number of cycles, minus 1, between assertion of SMP/CH and latching data
	localparam [COUNTER_WIDTH-1:0] DATA_SETUP_CYCLES = 3;
	//% Number of hold cycles after latching data before changing address (this should be zero).
	localparam [COUNTER_WIDTH-1:0] DATA_HOLD_CYCLES = 1;
	//% Number of additional cycles, minus 1, needed when asserting SMPALL before latching data
	localparam [COUNTER_WIDTH-1:0] SMPALL_SETUP_CYCLES = 0;
	//% Number of additional cycles, minus 1, needed when changing CH.
	localparam [COUNTER_WIDTH-1:0] CHANNEL_SETUP_CYCLES = 0;

	//% General-purpose counter.
	reg [COUNTER_WIDTH-1:0] counter = {COUNTER_WIDTH{1'b0}}; 
	//% Sample counter.
	reg [5:0] sample_counter = {6{1'b0}};
	//% Channel pointer.
	reg [2:0] channel_counter = {3{1'b0}};

	
`include "clogb2.vh"
	//% Number of bits in the state machine.
	localparam FSM_BITS = clogb2(7);
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
	localparam [FSM_BITS-1:0] INCREMENT_WAIT = 5;
	//% State machine has reached the destination address.
	localparam [FSM_BITS-1:0] INCREMENT = 6;
	//% Resetting.
	localparam [FSM_BITS-1:0] READ_DONE = 7;
	//% State variable. Begins in IDLE.
	reg [FSM_BITS-1:0] state = IDLE;
	
	
	//% Number of cycles, minus 1, that RD_SCLK is high.
	localparam [4:0] DO_SCLK_HIGH = 10;
	//% Number of cycles, minus 1, that RD_SCLK is low.
	localparam [4:0] DO_SCLK_LOW = 10;
	//% Number of shifts to perform.
	localparam [3:0] DO_NUM_SHIFTS = 9;
	

	//% Number of cycles, minus 1, from asserting RD_DIR to first assertion of RD_SCLK.
	localparam [7:0] DO_DIR_SETUP = 10;
	//% Number of cycles, minus 1, from last SCLK low period to REACHED state.
	localparam [7:0] DO_SHIFT_HOLD = 10;	
	//% Number of cycles, minus 1, to allow latching of data.
	localparam [7:0] INCREMENT_WAIT_TIME = 1;	
	//% Number of cycles, minus 1, to allow increment DO_SCLK to be read by IRS3.
	localparam [7:0] INCREMENT_TIME = 1;	
	//% Number of cycles, minus 1, to allow increment DO_SCLK to be read by IRS3.
//	localparam [11:0] TOT_SAMPLES = 64*4+63;	//should be only one window! but *8 channels! now only selected channel #5 -- see below
//	wire [11:0] TOT_SAMPLES;//	= 64*4+63;	
//	assign TOT_SAMPLES = {3'b000, sel_channel, 6'b111111}; 

	wire [8:0] TOT_SAMPLES;//	= 64*4+63;	
	assign TOT_SAMPLES = {sel_channel, 6'b111111}; 
//	assign TOT_SAMPLES = {3'b000, sel_channel+1, 6'b111111}; //ends at end next channel

	//% IRS3B shift counter. Can count up to 16. Need 4 bits.
	reg [3:0] irs_shift_counter = {4{1'b0}};
	//% IRS3B shift counter. Can count up to channels*samples. Need 9 bits.
	reg [9:0] number_increments = {10{1'b0}};
	
	//LM new from here
	//% FSM logic. For the IRS3B this resets the counter to 0 and uses increment each time. 
	always @(posedge clk_i) begin : FSM
		if (rst_i) state <= IDLE;
		else if (clk_en) begin
			case(state)
				IDLE: if (start_i) begin
					if (increment)
						state <= SHIFT_START;
					else
						state <= INCREMENT;
				end
				SHIFT_START: if (counter == DO_DIR_SETUP) state <= SHIFT_LOW;
				SHIFT_HIGH: if (counter == DO_SCLK_HIGH) state <= SHIFT_LOW;
				SHIFT_LOW: if (counter == DO_SCLK_LOW) begin
					if (irs_shift_counter == DO_NUM_SHIFTS) state <= SHIFT_DONE;
					else state <= SHIFT_HIGH;
				end
				SHIFT_DONE: state <= IDLE;
//				SHIFT_DONE: if (counter == DO_SHIFT_HOLD) state <= INCREMENT_WAIT;
				INCREMENT_WAIT: if (counter == INCREMENT_WAIT_TIME) begin
//						if (number_increments == TOT_SAMPLES) state <= READ_DONE;
				 state <= READ_DONE; // only one increment!
//					else state <= INCREMENT;
				end
				INCREMENT: if (counter == INCREMENT_TIME)
					 state <= INCREMENT_WAIT;	
				READ_DONE: state <= IDLE;
				default: state <= IDLE;
			endcase
		end
	end
	
	//% @brief Counter logic. Counts up to the various delays.
	always @(posedge clk_i) begin : COUNTER_LOGIC
		if (clk_en) begin
			if (state == SHIFT_START) begin
				if (counter == DO_DIR_SETUP) counter <= {8{1'b0}};
				else counter <= counter + 1;
			end else if (state == SHIFT_HIGH) begin
				if (counter == DO_SCLK_HIGH) counter <= {8{1'b0}};
				else counter <= counter + 1;
			end else if (state == SHIFT_LOW) begin
				if (counter == DO_SCLK_LOW) counter <= {8{1'b0}};
				else counter <= counter + 1;
			end else if (state == SHIFT_DONE) begin
				if (counter == DO_SHIFT_HOLD) counter <= {8{1'b0}};
				else counter <= counter + 1;
			end else if (state == INCREMENT_WAIT) begin
				if (counter == INCREMENT_WAIT_TIME) counter <= {8{1'b0}};
				else counter <= counter + 1;
			end else if (state == INCREMENT) begin
				if (counter == INCREMENT_TIME) counter <= {8{1'b0}};
				else counter <= counter + 1;
			end else 
				counter <= {8{1'b0}};
		end
	end

	//% @brief Shift register counter. - the input is set to 0 to reset
	always @(posedge clk_i) begin : SHREG_COUNT_LOGIC
		if (clk_en) begin
			if (state == SHIFT_HIGH && counter == DO_SCLK_HIGH)
					irs_shift_counter <= irs_shift_counter + 1;
			else if (state == IDLE)
				irs_shift_counter <= {4{1'b0}};
		end
	end
////% @brief Tot sample register counter. - the input is set to 0 to reset
//	always @(posedge clk_i) begin : TOT_SAMPLE_COUNT_LOGIC
//		if (state == INCREMENT && counter == INCREMENT_TIME)
//			number_increments <= number_increments + 1;
//		else if (state == IDLE)
////			number_increments <= {9{1'b0}};
////			number_increments <= 256; //starts at channel 5 already
//			number_increments <= {1'b0, sel_channel, 	{6{1'b0}}}; //starts at channel x already
////			number_increments <= {sel_channel, 	1'b1, {5{1'b0}}}; //starts at midchannel x already
//	end
//		
////	assign DO_SIN = 0; // LM use serial in only to reset.
////	wire [8:0] START_ADDRESS = 9'b000000001; // starts with channel 5
	wire [8:0] START_ADDRESS = {6'b000000, sel_channel[0], sel_channel[1], sel_channel[2]}; // starts with channel sel_channel -- reverse!
//	wire [8:0] START_ADDRESS = {6'b000001, sel_channel[0], sel_channel[1], sel_channel[2]}; // starts with midchannel sel_channel -- reverse!
	reg DO_SIN_int;
//	assign DO_SIN = DO_SIN_int;
	wire [9:0] START_ADDRESS_EXTENDED = {START_ADDRESS, 1'b0};
	assign DO_SIN = START_ADDRESS_EXTENDED[irs_shift_counter];
//	always @(irs_shift_counter) begin
//		DO_SIN_int <= START_ADDRESS[irs_shift_counter];
//	end
	
	assign DO_SCLK = (state == SHIFT_HIGH) || (state == INCREMENT); //this guarantees a rising edge per shift and increment
	assign DO_DIR = ~((state == INCREMENT) || (state == INCREMENT_WAIT) || (state==IDLE)); //DIR is 0 - increment - only in the increment phase and in IDLE
																														//LM: to make sure enough margins
	
	
	//LM to here

	
	
	
//	//% Latched data from the IRS.
//	reg [11:0] latched_data = {12{1'b0}};
//	//% Data valid indicator.
//	reg latched_data_valid = 0;
//	//% Data done indicator.
//	reg latched_data_done = 0;

//	//% Data is latched during DATA_SETUP after DATA_SETUP_CYCLES have completed.
//	always @(posedge clk_i) begin : LATCHED_DATA_LOGIC
//		if (state == INCREMENT_WAIT && counter == INCREMENT_WAIT_TIME) begin
////			if (!test_mode_i)
//				latched_data <= irs_dat_i;
////			else
////				latched_data <= {1'b0,STACK_NUMBER,channel_counter,sample_counter};
//		end
//	end
//	//% Flag indicating data is valid and should be latched.
//	always @(posedge clk_i) begin : LATCHED_DATA_VALID_LOGIC
//		if (state == INCREMENT_WAIT && counter == INCREMENT_WAIT_TIME)
//			latched_data_valid <= 1;
//		else
//			latched_data_valid <= 0;
//	end
//	//% Flag indicating this data is the last one.
//	always @(posedge clk_i) begin : LATCHED_DATA_DONE_LOGIC
//		if (state == READ_DONE)
//			latched_data_done <= 1;
//		else
//			latched_data_done <= 0;
//	end
 assign new_sample_address_reached = ((state == SHIFT_DONE) || (state == READ_DONE));
//	assign dat_o = latched_data;
//	assign valid_o = latched_data_valid;
//	assign done_o = latched_data_done;

//	assign irs_smp_o = sample_counter;
//	assign irs_ch_o = channel_counter;
//	assign irs_smpall_o = (state != IDLE);
	
//	assign debug[2:0] = state;
//	assign debug[11:3] = number_increments;
//	assign debug[12] = done_o;
	
endmodule
