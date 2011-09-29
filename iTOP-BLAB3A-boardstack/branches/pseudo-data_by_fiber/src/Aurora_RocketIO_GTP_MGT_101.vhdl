-- 2011-09 mza
-----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity Aurora_RocketIO_GTP_MGT_101 is
	generic (
		CURRENT_PROTOCOL_FREEZE_DATE                : std_logic_vector(31 downto 0) := x"20110910";
		NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND : integer := 1; -- set to 83 for an 83kHz clock input
		SIM_GTPRESET_SPEEDUP                        : integer := 1  -- set to 1 to speed up sim reset
	);
	port (
		RESET                                                   : in    std_logic;
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
		Aurora_lane0_transmit_data_bus                          : in    std_logic_vector(31 downto 0);
		Aurora_lane0_transmit_source_ready_active_low           : in    std_logic;
		Aurora_lane0_transmit_destination_ready_active_low      :   out std_logic;
		Aurora_lane0_receive_source_ready_active_low            :   out std_logic;
		Aurora_lane0_receive_data_bus                           :   out std_logic_vector(31 downto 0);
		should_not_automatically_try_to_keep_fiber_link_up      : in    std_logic;
		fiber_link_is_up                                        :   out std_logic;
		EVENT_NUMBER_RESET                                      :   out std_logic;
		-----------------------------------------------------------------------------
		status_LEDs                                             :   out std_logic_vector(3 downto 0);
		chipscope_ila                                           :   out std_logic_vector(255 downto 0);
		chipscope_vio_buttons                                   : in    std_logic_vector(255 downto 0);
		chipscope_vio_display                                   :   out std_logic_vector(255 downto 0)
	);
end Aurora_RocketIO_GTP_MGT_101;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

architecture behavioral of Aurora_RocketIO_GTP_MGT_101 is
	signal internal_chipscope_ila         : std_logic_vector(255 downto 0);
	signal internal_chipscope_vio_buttons : std_logic_vector(255 downto 0);
	signal internal_chipscope_vio_display : std_logic_vector(255 downto 0);
	signal internal_Aurora_78MHz_clock    : std_logic;
	-----------------------------------------------------------------------------
--	signal request_a_fiber_link_reset                         : std_logic := '0';
	signal internal_fiber_link_is_up                          : std_logic;
	signal fiber_link_should_be_up                            : std_logic;
--	signal should_not_automatically_try_to_keep_fiber_link_up : std_logic := '0';
	-----------------------------------------------------------------------------
	signal internal_status_LEDs : std_logic_vector(3 downto 0) := x"0";
	-----------------------------------------------------------------------------
	attribute core_generation_info               : string;
	attribute core_generation_info of behavioral : architecture is "Aurora_IP_Core_A,aurora_8b10b_v5_2,{backchannel_mode=Sidebands, c_aurora_lanes=1, c_column_used=None, c_gt_clock_1=GTPD2, c_gt_clock_2=None, c_gt_loc_1=X, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=X, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=1, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=4, c_line_rate=3.125, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=156.25, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex}";
	-- Parameter Declarations --
	constant DLY : time := 1 ns;
	-- External Register Declarations --
	signal HARD_ERR_Buffer    : std_logic;
	signal SOFT_ERR_Buffer    : std_logic;
	signal LANE_UP_Buffer     : std_logic;
	signal CHANNEL_UP_Buffer  : std_logic;
	-- Internal Register Declarations --
	signal gt_reset_i         : std_logic; 
	signal system_reset_i     : std_logic;
	-- V5 Reference Clock Interface
	signal Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_left      : std_logic;
	-- Error Detection Interface
	signal hard_err_i       : std_logic;
	signal soft_err_i       : std_logic;
	-- Status
	signal channel_up_i       : std_logic;
	signal lane_up_i          : std_logic;
	signal not_lane_up_i      : std_logic;
	-- Clock Compensation Control Interface
	signal warn_cc_i          : std_logic;
	signal do_cc_i            : std_logic;
	-- System Interface ---------------------------------------------------------
	signal pll_not_locked_i   : std_logic;
	signal sync_clk_i         : std_logic;
	signal reset_i            : std_logic;
	signal power_down_i       : std_logic;
	signal loopback_i         : std_logic_vector(2 downto 0);
	signal tx_lock_i          : std_logic;
	signal gtpclkout_i        : std_logic;
	signal buf_gtpclkout_i    : std_logic;
	--Frame check signals -------------------------------------------------------
	signal err_count_i      : std_logic_vector(0 to 7);
	signal ERR_COUNT_Buffer : std_logic_vector(0 to 7);
	-----------------------------------------------------------------------------
	attribute ASYNC_REG        : string;
	attribute ASYNC_REG of tx_lock_i  : signal is "TRUE";
	signal AURORA_RESET_IN : std_logic := '1';
	signal GT_RESET_IN     : std_logic := '1';
	signal rx_char_is_comma_i : std_logic_vector(3 downto 0);
	signal lane_init_state_i  : std_logic_vector(6 downto 0);
	signal reset_lanes_i : std_logic;
	signal tx_pe_data_i : std_logic_vector(31 downto 0);
	-----------------------------------------------------------------------------
	signal internal_WRONG_PACKET_SIZE_COUNTER          : std_logic_vector(31 downto 0);
	signal internal_WRONG_PACKET_TYPE_COUNTER          : std_logic_vector(31 downto 0);
	signal internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER : std_logic_vector(31 downto 0);
	signal internal_WRONG_SCROD_ADDRESSED_COUNTER      : std_logic_vector(31 downto 0);
	signal internal_WRONG_CHECKSUM_COUNTER             : std_logic_vector(31 downto 0);
	signal internal_WRONG_FOOTER_COUNTER               : std_logic_vector(31 downto 0);
	signal internal_UNKNOWN_ERROR_COUNTER              : std_logic_vector(31 downto 0);
	signal internal_MISSING_ACKNOWLEDGEMENT_COUNTER    : std_logic_vector(31 downto 0);
	signal internal_number_of_sent_events              : std_logic_vector(31 downto 0);
	signal internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR : std_logic_vector(31 downto 0);
	signal internal_resynchronizing_with_header        : std_logic;
	signal internal_start_event_transfer               : std_logic;
	signal internal_acknowledge_start_event_transfer   : std_logic;
	signal internal_EVENT_NUMBER_RESET                 : std_logic := '0';
	-----------------------------------------------------------------------------
	signal chipscope_aurora_reset                             : std_logic;
	signal internal_FIBER_TRANSCEIVER_0_DISABLE_MODULE        : std_logic := '1';
	signal internal_Aurora_RocketIO_GTP_MGT_101_reset_clock   : std_logic;
	signal internal_Aurora_lane0_receive_data_bus : std_logic_vector(31 downto 0);
	signal internal_Aurora_lane0_transmit_source_ready_active_low : std_logic;
	signal internal_Aurora_lane0_receive_source_ready_active_low : std_logic;
	-----------------------------------------------------------------------------
begin
	IBUFDS_i : IBUFDS port map (I => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_P, IB => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_N, O => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_left);
	Aurora_78MHz_clock                                     <= internal_Aurora_78MHz_clock;
	Aurora_lane0_receive_data_bus                          <= internal_Aurora_lane0_receive_data_bus;
	Aurora_lane0_receive_source_ready_active_low           <= internal_Aurora_lane0_receive_source_ready_active_low;
	internal_Aurora_lane0_transmit_source_ready_active_low <= Aurora_lane0_transmit_source_ready_active_low;
	internal_Aurora_RocketIO_GTP_MGT_101_reset_clock       <= Aurora_RocketIO_GTP_MGT_101_reset_clock;
	not_lane_up_i                                          <= not lane_up_i;
	-----------------------------------------------------------------------------
	internal_status_LEDs(0) <= internal_fiber_link_is_up;
	internal_status_LEDs(1) <= fiber_link_should_be_up;
	internal_status_LEDs(2) <= FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER;
	internal_status_LEDs(3) <= FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT;
	EVENT_NUMBER_RESET <= internal_EVENT_NUMBER_RESET;
	-----------------------------------------------------------------------------
	FIBER_TRANSCEIVER_0_DISABLE_MODULE <= internal_FIBER_TRANSCEIVER_0_DISABLE_MODULE;
	FIBER_TRANSCEIVER_1_DISABLE_MODULE <= '1';
	chipscope_ila                  <= internal_chipscope_ila;
	chipscope_vio_display          <= internal_chipscope_vio_display;
	internal_chipscope_vio_buttons <= chipscope_vio_buttons;
	internal_chipscope_ila         <= (others => '0');
	internal_chipscope_vio_display <= (others => '0');
	reset_i                        <= system_reset_i or RESET;
	status_LEDs                    <= internal_status_LEDs;

	process(internal_Aurora_RocketIO_GTP_MGT_101_reset_clock, RESET, FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT)
		variable internal_COUNTER                                       : integer range 0 to 1000000 := 0;
		constant number_of_cycles_to_keep_fiber_transceiver_powered_off : integer := 2 * NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND;
		constant number_of_cycles_to_wait_for_transceiver_to_power_on   : integer := 300 * NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND;
		constant number_of_cycles_to_wait_for_gt_logic_to_reset         : integer := 5 * NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND;
		constant number_of_cycles_to_wait_for_aurora_logic_to_reset     : integer := 5 * NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND;
		constant number_of_cycles_to_wait_for_aurora_to_connect         : integer := 100 * NUMBER_OF_SLOW_CLOCK_CYCLES_PER_MILLISECOND;
		constant counter_value_to_get_past_fiber_transceiver_power_off_state : integer := number_of_cycles_to_keep_fiber_transceiver_powered_off;
		constant counter_value_to_get_past_fiber_transceiver_reset_state     : integer := number_of_cycles_to_keep_fiber_transceiver_powered_off + number_of_cycles_to_wait_for_transceiver_to_power_on;
		constant counter_value_to_get_past_gt_logic_reset_state              : integer := number_of_cycles_to_keep_fiber_transceiver_powered_off + number_of_cycles_to_wait_for_transceiver_to_power_on + number_of_cycles_to_wait_for_gt_logic_to_reset;
		constant counter_value_to_get_past_aurora_logic_reset_state          : integer := number_of_cycles_to_keep_fiber_transceiver_powered_off + number_of_cycles_to_wait_for_transceiver_to_power_on + number_of_cycles_to_wait_for_gt_logic_to_reset + number_of_cycles_to_wait_for_aurora_logic_to_reset;
		constant counter_value_to_get_past_aurora_connection_wait_state      : integer := number_of_cycles_to_keep_fiber_transceiver_powered_off + number_of_cycles_to_wait_for_transceiver_to_power_on + number_of_cycles_to_wait_for_gt_logic_to_reset + number_of_cycles_to_wait_for_aurora_logic_to_reset + number_of_cycles_to_wait_for_aurora_to_connect;
	begin
		if (	RESET = '1' or
				FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT = '1' or
				(should_not_automatically_try_to_keep_fiber_link_up = '0' and fiber_link_should_be_up = '1' and internal_fiber_link_is_up = '0')
				) then
			fiber_link_should_be_up <= '0';
--			internal_fiber_link_is_up <= '0';
			internal_COUNTER := 0;
			AURORA_RESET_IN <= '1';
			GT_RESET_IN     <= '1';
			internal_FIBER_TRANSCEIVER_0_DISABLE_MODULE <= '1';
		elsif (rising_edge(internal_Aurora_RocketIO_GTP_MGT_101_reset_clock)) then
			-- an avago afbr-57r5aez requires the following (pdf, page 12):
			-- a rising edge on tx_disable (from page 12 note 1)
			-- a maximum power-up time of 300ms from power up or falling edge of
			--     tx_disable to when it can be used for data (from page 12 note 3)
			if (internal_COUNTER < counter_value_to_get_past_fiber_transceiver_power_off_state) then -- 0 to 1
				internal_COUNTER := internal_COUNTER + 1;
				AURORA_RESET_IN <= '1';
				GT_RESET_IN     <= '1';
				internal_fiber_link_is_up <= '0';
				internal_FIBER_TRANSCEIVER_0_DISABLE_MODULE <= '1';
			elsif (internal_COUNTER < counter_value_to_get_past_fiber_transceiver_reset_state) then  -- 2 to 301
				internal_COUNTER := internal_COUNTER + 1;
				internal_FIBER_TRANSCEIVER_0_DISABLE_MODULE <= '0';
			elsif (internal_COUNTER < counter_value_to_get_past_gt_logic_reset_state) then           -- 302 to 306
				internal_COUNTER := internal_COUNTER + 1;
				GT_RESET_IN     <= '0';
			elsif (internal_COUNTER < counter_value_to_get_past_aurora_logic_reset_state) then       -- 307 to 311
				internal_COUNTER := internal_COUNTER + 1;
				AURORA_RESET_IN <= '0';
			elsif (internal_COUNTER < counter_value_to_get_past_aurora_connection_wait_state) then   -- 312 to 411
				internal_COUNTER := internal_COUNTER + 1;
			else                                                                                     -- 412
				internal_fiber_link_is_up <= CHANNEL_UP_Buffer and LANE_UP_Buffer;
				if (FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER = '0') then
					fiber_link_should_be_up <= '1';
				else
					fiber_link_should_be_up <= '0';
				end if;
			end if;
		end if;
	end process;

    -- Register User I/O --
    -- Register User Outputs from core.
	process (internal_Aurora_78MHz_clock)
	begin
		if rising_edge(internal_Aurora_78MHz_clock) then
			HARD_ERR_Buffer    <= hard_err_i;
			SOFT_ERR_Buffer    <= soft_err_i;
			ERR_COUNT_Buffer   <= err_count_i;
			LANE_UP_Buffer     <= lane_up_i;
			CHANNEL_UP_Buffer  <= channel_up_i;
		end if;
	end process;

	BUFIO2_i : BUFIO2
	generic map (
		DIVIDE         =>      1,
		DIVIDE_BYPASS  =>      TRUE
	)
	port map (
		I              =>      gtpclkout_i,
		DIVCLK         =>      buf_gtpclkout_i,
		IOCLK          =>      open,
		SERDESSTROBE   =>      open
	);

	-- Instantiate a clock module for clock division
	clock_module_i : entity work.Aurora_IP_Core_A_CLOCK_MODULE
	port map (
		GT_CLK          => buf_gtpclkout_i,
		GT_CLK_LOCKED   => tx_lock_i,
		USER_CLK        => internal_Aurora_78MHz_clock,
		SYNC_CLK        => sync_clk_i,
		PLL_NOT_LOCKED  => pll_not_locked_i
	);

    -- System Interface
	power_down_i     <= '0';
	loopback_i       <= "000";

	PRCI : entity work.packet_receiver_and_command_interpreter
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE => unsigned(CURRENT_PROTOCOL_FREEZE_DATE)
	)
	port map (
		-- User Interface
		RX_D            =>  internal_Aurora_lane0_receive_data_bus,
		RX_SRC_RDY_N    =>  internal_Aurora_lane0_receive_source_ready_active_low,  
		-- System Interface
		USER_CLK        =>  internal_Aurora_78MHz_clock,   
		RESET           =>  reset_i,
		CHANNEL_UP      =>  channel_up_i,
		WRONG_PACKET_SIZE_COUNTER                      => internal_WRONG_PACKET_SIZE_COUNTER,
		WRONG_PACKET_TYPE_COUNTER                      => internal_WRONG_PACKET_TYPE_COUNTER,
		WRONG_PROTOCOL_FREEZE_DATE_COUNTER             => internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER,
		WRONG_SCROD_ADDRESSED_COUNTER                  => internal_WRONG_SCROD_ADDRESSED_COUNTER,
		WRONG_CHECKSUM_COUNTER                         => internal_WRONG_CHECKSUM_COUNTER,
		WRONG_FOOTER_COUNTER                           => internal_WRONG_FOOTER_COUNTER,
		UNKNOWN_ERROR_COUNTER                          => internal_UNKNOWN_ERROR_COUNTER,
		MISSING_ACKNOWLEDGEMENT_COUNTER                => internal_MISSING_ACKNOWLEDGEMENT_COUNTER,
		number_of_sent_events                          => internal_number_of_sent_events,
		NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR => internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR,
		resynchronizing_with_header                    => internal_resynchronizing_with_header,
		start_event_transfer                           => internal_start_event_transfer,
		acknowledge_start_event_transfer               => internal_acknowledge_start_event_transfer,
		ERR_COUNT                                      => err_count_i,
		EVENT_NUMBER_RESET                             => internal_EVENT_NUMBER_RESET
	);

	aurora_module_i : entity work.Aurora_IP_Core_A
	generic map(
		SIM_GTPRESET_SPEEDUP => SIM_GTPRESET_SPEEDUP
	)
	port map (
		-- LocalLink TX Interface
		TX_D             => Aurora_lane0_transmit_data_bus,
		TX_SRC_RDY_N     => internal_Aurora_lane0_transmit_source_ready_active_low,
		TX_DST_RDY_N     => Aurora_lane0_transmit_destination_ready_active_low,
		-- LocalLink RX Interface
		RX_D             => internal_Aurora_lane0_receive_data_bus,
		RX_SRC_RDY_N     => internal_Aurora_lane0_receive_source_ready_active_low,
		-- V5 Serial I/O
		RXP              => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_P,
		RXN              => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_N,
		TXP              => Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_P,
		TXN              => Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_N,
		-- V5 Reference Clock Interface
		GTPD2    => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_left,
		-- Error Detection Interface
		HARD_ERR       => hard_err_i,
		SOFT_ERR       => soft_err_i,
		-- Status
		CHANNEL_UP       => channel_up_i,
		LANE_UP          => lane_up_i,
		-- Clock Compensation Control Interface
		WARN_CC          => warn_cc_i,
		DO_CC            => do_cc_i,
		-- System Interface
		USER_CLK         => internal_Aurora_78MHz_clock,
		SYNC_CLK         => sync_clk_i,
		RESET            => reset_i,
		POWER_DOWN       => power_down_i,
		LOOPBACK         => loopback_i,
		GT_RESET         => gt_reset_i,
		GTPCLKOUT        => gtpclkout_i,
		TX_LOCK          => tx_lock_i,
		-- Kurtis added
		RX_CHAR_IS_COMMA => rx_char_is_comma_i,
		LANE_INIT_STATE  => lane_init_state_i,
		RESET_LANES      => reset_lanes_i,
		TX_PE_DATA       => tx_pe_data_i
	);

	standard_cc_module_i : entity work.Aurora_IP_Core_A_STANDARD_CC_MODULE
	port map (
		-- Clock Compensation Control Interface
		WARN_CC        => warn_cc_i,
		DO_CC          => do_cc_i,
		-- System Interface
		PLL_NOT_LOCKED => pll_not_locked_i,
		USER_CLK       => internal_Aurora_78MHz_clock,
		RESET          => not_lane_up_i
	);

	reset_logic_i : entity work.Aurora_IP_Core_A_RESET_LOGIC
	port map (
		RESET            => AURORA_RESET_IN,
		USER_CLK         => internal_Aurora_78MHz_clock,
		INIT_CLK         => Aurora_RocketIO_GTP_MGT_101_initialization_clock,
		GT_RESET_IN      => GT_RESET_IN,
		TX_LOCK_IN       => tx_lock_i,
		PLL_NOT_LOCKED   => pll_not_locked_i,
		SYSTEM_RESET     => system_reset_i,
		GT_RESET_OUT     => gt_reset_i
	);

end behavioral;
