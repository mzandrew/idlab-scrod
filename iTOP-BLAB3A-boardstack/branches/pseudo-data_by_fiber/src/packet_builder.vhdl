-- 2011-08-11 to 2011-08-13 mza
-----------------------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------------------
entity packet_builder is
	generic (
		WIDTH_OF_INPUT_ADDRESS_BUS               : integer := 15; -- 128 channels/qevent * 64 samples/window/channel * 4 windows = 32768 samples/qevent
		WIDTH_OF_OUTPUT_ADDRESS_BUS              : integer := 17; -- 132 packets/qevent * 140 words/packet = 73920 words/qevent
--		WIDTH_OF_INPUT_ADDRESS_BUS               : integer :=  8; -- 64 samples/window * 4 windows = 256 samples
		WIDTH_OF_INPUT_DATA_BUS                  : integer := 16;
--		WIDTH_OF_OUTPUT_ADDRESS_BUS              : integer :=  9; -- 140 words/packet
		WIDTH_OF_OUTPUT_DATA_BUS                 : integer := 32;
		NUMBER_OF_WORDS_IN_A_PACKET              : integer := 140;
		HEADER                                   : std_logic_vector(31 downto 0) := x"00be11e2";
		PACKET_SIZE_IN_WORDS                     : std_logic_vector(31 downto 0) := x"0000008c";
		CURRENT_PROTOCOL_FREEZE_DATE             : std_logic_vector(31 downto 0) := x"20110901";
		PACKET_TYPE_EVENT_HEADER                 : std_logic_vector(31 downto 0) := x"55555555";
		PACKET_TYPE_COFFEE                       : std_logic_vector(31 downto 0) := x"00c0ffee";
		PACKET_RESERVED_WORD                     : std_logic_vector(31 downto 0) := x"99999999";
		PACKET_TYPE_EVENT_FOOTER                 : std_logic_vector(31 downto 0) := x"77777777";
		WIDTH_OF_EVENT_NUMBER                    : integer := 32;
		WIDTH_OF_PACKET_NUMBER                   : integer := 16;
		INPUT_BLOCK_RAM_PHASE_OFFSET             : integer := 2;
--		NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES : integer := 8;
		NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES : integer := 4;
--		NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES : integer := 3;
		NUMBER_OF_SAMPLES_IN_A_PACKET            : integer := 256;
		SCROD_REVISION                           : std_logic_vector(15 downto 0) := x"000a";
		SCROD_ID                                 : std_logic_vector(15 downto 0) := x"0001";
		FOOTER                                   : std_logic_vector(31 downto 0) := x"62504944"
	);
	port (
		RESET                                              : in    std_logic;
		CLOCK                                              : in    std_logic;
		INPUT_DATA_BUS                                     : in    std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1     downto 0);
		INPUT_ADDRESS_BUS                                  :   out std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC                 : in    std_logic_vector(8 downto 0);
		OUTPUT_DATA_BUS                                    :   out std_logic_vector(WIDTH_OF_OUTPUT_DATA_BUS-1    downto 0);
		OUTPUT_ADDRESS_BUS                                 :   out std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0);
		OUTPUT_FIFO_WRITE_ENABLE                           :   out std_logic;
		START_BUILDING_A_PACKET                            : in    std_logic;
		PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET :   out std_logic;
		PACKET_BUILDER_IS_BUILDING_A_PACKET                :   out std_logic;
		PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           :   out std_logic;
		THIS_PACKET_IS_A_QUARTER_EVENT_HEADER              : in    std_logic;
		THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER              : in    std_logic;
		THIS_PACKET_IS_QUARTER_EVENT_MEAT                  : in    std_logic;
		EVENT_NUMBER                                       : in    std_logic_vector(WIDTH_OF_EVENT_NUMBER-1       downto 0);
		PACKET_NUMBER                                      : in    std_logic_vector(WIDTH_OF_PACKET_NUMBER-1      downto 0);
		INPUT_BASE_ADDRESS                                 : in    std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
		OUTPUT_BASE_ADDRESS                                : in    std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0)		
	);
end packet_builder;
-----------------------------------------------------------------------------
architecture packet_builder_architecture of packet_builder is
	signal internal_RESET                                              : std_logic;
	signal internal_CLOCK                                              : std_logic;
	signal internal_INPUT_DATA_BUS                                     : std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1     downto 0);
	signal internal_INPUT_ADDRESS_BUS                                  : std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0) := "000" & x"003";
	signal internal_OUTPUT_DATA_BUS                                    : std_logic_vector(WIDTH_OF_OUTPUT_DATA_BUS-1    downto 0) := x"45455656";
	signal internal_OUTPUT_ADDRESS_BUS                                 : std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0) := '0' & x"3434";
	signal internal_OUTPUT_FIFO_WRITE_ENABLE                           : std_logic := '0';
	signal internal_START_BUILDING_A_PACKET                            : std_logic;
	signal internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER              : std_logic;
	signal internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER              : std_logic;
	signal internal_THIS_PACKET_IS_QUARTER_EVENT_MEAT                  : std_logic;
	signal internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET : std_logic := '0';
	signal internal_PACKET_BUILDER_IS_BUILDING_A_PACKET                : std_logic := '0';
	signal internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           : std_logic := '0';
	signal internal_EVENT_NUMBER                                       : std_logic_vector(WIDTH_OF_EVENT_NUMBER-1       downto 0);
	signal internal_PACKET_NUMBER                                      : std_logic_vector(WIDTH_OF_PACKET_NUMBER-1      downto 0);
	signal internal_INPUT_BASE_ADDRESS                                 : std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
	signal internal_OUTPUT_BASE_ADDRESS                                : std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0);
	signal CHECKSUM                                                    : std_logic_vector(31 downto 0);
	signal internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC                 : std_logic_vector(8 downto 0) := "1" & x"5a";
	type packet_builder_state_type is (IDLE,
		ABOUT_TO_BUILD_A_PACKET, BUILD_THE_FIRST_PART_OF_A_PACKET,
		ABOUT_TO_FETCH_SOME_INPUT_DATA, FETCH_SOME_INPUT_DATA, PACK_DATA, WRITE_SOME_OUTPUT_DATA,
		WRITE_THE_LAST_PART_OF_A_PACKET, ALMOST_DONE_BUILDING_PACKET, DONE_BUILDING_PACKET);
	signal packet_builder_state : packet_builder_state_type := IDLE;
begin
	internal_CLOCK     <= CLOCK;
	internal_RESET     <= RESET;
	INPUT_ADDRESS_BUS  <= internal_INPUT_ADDRESS_BUS;
	OUTPUT_DATA_BUS    <= internal_OUTPUT_DATA_BUS;
	OUTPUT_ADDRESS_BUS <= internal_OUTPUT_ADDRESS_BUS;
	PACKET_BUILDER_IS_BUILDING_A_PACKET                <= internal_PACKET_BUILDER_IS_BUILDING_A_PACKET;
	PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           <= internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET;
	PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET <= internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET;
	internal_EVENT_NUMBER        <= EVENT_NUMBER;
	internal_PACKET_NUMBER       <= PACKET_NUMBER;
	internal_INPUT_BASE_ADDRESS  <= INPUT_BASE_ADDRESS;
	internal_OUTPUT_BASE_ADDRESS <= OUTPUT_BASE_ADDRESS;
	OUTPUT_FIFO_WRITE_ENABLE <= internal_OUTPUT_FIFO_WRITE_ENABLE;
	process (internal_CLOCK)
		constant HEADER_INDEX                       : integer := 0;
		constant PACKET_SIZE_IN_WORDS_INDEX         : integer := 1;
		constant CURRENT_PROTOCOL_FREEZE_DATE_INDEX : integer := 2;
		constant PACKET_TYPE_INDEX                  : integer := 3;
		constant EVENT_NUMBER_INDEX                 : integer := 4;
		constant PACKET_NUMBER_INDEX                : integer := 5;
		constant ADDRESS_OF_STARTING_WINDOW_INDEX   : integer := 6;
		constant START_OF_SAMPLE_DATA_INDEX         : integer := 7;
		constant END_OF_SAMPLE_DATA_INDEX           : integer := START_OF_SAMPLE_DATA_INDEX + NUMBER_OF_SAMPLES_IN_A_PACKET * NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES / 8;
		constant START_OF_RESERVED_WORDS_INDEX      : integer := END_OF_SAMPLE_DATA_INDEX + 1;
		constant END_OF_RESERVED_WORDS_INDEX        : integer := NUMBER_OF_WORDS_IN_A_PACKET - 4;
		constant SCROD_REV_AND_ID_INDEX             : integer := NUMBER_OF_WORDS_IN_A_PACKET - 3;
		constant CHECKSUM_INDEX                     : integer := NUMBER_OF_WORDS_IN_A_PACKET - 2;
		constant	FOOTER_INDEX                       : integer := NUMBER_OF_WORDS_IN_A_PACKET - 1;
		-----------------------------------------------------------------------------
		variable word_counter         : integer range 0 to NUMBER_OF_WORDS_IN_A_PACKET := 0;
		variable sample_counter       : integer range 0 to NUMBER_OF_SAMPLES_IN_A_PACKET := 0;
		variable eight_sample_counter : integer range 0 to 8 := 0;
		type eight_samples_type is array(7 downto 0) of unsigned(11 downto 0);
		variable eight_samples        : eight_samples_type;
		variable output_word_counter : integer range 0 to 16 := 0;
		variable block_ram_phase_counter : integer range 0 to 10 := 0;
		-----------------------------------------------------------------------------
	begin
		if (internal_RESET = '1') then
			packet_builder_state <= IDLE;
--			internal_INPUT_ADDRESS_BUS  <= (others => '0');
			internal_INPUT_ADDRESS_BUS  <= "000" & x"033";
			internal_OUTPUT_DATA_BUS    <= (others => '0');
			internal_OUTPUT_ADDRESS_BUS <= (others => '0');
--			internal_OUTPUT_FIFO_WRITE_ENABLE <= '0';
			internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET <= '0';
			internal_PACKET_BUILDER_IS_BUILDING_A_PACKET                <= '0';
			internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           <= '0';
			word_counter := 0;
			sample_counter := 0;
			eight_sample_counter := 0;
			internal_OUTPUT_FIFO_WRITE_ENABLE <= '0';
		elsif rising_edge(internal_CLOCK) then
			internal_INPUT_DATA_BUS          <= INPUT_DATA_BUS;
			internal_START_BUILDING_A_PACKET <= START_BUILDING_A_PACKET;
			case packet_builder_state is
				when IDLE =>
					internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER <= THIS_PACKET_IS_A_QUARTER_EVENT_HEADER;
					internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER <= THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER;
					internal_THIS_PACKET_IS_QUARTER_EVENT_MEAT     <= THIS_PACKET_IS_QUARTER_EVENT_MEAT;
					internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET <= '0';
					internal_PACKET_BUILDER_IS_BUILDING_A_PACKET                <= '0';
					internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           <= '0';
					internal_OUTPUT_FIFO_WRITE_ENABLE <= '0';
					if (internal_START_BUILDING_A_PACKET = '1') then
						internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC <= ADDRESS_OF_STARTING_WINDOW_IN_ASIC;
						internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET <= '1';
						packet_builder_state <= ABOUT_TO_BUILD_A_PACKET;
					end if;
				when ABOUT_TO_BUILD_A_PACKET =>
					sample_counter := 0;
					word_counter := 0;
					internal_PACKET_BUILDER_IS_BUILDING_A_PACKET <= '1';
					internal_INPUT_ADDRESS_BUS  <= internal_INPUT_BASE_ADDRESS;
					internal_OUTPUT_ADDRESS_BUS <= internal_OUTPUT_BASE_ADDRESS;
					packet_builder_state <= BUILD_THE_FIRST_PART_OF_A_PACKET;
				when BUILD_THE_FIRST_PART_OF_A_PACKET =>
					internal_OUTPUT_FIFO_WRITE_ENABLE <= '1';
					internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET <= '0';
				-----------------------------------------------------------------------------
					if (word_counter = 0) then
						CHECKSUM <= std_logic_vector(unsigned(FOOTER) + unsigned(SCROD_REVISION & SCROD_ID)); -- there's nothing valid on the OUTPUT_DATA_BUS the first time through, so we might as well start with the words that come too late at the end...
					else
						internal_OUTPUT_ADDRESS_BUS <= std_logic_vector(unsigned(internal_OUTPUT_ADDRESS_BUS) + 1);
						CHECKSUM <= std_logic_vector(unsigned(CHECKSUM) + unsigned(internal_OUTPUT_DATA_BUS)); -- grabs the previous word
					end if;
					if (word_counter = HEADER_INDEX) then
						internal_OUTPUT_DATA_BUS <= HEADER;
					elsif (word_counter = PACKET_SIZE_IN_WORDS_INDEX) then
						internal_OUTPUT_DATA_BUS <= PACKET_SIZE_IN_WORDS;
					elsif (word_counter = CURRENT_PROTOCOL_FREEZE_DATE_INDEX) then
						internal_OUTPUT_DATA_BUS <= CURRENT_PROTOCOL_FREEZE_DATE;
					-----------------------------------------------------------------------------
					elsif (word_counter = PACKET_TYPE_INDEX) then
						if (internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER = '1') then
							internal_OUTPUT_DATA_BUS <= PACKET_TYPE_EVENT_HEADER;
						elsif (internal_THIS_PACKET_IS_QUARTER_EVENT_MEAT = '1') then
							internal_OUTPUT_DATA_BUS <= PACKET_TYPE_COFFEE;
						elsif (internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER = '1') then
							internal_OUTPUT_DATA_BUS <= PACKET_TYPE_EVENT_FOOTER;
						else
							--internal_OUTPUT_DATA_BUS <= (others => '0');
							internal_OUTPUT_DATA_BUS <= PACKET_RESERVED_WORD;
						end if;
					elsif (word_counter = EVENT_NUMBER_INDEX) then
						internal_OUTPUT_DATA_BUS <= EVENT_NUMBER;
					elsif (word_counter = PACKET_NUMBER_INDEX) then
						internal_OUTPUT_DATA_BUS <= x"0000" & PACKET_NUMBER;
					elsif (word_counter = ADDRESS_OF_STARTING_WINDOW_INDEX) then
						internal_OUTPUT_DATA_BUS <= x"00000" & "000" & internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC;
						packet_builder_state <= ABOUT_TO_FETCH_SOME_INPUT_DATA;
					end if;
					word_counter := word_counter + 1;
				-----------------------------------------------------------------------------
				when ABOUT_TO_FETCH_SOME_INPUT_DATA =>
					internal_OUTPUT_FIFO_WRITE_ENABLE <= '0';
					eight_sample_counter := 0;
					block_ram_phase_counter := 0;
					packet_builder_state <= FETCH_SOME_INPUT_DATA;
				when FETCH_SOME_INPUT_DATA =>
					if (block_ram_phase_counter < INPUT_BLOCK_RAM_PHASE_OFFSET) then -- block_ram_phase_counter = 0,1,2
						internal_INPUT_ADDRESS_BUS <= std_logic_vector(unsigned(internal_INPUT_ADDRESS_BUS) + 1);
						block_ram_phase_counter := block_ram_phase_counter + 1;
					elsif (eight_sample_counter < 8) then -- eight_sample_counter = 0,1,2,3,4,5,6,7
						eight_samples(eight_sample_counter) := unsigned(internal_INPUT_DATA_BUS(11 downto 0));
						if (eight_sample_counter < 8 - INPUT_BLOCK_RAM_PHASE_OFFSET) then -- eight_sample_counter = 0,1,2,3,4
							internal_INPUT_ADDRESS_BUS <= std_logic_vector(unsigned(internal_INPUT_ADDRESS_BUS) + 1);
						end if;
						eight_sample_counter := eight_sample_counter + 1;
						sample_counter := sample_counter + 1;
					else -- eight_sample_counter = 8
						output_word_counter := 0;
						packet_builder_state <= PACK_DATA;
					end if;
				-----------------------------------------------------------------------------
				when PACK_DATA =>
					internal_OUTPUT_FIFO_WRITE_ENABLE <= '0';
					if (NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES = 4) then
						if (output_word_counter = 0) then
							internal_OUTPUT_DATA_BUS <= x"0" & std_logic_vector(eight_samples(1)) & x"0" & std_logic_vector(eight_samples(0));
						elsif (output_word_counter = 1) then
							internal_OUTPUT_DATA_BUS <= x"0" & std_logic_vector(eight_samples(3)) & x"0" & std_logic_vector(eight_samples(2));
						elsif (output_word_counter = 2) then
							internal_OUTPUT_DATA_BUS <= x"0" & std_logic_vector(eight_samples(5)) & x"0" & std_logic_vector(eight_samples(4));
						elsif (output_word_counter = 3) then
							internal_OUTPUT_DATA_BUS <= x"0" & std_logic_vector(eight_samples(7)) & x"0" & std_logic_vector(eight_samples(6));
						end if;
					elsif (NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES = 3) then
						-- do some stuff...
					end if;
					if (output_word_counter < NUMBER_OF_WORDS_NEEDED_TO_PACK_8_SAMPLES) then -- output_word_counter = 0,1,2,3
						internal_OUTPUT_ADDRESS_BUS <= std_logic_vector(unsigned(internal_OUTPUT_ADDRESS_BUS) + 1);
						packet_builder_state <= WRITE_SOME_OUTPUT_DATA;
						output_word_counter := output_word_counter + 1;
					else -- output_word_counter = 4
						if (sample_counter < NUMBER_OF_SAMPLES_IN_A_PACKET) then
							packet_builder_state <= ABOUT_TO_FETCH_SOME_INPUT_DATA;
						else
							packet_builder_state <= WRITE_THE_LAST_PART_OF_A_PACKET;
						end if;
					end if;
				when WRITE_SOME_OUTPUT_DATA =>
					internal_OUTPUT_FIFO_WRITE_ENABLE <= '1';
					CHECKSUM <= std_logic_vector(unsigned(CHECKSUM) + unsigned(internal_OUTPUT_DATA_BUS)); -- grabs the previous word
					packet_builder_state <= PACK_DATA;
					word_counter := word_counter + 1;
				-----------------------------------------------------------------------------
				when WRITE_THE_LAST_PART_OF_A_PACKET =>
					internal_OUTPUT_FIFO_WRITE_ENABLE <= '1';
					CHECKSUM <= std_logic_vector(unsigned(CHECKSUM) + unsigned(internal_OUTPUT_DATA_BUS)); -- grabs the previous word
					if (word_counter <= FOOTER_INDEX) then
						internal_OUTPUT_ADDRESS_BUS <= std_logic_vector(unsigned(internal_OUTPUT_ADDRESS_BUS) + 1);
					end if;
					if (word_counter <= END_OF_RESERVED_WORDS_INDEX) then
						internal_OUTPUT_DATA_BUS <= PACKET_RESERVED_WORD;
					elsif (word_counter = SCROD_REV_AND_ID_INDEX) then
						internal_OUTPUT_DATA_BUS <= SCROD_REVISION & SCROD_ID;
					elsif (word_counter = CHECKSUM_INDEX) then
						internal_OUTPUT_DATA_BUS <= CHECKSUM;
					elsif (word_counter = FOOTER_INDEX) then
						internal_OUTPUT_DATA_BUS <= FOOTER;
					else
						internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET <= '1';
						internal_OUTPUT_FIFO_WRITE_ENABLE <= '0';
						packet_builder_state <= ALMOST_DONE_BUILDING_PACKET;
					end if;
					word_counter := word_counter + 1;
				-----------------------------------------------------------------------------
				when ALMOST_DONE_BUILDING_PACKET =>
					internal_PACKET_BUILDER_IS_BUILDING_A_PACKET <= '0';
					packet_builder_state <= DONE_BUILDING_PACKET;
				when DONE_BUILDING_PACKET =>
					internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET <= '0';
					packet_builder_state <= IDLE;
				when others =>
					packet_builder_state <= IDLE;
			end case;
		end if;
	end process;
end architecture packet_builder_architecture;
-----------------------------------------------------------------------------
-- internal_INPUT_ADDRESS_BUS <= std_logic_vector(to_unsigned(word_counter, 15) + 1); -- an example of how to add to a std_logic_vector
