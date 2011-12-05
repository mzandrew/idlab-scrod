-- 2011-06-07 kurtis, modified by mza
-- 2011-07 under heavy development by mza
-- 2011-09 mza started adding actual commands
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.Board_Stack_Definitions.all;

entity packet_receiver_and_command_interpreter is
	generic (
		CURRENT_PROTOCOL_FREEZE_DATE  : unsigned(31 downto 0) := x"20110901";
		EXPECTED_PACKET_SIZE : unsigned := x"8c";
		SCROD_REVISION       : unsigned := x"000a";
		SCROD_ID             : unsigned := x"0001"
	);
	port (
		-- User Interface
		RX_D            : in  std_logic_vector(31 downto 0);
		RX_SRC_RDY_N    : in  std_logic;
		-- System Interface
		USER_CLK        : in  std_logic;
		RESET           : in  std_logic;
--		CHANNEL_UP      : in  std_logic;
		WRONG_PACKET_SIZE_COUNTER          :   out std_logic_vector(31 downto 0);
		WRONG_PACKET_TYPE_COUNTER          :   out std_logic_vector(31 downto 0);
		WRONG_PROTOCOL_FREEZE_DATE_COUNTER :   out std_logic_vector(31 downto 0);
		WRONG_SCROD_ADDRESSED_COUNTER      :   out std_logic_vector(31 downto 0);
		WRONG_CHECKSUM_COUNTER             :   out std_logic_vector(31 downto 0);
		WRONG_FOOTER_COUNTER               :   out std_logic_vector(31 downto 0);
		UNKNOWN_ERROR_COUNTER              :   out std_logic_vector(31 downto 0);
		MISSING_ACKNOWLEDGEMENT_COUNTER    :   out std_logic_vector(31 downto 0);
		number_of_sent_events              :   out std_logic_vector(31 downto 0);
		NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR :   out std_logic_vector(31 downto 0);
		resynchronizing_with_header        :   out std_logic;
		-- commands ----------------------------------------------------------------------
		COMMAND_ARGUMENT                   :   out std_logic_vector(31 downto 0);
		EVENT_NUMBER_SET                   :   out std_logic;
		REQUEST_A_GLOBAL_RESET             :   out std_logic;
		DESIRED_DAC_SETTINGS               :   out Board_Stack_Voltages;
		SOFT_TRIGGER_FROM_FIBER            :   out std_logic;
		CLEAR_TRIGGER_VETO                 :   out std_logic;
		RESET_SCALER_COUNTERS              :   out std_logic;
		ASIC_START_WINDOW                  :   out std_logic_vector(8 downto 0);
		ASIC_END_WINDOW                    :   out std_logic_vector(8 downto 0);
		WINDOWS_TO_LOOK_BACK               :   out std_logic_vector(8 downto 0);
		SAMPLING_RATE_FEEDBACK_GOAL        :   out std_logic_vector(31 downto 0);
		WILKINSON_RATE_FEEDBACK_GOAL       :   out std_logic_vector(31 downto 0);
		TRIGGER_WIDTH_FEEDBACK_GOAL        :   out std_logic_vector(31 downto 0);
		SAMPLING_RATE_FEEDBACK_ENABLE      :   out std_logic_vector(15 downto 0);
		WILKINSON_RATE_FEEDBACK_ENABLE     :   out std_logic_vector(15 downto 0);
		TRIGGER_WIDTH_FEEDBACK_ENABLE      :   out std_logic_vector(15 downto 0);
		----------------------------------------------------------------------------------
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_WILKINSON_CLOCK_RATE : in    Wilkinson_Rate_DAC_C_R;
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJP  : in    Sampling_Rate_DAC_C_R;
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJN  : in    Sampling_Rate_DAC_C_R;
		acknowledge_execution_of_command   : in    std_logic;
		UNKNOWN_COMMAND_RECEIVED_COUNTER   :   out std_logic_vector(7 downto 0)
);
end packet_receiver_and_command_interpreter;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.Board_Stack_Definitions.all;

architecture Behavioral of packet_receiver_and_command_interpreter is
	type PACKET_RECEIVER_STATE_TYPE is (WAITING_FOR_HEADER, READING_PACKET_SIZE, READING_PROTOCOL_DATE, READING_PACKET_TYPE, READING_VALUES, READING_SCROD_REV_AND_ID, READING_CHECKSUM, READING_FOOTER);
	type COMMAND_PROCESSING_STATE_TYPE is (WAITING_TO_PROCESS_COMMAND, PROCESS_COMMAND, WAITING_FOR_COMMAND_EXECUTION, RESET_DAC_VALUES_TO_NOMINAL, CLEAR_ALL_SIGNALS, WAITING_FOR_ACKNOWLEDGE);
	signal internal_RX_D                               : std_logic_vector(31 downto 0);
	signal internal_RX_SRC_RDY_N                       : std_logic;
	signal internal_WRONG_PACKET_SIZE_COUNTER          : std_logic_vector(31 downto 0);
	signal internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER : std_logic_vector(31 downto 0);
	signal internal_WRONG_PACKET_TYPE_COUNTER          : std_logic_vector(31 downto 0);
	signal internal_WRONG_SCROD_ADDRESSED_COUNTER      : std_logic_vector(31 downto 0);
	signal internal_WRONG_CHECKSUM_COUNTER             : std_logic_vector(31 downto 0);
	signal internal_WRONG_FOOTER_COUNTER               : std_logic_vector(31 downto 0);
	signal internal_UNKNOWN_ERROR_COUNTER              : std_logic_vector(31 downto 0);
	signal internal_number_of_sent_events              : std_logic_vector(31 downto 0);
	signal internal_MISSING_ACKNOWLEDGEMENT_COUNTER    : std_logic_vector(31 downto 0);
	signal internal_resynchronizing_with_header        : std_logic;
	signal internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR : std_logic_vector(31 downto 0);
	-- commands ----------------------------------------------------------------------
	signal internal_COMMAND_ARGUMENT                   : std_logic_vector(31 downto 0);
	signal internal_EVENT_NUMBER_SET                   : std_logic := '0';
	signal internal_REQUEST_A_GLOBAL_RESET             : std_logic := '0';
	signal internal_SOFT_TRIGGER_FROM_FIBER            : std_logic := '0';
	signal internal_CLEAR_TRIGGER_VETO                 : std_logic := '0';
	signal internal_RESET_SCALER_COUNTERS              : std_logic := '0';
	signal internal_ASIC_START_WINDOW                  : std_logic_vector(8 downto 0) := (others => '0');
	signal internal_ASIC_END_WINDOW                    : std_logic_vector(8 downto 0) := (others => '1');
	signal internal_WINDOWS_TO_LOOK_BACK               : std_logic_vector(8 downto 0) := "000000100";
	signal internal_SAMPLING_RATE_FEEDBACK_GOAL        : std_logic_vector(31 downto 0);
	signal internal_WILKINSON_RATE_FEEDBACK_GOAL       : std_logic_vector(31 downto 0);
	signal internal_TRIGGER_WIDTH_FEEDBACK_GOAL        : std_logic_vector(31 downto 0);
	signal internal_SAMPLING_RATE_FEEDBACK_ENABLE      : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_WILKINSON_RATE_FEEDBACK_ENABLE     : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_TRIGGER_WIDTH_FEEDBACK_ENABLE      : std_logic_vector(15 downto 0) := (others => '0');
	----------------------------------------------------------------------------------
	signal DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE : Wilkinson_Rate_DAC_C_R;
	signal DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJP  : Sampling_Rate_DAC_C_R;
	signal DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJN  : Sampling_Rate_DAC_C_R;
	signal internal_UNKNOWN_COMMAND_RECEIVED_COUNTER   : std_logic_vector(31 downto 0);
	signal PACKET_RECEIVER_STATE                       : PACKET_RECEIVER_STATE_TYPE    := WAITING_FOR_HEADER;
	signal COMMAND_PROCESSING_STATE                    : COMMAND_PROCESSING_STATE_TYPE := RESET_DAC_VALUES_TO_NOMINAL;
begin
	UNKNOWN_COMMAND_RECEIVED_COUNTER   <= internal_UNKNOWN_COMMAND_RECEIVED_COUNTER(7 downto 0);
	internal_RX_D                      <= RX_D;
	internal_RX_SRC_RDY_N              <= RX_SRC_RDY_N;
	WRONG_PACKET_TYPE_COUNTER          <= internal_WRONG_PACKET_TYPE_COUNTER;
	WRONG_PACKET_SIZE_COUNTER          <= internal_WRONG_PACKET_SIZE_COUNTER;
	WRONG_PROTOCOL_FREEZE_DATE_COUNTER <= internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER;
	WRONG_SCROD_ADDRESSED_COUNTER      <= internal_WRONG_SCROD_ADDRESSED_COUNTER;
	WRONG_CHECKSUM_COUNTER             <= internal_WRONG_CHECKSUM_COUNTER;
	WRONG_FOOTER_COUNTER               <= internal_WRONG_FOOTER_COUNTER;
	UNKNOWN_ERROR_COUNTER              <= internal_UNKNOWN_ERROR_COUNTER;
	number_of_sent_events              <= internal_number_of_sent_events;
	NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR <= internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR;
	MISSING_ACKNOWLEDGEMENT_COUNTER    <= internal_MISSING_ACKNOWLEDGEMENT_COUNTER;
	resynchronizing_with_header        <= internal_resynchronizing_with_header;
	-- commands ----------------------------------------------------------------------
	COMMAND_ARGUMENT                   <= internal_COMMAND_ARGUMENT;
	EVENT_NUMBER_SET                   <= internal_EVENT_NUMBER_SET;
	REQUEST_A_GLOBAL_RESET             <= internal_REQUEST_A_GLOBAL_RESET;
	SOFT_TRIGGER_FROM_FIBER            <= internal_SOFT_TRIGGER_FROM_FIBER;
	CLEAR_TRIGGER_VETO                 <= internal_CLEAR_TRIGGER_VETO;
	RESET_SCALER_COUNTERS              <= internal_RESET_SCALER_COUNTERS;
	ASIC_START_WINDOW                  <= internal_ASIC_START_WINDOW;
	ASIC_END_WINDOW                    <= internal_ASIC_END_WINDOW;
	WINDOWS_TO_LOOK_BACK               <= internal_WINDOWS_TO_LOOK_BACK;
	SAMPLING_RATE_FEEDBACK_GOAL        <= internal_SAMPLING_RATE_FEEDBACK_GOAL;
	WILKINSON_RATE_FEEDBACK_GOAL       <= internal_WILKINSON_RATE_FEEDBACK_GOAL;
	TRIGGER_WIDTH_FEEDBACK_GOAL        <= internal_TRIGGER_WIDTH_FEEDBACK_GOAL;
	SAMPLING_RATE_FEEDBACK_ENABLE      <= internal_SAMPLING_RATE_FEEDBACK_ENABLE;
	WILKINSON_RATE_FEEDBACK_ENABLE     <= internal_WILKINSON_RATE_FEEDBACK_ENABLE;
	TRIGGER_WIDTH_FEEDBACK_ENABLE      <= internal_TRIGGER_WIDTH_FEEDBACK_ENABLE;
	----------------------------------------------------------------------------------
	process (internal_WILKINSON_RATE_FEEDBACK_ENABLE, DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_WILKINSON_CLOCK_RATE, DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE)
	begin
--	if (internal_WILK_FEEDBACK_ENABLE = '1') then
--		DESIRED_DAC_SETTINGS(i)(j*2+1)(4) <= internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R(i)(j);
--	else
		for i in 0 to 3 loop
			for j in 0 to 3 loop
				if (internal_WILKINSON_RATE_FEEDBACK_ENABLE(4*i+j) = '1') then -- this line is where the bug is
					DESIRED_DAC_SETTINGS(i)(j*2+1)(4) <= DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_WILKINSON_CLOCK_RATE(i)(j); --VDLY
				else
					DESIRED_DAC_SETTINGS(i)(j*2+1)(4) <= DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE(i)(j); --VDLY
				end if;
				if (internal_SAMPLING_RATE_FEEDBACK_ENABLE(4*i+j) = '1') then
					DESIRED_DAC_SETTINGS(i)(j*2+0)(2) <= DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJP(i)(j); -- VadjP
					DESIRED_DAC_SETTINGS(i)(j*2+0)(3) <= DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJN(i)(j); -- VadjN
				else 
					DESIRED_DAC_SETTINGS(i)(j*2+0)(2) <= DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJP(i)(j); -- VadjP
					DESIRED_DAC_SETTINGS(i)(j*2+0)(3) <= DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJN(i)(j); -- VadjN
				end if;
			end loop;
		end loop;
	end process;
	----------------------------------------------------------------------------------
	process (RESET, USER_CLK, RX_SRC_RDY_N)
		constant COMMAND_PACKET_OFFSET                    : integer                :=   5;
		constant NUMBER_OF_PACKETS_IN_COMMAND_PACKET_BODY : integer range 0 to 255 := 133; -- 140 - 1*(head, size, date, type, scrod, check, foot)
		type command_word_type is array(NUMBER_OF_PACKETS_IN_COMMAND_PACKET_BODY-1 downto 0) of unsigned(31 downto 0);
		variable command_word              : command_word_type;
		variable command_word_counter      : integer range 0 to NUMBER_OF_PACKETS_IN_COMMAND_PACKET_BODY; -- to_integer(EXPECTED_PACKET_SIZE);
		variable packet_size               : unsigned(15 downto 0);
		variable remaining_words_in_packet : unsigned(15 downto 0);
		variable protocol_date             : unsigned(31 downto 0);
		variable value                     : unsigned(31 downto 0);
		variable revision_and_id           : unsigned(31 downto 0);
		variable revision                  : unsigned(15 downto 0);
		variable id                        : unsigned(15 downto 0);
		variable checksum                  : unsigned(31 downto 0);
		variable checksum_from_packet      : unsigned(31 downto 0);
		variable footer                    : unsigned(31 downto 0);
		variable timeout_waiting_for_acknowledge_counter  : unsigned(31 downto 0);
		constant NUMBER_OF_CYCLES_TO_WAIT_FOR_ACKNOWLEDGE : unsigned(31 downto 0) := x"00000100";
		variable m : integer range 0 to 255 := 0;
		variable n : integer range 0 to 255 := 0;
		variable o : integer range 0 to 255 := 0;
		variable p : integer range 0 to 255 := 0;
	begin
		if (RESET = '1') then
			internal_UNKNOWN_COMMAND_RECEIVED_COUNTER   <= (others => '0');
			internal_resynchronizing_with_header        <= '0';
			internal_WRONG_PACKET_TYPE_COUNTER          <= (others => '0');
			internal_WRONG_PACKET_SIZE_COUNTER          <= (others => '0');
			internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER <= (others => '0');
			internal_WRONG_SCROD_ADDRESSED_COUNTER      <= (others => '0');
			internal_WRONG_CHECKSUM_COUNTER             <= (others => '0');
			internal_WRONG_FOOTER_COUNTER               <= (others => '0');
			internal_UNKNOWN_ERROR_COUNTER              <= (others => '0');
			internal_number_of_sent_events              <= (others => '0');
			internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR <= (others => '0');
			internal_MISSING_ACKNOWLEDGEMENT_COUNTER    <= (others => '0');
			-- commands ----------------------------------------------------------------------
			internal_COMMAND_ARGUMENT         <= (others => '0');
			internal_EVENT_NUMBER_SET         <= '0';
			internal_REQUEST_A_GLOBAL_RESET   <= '0';
			internal_SOFT_TRIGGER_FROM_FIBER  <= '0';
			internal_RESET_SCALER_COUNTERS    <= '0';
			internal_ASIC_START_WINDOW        <= (others => '0');
			internal_ASIC_END_WINDOW          <= (others => '1');
			internal_WINDOWS_TO_LOOK_BACK     <= "000000100";
			-- the following will be good when the fiber transceiver reset logic is finally working right:
--			for i in 0 to 3 loop
--				for j in 0 to 7 loop
--					for k in 0 to 7 loop
--						DESIRED_DAC_SETTINGS(i)(j)(k) <= x"001"; -- this should cause the DACs to go silent during reset, but after reset is deaserted, they should come back to nominal values
--					end loop;
--				end loop;
--			end loop;
			internal_SAMPLING_RATE_FEEDBACK_GOAL    <= x"00000410";
			internal_WILKINSON_RATE_FEEDBACK_GOAL   <= x"00000666";
			internal_TRIGGER_WIDTH_FEEDBACK_GOAL    <= x"00000777";
			internal_SAMPLING_RATE_FEEDBACK_ENABLE  <= (others => '0');
			internal_WILKINSON_RATE_FEEDBACK_ENABLE <= (others => '0');
			internal_TRIGGER_WIDTH_FEEDBACK_ENABLE  <= (others => '0');
			----------------------------------------------------------------------------------
			PACKET_RECEIVER_STATE    <= WAITING_FOR_HEADER;
			COMMAND_PROCESSING_STATE <= RESET_DAC_VALUES_TO_NOMINAL;
--		elsif (CHANNEL_UP = '0') then
		elsif (rising_edge(USER_CLK)) then
			-- this only receives packets when internal_RX_SRC_RDY_N = '0'
			-- and it only processes commands when internal_RX_SRC_RDY_N = '1'
			if (internal_RX_SRC_RDY_N = '0') then
				internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR <= std_logic_vector(unsigned(internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR) + 1);
				case PACKET_RECEIVER_STATE is
					when WAITING_FOR_HEADER =>
--						values_read := 0;
						if (internal_RX_D = x"00BE11E2") then
							checksum := x"00BE11E2";
							internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR <= x"00000001";
							PACKET_RECEIVER_STATE <= READING_PACKET_SIZE;
							internal_resynchronizing_with_header <= '0';
						else
							internal_resynchronizing_with_header <= '1';
						end if;
					when READING_PACKET_SIZE =>
						packet_size := unsigned(internal_RX_D(15 downto 0));
						checksum := checksum + packet_size;
						remaining_words_in_packet := packet_size - 2; -- 1 each for header & packet size
						if (packet_size = EXPECTED_PACKET_SIZE) then
							PACKET_RECEIVER_STATE <= READING_PROTOCOL_DATE;
						else
							internal_WRONG_PACKET_SIZE_COUNTER <= std_logic_vector(unsigned(internal_WRONG_PACKET_SIZE_COUNTER) + 1);
							PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
						end if;
					when READING_PROTOCOL_DATE =>
						protocol_date := unsigned(internal_RX_D);
						checksum := checksum + protocol_date;
						remaining_words_in_packet := remaining_words_in_packet - 1;
						if (protocol_date = CURRENT_PROTOCOL_FREEZE_DATE) then
							PACKET_RECEIVER_STATE <= READING_PACKET_TYPE;
						else
							internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER <= std_logic_vector(unsigned(internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER) + 1);
							PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
						end if;
					when READING_PACKET_TYPE =>
						checksum := checksum + unsigned(internal_RX_D);
						remaining_words_in_packet := remaining_words_in_packet - 1;
						if (internal_RX_D = x"B01DFACE") then -- command packet
							command_word_counter := 0;
							PACKET_RECEIVER_STATE <= READING_VALUES;
						else
							internal_WRONG_PACKET_TYPE_COUNTER <= std_logic_vector(unsigned(internal_WRONG_PACKET_TYPE_COUNTER) + 1);
							PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
						end if;
					when READING_VALUES =>
						value := unsigned(internal_RX_D);
						if (command_word_counter < NUMBER_OF_PACKETS_IN_COMMAND_PACKET_BODY) then
							command_word(command_word_counter) := value;
						end if;
						checksum := checksum + value;
						remaining_words_in_packet := remaining_words_in_packet - 1;
						command_word_counter := command_word_counter + 1;
						-- ignore stream of values other than to perform checksum
						if (remaining_words_in_packet = 3) then -- 1 each for SCROD rev/id, checksum and footer
							PACKET_RECEIVER_STATE <= READING_SCROD_REV_AND_ID;
						end if;
					when READING_SCROD_REV_AND_ID =>
						revision_and_id := unsigned(internal_RX_D);
						revision := revision_and_id(31 downto 16);
						id := revision_and_id(15 downto 0);
						checksum := checksum + revision_and_id;
						remaining_words_in_packet := remaining_words_in_packet - 1; -- should be two after this
						if (id = 0 or id = SCROD_ID) then
						else
							internal_WRONG_SCROD_ADDRESSED_COUNTER <= std_logic_vector(unsigned(internal_WRONG_SCROD_ADDRESSED_COUNTER) + 1);
							PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
						end if;
						if (revision = 0 or revision = SCROD_REVISION) then
					else
							internal_WRONG_SCROD_ADDRESSED_COUNTER <= std_logic_vector(unsigned(internal_WRONG_SCROD_ADDRESSED_COUNTER) + 1);
							PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
						end if;
						PACKET_RECEIVER_STATE <= READING_CHECKSUM;
					when READING_CHECKSUM =>
						-- this state does not change the running checksum "checksum" like all other states do
						checksum_from_packet := unsigned(internal_RX_D);
						remaining_words_in_packet := remaining_words_in_packet - 1; -- should be one after this
						PACKET_RECEIVER_STATE <= READING_FOOTER;
					when READING_FOOTER =>
						footer := unsigned(internal_RX_D);
						checksum := checksum + footer;
						remaining_words_in_packet := remaining_words_in_packet - 1; -- should be zero after this
--						if (remaining_words_in_packet = '0') then
--								internal_WRONG__COUNTER <= std_logic_vector(unsigned(internal_WRONG__COUNTER) + 1);
--						end if;
						if (footer = x"62504944") then
							if (checksum = checksum_from_packet) then
								COMMAND_PROCESSING_STATE <= PROCESS_COMMAND;
								PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
							else
								internal_WRONG_CHECKSUM_COUNTER <= std_logic_vector(unsigned(internal_WRONG_CHECKSUM_COUNTER) + 1);
								PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
							end if;
						else
							internal_WRONG_FOOTER_COUNTER <= std_logic_vector(unsigned(internal_WRONG_FOOTER_COUNTER) + 1);
							PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
						end if;
					when others =>
						internal_UNKNOWN_ERROR_COUNTER <= std_logic_vector(unsigned(internal_UNKNOWN_ERROR_COUNTER) + 1);
						PACKET_RECEIVER_STATE <= WAITING_FOR_HEADER;
				end case;
			else
				case COMMAND_PROCESSING_STATE is
					when WAITING_TO_PROCESS_COMMAND =>
					when PROCESS_COMMAND =>
						--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
						if    (command_word(0) = x"33333333") then -- global reset -- when Lt. Comm. Data was stuck in a time loop, seeing that things that should be random were occuring with the number 3 preferentially allowed him to realize the correct course of action and get out of the indefinite loop
							internal_REQUEST_A_GLOBAL_RESET   <= '1';
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"01001500") then -- reset scaler counters -- right ascension and declination of Pisces constellation (and fish have scales)
							internal_RESET_SCALER_COUNTERS <= '1';
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"e0000000") then -- set event number -- e for event and all zeroes for the usual desire of resetting event numbers to zero before a run
							internal_EVENT_NUMBER_SET <= '1';
							internal_COMMAND_ARGUMENT <= std_logic_vector(command_word(1));
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"eeeee01a") then -- set trigger thresholds -- "eee-oh-lay" is the call of a male wood thrush
							for i in 0 to 3 loop
								for j in 0 to 3 loop
									DESIRED_DAC_SETTINGS(i)(j*2+0)(0) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_01
									DESIRED_DAC_SETTINGS(i)(j*2+0)(1) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_23
									DESIRED_DAC_SETTINGS(i)(j*2+0)(6) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_45
									DESIRED_DAC_SETTINGS(i)(j*2+0)(7) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_67
								end loop;
							end loop;
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"5555b1a5") then -- set Vbiases all to the same value
							for i in 0 to 3 loop
								for j in 0 to 3 loop
									DESIRED_DAC_SETTINGS(i)(j*2+0)(5) <= std_logic_vector(command_word(1)(11 downto 0)); -- VBIAS
								end loop;
							end loop;
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"0bac2dac") then -- back to DAC - set all DACs to arbitrary given values
							-- IRS2_DC revB channel mappings
							for j in 6 to 13 loop -- TRGbias values
								m := (j-6) / 2;                 -- 0, 0, 1, 1, 2, 2, 3, 3
								n := 4 * ((j-6) mod 2);         -- 0, 4, 0, 4, 0, 4, 0, 4
								o := n + 2;                     -- 2, 6, 2, 6, 2, 6, 2, 6
								p := j - COMMAND_PACKET_OFFSET; -- 1, 2, 3, 4, 5, 6, 7, 8
								DESIRED_DAC_SETTINGS(m)(n)(4) <= std_logic_vector(command_word(p)(11 downto  0));
								DESIRED_DAC_SETTINGS(m)(o)(4) <= std_logic_vector(command_word(p)(27 downto 16));
							end loop;
--Since we had problems with the equivalent of the following four lines in packet builer, switching to the brute force version.
--							for j in 14 to 45 loop -- TRGthreshold
--								DESIRED_DAC_SETTINGS( (j-14)/8 )( ((j-14)/2*2) mod 8 )( ((j-14) mod 2) * 6 )     <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
--								DESIRED_DAC_SETTINGS( (j-14)/8 )( ((j-14)/2*2) mod 8 )( ((j-14) mod 2) * 6 + 1 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
--							end loop;
							-- TRGthreshold
							DESIRED_DAC_SETTINGS(0)(0)(0) <= std_logic_vector(command_word(14-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(0)(1) <= std_logic_vector(command_word(14-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(0)(6) <= std_logic_vector(command_word(15-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(0)(7) <= std_logic_vector(command_word(15-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(2)(0) <= std_logic_vector(command_word(16-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(2)(1) <= std_logic_vector(command_word(16-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(2)(6) <= std_logic_vector(command_word(17-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(2)(7) <= std_logic_vector(command_word(17-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(4)(0) <= std_logic_vector(command_word(18-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(4)(1) <= std_logic_vector(command_word(18-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(4)(6) <= std_logic_vector(command_word(19-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(4)(7) <= std_logic_vector(command_word(19-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(6)(0) <= std_logic_vector(command_word(20-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(6)(1) <= std_logic_vector(command_word(20-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(0)(6)(6) <= std_logic_vector(command_word(21-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(0)(6)(7) <= std_logic_vector(command_word(21-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(0)(0) <= std_logic_vector(command_word(22-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(0)(1) <= std_logic_vector(command_word(22-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(0)(6) <= std_logic_vector(command_word(23-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(0)(7) <= std_logic_vector(command_word(23-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(2)(0) <= std_logic_vector(command_word(24-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(2)(1) <= std_logic_vector(command_word(24-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(2)(6) <= std_logic_vector(command_word(25-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(2)(7) <= std_logic_vector(command_word(25-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(4)(0) <= std_logic_vector(command_word(26-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(4)(1) <= std_logic_vector(command_word(26-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(4)(6) <= std_logic_vector(command_word(27-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(4)(7) <= std_logic_vector(command_word(27-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(6)(0) <= std_logic_vector(command_word(28-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(6)(1) <= std_logic_vector(command_word(28-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(1)(6)(6) <= std_logic_vector(command_word(29-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(1)(6)(7) <= std_logic_vector(command_word(29-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(0)(0) <= std_logic_vector(command_word(30-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(0)(1) <= std_logic_vector(command_word(30-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(0)(6) <= std_logic_vector(command_word(31-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(0)(7) <= std_logic_vector(command_word(31-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(2)(0) <= std_logic_vector(command_word(32-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(2)(1) <= std_logic_vector(command_word(32-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(2)(6) <= std_logic_vector(command_word(33-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(2)(7) <= std_logic_vector(command_word(33-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(4)(0) <= std_logic_vector(command_word(34-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(4)(1) <= std_logic_vector(command_word(34-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(4)(6) <= std_logic_vector(command_word(35-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(4)(7) <= std_logic_vector(command_word(35-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(6)(0) <= std_logic_vector(command_word(36-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(6)(1) <= std_logic_vector(command_word(36-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(2)(6)(6) <= std_logic_vector(command_word(37-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(2)(6)(7) <= std_logic_vector(command_word(37-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(0)(0) <= std_logic_vector(command_word(38-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(0)(1) <= std_logic_vector(command_word(38-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(0)(6) <= std_logic_vector(command_word(39-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(0)(7) <= std_logic_vector(command_word(39-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(2)(0) <= std_logic_vector(command_word(40-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(2)(1) <= std_logic_vector(command_word(40-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(2)(6) <= std_logic_vector(command_word(41-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(2)(7) <= std_logic_vector(command_word(41-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(4)(0) <= std_logic_vector(command_word(42-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(4)(1) <= std_logic_vector(command_word(42-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(4)(6) <= std_logic_vector(command_word(43-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(4)(7) <= std_logic_vector(command_word(43-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(6)(0) <= std_logic_vector(command_word(44-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(6)(1) <= std_logic_vector(command_word(44-COMMAND_PACKET_OFFSET)(27 downto 16));
							DESIRED_DAC_SETTINGS(3)(6)(6) <= std_logic_vector(command_word(45-COMMAND_PACKET_OFFSET)(11 downto 0));
							DESIRED_DAC_SETTINGS(3)(6)(7) <= std_logic_vector(command_word(45-COMMAND_PACKET_OFFSET)(27 downto 16));
							for j in 46 to 53 loop -- Wbias values
								DESIRED_DAC_SETTINGS( (j-46)/2 )( ((j-46) mod 2)*4+1)(7) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-46)/2 )( ((j-46) mod 2)*4+3)(7) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 54 to 61 loop -- VadjP values
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJP( (j-54)/2 )( 2*((j-54) mod 2) + 0 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJP( (j-54)/2 )( 2*((j-54) mod 2) + 1 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
--								DESIRED_DAC_SETTINGS( (j-54)/2 )( ((j-54) mod 2)*4)(2)   <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
--								DESIRED_DAC_SETTINGS( (j-54)/2 )( ((j-54) mod 2)*4+2)(2) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 62 to 69 loop -- VadjN values
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJN( (j-62)/2 )( 2*((j-62) mod 2) + 0 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJN( (j-62)/2 )( 2*((j-62) mod 2) + 1 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
--								DESIRED_DAC_SETTINGS( (j-62)/2 )( ((j-62) mod 2)*4)(3)   <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
--								DESIRED_DAC_SETTINGS( (j-62)/2 )( ((j-62) mod 2)*4+2)(3) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 70 to 77 loop -- Vbias values
								DESIRED_DAC_SETTINGS( (j-70)/2 )( ((j-70) mod 2)*4 )(5)    <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-70)/2 )( ((j-70) mod 2)*4 +2 )(5) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 78 to 85 loop -- SBbias values
								DESIRED_DAC_SETTINGS( (j-78)/2 )( ((j-78) mod 2)*4+1)(2) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-78)/2 )( ((j-78) mod 2)*4+3)(2) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 86 to 93 loop -- Isel values
								DESIRED_DAC_SETTINGS( (j-86)/2 )( ((j-86) mod 2)*4+1)(1) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-86)/2 )( ((j-86) mod 2)*4+3)(1) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 94 to 101 loop -- Vdly values
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE( (j-94)/2 )( 2*((j-94) mod 2)+0 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0)); -- here is the other pair of bugs
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE( (j-94)/2 )( 2*((j-94) mod 2)+1 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
--								DESIRED_DAC_SETTINGS( (j-94)/2 )( ((j-94) mod 2)*4+1)(4) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
--								DESIRED_DAC_SETTINGS( (j-94)/2 )( ((j-94) mod 2)*4+3)(4) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 102 to 109 loop -- CMPbias values
								DESIRED_DAC_SETTINGS( (j-102)/2 )( ((j-102) mod 2)*4+1)(5) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-102)/2 )( ((j-102) mod 2)*4+3)(5) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 110 to 117 loop -- PUbias values
								DESIRED_DAC_SETTINGS( (j-110)/2 )( ((j-110) mod 2)*4+1)(3) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-110)/2 )( ((j-110) mod 2)*4+3)(3) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 118 to 125 loop -- TRGthreshref values
								DESIRED_DAC_SETTINGS( (j-118)/2 )( ((j-118) mod 2)*4+1)(0) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-118)/2 )( ((j-118) mod 2)*4+3)(0) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));							
							end loop;							
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"1bac2dac") then -- set all DACs to nominal built-in values
							COMMAND_PROCESSING_STATE <= RESET_DAC_VALUES_TO_NOMINAL;
						elsif (command_word(0) = x"4bac2dac") then -- set all DACs to argument #1
							for i in 0 to 3 loop
								for j in 0 to 3 loop
									--IRS2_DC revB channel mappings
									--DAC0 : "DAC1" on schematic
									DESIRED_DAC_SETTINGS(i)(j*2+0)(0) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_01
									DESIRED_DAC_SETTINGS(i)(j*2+0)(1) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_23
									DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJP(i)(j) <= std_logic_vector(command_word(1)(11 downto 0)); -- VADJP
									DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJN(i)(j) <= std_logic_vector(command_word(1)(11 downto 0)); -- VADJN
									DESIRED_DAC_SETTINGS(i)(j*2+0)(4) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRGBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+0)(5) <= std_logic_vector(command_word(1)(11 downto 0)); -- VBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+0)(6) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_45
									DESIRED_DAC_SETTINGS(i)(j*2+0)(7) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRIG_THRESH_67
									--DAC1 : "DAC2" on schematic
									DESIRED_DAC_SETTINGS(i)(j*2+1)(0) <= std_logic_vector(command_word(1)(11 downto 0)); -- TRGTHREF
									DESIRED_DAC_SETTINGS(i)(j*2+1)(1) <= std_logic_vector(command_word(1)(11 downto 0)); -- ISEL
									DESIRED_DAC_SETTINGS(i)(j*2+1)(2) <= std_logic_vector(command_word(1)(11 downto 0)); -- SBBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+1)(3) <= std_logic_vector(command_word(1)(11 downto 0)); -- PUBIAS
									DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE(i)(j) <= std_logic_vector(command_word(1)(11 downto 0)); --VDLY
									DESIRED_DAC_SETTINGS(i)(j*2+1)(5) <= std_logic_vector(command_word(1)(11 downto 0)); -- CMPBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+1)(6) <= std_logic_vector(command_word(1)(11 downto 0)); -- PAD_G									
									DESIRED_DAC_SETTINGS(i)(j*2+1)(7) <= std_logic_vector(command_word(1)(11 downto 0)); -- WBIAS
								end loop;
							end loop;
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"feedbacc") then -- feedback control - enables and set goals of feedback loops
							internal_SAMPLING_RATE_FEEDBACK_GOAL    <= std_logic_vector(command_word(1));
							internal_WILKINSON_RATE_FEEDBACK_GOAL   <= std_logic_vector(command_word(2));
							internal_TRIGGER_WIDTH_FEEDBACK_GOAL    <= std_logic_vector(command_word(3));
							internal_SAMPLING_RATE_FEEDBACK_ENABLE  <= std_logic_vector(command_word(4)(15 downto 0));
							internal_WILKINSON_RATE_FEEDBACK_ENABLE <= std_logic_vector(command_word(5)(15 downto 0));
							internal_TRIGGER_WIDTH_FEEDBACK_ENABLE  <= std_logic_vector(command_word(6)(15 downto 0));
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"000001ff") then -- set starting window in ASIC's analog storage array
							internal_ASIC_START_WINDOW <= std_logic_vector(command_word(1)(8 downto 0));
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"000101ff") then -- set ending window in ASIC's analog storage array
							internal_ASIC_END_WINDOW <= std_logic_vector(command_word(1)(8 downto 0));
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"0100cbac") then 
						   internal_WINDOWS_TO_LOOK_BACK <= std_logic_vector(command_word(1)(8 downto 0));
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"19321965") then -- trigger readout -- birth / death years of Roy Rogers' horse, Trigger
--							internal_number_of_sent_events <= std_logic_vector(unsigned(internal_number_of_sent_events) + 1);
							internal_SOFT_TRIGGER_FROM_FIBER <= '1';
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"0000C1EA") then -- trigger veto clear
							internal_CLEAR_TRIGGER_VETO <= '1';
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
						else -- unsupported command encountered
							internal_UNKNOWN_COMMAND_RECEIVED_COUNTER <= std_logic_vector(unsigned(internal_UNKNOWN_COMMAND_RECEIVED_COUNTER) + 1);
							COMMAND_PROCESSING_STATE <= WAITING_TO_PROCESS_COMMAND;
						end if;
					when WAITING_FOR_COMMAND_EXECUTION =>
						timeout_waiting_for_acknowledge_counter := NUMBER_OF_CYCLES_TO_WAIT_FOR_ACKNOWLEDGE;
						COMMAND_PROCESSING_STATE <= WAITING_FOR_ACKNOWLEDGE;
					when WAITING_FOR_ACKNOWLEDGE =>
						timeout_waiting_for_acknowledge_counter := timeout_waiting_for_acknowledge_counter - 1;
						if (acknowledge_execution_of_command = '1') then
							COMMAND_PROCESSING_STATE <= CLEAR_ALL_SIGNALS;
						elsif (timeout_waiting_for_acknowledge_counter = 0) then
							internal_MISSING_ACKNOWLEDGEMENT_COUNTER <= std_logic_vector(unsigned(internal_MISSING_ACKNOWLEDGEMENT_COUNTER) + 1);
							COMMAND_PROCESSING_STATE <= CLEAR_ALL_SIGNALS;
						end if;
					when RESET_DAC_VALUES_TO_NOMINAL =>
						internal_SAMPLING_RATE_FEEDBACK_ENABLE  <= (others => '0');
						internal_WILKINSON_RATE_FEEDBACK_ENABLE <= (others => '0');
						internal_TRIGGER_WIDTH_FEEDBACK_ENABLE  <= (others => '0');
						for i in 0 to 3 loop
							for j in 0 to 3 loop
								--IRS2_DC revB channel mappings
								--DAC0 : "DAC1" on schematic
								DESIRED_DAC_SETTINGS(i)(j*2+0)(0) <= x"76C"; -- TRIG_THRESH_01
								DESIRED_DAC_SETTINGS(i)(j*2+0)(1) <= x"76C"; -- TRIG_THRESH_23
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJP(i)(j) <= x"C9E"; -- VADJP
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_SAMPLING_RATE_VADJN(i)(j) <= x"42E"; -- VADJN
								DESIRED_DAC_SETTINGS(i)(j*2+0)(4) <= x"3E8"; -- TRGBIAS
								DESIRED_DAC_SETTINGS(i)(j*2+0)(5) <= x"44C"; -- VBIAS
								DESIRED_DAC_SETTINGS(i)(j*2+0)(6) <= x"76C"; -- TRIG_THRESH_45
								DESIRED_DAC_SETTINGS(i)(j*2+0)(7) <= x"76C"; -- TRIG_THRESH_67
								--DAC1 : "DAC2" on schematic
								DESIRED_DAC_SETTINGS(i)(j*2+1)(0) <= x"000"; -- TRGTHREF
								DESIRED_DAC_SETTINGS(i)(j*2+1)(1) <= x"7D0"; -- ISEL
								DESIRED_DAC_SETTINGS(i)(j*2+1)(2) <= x"640"; -- SBBIAS
								DESIRED_DAC_SETTINGS(i)(j*2+1)(3) <= x"CE4"; -- PUBIAS
								DESIRED_DAC_SETTING_FROM_FIBER_FOR_WILKINSON_CLOCK_RATE(i)(j) <= x"AF0"; --VDLY
								DESIRED_DAC_SETTINGS(i)(j*2+1)(5) <= x"384"; -- CMPBIAS
								DESIRED_DAC_SETTINGS(i)(j*2+1)(6) <= x"7FF"; -- PAD_G									
								DESIRED_DAC_SETTINGS(i)(j*2+1)(7) <= x"51E"; -- WBIAS
							end loop;
						end loop;
						COMMAND_PROCESSING_STATE <= CLEAR_ALL_SIGNALS;
					when CLEAR_ALL_SIGNALS =>
						internal_COMMAND_ARGUMENT         <= (others => '0');
						internal_EVENT_NUMBER_SET         <= '0';
						internal_REQUEST_A_GLOBAL_RESET   <= '0';
						internal_SOFT_TRIGGER_FROM_FIBER  <= '0';
						internal_RESET_SCALER_COUNTERS    <= '0';
						internal_CLEAR_TRIGGER_VETO       <= '0';
						COMMAND_PROCESSING_STATE          <= WAITING_TO_PROCESS_COMMAND;
					when others =>
--						internal_UNKNOWN_ERROR_COUNTER <= std_logic_vector(unsigned(internal_UNKNOWN_ERROR_COUNTER) + 1);
						COMMAND_PROCESSING_STATE <= CLEAR_ALL_SIGNALS;
				end case;
			end if;
		end if;
	end process;
end Behavioral;
