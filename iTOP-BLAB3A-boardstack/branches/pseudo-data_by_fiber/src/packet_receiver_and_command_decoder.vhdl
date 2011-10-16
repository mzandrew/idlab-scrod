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
		CHANNEL_UP      : in  std_logic;
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
		acknowledge_execution_of_command   : in    std_logic;
		ERR_COUNT                          :   out std_logic_vector(7 downto 0);
		-- commands ----------------------------------------------------------------------
		COMMAND_ARGUMENT                   :   out std_logic_vector(31 downto 0);
		EVENT_NUMBER_SET                   :   out std_logic;
		REQUEST_A_GLOBAL_RESET             :   out std_logic;
		DESIRED_DAC_SETTINGS               :   out Board_Stack_Voltages;
		start_event_transfer               :   out std_logic
		----------------------------------------------------------------------------------
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
	type COMMAND_PROCESSING_STATE_TYPE is (WAITING_TO_PROCESS_COMMAND, PROCESS_COMMAND, WAITING_FOR_COMMAND_EXECUTION, CLEAR_ALL_SIGNALS, WAITING_FOR_ACKNOWLEDGE);
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
	signal internal_start_event_transfer               : std_logic;
	----------------------------------------------------------------------------------
	signal internal_ERROR_COUNT                        : std_logic_vector(7 downto 0)  := x"00";
	signal PACKET_RECEIVER_STATE                       : PACKET_RECEIVER_STATE_TYPE    := WAITING_FOR_HEADER;
	signal COMMAND_PROCESSING_STATE                    : COMMAND_PROCESSING_STATE_TYPE := CLEAR_ALL_SIGNALS;
begin
	ERR_COUNT                          <= internal_ERROR_COUNT;
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
	start_event_transfer               <= internal_start_event_transfer;
	----------------------------------------------------------------------------------
	process (USER_CLK, RX_SRC_RDY_N)
		constant NUMBER_OF_PACKETS_IN_COMMAND_PACKET_BODY : integer range 0 to 128 := 125;
		variable packet_size               : unsigned(15 downto 0);
		variable remaining_words_in_packet : unsigned(15 downto 0);
		variable protocol_date             : unsigned(31 downto 0);
--		variable values_read               : integer range 0 to 255 := 0; ???
		variable value                     : unsigned(31 downto 0);
		type command_word_type is array(NUMBER_OF_PACKETS_IN_COMMAND_PACKET_BODY-1 downto 0) of unsigned(31 downto 0);
		variable command_word              : command_word_type;
		variable command_word_counter      : integer range 0 to to_integer(EXPECTED_PACKET_SIZE);
		variable revision_and_id           : unsigned(31 downto 0);
		variable revision                  : unsigned(15 downto 0);
		variable id                        : unsigned(15 downto 0);
		variable checksum                  : unsigned(31 downto 0);
		variable checksum_from_packet      : unsigned(31 downto 0);
		variable footer                    : unsigned(31 downto 0);
		variable timeout_waiting_for_acknowledge_counter  : unsigned(31 downto 0);
		constant NUMBER_OF_CYCLES_TO_WAIT_FOR_ACKNOWLEDGE : unsigned(31 downto 0) := x"00000100";
		constant COMMAND_PACKET_OFFSET : integer := 3;
	begin
		if (RESET = '1') then
			PACKET_RECEIVER_STATE    <= WAITING_FOR_HEADER;
			COMMAND_PROCESSING_STATE <= CLEAR_ALL_SIGNALS;
			internal_resynchronizing_with_header   <= '0';
			internal_WRONG_PACKET_TYPE_COUNTER     <= (others => '0');
			internal_WRONG_PACKET_SIZE_COUNTER     <= (others => '0');
			internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER <= (others => '0');
			internal_WRONG_SCROD_ADDRESSED_COUNTER <= (others => '0');
			internal_WRONG_CHECKSUM_COUNTER        <= (others => '0');
			internal_WRONG_FOOTER_COUNTER          <= (others => '0');
			internal_UNKNOWN_ERROR_COUNTER         <= (others => '0');
			internal_number_of_sent_events         <= (others => '0');
			internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR <= (others => '0');
			internal_MISSING_ACKNOWLEDGEMENT_COUNTER <= (others => '0');
			-- commands ----------------------------------------------------------------------
			internal_COMMAND_ARGUMENT         <= (others => '0');
			internal_EVENT_NUMBER_SET         <= '0';
			internal_REQUEST_A_GLOBAL_RESET   <= '0';
			for i in 0 to 3 loop
				for j in 0 to 7 loop
					for k in 0 to 7 loop
						DESIRED_DAC_SETTINGS(i)(j)(k) <= x"001";
					end loop;
				end loop;
			end loop;
			internal_start_event_transfer     <= '0';
			----------------------------------------------------------------------------------
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
						if (command_word(0) = x"b01dface") then
							internal_start_event_transfer <= '1';
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"e0000000") then
							internal_EVENT_NUMBER_SET <= '1';
							internal_COMMAND_ARGUMENT <= std_logic_vector(command_word(1));
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"33333333") then
							internal_REQUEST_A_GLOBAL_RESET   <= '1';
							COMMAND_PROCESSING_STATE <= WAITING_FOR_COMMAND_EXECUTION;
						elsif (command_word(0) = x"1bac2dac") then
							for i in 0 to 3 loop
								for j in 0 to 3 loop
									--Rev B channel mappings
									--DAC0 : "DAC1" on schematic
									DESIRED_DAC_SETTINGS(i)(j*2+0)(0) <= x"76C"; -- TRIG_THRESH_01
									DESIRED_DAC_SETTINGS(i)(j*2+0)(1) <= x"76C"; -- TRIG_THRESH_23
									DESIRED_DAC_SETTINGS(i)(j*2+0)(2) <= x"C9E"; -- VADJP
									DESIRED_DAC_SETTINGS(i)(j*2+0)(3) <= x"42E"; -- VADJN
									DESIRED_DAC_SETTINGS(i)(j*2+0)(4) <= x"3E8"; -- TRGBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+0)(5) <= x"44C"; -- VBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+0)(6) <= x"76C"; -- TRIG_THRESH_45
									DESIRED_DAC_SETTINGS(i)(j*2+0)(7) <= x"76C"; -- TRIG_THRESH_67
									--DAC1 : "DAC2" on schematic
									DESIRED_DAC_SETTINGS(i)(j*2+1)(0) <= x"000"; -- TRGTHREF
									DESIRED_DAC_SETTINGS(i)(j*2+1)(1) <= x"7D0"; -- ISEL
									DESIRED_DAC_SETTINGS(i)(j*2+1)(2) <= x"640"; -- SBBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+1)(3) <= x"CE4"; -- PUBIAS
--									if (internal_WILK_FEEDBACK_ENABLE = '1') then
--										DESIRED_DAC_SETTINGS(i)(j*2+1)(4) <= internal_FEEDBACK_WILKINSON_DAC_VALUE_C_R(i)(j);
--									else
										DESIRED_DAC_SETTINGS(i)(j*2+1)(4) <= x"AF0"; --VDLY
--									end if;
									DESIRED_DAC_SETTINGS(i)(j*2+1)(5) <= x"384"; -- CMPBIAS
									DESIRED_DAC_SETTINGS(i)(j*2+1)(6) <= x"7FF"; -- PAD_G									
									DESIRED_DAC_SETTINGS(i)(j*2+1)(7) <= x"578"; -- WBIAS
								end loop;
							end loop;
						elsif (command_word(0) = x"0bac2dac") then
							--Rev B channel mappings
							for j in 6 to 13 loop -- TRGbias values
								DESIRED_DAC_SETTINGS( (j-6)/2 )( ((j-6) mod 2)*4)(4)    <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-6)/2 )( ((j-6) mod 2)*4+2)(4)  <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 14 to 45 loop -- TRGthreshold
								DESIRED_DAC_SETTINGS( (j-14)/8 )( ((j-14)/2*2) mod 8 )( ((j-14) mod 2) * 6 )     <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-14)/8 )( ((j-14)/2*2) mod 8 )( ((j-14) mod 2) * 6 + 1 ) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 46 to 53 loop -- Wbias values
								DESIRED_DAC_SETTINGS( (j-46)/2 )( ((j-46) mod 2)*4+1)(7) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-46)/2 )( ((j-46) mod 2)*4+3)(7) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 54 to 61 loop -- VadjP values
								DESIRED_DAC_SETTINGS( (j-54)/2 )( ((j-54) mod 2)*4)(2)   <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-54)/2 )( ((j-54) mod 2)*4+2)(2) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
							end loop;
							for j in 62 to 69 loop -- VadjN values
								DESIRED_DAC_SETTINGS( (j-62)/2 )( ((j-62) mod 2)*4)(3)    <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-62)/2 )( ((j-62) mod 2)*4+2)(3) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
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
								DESIRED_DAC_SETTINGS( (j-94)/2 )( ((j-94) mod 2)*4+1)(4) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(11 downto  0));
								DESIRED_DAC_SETTINGS( (j-94)/2 )( ((j-94) mod 2)*4+3)(4) <= std_logic_vector(command_word( j-COMMAND_PACKET_OFFSET)(27 downto 16));
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
						else
							internal_ERROR_COUNT <= std_logic_vector(unsigned(internal_ERROR_COUNT) + 1);
							COMMAND_PROCESSING_STATE <= WAITING_TO_PROCESS_COMMAND;
						end if;
					when WAITING_FOR_COMMAND_EXECUTION =>
--						internal_number_of_sent_events <= std_logic_vector(unsigned(internal_number_of_sent_events) + 1);
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
					when CLEAR_ALL_SIGNALS =>
						internal_COMMAND_ARGUMENT         <= (others => '0');
						internal_EVENT_NUMBER_SET         <= '0';
						internal_REQUEST_A_GLOBAL_RESET   <= '0';
						for i in 0 to 3 loop
							for j in 0 to 7 loop
								for k in 0 to 7 loop
									DESIRED_DAC_SETTINGS(i)(j)(k) <= x"001";
								end loop;
							end loop;
						end loop;
						internal_start_event_transfer     <= '0';
						COMMAND_PROCESSING_STATE          <= WAITING_TO_PROCESS_COMMAND;
					when others => 
--						internal_UNKNOWN_ERROR_COUNTER <= std_logic_vector(unsigned(internal_UNKNOWN_ERROR_COUNTER) + 1);
						COMMAND_PROCESSING_STATE <= CLEAR_ALL_SIGNALS;
				end case;
			end if;
		end if;
	end process;
end Behavioral;
