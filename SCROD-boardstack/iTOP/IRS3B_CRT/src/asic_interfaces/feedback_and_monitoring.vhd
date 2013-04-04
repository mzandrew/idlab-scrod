----------------------------------------------------------------------------------
-- Feedback and monitoring for ASIC items
-- Description:
--		This module handles all the feedback related ASIC items, such as 
--    sampling rate, wilkinson conversion rate, and trigger width.
--    Inputs and outputs are still in a state of flux... at the moment only
--    the Wilkinson rate feedback is implemented.  The desired DAC values 
--    come from this module, but should be multiplexed to the actual DAC
--    choices somewhere else in case feedback should be turned off.
-- Change log:
-- 2011-09-?? - Created by Kurtis
-- 2011-09-29 - Comments/description added to describe basic functionality - Kurtis
-- 2012-11-21 - Modifying for new version of front-end firmware
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs3b_carrier_revB.all;
use work.IRS3B_CarrierRevB_DAC_definitions.all;

entity feedback_and_monitoring is
  generic (
		      CLOCK_RATE : real := 50000000.0
  );
  port (
				AsicOut_MONITOR_TRIG_C0_R                 : in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C1_R                 : in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C2_R                 : in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_TRIG_C3_R                 : in std_logic_vector(3 downto 0);
				
				FEEDBACK_WBIAS_ENABLES_C_R                : in  Column_Row_Enables;
				FEEDBACK_WBIAS_GOALS_C_R                  : in  Column_Row_Counters;
				FEEDBACK_WBIAS_COUNTERS_C_R               : out Column_Row_Counters;
				FEEDBACK_WBIAS_DAC_VALUES_C_R             : out DAC_Setting_C_R;
				STARTING_WBIAS_DAC_VALUES_C_R             : in  DAC_Setting_C_R;

				AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C0_R : in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C1_R : in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C2_R : in std_logic_vector(3 downto 0);
				AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C3_R : in std_logic_vector(3 downto 0);
				
				FEEDBACK_SAMPLING_RATE_ENABLE             : in  Column_Row_Enables;
				FEEDBACK_SAMPLING_RATE_GOALS_C_R          : in  Column_Row_Counters;
				FEEDBACK_SAMPLING_RATE_COUNTER_C_R        : out Column_Row_Counters;
				FEEDBACK_SAMPLING_RATE_VADJP_C_R          : out DAC_Setting_C_R;
				FEEDBACK_SAMPLING_RATE_VADJN_C_R          : out DAC_Setting_C_R;
				STARTING_SAMPLING_RATE_VADJN_C_R          : in  DAC_Setting_C_R;				

				AsicOut_MONITOR_WILK_COUNTERS_C0_R        : in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTERS_C1_R        : in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTERS_C2_R        : in std_logic_vector(3 downto 0);
				AsicOut_MONITOR_WILK_COUNTERS_C3_R        : in std_logic_vector(3 downto 0);
				
				FEEDBACK_WILKINSON_ENABLES_C_R            : in  Column_Row_Enables;
				FEEDBACK_WILKINSON_GOALS_C_R              : in  Column_Row_Counters;
				FEEDBACK_WILKINSON_COUNTERS_C_R           : out Column_Row_Counters;
				FEEDBACK_WILKINSON_DAC_VALUES_C_R         : out DAC_Setting_C_R;
				STARTING_WILKINSON_DAC_VALUES_C_R         : in  DAC_Setting_C_R;				
				
				CLOCK                                     : in std_logic
	);
end feedback_and_monitoring;

architecture Behavioral of feedback_and_monitoring is 

begin
	--Unused for now... wiring to zero to avoid warnings
	gen_vadjp_dummy_col : for col in 0 to 3 generate
		gen_vadjp_dummy_row : for row in 0 to 3 generate
			FEEDBACK_SAMPLING_RATE_VADJP_C_R(col)(row) <= (others => '0');
		end generate;
	end generate;
	--

	map_wilkinson_monitoring : entity work.wilkinson_monitoring 
	generic map (
		USE_SIMPLE_FEEDBACK   => 0,
		USE_RCO_COUNTER       => 0,
		CLOCK_RATE            => CLOCK_RATE,
		INTEGRATION_FREQUENCY => WILKINSON_INTEGRATION_FREQUENCY
	)
	port map (
		AsicOut_MONITOR_WILK_COUNTERS_C0_R => AsicOut_MONITOR_WILK_COUNTERS_C0_R,
		AsicOut_MONITOR_WILK_COUNTERS_C1_R => AsicOut_MONITOR_WILK_COUNTERS_C1_R,
		AsicOut_MONITOR_WILK_COUNTERS_C2_R => AsicOut_MONITOR_WILK_COUNTERS_C2_R,
		AsicOut_MONITOR_WILK_COUNTERS_C3_R => AsicOut_MONITOR_WILK_COUNTERS_C3_R,
		FEEDBACK_WILKINSON_ENABLES_C_R     => FEEDBACK_WILKINSON_ENABLES_C_R,
		FEEDBACK_WILKINSON_GOALS_C_R       => FEEDBACK_WILKINSON_GOALS_C_R,
		FEEDBACK_WILKINSON_COUNTERS_C_R    => FEEDBACK_WILKINSON_COUNTERS_C_R,
		FEEDBACK_WILKINSON_DAC_VALUES_C_R  => FEEDBACK_WILKINSON_DAC_VALUES_C_R,
		STARTING_WILKINSON_DAC_VALUES_C_R  => STARTING_WILKINSON_DAC_VALUES_C_R,
		CLOCK                              => CLOCK
	);
	
	-- Right now we're reusing the Wilkinson monitoring code for RCO monitoring.
	map_rco_monitoring : entity work.wilkinson_monitoring
	generic map (
		USE_SIMPLE_FEEDBACK   => 1,
		USE_RCO_COUNTER       => 1,
		CLOCK_RATE            => CLOCK_RATE,
		INTEGRATION_FREQUENCY => RCO_INTEGRATION_FREQUENCY
	)
	port map (
		AsicOut_MONITOR_WILK_COUNTERS_C0_R => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C0_R,
		AsicOut_MONITOR_WILK_COUNTERS_C1_R => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C1_R,
		AsicOut_MONITOR_WILK_COUNTERS_C2_R => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C2_R,
		AsicOut_MONITOR_WILK_COUNTERS_C3_R => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C3_R,
		FEEDBACK_WILKINSON_ENABLES_C_R     => FEEDBACK_SAMPLING_RATE_ENABLE,
		FEEDBACK_WILKINSON_GOALS_C_R       => FEEDBACK_SAMPLING_RATE_GOALS_C_R,
		FEEDBACK_WILKINSON_COUNTERS_C_R    => FEEDBACK_SAMPLING_RATE_COUNTER_C_R,
		FEEDBACK_WILKINSON_DAC_VALUES_C_R  => FEEDBACK_SAMPLING_RATE_VADJN_C_R,
		STARTING_WILKINSON_DAC_VALUES_C_R  => STARTING_SAMPLING_RATE_VADJN_C_R,
		CLOCK                              => CLOCK
	);
	
	-- WBIAS monitoring
	map_trigger_width_monitoring : entity work.all_trigger_width_monitors
	port map (
		TRIGGER_MONITORS_C0_R         => AsicOut_MONITOR_TRIG_C0_R,
		TRIGGER_MONITORS_C1_R         => AsicOut_MONITOR_TRIG_C1_R,
		TRIGGER_MONITORS_C2_R         => AsicOut_MONITOR_TRIG_C2_R,
		TRIGGER_MONITORS_C3_R         => AsicOut_MONITOR_TRIG_C3_R,
		FEEDBACK_WBIAS_ENABLES_C_R    => FEEDBACK_WBIAS_ENABLES_C_R,
		FEEDBACK_WBIAS_GOALS_C_R      => FEEDBACK_WBIAS_GOALS_C_R,
		FEEDBACK_WBIAS_COUNTERS_C_R   => FEEDBACK_WBIAS_COUNTERS_C_R,
		FEEDBACK_WBIAS_DAC_VALUES_C_R => FEEDBACK_WBIAS_DAC_VALUES_C_R,
		STARTING_WBIAS_DAC_VALUES_C_R => STARTING_WBIAS_DAC_VALUES_C_R,
		CLOCK                         => CLOCK
	);

end Behavioral;

