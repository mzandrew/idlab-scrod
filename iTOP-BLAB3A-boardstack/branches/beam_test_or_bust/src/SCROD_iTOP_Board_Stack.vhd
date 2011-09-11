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
	signal internal_LEDS        		: std_logic_vector(15 downto 0);
	signal internal_MONITOR_INPUTS	: std_logic_vector(0 downto 0);
	signal internal_MONITOR_OUTPUTS	: std_logic_vector(15 downto 1);	
	signal internal_CHIPSCOPE_CONTROL0 : std_logic_vector(35 downto 0);
	--------Signals for the clocking and FTSW interface------
	signal internal_USE_FTSW_CLOCK				: std_logic;
	signal internal_FTSW_INTERFACE_READY		: std_logic;
	signal internal_RESET_SAMPLING_CLOCK_GEN	: std_logic;
	signal internal_SAMPLING_CLOCKS_READY		: std_logic;
	
	signal internal_CLOCK_127MHz			: std_logic;
	signal internal_CLOCK_SSP 				: std_logic;
	signal internal_CLOCK_SST 				: std_logic;	
	signal internal_CLOCK_WRITE_STROBE	: std_logic;
	signal internal_CLOCK_4xSST			: std_logic;
	signal internal_CLOCK_83kHz			: std_logic;
	signal internal_CLOCK_80Hz				: std_logic;
	
	signal internal_FTSW_TRIGGER21_SHIFTED : std_logic;
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
	-----ASIC sampling and analog storage control------------
	map_ASIC_sampling_control : entity work.ASIC_sampling_control
		port map (
			CONTINUE_WRITING			=> not(internal_FTSW_TRIGGER21_SHIFTED),
			CLOCK_SST					=> internal_CLOCK_SST,
			CLOCK_SSP					=> internal_CLOCK_SSP,
			CLOCK_WRITE_STROBE		=> internal_CLOCK_WRITE_STROBE,
			FIRST_ADDRESS_ALLOWED	=> "000000000",
			LAST_ADDRESS_ALLOWED		=> "111111111",
			WRITING						=> open,
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
			CONTROL0 => internal_CHIPSCOPE_CONTROL0
		);
	--
	internal_MONITOR_INPUTS <= MONITOR_INPUTS;
	internal_MONITOR_OUTPUTS(15 downto 1) <= (others => '0');
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
