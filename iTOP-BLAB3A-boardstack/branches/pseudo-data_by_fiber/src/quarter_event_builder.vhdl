-- 2011-08-11 to 2011-08-13 mza
-----------------------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------------------
entity quarter_event_builder is
	generic (
		CURRENT_PROTOCOL_FREEZE_DATE                : std_logic_vector(31 downto 0) := x"20110901";
		NUMBER_OF_INPUT_BLOCK_RAMS                  : integer :=  2;
		WIDTH_OF_INPUT_ADDRESS_BUS                  : integer := 13; -- (128 channels/qevent * 64 samples/window/channel * 4 windows = 32768 samples/qevent) / 2^NUMBER_OF_INPUT_BLOCK_RAMS
		WIDTH_OF_INPUT_DATA_BUS                     : integer := 16;
		WIDTH_OF_OUTPUT_ADDRESS_BUS                 : integer := 17; -- 132 packets/qevent * 140 words/packet = 73920 words/qevent
		WIDTH_OF_OUTPUT_DATA_BUS                    : integer := 32;
		NUMBER_OF_SAMPLES_IN_ONE_WAVEFORM           : integer := 64;
		NUMBER_OF_WAVEFORMS_TO_READ_OUT_AT_ONE_TIME : integer := 8;
		NUMBER_OF_CHANNELS_TO_READ_OUT_AT_ONE_TIME  : integer := 8;
		NUMBER_OF_WORDS_IN_A_PACKET                 : integer := 140;
		NUMBER_OF_PACKETS_IN_AN_EVENT               : integer := 132;
		WIDTH_OF_EVENT_NUMBER                       : integer := 32;
		WIDTH_OF_PACKET_NUMBER                      : integer := 8
	);
	port (
		RESET                              : in    std_logic;
		CLOCK                              : in    std_logic;
		COMMAND_ARGUMENT                   : in    std_logic_vector(31 downto 0);
		EVENT_NUMBER_SET                   : in    std_logic;
		INPUT_DATA_BUS                     : in    std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1           downto 0);
		INPUT_ADDRESS_BUS                  :   out std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1        downto 0);
		INPUT_BLOCK_RAM_ADDRESS            :   out std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1        downto 0);
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC : in    std_logic_vector(8 downto 0);
		OUTPUT_DATA_BUS                    :   out std_logic_vector(WIDTH_OF_OUTPUT_DATA_BUS-1    downto 0);
		OUTPUT_ADDRESS_BUS                 :   out std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0);
		OUTPUT_FIFO_WRITE_ENABLE           :   out std_logic;
		START_BUILDING_A_QUARTER_EVENT     : in    std_logic;
		DONE_BUILDING_A_QUARTER_EVENT      :   out std_logic
	);
end quarter_event_builder;
-----------------------------------------------------------------------------
architecture quarter_event_builder_architecture of quarter_event_builder is
	component packet_builder
	generic (
		NUMBER_OF_PACKETS_IN_AN_EVENT : integer := NUMBER_OF_PACKETS_IN_AN_EVENT;
		CURRENT_PROTOCOL_FREEZE_DATE  : std_logic_vector(31 downto 0) := CURRENT_PROTOCOL_FREEZE_DATE
	);
	port (
		RESET                                              : in    std_logic;
		CLOCK                                              : in    std_logic;
		INPUT_DATA_BUS                                     : in    std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1     downto 0);
		INPUT_ADDRESS_BUS                                  :   out std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
		INPUT_BLOCK_RAM_ADDRESS                            :   out std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
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
	end component;
	signal internal_RESET                                              : std_logic;
	signal internal_CLOCK                                              : std_logic;
	signal internal_START_BUILDING_A_QUARTER_EVENT                     : std_logic := '0';
	signal internal_START_BUILDING_A_PACKET                            : std_logic := '0';
	signal internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER_PACKET       : std_logic;
	signal internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER_PACKET       : std_logic;
	signal internal_THIS_PACKET_IS_A_QUARTER_EVENT_MEAT_PACKET         : std_logic;
	signal internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET : std_logic;
	signal internal_PACKET_BUILDER_IS_BUILDING_A_PACKET                : std_logic;
	signal internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           : std_logic;
	signal internal_EVENT_NUMBER                                       : std_logic_vector(WIDTH_OF_EVENT_NUMBER-1       downto 0);
	signal internal_COMMAND_ARGUMENT                                   : std_logic_vector(31 downto 0);
	signal internal_EVENT_NUMBER_SET                                   : std_logic := '0';
	signal internal_PACKET_NUMBER                                      : std_logic_vector(WIDTH_OF_PACKET_NUMBER-1      downto 0);
	signal internal_INPUT_BASE_ADDRESS                                 : std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
	signal internal_OUTPUT_BASE_ADDRESS                                : std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0);
	signal internal_DONE_BUILDING_A_QUARTER_EVENT                      : std_logic := '0';
	type quarter_event_builder_state_type is (IDLE,
		BUILD_A_QUARTER_EVENT_HEADER_PACKET, DONE_BUILDING_A_QUARTER_EVENT_HEADER_PACKET,
		BUILD_A_QUARTER_EVENT_MEAT_PACKET, DONE_BUILDING_A_QUARTER_EVENT_MEAT_PACKET,
		BUILD_A_QUARTER_EVENT_FOOTER_PACKET, DONE_BUILDING_A_QUARTER_EVENT_FOOTER_PACKET,
		ALMOST_DONE_BUILDING_QUARTER_EVENT, DONE_BUILDING_QUARTER_EVENT);
	signal quarter_event_builder_state : quarter_event_builder_state_type := IDLE;
begin
	PB : packet_builder port map (
		RESET                                              => internal_RESET,
		CLOCK                                              => internal_CLOCK,
		INPUT_DATA_BUS                                     => INPUT_DATA_BUS,
		INPUT_ADDRESS_BUS                                  => INPUT_ADDRESS_BUS,
		INPUT_BLOCK_RAM_ADDRESS                            => INPUT_BLOCK_RAM_ADDRESS,
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC                 => ADDRESS_OF_STARTING_WINDOW_IN_ASIC,
		OUTPUT_DATA_BUS                                    => OUTPUT_DATA_BUS,
		OUTPUT_ADDRESS_BUS                                 => OUTPUT_ADDRESS_BUS,
		OUTPUT_FIFO_WRITE_ENABLE                           => OUTPUT_FIFO_WRITE_ENABLE,
		START_BUILDING_A_PACKET                            => internal_START_BUILDING_A_PACKET,
		THIS_PACKET_IS_A_QUARTER_EVENT_HEADER              => internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER_PACKET,
		THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER              => internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER_PACKET,
		THIS_PACKET_IS_QUARTER_EVENT_MEAT                  => internal_THIS_PACKET_IS_A_QUARTER_EVENT_MEAT_PACKET,
		PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET => internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET,
		PACKET_BUILDER_IS_BUILDING_A_PACKET                => internal_PACKET_BUILDER_IS_BUILDING_A_PACKET,
		PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET           => internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET,
		EVENT_NUMBER                                       => internal_EVENT_NUMBER,
		PACKET_NUMBER                                      => internal_PACKET_NUMBER,
		INPUT_BASE_ADDRESS                                 => internal_INPUT_BASE_ADDRESS,
		OUTPUT_BASE_ADDRESS                                => internal_OUTPUT_BASE_ADDRESS
	);
	internal_CLOCK <= CLOCK;
	internal_RESET <= RESET;
	DONE_BUILDING_A_QUARTER_EVENT <= internal_DONE_BUILDING_A_QUARTER_EVENT;
	process (internal_CLOCK, internal_RESET)
		variable current_packet_number : integer range 0 to 150 := 0;
	begin
		if (internal_RESET = '1') then
			quarter_event_builder_state <= IDLE;
			internal_START_BUILDING_A_PACKET                      <= '0';
			internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER_PACKET <= '0';
			internal_THIS_PACKET_IS_A_QUARTER_EVENT_MEAT_PACKET   <= '0';
			internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER_PACKET <= '0';
			internal_EVENT_NUMBER        <= (others => '0');
			internal_PACKET_NUMBER       <= (others => '0');
			current_packet_number := 0;
			internal_INPUT_BASE_ADDRESS  <= (others => '0');
			internal_OUTPUT_BASE_ADDRESS <= (others => '0');
			internal_DONE_BUILDING_A_QUARTER_EVENT <= '0';
		elsif rising_edge(internal_CLOCK) then
			-- putting these here causes a one cycle delay:
			internal_START_BUILDING_A_QUARTER_EVENT <= START_BUILDING_A_QUARTER_EVENT;
			internal_COMMAND_ARGUMENT               <= COMMAND_ARGUMENT;
			internal_EVENT_NUMBER_SET               <= EVENT_NUMBER_SET;
			case quarter_event_builder_state is
				when IDLE =>
					if (internal_EVENT_NUMBER_SET = '1') then
						internal_EVENT_NUMBER <= internal_COMMAND_ARGUMENT;
					elsif (internal_START_BUILDING_A_QUARTER_EVENT = '1') then
						internal_INPUT_BASE_ADDRESS  <= (others => '0');
						internal_OUTPUT_BASE_ADDRESS <= (others => '0');
						internal_DONE_BUILDING_A_QUARTER_EVENT <= '0';
						current_packet_number := 0;
						internal_EVENT_NUMBER  <= std_logic_vector(unsigned(internal_EVENT_NUMBER) + 1);
						internal_PACKET_NUMBER <= (others => '0');
						quarter_event_builder_state <= BUILD_A_QUARTER_EVENT_HEADER_PACKET;
					end if;
				when BUILD_A_QUARTER_EVENT_HEADER_PACKET =>
					if ((internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET or internal_PACKET_BUILDER_IS_BUILDING_A_PACKET or internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET) = '0') then
						internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER_PACKET <= '1';
						internal_START_BUILDING_A_PACKET                      <= '1';
					else
						-- de-assert control signals and then wait here for a while until it's done...
						internal_THIS_PACKET_IS_A_QUARTER_EVENT_HEADER_PACKET <= '0';
						internal_START_BUILDING_A_PACKET                      <= '0';
						if (internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET = '1') then
							quarter_event_builder_state <= DONE_BUILDING_A_QUARTER_EVENT_HEADER_PACKET;
						end if;
					end if;
				when DONE_BUILDING_A_QUARTER_EVENT_HEADER_PACKET =>
					if (internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET = '0') then
						current_packet_number := current_packet_number + 1;
						internal_PACKET_NUMBER <= std_logic_vector(to_unsigned(current_packet_number, WIDTH_OF_PACKET_NUMBER));
						quarter_event_builder_state <= BUILD_A_QUARTER_EVENT_MEAT_PACKET;
					end if;
				when BUILD_A_QUARTER_EVENT_MEAT_PACKET =>
					if ((internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET or internal_PACKET_BUILDER_IS_BUILDING_A_PACKET or internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET) = '0') then
						internal_THIS_PACKET_IS_A_QUARTER_EVENT_MEAT_PACKET   <= '1';
						internal_START_BUILDING_A_PACKET                      <= '1';
					else
						-- de-assert control signals and then wait here for a while until it's done...
						internal_THIS_PACKET_IS_A_QUARTER_EVENT_MEAT_PACKET   <= '0';
						internal_START_BUILDING_A_PACKET                      <= '0';
						if (internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET = '1') then
							quarter_event_builder_state <= DONE_BUILDING_A_QUARTER_EVENT_MEAT_PACKET;
						end if;
					end if;
				when DONE_BUILDING_A_QUARTER_EVENT_MEAT_PACKET =>
					if (internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET = '0') then
						current_packet_number := current_packet_number + 1;
						internal_PACKET_NUMBER <= std_logic_vector(to_unsigned(current_packet_number, WIDTH_OF_PACKET_NUMBER));
						if (current_packet_number < NUMBER_OF_PACKETS_IN_AN_EVENT - 1) then
							quarter_event_builder_state <= BUILD_A_QUARTER_EVENT_MEAT_PACKET;
						else
							quarter_event_builder_state <= BUILD_A_QUARTER_EVENT_FOOTER_PACKET;
						end if;
					end if;
				when BUILD_A_QUARTER_EVENT_FOOTER_PACKET =>
					if ((internal_PACKET_BUILDER_IS_GOING_TO_START_BUILDING_A_PACKET or internal_PACKET_BUILDER_IS_BUILDING_A_PACKET or internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET) = '0') then
						internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER_PACKET <= '1';
						internal_START_BUILDING_A_PACKET                      <= '1';
					else
						-- de-assert control signals and then wait here for a while until it's done...
						internal_THIS_PACKET_IS_A_QUARTER_EVENT_FOOTER_PACKET <= '0';
						internal_START_BUILDING_A_PACKET                      <= '0';
						if (internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET = '1') then
							quarter_event_builder_state <= DONE_BUILDING_A_QUARTER_EVENT_FOOTER_PACKET;
						end if;
					end if;
				when DONE_BUILDING_A_QUARTER_EVENT_FOOTER_PACKET =>
					if (internal_PACKET_BUILDER_IS_DONE_BUILDING_A_PACKET = '0') then
--						current_packet_number := current_packet_number + 1;
--						internal_PACKET_NUMBER <= std_logic_vector(to_unsigned(current_packet_number, WIDTH_OF_PACKET_NUMBER));
						quarter_event_builder_state <= ALMOST_DONE_BUILDING_QUARTER_EVENT;
					end if;
				when ALMOST_DONE_BUILDING_QUARTER_EVENT =>
					internal_DONE_BUILDING_A_QUARTER_EVENT <= '1';
					if (internal_START_BUILDING_A_QUARTER_EVENT = '0') then
						quarter_event_builder_state <= DONE_BUILDING_QUARTER_EVENT;						
					end if;
				when DONE_BUILDING_QUARTER_EVENT =>
					quarter_event_builder_state <= IDLE;
				when others =>
					quarter_event_builder_state <= IDLE;
			end case;
		end if;
	end process;
end architecture quarter_event_builder_architecture;
-----------------------------------------------------------------------------
entity quarter_event_builder_testbench is
	generic (
		NUMBER_OF_INPUT_BLOCK_RAMS                  : integer :=  2;
		WIDTH_OF_INPUT_ADDRESS_BUS                  : integer := 13; -- (128 channels/qevent * 64 samples/window/channel * 4 windows = 32768 samples/qevent) / 2^NUMBER_OF_INPUT_BLOCK_RAMS
		WIDTH_OF_INPUT_DATA_BUS                     : integer := 16;
		WIDTH_OF_OUTPUT_ADDRESS_BUS                 : integer := 17; -- 132 packets/qevent * 140 words/packet = 73920 words/qevent
		WIDTH_OF_OUTPUT_DATA_BUS                    : integer := 32
	);
end quarter_event_builder_testbench;
-----------------------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.all;
architecture quarter_event_builder_testbench_architecture of quarter_event_builder_testbench is
	component quarter_event_builder
	generic (
		CURRENT_PROTOCOL_FREEZE_DATE : std_logic_vector(31 downto 0) := x"20110902"
	);
	port (
		RESET                              : in    std_logic;
		CLOCK                              : in    std_logic;
		INPUT_DATA_BUS                     : in    std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1     downto 0);
		INPUT_ADDRESS_BUS                  :   out std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
		INPUT_BLOCK_RAM_ADDRESS            :   out std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC : in    std_logic_vector(8 downto 0);
		OUTPUT_DATA_BUS                    :   out std_logic_vector(WIDTH_OF_OUTPUT_DATA_BUS-1    downto 0);
		OUTPUT_ADDRESS_BUS                 :   out std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0);
		OUTPUT_FIFO_WRITE_ENABLE           :   out std_logic;
		START_BUILDING_A_QUARTER_EVENT     : in    std_logic;
		DONE_BUILDING_A_QUARTER_EVENT      :   out std_logic
	);
	end component;
	component pseudo_data_block_ram
	port (
		CLOCK                   : in    std_logic;
		ADDRESS_IN              : in    std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1 downto 0);
		INPUT_BLOCK_RAM_ADDRESS : in    std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
		DATA_OUT                :   out std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1 downto 0)
	);
	end component;
	signal internal_RESET                          : std_logic := '0';
	signal internal_CLOCK                          : std_logic := '0';
	signal internal_DOUBLE_CLOCK                   : std_logic := '0';
--	signal internal_inverted_CLOCK                 : std_logic := '1';
	signal internal_INPUT_DATA_BUS                 : std_logic_vector(WIDTH_OF_INPUT_DATA_BUS-1     downto 0) := x"6767";
	signal internal_INPUT_ADDRESS_BUS              : std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0);
	signal internal_OUTPUT_DATA_BUS                : std_logic_vector(WIDTH_OF_OUTPUT_DATA_BUS-1    downto 0);
	signal internal_FIFO_OUTPUT_DATA_BUS           : std_logic_vector(WIDTH_OF_OUTPUT_DATA_BUS-1    downto 0);
	signal internal_OUTPUT_ADDRESS_BUS             : std_logic_vector(WIDTH_OF_OUTPUT_ADDRESS_BUS-1 downto 0);
	signal internal_OUTPUT_FIFO_WRITE_ENABLE       : std_logic;
	signal internal_START_BUILDING_A_QUARTER_EVENT : std_logic := '0';
	signal internal_DONE_BUILDING_A_QUARTER_EVENT  : std_logic := '0';
	signal internal_INPUT_BLOCK_RAM_ADDRESS        : std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
--	signal fake_input_address_bus                  : std_logic_vector(WIDTH_OF_INPUT_ADDRESS_BUS-1  downto 0) := (others => '0');
--	signal internal_FAKE_ASIC_DATA    : std_logic_vector(11 downto 0) := x"321";
--	signal internal_FAKE_ASIC_ADDRESS : std_logic_vector(11 downto 0) := (others => '0');
--	signal db : std_logic_vector(15 downto 0) := x"0321";
	signal fifo_is_empty : std_logic;
	signal fifo_read_enable : std_logic := '0';
	signal fifo_should_be_read_now : std_logic := '0';
	signal internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC : std_logic_vector(8 downto 0) := "0" & x"64";
begin
	QEB : quarter_event_builder port map (
		RESET                              => internal_RESET,
		CLOCK                              => internal_CLOCK,
		INPUT_DATA_BUS                     => internal_INPUT_DATA_BUS,
		INPUT_ADDRESS_BUS                  => internal_INPUT_ADDRESS_BUS,
		INPUT_BLOCK_RAM_ADDRESS            => internal_INPUT_BLOCK_RAM_ADDRESS,
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC => internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC,
		OUTPUT_DATA_BUS                    => internal_OUTPUT_DATA_BUS,
		OUTPUT_ADDRESS_BUS                 => internal_OUTPUT_ADDRESS_BUS,
		OUTPUT_FIFO_WRITE_ENABLE           => internal_OUTPUT_FIFO_WRITE_ENABLE,
		START_BUILDING_A_QUARTER_EVENT     => internal_START_BUILDING_A_QUARTER_EVENT,
		DONE_BUILDING_A_QUARTER_EVENT      => internal_DONE_BUILDING_A_QUARTER_EVENT
	);
	PDBR : pseudo_data_block_ram port map (
		CLOCK                   => internal_CLOCK,
		ADDRESS_IN              => internal_INPUT_ADDRESS_BUS,
		INPUT_BLOCK_RAM_ADDRESS => internal_INPUT_BLOCK_RAM_ADDRESS,
		DATA_OUT                => internal_INPUT_DATA_BUS
	);
--	FAKE_ASIC_RAM_BLOCK : entity work.MULTI_WINDOW_RAM_BLOCK port map (
--		clka  => internal_CLOCK,
--		ena   => '1',
--		wea   => std_logic_vector(to_unsigned(1, 1)),
--		addra => internal_FAKE_ASIC_ADDRESS,
--		dina  => db,
--		clkb  => internal_CLOCK,
--		enb   => '1',
--		addrb => internal_INPUT_ADDRESS_BUS(11 downto 0),
--		doutb => internal_INPUT_DATA_BUS
--	);
--	db <= x"0" & internal_FAKE_ASIC_DATA;
	QUARTER_EVENT_FIFO : entity work.quarter_event_fifo port map (
		rst    => internal_RESET,
		wr_clk => internal_CLOCK,
		rd_clk => internal_CLOCK,
		din    => internal_OUTPUT_DATA_BUS,
		wr_en  => internal_OUTPUT_FIFO_WRITE_ENABLE,
		rd_en  => fifo_read_enable,
		dout   => internal_FIFO_OUTPUT_DATA_BUS,
		full   => open,
		empty  => fifo_is_empty,
		valid  => open
	);
--	internal_inverted_CLOCK <= not internal_CLOCK;
	process
		constant quarter_clock_period : time := 2.5 ns;
		variable clock_counter     : integer range 0 to 100000000 := 0;
	begin
		internal_CLOCK <= '0';
		internal_DOUBLE_CLOCK <= '1';
		wait for quarter_clock_period;
		internal_DOUBLE_CLOCK <= '0';
		wait for quarter_clock_period;
		internal_CLOCK <= '1';
		internal_DOUBLE_CLOCK <= '1';
		wait for quarter_clock_period;
		internal_DOUBLE_CLOCK <= '0';
		wait for quarter_clock_period;
		clock_counter := clock_counter + 1;
		-----------------------------------------------------------------------------
		if (clock_counter < 3 or clock_counter > 5) then
			internal_RESET <= '0';
		else
			internal_RESET <= '1';
		end if;
		if (clock_counter < 80 or clock_counter > 86) then
			internal_START_BUILDING_A_QUARTER_EVENT <= '0';
		else
			internal_START_BUILDING_A_QUARTER_EVENT <= '1';
		end if;
-----------------------------------------------------------------------------
	end process;
--		internal_CLOCK <= '0', '1' after clock_period, '0' after 20ns, '1' after 30ns, '0' after 40ns, '1' after 50ns;
-----------------------------------------------------------------------------
	fifo_read_enable <= fifo_should_be_read_now and (not fifo_is_empty);
	process (internal_CLOCK)
--		variable                           junk_address : integer range 0 to 4096 := 0;
--		variable least_significant_part_of_junk_address : integer range 0 to 4096 := 0;
	begin
		if (internal_RESET = '1') then
			fifo_should_be_read_now <= '0';
		elsif rising_edge(internal_CLOCK) then
			if (internal_DONE_BUILDING_A_QUARTER_EVENT = '1') then
				fifo_should_be_read_now <= '1';
			end if;
			if (fifo_is_empty = '1') then
				fifo_should_be_read_now <= '0';
			end if;
--			internal_FAKE_ASIC_ADDRESS <= std_logic_vector(to_unsigned(junk_address, 12));
--			least_significant_part_of_junk_address := to_integer(to_unsigned(junk_address, 4));

--			junk_address := junk_address + 1;
		end if;
	end process;
end architecture quarter_event_builder_testbench_architecture;
-----------------------------------------------------------------------------
