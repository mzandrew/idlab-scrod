-- 2011-09 mza
-----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity fiber_readout is
	generic (
		CURRENT_PROTOCOL_FREEZE_DATE                   : std_logic_vector(31 downto 0) := x"20111016";
		NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND    : integer :=  1; -- set to 83 for an 83kHz clock input
		WIDTH_OF_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS    : integer := 32;
		WIDTH_OF_QUARTER_EVENT_FIFO_OUTPUT_ADDRESS_BUS : integer := 17;
		WIDTH_OF_ASIC_DATA_BLOCKRAM_DATA_BUS           : integer := 16;
		WIDTH_OF_ASIC_DATA_BLOCKRAM_ADDRESS_BUS        : integer := 13;
		NUMBER_OF_INPUT_BLOCK_RAMS                     : integer :=  2;
		SIM_GTPRESET_SPEEDUP                           : integer :=  1  --Set to 1 to speed up sim reset
	);
	port (
		RESET                                                   : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_RESET                       : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_initialization_clock        : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_reset_clock                 : in    std_logic;
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
		Aurora_78MHz_clock                                      :   out std_logic;
		QEB_AND_PB_CLOCK                                        : in    std_logic;
		should_not_automatically_try_to_keep_fiber_link_up      : in    std_logic;
		fiber_link_is_up                                        :   out std_logic;
		-----------------------------------------------------------------------------
		Aurora_RocketIO_GTP_MGT_101_status_LEDs                 :   out std_logic_vector(3 downto 0);
		chipscope_ila                                           :   out std_logic_vector(255 downto 0);
		chipscope_vio_buttons                                   : in    std_logic_vector(255 downto 0);
		chipscope_vio_display                                   :   out std_logic_vector(255 downto 0);
		-----------------------------------------------------------------------------
		TRIGGER                                                 : in    std_logic;
		DONE_BUILDING_A_QUARTER_EVENT                           :   out std_logic;
		CURRENTLY_BUILDING_A_QUARTER_EVENT							  :   out std_logic;
		-- commamds -----------------------------------------------------------------
		REQUEST_A_GLOBAL_RESET                                  :   out std_logic;
		DESIRED_DAC_SETTINGS                                    :   out Board_Stack_Voltages;
		CURRENT_DAC_SETTINGS                                    : in    Board_Stack_Voltages;
		SOFT_TRIGGER_FROM_FIBER                                 :   out std_logic;
		RESET_SCALER_COUNTERS                                   :   out std_logic;
		CLEAR_TRIGGER_VETO                                      :   out std_logic;
		-----------------------------------------------------------------------------
		INPUT_DATA_BUS                                          : in    std_logic_vector(WIDTH_OF_ASIC_DATA_BLOCKRAM_DATA_BUS-1     downto 0);
		INPUT_ADDRESS_BUS                                       :   out std_logic_vector(WIDTH_OF_ASIC_DATA_BLOCKRAM_ADDRESS_BUS-1  downto 0);
		INPUT_BLOCK_RAM_ADDRESS                                 :   out std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
		ASIC_START_WINDOW                                       :   out std_logic_vector(8 downto 0);
		ASIC_END_WINDOW                                         :   out std_logic_vector(8 downto 0);
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC                      : in    std_logic_vector(8 downto 0);
		-----------------------------------------------------------------------------
		ASIC_SCALERS                                            : in    ASIC_Scalers_C_R_CH;
		ASIC_TRIGGER_STREAMS                                    : in    ASIC_Trigger_Stream_C_R_CH;
		-----------------------------------------------------------------------------
		TEMPERATURE_R1                                          : in    std_logic_vector(11 downto 0);
		FEEDBACK_WILKINSON_DAC_VALUE_C_R                        : in    Wilkinson_Rate_DAC_C_R;
		SAMPLING_RATE_FEEDBACK_GOAL                             :   out std_logic_vector(31 downto 0);
		WILKINSON_RATE_FEEDBACK_GOAL                            :   out std_logic_vector(31 downto 0);
		TRIGGER_WIDTH_FEEDBACK_GOAL                             :   out std_logic_vector(31 downto 0);
		SAMPLING_RATE_FEEDBACK_ENABLE                           :   out std_logic_vector(15 downto 0);
		WILKINSON_RATE_FEEDBACK_ENABLE                          :   out std_logic_vector(15 downto 0);
		TRIGGER_WIDTH_FEEDBACK_ENABLE                           :   out std_logic_vector(15 downto 0)
	);
end fiber_readout;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

architecture behavioral of fiber_readout is
	signal trigger_acknowledge : std_logic;
-----------------------------------------------------------------------------
--	signal should_not_automatically_try_to_keep_fiber_link_up : std_logic;
--	signal fiber_link_is_up                                   : std_logic;
	signal Aurora_data_link_reset                             : std_logic := '0';
	signal internal_Aurora_78MHz_clock                        : std_logic;
--	signal Aurora_RocketIO_GTP_MGT_101_status_LEDs            : std_logic_vector(3 downto 0);
-----------------------------------------------------------------------------
	signal internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC : std_logic_vector(8 downto 0) := "1" & x"f0";
	signal internal_INPUT_BLOCK_RAM_ADDRESS            : std_logic_vector(NUMBER_OF_INPUT_BLOCK_RAMS-1  downto 0);
	signal internal_ASIC_DATA_BLOCKRAM_DATA_BUS        : std_logic_vector(WIDTH_OF_ASIC_DATA_BLOCKRAM_DATA_BUS-1        downto 0);
	signal internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS     : std_logic_vector(WIDTH_OF_ASIC_DATA_BLOCKRAM_ADDRESS_BUS-1     downto 0);
	signal internal_QUARTER_EVENT_FIFO_INPUT_DATA_BUS  : std_logic_vector(WIDTH_OF_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS-1 downto 0);
	signal internal_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS : std_logic_vector(WIDTH_OF_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS-1 downto 0);
	signal internal_QUARTER_EVENT_FIFO_WRITE_ENABLE    : std_logic;
	signal internal_START_BUILDING_A_QUARTER_EVENT     : std_logic;
	signal internal_DONE_BUILDING_A_QUARTER_EVENT      : std_logic;
	signal internal_CURRENTLY_BUILDING_A_QUARTER_EVENT : std_logic;
	signal quarter_event_builder_enable : std_logic := '0';
	signal quarter_event_fifo_read_enable : std_logic := '0';
	signal quarter_event_fifo_is_empty    : std_logic;
	-- Stream TX Interface ------------------------------------------------------
	signal Aurora_lane0_transmit_data_bus                     : std_logic_vector(0 to 31);
	signal Aurora_lane0_transmit_source_ready_active_low      : std_logic;
	signal Aurora_lane0_transmit_destination_ready_active_low : std_logic;
	-- Stream RX Interface ------------------------------------------------------
	signal Aurora_lane0_receive_data_bus                      : std_logic_vector(0 to 31);
	signal Aurora_lane0_receive_source_ready_active_low       : std_logic;
	-----------------------------------------------------------------------------
	signal internal_UNKNOWN_COMMAND_RECEIVED_COUNTER      : std_logic_vector(7 downto 0);
	-- commands: ----------------------------------------------------------------
	signal internal_DESIRED_DAC_SETTINGS               : Board_Stack_Voltages;
	signal internal_COMMAND_ARGUMENT                   : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_EVENT_NUMBER_SET                   : std_logic                     := '0';
	signal internal_ASIC_START_WINDOW                  : std_logic_vector( 8 downto 0) := (others => '0');
	signal internal_ASIC_END_WINDOW                    : std_logic_vector( 8 downto 0) := (others => '1');
	signal internal_SAMPLING_RATE_FEEDBACK_ENABLE      : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_WILKINSON_RATE_FEEDBACK_ENABLE     : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_TRIGGER_WIDTH_FEEDBACK_ENABLE      : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_SAMPLING_RATE_FEEDBACK_GOAL        : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_WILKINSON_RATE_FEEDBACK_GOAL       : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_TRIGGER_WIDTH_FEEDBACK_GOAL        : std_logic_vector(31 downto 0) := (others => '0');
	-----------------------------------------------------------------------------
begin
	Aurora_data_link : entity work.Aurora_RocketIO_GTP_MGT_101
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE                => CURRENT_PROTOCOL_FREEZE_DATE,
		NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND => NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND
	)
	port map (
		RESET                                                   => Aurora_data_link_reset,
		Aurora_RocketIO_GTP_MGT_101_initialization_clock        => Aurora_RocketIO_GTP_MGT_101_initialization_clock,
		Aurora_RocketIO_GTP_MGT_101_reset_clock                 => Aurora_RocketIO_GTP_MGT_101_reset_clock,
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
		Aurora_lane0_transmit_data_bus                          => Aurora_lane0_transmit_data_bus,
		Aurora_lane0_transmit_source_ready_active_low           => Aurora_lane0_transmit_source_ready_active_low,
		Aurora_lane0_transmit_destination_ready_active_low      => Aurora_lane0_transmit_destination_ready_active_low,
		Aurora_lane0_receive_source_ready_active_low            => Aurora_lane0_receive_source_ready_active_low,
		Aurora_lane0_receive_data_bus                           => Aurora_lane0_receive_data_bus,
		should_not_automatically_try_to_keep_fiber_link_up      => should_not_automatically_try_to_keep_fiber_link_up,
		fiber_link_is_up                                        => fiber_link_is_up,
		-- commands -----------------------------------------------------------------
		COMMAND_ARGUMENT                                        => internal_COMMAND_ARGUMENT,
		EVENT_NUMBER_SET                                        => internal_EVENT_NUMBER_SET,
		REQUEST_A_GLOBAL_RESET                                  => REQUEST_A_GLOBAL_RESET,
		DESIRED_DAC_SETTINGS                                    => internal_DESIRED_DAC_SETTINGS,
		SOFT_TRIGGER_FROM_FIBER                                 => SOFT_TRIGGER_FROM_FIBER,
		RESET_SCALER_COUNTERS                                   => RESET_SCALER_COUNTERS,
		ASIC_START_WINDOW                                       => internal_ASIC_START_WINDOW,
		ASIC_END_WINDOW                                         => internal_ASIC_END_WINDOW,
		SAMPLING_RATE_FEEDBACK_GOAL                             => internal_SAMPLING_RATE_FEEDBACK_GOAL,
		WILKINSON_RATE_FEEDBACK_GOAL                            => internal_WILKINSON_RATE_FEEDBACK_GOAL,
		TRIGGER_WIDTH_FEEDBACK_GOAL                             => internal_TRIGGER_WIDTH_FEEDBACK_GOAL,
		SAMPLING_RATE_FEEDBACK_ENABLE                           => internal_SAMPLING_RATE_FEEDBACK_ENABLE,
		WILKINSON_RATE_FEEDBACK_ENABLE                          => internal_WILKINSON_RATE_FEEDBACK_ENABLE,
		TRIGGER_WIDTH_FEEDBACK_ENABLE                           => internal_TRIGGER_WIDTH_FEEDBACK_ENABLE,
		CLEAR_TRIGGER_VETO                                      => CLEAR_TRIGGER_VETO,
		-----------------------------------------------------------------------------
		FEEDBACK_WILKINSON_DAC_VALUE_C_R                        => FEEDBACK_WILKINSON_DAC_VALUE_C_R,
		UNKNOWN_COMMAND_RECEIVED_COUNTER                        => internal_UNKNOWN_COMMAND_RECEIVED_COUNTER,
		status_LEDs                                             => Aurora_RocketIO_GTP_MGT_101_status_LEDs,
		chipscope_ila                                           => open,
		chipscope_vio_buttons                                   => chipscope_vio_buttons,
		chipscope_vio_display                                   => chipscope_vio_display
	);

	QEB : entity work.quarter_event_builder
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE => CURRENT_PROTOCOL_FREEZE_DATE
	)
	port map (
		RESET                              => RESET,
--		CLOCK                              => internal_Aurora_78MHz_clock,
		CLOCK                              => QEB_AND_PB_CLOCK,
		COMMAND_ARGUMENT                   => internal_COMMAND_ARGUMENT,
		EVENT_NUMBER_SET                   => internal_EVENT_NUMBER_SET,
		INPUT_DATA_BUS                     => internal_ASIC_DATA_BLOCKRAM_DATA_BUS,
		INPUT_ADDRESS_BUS                  => internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS,
		INPUT_BLOCK_RAM_ADDRESS            => internal_INPUT_BLOCK_RAM_ADDRESS,
		ASIC_START_WINDOW                  => internal_ASIC_START_WINDOW,
		ASIC_END_WINDOW                    => internal_ASIC_END_WINDOW,
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC => internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC,
		OUTPUT_DATA_BUS                    => internal_QUARTER_EVENT_FIFO_INPUT_DATA_BUS,
		OUTPUT_ADDRESS_BUS                 => open,
		OUTPUT_FIFO_WRITE_ENABLE           => internal_QUARTER_EVENT_FIFO_WRITE_ENABLE,
		START_BUILDING_A_QUARTER_EVENT     => internal_START_BUILDING_A_QUARTER_EVENT,
		DONE_BUILDING_A_QUARTER_EVENT      => internal_DONE_BUILDING_A_QUARTER_EVENT,
		ASIC_SCALERS                       => ASIC_SCALERS,
		ASIC_TRIGGER_STREAMS               => ASIC_TRIGGER_STREAMS,
		TEMPERATURE_R1                     => TEMPERATURE_R1,
		SAMPLING_RATE_FEEDBACK_GOAL        => internal_SAMPLING_RATE_FEEDBACK_GOAL,
		WILKINSON_RATE_FEEDBACK_GOAL       => internal_WILKINSON_RATE_FEEDBACK_GOAL,
		TRIGGER_WIDTH_FEEDBACK_GOAL        => internal_TRIGGER_WIDTH_FEEDBACK_GOAL,
		SAMPLING_RATE_FEEDBACK_ENABLE      => internal_SAMPLING_RATE_FEEDBACK_ENABLE,
		WILKINSON_RATE_FEEDBACK_ENABLE     => internal_WILKINSON_RATE_FEEDBACK_ENABLE,
		TRIGGER_WIDTH_FEEDBACK_ENABLE      => internal_TRIGGER_WIDTH_FEEDBACK_ENABLE,
		DESIRED_DAC_SETTINGS               => internal_DESIRED_DAC_SETTINGS,
		CURRENT_DAC_SETTINGS               => CURRENT_DAC_SETTINGS
	);
	internal_ASIC_DATA_BLOCKRAM_DATA_BUS <= INPUT_DATA_BUS;
	INPUT_ADDRESS_BUS <= internal_ASIC_DATA_BLOCKRAM_ADDRESS_BUS;
	INPUT_BLOCK_RAM_ADDRESS <= internal_INPUT_BLOCK_RAM_ADDRESS;
	Aurora_78MHz_clock <= internal_Aurora_78MHz_clock;
--	internal_ASIC_DATA_BLOCKRAM_DATA_BUS <= x"1812"; -- upper four bits should be masked off elsewhere, so should see 0x0812
--	internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC <= "0" & x"59";
	internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC <= ADDRESS_OF_STARTING_WINDOW_IN_ASIC;
	internal_START_BUILDING_A_QUARTER_EVENT <= quarter_event_builder_enable and TRIGGER;
	quarter_event_builder_enable <= '1';
--	quarter_event_builder_enable <= not transmit_disable;
	DONE_BUILDING_A_QUARTER_EVENT <= internal_DONE_BUILDING_A_QUARTER_EVENT;
	CURRENTLY_BUILDING_A_QUARTER_EVENT <= internal_CURRENTLY_BUILDING_A_QUARTER_EVENT;
	Aurora_data_link_reset <= RESET;
	ASIC_START_WINDOW <= internal_ASIC_START_WINDOW;
	ASIC_END_WINDOW <= internal_ASIC_END_WINDOW;
	SAMPLING_RATE_FEEDBACK_GOAL    <= internal_SAMPLING_RATE_FEEDBACK_GOAL;
	WILKINSON_RATE_FEEDBACK_GOAL   <= internal_WILKINSON_RATE_FEEDBACK_GOAL;
	TRIGGER_WIDTH_FEEDBACK_GOAL    <= internal_TRIGGER_WIDTH_FEEDBACK_GOAL;
	SAMPLING_RATE_FEEDBACK_ENABLE  <= internal_SAMPLING_RATE_FEEDBACK_ENABLE;
	WILKINSON_RATE_FEEDBACK_ENABLE <= internal_WILKINSON_RATE_FEEDBACK_ENABLE;
	TRIGGER_WIDTH_FEEDBACK_ENABLE  <= internal_TRIGGER_WIDTH_FEEDBACK_ENABLE;
	DESIRED_DAC_SETTINGS <= internal_DESIRED_DAC_SETTINGS;

	QEF : entity work.quarter_event_fifo port map (
		rst    => RESET,
--		wr_clk => internal_Aurora_78MHz_clock,
		wr_clk => QEB_AND_PB_CLOCK,
		rd_clk => internal_Aurora_78MHz_clock,
		din    => internal_QUARTER_EVENT_FIFO_INPUT_DATA_BUS,
		wr_en  => internal_QUARTER_EVENT_FIFO_WRITE_ENABLE,
		rd_en  => quarter_event_fifo_read_enable,
		dout   => internal_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS,
		full   => open,
		empty  => quarter_event_fifo_is_empty,
		valid  => open
	);
--	inverted_clock_1MHz <= not clock_1MHz;
	-- might want to have an additional signal anded with these that is a
	-- set-reset flip flop that is set when the quarter event is finished
	--	building and cleared when another one is started:
	quarter_event_fifo_read_enable <= (not quarter_event_fifo_is_empty) and (not Aurora_lane0_transmit_destination_ready_active_low);
	Aurora_lane0_transmit_source_ready_active_low <= not quarter_event_fifo_read_enable;
	Aurora_lane0_transmit_data_bus <= internal_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS;

	--Logic to generate the "busy" signal
--	process(internal_Aurora_78MHz_clock) begin
--		if (rising_edge(internal_Aurora_78MHz_clock)) then
	process(QEB_AND_PB_CLOCK) begin
		if (rising_edge(QEB_AND_PB_CLOCK)) then
			if (TRIGGER = '1' and internal_CURRENTLY_BUILDING_A_QUARTER_EVENT = '0') then
				internal_CURRENTLY_BUILDING_A_QUARTER_EVENT <= '1';
			elsif (internal_DONE_BUILDING_A_QUARTER_EVENT = '1') then
				internal_CURRENTLY_BUILDING_A_QUARTER_EVENT <= '0';
			end if;
		end if;
	end process;

end behavioral;
