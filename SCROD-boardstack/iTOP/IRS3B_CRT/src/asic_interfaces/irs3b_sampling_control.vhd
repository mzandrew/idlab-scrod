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
		choose_phase										: in std_logic_vector(1 downto 0); -- LM: added
		--Control from general user registers
		FIRST_ADDRESS_ALLOWED                     : in  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
		LAST_ADDRESS_ALLOWED                      : in  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
		WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER      : in  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0);
		--LSB of sampling to storage address must be tracked here
		SAMPLING_TO_STORAGE_ADDRESS_LSB           : out std_logic;
		--Outputs to the ASIC
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_NO_LSB : out	std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0);
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : out	std_logic;
		state_debug											: out std_logic_vector(1 downto 0)
	);
end irs3b_sampling_control;

architecture Behavioral of irs3b_sampling_control is
	type sampling_state is (INITIALIZE, NORMAL_SAMPLING, POST_TRIGGER_SAMPLING, DONE);
	signal internal_SAMPLING_STATE                            : sampling_state := INITIALIZE;
	signal internal_NEXT_SAMPLING_STATE                       : sampling_state := INITIALIZE;
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS        : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0');
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : std_logic := '0';
	signal internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER        : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0');
	signal internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE : std_logic := '0';
	signal internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET  : std_logic := '0';	
	signal internal_CONTINUE_WRITING                          : std_logic := '0';

	signal phaseA_B_old : std_logic;
	signal initialize_done : std_logic := '0';
	signal sync_edge : std_logic;
	
	signal CLK_SST_div : std_logic_vector(3 downto 0);

	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0');
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2 : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0');
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0');
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2 : unsigned(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0) := (others => '0');
	
	
	
begin
--	LAST_WINDOW_SAMPLED <= std_logic_vector(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS) & '1';
	LAST_WINDOW_SAMPLED <= std_logic_vector(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f) & '1';
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS_NO_LSB <= std_logic_vector(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS);
	--For now we just use PHAB as the LSB for the write address.
	SAMPLING_TO_STORAGE_ADDRESS_LSB <= phaseA_B;

	--State outputs
	process(internal_SAMPLING_STATE) begin
		case internal_SAMPLING_STATE is
			when INITIALIZE =>
				state_debug <= "00";
				CURRENTLY_WRITING <= '1'; --KN: this was set to '0' but this is used to handshake with other blocks.  '0' indicates we've had a trigger of some type
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '0';
				internal_CONTINUE_WRITING <= '0';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '1'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '0'; --LM added, otherwise never active		
			when NORMAL_SAMPLING =>
				state_debug <= "01";
				CURRENTLY_WRITING <= '1';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '1';
				internal_CONTINUE_WRITING <= '1';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '1'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '0'; --LM added, otherwise never active
			when POST_TRIGGER_SAMPLING =>
				state_debug <= "10";
				CURRENTLY_WRITING <= '1';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '1';
				internal_CONTINUE_WRITING <= '1';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '0'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '1'; --LM added, otherwise never active
			when DONE =>
				state_debug <= "11";
				CURRENTLY_WRITING <= '0';
				AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '0';
				internal_CONTINUE_WRITING <= '0';
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET <= '0'; --LM added, otherwise never active
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE <= '0'; --LM added, otherwise never active
		end case;
	end process;
	--Next state logic
	process(internal_SAMPLING_STATE, STOP_WRITING, RESUME_WRITING, internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER, WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER) begin
		case internal_SAMPLING_STATE is
			when INITIALIZE =>
				if (initialize_done = '1') then
					internal_NEXT_SAMPLING_STATE <= NORMAL_SAMPLING;				
				else
					internal_NEXT_SAMPLING_STATE <= INITIALIZE;
				end if;
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
					internal_NEXT_SAMPLING_STATE <= DONE;
				end if;
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
	--Generate the synch signal
		dividedSST: process(CLOCK_SST)
	begin
	if rising_edge(CLOCK_SST) then 
		CLK_SST_div(0) <= not CLK_SST_div(0);
	end if;
	end process;
	
	delayed_PHAB: process(CLK_SSTx2) begin
		if rising_edge(CLK_SSTx2) then 
			CLK_SST_div(1) <= CLK_SST_div(0);
			CLK_SST_div(2) <= CLK_SST_div(1);
			CLK_SST_div(3) <= CLK_SST_div(2);
			phaseA_B_old <= phaseA_B;
			if  (phaseA_B = '1' and phaseA_B_old = '0')  and   do_synchronize = '1'  and initialize_done = '0' then 
				initialize_done <= '1';
				if (CLK_SST_div = "1001"  or CLK_SST_div = "0110" ) then
					sync_edge <= '1';
				else 
					sync_edge <='0'; -- it should be ok as it is 90 degrees off... 
				end if;
			end if;
		end if;
	end process;
	
	--Counter for incrementing the analog storage window 
	process(CLOCK_SST) begin
		if falling_edge(CLOCK_SST) then
			if (internal_CONTINUE_WRITING = '1') then
				if (unsigned(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f & '1') < unsigned(LAST_ADDRESS_ALLOWED)) then
					internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f + 1;
				else
					internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f <= unsigned(FIRST_ADDRESS_ALLOWED(FIRST_ADDRESS_ALLOWED'length-1 downto 1));
				end if;
			end if;
		end if;
	end process;

	process(CLOCK_SST) begin
		if rising_edge(CLOCK_SST) then
			if (internal_CONTINUE_WRITING = '1') then
				if (unsigned(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r & '1') < unsigned(LAST_ADDRESS_ALLOWED)) then
					internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r + 1;
				else
					internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r <= unsigned(FIRST_ADDRESS_ALLOWED(FIRST_ADDRESS_ALLOWED'length-1 downto 1));
				end if;
			end if;
			internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2 <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
		end if;
	end process;

	--Counter for post trigger sampling
	process(CLOCK_SST) begin
		if (falling_edge(CLOCK_SST)) then
			if (internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_RESET = '1') then
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER <= (others => '0');
			elsif (internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER_ENABLE = '1') then
				internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER <= internal_WINDOW_PAIRS_SAMPLED_AFTER_TRIGGER + 1;
			end if;
			internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2 <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f;
		end if;
	end process;
	
--	internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r when sync_edge = '1'
--																	else internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f;

-- Commented out as per Luca's advice	
--	process(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r, internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2, internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f,
--	internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2, choose_phase)
--	begin
--	case choose_phase is
--	when "00" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
--	when "01" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2;
--	when "10" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f;
--	when "11" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2;
--	when others => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
--	end case;
--	end process;

-- This replaces the above process
process(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r, internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2, internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f,
        internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2, choose_phase, sync_edge) begin
	if sync_edge = '1' then
		case choose_phase is
			when "00" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
			when "01" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2;
			when "10" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f;
			when "11" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2;
			when others => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
		end case;
	else
		case choose_phase is
			when "00" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f;
			when "01" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f_2;
			when "10" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
			when "11" => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r_2;
			when others => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_r;
		end case;
	end if;
end process;	
	
--	internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_f;
			
--LM : eventually add delays to guarantee correct alignment of WRADDR = internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS!
end Behavioral;

