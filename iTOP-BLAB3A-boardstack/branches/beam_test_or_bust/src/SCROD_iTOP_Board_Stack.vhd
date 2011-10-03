----------------------------------------------------------------------------------
-- SCROD - iTOP Board Stack
-- Top level firmware intended for 2011 cosmic ray and beam tests.
--
-- Contributors: Matt Andrew, Kurtis Nishimura, Xiaowen Shi, Lynn Wood
--
-- This module forms the top level of the board stack firmware.
-- Please see the block diagram at <link_forthcoming> to see a
-- graphical representation of the wiring between modules.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity SCROD_iTOP_Board_Stack is
	Generic (
				WIDTH_OF_BLOCKRAM_DATA_BUS		: integer := 16;
				WIDTH_OF_BLOCKRAM_ADDRESS_BUS : integer := 13
	);
   Port ( 
				--On board differential oscillator pins
				BOARD_CLOCK_250MHz_P : in STD_LOGIC;
				BOARD_CLOCK_250MHz_N : in STD_LOGIC;
				
				---FTSW I/Os (from RJ45)
				RJ45_ACK_P			: out std_logic;
				RJ45_ACK_N			: out std_logic;			  
				RJ45_TRG_P			: in std_logic;
				RJ45_TRG_N			: in std_logic;			  			  
				RJ45_RSV_P			: out std_logic;
				RJ45_RSV_N			: out std_logic;
				RJ45_CLK_P			: in std_logic;
				RJ45_CLK_N			: in std_logic;

				--External DAC I/Os (IIC)
				DAC_SCL_C					: out std_logic_vector(3 downto 0);
				DAC_SDA_C					: inout std_logic_vector(3 downto 0); 
				
				--ASIC Sampling and analog storage control
				AsicIn_SAMPLING_HOLD_MODE_C					: out	std_logic_vector(3 downto 0);
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS			: out	std_logic_vector(8 downto 0);
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE	: out	std_logic;
				AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C		: out	std_logic_vector(3 downto 0);
				AsicIn_SAMPLING_TRACK_MODE_C					: out	std_logic_vector(3 downto 0);				

				--ASIC Digitizing and Readout
				AsicIn_DATA_BUS_CHANNEL_ADDRESS			: out std_logic_vector(2 downto 0);		
				AsicIn_DATA_BUS_SAMPLE_ADDRESS			: out std_logic_vector(5 downto 0);
				AsicIn_DATA_BUS_OUTPUT_ENABLE				: out std_logic;
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C0_R		: out std_logic_vector(3 downto 0);	
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C1_R		: out std_logic_vector(3 downto 0);
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C2_R		: out std_logic_vector(3 downto 0);
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C3_R		: out std_logic_vector(3 downto 0);
				AsicIn_STORAGE_TO_WILK_ADDRESS			: out std_logic_vector(8 downto 0);
				AsicIn_STORAGE_TO_WILK_ADDRESS_ENABLE	: out std_logic;
				AsicIn_STORAGE_TO_WILK_ENABLE				: out std_logic;
				AsicIn_WILK_COUNTER_RESET					: out std_logic;
				AsicIn_WILK_COUNTER_START_C				: out std_logic_vector(3 downto 0);
				AsicIn_WILK_RAMP_ACTIVE						: out std_logic;
				AsicOut_DATA_BUS_C0							: in std_logic_vector(11 downto 0);
				AsicOut_DATA_BUS_C1							: in std_logic_vector(11 downto 0);
				AsicOut_DATA_BUS_C2							: in std_logic_vector(11 downto 0);	
				AsicOut_DATA_BUS_C3							: in std_logic_vector(11 downto 0);	
				
				--ASIC monitoring and feedback signals
				AsicIn_MONITOR_TRIG							: out std_logic;
				AsicOut_MONITOR_TRIG_C0_R					: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C1_R					: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C2_R					: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C3_R					: in std_logic_vector(3 downto 0);
				AsicIn_MONITOR_WILK_COUNTER_RESET		: out std_logic;
				AsicIn_MONITOR_WILK_COUNTER_START		: out std_logic;
				AsicOut_MONITOR_WILK_COUNTER_C0_R		: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTER_C1_R		: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTER_C2_R		: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTER_C3_R		: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C0_R			: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C1_R			: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C2_R			: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C3_R			: in std_logic_vector(3 downto 0);

				--ASIC trigger interface signals
				AsicIn_TRIG_ON_RISING_EDGE					: out std_logic;
				AsicOut_TRIG_OUTPUT_R0_C0_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R0_C1_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R0_C2_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R0_C3_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R1_C0_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R1_C1_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R1_C2_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R1_C3_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R2_C0_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R2_C1_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R2_C2_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R2_C3_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R3_C0_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R3_C1_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R3_C2_CH				: in std_logic_vector(7 downto 0);
				AsicOut_TRIG_OUTPUT_R3_C3_CH				: in std_logic_vector(7 downto 0);

				--Interfaces for the temperature sensors
				TMP_SCL	: out 	std_logic;
				TMP_SDA	: inout  std_logic;

				---General monitor and diagnostic
				LEDS 					: out STD_LOGIC_VECTOR(15 downto 0);
				MONITOR_INPUTS		: in STD_LOGIC_VECTOR(0 downto 0)
			);
end SCROD_iTOP_Board_Stack;

architecture Behavioral of SCROD_iTOP_Board_Stack is

	--------SIGNAL DEFINITIONS-------------------------------
	signal internal_LEDS        					: std_logic_vector(15 downto 0);
	signal internal_MONITOR_INPUTS				: std_logic_vector(0 downto 0);	
	signal internal_CHIPSCOPE_CONTROL0 			: std_logic_vector(35 downto 0);
	signal internal_CHIPSCOPE_CONTROL1 			: std_logic_vector(35 downto 0);
	--------Signals for the clocking and FTSW interface------
	signal internal_USE_FTSW_CLOCK				: std_logic;
	signal internal_FTSW_INTERFACE_READY		: std_logic;
	signal internal_RESET_SAMPLING_CLOCK_GEN	: std_logic;
	signal internal_SAMPLING_CLOCKS_READY		: std_logic;
	
	signal internal_CLOCK_127MHz					: std_logic;
	signal internal_CLOCK_SSP 						: std_logic;
	signal internal_CLOCK_SST 						: std_logic;	
	signal internal_CLOCK_WRITE_STROBE			: std_logic;
	signal internal_CLOCK_4xSST					: std_logic;
	signal internal_CLOCK_83kHz					: std_logic;
	signal internal_CLOCK_80Hz						: std_logic;
	
	signal internal_FTSW_TRIGGER21_SHIFTED 	: std_logic;
	---------Signals for DAC interface-----------------------
	signal internal_DESIRED_DAC_VOLTAGES : Board_Stack_Voltages;
	signal internal_CURRENT_DAC_VOLTAGES : Board_Stack_Voltages;
   ---------------------------------------------------------	
	--Signals for interfacing to the temperature sensors-----
	signal internal_TEMP_R1	: std_logic_vector(11 downto 0);
	---------------------------------------------------------
	---------ASIC feedback related signals-------------------
	signal internal_FEEDBACK_WILKINSON_COUNTER_C_R		: Wilkinson_Rate_Counters_C_R;
	signal internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R	: Wilkinson_Rate_DAC_C_R;
	---------------------------------------------------------
	----Signals for ASIC sampling / analog storage-----------
	signal internal_CONTINUE_ANALOG_WRITING	: std_logic;
	signal internal_LAST_ADDRESS_WRITTEN		: std_logic_vector(8 downto 0);
	---------------------------------------------------------
	----Signals for ASIC digitizing / readout <==> fiber interface
	signal internal_DONE_DIGITIZING			: std_logic;
	signal internal_BLOCKRAM_COLUMN_SELECT	: std_logic_vector(1 downto 0);
	signal internal_BLOCKRAM_READ_ADDRESS	: std_logic_vector(WIDTH_OF_BLOCKRAM_ADDRESS_BUS-1	downto 0); 
	signal internal_BLOCKRAM_READ_DATA		: std_logic_vector(WIDTH_OF_BLOCKRAM_DATA_BUS-1		downto 0);
	------------------------------------------------------------
	----Signals for the ASIC trigger interface------------------
	signal internal_ASIC_TRIGGER_BITS_C_R_CH		: ASIC_Trigger_Bits_C_R_CH;
	signal internal_ASIC_SCALERS_C_R_CH				: ASIC_Scalers_C_R_CH;
	signal internal_ASIC_TRIGGER_STREAMS_C_R_CH 	: ASIC_Trigger_Stream_C_R_CH;
	------------------------------------------------------------
	--Signals that I expect will be added later but are now placeholders---
	signal internal_CLOCK_DAQ_INTERFACE		: std_logic;
	signal internal_DAQ_BUSY					: std_logic;
	------------------------------------------------------------
	--Temporary debugging signals----------------------------
	signal internal_VIO_IN 								: std_logic_vector(255 downto 0);
	signal internal_VIO_OUT 							: std_logic_vector(255 downto 0);
	signal internal_TEST_DAC_COLUMN					: std_logic_vector(1 downto 0);
	signal internal_TEST_DAC_LOC						: std_logic_vector(2 downto 0);
	signal internal_TEST_DAC_CH						: std_logic_vector(2 downto 0);
	signal internal_RESET_ALL_DACS 					: std_logic;
	signal internal_WILK_FEEDBACK_ENABLE			: std_logic;
	signal internal_FEEDBACK_MONITOR_COLUMN 		: std_logic_vector(1 downto 0);
	signal internal_FEEDBACK_MONITOR_ROW 			: std_logic_vector(1 downto 0);
	signal internal_SOFTWARE_TRIGGER					: std_logic;
	signal internal_DUMMY_FTSW_TRIGGER21_SHIFTED : std_logic;
	signal internal_RESET_SCALERS						: std_logic;
	signal internal_LATCH_SCALERS						: std_logic;
	signal internal_TEST_SCALER_ROW					: std_logic_vector(1 downto 0);
	signal internal_TEST_SCALER_COLUMN				: std_logic_vector(1 downto 0);
	signal internal_TEST_SCALER_CH					: std_logic_vector(2 downto 0);
	signal internal_TEST_TRIG_THRESH					: std_logic_vector(11 downto 0);
	---------------------------------------------------------
begin
	-----Clocking and FTSW interface-------------------------
	internal_USE_FTSW_CLOCK <= not(internal_MONITOR_INPUTS(0));
	---------
	map_clocking_and_ftsw_interface : entity work.clocking_and_ftsw_interface
		port map (
			BOARD_CLOCK_250MHz_P => BOARD_CLOCK_250MHz_P,
			BOARD_CLOCK_250MHz_N => BOARD_CLOCK_250MHz_N,
			---FTSW I/Os (from RJ45)
			RJ45_ACK_P				=> RJ45_ACK_P,
			RJ45_ACK_N				=> RJ45_ACK_N,
			RJ45_TRG_P				=> RJ45_TRG_P,
			RJ45_TRG_N				=> RJ45_TRG_N,
			RJ45_RSV_P				=> RJ45_RSV_P,
			RJ45_RSV_N				=> RJ45_RSV_N,
			RJ45_CLK_P				=> RJ45_CLK_P,
			RJ45_CLK_N				=> RJ45_CLK_N,
			--Inputs from the user/board
			USE_FTSW_CLOCK			=> internal_USE_FTSW_CLOCK,
			--Status outputs
			FTSW_INTERFACE_READY 	=> internal_FTSW_INTERFACE_READY,
			SAMPLING_CLOCKS_READY 	=> internal_SAMPLING_CLOCKS_READY,
			--Clock outputs 
			CLOCK_127MHz			=> internal_CLOCK_127MHz,
			CLOCK_SST				=> internal_CLOCK_SST,
			CLOCK_SSP				=> internal_CLOCK_SSP,
			CLOCK_WRITE_STROBE 	=> internal_CLOCK_WRITE_STROBE,
			CLOCK_4xSST				=> internal_CLOCK_4xSST,
			CLOCK_83kHz				=> internal_CLOCK_83kHz,
			CLOCK_80Hz				=> internal_CLOCK_80Hz,
			FTSW_TRIGGER21_SHIFTED => internal_FTSW_TRIGGER21_SHIFTED
		);
	---------------------------------------------------------
	-----Control for external DACs on each daughter card-----
	map_iTOP_Board_Stack_DAC_Control : entity work.iTOP_Board_Stack_DAC_Control
		port map ( 
			INTENDED_DAC_VALUES	=> internal_DESIRED_DAC_VOLTAGES,
			CURRENT_DAC_VALUES 	=> internal_CURRENT_DAC_VOLTAGES,
			CLK_100kHz_MAX      	=> internal_Clock_83kHz,
			SCL_C 		  			=> DAC_SCL_C,
			SDA_C		  				=> DAC_SDA_C
		);
	---------------------------------------------------------
	-----------Temperature sensors interface-------------------
	map_temperature_sensors_interface : entity work.Temperature_Sensors_Interface
	port map (
		READ_TEMP_NOW 	=> internal_CLOCK_80Hz,
		CLK_100kHz_MAX => internal_CLOCK_83kHz,
		TMP_SCL 			=> TMP_SCL,	
		TMP_SDA			=> TMP_SDA,	
		TEMP_R1			=> internal_TEMP_R1
	);
	-----------------------------------------------------------
	-----ASIC sampling and analog storage control------------
	map_ASIC_sampling_control : entity work.ASIC_sampling_control
		generic map (
			use_chipscope_ila			=> false
		)
		port map (
			CONTINUE_WRITING			=> internal_CONTINUE_ANALOG_WRITING,
			CLOCK_SST					=> internal_CLOCK_SST,
			CLOCK_SSP					=> internal_CLOCK_SSP,
			CLOCK_WRITE_STROBE		=> internal_CLOCK_WRITE_STROBE,
			FIRST_ADDRESS_ALLOWED	=> "000000000",
			LAST_ADDRESS_ALLOWED		=> "111111111",
			LAST_ADDRESS_WRITTEN 	=>	internal_LAST_ADDRESS_WRITTEN,
			AsicIn_SAMPLING_HOLD_MODE_C					=> AsicIn_SAMPLING_HOLD_MODE_C,
			AsicIn_SAMPLING_TO_STORAGE_ADDRESS			=> AsicIn_SAMPLING_TO_STORAGE_ADDRESS,
			AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE	=> AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE,
			AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C		=> AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C,
			AsicIn_SAMPLING_TRACK_MODE_C					=> AsicIn_SAMPLING_TRACK_MODE_C,
			CHIPSCOPE_CONTROL									=> open
		);
	---------------------------------------------------------
	--------ASIC digitizing and readout----------------------
	map_ASIC_digitizing_and_readout : entity work.ASIC_digitizing_and_readout
		generic map (
			WIDTH_OF_BLOCKRAM_DATA_BUS		=> WIDTH_OF_BLOCKRAM_DATA_BUS,
			WIDTH_OF_BLOCKRAM_ADDRESS_BUS => WIDTH_OF_BLOCKRAM_ADDRESS_BUS,	
			use_chipscope_ila					=> true
		)
		port map (
			AsicIn_DATA_BUS_CHANNEL_ADDRESS			=> AsicIn_DATA_BUS_CHANNEL_ADDRESS,
			AsicIn_DATA_BUS_SAMPLE_ADDRESS			=> AsicIn_DATA_BUS_SAMPLE_ADDRESS,
			AsicIn_DATA_BUS_OUTPUT_ENABLE				=> AsicIn_DATA_BUS_OUTPUT_ENABLE,
			AsicIn_DATA_BUS_OUTPUT_DISABLE_C0_R		=> AsicIn_DATA_BUS_OUTPUT_DISABLE_C0_R,
			AsicIn_DATA_BUS_OUTPUT_DISABLE_C1_R		=> AsicIn_DATA_BUS_OUTPUT_DISABLE_C1_R,
			AsicIn_DATA_BUS_OUTPUT_DISABLE_C2_R		=> AsicIn_DATA_BUS_OUTPUT_DISABLE_C2_R,
			AsicIn_DATA_BUS_OUTPUT_DISABLE_C3_R		=> AsicIn_DATA_BUS_OUTPUT_DISABLE_C3_R,
			AsicIn_STORAGE_TO_WILK_ADDRESS			=> AsicIn_STORAGE_TO_WILK_ADDRESS,
			AsicIn_STORAGE_TO_WILK_ADDRESS_ENABLE	=> AsicIn_STORAGE_TO_WILK_ADDRESS_ENABLE,
			AsicIn_STORAGE_TO_WILK_ENABLE				=> AsicIn_STORAGE_TO_WILK_ENABLE,
			AsicIn_WILK_COUNTER_RESET					=> AsicIn_WILK_COUNTER_RESET,
			AsicIn_WILK_COUNTER_START_C				=> AsicIn_WILK_COUNTER_START_C,
			AsicIn_WILK_RAMP_ACTIVE						=> AsicIn_WILK_RAMP_ACTIVE,
			AsicOut_DATA_BUS_C0							=> AsicOut_DATA_BUS_C0,
			AsicOut_DATA_BUS_C1							=> AsicOut_DATA_BUS_C1,
			AsicOut_DATA_BUS_C2							=> AsicOut_DATA_BUS_C2,
			AsicOut_DATA_BUS_C3							=> AsicOut_DATA_BUS_C3,
			BLOCKRAM_COLUMN_SELECT						=> internal_BLOCKRAM_COLUMN_SELECT,
			BLOCKRAM_READ_ADDRESS						=> internal_BLOCKRAM_READ_ADDRESS,
			BLOCKRAM_READ_DATA							=> internal_BLOCKRAM_READ_DATA,
			LAST_ADDRESS_WRITTEN 						=> internal_LAST_ADDRESS_WRITTEN,
			TRIGGER_DIGITIZING							=> (internal_FTSW_TRIGGER21_SHIFTED or internal_DUMMY_FTSW_TRIGGER21_SHIFTED),
			CONTINUE_ANALOG_WRITING						=> internal_CONTINUE_ANALOG_WRITING,

			DONE_DIGITIZING								=> internal_DONE_DIGITIZING,
			DAQ_BUSY											=> internal_DAQ_BUSY,
			
			CLOCK_SST										=> internal_CLOCK_SST,
			CLOCK_DAQ_INTERFACE							=> internal_CLOCK_DAQ_INTERFACE,
			
			CHIPSCOPE_CONTROL								=> internal_CHIPSCOPE_CONTROL0
		);
	---------------------------------------------------------
	--------ASIC feedback and monitoring loops---------------
	map_ASIC_feedback_and_monitoring : entity work.Board_Stack_Feedback_and_Monitoring 
		port map (
			AsicIn_MONITOR_TRIG								=> AsicIn_MONITOR_TRIG,
			AsicOut_MONITOR_TRIG_C0_R						=> AsicOut_MONITOR_TRIG_C0_R,
			AsicOut_MONITOR_TRIG_C1_R						=> AsicOut_MONITOR_TRIG_C1_R,
			AsicOut_MONITOR_TRIG_C2_R						=> AsicOut_MONITOR_TRIG_C2_R,
			AsicOut_MONITOR_TRIG_C3_R						=> AsicOut_MONITOR_TRIG_C3_R,
			AsicOut_SAMPLING_TRACK_MODE_C0_R				=> AsicOut_SAMPLING_TRACK_MODE_C0_R,
			AsicOut_SAMPLING_TRACK_MODE_C1_R				=> AsicOut_SAMPLING_TRACK_MODE_C1_R,
			AsicOut_SAMPLING_TRACK_MODE_C2_R				=> AsicOut_SAMPLING_TRACK_MODE_C2_R,
			AsicOut_SAMPLING_TRACK_MODE_C3_R				=> AsicOut_SAMPLING_TRACK_MODE_C3_R,
			AsicIn_MONITOR_WILK_COUNTER_RESET			=> AsicIn_MONITOR_WILK_COUNTER_RESET,
			AsicIn_MONITOR_WILK_COUNTER_START			=> AsicIn_MONITOR_WILK_COUNTER_START,
			AsicOut_MONITOR_WILK_COUNTER_C0_R			=> AsicOut_MONITOR_WILK_COUNTER_C0_R,
			AsicOut_MONITOR_WILK_COUNTER_C1_R			=> AsicOut_MONITOR_WILK_COUNTER_C1_R,
			AsicOut_MONITOR_WILK_COUNTER_C2_R			=> AsicOut_MONITOR_WILK_COUNTER_C2_R,
			AsicOut_MONITOR_WILK_COUNTER_C3_R			=> AsicOut_MONITOR_WILK_COUNTER_C3_R,
			FEEDBACK_WILKINSON_COUNTER_C_R				=> internal_FEEDBACK_WILKINSON_COUNTER_C_R,
			FEEDBACK_WILKINSON_DAC_VALUE_C_R				=> internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R,
			CLOCK_80Hz											=> internal_CLOCK_80Hz
		);
	-----------------------------------------------------------
	--------ASIC Trigger Bit interface-------------------------
	AsicIn_TRIG_ON_RISING_EDGE <= '0';

	internal_ASIC_TRIGGER_BITS_C_R_CH(0)(0)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R0_C0_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(1)(0)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R0_C1_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(2)(0)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R0_C2_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(3)(0)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R0_C3_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(0)(1)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R1_C0_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(1)(1)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R1_C1_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(2)(1)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R1_C2_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(3)(1)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R1_C3_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(0)(2)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R2_C0_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(1)(2)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R2_C1_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(2)(2)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R2_C2_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(3)(2)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R2_C3_CH(7 downto 0);	
	internal_ASIC_TRIGGER_BITS_C_R_CH(0)(3)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R3_C0_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(1)(3)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R3_C1_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(2)(3)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R3_C2_CH(7 downto 0);
	internal_ASIC_TRIGGER_BITS_C_R_CH(3)(3)(7 downto 0) <= AsicOut_TRIG_OUTPUT_R3_C3_CH(7 downto 0);

	map_ASIC_trigger_interface : entity work.ASIC_trigger_interface
		port map (
			TRIGGER_BITS		=> internal_ASIC_TRIGGER_BITS_C_R_CH,
			RESET_SCALERS		=> internal_RESET_SCALERS,
			LATCH_SCALERS		=> internal_LATCH_SCALERS,
			SCALERS				=> internal_ASIC_SCALERS_C_R_CH,			
			CLOCK_4xSST			=> internal_CLOCK_4xSST,
			CONTINUE_WRITING 	=> internal_CONTINUE_ANALOG_WRITING,
			TRIGGER_STREAMS 	=> internal_ASIC_TRIGGER_STREAMS_C_R_CH
		);
	-----------------------------------------------------------
	
	--Diagnostic outputs, monitors, LEDs, Chipscope Core, etc--
	map_Chipscope_Core : entity work.Chipscope_Core
		port map (
			CONTROL0 => internal_CHIPSCOPE_CONTROL0,
			CONTROL1 => internal_CHIPSCOPE_CONTROL1
		);
	--
	map_Chipscope_VIO : entity work.Chipscope_VIO
		port map (
			CONTROL => internal_CHIPSCOPE_CONTROL1,
			CLK => internal_CLOCK_80Hz,
			SYNC_IN => internal_VIO_IN,
			SYNC_OUT => internal_VIO_OUT		
		);	
	--
	internal_RESET_ALL_DACS <= internal_VIO_OUT(0);
	internal_TEST_DAC_COLUMN <= internal_VIO_OUT(2 downto 1);
	internal_TEST_DAC_LOC <= internal_VIO_OUT(5 downto 3);
	internal_TEST_DAC_CH <= internal_VIO_OUT(8 downto 6);
	internal_WILK_FEEDBACK_ENABLE <= internal_VIO_OUT(9);
	internal_FEEDBACK_MONITOR_COLUMN <= internal_VIO_OUT(11 downto 10);
	internal_FEEDBACK_MONITOR_ROW <= internal_VIO_OUT(13 downto 12);
	internal_DAQ_BUSY <= internal_VIO_OUT(14);
	internal_SOFTWARE_TRIGGER <= internal_VIO_OUT(15);
	internal_RESET_SCALERS <= internal_VIO_OUT(16);
	internal_LATCH_SCALERS <= internal_VIO_OUT(17) and internal_CLOCK_80Hz;
	internal_TEST_SCALER_ROW <= internal_VIO_OUT(19 downto 18);
	internal_TEST_SCALER_COLUMN <= internal_VIO_OUT(21 downto 20);
	internal_TEST_SCALER_CH	<= internal_VIO_OUT(24 downto 22);
	internal_TEST_TRIG_THRESH <= internal_VIO_OUT(36 downto 25);
	
	process(internal_CLOCK_SST)
		variable trigger_seen : boolean := false;
	begin
		if (falling_edge(internal_CLOCK_SST)) then
			if (internal_SOFTWARE_TRIGGER = '0') then
				trigger_seen := false;
				internal_DUMMY_FTSW_TRIGGER21_SHIFTED <= '0';
			elsif (internal_SOFTWARE_TRIGGER = '1' and trigger_seen = false) then
				trigger_seen := true;
				internal_DUMMY_FTSW_TRIGGER21_SHIFTED <= '1';
			else
				internal_DUMMY_FTSW_TRIGGER21_SHIFTED <= '0';
			end if;
		end if;
	end process;
	--
	process(internal_CLOCK_80Hz) begin
		if (rising_edge(internal_CLOCK_80Hz)) then
			internal_VIO_IN(11 downto 0) <= internal_CURRENT_DAC_VOLTAGES( to_integer( unsigned(internal_TEST_DAC_COLUMN) ))
																							 ( to_integer( unsigned(internal_TEST_DAC_LOC) ))
																							 ( to_integer( unsigned(internal_TEST_DAC_CH) ) );
			internal_VIO_IN(27 downto 12) <= internal_FEEDBACK_WILKINSON_COUNTER_C_R( to_integer( unsigned(internal_FEEDBACK_MONITOR_COLUMN) ))
																											( to_integer( unsigned(internal_FEEDBACK_MONITOR_ROW) ));
			internal_VIO_IN(39 downto 28) <= internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R( to_integer( unsigned(internal_FEEDBACK_MONITOR_COLUMN) ))
																											  ( to_integer( unsigned(internal_FEEDBACK_MONITOR_ROW) ));
			internal_VIO_IN(68 downto 53) <= internal_ASIC_SCALERS_C_R_CH( to_integer( unsigned(internal_TEST_SCALER_COLUMN) ))
																							 ( to_integer( unsigned(internal_TEST_SCALER_ROW) ))
																							 ( to_integer( unsigned(internal_TEST_SCALER_CH) ));
			internal_VIO_IN(84 downto 69) <= internal_ASIC_TRIGGER_STREAMS_C_R_CH( to_integer( unsigned(internal_TEST_SCALER_COLUMN) ))
																										( to_integer( unsigned(internal_TEST_SCALER_ROW) ))
																										( to_integer( unsigned(internal_TEST_SCALER_CH) ));
		end if;
	end process;
	internal_VIO_IN(51 downto 40) <= internal_TEMP_R1;
	internal_VIO_IN(52) <= internal_DONE_DIGITIZING;
	--
	process(internal_CLOCK_80Hz) begin
		if (rising_edge(internal_CLOCK_80Hz)) then
			if (internal_RESET_ALL_DACS = '1') then
				for i in 0 to 3 loop 
					for j in 0 to 7 loop
						for k in 0 to 7 loop
							internal_DESIRED_DAC_VOLTAGES(i)(j)(k) <= x"001";
						end loop;
					end loop;
				end loop;
			else
				for i in 0 to 3 loop
					for j in 0 to 3 loop 
--						--Rev A channel mappings
--						--DAC0 : "DAC1" on schematic
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(0) <= x"C9E"; -- VADJP
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(1) <= x"42E"; -- VADJN
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(2) <= x"000"; -- TRGTHREF
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(3) <= x"7D0"; -- ISEL
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(4) <= x"578"; -- WBIAS
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(5) <= x"3E8"; -- TRGBIAS
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(6) <= x"44C"; -- VBIAS
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(7) <= x"3E8"; -- TRIG_THRESH
--						--DAC1 : "DAC2" on schematic
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(0) <= x"640"; -- SBBIAS
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(1) <= x"CE4"; -- PUBIAS
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(2) <= x"384"; -- CMPBIAS
--						if (internal_WILK_FEEDBACK_ENABLE = '1') then
--							internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(3) <= internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R(i)(j);
--						else
--							internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(3) <= x"AF0"; -- VDLY
--						end if;						
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(4) <= x"000"; -- PAD_E
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(5) <= x"000"; -- unconnected
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(6) <= x"7FF"; -- PAD_G
--						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(7) <= x"000"; -- unconnected

						--Rev B channel mappings
						--DAC0 : "DAC1" on schematic
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(0) <= internal_TEST_TRIG_THRESH; -- TRIG_THRESH_01
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(1) <= internal_TEST_TRIG_THRESH; -- TRIG_THRESH_23
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(2) <= x"C9E"; -- VADJP
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(3) <= x"42E"; -- VADJN
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(4) <= x"3E8"; -- TRGBIAS
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(5) <= x"44C"; -- VBIAS
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(6) <= internal_TEST_TRIG_THRESH; -- TRIG_THRESH_45
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+0)(7) <= internal_TEST_TRIG_THRESH; -- TRIG_THRESH_67
						--DAC1 : "DAC2" on schematic
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(0) <= x"000"; -- TRGTHREF
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(1) <= x"7D0"; -- ISEL
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(2) <= x"640"; -- SBBIAS
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(3) <= x"CE4"; -- PUBIAS
						if (internal_WILK_FEEDBACK_ENABLE = '1') then
							internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(4) <= internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R(i)(j);
						else
							internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(4) <= x"AF0"; --VDLY
						end if;
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(5) <= x"384"; -- CMPBIAS
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(6) <= x"7FF"; -- PAD_G
						internal_DESIRED_DAC_VOLTAGES(i)(j*2+1)(7) <= x"578"; -- WBIAS
					end loop;
				end loop;
			end if;
		end if;
	end process;
	--
	internal_MONITOR_INPUTS <= MONITOR_INPUTS;
	internal_LEDS(0) <= internal_CLOCK_80Hz;
	internal_LEDS(1) <= internal_CLOCK_83kHz;
	internal_LEDS(2) <= internal_ASIC_TRIGGER_BITS_C_R_CH(0)(1)(0);
	internal_LEDS(3) <= internal_ASIC_TRIGGER_BITS_C_R_CH(3)(1)(0);	
	internal_LEDS(12 downto 4) <= (others => '0');
	internal_LEDS(13) <= internal_USE_FTSW_CLOCK;
	internal_LEDS(14) <= internal_FTSW_INTERFACE_READY;
	internal_LEDS(15) <= internal_SAMPLING_CLOCKS_READY;
	LEDS <= internal_LEDS;
	---------------------------------------------------------	

end Behavioral;
