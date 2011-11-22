----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:34:13 09/14/2011 
-- Design Name: 
-- Module Name:    Wilkinson_Monitoring - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity Wilkinson_Monitoring is
  port (
				AsicIn_MONITOR_WILK_COUNTER_RESET			: out std_logic;
				AsicIn_MONITOR_WILK_COUNTER_START			: out std_logic;
				AsicOut_MONITOR_WILK_COUNTER_C0_R			: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTER_C1_R			: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTER_C2_R			: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTER_C3_R			: in std_logic_vector(3 downto 0);				

				FEEDBACK_WILKINSON_ENABLE                 : in std_logic_vector(15 downto 0);
				FEEDBACK_WILKINSON_GOAL                   : in std_logic_vector(31 downto 0);
				FEEDBACK_WILKINSON_COUNTER_C_R				: out Wilkinson_Rate_Counters_C_R;
				FEEDBACK_WILKINSON_DAC_VALUE_C_R				: out Wilkinson_Rate_DAC_C_R;
				
				CLOCK_80Hz											: in std_logic;
				DAC_SYNC_CLOCK                            : in std_logic
				);
end Wilkinson_Monitoring;

architecture Behavioral of Wilkinson_Monitoring is

begin
	--Disable the reset for the test Wilkinson counter.  This signal keeps
	--those counters reset to zero, but we always want to be able to monitor
	--them.
	AsicIn_MONITOR_WILK_COUNTER_RESET <= '0';
	--Send a slow clock out to the Wilkinson.  In principle we should only
	--need one edge to start the counter permanently, so this is likely
	--overkill.
	AsicIn_MONITOR_WILK_COUNTER_START <= CLOCK_80Hz;
	
	--Create the instances of the Wilkinson feedback.  The enable will be 
	--tied high here.  The multiplexing between user selectable DAC values
	--and feedback control DAC values is done in the DAC block.
--	map_Wilk_Control_Loop_GEN : for i in 0 to 3 generate
--		map_Wilk_Control_Loop_C0_R : entity work.CTRL_LOOP_PRCO
--			port map(
--				ENABLE => FEEDBACK_WILKINSON_ENABLE(0 + i),
--				xCLR_ALL => '0',
--				xREFRESH_CLK => CLOCK_80Hz,
--				xTST_OUT => AsicOut_MONITOR_WILK_COUNTER_C0_R(i),
--				xPRCO_INT => FEEDBACK_WILKINSON_COUNTER_C_R(0)(i),
--				xPROVDD => FEEDBACK_WILKINSON_DAC_VALUE_C_R(0)(i),
--				TARGET_COUNT => FEEDBACK_WILKINSON_GOAL(15 downto 0)
--			);
--		map_Wilk_Control_Loop_C1_R : entity work.CTRL_LOOP_PRCO
--			port map(
--				ENABLE => FEEDBACK_WILKINSON_ENABLE(4 + i),
--				xCLR_ALL => '0',
--				xREFRESH_CLK => CLOCK_80Hz,
--				xTST_OUT => AsicOut_MONITOR_WILK_COUNTER_C1_R(i),
--				xPRCO_INT => FEEDBACK_WILKINSON_COUNTER_C_R(1)(i),
--				xPROVDD => FEEDBACK_WILKINSON_DAC_VALUE_C_R(1)(i),
--				TARGET_COUNT => FEEDBACK_WILKINSON_GOAL(15 downto 0)
--			);
--		map_Wilk_Control_Loop_C2_R : entity work.CTRL_LOOP_PRCO
--			port map(
--				ENABLE => FEEDBACK_WILKINSON_ENABLE(8 + i),
--				xCLR_ALL => '0',
--				xREFRESH_CLK => CLOCK_80Hz,
--				xTST_OUT => AsicOut_MONITOR_WILK_COUNTER_C2_R(i),
--				xPRCO_INT => FEEDBACK_WILKINSON_COUNTER_C_R(2)(i),
--				xPROVDD => FEEDBACK_WILKINSON_DAC_VALUE_C_R(2)(i),
--				TARGET_COUNT => FEEDBACK_WILKINSON_GOAL(15 downto 0)
--			);			
--		map_Wilk_Control_Loop_C3_R : entity work.CTRL_LOOP_PRCO
--			port map(
--				ENABLE => FEEDBACK_WILKINSON_ENABLE(12 + i),
--				xCLR_ALL => '0',
--				xREFRESH_CLK => CLOCK_80Hz,
--				xTST_OUT => AsicOut_MONITOR_WILK_COUNTER_C3_R(i),
--				xPRCO_INT => FEEDBACK_WILKINSON_COUNTER_C_R(3)(i),
--				xPROVDD => FEEDBACK_WILKINSON_DAC_VALUE_C_R(3)(i),
--				TARGET_COUNT => FEEDBACK_WILKINSON_GOAL(15 downto 0)
--			);			
--	end generate;

	--Switched out the above blocks for a "safer" VHDL version below which runs at a reduced duty cycle but with race conditions eliminated... at least, that was the intention.
	map_Wilk_Control_Loop_GEN : for i in 0 to 3 generate
		map_Wilk_Control_Loop_C0_R : entity work.Wilkinson_Feedback_Loop
			port map(
				ENABLE_FEEDBACK      => FEEDBACK_WILKINSON_ENABLE(0 + i),
				RESET_FEEDBACK       => '0',
				REFRESH_CLOCK        => CLOCK_80Hz,
				DAC_SYNC_CLOCK       => DAC_SYNC_CLOCK,
				WILK_MONITOR_BIT     => AsicOut_MONITOR_WILK_COUNTER_C0_R(i),
				DESIRED_COUNT_VALUE  => FEEDBACK_WILKINSON_GOAL(15 downto 0),
				CURRENT_COUNT_VALUE  => FEEDBACK_WILKINSON_COUNTER_C_R(0)(i),
				DESIRED_DAC_VALUE    => FEEDBACK_WILKINSON_DAC_VALUE_C_R(0)(i)
			);
		map_Wilk_Control_Loop_C1_R : entity work.Wilkinson_Feedback_Loop
			port map(
				ENABLE_FEEDBACK      => FEEDBACK_WILKINSON_ENABLE(4 + i),
				RESET_FEEDBACK       => '0',
				REFRESH_CLOCK        => CLOCK_80Hz,
				DAC_SYNC_CLOCK       => DAC_SYNC_CLOCK,
				WILK_MONITOR_BIT     => AsicOut_MONITOR_WILK_COUNTER_C1_R(i),
				DESIRED_COUNT_VALUE  => FEEDBACK_WILKINSON_GOAL(15 downto 0),
				CURRENT_COUNT_VALUE  => FEEDBACK_WILKINSON_COUNTER_C_R(1)(i),
				DESIRED_DAC_VALUE    => FEEDBACK_WILKINSON_DAC_VALUE_C_R(1)(i)
			);
		map_Wilk_Control_Loop_C2_R : entity work.Wilkinson_Feedback_Loop
			port map(
				ENABLE_FEEDBACK      => FEEDBACK_WILKINSON_ENABLE(8 + i),
				RESET_FEEDBACK       => '0',
				REFRESH_CLOCK        => CLOCK_80Hz,
				DAC_SYNC_CLOCK       => DAC_SYNC_CLOCK,
				WILK_MONITOR_BIT     => AsicOut_MONITOR_WILK_COUNTER_C2_R(i),
				DESIRED_COUNT_VALUE  => FEEDBACK_WILKINSON_GOAL(15 downto 0),
				CURRENT_COUNT_VALUE  => FEEDBACK_WILKINSON_COUNTER_C_R(2)(i),
				DESIRED_DAC_VALUE    => FEEDBACK_WILKINSON_DAC_VALUE_C_R(2)(i)
			);			
		map_Wilk_Control_Loop_C3_R : entity work.Wilkinson_Feedback_Loop
			port map(
				ENABLE_FEEDBACK      => FEEDBACK_WILKINSON_ENABLE(12 + i),
				RESET_FEEDBACK       => '0',
				REFRESH_CLOCK        => CLOCK_80Hz,
				DAC_SYNC_CLOCK       => DAC_SYNC_CLOCK,
				WILK_MONITOR_BIT     => AsicOut_MONITOR_WILK_COUNTER_C3_R(i),
				DESIRED_COUNT_VALUE  => FEEDBACK_WILKINSON_GOAL(15 downto 0),
				CURRENT_COUNT_VALUE  => FEEDBACK_WILKINSON_COUNTER_C_R(3)(i),
				DESIRED_DAC_VALUE    => FEEDBACK_WILKINSON_DAC_VALUE_C_R(3)(i)
			);			
	end generate;


end Behavioral;

