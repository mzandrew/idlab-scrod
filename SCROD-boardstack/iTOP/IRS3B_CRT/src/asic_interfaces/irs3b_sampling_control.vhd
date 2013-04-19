----------------------------------------------------------------------------------
-- ASIC sampling control
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.asic_definitions_irs3b_carrier_revB.all;

entity irs3b_sampling_control is
	Port (
		--Flow control signals
		CURRENTLY_WRITING                         : out std_logic;
		STOP_WRITING                              : in  std_logic;
		RESUME_WRITING                            : in  std_logic;
		LAST_WINDOW_SAMPLED                       : out std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
		--Single clock signal in
		CLOCK_SST                                 : in  std_logic;
		-- Phase sync signals
		CLK_SSTx2                                 : in std_logic; -- LM: added to synchronize WRADDR - here it needs to select between rising or falling edge
		phaseA_B                                  : in std_logic; -- LM: added
		do_synchronize										: in std_logic; -- LM: added
		choose_phase										: in std_logic_vector(2 downto 0); -- LM: added, KN: modified to allow 8 phases
		--Control from general user registers
		FIRST_ADDRESS_ALLOWED                     : in  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0); -- the LSB of this corresponds to one window
		LAST_ADDRESS_ALLOWED                      : in  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0); -- the LSB of this corresponds to one window
		WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER      : in  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0); -- the LSB of this corresponds to a pair of windows
		--LSB of sampling to storage address must be tracked here
		SAMPLING_TO_STORAGE_ADDRESS_LSB           : out std_logic; -- this corresponds to one window
		--Outputs to the ASIC
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_NO_LSB : out	std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0); -- the LSB of this corresponds to a pair of windows
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : out	std_logic;
		state_debug											: out std_logic_vector(1 downto 0)
	);
end irs3b_sampling_control;

architecture Behavioral of irs3b_sampling_control is
	type sampling_state is (NORMAL_SAMPLING, POST_TRIGGER_SAMPLING, LATCH_LAST_WINDOW, DONE);
	signal internal_SAMPLING_STATE                            : sampling_state := NORMAL_SAMPLING;
	signal internal_NEXT_SAMPLING_STATE                       : sampling_state := NORMAL_SAMPLING;
	signal internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER        : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0'); -- the LSB of this corresponds to a pair of windows
	signal internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE : std_logic := '0';
	signal internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET  : std_logic := '0';	

	type sync_state is (IDLE, SEARCHING, FOUND, DONE);
	signal internal_SYNC_STATE_RISING       : sync_state;
	signal internal_NEXT_SYNC_STATE_RISING  : sync_state;
	signal internal_SYNC_STATE_FALLING      : sync_state;
	signal internal_NEXT_SYNC_STATE_FALLING : sync_state;
	--Ensure that these registers are not removed
	signal internal_PHAB_RECORD_RISING      : std_logic_vector(1 downto 0);
	signal internal_PHAB_RECORD_FALLING     : std_logic_vector(1 downto 0);

	type address_choice is array(3 downto 0) of std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_SAMPLING_TO_STORAGE_ADDRESS                 : std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING  : address_choice;
	signal internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING : address_choice;
	signal internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_RISING    : std_logic;
	signal internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_FALLING   : std_logic;	

	signal internal_LATCH_LAST_WINDOW : std_logic;

begin
	--Connections to the ports
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS_NO_LSB <= internal_SAMPLING_TO_STORAGE_ADDRESS(ANALOG_MEMORY_ADDRESS_BITS-1 downto 1);
	SAMPLING_TO_STORAGE_ADDRESS_LSB           <= internal_SAMPLING_TO_STORAGE_ADDRESS(0);
	--Signals that should be MUXED out
--	internal_SAMPLING_TO_STORAGE_ADDRESS    <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0)  when choose_phase = "000" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(1)  when choose_phase = "001" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(2)  when choose_phase = "010" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(3)  when choose_phase = "011" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0) when choose_phase = "100" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(1) when choose_phase = "101" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(2) when choose_phase = "110" else
--	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(3) when choose_phase = "111" else
--	                                           (others => 'X');
	internal_SAMPLING_TO_STORAGE_ADDRESS    <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(3)  when choose_phase = "000" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(3) when choose_phase = "001" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(2)  when choose_phase = "010" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(2) when choose_phase = "011" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(1)  when choose_phase = "100" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(1) when choose_phase = "101" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0)  when choose_phase = "110" else
	                                           internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0) when choose_phase = "111" else
	                                           (others => 'X');
	--Simple process to latch the last window sampled
	process(CLOCK_SST) begin
		if (falling_edge(CLOCK_SST)) then
			if (internal_LATCH_LAST_WINDOW = '1') then
				LAST_WINDOW_SAMPLED <= internal_SAMPLING_TO_STORAGE_ADDRESS(ANALOG_MEMORY_ADDRESS_BITS-1 downto 1) & '1';
			end if;
		end if;
	end process;

	--State outputs
	process(internal_SAMPLING_STATE) begin
		case internal_SAMPLING_STATE is
			when NORMAL_SAMPLING =>
				state_debug <= "00";
				CURRENTLY_WRITING <= '1';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '1';
				internal_LATCH_LAST_WINDOW <= '0';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '1'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '0'; --LM added, otherwise never active
			when POST_TRIGGER_SAMPLING =>
				state_debug <= "01";
				CURRENTLY_WRITING <= '1';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '1';
				internal_LATCH_LAST_WINDOW <= '0';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '0'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '1'; --LM added, otherwise never active
			when LATCH_LAST_WINDOW =>
				state_debug <= "10";
				CURRENTLY_WRITING <= '1';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '1';
				internal_LATCH_LAST_WINDOW <= '1';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '0'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '0'; --LM added, otherwise never active				
			when DONE =>
				state_debug <= "11";
				CURRENTLY_WRITING <= '0';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '0';
				internal_LATCH_LAST_WINDOW <= '0';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '0'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '0'; --LM added, otherwise never active
		end case;
	end process;
	--Next state logic
	process(internal_SAMPLING_STATE, STOP_WRITING, RESUME_WRITING, internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER, WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER) begin
		case internal_SAMPLING_STATE is
			when NORMAL_SAMPLING =>
				if (STOP_WRITING = '1') then
					internal_NEXT_SAMPLING_STATE <= POST_TRIGGER_SAMPLING;				
				else
					internal_NEXT_SAMPLING_STATE <= NORMAL_SAMPLING;
				end if;
			when POST_TRIGGER_SAMPLING =>
				if (internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER < unsigned(WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER)) then
					internal_NEXT_SAMPLING_STATE <= POST_TRIGGER_SAMPLING;
				else
					internal_NEXT_SAMPLING_STATE <= LATCH_LAST_WINDOW;
				end if;
			when LATCH_LAST_WINDOW =>
				internal_NEXT_SAMPLING_STATE <= DONE;
			when DONE =>
				if (RESUME_WRITING = '1') then
					internal_NEXT_SAMPLING_STATE <= NORMAL_SAMPLING;
				else
					internal_NEXT_SAMPLING_STATE <= DONE;
				end if;
		end case;
	end process;	
	--Register the next state
	process(CLOCK_SST) begin
		if (falling_edge(CLOCK_SST)) then --LM maybe use this to synchronize with PHAB? To guarantee that the entire state machine moves in lockstep?
--			if  (phaseA_B = '1' and phaseA_B_old = '0') or initialize_done = '1' then 
--				initialize_done <= '1';
				internal_SAMPLING_STATE <= internal_NEXT_SAMPLING_STATE;
--			end if;
		end if;
	end process;

	--Counter for post trigger sampling
	process(CLOCK_SST) begin
		if (falling_edge(CLOCK_SST)) then
			if (internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET = '1') then
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER <= (others => '0'); -- the LSB of this corresponds to a pair of windows
			elsif (internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE = '1') then
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER <= internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER + 1; -- the LSB of this corresponds to a pair of windows
			end if;
		end if;
	end process;
	
	
	----------------SYNCHRONIZATION SIGNALS----------------------
	--RISING EDGE VERSION
	--State outputs
	process(internal_SYNC_STATE_RISING) begin
		internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_RISING <= '0';
		case internal_SYNC_STATE_RISING is
			when IDLE =>
			when SEARCHING =>
			when FOUND =>
				internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_RISING <= '1';
			when DONE =>
		end case;
	end process;
	--Next state logic
	process(internal_SYNC_STATE_RISING, do_synchronize, internal_PHAB_RECORD_RISING) begin
		case internal_SYNC_STATE_RISING is
			when IDLE =>
				if (do_synchronize = '1') then
					internal_NEXT_SYNC_STATE_RISING <= SEARCHING;
				else
					internal_NEXT_SYNC_STATE_RISING <= IDLE;
				end if;
			when SEARCHING =>
				if (internal_PHAB_RECORD_RISING = "01") then
					internal_NEXT_SYNC_STATE_RISING <= FOUND;
				else
					internal_NEXT_SYNC_STATE_RISING <= SEARCHING;
				end if;
			when FOUND =>
				internal_NEXT_SYNC_STATE_RISING <= DONE;
			when DONE =>
				if (do_synchronize = '0') then
					internal_NEXT_SYNC_STATE_RISING <= IDLE;
				else
					internal_NEXT_SYNC_STATE_RISING <= DONE;
				end if;
		end case;
	end process;	
	--Latch next state
	process(CLK_SSTx2) begin
		if (rising_edge(CLK_SSTx2)) then
			internal_SYNC_STATE_RISING <= internal_NEXT_SYNC_STATE_RISING;
		end if;
	end process;
	--FALLING EDGE VERSION
	--State outputs
	process(internal_SYNC_STATE_FALLING) begin
		internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_FALLING <= '0';
		case internal_SYNC_STATE_FALLING is
			when IDLE =>
			when SEARCHING =>
			when FOUND =>
				internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_FALLING <= '1';
			when DONE =>
		end case;
	end process;
	--Next state logic
	process(internal_SYNC_STATE_FALLING, do_synchronize, internal_PHAB_RECORD_FALLING) begin
		case internal_SYNC_STATE_FALLING is
			when IDLE =>
				if (do_synchronize = '1') then
					internal_NEXT_SYNC_STATE_FALLING <= SEARCHING;
				else
					internal_NEXT_SYNC_STATE_FALLING <= IDLE;
				end if;
			when SEARCHING =>
				if (internal_PHAB_RECORD_FALLING = "01") then
					internal_NEXT_SYNC_STATE_FALLING <= FOUND;
				else
					internal_NEXT_SYNC_STATE_FALLING <= SEARCHING;
				end if;
			when FOUND =>
				internal_NEXT_SYNC_STATE_FALLING <= DONE;
			when DONE =>
				if (do_synchronize = '0') then
					internal_NEXT_SYNC_STATE_FALLING <= IDLE;
				else
					internal_NEXT_SYNC_STATE_FALLING <= DONE;
				end if;
		end case;
	end process;	
	--Latch next state
	process(CLK_SSTx2) begin
		if (falling_edge(CLK_SSTx2)) then
			internal_SYNC_STATE_FALLING <= internal_NEXT_SYNC_STATE_FALLING;
		end if;
	end process;

	--RISING EDGE COUNTERS
	process(CLK_SSTx2) begin
		if (rising_edge(CLK_SSTx2)) then
			if (internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_RISING = '1') then
				internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0) <= FIRST_ADDRESS_ALLOWED;
			elsif (unsigned(internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0)) < unsigned(LAST_ADDRESS_ALLOWED)) then
				internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0) <= std_logic_vector(unsigned(internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0)) + 1);
			else
				internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0) <= FIRST_ADDRESS_ALLOWED;				
			end if;
			internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(1) <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(0);
			internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(2) <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(1);
			internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(3) <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_RISING(2);
			internal_PHAB_RECORD_RISING(0) <= phaseA_B;
			internal_PHAB_RECORD_RISING(1) <= internal_PHAB_RECORD_RISING(0);
		end if;
	end process;

	--FALLING EDGE COUNTERS
	process(CLK_SSTx2) begin
		if (falling_edge(CLK_SSTx2)) then
			if (internal_SAMPLING_TO_STORAGE_ADDRESS_RESET_FALLING = '1') then
				internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0) <= FIRST_ADDRESS_ALLOWED;
			elsif (unsigned(internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0)) < unsigned(LAST_ADDRESS_ALLOWED)) then
				internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0) <= std_logic_vector(unsigned(internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0)) + 1);
			else
				internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0) <= FIRST_ADDRESS_ALLOWED;				
			end if;
			internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(1) <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(0);
			internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(2) <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(1);
			internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(3) <= internal_SAMPLING_TO_STORAGE_ADDRESS_CHOICES_FALLING(2);
			internal_PHAB_RECORD_FALLING(0) <= phaseA_B;
			internal_PHAB_RECORD_FALLING(1) <= internal_PHAB_RECORD_FALLING(0);
		end if;
	end process;

end Behavioral;

