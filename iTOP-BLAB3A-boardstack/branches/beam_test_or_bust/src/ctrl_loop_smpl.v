`timescale 1ns/1ps

/****************************************************************************
	University of Hawaii at Manoa
	Instrumentation Development Lab / GARY S. VARNER
	Watanabe Hall Room 214
	2505 Correa Road
	Honolulu, HI 96822
	Lab: (808) 956-2920
	Fax: (808) 956-2930
	E-mail: idlab@phys.hawaii.edu
	
AND
	
	Pacific Northwest National Laboratory
	902 Battelle Blvd., MS J4-60
	Richland, WA  99352
	
 ****************************************************************************

	Design by:	Lynn Wood, PNNL (lynn.wood@pnnl.gov)
	Started:		19 Jun 2011
	Project:		Belle II iTOP firmware

	Description:
		Provides feedback for the sampling rate circuitry to adjust for 
		temperature variation.  It does this by feeding the SSPin signal
		through a delay chain of fixed length and comparing the output to the
		SSPout signal.  It then builds up statistics in a up/down delta 
		counter, representing how many times the SSPout timing was faster or 
		slower than the delay chain sequence.

		When the REFRESH_CLK signal occurs, the delta counter is checked and 
		the VADJN and VADJP DAC outputs adjusted accordingly if the delta 
		range is outside the allowed window (defined below).


	Inputs (all active high):
		ENABLE				enable control loop feedback
		CLR_ALL				resets the up/down counter and DAC output to default values
		PULSEDET_CLK		clock for pulse detection; should be same freq as SSP_OUT
		REFRESH_CLK			clock signal, updates DAC setting on rising edge
		SSP_IN				sample control pulse from IRS_MAIN
		SSP_OUT				delayed sample control pulse from IRS/BLAB3
		INITIAL_VADJP		set VADJP to this on CLR_ALL
		INITIAL_VADJN		set VADJN to this on CLR_ALL
		SMPL_THRESH_LOW	low threshold for delta counter
		SMPL_THRESH_HIGH	high threshold for delta counter

	Outputs:
		SMPL_INT				20-bit output for USB monitoring, currently last delta reading
		VADJN					12-bit setting for PROVDD DAC output
		VADJP					12-bit setting for PROVDD DAC output				
		NO_PULSE				Signal identifying lack in SSP_OUT pulses
		
 ****************************************************************************/

module CTRL_LOOP_SMPL(ENABLE, CLR_ALL, PULSEDET_CLK, REFRESH_CLK, SSP_IN, SSP_OUT, 
								SMPL_INT, VADJP, VADJN, NO_PULSE,
								INITIAL_VADJP, INITIAL_VADJN,
								SMPL_THRESH_LOW, SMPL_THRESH_HIGH);

	input ENABLE;						// control loop enable
	input CLR_ALL;						// reset signal for counters?
	input PULSEDET_CLK;					// main clock -- used to detect lack of pulses
	input REFRESH_CLK;				// refresh update clock, set in RCO_MAIN -- typ 100Hz
	input SSP_IN;						// pre-delay sampling input
	input SSP_OUT;						// post-delay sampling input

	output [15:0] SMPL_INT;			// useful data to USB interface
	output [11:0] VADJP, VADJN;	// DAC settings
	output        NO_PULSE;

	input [11:0] INITIAL_VADJP, 
	             INITIAL_VADJN;	// current DAC settings
	input [19:0] SMPL_THRESH_LOW,
	             SMPL_THRESH_HIGH;// threshold for DAC adjust


	reg [15:0] SMPL_INT;				// reg for output (all others reg inside counters)

	//////////////////////////////////////////////////////////////////////////

	reg		  adjstep;			// are we adjusting VADJN or VADJP?

	wire [19:0] delta;			// delta counter (probably larger than necessary)

	//////////////////////////////////////////////////////////////////////////
	// tunable parameters

	// changing these values affects the sensitivity of the adjustment; the
	// delta counter needs to exceed one of these values for a DAC output
	//	to change.  Values closer to 80000 (midpoint) provide greater sensitivity.
	
//	parameter SMPL_THRESH_LOW	 = 20'h7FFF0;	// lower allowed delta counter limit
//	parameter SMPL_THRESH_HIGH =	20'h80010;	// upper allowed delta counter limit

	//////////////////////////////////////////////////////////////////////////
	// pulse detector -- don't adjust voltages if SSP_OUT missing any pulses
	//
	//		This could be implemented more "elegantly" as an FSM, but the
	//		variation in the position/width of the SSP_OUT signal actually
	//		makes that fairly complicated (input is ~asynchronous from
	//		the state machine clock).
	//
	
	reg [3:0]	pulse_counter;	
	reg [2:0]	fastclk_counter;
	reg			pulse_counter_reset;
	reg			hold_nopulses;


	initial begin
		pulse_counter = 0;
		fastclk_counter = 0;
		hold_nopulses = 1;
		pulse_counter_reset = 0;
	end


	// SSP_OUT pulse counter
	always @(posedge pulse_counter_reset or posedge SSP_OUT) begin
		if (pulse_counter_reset)	pulse_counter <= 0;
		else								pulse_counter <= pulse_counter + 1;
	end

	// PULSEDET_CLK counter (should have same frequency as clock that generates SSP_OUT)
	always @(posedge PULSEDET_CLK) begin
		if (fastclk_counter == 3'b111) begin
			// reset counter
			pulse_counter_reset <= 1;
			fastclk_counter <= 0;

			// check pulse_counter to see if it holds expected value 
			//		(should see 8 SSP_OUT pulses in 8 PULSEDET_CLK pulses)
			if (pulse_counter != 3'b111)		hold_nopulses <= 1;		// stop making voltage adjustments
			else										hold_nopulses <= 0;
		end
		else begin
			// increment counter
			fastclk_counter <= fastclk_counter + 1;
			pulse_counter_reset <= 0;
		end

	end

	assign NO_PULSE = hold_nopulses;

	//////////////////////////////////////////////////////////////////////////

	// provide latched "last delta count" to USB
	always @ (posedge REFRESH_CLK) begin
		SMPL_INT <= delta[19:4];	//delta;
	end

	initial begin
		adjstep <= 0;		// start in known state
	end

	always @ (posedge REFRESH_CLK) begin
		if (toolow | toohigh)		// when an adjustment will occur
			adjstep <= ~adjstep;		// flip the toggle for which DAC gets adjusted
	end

	//////////////////////////////////////////////////////////////////////////
	// carry chain

	// this is necessary to allow SSP_IN (PLL output) to attach to logic in a
	// fixed location (carry chain) -- there's a restriction about things being
	// in the same horizontal row, which is currently not the case.  Adding the
	// BUFG allows the connection.
	//
	// There is also a UCF requirement for the BUFG to allow routing a clock 
	// signal to logic, i.e. 
	//		PIN "map_CTRL_LOOP_SMPL/SSP_IN_BUF.O" CLOCK_DEDICATED_ROUTE = FALSE;
	
//	wire SSP_IN_buffered;
//	BUFG SSP_IN_BUF(.I(SSP_IN), .O(SSP_IN_buffered));
	assign SSP_IN_buffered = SSP_IN;
	
	wire SSP_IN_delayed;
	SMPL_CARRY_CHAIN	carry_chain(SSP_IN_buffered, SSP_IN_delayed);
 
	//////////////////////////////////////////////////////////////////////////
	// delta counter

	// instantiate up/down counter for delta:
	//		- updates on falling edge of xSSP_IN_delayed
	//		- counts up if xSSP_OUT is 1
	//		- counts down if xSSP_OUT is 0
	//
	//			NOTE that this counter's clock is asynchronous compared to the rest of the design!
	//

	wire delta_reset = REFRESH_CLK;	// THIS IS NOT RIGHT!  NEED EDGE DETECTOR FOR REFRESH_CLK? (so it counts when REFRESH_CLK is high)

	UPDOWN20 updown20(delta, SSP_OUT, delta_reset, ~SSP_IN_delayed);

	//////////////////////////////////////////////////////////////////////////
	// DAC setting counters

	// How all this is related:
	//
	//		toolow	toohigh	adjstep		justright	hold_vadjp	hold_vadjn	updown_vadjp	updown_vadjn
	//			0			0			x		=>		1				1				1					x					x			do nothing
	//			1			0			0		=>		0				1				0					x					0			decrease VADJN
	//			1			0			1		=>		0				0				1					1					x			increase VADJP
	//			0			1			0		=>		0				1				0					x					1			increase VADJN
	//			0			1			1		=>		0				0				1					0					x			decrease VADJP
	//			1			1			x		=>		1				1				1					x					x			do nothing

	// signals to identify what adjustment needs to be made
	wire toolow    =  ENABLE & (delta < SMPL_THRESH_LOW);
	wire toohigh   =  ENABLE & (delta > SMPL_THRESH_HIGH);
	wire justright =  ~(toolow ^ toohigh);		// no change if both are 0 (or both are 1, which shouldn't happen)

	// the "hold" signals prevent changes to the DAC outputs, and control (with adjstep)
	// the alternation between VADJP and VADJN
	wire hold_vadjp = justright || (toohigh && !adjstep) || (toolow &&  adjstep);
	wire hold_vadjn = justright || (toohigh &&  adjstep) || (toolow && !adjstep);

	// signals to determine whether the DAC counters should increase or decrease
	wire updown_vadjp = !toohigh &  toolow;
	wire updown_vadjn =  toohigh & !toolow;
	

	UPDOWN12INIT vadjn(VADJN, updown_vadjn, hold_vadjn, CLR_ALL || hold_nopulses, REFRESH_CLK, INITIAL_VADJN);
	UPDOWN12INIT vadjp(VADJP, updown_vadjp, hold_vadjp, CLR_ALL || hold_nopulses, REFRESH_CLK, INITIAL_VADJP);

endmodule

//////////////////////////////////////////////////////////////////////////
// 12- and 16-bit up/down counters

module UPDOWN12INIT(data, updown, hold, rst, clk, initialvalue);
	output [11:0] data;
	input			  updown;	// 0=decrement, 1=increment
	input			  hold;		// 0=update counter, 1=don't update
	input         rst;
	input         clk;
	input  [11:0] initialvalue;
	
	reg    [11:0] data;
	
	always @ (posedge clk) begin
		if (rst)		data <= initialvalue;	// reset to midpoint of counter
		else if (~hold) begin

			if (updown) begin
				if (data < 12'hFFF)		data <= data + 1;
			end
			else begin
				if (data > 12'h000)		data <= data - 1;
			end

		end
	end
endmodule

//////////

module UPDOWN20(data, updown, rst, clk);
	output [19:0] data;
	input			  updown;	// 0=decrement, 1=increment
	input         rst;
	input         clk;
	
	reg    [19:0] data;
	
	always @ (posedge clk) begin
		if (rst)		data <= 20'h80000;	// reset to midpoint of counter
		else begin
			if (updown)
				if (data < 20'hFFFFF)		data <= data + 1'b1;
				else								data <= data;
			else
				if (data > 20'h00000) 		data <= data - 1'b1;
				else								data <= data;
		end
	end
endmodule

