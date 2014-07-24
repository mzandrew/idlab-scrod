----------------------------------------------------------------------------------
-- Consists of a few components - 
--   0. trigger definitions (see asic_definitions_irs2_carrier_revA.vhd)
--   1. trigger_scaler_timing_generator
--   2. trigger_scaler_single_channel
--   3. trigger_scaler_asic                            
----------------------------------------------------------------------------------

-----------------------------------------------------------
--      1. trigger_scaler_timing_generator               --
-----------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs2_carrier_revA.all;

entity trigger_scaler_timing_generator is
	Port ( 
		CLOCK           : in  STD_LOGIC;
		READ_ENABLE     : out STD_LOGIC;
		RESET_COUNTER   : out STD_LOGIC
	);
end trigger_scaler_timing_generator;

architecture Behavioral of trigger_scaler_timing_generator is
	signal internal_COUNTER          : unsigned(TRIGGER_COUNTER_WIDTH-1 downto 0) := (others => '0');
	signal internal_COUNTER_RESET    : std_logic := '0';
	signal internal_ENABLE_OUT       : std_logic := '0';
	signal internal_ENABLE_OUT_DELAY : std_logic := '0';
begin
	--simple counter
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			if (internal_COUNTER_RESET = '1') then
				internal_COUNTER <= (others => '0');
			else
				internal_COUNTER <= internal_COUNTER + 1;
			end if;
		end if;
	end process;
	--comparator
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			--if (internal_COUNTER = to_unsigned(TRIGGER_TARGET_COUNT,TRIGGER_COUNTER_WIDTH)) then
			if (internal_COUNTER = 500000) then -- IM 6/4/2014: testing 

				internal_COUNTER_RESET <= '1';
			else 
				internal_COUNTER_RESET <= '0';
			end if;
		end if;
	end process;
	internal_ENABLE_OUT <= internal_COUNTER_RESET;
	--pipeline stage to generate a one cycle delayed version of enable
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			internal_ENABLE_OUT_DELAY <= internal_ENABLE_OUT;
		end if;
	end process;
	--Map to output ports
	READ_ENABLE <= internal_ENABLE_OUT;
	RESET_COUNTER <= internal_ENABLE_OUT_DELAY;
end Behavioral;


-----------------------------------------------------------
--      2. single channel trigger scaler                 --
-----------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs2_carrier_revA.all;

entity trigger_scaler_single_channel is
	Port ( 
		SIGNAL_TO_COUNT : in  STD_LOGIC;
		CLOCK           : in  STD_LOGIC;
		READ_ENABLE     : in  STD_LOGIC;
		RESET_COUNTER   : in  STD_LOGIC;
		SCALER          : out STD_LOGIC_VECTOR(TRIGGER_SCALER_BIT_WIDTH-1 downto 0)
	);
end trigger_scaler_single_channel;

architecture Behavioral of trigger_scaler_single_channel is
	signal internal_PULSE_TO_COUNT : std_logic := '0';
	signal internal_COUNTER        : unsigned(TRIGGER_SCALER_BIT_WIDTH-1 downto 0) := (others => '0');
	signal internal_COUNTER_OUT    : std_logic_vector(TRIGGER_SCALER_BIT_WIDTH-1 downto 0) := (others => '0');
begin
	--This takes asynchronous trigger bits and produces pulses
	--with a width of one CLOCK period.
	map_trigger_flip_flop : entity work.edge_to_pulse_converter
	port map(
		INPUT_EDGE   => SIGNAL_TO_COUNT,
		OUTPUT_PULSE => internal_PULSE_TO_COUNT,
		CLOCK        => CLOCK,
		CLOCK_ENABLE => '1'
	);
	--This counts the number of pulses 
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			if (RESET_COUNTER = '1') then
				internal_COUNTER <= (others => '0');
			elsif (internal_PULSE_TO_COUNT = '1' and internal_COUNTER/=x"FFFF") then
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
	SCALER <= internal_COUNTER_OUT;
end Behavioral;

--------------------------------------------------------------------------------------------------
---- 2.A  trigger scaler single channel w built in timing generator
--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs2_carrier_revA.all;

entity trigger_scaler_single_channel_w_timing_gen is
	Port ( 
		SIGNAL_TO_COUNT : in  STD_LOGIC;
		CLOCK           : in  STD_LOGIC;
		READ_ENABLE_IN     : in  STD_LOGIC;
		RESET_COUNTER   : in  STD_LOGIC;
		SCALER          : out STD_LOGIC_VECTOR(TRIGGER_SCALER_BIT_WIDTH-1 downto 0);
		READ_ENABLE_TIMER : out STD_LOGIC
	);
end trigger_scaler_single_channel_w_timing_gen;

architecture Behavioral of trigger_scaler_single_channel_w_timing_gen is
--
--  COMPONENT trigger_scaler_single_channel
--    PORT(
--         internal_SIGNAL_TO_COUNT : IN  std_logic;
--         internal_CLOCK : IN  std_logic;
--         internal_READ_ENABLE : IN  std_logic;
--         internal_RESET_COUNTER : IN  std_logic;
--         internal_SCALER : OUT  std_logic_vector(15 downto 0)
--        );
--    END COMPONENT;
--    
--	 component trigger_scaler_timing_generator
--	  	Port ( 
--		internal_timing_CLOCK           : in  STD_LOGIC;
--		internal_timing_READ_ENABLE     : out STD_LOGIC;
--		internal_timing_RESET_COUNTER   : out STD_LOGIC
--		);
--		end component;
		
		signal internal_ready : STD_LOGIC;
		signal internal_reset_cntr: STD_LOGIC;

	
begin

		u_trigger_scaler_single_channel: entity work.trigger_scaler_single_channel Port Map ( 
			SIGNAL_TO_COUNT => SIGNAL_TO_COUNT,
			CLOCK           => CLOCK,
			READ_ENABLE     => internal_ready,
			RESET_COUNTER   => internal_reset_cntr,
			SCALER          => SCALER
		);
		
		u_trigger_scaler_timing_generator: entity work.trigger_scaler_timing_generator port map (
			CLOCK					=> CLOCK,
			READ_ENABLE		=> internal_ready,
			RESET_COUNTER	=>	internal_reset_cntr
		);
		
		READ_ENABLE_TIMER <=internal_ready;

end Behavioral;
--GV 6/9/14: Bring pin (reset or counter ) out and look on scope to see if timing contstraints are ok

----------------------------------------------------------------
-- 3. scaler counters corresponding to one ASIC (x8 for IRS2) --
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.asic_definitions_irs2_carrier_revA.all;

entity trigger_scaler_one_asic is
	Port ( 
		SIGNALS_TO_COUNT : in  STD_LOGIC_VECTOR(TRIGGER_CHANNELS_PER_ASIC-1 downto 0);
		CLOCK            : in  STD_LOGIC;
		READ_ENABLE      : in  STD_LOGIC;
		RESET_COUNTER    : in  STD_LOGIC;
		SCALERS          : out ASIC_TRIGGER_SCALERS
	);
end trigger_scaler_one_asic;

architecture Behavioral of trigger_scaler_one_asic is
begin
	gen_trigger_scalers_one_asic : for i in 0 to TRIGGER_CHANNELS_PER_ASIC-1 generate
		map_trigger_scaler_ch : entity work.trigger_scaler_single_channel
		port map( 
			SIGNAL_TO_COUNT => SIGNALS_TO_COUNT(i),
			CLOCK           => CLOCK,
			READ_ENABLE     => READ_ENABLE,
			RESET_COUNTER   => RESET_COUNTER,
			SCALER          => SCALERS(i)
		);
	end generate;
end Behavioral;

----------------------------------------------------------------
-- 4. top level of the trigger scaler interface               --
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs2_carrier_revA.all;

entity trigger_scaler_top is
	Port ( 
		TRIGGER_BITS_IN  : in  COL_ROW_TRIGGER_BITS;
		CLOCK            : in  STD_LOGIC;
		ROW_SELECT       : in  STD_LOGIC_VECTOR(ROW_SELECT_BITS-1 downto 0);
		COL_SELECT       : in  STD_LOGIC_VECTOR(COL_SELECT_BITS-1 downto 0);		
		SCALERS          : out ASIC_TRIGGER_SCALERS
	);
end trigger_scaler_top;

architecture Behavioral of trigger_scaler_top is
	signal internal_ACTIVE_TRIGGER_BITS : TRIGGER_BITS;
	signal internal_READ_ENABLE         : std_logic := '0';
	signal internal_RESET_COUNTER       : std_logic := '0';
begin
	--Multiplex the inputs in and select a given ASIC to monitor
	process(TRIGGER_BITS_IN, COL_SELECT, ROW_SELECT) begin
		internal_ACTIVE_TRIGGER_BITS <= TRIGGER_BITS_IN(to_integer(unsigned(COL_SELECT)))(to_integer(unsigned(ROW_SELECT)));
	end process;

	map_trigger_scaler_asic : entity work.trigger_scaler_one_asic
	port map( 
		SIGNALS_TO_COUNT => internal_ACTIVE_TRIGGER_BITS,
		CLOCK            => CLOCK,
		READ_ENABLE      => internal_READ_ENABLE,
		RESET_COUNTER    => internal_RESET_COUNTER,
		SCALERS          => SCALERS
	);
	
	map_trigger_scaler_timing_gen : entity work.trigger_scaler_timing_generator
	port map(
		CLOCK         => CLOCK,
		READ_ENABLE   => internal_READ_ENABLE,
		RESET_COUNTER => internal_RESET_COUNTER
	);

end Behavioral;