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
		Provides feedback for Wilkinson clock to adjust for temperature 
		variation.  It does this by monitoring the TST_OUT signal, counting 
		pulses between each REFRESH_CLK pulse.  It then adjusts the PROVDD DAC 
		output if the count falls outside of a certain range, defined in 
		parameters below.

		NOTE that this design assumes that REFRESH_CLK is truly a clock, i.e.
		that it has a regular period, although the duty cycle does not need
		to be 50%.  If the period varies then the threshold settings will 
		not be correct.


		Potential improvements:
		  - over/underflow flags for tst_counter and PROVDD
		  - faster settling to target voltage -- fast/slow regions?  PID?


	Inputs (all active high):
		xCLR_ALL			resets the counter and DAC output to default values
		xTST_OUT			input pulse from IRS/BLAB3 ASIC for ramp timing
		xREFRESH_CLK	clock signal, updates DAC setting on rising edge
		
	Outputs:
		xPROVDD[11:0]		12-bit setting for PROVDD DAC output
		xPROC_INT[11:0]	last tst_counter value, passed to USB
		xDBGVEC[31:0]		Signal routing for debugging

 ****************************************************************************/

module CTRL_LOOP_PRCO(ENABLE, xCLR_ALL, xREFRESH_CLK, xTST_OUT, xPRCO_INT, xPROVDD/*, xDBGVEC*/);

	input ENABLE;					// control loop enabled if set to 1
	input xCLR_ALL;				// reset signal for counters?
	input xREFRESH_CLK;			// refresh update clock, set in RCO_MAIN -- typ 100Hz
	input xTST_OUT;				// output from test Wilkinson counter (13th bit), typ. ~120-200kHz
	output [15:0] xPRCO_INT;	// last counter setting (passed to USB MESS)
	output [11:0] xPROVDD;		// DAC setting for Wilkinson clock control
//	output [31:0] xDBGVEC;		// DEBUG signals only! 
	
	reg	[15:0] xPRCO_INT;
	reg	[11:0] xPROVDD;
	wire	[15:0] tst_counter;
	reg	toolow, toohigh;
	
	//////////////////////////////////////////////////////////////////////////
	// configuration parameters are set here

	parameter MIN_PROVDD = 12'h000;		// upper/lower limits on PRCO output values
	parameter MAX_PROVDD = 12'hFFF;
	
	//parameter INITIAL_VALUE = 12'h46C;	// initial ADC output to fall within limits set below		
	parameter INITIAL_VALUE = 12'd3000;	// initial ADC output to fall within limits set below	

//	parameter MIN_LIMIT = 20'd1800;		// low TST_OUT count limit
//	parameter MAX_LIMIT = 20'd1816;		// upper TST_OUT count limit
	parameter MIN_LIMIT = 20'd1040;		// low TST_OUT count limit
	parameter MAX_LIMIT = 20'd1042;		// upper TST_OUT count limit

	//////////////////////////////////////////////////////////////////////////
/*
	assign xDBGVEC[0] = xCLR_ALL;
	assign xDBGVEC[1] = xREFRESH_CLK;
	assign xDBGVEC[2] = xTST_OUT;
	assign xDBGVEC[3] = 1'b0;
	assign xDBGVEC[15:4]  = xPROVDD;
	assign xDBGVEC[31:16] = tst_counter[19:4];
*/
	initial begin
		xPROVDD <= INITIAL_VALUE;
		xPRCO_INT <= 12'h000;
	end
/*	
	// synchronize the xCLR_ALL and xREFRESH_CLK inputs to the xTST_OUT signal
	always @ (posedge xTST_OUT) begin
		if (xCLR_ALL | xREFRESH_CLK) begin
			if (counter_reset)	counter_reset = 0;
			else						counter_reset = 1;

		end
	end
*/	
	// instantiate the counter itself
	wire counter_reset = xCLR_ALL | xREFRESH_CLK;
	COUNTER20	counter20(tst_counter, counter_reset, xTST_OUT);

	// handle when xREFRESH_CLK comes in
	always @ (posedge xCLR_ALL or posedge xREFRESH_CLK) begin
		if (xCLR_ALL) 
			xPROVDD <= INITIAL_VALUE;
		
		else begin
			toolow  <= (tst_counter < MIN_LIMIT);
			toohigh <= (tst_counter > MAX_LIMIT);

			case ({ENABLE,toolow,toohigh})
				3'b101: begin
					if (xPROVDD > MIN_PROVDD)
						xPROVDD <= xPROVDD - 12'h001;			// decrease DAC output
				end

				3'b110:	// too low
					if (xPROVDD < MAX_PROVDD)
						xPROVDD <= xPROVDD + 12'h001;			// increase DAC output

				default:	; // do nothing if not enabled (0xx), within window (100), or invalid (x11)
							  //		ensures all case statements covered
			endcase

			xPRCO_INT <= tst_counter;
//			xPRCO_INT <= tst_counter[15:0];	// record bits 0 to 15 (lower 16) of last counter value
//			xPRCO_INT <= tst_counter[19:4];	// record bits 4 to 19 (upper 16) of last counter value
		end
	end

endmodule

////////////////////////////////////////////////////////////////////////////////
// 20-bit up counter with reset

module COUNTER20(data, rst, clk);
	output [15:0] data;
	input         rst;
	input         clk;
	
	reg    [15:0] data;
	
	always @ (posedge clk)
		if (rst)		data <= 16'h0000;
		else			data <= data + 1'b1;
endmodule