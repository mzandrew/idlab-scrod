----------------------------------------------------------------------------------
-- Single channel trigger width monitor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trigger_width_monitor is
Generic (
	BIT_WIDTH          : integer := 16
);
Port ( 
	CLOCK              : in  STD_LOGIC;
   TRIGGER_MONITOR_IN : in  STD_LOGIC;
	RESET_COUNTER      : in  STD_LOGIC;
	READ_ENABLE        : in  STD_LOGIC;
   COUNTER_OUT        : out STD_LOGIC_VECTOR(BIT_WIDTH-1 downto 0)
);
end trigger_width_monitor;

architecture Behavioral of trigger_width_monitor is
	constant MAX_COUNT             : unsigned(BIT_WIDTH-1 downto 0) := (others => '1');
	signal internal_COUNTER        : unsigned(BIT_WIDTH-1 downto 0) := (others => '0');
	signal internal_COUNTER_OUT    : std_logic_vector(BIT_WIDTH-1 downto 0) := (others => '0');
begin

	--This counts the number of pulses 
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			if (RESET_COUNTER = '1') then
				internal_COUNTER <= (others => '0');
			elsif (TRIGGER_MONITOR_IN = '1' and internal_COUNTER /= MAX_COUNT) then
				internal_COUNTER <= internal_COUNTER + 1;
			end if;
		end if;
	end process;
	--Latch the value of the counter to the output
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			if (READ_ENABLE = '1') then
				internal_COUNTER_OUT <= std_logic_vector(internal_COUNTER);
			end if;
		end if;
	end process;
	COUNTER_OUT <= internal_COUNTER_OUT;
end Behavioral;

----------------------------------------------------------------------------------
-- Board stack channel trigger width monitors
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs3b_carrier_revB.all;
use work.IRS3B_CarrierRevB_DAC_definitions.all;

entity all_trigger_width_monitors is
Port ( 
	TRIGGER_MONITORS_C0_R         : in  STD_LOGIC_VECTOR(3 downto 0);
	TRIGGER_MONITORS_C1_R         : in  STD_LOGIC_VECTOR(3 downto 0);
	TRIGGER_MONITORS_C2_R         : in  STD_LOGIC_VECTOR(3 downto 0);
	TRIGGER_MONITORS_C3_R         : in  STD_LOGIC_VECTOR(3 downto 0);
	FEEDBACK_WBIAS_ENABLES_C_R    : in  Column_Row_Enables;
	FEEDBACK_WBIAS_GOALS_C_R      : in  Column_Row_Counters;
	FEEDBACK_WBIAS_COUNTERS_C_R   : out Column_Row_Counters;
	FEEDBACK_WBIAS_DAC_VALUES_C_R : out DAC_Setting_C_R;
	STARTING_WBIAS_DAC_VALUES_C_R : in  DAC_Setting_C_R;
	CLOCK                         : in  STD_LOGIC
);
end all_trigger_width_monitors;

architecture Behavioral of all_trigger_width_monitors is
	signal internal_READ_ENABLE   : std_logic := '0';
	signal internal_RESET_COUNTER : std_logic := '0';
	signal internal_WBIAS_COUNTERS_C_R : Column_Row_Counters;
begin
	--Map to top level ports
	FEEDBACK_WBIAS_COUNTERS_C_R <= internal_WBIAS_COUNTERS_C_R;
	--Generate the timing signals for the read enables and resets for the counters
	map_read_reset_timing_generator : entity work.trigger_scaler_timing_generator
	generic map (
		CLOCK_RATE            => 50000000.0, --In Hz
		INTEGRATION_FREQUENCY =>       10.0  --In Hz
	)
	port map ( 
		CLOCK                 => CLOCK,
		READ_ENABLE           => internal_READ_ENABLE,
		RESET_COUNTER         => internal_RESET_COUNTER
	);
	--Instantiate the counters
	gen_wbias_counters_row : for row in 0 to 3 generate
		map_gen_wbias_counters_c0 : entity work.trigger_width_monitor
			port map ( 
				CLOCK              => CLOCK,
				TRIGGER_MONITOR_IN => TRIGGER_MONITORS_C0_R(row),
				RESET_COUNTER      => internal_RESET_COUNTER,
				READ_ENABLE        => internal_READ_ENABLE,
				COUNTER_OUT        => internal_WBIAS_COUNTERS_C_R(0)(row)
			);
		map_gen_wbias_counters_c1 : entity work.trigger_width_monitor
			port map ( 
				CLOCK              => CLOCK,
				TRIGGER_MONITOR_IN => TRIGGER_MONITORS_C1_R(row),
				RESET_COUNTER      => internal_RESET_COUNTER,
				READ_ENABLE        => internal_READ_ENABLE,
				COUNTER_OUT        => internal_WBIAS_COUNTERS_C_R(1)(row)
			);
		map_gen_wbias_counters_c2 : entity work.trigger_width_monitor
			port map ( 
				CLOCK              => CLOCK,
				TRIGGER_MONITOR_IN => TRIGGER_MONITORS_C2_R(row),
				RESET_COUNTER      => internal_RESET_COUNTER,
				READ_ENABLE        => internal_READ_ENABLE,
				COUNTER_OUT        => internal_WBIAS_COUNTERS_C_R(2)(row)
			);
		map_gen_wbias_counters_c3 : entity work.trigger_width_monitor
			port map ( 
				CLOCK              => CLOCK,
				TRIGGER_MONITOR_IN => TRIGGER_MONITORS_C3_R(row),
				RESET_COUNTER      => internal_RESET_COUNTER,
				READ_ENABLE        => internal_READ_ENABLE,
				COUNTER_OUT        => internal_WBIAS_COUNTERS_C_R(3)(row)
			);
	end generate;
	--Instantiate simple feedback loops
		gen_simple_feedback_col : for col in 0 to 3 generate
			gen_simple_feedback_row : for row in 0 to 3 generate
				map_simple_feedback : entity work.simple_feedback
					generic map(
						DEADBAND_SIZE   => (others => '0')
					)
					port map(
						CLOCK           => CLOCK,
						CLOCK_ENABLE    => internal_RESET_COUNTER,
						FEEDBACK_ENABLE => FEEDBACK_WBIAS_ENABLES_C_R(col)(row),
						CURRENT_VALUE   => internal_WBIAS_COUNTERS_C_R(col)(row),
						TARGET_VALUE    => FEEDBACK_WBIAS_GOALS_C_R(col)(row),
						DAC_VALUE       => FEEDBACK_WBIAS_DAC_VALUES_C_R(col)(row),
						STARTING_VALUE  => STARTING_WBIAS_DAC_VALUES_C_R(col)(row)
					);
			end generate;
		end generate;	
	

end Behavioral;