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
	Started:		7 Nov 2011
	Project:		Belle II iTOP firmware

	Description:
		Provides basic round-robin scheduling for the 16 ASICs to share
		the single sampling control loop instance.  This is primarily
		controlled by the REFRESH_CLK signal.
		
		When REFRESH_CLK goes high, the scheduler will reset the sampling
		control loop and increment the ASIC index.  It holds the control
		loop in reset until REFRESH_CLK goes low (since the control loop
		does nothing during that time) then lets it run until 64 REFRESH_CLK
		cycles complete.
		
		All signals other than SSP_OUT, VADJN, and VADJP are simply passed 
		through to the SMPL_CTRL_LOOP module; this scheduler alternates
		between each of the 16 possible ASICs with each REFRESH_CLK.

	Inputs (all active high):
		ENABLE				(passthru)	enable control loop feedback
		CLR_ALL				(passthru)	resets the up/down counter and DAC output to default values
		PULSEDET_CLK		(passthru)	clock for pulse detection; should be same freq as SSP_OUT
		REFRESH_CLK			(passthru)	clock signal, updates DAC setting on rising edge
		SSP_IN[15:0]		(vector)		sample control pulse from IRS_MAIN
		SSP_OUT[15:0]		(vector)		delayed sample control pulse from IRS/BLAB3
		INITIAL_VADJP		(passthru)	set VADJP to this on CLR_ALL
		INITIAL_VADJN		(passthru)	set VADJN to this on CLR_ALL
		SMPL_THRESH_LOW	(passthru)	low threshold for delta counter
		SMPL_THRESH_HIGH	(passthru)	high threshold for delta counter

	Outputs:
		SMPL_INT[15:0]		(passthru)	16-bit output for USB monitoring, currently last delta reading
		VADJN[15:0]			(vector)		12-bit setting for PROVDD DAC output
		VADJP[15:0]			(vector)		12-bit setting for PROVDD DAC output				
		NO_PULSE				(passthru)	Signal identifying lack in SSP_OUT pulses
		
 ****************************************************************************/

module CTRL_LOOP_SMPL_SCHEDULER(ENABLE, CLR_ALL, PULSEDET_CLK, REFRESH_CLK, 
								SSP_IN, SSP_OUT, 
								
								SMPL_INT15, SMPL_INT14, SMPL_INT13, SMPL_INT12, SMPL_INT11, SMPL_INT10, SMPL_INT09, SMPL_INT08, 
								SMPL_INT07, SMPL_INT06, SMPL_INT05, SMPL_INT04, SMPL_INT03, SMPL_INT02, SMPL_INT01, SMPL_INT00, 
								
								//VADJP, VADJN, 
								//VADJP_FLAT, VADJN_FLAT, 

								VADJP15, VADJP14, VADJP13, VADJP12, VADJP11, VADJP10, VADJP09, VADJP08, 
								VADJP07, VADJP06, VADJP05, VADJP04, VADJP03, VADJP02, VADJP01, VADJP00, 

								VADJN15, VADJN14, VADJN13, VADJN12, VADJN11, VADJN10, VADJN09, VADJN08, 
								VADJN07, VADJN06, VADJN05, VADJN04, VADJN03, VADJN02, VADJN01, VADJN00, 
								
								NO_PULSE,
								INITIAL_VADJP, INITIAL_VADJN,
								SMPL_THRESH_LOW, SMPL_THRESH_HIGH);

	input ENABLE;							// control loop enable
	input CLR_ALL;							// reset signal for counters?
	input PULSEDET_CLK;					// main clock -- used to detect lack of pulses
	input REFRESH_CLK;					// refresh update clock, set in RCO_MAIN -- typ 100Hz
	input SSP_IN;							// pre-delay sampling input
	input [15:0] SSP_OUT;				// post-delay sampling input (vector of 16)

	output [15:0]	SMPL_INT15, SMPL_INT14, SMPL_INT13, SMPL_INT12, SMPL_INT11, SMPL_INT10, SMPL_INT09, SMPL_INT08, 
						SMPL_INT07, SMPL_INT06, SMPL_INT05, SMPL_INT04, SMPL_INT03, SMPL_INT02, SMPL_INT01, SMPL_INT00;

	output [11:0]	VADJP15, VADJP14, VADJP13, VADJP12, VADJP11, VADJP10, VADJP09, VADJP08, 
						VADJP07, VADJP06, VADJP05, VADJP04, VADJP03, VADJP02, VADJP01, VADJP00;
	output [11:0]	VADJN15, VADJN14, VADJN13, VADJN12, VADJN11, VADJN10, VADJN09, VADJN08, 
						VADJN07, VADJN06, VADJN05, VADJN04, VADJN03, VADJN02, VADJN01, VADJN00;

	output       	NO_PULSE;

	input [11:0]	INITIAL_VADJP, 
						INITIAL_VADJN;		// current DAC settings
	input [19:0]	SMPL_THRESH_LOW,
						SMPL_THRESH_HIGH; // threshold for DAC adjust

	reg [15:0]		SMPL_INT15, SMPL_INT14, SMPL_INT13, SMPL_INT12, SMPL_INT11, SMPL_INT10, SMPL_INT09, SMPL_INT08, 
						SMPL_INT07, SMPL_INT06, SMPL_INT05, SMPL_INT04, SMPL_INT03, SMPL_INT02, SMPL_INT01, SMPL_INT00;

	reg [11:0]		VADJP15, VADJP14, VADJP13, VADJP12, VADJP11, VADJP10, VADJP09, VADJP08, 
						VADJP07, VADJP06, VADJP05, VADJP04, VADJP03, VADJP02, VADJP01, VADJP00;
	reg [11:0]		VADJN15, VADJN14, VADJN13, VADJN12, VADJN11, VADJN10, VADJN09, VADJN08, 
						VADJN07, VADJN06, VADJN05, VADJN04, VADJN03, VADJN02, VADJN01, VADJN00;

	//////////////////////////////////////////////////////////////////////////

	parameter	FSM_RESET  = 0;
	parameter	FSM_COUNT  = 1;
	parameter	FSM_INCR   = 2;

	reg			fsm_reset_out;
	reg  [2:0]	fsm_mode;
	reg  [3:0]	node;
	//reg  [5:0]	node_ctr;

	wire			cur_ssp_out;
	wire [11:0]	cur_vadjp, cur_vadjn;
	wire [19:0]	smpl_int_out;
	wire [15:0] cur_smpl_int;
	
	initial begin
		fsm_mode = 0;
		fsm_reset_out = 0;
		node = 0;
		//node_ctr = 0;
	end
	
	// assign current node's SSP_OUT to the control loop's input
	assign cur_ssp_out = SSP_OUT[node];

	always @(posedge PULSEDET_CLK) begin		
		case (fsm_mode)
			// reset the counter
			FSM_RESET: begin	
				fsm_reset_out <= 1;
				//node_ctr <= 0;
				if (!REFRESH_CLK)	fsm_mode <= FSM_COUNT;	// don't leave reset state until REFRESH_CLK disappears
			end

			// attach output and let it run for remainder of refresh_clk cycle
			FSM_COUNT: begin	
				fsm_reset_out <= 0;
//				VADJP[node] <= cur_vadjp;
//				VADJN[node] <= cur_vadjn;
				case (node)
					4'b0000: begin	VADJP00 <= cur_vadjp;	VADJN00 <= cur_vadjn;	SMPL_INT00 <= cur_smpl_int;	end
					4'b0001: begin	VADJP01 <= cur_vadjp;	VADJN01 <= cur_vadjn;	SMPL_INT01 <= cur_smpl_int;	end
					4'b0010: begin	VADJP02 <= cur_vadjp;	VADJN02 <= cur_vadjn;	SMPL_INT02 <= cur_smpl_int;	end
					4'b0011: begin	VADJP03 <= cur_vadjp;	VADJN03 <= cur_vadjn;	SMPL_INT03 <= cur_smpl_int;	end
					4'b0100: begin	VADJP04 <= cur_vadjp;	VADJN04 <= cur_vadjn;	SMPL_INT04 <= cur_smpl_int;	end
					4'b0101: begin	VADJP05 <= cur_vadjp;	VADJN05 <= cur_vadjn;	SMPL_INT05 <= cur_smpl_int;	end
					4'b0110: begin	VADJP06 <= cur_vadjp;	VADJN06 <= cur_vadjn;	SMPL_INT06 <= cur_smpl_int;	end
					4'b0111: begin	VADJP07 <= cur_vadjp;	VADJN07 <= cur_vadjn;	SMPL_INT07 <= cur_smpl_int;	end
					4'b1000: begin	VADJP08 <= cur_vadjp;	VADJN08 <= cur_vadjn;	SMPL_INT08 <= cur_smpl_int;	end
					4'b1001: begin	VADJP09 <= cur_vadjp;	VADJN09 <= cur_vadjn;	SMPL_INT09 <= cur_smpl_int;	end
					4'b1010: begin	VADJP10 <= cur_vadjp;	VADJN10 <= cur_vadjn;	SMPL_INT10 <= cur_smpl_int;	end
					4'b1011: begin	VADJP11 <= cur_vadjp;	VADJN11 <= cur_vadjn;	SMPL_INT11 <= cur_smpl_int;	end
					4'b1100: begin	VADJP12 <= cur_vadjp;	VADJN12 <= cur_vadjn;	SMPL_INT12 <= cur_smpl_int;	end
					4'b1101: begin	VADJP13 <= cur_vadjp;	VADJN13 <= cur_vadjn;	SMPL_INT13 <= cur_smpl_int;	end
					4'b1110: begin	VADJP14 <= cur_vadjp;	VADJN14 <= cur_vadjn;	SMPL_INT14 <= cur_smpl_int;	end
					4'b1111: begin	VADJP15 <= cur_vadjp;	VADJN15 <= cur_vadjn;	SMPL_INT15 <= cur_smpl_int;	end
				endcase
				//node_ctr <= node_ctr + 1;
				//if (node_ctr == 6'b111111)	fsm_mode <= FSM_INCR;
				if (REFRESH_CLK)	fsm_mode <= FSM_INCR;
			end	
			
			// move to next node, restart FSM
			FSM_INCR: begin
				node <= node + 1;
				fsm_mode <= FSM_RESET;
			end

			// should never get here
			default: begin	
				fsm_mode <= FSM_RESET;
			end			
		endcase
	end

//2011-11-28 Kurtis: Commenting out this instantiation to see if it allows compilation.
//                   With this instantiated, map always fails with no specific errors. 
//	CTRL_LOOP_SMPL	ctrl_loop_smpl(ENABLE | !fsm_reset_out, CLR_ALL | fsm_reset_out,
//												PULSEDET_CLK, REFRESH_CLK,
//												SSP_IN,
//												cur_ssp_out,
//												cur_smpl_int,
//												cur_vadjp,
//												cur_vadjn,
//												NO_PULSE, INITIAL_VADJP, INITIAL_VADJN,
//												SMPL_THRESH_LOW, SMPL_THRESH_HIGH);

endmodule
