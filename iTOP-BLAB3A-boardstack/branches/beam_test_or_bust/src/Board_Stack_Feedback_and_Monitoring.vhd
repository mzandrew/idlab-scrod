----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:57:45 09/14/2011 
-- Design Name: 
-- Module Name:    Board_Stack_Feedback_and_Monitoring - Behavioral 
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
				
				FEEDBACK_WILKINSON_COUNTER_C_R				: out Wilkinson_Rate_Counters_C_R;
				FEEDBACK_WILKINSON_DAC_VALUE_C_R				: out Wilkinson_Rate_DAC_C_R;
				
				CLOCK_80Hz											: in std_logic
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
				FEEDBACK_WILKINSON_COUNTER_C_R				=> FEEDBACK_WILKINSON_COUNTER_C_R,
				FEEDBACK_WILKINSON_DAC_VALUE_C_R				=> FEEDBACK_WILKINSON_DAC_VALUE_C_R,
				CLOCK_80Hz											=> CLOCK_80Hz
		);
end Behavioral;

