`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:58:13 10/15/2012 
// Design Name: 
// Module Name:    program_DACs 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module program_DACs(
	input clk,
	input do_load,
	input [11:0] THR1, //1
	input [11:0] THR2, //2
	input [11:0] THR3, //3
	input [11:0] THR4, //4
	input [11:0] THR5, //5
	input [11:0] THR6, //6
	input [11:0] THR7, //7
	input [11:0] THR8, //8
	input [11:0] VBDBIAS, //9
	input [11:0] VBIAS, //10
	input [11:0] VBIAS2, //11
	input [7:0] MiscReg, //12(incl. SGN)
	input [11:0] WBDbias, //13
	input [11:0] Wbias, //14
	input [11:0] TCDbias, //15
	input [11:0] TRGbias,//16
	input [11:0] THDbias,//17
	input [11:0] Tbbias,//18
	input [11:0] TRGDbias,//19
	input [11:0] TRGbias2,//20
	input [11:0] TRGthref,//21
	input [7:0] LeadSSPin,//22
	input [7:0] TrailSSPin,//23
	input [7:0] LeadS1,//24
	input [7:0] TrailS1,//25
	input [7:0] LeadS2,//26
	input [7:0] TrailS2,//27
	input [7:0] LeadPHASE,//28
	input [7:0] TrailPHASE,//29
	input [7:0] LeadWR_STRB,//30
	input [7:0] TrailWR_STRB,//31
	input [7:0] TimGenReg,//32
	input [11:0] PDDbias,//33
	input [11:0] CMPbias,//34
	input [11:0] PUDbias,//35
	input [11:0] PUbias,//36
	input [11:0] SBDbias,//37
	input [11:0] Sbbias,//38
	input [11:0] ISDbias,//39
	input [11:0] ISEL,//40
	input [11:0] VDDbias,//41
	input [11:0] Vdly,//42	
	input [11:0] VAPDbias,//43
	input [11:0] VadjP,//44
	input [11:0] VANDbias,//45
	input [11:0] VadjN,//46
	output init_done,
	output PCLK,
	output SCLK,
	output SIN,
	input SHOUT,
	output flag_done,
	output DAC_updating //used to block triggers while updating
	//output SST,
	//output [35:0] debug_ila
   );

	reg [17:0] shift_in = {18{1'b0}};
	reg [7:0] shift_counter = {8{1'b0}};
	reg [7:0] counter = {8{1'b0}};
	reg [5:0] addr_load = {6{1'b0}};
	//	wire [5:0] addr_load; //ONLY FOR DEBUG!
	reg addr_done = 0;


	localparam FSM_BITS=4;
	localparam [FSM_BITS-1:0] IDLE = 0;
	localparam [FSM_BITS-1:0] SHIFT_HIGH = 1;
	localparam [FSM_BITS-1:0] SHIFT_LOW = 2;
	localparam [FSM_BITS-1:0] PCLK_WAIT = 3;
	localparam [FSM_BITS-1:0] LATCH_DATA = 4;
	localparam [FSM_BITS-1:0] PCLK_WAIT_2 = 5;
	localparam [FSM_BITS-1:0] LOAD_REG = 6;
	localparam [FSM_BITS-1:0] DONE = 7;
	localparam [FSM_BITS-1:0] CHANGE_ADDR = 8;
	localparam [FSM_BITS-1:0] CHANGE_SHIFT = 9;
	localparam [FSM_BITS-1:0] DUMMY10 = 10;
	localparam [FSM_BITS-1:0] DUMMY11 = 11;
	localparam [FSM_BITS-1:0] DUMMY12 = 12;
	localparam [FSM_BITS-1:0] DUMMY13 = 13;
	localparam [FSM_BITS-1:0] DUMMY14 = 14;
	localparam [FSM_BITS-1:0] DUMMY15 = 15;
	reg [FSM_BITS-1:0] state = IDLE;
	reg initial_reset = 1;

	wire [75:0] vio_out;
	wire [7:0] sclk_high_time =10; 
	wire [7:0] sclk_low_time = 10; 
	wire [7:0] num_sclk_shifts = 17; 
	wire [7:0] pclk_wait_time = 10; 
	wire [7:0] latch_data_time = 10; 
	wire [7:0] pclk_wait_2_time = 10; 
	wire [7:0] load_reg_time = 10; 	
	reg int_init_done;
	
	// 7x8 = 56 + 18 = 74 bits + 1 + 1 = 75 bits
	wire sst_enable = vio_out[75];
	assign init_done = int_init_done;
	always @(posedge clk) begin
		case (state)
			IDLE: if (do_load || initial_reset) begin initial_reset <= 0; state <= SHIFT_LOW;  int_init_done <= 1'b1; end
			SHIFT_LOW: if (counter == sclk_low_time) state <= SHIFT_HIGH;
			SHIFT_HIGH: if (counter == sclk_high_time) begin
				if (shift_counter == num_sclk_shifts)
					state <= PCLK_WAIT;
				else
					state <= SHIFT_LOW;
			end
			PCLK_WAIT: if (counter == pclk_wait_time) state <= LATCH_DATA;
			LATCH_DATA: if (counter == latch_data_time) state <= PCLK_WAIT_2;
			PCLK_WAIT_2: if (counter == pclk_wait_2_time) state <= LOAD_REG;
			LOAD_REG: if (counter == load_reg_time) state <= CHANGE_SHIFT;
			CHANGE_SHIFT: state <= CHANGE_ADDR;
			CHANGE_ADDR: if (addr_load == 61) begin state <= DONE; end 
							 else begin state <= SHIFT_LOW; end
			DONE: if (~do_load) state <= IDLE; //stay here until DAC loading request goes down
			default: state <= IDLE;
		endcase
	end
	
	wire [7:0] wait_mux[9:0]; //need to change this
	assign wait_mux[0] = {8{1'b0}};
	assign wait_mux[1] = sclk_high_time;
	assign wait_mux[2] = sclk_low_time;
	assign wait_mux[3] = pclk_wait_time;
	assign wait_mux[4] = latch_data_time;
	assign wait_mux[5] = pclk_wait_2_time;
	assign wait_mux[6] = load_reg_time;
	assign wait_mux[7] = {8{1'b0}};
	//	assign wait_mux[8] = {8{1'b0}};
	//	assign wait_mux[9] = {8{1'b0}};
	
	reg counter_done = 0;
	always @(posedge clk) begin
		if (counter == wait_mux[state]) begin
			counter_done <= 1;
			counter <= {8{1'b0}};
		end else begin
			counter_done <= 0;
			counter <= counter + 1;
		end
	end
	always @(posedge clk) begin
		if (state == SHIFT_HIGH && counter == sclk_high_time)
			shift_counter <= shift_counter + 1;
		else if ((state == IDLE) || (state == CHANGE_ADDR)) shift_counter <= {8{1'b0}};
	end
	always @(posedge clk) begin
		if (state == CHANGE_ADDR) 
			begin
			if (addr_load == 44 || addr_load == 46) begin
				addr_done <= 0;
				addr_load <= 61;
			end
			else if (addr_load == 61) begin // when you are done with 61 == PCK62 - should stop!
				addr_done <= 1;
				addr_load <= {6{1'b0}};				
			end else begin
				addr_done <= 0;
				addr_load <= addr_load + 1;
			end
		end
	end	

	always @(posedge clk) begin
		if (state == CHANGE_SHIFT) begin
			case  (addr_load) 
				0 : shift_in[11:0] <= THR1; 
				1 : shift_in[11:0] <= THR2; 
				2 : shift_in[11:0] <= THR3; 
				3 : shift_in[11:0] <= THR4; 
				4 : shift_in[11:0] <= THR5; 
				5 : shift_in[11:0] <= THR6; 
				6 : shift_in[11:0] <= THR7; 
				7 : shift_in[11:0] <= THR8; 
				8 : shift_in[11:0] <=VBDBIAS; //9
				9 : shift_in[11:0] <=VBIAS; //10
				10 : shift_in[11:0] <=VBIAS2; //11
				11 : shift_in[11:0] <={4'b0000, MiscReg}; //12(incl. SGN)
				12 : shift_in[11:0] <=WBDbias; //13
				13 : shift_in[11:0] <=Wbias; //14
				14 : shift_in[11:0] <=TCDbias; //15
				15 : shift_in[11:0] <=TRGbias;//16
				16 : shift_in[11:0] <=THDbias;//17
				17 : shift_in[11:0] <=Tbbias;//18
				18 : shift_in[11:0] <= TRGDbias;//19
				19 : shift_in[11:0] <=TRGbias2;//20
				20 : shift_in[11:0] <=TRGthref;//21
				21 : shift_in[11:0] <={4'b0000,LeadSSPin};//22
				22 : shift_in[11:0] <={4'b0000,TrailSSPin};//23
				23 : shift_in[11:0] <={4'b0000,LeadS1};//24
				24 : shift_in[11:0] <={4'b0000,TrailS1};//25
				25 : shift_in[11:0] <={4'b0000,LeadS2};//26
				26 : shift_in[11:0] <={4'b0000,TrailS2};//27
				27 : shift_in[11:0] <={4'b0000,LeadPHASE};//28
				28 : shift_in[11:0] <={4'b0000,TrailPHASE};//29
				29 : shift_in[11:0] <={4'b0000,LeadWR_STRB};//30
				30 : shift_in[11:0] <={4'b0000,TrailWR_STRB};//31
				31 : shift_in[11:0] <={4'b0000,TimGenReg};//32
				32 : shift_in[11:0] <=PDDbias;//33
				33 : shift_in[11:0] <= CMPbias;//34
				34 : shift_in[11:0] <= PUDbias;//35
				35 : shift_in[11:0] <= PUbias;//36
				36 : shift_in[11:0] <= SBDbias;//37
				37 : shift_in[11:0] <= Sbbias;//38
				38 : shift_in[11:0] <= ISDbias;//39
				39 : shift_in[11:0] <= ISEL;//40
				40 : shift_in[11:0] <= VDDbias;//41
				41 : shift_in[11:0] <= Vdly;//42
				42 : shift_in[11:0] <= VAPDbias;//43
				43 : shift_in[11:0] <= VadjP;//44
				44 : shift_in[11:0] <= VANDbias;//45
				45 : shift_in[11:0] <=  VadjN;//46
				46 : shift_in[11:0] <=  0;//47 -- dummy
				61 : shift_in[11:0] <=  {12{1'b1}};//62 -- start wilkinson - needs to have SIN=1 during PCLK?
			default : shift_in[11:0] <= 0;
		endcase 
			shift_in[17:12] <= addr_load;
		end
		else if (state == SHIFT_HIGH && counter == sclk_high_time)
	//		begin shift_in <= {shift_in[0],shift_in[17:1]}; end
			begin shift_in <= {shift_in[16:0],shift_in[17]}; end //LM: changed order as it looks the MSB go first - and they should be the addresses
	end


	assign PCLK = (state == LATCH_DATA || state == LOAD_REG);
	assign SCLK = (state == SHIFT_HIGH);
	assign SIN = ((state == SHIFT_HIGH || state == SHIFT_LOW) && shift_in[17]) || //LM: changed order as it looks the MSB go first - and they should be the addresses
					 (state == PCLK_WAIT_2 || state == LOAD_REG);
	assign flag_done = (state == DONE);
	assign DAC_updating = ~(state == IDLE);
 
	// ILA wants SIN, SCLK, PCLK, SST, state done, counter_done, and SHOUT.
	// This is 7 bits, use 18.
	//	wire [17:0] debug_ila;
	//assign debug_ila[0] = SIN;
	//assign debug_ila[1] = SCLK;
	//assign debug_ila[2] = PCLK;
	//	assign debug_ila[3] = SST;
	//assign debug_ila[3] = flag_done;
	//assign debug_ila[4] = counter_done;
	//assign debug_ila[5] = SHOUT;
	//	assign debug_ila[6] = MONTIMING;
	//	assign debug_ila[7] = RCO;
	//assign debug_ila[6 +: 4] = state;
	//assign debug_ila[10] = do_load;
	
	//	assign debug_ila[10 +: 18] = shift_in;
	//	assign debug_ila[10] = addr_done;
	//assign debug_ila[11 +: 6] = addr_load;
	//wire [31:0] vio_sync_in;	
	//wire [35:0] ila_control;
	//wire [35:0] vio_control;

endmodule
