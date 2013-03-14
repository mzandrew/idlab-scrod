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
--				AsicIn_MONITOR_TRIG                       : out std_logic;
--				AsicOut_MONITOR_TRIG_C0_R                 : in std_logic_vector(3 downto 0);
--				AsicOut_MONITOR_TRIG_C1_R                 : in std_logic_vector(3 downto 0);
--				AsicOut_MONITOR_TRIG_C2_R                 : in std_logic_vector(3 downto 0);
--				AsicOut_MONITOR_TRIG_C3_R                 : in std_logic_vector(3 downto 0);
--
--				AsicIn_SAMPLING_TRACK_MODE                : in std_logic;

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

--type T_array is array(3 downto 0) of std_logic_vector(15 downto 0);
--signal numT_array_C0 : T_array;
--signal numT_array_C1 : T_array;
--signal numT_array_C2 : T_array;
--signal numT_array_C3 : T_array;
--
--signal new_num_T_array_C0 : std_logic_vector(3 downto 0);
--signal new_num_T_array_C1 : std_logic_vector(3 downto 0);
--signal new_num_T_array_C2 : std_logic_vector(3 downto 0);
--signal new_num_T_array_C3 : std_logic_vector(3 downto 0);
--
--signal new_num_T_allowed_C0 : std_logic_vector(3 downto 0);
--signal new_num_T_allowed_C1 : std_logic_vector(3 downto 0);
--signal new_num_T_allowed_C2 : std_logic_vector(3 downto 0);
--signal new_num_T_allowed_C3 : std_logic_vector(3 downto 0);
--
--
--signal updateVadjN_C0 : std_logic_vector(3 downto 0); --LM: note: these are not used now
--signal updateVadjN_C1 : std_logic_vector(3 downto 0);
--signal updateVadjN_C2 : std_logic_vector(3 downto 0);
--signal updateVadjN_C3 : std_logic_vector(3 downto 0);
--
--component RCO_measure 
--port(
--	clk: in std_logic;
--	RCO_in : in std_logic;
--	new_num_T : out std_logic;
--	num_T : out std_logic_vector(15 downto 0);
--	TC_debug : out std_logic
--);
--end component;
--
--component Feedback_RCO 
--port(
--	clk : in std_logic;
--	num_T : in std_logic_vector(15 downto 0);
--	desirednumT : in std_logic_vector(15 downto 0);
--	newnumT : in std_logic;
--	update : out std_logic;
--	forcedVadjN: out  std_logic_vector(11 downto 0)
--);
--end component;

begin
	map_wilkinson_monitoring : entity work.wilkinson_monitoring 
	generic map (
		USE_SIMPLE_FEEDBACK   => 0,
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

----This was fixed for Luca's version, but should now be controllable from the general
---- registers.
----desirednumT <= X"7201"; --LM: this is fixed now - we'll connect it to goals later 
--
--gen_RCO_measure_row : for row in 0 to 3 generate
--	RCO_measure_C0 : RCO_measure 
--	port map(
--		clk       => CLOCK,
--		RCO_in    => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C0_R(row), 
--		new_num_T => new_num_T_array_C0(row),
--		num_T     => numT_array_C0(row),
--		TC_debug  => open
--	); 
--	RCO_measure_C1 : RCO_measure 
--	port map(
--		clk       => CLOCK,
--		RCO_in    => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C1_R(row), 
--		new_num_T => new_num_T_array_C1(row),
--		num_T     => numT_array_C1(row),
--		TC_debug  => open
--	); 
--	RCO_measure_C2 : RCO_measure 
--	port map(
--		clk       => CLOCK,
--		RCO_in    => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C2_R(row), 
--		new_num_T => new_num_T_array_C2(row),
--		num_T     => numT_array_C2(row),
--		TC_debug  => open
--	); 
--	RCO_measure_C3 : RCO_measure 
--	port map(
--		clk       => CLOCK,
--		RCO_in    => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C3_R(row), 
--		new_num_T => new_num_T_array_C3(row),
--		num_T     => numT_array_C3(row),
--		TC_debug  => open
--	); 	
--end generate;
--
--gen_RCO_feedback_row : for row in 0 to 3 generate
--	Feedback_RCO_C0 : Feedback_RCO 
--	port map(
--		clk         => CLOCK,
--		num_T       => numT_array_C0(row),
--		desirednumT => FEEDBACK_SAMPLING_RATE_GOALS_C_R(0)(row),
--		newnumT     => new_num_T_allowed_C0(row), 
--		update      => updateVadjN_C0(row),
--		forcedVadjN => FEEDBACK_SAMPLING_RATE_VADJN_C_R(0)(row)
--	);
--	Feedback_RCO_C1 : Feedback_RCO 
--	port map(
--		clk         => CLOCK,
--		num_T       => numT_array_C1(row),
--		desirednumT => FEEDBACK_SAMPLING_RATE_GOALS_C_R(1)(row),
--		newnumT     => new_num_T_allowed_C1(row), 
--		update      => updateVadjN_C1(row),
--		forcedVadjN => FEEDBACK_SAMPLING_RATE_VADJN_C_R(1)(row)
--	);
--	Feedback_RCO_C2 : Feedback_RCO 
--	port map(
--		clk         => CLOCK,
--		num_T       => numT_array_C2(row),
--		desirednumT => FEEDBACK_SAMPLING_RATE_GOALS_C_R(2)(row),
--		newnumT     => new_num_T_allowed_C2(row), 
--		update      => updateVadjN_C2(row),
--		forcedVadjN => FEEDBACK_SAMPLING_RATE_VADJN_C_R(2)(row)
--	);
--	Feedback_RCO_C3 : Feedback_RCO 
--	port map(
--		clk         => CLOCK,
--		num_T       => numT_array_C3(row),
--		desirednumT => FEEDBACK_SAMPLING_RATE_GOALS_C_R(3)(row),
--		newnumT     => new_num_T_allowed_C3(row), 
--		update      => updateVadjN_C3(row),
--		forcedVadjN => FEEDBACK_SAMPLING_RATE_VADJN_C_R(3)(row)
--	);
--end generate;
--
--gen_enables_row : for row in 0 to 3 generate
--	new_num_T_allowed_C0(row) <= new_num_T_array_C0(row) and FEEDBACK_SAMPLING_RATE_ENABLE(0)(row);
--	new_num_T_allowed_C1(row) <= new_num_T_array_C1(row) and FEEDBACK_SAMPLING_RATE_ENABLE(1)(row);
--	new_num_T_allowed_C2(row) <= new_num_T_array_C2(row) and FEEDBACK_SAMPLING_RATE_ENABLE(2)(row);
--	new_num_T_allowed_C3(row) <= new_num_T_array_C3(row) and FEEDBACK_SAMPLING_RATE_ENABLE(3)(row);
--end generate;
--
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(0) <= numT_array_C0(0);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(1) <= numT_array_C0(1);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(2) <= numT_array_C0(2);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(0)(3) <= numT_array_C0(3);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(0) <= numT_array_C1(0);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(1) <= numT_array_C1(1);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(2) <= numT_array_C1(2);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(1)(3) <= numT_array_C1(3);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(0) <= numT_array_C2(0);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(1) <= numT_array_C2(1);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(2) <= numT_array_C2(2);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(2)(3) <= numT_array_C2(3);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(0) <= numT_array_C3(0);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(1) <= numT_array_C3(1);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(2) <= numT_array_C3(2);
--FEEDBACK_SAMPLING_RATE_COUNTER_C_R(3)(3) <= numT_array_C3(3);

end Behavioral;

