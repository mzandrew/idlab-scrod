-- 2011-06 Xilinx coregen
-- 2011-06 kurtis
-- 2011-07 to 2011-09 mza
---------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity pseudo_data_by_fiber is
	generic(
		CURRENT_PROTOCOL_FREEZE_DATE                   : std_logic_vector(31 downto 0) := x"20110910";
		NUMBER_OF_INPUT_BLOCK_RAMS                     : integer :=  2;
		WIDTH_OF_ASIC_DATA_BLOCKRAM_DATA_BUS           : integer := 16;
		WIDTH_OF_ASIC_DATA_BLOCKRAM_ADDRESS_BUS        : integer := 13;
		USE_CHIPSCOPE                                  : integer := 1
	);
	port (
		-- fiber optic dual clock input
		Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_P             : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_N             : in    std_logic;
		-- fiber optic transceiver #101 lane 0 I/O
		Aurora_RocketIO_GTP_MGT_101_lane0_Receive_P             : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_lane0_Receive_N             : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_P            :   out std_logic;
		Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_N            :   out std_logic;
		FIBER_TRANSCEIVER_0_LASER_FAULT_DETECTED_IN_TRANSMITTER : in    std_logic;
		FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER : in    std_logic;
 		FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT  : in    std_logic;
		FIBER_TRANSCEIVER_0_DISABLE_MODULE                      :   out std_logic;
		-- fiber optic transceiver #101 lane 1 I/O
		FIBER_TRANSCEIVER_1_DISABLE_MODULE                      :   out std_logic;
		-----------------------------------------------------------------------------
		-- remote trigger, revolution pulse and distributed clock
		REMOTE_SIMPLE_TRIGGER_P    : in    std_logic;
		REMOTE_SIMPLE_TRIGGER_N    : in    std_logic;
		REMOTE_ENCODED_TRIGGER_P   : in    std_logic;
		REMOTE_ENCODED_TRIGGER_N   : in    std_logic;
		REMOTE_CLOCK_P             : in    std_logic;
		REMOTE_CLOCK_N             : in    std_logic;
		-- other I/O
		board_clock_250MHz_P	: in    std_logic;
		board_clock_250MHz_N	: in    std_logic;
		LEDS                 :   out std_logic_vector(15 downto 0);
		MONITOR_HEADER_OUTPUT :   out std_logic_vector(14 downto 0);
		MONITOR_HEADER_INPUT  : in    std_logic_vector(15 downto 15)
	);
end pseudo_data_by_fiber;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture PDBF of pseudo_data_by_fiber is
	signal global_reset : std_logic := '1';
	signal request_a_global_reset : std_logic := '0';
-- clocks -------------------------------------------------------------------
	signal internal_clock_from_remote_source : std_logic;
	signal internal_clock_250MHz             : std_logic;
	signal internal_COUNTER : std_logic_vector(31 downto 0);
	signal clock_1MHz : std_logic;
	signal clock_1kHz : std_logic;
	signal internal_clock_for_state_machine : std_logic;
	signal clock_select : std_logic := '0'; -- '0' = local; '1' = remote
-- chipscope signals --------------------------------------------------------
	signal chipscope_vio_buttons : std_logic_vector(255 downto 0);
	signal chipscope_vio_display : std_logic_vector(255 downto 0);
	signal chipscope_ila_data    : std_logic_vector(255 downto 0) := (others => '0');
	signal chipscope_ila_trigger : std_logic_vector(255 downto 0) := (others => '0');
	signal fiber_readout_chipscope_vio_buttons     : std_logic_vector(255 downto 0) := (others => '0');
	signal fiber_readout_chipscope_vio_display     : std_logic_vector(255 downto 0) := (others => '0');
	signal fake_button : std_logic := '1';
-- trigger signals ----------------------------------------------------------
	signal external_trigger_1_from_monitor_header   : std_logic;
	signal external_trigger_2_from_LVDS             : std_logic;
	signal external_encoded_trigger_from_LVDS       : std_logic;
	signal external_trigger_disable                 : std_logic := '0';
	signal internal_TRIGGER                         : std_logic := '0';
	signal fake_spill_structure_enable              : std_logic;
	signal spill_active                             : std_logic;
	signal raw_5Hz_fake_trigger                     : std_logic := '0';
-- aurora/fiber signals -----------------------------------------------------
	signal transmit_disable : std_logic := '0';
	signal transmit_always : std_logic;
	signal request_a_fiber_link_reset                         : std_logic;
	signal should_not_automatically_try_to_keep_fiber_link_up : std_logic;
	signal fiber_link_is_up                                   : std_logic;
	signal Aurora_data_link_reset                             : std_logic;
	signal internal_Aurora_78MHz_clock                                 : std_logic;
	signal internal_Aurora_RocketIO_GTP_MGT_101_status_LEDs            : std_logic_vector(3 downto 0);
	signal internal_DONE_BUILDING_A_QUARTER_EVENT      : std_logic;
-----------------------------------------------------------------------------
	signal internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC : std_logic_vector(8 downto 0) := "1" & x"f0";
	signal internal_INPUT_BLOCK_RAM_ADDRESS            : std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
	signal internal_ASIC_DATA_BLOCKRAM_DATA_BUS        : std_logic_vector(WIDTH_OF_ASIC_DATA_BLOCKRAM_DATA_BUS-1        downto 0);
	signal internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS     : std_logic_vector(WIDTH_OF_ASIC_DATA_BLOCKRAM_ADDRESS_BUS-1     downto 0);
begin
	process(internal_clock_for_state_machine, request_a_global_reset)
		variable internal_COUNTER  : integer range 0 to 250000000 := 0;
	begin
		if (rising_edge(internal_clock_for_state_machine)) then
			if (request_a_global_reset = '1') then
				internal_COUNTER := 0;
				global_reset <= '1';
			elsif (internal_COUNTER < 2500000) then
				internal_COUNTER := internal_COUNTER + 1;
			else
				global_reset <= '0';
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
	process(internal_clock_for_state_machine, global_reset)
		variable counter_250_MHz  : integer range 0 to 250 := 0;
	begin
		if (global_reset = '1') then
			counter_250_MHz := 0;
		elsif rising_edge(internal_clock_for_state_machine) then
			counter_250_MHz := counter_250_MHz + 1;
			clock_1MHz <= '0';
			if (counter_250_MHz > 124) then
				clock_1MHz <= '1';
			end if;
			if (counter_250_MHz > 249) then -- is 1 to 250 at this part of the loop
				counter_250_MHz := 0;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
	process(clock_1MHz, global_reset)
		variable counter_1_MHz    : integer range 0 to 10 := 0;
		variable counter_100_kHz  : integer range 0 to 10 := 0;
		variable counter_10_kHz   : integer range 0 to 10 := 0;
--		variable counter_2_kHz    : integer range 0 to 10 := 0;
	begin
		if (global_reset = '1') then
			counter_1_MHz   := 0;
			counter_100_kHz := 0;
			counter_10_kHz  := 0;
--			counter_2_kHz   := 0;
		elsif rising_edge(clock_1MHz) then
			-- evaluated once per microsecond
			counter_1_MHz := counter_1_MHz + 1;
			if (counter_1_MHz > 9) then
				-- evaluated 100,000 times per second
				counter_1_MHz := 0;
				counter_100_kHz := counter_100_kHz + 1;
			end if;
			if (counter_100_kHz > 9) then
				-- evaluated 10,000 times per second
				counter_100_kHz := 0;
				counter_10_kHz := counter_10_kHz + 1;
			end if;
			if (counter_10_kHz > 4) then
				-- evaluated 2,000 times per second
				counter_10_kHz := 0;
--				counter_2_kHz := counter_2_kHz + 1;
				clock_1kHz <= not clock_1kHz;
			end if;
--			if (counter_2_kHz > 2) then
				-- evaluated 1,000 times per second
--				counter_2_kHz := 0;
--				
--			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
	FR : entity work.fiber_readout
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE                => CURRENT_PROTOCOL_FREEZE_DATE,
		NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND => 1
	)
	port map (
		RESET                                                   => global_reset,
		Aurora_RocketIO_GTP_MGT_101_RESET                       => Aurora_data_link_reset,
		Aurora_RocketIO_GTP_MGT_101_initialization_clock        => internal_COUNTER(2),
		Aurora_RocketIO_GTP_MGT_101_reset_clock                 => clock_1kHz, -- make sure to update NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND if you change this
		Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_P             => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_P,
		Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_N             => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_N,
		Aurora_RocketIO_GTP_MGT_101_lane0_Receive_P             => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_P,
		Aurora_RocketIO_GTP_MGT_101_lane0_Receive_N             => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_N,
		Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_P            => Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_P,
		Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_N            => Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_N,
		FIBER_TRANSCEIVER_0_LASER_FAULT_DETECTED_IN_TRANSMITTER => FIBER_TRANSCEIVER_0_LASER_FAULT_DETECTED_IN_TRANSMITTER,
		FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER => FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER,
 		FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT  => FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT,
		FIBER_TRANSCEIVER_0_DISABLE_MODULE                      => FIBER_TRANSCEIVER_0_DISABLE_MODULE,
		FIBER_TRANSCEIVER_1_DISABLE_MODULE                      => FIBER_TRANSCEIVER_1_DISABLE_MODULE,
		Aurora_78MHz_clock                                      => internal_Aurora_78MHz_clock,
		should_not_automatically_try_to_keep_fiber_link_up      => should_not_automatically_try_to_keep_fiber_link_up,
		fiber_link_is_up                                        => fiber_link_is_up,
		Aurora_RocketIO_GTP_MGT_101_status_LEDs                 => internal_Aurora_RocketIO_GTP_MGT_101_status_LEDs,
		chipscope_ila                                           => open,
		chipscope_vio_display                                   => fiber_readout_chipscope_vio_display,
		chipscope_vio_buttons                                   => fiber_readout_chipscope_vio_buttons,
		TRIGGER                                                 => internal_TRIGGER,
		DONE_BUILDING_A_QUARTER_EVENT                           => internal_DONE_BUILDING_A_QUARTER_EVENT,
		INPUT_DATA_BUS                                          => internal_ASIC_DATA_BLOCKRAM_DATA_BUS,
		INPUT_ADDRESS_BUS                                       => internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS,
		INPUT_BLOCK_RAM_ADDRESS                                 => internal_INPUT_BLOCK_RAM_ADDRESS,
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC                      => internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC
	);
	PDBR : entity work.pseudo_data_block_ram
	port map (
		CLOCK                   => internal_Aurora_78MHz_clock,
		INPUT_BLOCK_RAM_ADDRESS => internal_INPUT_BLOCK_RAM_ADDRESS,
		ADDRESS_IN              => internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS,
		DATA_OUT                => internal_ASIC_DATA_BLOCKRAM_DATA_BUS
	);
--	Aurora_trigger_link : entity work.Aurora_RocketIO_GTP_MGT_101
	Aurora_data_link_reset <= global_reset or request_a_fiber_link_reset;
	internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC <= "1" & x"39";
-----------------------------------------------------------------------------
	LVDS_SIMPLE_TRIGGER  : IBUFDS port map (I => REMOTE_SIMPLE_TRIGGER_P,  IB => REMOTE_SIMPLE_TRIGGER_N,  O => external_trigger_2_from_LVDS);
	LVDS_ENCODED_TRIGGER : IBUFDS port map (I => REMOTE_ENCODED_TRIGGER_P, IB => REMOTE_ENCODED_TRIGGER_N, O => external_encoded_trigger_from_LVDS);
	T : entity work.trigger
	port map (
		RESET                                    => global_reset,
		CLOCK_1MHz                               => clock_1MHz,
		CLOCK_1kHz                               => clock_1kHz,
		external_trigger_from_monitor_header     => external_trigger_1_from_monitor_header,
		external_simple_trigger_from_LVDS        => external_trigger_2_from_LVDS,
		external_encoded_trigger_from_LVDS       => external_encoded_trigger_from_LVDS,
		transmit_always                          => transmit_always,
		fake_spill_structure_enable              => fake_spill_structure_enable,
		external_trigger_disable                 => external_trigger_disable,
		FAKE_SPILL_ACTIVE                        => spill_active,
		raw_fake_trigger                         => raw_5Hz_fake_trigger,
		TRIGGER                                  => internal_TRIGGER,
		TRIGGER_ACKNOWLEDGE                      => internal_DONE_BUILDING_A_QUARTER_EVENT
	);
-----------------------------------------------------------------------------
	LEDS(3 downto 0) <= internal_Aurora_RocketIO_GTP_MGT_101_status_LEDs;

	LEDS(4) <= global_reset;
	LEDS(5) <= '0';
	LEDS(6) <= '0';
	LEDS(7) <= fake_button;

	LEDS(8)  <= '0';--raw_5Hz_fake_trigger;
	LEDS(9)  <= external_trigger_1_from_monitor_header;
--	LEDS(10) <= external_triggers_ORed_together;
	LEDS(10) <= internal_TRIGGER;
--	LEDS(11) <= gated_trigger;

--	LEDS(15 downto 12) <= internal_number_of_sent_events(3 downto 0);
	LEDS(15 downto 11) <= (others => '0');
-----------------------------------------------------------------------------
	MONITOR_HEADER_OUTPUT(0) <= '0';--Aurora_lane0_transmit_source_ready_active_low;
	MONITOR_HEADER_OUTPUT(1) <= clock_1MHz;
	MONITOR_HEADER_OUTPUT(2) <= clock_1kHz;

	MONITOR_HEADER_OUTPUT(10 downto 3) <= (others => '0');
	MONITOR_HEADER_OUTPUT(11) <= external_trigger_2_from_LVDS;

	MONITOR_HEADER_OUTPUT(12) <= internal_TRIGGER;
	MONITOR_HEADER_OUTPUT(13) <= '0';
	MONITOR_HEADER_OUTPUT(14) <= raw_5Hz_fake_trigger;
	external_trigger_1_from_monitor_header <= MONITOR_HEADER_INPUT(15);
-----------------------------------------------------------------------------
	IBUFGDS_i_local  : IBUFGDS port map (I => board_clock_250MHz_P, IB => board_clock_250MHz_N, O => internal_clock_250MHz);
	IBUFGDS_i_remote : IBUFGDS port map (I => REMOTE_CLOCK_P, IB => REMOTE_CLOCK_N, O => internal_clock_from_remote_source);
	internal_clock_for_state_machine <= internal_clock_250MHz;
-----------------------------------------------------------------------------
	chipscope : entity work.chipscope
	port map (
		CLOCK       => internal_Aurora_78MHz_clock,
		ILA_DATA    => chipscope_ila_data,
		ILA_TRIGGER => chipscope_ila_trigger,
		VIO_DISPLAY => chipscope_vio_display,
		VIO_BUTTONS => chipscope_vio_buttons
	);

	chipscope_ila_data(234 downto 0)    <= (others => '0');
	chipscope_ila_data(247 downto 235)  <= internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS;
	chipscope_ila_data(249 downto 248)  <= internal_INPUT_BLOCK_RAM_ADDRESS;
	chipscope_ila_data(255 downto 250)  <= (others => '0');
	chipscope_ila_trigger(255 downto 0) <= (others => '0');

	chipscope_vio_display(0)             <= fiber_link_is_up;
	chipscope_vio_display(1)             <= internal_TRIGGER;
	chipscope_vio_display(2)             <= spill_active;
	chipscope_vio_display(255 downto 3)  <= (others => '0');

	request_a_global_reset                             <= chipscope_vio_buttons(0);
	request_a_fiber_link_reset                         <= chipscope_vio_buttons(1);
	transmit_disable                                   <= chipscope_vio_buttons(2);
	transmit_always                                    <= chipscope_vio_buttons(3);
	external_trigger_disable                           <= chipscope_vio_buttons(4);
	fake_spill_structure_enable                        <= chipscope_vio_buttons(5);
	should_not_automatically_try_to_keep_fiber_link_up <= chipscope_vio_buttons(6);
	fake_button                                        <= chipscope_vio_buttons(7);
-----------------------------------------------------------------------------
end PDBF;
