----------------------------------------------------------------------------------
-- Feedback and monitoring for ASIC items
-- Description:
--		This module handles all the feedback related ASIC items, such as 
--    sampling rate, wilkinson conversion rate, and trigger width.
--    Inputs and outputs are still in a state of flux... at the moment only
--    the Wilkinson rate feedback is implemented.  The desired DAC values 
--    come from this module, but should be multiplexed to the actual DAC
--    choices somewhere else in case feedback should be turned off.
--    State machines here run relatively slow, using an 80 Hz clock.
-- Change log:
-- 2011-09-?? - Created by Kurtis
-- 2011-09-29 - Comments/description added to describe basic functionality - Kurtis
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

entity Board_Stack_Feedback_and_Monitoring is
  port (
				AsicIn_MONITOR_TRIG								: out std_logic;
				AsicOut_MONITOR_TRIG_C0_R						: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C1_R						: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C2_R						: in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C3_R						: in std_logic_vector(3 downto 0);

				AsicOut_SAMPLING_TRACK_MODE_C0_R				: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C1_R				: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C2_R				: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C3_R				: in std_logic_vector(3 downto 0);

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
end Board_Stack_Feedback_and_Monitoring;

architecture Behavioral of Board_Stack_Feedback_and_Monitoring is

begin
	map_Wilkinson_Monitoring : entity work.Wilkinson_Monitoring 
		port map (
				AsicIn_MONITOR_WILK_COUNTER_RESET			=> AsicIn_MONITOR_WILK_COUNTER_RESET,
				AsicIn_MONITOR_WILK_COUNTER_START			=> AsicIn_MONITOR_WILK_COUNTER_START,
				AsicOut_MONITOR_WILK_COUNTER_C0_R			=> AsicOut_MONITOR_WILK_COUNTER_C0_R,
				AsicOut_MONITOR_WILK_COUNTER_C1_R			=> AsicOut_MONITOR_WILK_COUNTER_C1_R,
				AsicOut_MONITOR_WILK_COUNTER_C2_R			=> AsicOut_MONITOR_WILK_COUNTER_C2_R,
				AsicOut_MONITOR_WILK_COUNTER_C3_R			=> AsicOut_MONITOR_WILK_COUNTER_C3_R,
				FEEDBACK_WILKINSON_ENABLE                 => FEEDBACK_WILKINSON_ENABLE,
				FEEDBACK_WILKINSON_GOAL                   => FEEDBACK_WILKINSON_GOAL,
				FEEDBACK_WILKINSON_COUNTER_C_R				=> FEEDBACK_WILKINSON_COUNTER_C_R,
				FEEDBACK_WILKINSON_DAC_VALUE_C_R				=> FEEDBACK_WILKINSON_DAC_VALUE_C_R,
				CLOCK_80Hz											=> CLOCK_80Hz,
				DAC_SYNC_CLOCK                            => DAC_SYNC_CLOCK
		);
end Behavioral;

