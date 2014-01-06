--LM: to do:
-- - check what is odd-even w Kurtis
-- - write/copy the serial register blocks
----------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs2_carrier_revA.all;
use work.readout_definitions.all;

entity irs2_digitizing is
	Port ( 
		--Inputs for running the digitizing state machine
		CLOCK                                 : in  STD_LOGIC;
		CLOCK_ENABLE                          : in  STD_LOGIC;
		--Interface to the ROI recorder
		NEXT_WINDOW_FIFO_READ_CLOCK           : out std_logic;
		NEXT_WINDOW_FIFO_READ_ENABLE          : out std_logic;
		NEXT_WINDOW_FIFO_EMPTY                : in  std_logic;
		NEXT_WINDOW_FIFO_DATA                 : in  STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS+ROW_SELECT_BITS+COL_SELECT_BITS+CH_SELECT_BITS-1 downto 0);
		ROI_PARSER_READY_FOR_TRIGGER          : in  std_logic;
		--Input ports for data to be written to packets
		EVENT_NUMBER_WORD                     : in  STD_LOGIC_VECTOR(31 downto 0);
		SCROD_REV_AND_ID_WORD                 : in  STD_LOGIC_VECTOR(31 downto 0);
		REFERENCE_WINDOW                      : in  STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
		--FIFO outputs to packet builder
		WAVEFORM_DATA_OUT                     : out STD_LOGIC_VECTOR(31 downto 0);
		WAVEFORM_DATA_EMPTY                   : out STD_LOGIC;
		WAVEFORM_DATA_READ_CLOCK              : in  STD_LOGIC;
		WAVEFORM_DATA_READ_ENABLE             : in  STD_LOGIC;
		WAVEFORM_DATA_VALID                   : out STD_LOGIC;
		--Status outputs to the packet builder
		DIGITIZER_BUSY                        : out STD_LOGIC;
		--Outputs to the ASIC (or daughter cards)
		ASIC_STORAGE_TO_WILK_ADDRESS          : out STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
		ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE   : out STD_LOGIC;
		ASIC_STORAGE_TO_WILK_ENABLE           : out STD_LOGIC;
		ASIC_WILK_COUNTER_RESET               : out STD_LOGIC;
		ASIC_WILK_COUNTER_START               : out ASIC_START_C; --Real running mode
--		ASIC_WILK_COUNTER_START               : out STD_LOGIC_VECTOR(3 downto 0);  --Switch in for simulation only
		ASIC_WILK_RAMP_ACTIVE                 : out STD_LOGIC;
		ASIC_READOUT_CHANNEL_ADDRESS          : out STD_LOGIC_VECTOR(CH_SELECT_BITS-1 downto 0);
		ASIC_READOUT_SAMPLE_ADDRESS           : out STD_LOGIC_VECTOR(SAMPLE_SELECT_BITS-1 downto 0);
		ASIC_READOUT_ENABLE                   : out STD_LOGIC;
		ASIC_READOUT_TRISTATE_DISABLE         : out Column_Row_Enables; --Real running mode
--		ASIC_READOUT_TRISTATE_DISABLE         : out STD_LOGIC_VECTOR(3 downto 0); --Switch in for simulation
		--Inputs from the ASIC
		ASIC_READOUT_DATA                     : in  ASIC_DATA_C;
--		ASIC_READOUT_DATA                     : in  STD_LOGIC_VECTOR(11 downto 0) --For simulation
		new_address_reached						: in std_logic; --LM: updating address 
		START_NEW_ADDRESS							: out std_logic; --LM: start new address update
		new_sample_address_reached				: in std_logic; --LM: updating sample address
		START_NEW_SAMPLE_ADDRESS							: out std_logic; --LM: start new sample address update
--LM: what follows are the serial interfaces for RD and DO
		DO_RESET_SMPSEL							: out std_logic; --LM: start GPIO to reset SMPSEL_ANY
		DO_SET_SMPSEL								: out std_logic; --LM: start GPIO to set SMPSEL_ANY
		CARRIER_ACTIVE 							: out	std_logic_vector(1 downto 0);
		smpsel_done									: in std_logic; --LM:  GPIO finished setting/resetting  SMPSEL_ANY
		SAMPLE_COUNTER_RESET			: out std_logic; -- LM: resets sample address
--LM: debugging
		state_debug : out STD_LOGIC_VECTOR(3 downto 0)
	);
end irs2_digitizing;

architecture Behavioral of irs2_digitizing is
	constant target_WILKINSON_COUNT : integer := 39;   --Number of cycles to run the Wilkinson counter, 39  @ 6.25 MHz is ~6.2 us
--	constant target_WILKINSON_COUNT : integer := 155;  --Number of cycles to run the Wilkinson counter, 155 @ 25 MHz is ~6.2 us
--	constant target_WILKINSON_COUNT : integer := 310;  --Number of cycles to run the Wilkinson counter, 310 @ 50 MHz is ~6.2 us
--	constant target_WILKINSON_COUNT : integer := 10; --Shorter version for simulation
	signal internal_CHECKSUM        : unsigned(31 downto 0) := (others => '0');
	signal internal_CHECKSUM_RESET  : std_logic := '0';

	type digitizing_state is (IDLE, READ_NEXT_MEMORY_ADDRESS, WAIT_FOR_NEW_ADDRESS, CHECK_IF_DIGITIZED, DIGITIZE, SET_SMPSEL_ANY, RESET_SMPSEL_ANY,
	BUILD_PACKET_HEADER, READOUT_EVEN_WAIT, READOUT_EVEN, READOUT_ODD_WAIT, READOUT_ODD, WRITE_ADC_VALUE, WRITE_CHECKSUM);
	signal internal_DIGITIZING_STATE      : digitizing_state := IDLE;
	signal internal_NEXT_DIGITIZING_STATE : digitizing_state := IDLE;
	
	signal internal_WILKINSON_COUNTER        : unsigned(8 downto 0) := (others => '0');
	signal internal_WILKINSON_COUNTER_ENABLE : std_logic := '0';
	signal internal_WILKINSON_COUNTER_RESET  : std_logic := '0';

	signal internal_PACKET_COUNTER           : unsigned(8 downto 0) := (others => '0');
	signal internal_PACKET_COUNTER_ENABLE    : std_logic := '0';
	signal internal_PACKET_COUNTER_RESET     : std_logic := '0';

	signal internal_SAMPLE_COUNTER           : unsigned(SAMPLE_SELECT_BITS-1 downto 0) := (others => '0');
	signal internal_SAMPLE_COUNTER_ENABLE    : std_logic := '0';
	signal internal_SAMPLE_COUNTER_RESET     : std_logic := '0';
	
	signal internal_NEXT_ADDRESS_TO_READ     : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS+ROW_SELECT_BITS+COL_SELECT_BITS+CH_SELECT_BITS-1 downto 0);
	signal internal_CHANNEL_TO_READ          : STD_LOGIC_VECTOR(CH_SELECT_BITS-1 downto 0);
	signal internal_ROW_TO_READ              : STD_LOGIC_VECTOR(ROW_SELECT_BITS-1 downto 0);
	signal internal_COL_TO_READ              : STD_LOGIC_VECTOR(COL_SELECT_BITS-1 downto 0);	
	signal internal_ADDR_TO_READ             : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);	
	signal internal_LAST_ADDRESS_DIGITIZED   : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);	
	signal internal_NEXT_ADDRESS_READ_ENABLE : STD_LOGIC := '0';

	signal internal_ASIC_READOUT_TRISTATE_DISABLE       : Column_Row_Enables;
	signal internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE : std_logic;
	signal internal_ASIC_STORAGE_TO_WILK_ENABLE         : std_logic;
	signal internal_ASIC_READOUT_ENABLE                 : std_logic;

	--Single start that will be mapped out to all columns
	signal internal_ASIC_WILK_COUNTER_START  : std_logic := '0';
	--Reset and ramp are shared for all asics
	signal internal_ASIC_WILK_COUNTER_RESET  : std_logic := '0';
	signal internal_ASIC_WILK_RAMP_ACTIVE    : std_logic := '0';

	--Signals to choose which column we're reading from
	signal internal_SINGLE_ASIC_READOUT_DATA : STD_LOGIC_VECTOR(11 downto 0);

	--Word for packing two ADC values into a word
	signal internal_ADC_VALUES               : STD_LOGIC_VECTOR(31 downto 0);
	signal internal_ADC_EVEN_READ_ENABLE     : STD_LOGIC := '0';
	signal internal_ADC_ODD_READ_ENABLE      : STD_LOGIC := '0';

	--A set-reset to ensure that we always digitize the first window of any event
	signal internal_FORCE_NEXT_DIGITIZE               : std_logic := '1';
	signal internal_CLEAR_FORCE_NEXT_DIGITIZE         : std_logic := '0';
	signal internal_ROI_PARSER_READY_FOR_TRIGGER      : std_logic := '0';
	signal internal_ROI_PARSER_READY_FOR_TRIGGER_LAST : std_logic := '0';

	--FIFO write interface
	signal internal_WAVEFORM_FIFO_WRITE_ENABLE : std_logic := '0';
	signal internal_WAVEFORM_FIFO_WRITE_DATA   : std_logic_vector(31 downto 0) := (others => '0');

	signal first_sample : std_logic :='1';

--	--Chipscope debugging signals
--	signal internal_CHIPSCOPE_CONTROL : std_logic_vector(35 downto 0);
--	signal internal_CHIPSCOPE_ILA     : std_logic_vector(127 downto 0);
--	signal internal_CHIPSCOPE_ILA_REG : std_logic_vector(127 downto 0);

begin
	--Mapping to the top level ports
	CARRIER_ACTIVE <= internal_ROW_TO_READ;
	
	SAMPLE_COUNTER_RESET <= internal_SAMPLE_COUNTER_RESET;
	NEXT_WINDOW_FIFO_READ_CLOCK         <= CLOCK;
	ASIC_STORAGE_TO_WILK_ADDRESS        <= internal_ADDR_TO_READ;
	ASIC_READOUT_CHANNEL_ADDRESS        <= internal_CHANNEL_TO_READ;
	ASIC_READOUT_SAMPLE_ADDRESS         <= std_logic_vector(internal_SAMPLE_COUNTER);
	ASIC_WILK_COUNTER_RESET             <= internal_ASIC_WILK_COUNTER_RESET;
	ASIC_WILK_RAMP_ACTIVE               <= internal_ASIC_WILK_RAMP_ACTIVE;
	ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE <= internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE;
	ASIC_STORAGE_TO_WILK_ENABLE         <= internal_ASIC_STORAGE_TO_WILK_ENABLE;
	ASIC_READOUT_ENABLE                 <= internal_ASIC_READOUT_ENABLE;
	ASIC_READOUT_TRISTATE_DISABLE       <= internal_ASIC_READOUT_TRISTATE_DISABLE;
	--Output enables for the tristates on the ASIC data buses
	--We could technically readout multiple columns simultaneously, but let's start simple...
	--LM: modification: We NEED to read all columns together, possibly here stuff gets read multiple times
	-- at the moment 3 out of 4 bits are redundant
--	process(internal_COL_TO_READ,internal_ROW_TO_READ) begin
	process(CLOCK) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
		for col in 0 to ASICS_PER_ROW-1 loop
			for row in 0 to ROWS_PER_COL-1 loop
--				if (internal_COL_TO_READ = std_logic_vector(to_unsigned(col,internal_COL_TO_READ'length)) and
				if   internal_ROW_TO_READ = std_logic_vector(to_unsigned(row,internal_COL_TO_READ'length))  then
					 internal_ASIC_READOUT_TRISTATE_DISABLE(col)(row) <= '0';
				else
					 internal_ASIC_READOUT_TRISTATE_DISABLE(col)(row) <= '1';					
				end if;
			end loop;
		end loop;
		end if;
	end process;
--	--Simulation version of above
--	process(internal_COL_TO_READ,internal_ROW_TO_READ) begin
--		for col in 0 to ASICS_PER_ROW-1 loop
--				if (internal_COL_TO_READ = std_logic_vector(to_unsigned(col,internal_COL_TO_READ'length))) then
--					 ASIC_READOUT_TRISTATE_DISABLE(col) <= '0';
--				else
--					 ASIC_READOUT_TRISTATE_DISABLE(col) <= '1';					
--				end if;				
--		end loop;
--	end process;

	--Let's also choose which column we're reading out here
--	process(internal_COL_TO_READ, ASIC_READOUT_DATA) begin
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			internal_SINGLE_ASIC_READOUT_DATA <= ASIC_READOUT_DATA(to_integer(unsigned(internal_COL_TO_READ)));
		end if;
	end process;
--	-- Simulation-friendly version of above
--	internal_SINGLE_ASIC_READOUT_DATA <= ASIC_READOUT_DATA;
	--Map the start signal out to all columns
	map_wilk_start_col : for col in 0 to ASICS_PER_ROW-1 generate
		ASIC_WILK_COUNTER_START(col) <= internal_ASIC_WILK_COUNTER_START;
	end generate;

	--State output logic
	process(internal_DIGITIZING_STATE, NEXT_WINDOW_FIFO_EMPTY, internal_FORCE_NEXT_DIGITIZE, internal_ADDR_TO_READ, internal_LAST_ADDRESS_DIGITIZED, internal_WILKINSON_COUNTER) begin
		--Defaults
		internal_CLEAR_FORCE_NEXT_DIGITIZE  <= '0';
		internal_WILKINSON_COUNTER_ENABLE   <= '0';
		internal_WILKINSON_COUNTER_RESET    <= '0';
		internal_SAMPLE_COUNTER_ENABLE      <= '0';
		internal_SAMPLE_COUNTER_RESET       <= '0';
		internal_PACKET_COUNTER_ENABLE      <= '0';
		internal_PACKET_COUNTER_RESET       <= '0';
		internal_NEXT_ADDRESS_READ_ENABLE   <= '0';
		internal_WAVEFORM_FIFO_WRITE_ENABLE <= '0';
		internal_CHECKSUM_RESET             <= '0';
		internal_ADC_EVEN_READ_ENABLE       <= '0';
		internal_ADC_ODD_READ_ENABLE        <= '0';
		NEXT_WINDOW_FIFO_READ_ENABLE        <= '0';
		internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE <= '0';
		internal_ASIC_STORAGE_TO_WILK_ENABLE         <= '0';
		internal_ASIC_WILK_COUNTER_RESET    <= '0';
		internal_ASIC_WILK_COUNTER_START    <= '0';
		internal_ASIC_WILK_RAMP_ACTIVE      <= '0';
		internal_ASIC_READOUT_ENABLE        <= '0';
		DIGITIZER_BUSY                      <= '1';
		START_NEW_ADDRESS <= '0';
		--Logic outputs for each state
		case(internal_DIGITIZING_STATE) is
			when IDLE =>
				state_debug <= "0001"; --1
				DIGITIZER_BUSY                   <= '0';
				internal_WILKINSON_COUNTER_RESET <= '1';
				internal_SAMPLE_COUNTER_RESET    <= '1';
				internal_PACKET_COUNTER_RESET    <= '1';
				internal_CHECKSUM_RESET          <= '1';
				if (NEXT_WINDOW_FIFO_EMPTY = '0') then
					NEXT_WINDOW_FIFO_READ_ENABLE  <= '1' and CLOCK_ENABLE;
				end if;
			when READ_NEXT_MEMORY_ADDRESS =>
				state_debug <= "0010"; --2
				internal_NEXT_ADDRESS_READ_ENABLE <= '1';
				START_NEW_ADDRESS <= '1';
			when WAIT_FOR_NEW_ADDRESS =>  --LM just a wait state for readout
				state_debug <= "0011"; --3 
			when CHECK_IF_DIGITIZED =>
				state_debug <= "0100"; --4
				if (internal_FORCE_NEXT_DIGITIZE = '1' or internal_ADDR_TO_READ /= internal_LAST_ADDRESS_DIGITIZED) then
					internal_ASIC_WILK_COUNTER_RESET <= '1';
				end if;
			when DIGITIZE =>
				state_debug <= "0101"; --5
				internal_CLEAR_FORCE_NEXT_DIGITIZE  <= '1';
				internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE <= '1';
				internal_ASIC_STORAGE_TO_WILK_ENABLE <= '1';
				internal_WILKINSON_COUNTER_ENABLE <= '1';
				--The following is meant to remove a potential race condition between START and RESET/ENABLES.
				if (to_integer(internal_WILKINSON_COUNTER) /= 0) then
					internal_ASIC_WILK_COUNTER_START <= '1';
					internal_ASIC_WILK_RAMP_ACTIVE   <= '1';
				end if;
			when BUILD_PACKET_HEADER =>
				state_debug <= "0110"; --6
				internal_WAVEFORM_FIFO_WRITE_ENABLE <= '1';
				internal_PACKET_COUNTER_ENABLE      <= '1';
				internal_ASIC_READOUT_ENABLE        <= '1';
				first_sample <='1';
			when READOUT_EVEN =>
				internal_ADC_EVEN_READ_ENABLE       <= '1';
				internal_ASIC_READOUT_ENABLE        <= '1';
				internal_SAMPLE_COUNTER_ENABLE      <= '1';
			when READOUT_EVEN_WAIT => 
				state_debug <= "1000"; --8
--				if(first_sample = '1') then internal_SAMPLE_COUNTER_RESET <='1'; -- gets changed here - first point of entry for samples
--				else 
				internal_SAMPLE_COUNTER_RESET <='0';
--				end if;			
			when READOUT_ODD =>
				state_debug <= "1001"; --9
				internal_ADC_ODD_READ_ENABLE        <= '1';
				internal_ASIC_READOUT_ENABLE        <= '1';
				first_sample <='0';
			when READOUT_ODD_WAIT => NULL;
				state_debug <= "1010"; --A
			when WRITE_ADC_VALUE =>
				state_debug <= "1011"; --B
				internal_WAVEFORM_FIFO_WRITE_ENABLE <= '1';
				internal_PACKET_COUNTER_ENABLE      <= '1';
				internal_SAMPLE_COUNTER_ENABLE      <= '1';
				internal_ASIC_READOUT_ENABLE        <= '1';
			when SET_SMPSEL_ANY =>
				state_debug <= "1100"; --C
				first_sample <='1';
				internal_SAMPLE_COUNTER_RESET    <= '1';					
			when RESET_SMPSEL_ANY =>
				state_debug <= "1101"; --D
				internal_SAMPLE_COUNTER_RESET    <= '1';	 -- an entire cycle of read consists in an entire window - for a single channel				
			when WRITE_CHECKSUM => 
				state_debug <= "1110"; --E
				internal_WAVEFORM_FIFO_WRITE_ENABLE <= '1';
			when others =>
				state_debug <= "1111";
		end case;
	end process;
	--Next state logic
	process(internal_DIGITIZING_STATE,NEXT_WINDOW_FIFO_EMPTY,internal_FORCE_NEXT_DIGITIZE,
	internal_ADDR_TO_READ,internal_LAST_ADDRESS_DIGITIZED,internal_WILKINSON_COUNTER,
	internal_PACKET_COUNTER,internal_SAMPLE_COUNTER, 
	new_address_reached, new_sample_address_reached, smpsel_done) 
	begin
		START_NEW_SAMPLE_ADDRESS <= '0';
		DO_SET_SMPSEL<='0';
		DO_RESET_SMPSEL<='0';
		case(internal_DIGITIZING_STATE) is
			when IDLE =>
				if (NEXT_WINDOW_FIFO_EMPTY = '0') then
					internal_NEXT_DIGITIZING_STATE <= READ_NEXT_MEMORY_ADDRESS;
				else
					internal_NEXT_DIGITIZING_STATE <= IDLE;
				end if;
			when READ_NEXT_MEMORY_ADDRESS =>
--				internal_NEXT_DIGITIZING_STATE <= CHECK_IF_DIGITIZED;
				internal_NEXT_DIGITIZING_STATE <= WAIT_FOR_NEW_ADDRESS;
			when WAIT_FOR_NEW_ADDRESS =>
				if new_address_reached = '1'  then
				internal_NEXT_DIGITIZING_STATE <= CHECK_IF_DIGITIZED;
				else
					internal_NEXT_DIGITIZING_STATE <= WAIT_FOR_NEW_ADDRESS;			
				end if;
			when CHECK_IF_DIGITIZED =>
				if (internal_FORCE_NEXT_DIGITIZE = '1' or internal_ADDR_TO_READ /= internal_LAST_ADDRESS_DIGITIZED) then
					internal_NEXT_DIGITIZING_STATE <= DIGITIZE;
				else
					internal_NEXT_DIGITIZING_STATE <= BUILD_PACKET_HEADER;
				end if;
			when DIGITIZE =>
				if (internal_WILKINSON_COUNTER = to_unsigned(target_WILKINSON_COUNT,internal_WILKINSON_COUNTER'length)) then
					internal_NEXT_DIGITIZING_STATE <= BUILD_PACKET_HEADER;
				else
					internal_NEXT_DIGITIZING_STATE <= DIGITIZE;
				end if;
			when BUILD_PACKET_HEADER =>
				if (to_integer(internal_PACKET_COUNTER) = NUMBER_OF_WAVEFORM_PACKET_WORDS_BEFORE_ADC) then
					internal_NEXT_DIGITIZING_STATE <= SET_SMPSEL_ANY;
					DO_SET_SMPSEL<='1';
				else
					internal_NEXT_DIGITIZING_STATE <= BUILD_PACKET_HEADER;
				end if;
			when SET_SMPSEL_ANY =>
				if smpsel_done = '1' then 
						internal_NEXT_DIGITIZING_STATE <= READOUT_EVEN_WAIT;
						START_NEW_SAMPLE_ADDRESS <= '1';
					else
						internal_NEXT_DIGITIZING_STATE <= SET_SMPSEL_ANY;					
				end if;
			when READOUT_EVEN_WAIT =>
				if new_sample_address_reached = '1'  then
					internal_NEXT_DIGITIZING_STATE <= READOUT_EVEN;
				else
					internal_NEXT_DIGITIZING_STATE <= READOUT_EVEN_WAIT;				
				end if;
			when READOUT_EVEN =>
					internal_NEXT_DIGITIZING_STATE <= READOUT_ODD_WAIT;
					START_NEW_SAMPLE_ADDRESS <= '1';
			when READOUT_ODD_WAIT =>
				if new_sample_address_reached = '1'  then
				internal_NEXT_DIGITIZING_STATE <= READOUT_ODD;
				else
					internal_NEXT_DIGITIZING_STATE <= READOUT_ODD_WAIT;
				end if;
			when READOUT_ODD =>
				internal_NEXT_DIGITIZING_STATE <= WRITE_ADC_VALUE;
			when WRITE_ADC_VALUE =>
				if (to_integer(internal_SAMPLE_COUNTER) = SAMPLES_PER_WINDOW-1) then
					internal_NEXT_DIGITIZING_STATE <= RESET_SMPSEL_ANY;
					DO_RESET_SMPSEL<='1';
				else
					START_NEW_SAMPLE_ADDRESS <= '1';
					internal_NEXT_DIGITIZING_STATE <= READOUT_EVEN_WAIT;
				end if;
			when RESET_SMPSEL_ANY =>
				if smpsel_done = '1' then 
					internal_NEXT_DIGITIZING_STATE <= WRITE_CHECKSUM;
				else
						internal_NEXT_DIGITIZING_STATE <= RESET_SMPSEL_ANY;				
				end if;
			when WRITE_CHECKSUM =>
				internal_NEXT_DIGITIZING_STATE <= IDLE;
			when others =>
				internal_NEXT_DIGITIZING_STATE <= IDLE;
		end case;
	end process;	
	--Register the next state
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			internal_DIGITIZING_STATE <= internal_NEXT_DIGITIZING_STATE;
		end if;
	end process;

	--Logic to parse the row, col, channel, address from the word
	internal_COL_TO_READ     <= internal_NEXT_ADDRESS_TO_READ(ANALOG_MEMORY_ADDRESS_BITS+ROW_SELECT_BITS+COL_SELECT_BITS+CH_SELECT_BITS-1 downto ANALOG_MEMORY_ADDRESS_BITS+ROW_SELECT_BITS+CH_SELECT_BITS);
	internal_ROW_TO_READ     <= internal_NEXT_ADDRESS_TO_READ(ANALOG_MEMORY_ADDRESS_BITS+ROW_SELECT_BITS+CH_SELECT_BITS-1 downto ANALOG_MEMORY_ADDRESS_BITS+CH_SELECT_BITS);
	internal_CHANNEL_TO_READ <= internal_NEXT_ADDRESS_TO_READ(ANALOG_MEMORY_ADDRESS_BITS+CH_SELECT_BITS-1 downto ANALOG_MEMORY_ADDRESS_BITS);
	internal_ADDR_TO_READ    <= internal_NEXT_ADDRESS_TO_READ(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	--Keep track of the last address
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_NEXT_ADDRESS_READ_ENABLE = '1') then
				internal_NEXT_ADDRESS_TO_READ   <= NEXT_WINDOW_FIFO_DATA;
				internal_LAST_ADDRESS_DIGITIZED <= internal_ADDR_TO_READ;
			end if;
		end if;
	end process;

	--Look for rising edges of ROI_PARSER_READY_FOR_TRIGGER to set the status of FORCE_NEXT_DIGITIZE
	--Clear it on the first digitization for an event
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			internal_ROI_PARSER_READY_FOR_TRIGGER      <= ROI_PARSER_READY_FOR_TRIGGER;
			internal_ROI_PARSER_READY_FOR_TRIGGER_LAST <= internal_ROI_PARSER_READY_FOR_TRIGGER;
		end if;
	end process;
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_ROI_PARSER_READY_FOR_TRIGGER = '1' and internal_ROI_PARSER_READY_FOR_TRIGGER_LAST = '0') then
				internal_FORCE_NEXT_DIGITIZE <= '1';
			elsif (internal_CLEAR_FORCE_NEXT_DIGITIZE = '1') then
				internal_FORCE_NEXT_DIGITIZE <= '0';
			end if;
		end if;
	end process;

	--Counters for Wilkinson conversion, sample selection, and packet word
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_WILKINSON_COUNTER_RESET = '1') then
				internal_WILKINSON_COUNTER <= (others => '0');
			elsif (internal_WILKINSON_COUNTER_ENABLE = '1') then
				internal_WILKINSON_COUNTER <= internal_WILKINSON_COUNTER + 1;
			end if;
		end if;
	end process;
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_SAMPLE_COUNTER_RESET = '1') then
				internal_SAMPLE_COUNTER <= (others => '0');
			elsif (internal_SAMPLE_COUNTER_ENABLE = '1') then
				internal_SAMPLE_COUNTER <= internal_SAMPLE_COUNTER + 1;
			end if;
		end if;
	end process;
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_PACKET_COUNTER_RESET = '1') then
				internal_PACKET_COUNTER <= (others => '0');
			elsif (internal_PACKET_COUNTER_ENABLE = '1') then
				internal_PACKET_COUNTER <= internal_PACKET_COUNTER + 1;
			end if;
		end if;
	end process;

	--Process to handle incrementing the checksum
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_CHECKSUM_RESET = '1') then
				internal_CHECKSUM <= (others => '0');
			elsif (internal_WAVEFORM_FIFO_WRITE_ENABLE = '1') then
				internal_CHECKSUM <= internal_CHECKSUM + unsigned(internal_WAVEFORM_FIFO_WRITE_DATA);
			end if;
		end if;
	end process;
	
	--Process to pack two 12-bit ADC values into a single 32-bit word
	process(CLOCK, CLOCK_ENABLE) begin
		if (rising_edge(CLOCK) and CLOCK_ENABLE = '1') then
			if (internal_ADC_EVEN_READ_ENABLE = '1') then
				internal_ADC_VALUES(15 downto 0) <= x"0" & internal_SINGLE_ASIC_READOUT_DATA;
			end if;
			if (internal_ADC_ODD_READ_ENABLE = '1') then
				internal_ADC_VALUES(31 downto 16)  <= x"0" & internal_SINGLE_ASIC_READOUT_DATA;
			end if;
		end if;
	end process;
	
	--Multiplexer to choose what's being written to the FIFO	
	internal_WAVEFORM_FIFO_WRITE_DATA <=                   word_PACKET_HEADER when (to_integer(internal_PACKET_COUNTER) = 0) else
	                                     word_NUMBER_WORDS_IN_WAVEFORM_PACKET when (to_integer(internal_PACKET_COUNTER) = 1) else
	                                                     word_WAVEFORM_HEADER when (to_integer(internal_PACKET_COUNTER) = 2) else
	                                                    SCROD_REV_AND_ID_WORD when (to_integer(internal_PACKET_COUNTER) = 3) else
	                  std_logic_vector(resize(unsigned(REFERENCE_WINDOW),32)) when (to_integer(internal_PACKET_COUNTER) = 4) else --This was swapped with 5 on 2013-03-03
																		     EVENT_NUMBER_WORD when (to_integer(internal_PACKET_COUNTER) = 5) else --This was swapped with 4 on 2013-03-03
	                                  word_NUMBER_SEGMENTS_IN_WAVEFORM_PACKET when (to_integer(internal_PACKET_COUNTER) = 6) else
	     std_logic_vector(resize(unsigned(internal_NEXT_ADDRESS_TO_READ),32)) when (to_integer(internal_PACKET_COUNTER) = 7) else
	                                   word_NUMBER_SAMPLES_IN_WAVEFORM_PACKET when (to_integer(internal_PACKET_COUNTER) = 8) else
	                                      std_logic_vector(internal_CHECKSUM) when (to_integer(internal_PACKET_COUNTER) = to_integer(unsigned(word_NUMBER_WORDS_IN_WAVEFORM_PACKET)+1)) else
	                                                     internal_ADC_VALUES;

	--Instantiate the FIFO that will contain the waveform packets
	map_waveform_packet_fifo : entity work.waveform_packets_fifo
	port map(
		rst    => '0',
		wr_clk => CLOCK,
		rd_clk => WAVEFORM_DATA_READ_CLOCK,
		din    => internal_WAVEFORM_FIFO_WRITE_DATA,
		wr_en  => (internal_WAVEFORM_FIFO_WRITE_ENABLE and CLOCK_ENABLE),
		rd_en  => WAVEFORM_DATA_READ_ENABLE,
		dout   => WAVEFORM_DATA_OUT,
		full   => open,
		empty  => WAVEFORM_DATA_EMPTY,
		valid  => WAVEFORM_DATA_VALID	
	);



--	--DEBUGGING CRAP
--	map_ILA : entity work.s6_ila
--	port map (
--		CONTROL => internal_CHIPSCOPE_CONTROL,
--		CLK     => CLOCK,
--		TRIG0   => internal_CHIPSCOPE_ILA_REG
--	);
--	map_ICON : entity work.s6_icon
--	port map (
--		CONTROL0 => internal_CHIPSCOPE_CONTROL
--	);
--	
--	--Workaround for CS/picoblaze stupidness
--	process(CLOCK) begin
--		if (rising_edge(CLOCK)) then
--			internal_CHIPSCOPE_ILA_REG <= internal_CHIPSCOPE_ILA;
--		end if;
--	end process;
--	
--	internal_CHIPSCOPE_ILA(0)            <= internal_ASIC_WILK_COUNTER_RESET;
--	internal_CHIPSCOPE_ILA(1)            <= internal_ASIC_WILK_COUNTER_START;
--	internal_CHIPSCOPE_ILA(2)            <= internal_ASIC_WILK_RAMP_ACTIVE;
--	internal_CHIPSCOPE_ILA(14 downto  3) <= internal_SINGLE_ASIC_READOUT_DATA;
--	internal_CHIPSCOPE_ILA(16 downto 15) <= internal_COL_TO_READ;
--	internal_CHIPSCOPE_ILA(18 downto 17) <= internal_ROW_TO_READ;
--	internal_CHIPSCOPE_ILA(21 downto 19) <= internal_CHANNEL_TO_READ;
--	internal_CHIPSCOPE_ILA(27 downto 22) <= std_logic_vector(internal_SAMPLE_COUNTER);
--	internal_CHIPSCOPE_ILA(36 downto 28) <= internal_ADDR_TO_READ;
--	internal_CHIPSCOPE_ILA(45 downto 37) <= internal_LAST_ADDRESS_DIGITIZED;
--	internal_CHIPSCOPE_ILA(61 downto 46) <= NEXT_WINDOW_FIFO_DATA;
--	internal_CHIPSCOPE_ILA(62)           <= NEXT_WINDOW_FIFO_EMPTY;
--	internal_CHIPSCOPE_ILA(63)           <= internal_FORCE_NEXT_DIGITIZE;
--	internal_CHIPSCOPE_ILA(64)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(0)(0);
--	internal_CHIPSCOPE_ILA(65)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(0)(1);
--	internal_CHIPSCOPE_ILA(66)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(0)(2);
--	internal_CHIPSCOPE_ILA(67)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(0)(3);
--	internal_CHIPSCOPE_ILA(68)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(1)(0);
--	internal_CHIPSCOPE_ILA(69)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(1)(1);
--	internal_CHIPSCOPE_ILA(70)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(1)(2);
--	internal_CHIPSCOPE_ILA(71)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(1)(3);
--	internal_CHIPSCOPE_ILA(72)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(2)(0);
--	internal_CHIPSCOPE_ILA(73)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(2)(1);
--	internal_CHIPSCOPE_ILA(74)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(2)(2);
--	internal_CHIPSCOPE_ILA(75)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(2)(3);
--	internal_CHIPSCOPE_ILA(76)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(3)(0);
--	internal_CHIPSCOPE_ILA(77)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(3)(1);
--	internal_CHIPSCOPE_ILA(78)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(3)(2);
--	internal_CHIPSCOPE_ILA(79)           <= internal_ASIC_READOUT_TRISTATE_DISABLE(3)(3);
--	internal_CHIPSCOPE_ILA(80)           <= internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE;
--	internal_CHIPSCOPE_ILA(81)           <= internal_ASIC_STORAGE_TO_WILK_ENABLE;
--	internal_CHIPSCOPE_ILA(82)           <= internal_ASIC_READOUT_ENABLE;

end Behavioral;

