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
				
				---Monitor and diagnostic
				LEDS 					: out STD_LOGIC_VECTOR(15 downto 0);
				MONITOR_INPUTS		: in STD_LOGIC_VECTOR(0 downto 0);
				MONITOR_OUTPUTS 	: out STD_LOGIC_VECTOR(15 downto 1)
			);
end SCROD_iTOP_Board_Stack;

architecture Behavioral of SCROD_iTOP_Board_Stack is

	--------SIGNAL DEFINITIONS-------------------------------
	signal internal_LEDS        					: std_logic_vector(15 downto 0);
	signal internal_MONITOR_INPUTS				: std_logic_vector(0 downto 0);
	signal internal_MONITOR_OUTPUTS				: std_logic_vector(15 downto 1);	
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
	--Temporary debugging signals----------------------------
	signal internal_VIO_IN : std_logic_vector(255 downto 0);
	signal internal_VIO_OUT : std_logic_vector(255 downto 0);
	signal internal_TEST_DAC_VALUE : std_logic_vector(11 downto 0);
	signal internal_TEST_DAC_COLUMN : std_logic_vector(1 downto 0);
	signal internal_TEST_DAC_LOC	 : std_logic_vector(2 downto 0);
	signal internal_TEST_DAC_CH	: std_logic_vector(2 downto 0);
	---------------------------------------------------------
begin
	-----Clocking and FTSW interface-------------------------
	internal_USE_FTSW_CLOCK <= internal_MONITOR_INPUTS(0);
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
	-----ASIC sampling and analog storage control------------
	map_ASIC_sampling_control : entity work.ASIC_sampling_control
		port map (
			CONTINUE_WRITING			=> not(internal_FTSW_TRIGGER21_SHIFTED),
			CLOCK_SST					=> internal_CLOCK_SST,
			CLOCK_SSP					=> internal_CLOCK_SSP,
			CLOCK_WRITE_STROBE		=> internal_CLOCK_WRITE_STROBE,
			FIRST_ADDRESS_ALLOWED	=> "000000000",
			LAST_ADDRESS_ALLOWED		=> "111111111",
			LAST_ADDRESS_WRITTEN 	=> open,
			AsicIn_SAMPLING_HOLD_MODE_C					=> AsicIn_SAMPLING_HOLD_MODE_C,
			AsicIn_SAMPLING_TO_STORAGE_ADDRESS			=> AsicIn_SAMPLING_TO_STORAGE_ADDRESS,
			AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE	=> AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE,
			AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C		=> AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C,
			AsicIn_SAMPLING_TRACK_MODE_C					=> AsicIn_SAMPLING_TRACK_MODE_C,
			CHIPSCOPE_CONTROL			=> internal_CHIPSCOPE_CONTROL0
		);
	---------------------------------------------------------

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
	internal_TEST_DAC_VALUE <= internal_VIO_OUT(11 downto 0);
	internal_TEST_DAC_COLUMN <= internal_VIO_OUT(13 downto 12);
	internal_TEST_DAC_LOC <= internal_VIO_OUT(16 downto 14);
	internal_TEST_DAC_CH <= internal_VIO_OUT(19 downto 17);
	process(internal_CLOCK_80Hz) begin
		if (rising_edge(internal_CLOCK_80Hz)) then
			internal_DESIRED_DAC_VOLTAGES(to_integer( unsigned(internal_TEST_DAC_COLUMN)))
												  (to_integer( unsigned(internal_TEST_DAC_LOC) ))
												  (to_integer( unsigned(internal_TEST_DAC_CH) )) <= internal_TEST_DAC_VALUE;
			internal_VIO_IN(11 downto 0) <= internal_CURRENT_DAC_VOLTAGES( to_integer( unsigned(internal_TEST_DAC_COLUMN) ))
																							 ( to_integer( unsigned(internal_TEST_DAC_LOC) ))
																							 ( to_integer( unsigned(internal_TEST_DAC_CH) ) );
		end if;
	end process;
	--
	internal_MONITOR_INPUTS <= MONITOR_INPUTS;
	internal_MONITOR_OUTPUTS(11 downto 1) <= (others => '0');
	internal_MONITOR_OUTPUTS(15) <= DAC_SDA_C(0);
	internal_MONITOR_OUTPUTS(14) <= DAC_SDA_C(1);
	internal_MONITOR_OUTPUTS(13) <= DAC_SDA_C(2);
	internal_MONITOR_OUTPUTS(12) <= DAC_SDA_C(3);	
	MONITOR_OUTPUTS <= internal_MONITOR_OUTPUTS;
	internal_LEDS(0) <= internal_CLOCK_80Hz;
	internal_LEDS(1) <= internal_CLOCK_83kHz;
	internal_LEDS(12 downto 2) <= (others => '0');
	internal_LEDS(13) <= internal_USE_FTSW_CLOCK;
	internal_LEDS(14) <= internal_FTSW_INTERFACE_READY;
	internal_LEDS(15) <= internal_SAMPLING_CLOCKS_READY;
	LEDS <= internal_LEDS;
	---------------------------------------------------------	

end Behavioral;
