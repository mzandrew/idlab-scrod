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
	component s6_vio
	port (
		control     : inout std_logic_vector(35 downto 0);
		clk         : in    std_logic;
		sync_in     : in    std_logic_vector(255 downto 0);
		sync_out    :   out std_logic_vector(255 downto 0)
	);
	end component;
-- chipscope signals --------------------------------------------------------
	signal icon_to_vio_i         : std_logic_vector(35 downto 0);
	signal icon_to_ila_i         : std_logic_vector(35 downto 0);
	signal chipscope_vio_in      : std_logic_vector(255 downto 0);
	signal chipscope_vio_out     : std_logic_vector(255 downto 0);
	signal chipscope_ila_data    : std_logic_vector(255 downto 0) := (others => '0');
	signal chipscope_ila_trigger : std_logic_vector(255 downto 0) := (others => '0');
-----------------------------------------------------------------------------
	signal internal_clock_from_remote_source : std_logic;
	signal internal_clock_250MHz             : std_logic;
	signal internal_COUNTER : std_logic_vector(31 downto 0);
-----------------------------------------------------------------------------
	signal clock_1MHz : std_logic;
	signal clock_1kHz : std_logic;
-----------------------------------------------------------------------------
-- trigger signals:
	signal external_trigger_1_from_monitor_header : std_logic;
	signal external_trigger_2_from_LVDS           : std_logic;
	signal external_encoded_trigger_from_LVDS     : std_logic;
	signal raw_500Hz_fake_trigger : std_logic := '0';
	signal raw_100Hz_fake_trigger : std_logic := '0';
	signal raw_5Hz_fake_trigger   : std_logic := '0';
	signal external_triggers_ORed_together : std_logic;
	signal gated_trigger : std_logic;
	signal external_trigger_disable : std_logic := '0';
	signal internal_trigger : std_logic;
	signal gated_fill_inactive : std_logic;
	signal trigger_a_digitization_and_readout_event : std_logic;
	signal pulsed_trigger : std_logic := '0';
	signal trigger_acknowledge : std_logic;
-----------------------------------------------------------------------------
	signal transmit_disable : std_logic := '0';
	signal transmit_always : std_logic;
	signal spill_active : std_logic;
	signal fill_active  : std_logic;
	signal fake_spill_structure_enable : std_logic;
-----------------------------------------------------------------------------
	signal internal_clock_for_state_machine : std_logic;
	signal clock_select : std_logic := '0'; -- '0' = local; '1' = remote
	signal global_reset : std_logic := '1';
	signal request_a_global_reset : std_logic := '0';
-----------------------------------------------------------------------------
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
-----------------------------------------------------------------------------
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
	process(clock_1kHz, global_reset)
		variable counter_1_kHz    : integer range 0 to 10 := 0;
		variable counter_200_Hz   : integer range 0 to 10 := 0;
		variable counter_100_Hz   : integer range 0 to 10 := 0;
		variable counter_10_Hz    : integer range 0 to 10 := 0;
		variable counter_1_Hz     : integer range 0 to 3600 := 0;
		variable spill_counter         : integer range 0 to 60 := 1;
		constant spill_counter_maximum : integer range 0 to 60 := 2;
		variable fill_counter          : integer range 0 to 60 := 1;
		constant fill_counter_maximum  : integer range 0 to 60 := 4;
	begin
		if (global_reset = '1') then
			spill_active <= '1';
			fill_active  <= '0';
			counter_1_kHz   := 0;
			counter_200_Hz  := 0;
			counter_100_Hz  := 0;
			counter_10_Hz   := 0;
			counter_1_Hz    := 0;
			spill_counter   := 1;
			fill_counter    := 1;
			raw_5Hz_fake_trigger   <= '0';
			raw_100Hz_fake_trigger <= '0';
			raw_500Hz_fake_trigger <= '0';
		elsif rising_edge(clock_1kHz) then
			-- evaluated once per millisecond
			counter_1_kHz := counter_1_kHz + 1;
			if (counter_1_kHz > 4) then
				-- evaluated 200 times per second
				counter_1_kHz := 0;
				counter_200_Hz := counter_200_Hz + 1;
				raw_100Hz_fake_trigger <= not raw_100Hz_fake_trigger;
			end if;
			if (counter_200_Hz > 1) then
				-- evaluated 100 times per second
				counter_200_Hz := 0;
				counter_100_Hz := counter_100_Hz + 1;
			end if;
			if (counter_100_Hz > 9) then
				-- evaluated 10 times per second
				counter_100_Hz := 0;
				counter_10_Hz := counter_10_Hz + 1;
				raw_5Hz_fake_trigger <= not raw_5Hz_fake_trigger;
			end if;
--				raw_25Hz_fake_trigger <= not raw_25Hz_fake_trigger;
			if (counter_10_Hz > 9) then
				-- evaluated once per second
--				if (fiber_link_is_up = '0') then
--					pulsed_fiber_link_is_down = '1';
--					request_an_aurora_reset = '1';
--				end if;
				counter_10_Hz := 0;
				counter_1_Hz := counter_1_Hz + 1;
--				stupid_counter <= std_logic_vector(unsigned(stupid_counter) + 1);
				if (spill_counter < spill_counter_maximum) then
					spill_counter := spill_counter + 1;
				else
					spill_active <= '0';
					fill_active  <= '1';
					if (fill_counter < fill_counter_maximum) then
						fill_counter := fill_counter + 1;
					else
						spill_active <= '1';
						fill_active  <= '0';
						spill_counter := 1;
						fill_counter  := 1;
					end if;
				end if;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
	process(external_trigger_disable)
	begin
		if (external_trigger_disable = '0') then
			gated_trigger <= external_triggers_ORed_together;
		else
			gated_trigger <= internal_trigger;
		end if;
	end process;
-----------------------------------------------------------------------------
	process (trigger_a_digitization_and_readout_event, transmit_always, trigger_acknowledge)
	begin
		if (trigger_acknowledge = '1') then
			pulsed_trigger <= '0';
		elsif (transmit_always = '1') then
			pulsed_trigger <= '1';
		elsif rising_edge(trigger_a_digitization_and_readout_event) then
			pulsed_trigger <= '1';
		end if;
	end process;
-----------------------------------------------------------------------------
	process (clock_1MHz, global_reset)
		variable trigger_acknowledge_counter : integer range 0 to 100 := 0;
	begin
		if (global_reset = '1') then
			trigger_acknowledge <= '0';
			trigger_acknowledge_counter := 0;
		elsif rising_edge(clock_1MHz) then
			if (internal_DONE_BUILDING_A_QUARTER_EVENT = '1') then
				if (trigger_acknowledge_counter < 30) then
					trigger_acknowledge <= '1';
					trigger_acknowledge_counter := trigger_acknowledge_counter + 1;
				else
					trigger_acknowledge <= '0';
				end if;
			else
				trigger_acknowledge <= '0';
				trigger_acknowledge_counter := 0;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
--	internal_acknowledge_start_event_transfer <= '0';
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
		chipscope_vio_in                                        => chipscope_vio_in,
		chipscope_vio_out                                       => open,
		TRIGGER                                                 => pulsed_trigger,
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

	internal_trigger <= raw_5Hz_fake_trigger;
--	external_triggers_ORed_together <= external_trigger_1_from_monitor_header or external_trigger_2_from_LVDS;
--	external_triggers_ORed_together <= external_trigger_2_from_LVDS;
	external_triggers_ORed_together <= external_trigger_1_from_monitor_header;
	gated_fill_inactive <= fake_spill_structure_enable nand fill_active;
	trigger_a_digitization_and_readout_event <= gated_fill_inactive and gated_trigger;
--	internal_PACKET_GENERATOR_ENABLE(1) <= '1';--trigger_a_digitization_and_readout_event or transmit_always;
--	internal_PACKET_GENERATOR_ENABLE(0) <= not transmit_disable;
--	trigger_a_digitization_and_readout_event
--	pulsed_trigger <= trigger_a_digitization_and_readout_event or transmit_always;
-----------------------------------------------------------------------------
	LEDS(3 downto 0) <= internal_Aurora_RocketIO_GTP_MGT_101_status_LEDs;

	LEDS(4) <= global_reset;
	LEDS(5) <= '0';
	LEDS(6) <= '0';
	LEDS(7) <= '0';

	LEDS(8)  <= '0';--raw_5Hz_fake_trigger;
	LEDS(9)  <= external_trigger_1_from_monitor_header;
--	LEDS(10) <= external_triggers_ORed_together;
	LEDS(10) <= pulsed_trigger;
	LEDS(11) <= gated_trigger;

--	LEDS(15 downto 12) <= internal_number_of_sent_events(3 downto 0);
	LEDS(15 downto 12) <= (others => '0');
-----------------------------------------------------------------------------
	MONITOR_HEADER_OUTPUT(0) <= '0';--Aurora_lane0_transmit_source_ready_active_low;
	MONITOR_HEADER_OUTPUT(1) <= clock_1MHz;
	MONITOR_HEADER_OUTPUT(2) <= clock_1kHz;
	MONITOR_HEADER_OUTPUT(10 downto 3) <= (others => '0');
	
	MONITOR_HEADER_OUTPUT(11) <= external_trigger_2_from_LVDS;

	MONITOR_HEADER_OUTPUT(12) <= pulsed_trigger;
	MONITOR_HEADER_OUTPUT(13) <= raw_100Hz_fake_trigger;
	MONITOR_HEADER_OUTPUT(14) <= raw_5Hz_fake_trigger;
	external_trigger_1_from_monitor_header <= MONITOR_HEADER_INPUT(15);
-----------------------------------------------------------------------------

	IBUFGDS_i_local  : IBUFGDS port map (I => board_clock_250MHz_P, IB => board_clock_250MHz_N, O => internal_clock_250MHz);
	IBUFGDS_i_remote : IBUFGDS port map (I => REMOTE_CLOCK_P, IB => REMOTE_CLOCK_N, O => internal_clock_from_remote_source);
	internal_clock_for_state_machine <= internal_clock_250MHz;

	chipscope1 : if USE_CHIPSCOPE = 1 generate
		chipscope_ila_data(234 downto 0) <= (others => '0');
		chipscope_ila_data(247 downto 235) <= internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS;
		chipscope_ila_data(249 downto 248) <= internal_INPUT_BLOCK_RAM_ADDRESS;
		chipscope_ila_data(255 downto 250) <= (others => '0');
		chipscope_ila_trigger(255 downto 0) <= (others => '0');

		chipscope_vio_out(0)  <= fiber_link_is_up;
		chipscope_vio_out(1)  <= '0';
		chipscope_vio_out(2)  <= pulsed_trigger;
		chipscope_vio_out(4 downto 3) <= (others => '0');
		chipscope_vio_out(5)  <= trigger_acknowledge;
		chipscope_vio_out(9 downto 6) <= (others => '0');
		chipscope_vio_out(10) <= spill_active;
		chipscope_vio_out(255 downto 11) <= (others => '0');

		transmit_always                                    <= chipscope_vio_in(1);
		transmit_disable                                   <= chipscope_vio_in(2);
		external_trigger_disable                           <= chipscope_vio_in(36);
		fake_spill_structure_enable                        <= chipscope_vio_in(37);
		request_a_global_reset                             <= chipscope_vio_in(38);
		request_a_fiber_link_reset                         <= chipscope_vio_in(39);
		should_not_automatically_try_to_keep_fiber_link_up <= chipscope_vio_in(40);

		chipscope_icon : entity work.s6_icon
		port map (
			control0 => icon_to_vio_i,
			control1 => icon_to_ila_i
		);

		chipscope_vio : s6_vio
		port map (
			control   => icon_to_vio_i,
			clk       => internal_Aurora_78MHz_clock,
			sync_in   => chipscope_vio_out,
			sync_out  => chipscope_vio_in
		);

		chipscope_ila : entity work.s6_ila
		port map (
			control  => icon_to_ila_i,
			clk      => internal_Aurora_78MHz_clock,
			data     => chipscope_ila_data,
			trig0    => chipscope_ila_trigger,
			trig_out => open
		);
	end generate chipscope1;

	no_chipscope1 : if USE_CHIPSCOPE = 0 generate
		chipscope_vio_in  <= (others=>'0');
	end generate no_chipscope1;

end PDBF;
