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

	signal internal_BOARD_CLOCK_250MHz		: std_logic;
	signal internal_BOARD_CLOCK_127MHz		: std_logic;
	signal internal_BOARD_CLOCK_21MHz		: std_logic;	
	signal internal_BOARD_CLOCK_DCM_LOCKED : std_logic;

	signal internal_FTSW_INTERFACE_READY	: std_logic;
	signal internal_FTSW_CLOCK_127MHz		: std_logic;
	signal internal_FTSW_CLOCK_21MHz			: std_logic;
	signal internal_FTSW_TRIGGER127			: std_logic;
	signal internal_FTSW_TRIGGER21			: std_logic;

	signal internal_USE_FTSW_CLOCK			: std_logic;

	signal internal_CLOCK_127MHz				: std_logic;
	signal internal_CLOCK_21Mhz				: std_logic;
	signal internal_CLOCK_83kHz				: std_logic;
	signal internal_CLOCK_80Hz					: std_logic;
	
	signal internal_RESET_SAMPLING_CLOCK_GEN : std_logic;
	signal internal_SAMPLING_CLOCKS_READY	  : std_logic;

	signal internal_CLOCK_SSP 				: std_logic;
	signal internal_CLOCK_SST 				: std_logic;	
	signal internal_CLOCK_WRITE_STROBE	: std_logic;
	signal internal_CLOCK_4xSST			: std_logic;
   ---------------------------------------------------------	
begin
	---------------------------------------------------------
	map_FTSW_interface: entity work.bpid
    port map (
      ack_p  => RJ45_ACK_P,
      ack_n  => RJ45_ACK_N,
      trg_p  => RJ45_TRG_P,
      trg_n  => RJ45_TRG_N,
		rsv_p  => RJ45_RSV_P,
		rsv_n  => RJ45_RSV_N,
		clk_p  => RJ45_CLK_P,
		clk_n  => RJ45_CLK_N,
		clk127 => internal_FTSW_CLOCK_127MHz,
		clk21  => internal_FTSW_CLOCK_21MHz,
		trg127 => internal_FTSW_TRIGGER127,
		trg21  => internal_FTSW_TRIGGER21,
		ready  => internal_FTSW_INTERFACE_READY,
		monitor => open);
   ---------------------------------------------------------
	map_ibufgds_250MHz : IBUFGDS
      port map (O  => internal_BOARD_CLOCK_250MHz,
                I  => BOARD_CLOCK_250MHz_P,
                IB => BOARD_CLOCK_250MHz_N); 
	---------------------------------------------------------
	map_primary_ibufgmux : BUFGMUX
		port map (I0 => internal_BOARD_CLOCK_127MHz,
					 I1 => internal_FTSW_CLOCK_127MHz,
					 O  => internal_CLOCK_127MHz,
					 S  => internal_USE_FTSW_CLOCK);
	---------------------------------------------------------
	map_board_derived_clockgen : entity work.board_derived_clockgen
		port map (	-- Clock in ports
						CLK_IN1 => internal_BOARD_CLOCK_250MHz,
						-- Clock out ports
						CLK_OUT1 => internal_BOARD_CLOCK_127MHz,
						CLK_OUT2 => internal_BOARD_CLOCK_21MHz,
						-- Status and control signals
						RESET  => internal_USE_FTSW_CLOCK,
						LOCKED => internal_BOARD_CLOCK_DCM_LOCKED);
	---------------------------------------------------------
	map_sst_ibufgmux : BUFGMUX
		port map (I0 => internal_BOARD_CLOCK_21MHz,
					 I1 => internal_FTSW_CLOCK_21MHz,
					 O  => internal_CLOCK_21MHz,
					 S  => internal_USE_FTSW_CLOCK);
	---------------------------------------------------------
	map_sampling_clock_gen : entity work.sampling_clock_gen
		port map (	CLK_IN1  => internal_CLOCK_SST,
						CLK_OUT1 => internal_CLOCK_SSP,
						CLK_OUT2 => internal_CLOCK_WRITE_STROBE,
						CLK_OUT3 => internal_CLOCK_4xSST,
						RESET 	=> internal_RESET_SAMPLING_CLOCK_GEN,
						LOCKED	=> internal_SAMPLING_CLOCKS_READY);
	---------------------------------------------------------
	process (internal_CLOCK_21MHz) 
		variable counter : integer := 0;
		constant target  : integer := 128;
	begin
		if rising_edge(internal_CLOCK_21MHz) then
			if (counter = target) then
				internal_CLOCK_83kHz <= not(internal_CLOCK_83kHz);
				counter := 0;
			else 
				counter := counter + 1;
			end if;
		end if;
	end process;
	---------------------------------------------------------
	process (internal_CLOCK_83kHz)
		variable counter : integer := 0;
		constant target  : integer := 512;
	begin
		if rising_edge(internal_CLOCK_83kHz) then
			if (counter = target) then
				internal_CLOCK_80Hz <= not(internal_CLOCK_80Hz);
				counter := 0;
			else
				counter := counter + 1;
			end if;
		end if;
	end process;
	---------------------------------------------------------
	internal_CLOCK_SST <= internal_CLOCK_21MHz;
	internal_USE_FTSW_CLOCK <= internal_MONITOR_INPUTS(0);
	process (internal_USE_FTSW_CLOCK, internal_BOARD_CLOCK_DCM_LOCKED, internal_FTSW_INTERFACE_READY) begin
		if (internal_USE_FTSW_CLOCK = '1') then
			internal_RESET_SAMPLING_CLOCK_GEN <= not(internal_FTSW_INTERFACE_READY);
		else
			internal_RESET_SAMPLING_CLOCK_GEN <= not(internal_BOARD_CLOCK_DCM_LOCKED);
		end if;
	end process;
	---------------------------------------------------------
	internal_MONITOR_INPUTS <= MONITOR_INPUTS;
	internal_MONITOR_OUTPUTS(14 downto 1) <= (others => '0');
	internal_MONITOR_OUTPUTS(15) <= internal_CLOCK_SSP;
	MONITOR_OUTPUTS <= internal_MONITOR_OUTPUTS;
	internal_LEDS(0) <= internal_CLOCK_80Hz;
	internal_LEDS(1) <= internal_CLOCK_83kHz;
	internal_LEDS(10 downto 2) <= (others => '0');
	internal_LEDS(11) <= internal_FTSW_INTERFACE_READY;
	internal_LEDS(12) <= internal_BOARD_CLOCK_DCM_LOCKED;
	internal_LEDS(13) <= internal_USE_FTSW_CLOCK;
	internal_LEDS(14) <= internal_RESET_SAMPLING_CLOCK_GEN;
	internal_LEDS(15) <= internal_SAMPLING_CLOCKS_READY;
	LEDS <= internal_LEDS;


end Behavioral;
