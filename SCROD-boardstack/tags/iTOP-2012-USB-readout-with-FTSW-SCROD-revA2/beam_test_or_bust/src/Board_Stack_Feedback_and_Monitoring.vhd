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

				AsicIn_SAMPLING_TRACK_MODE                : in std_logic;
				AsicOut_SAMPLING_TRACK_MODE_C0_R				: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C1_R				: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C2_R				: in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TRACK_MODE_C3_R				: in std_logic_vector(3 downto 0);
				
				FEEDBACK_SAMPLING_RATE_ENABLE             : in std_logic_vector(15 downto 0);
				FEEDBACK_SAMPLING_RATE_COUNTER_C_R        : out Sampling_Rate_Counters_C_R;
				FEEDBACK_SAMPLING_RATE_VADJP_C_R          : out Sampling_Rate_DAC_C_R;
				FEEDBACK_SAMPLING_RATE_VADJN_C_R          : out Sampling_Rate_DAC_C_R;

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
	signal internal_AsicOut_SAMPLING_TRACK_MODE_FLATTENED : std_logic_vector(15 downto 0);
	signal internal_AsicIn_SAMPLING_TRACK_MODE            : std_logic;
	signal internal_NO_PULSE : std_logic;
begin
	internal_AsicOut_SAMPLING_TRACK_MODE_FLATTENED <= (AsicOut_SAMPLING_TRACK_MODE_C3_R) &
	                                                  (AsicOut_SAMPLING_TRACK_MODE_C2_R) &
	                                                  (AsicOut_SAMPLING_TRACK_MODE_C1_R) &																	  
	                                                  (AsicOut_SAMPLING_TRACK_MODE_C0_R);
	internal_AsicIn_SAMPLING_TRACK_MODE <= AsicIn_SAMPLING_TRACK_MODE;

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
		
		map_Sampling_Rate_Monitoring : entity work.ctrl_loop_smpl_scheduler
			port map (
--				ENABLE           =>  FEEDBACK_SAMPLING_RATE_ENABLE(0), --input
--				CLR_ALL          =>  not(FEEDBACK_SAMPLING_RATE_ENABLE(0)), --input, reset signal for counters
				ENABLE           =>  '1', --input
				CLR_ALL          =>  '0', --input, reset signal for counters
				PULSEDET_CLK     =>  AsicIn_SAMPLING_TRACK_MODE, --input,
				REFRESH_CLK      =>  CLOCK_80Hz, --input (~100 Hz)
				SSP_IN           =>  internal_AsicIn_SAMPLING_TRACK_MODE, --input, copy of AsicIn_SSP_IN
				SSP_OUT          =>  internal_AsicOut_SAMPLING_TRACK_MODE_FLATTENED, --input (15 downto 0), Asic_SSP_OUT
				SMPL_INT00       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(0), --output, counter for Asic 00
				SMPL_INT01       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(1), --output, counter for Asic 01
				SMPL_INT02       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(2), --output, counter for Asic 02
				SMPL_INT03       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(3), --output, counter for Asic 03
				SMPL_INT04       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(0), --output, counter for Asic 04
				SMPL_INT05       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(1), --output, counter for Asic 05
				SMPL_INT06       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(2), --output, counter for Asic 06
				SMPL_INT07       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(3), --output, counter for Asic 07
				SMPL_INT08       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(0), --output, counter for Asic 08
				SMPL_INT09       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(1), --output, counter for Asic 09
				SMPL_INT10       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(2), --output, counter for Asic 10
				SMPL_INT11       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(3), --output, counter for Asic 11
				SMPL_INT12       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(0), --output, counter for Asic 12
				SMPL_INT13       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(1), --output, counter for Asic 13
				SMPL_INT14       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(2), --output, counter for Asic 14
				SMPL_INT15       =>  FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(3), --output, counter for Asic 15
				VADJP00          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(0)(0), --output, DAC Value VadjP for Asic 00
				VADJP01          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(0)(1), --output, DAC Value VadjP for Asic 01
				VADJP02          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(0)(2), --output, DAC Value VadjP for Asic 02
				VADJP03          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(0)(3), --output, DAC Value VadjP for Asic 03
				VADJP04          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(1)(0), --output, DAC Value VadjP for Asic 04
				VADJP05          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(1)(1), --output, DAC Value VadjP for Asic 05
				VADJP06          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(1)(2), --output, DAC Value VadjP for Asic 06
				VADJP07          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(1)(3), --output, DAC Value VadjP for Asic 07
				VADJP08          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(2)(0), --output, DAC Value VadjP for Asic 08
				VADJP09          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(2)(1), --output, DAC Value VadjP for Asic 09
				VADJP10          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(2)(2), --output, DAC Value VadjP for Asic 10
				VADJP11          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(2)(3), --output, DAC Value VadjP for Asic 11
				VADJP12          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(3)(0), --output, DAC Value VadjP for Asic 12
				VADJP13          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(3)(1), --output, DAC Value VadjP for Asic 13
				VADJP14          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(3)(2), --output, DAC Value VadjP for Asic 14
				VADJP15          =>  FEEDBACK_SAMPLING_RATE_VADJP_C_R(3)(3), --output, DAC Value VadjP for Asic 15
				VADJN00          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(0)(0), --output, DAC Value VadjN for Asic 00
				VADJN01          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(0)(1), --output, DAC Value VadjN for Asic 01
				VADJN02          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(0)(2), --output, DAC Value VadjN for Asic 02
				VADJN03          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(0)(3), --output, DAC Value VadjN for Asic 03
				VADJN04          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(1)(0), --output, DAC Value VadjN for Asic 04
				VADJN05          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(1)(1), --output, DAC Value VadjN for Asic 05
				VADJN06          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(1)(2), --output, DAC Value VadjN for Asic 06
				VADJN07          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(1)(3), --output, DAC Value VadjN for Asic 07
				VADJN08          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(2)(0), --output, DAC Value VadjN for Asic 08
				VADJN09          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(2)(1), --output, DAC Value VadjN for Asic 09
				VADJN10          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(2)(2), --output, DAC Value VadjN for Asic 10
				VADJN11          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(2)(3), --output, DAC Value VadjN for Asic 11
				VADJN12          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(3)(0), --output, DAC Value VadjN for Asic 12
				VADJN13          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(3)(1), --output, DAC Value VadjN for Asic 13
				VADJN14          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(3)(2), --output, DAC Value VadjN for Asic 14
				VADJN15          =>  FEEDBACK_SAMPLING_RATE_VADJN_C_R(3)(3), --output, DAC Value VadjN for Asic 15
				NO_PULSE         =>  internal_NO_PULSE, --output, indicates no pulses seen on SSP_OUT
				INITIAL_VADJP    =>  x"C9E", --input (11 downto 0), initial VadjP value
				INITIAL_VADJN    =>  x"42E", --input (11 downto 0), initial VadjN value
				SMPL_THRESH_LOW  =>  x"7FFF0", --input (19 downto 0), threshold for DAC adjust
				SMPL_THRESH_HIGH =>  x"80010" --input (19 downto 0), threshold for DAC adjust
		);
end Behavioral;

