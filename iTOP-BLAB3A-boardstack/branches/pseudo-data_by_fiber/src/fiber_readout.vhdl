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
		USE_USB_READOUT										  : boolean := TRUE;
		CURRENT_PROTOCOL_FREEZE_DATE                   : std_logic_vector(31 downto 0) := x"20111213";
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
		SCROD_SER															  : in	 std_logic_vector(31 downto 0);
		Aurora_RocketIO_GTP_MGT_101_RESET                       : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_initialization_clock        : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_reset_clock                 : in    std_logic;
--		 fiber optic dual clock input
		Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_P             : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_N             : in    std_logic;
--		 fiber optic transceiver #101 lane 0 I/O
		Aurora_RocketIO_GTP_MGT_101_lane0_Receive_P             : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_lane0_Receive_N             : in    std_logic;
		Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_P            : out std_logic;
		Aurora_RocketIO_GTP_MGT_101_lane0_Transmit_N            : out std_logic;
		FIBER_TRANSCEIVER_0_LASER_FAULT_DETECTED_IN_TRANSMITTER : in    std_logic;
		FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER : in    std_logic;
 		FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT  : in    std_logic;
		FIBER_TRANSCEIVER_0_DISABLE_MODULE                      : out std_logic;
--		 fiber optic transceiver #101 lane 1 I/O
		FIBER_TRANSCEIVER_1_DISABLE_MODULE                      : out std_logic;
		should_not_automatically_try_to_keep_fiber_link_up      : in    std_logic;
		fiber_link_is_up                                        : out std_logic;
		READOUT_CLK			                                      : out std_logic;
		QEB_AND_PB_CLOCK                                        : in    std_logic;

		-- USB interface ------------------------------------------------------------
		IFCLK																	  : in std_logic;
		CLKOUT																  : in std_logic;
		FDD																	  : inout std_logic_vector(15 downto 0);
		PA0																	  : out std_logic;
		PA1																	  : out std_logic;
		PA2																	  : out std_logic;
		PA3																	  : out std_logic;
		PA4																	  : out std_logic;
		PA5																	  : out std_logic;
		PA6																	  : out std_logic;
		PA7																	  : in std_logic;
		CTL0																	  : in std_logic;
		CTL1																	  : in std_logic;
		CTL2																	  : in std_logic;
		RDY0																	  : out std_logic;
		RDY1																	  : out std_logic;
		WAKEUP																  : in std_logic;
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
		WINDOWS_TO_LOOK_BACK                                    :   out std_logic_vector(8 downto 0);
		ADDRESS_OF_STARTING_WINDOW_IN_ASIC                      : in    std_logic_vector(8 downto 0);
		-----------------------------------------------------------------------------
		ASIC_SCALERS                                            : in    ASIC_Scalers_C_R_CH;
		ASIC_TRIGGER_STREAMS                                    : in    ASIC_Trigger_Stream_C_R_CH;
		-----------------------------------------------------------------------------
		FEEDBACK_WILKINSON_COUNTER_C_R                          : in    Wilkinson_Rate_Counters_C_R;
		FEEDBACK_SAMPLING_RATE_COUNTER_C_R                      : in    Sampling_Rate_Counters_C_R;		
		-----------------------------------------------------------------------------
		TEMPERATURE_R1                                          : in    std_logic_vector(11 downto 0);
		FEEDBACK_WILKINSON_DAC_VALUE_C_R                        : in    Wilkinson_Rate_DAC_C_R;
		FEEDBACK_VADJP_DAC_VALUE_C_R                            : in    Sampling_Rate_DAC_C_R;
		FEEDBACK_VADJN_DAC_VALUE_C_R                            : in    Sampling_Rate_DAC_C_R;
		SAMPLING_RATE_FEEDBACK_GOAL                             :   out std_logic_vector(31 downto 0);
		WILKINSON_RATE_FEEDBACK_GOAL                            :   out std_logic_vector(31 downto 0);
		TRIGGER_WIDTH_FEEDBACK_GOAL                             :   out std_logic_vector(31 downto 0);
		SAMPLING_RATE_FEEDBACK_ENABLE                           :   out std_logic_vector(15 downto 0);
		WILKINSON_RATE_FEEDBACK_ENABLE                          :   out std_logic_vector(15 downto 0);
		TRIGGER_WIDTH_FEEDBACK_ENABLE                           :   out std_logic_vector(15 downto 0)
		
--		CONTROL3																  : inout std_logic_vector(35 downto 0)
--		CONTROL4																  : inout std_logic_vector(35 downto 0)
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
	signal Aurora_data_link_reset                             : std_logic := '0';
	signal internal_Aurora_78MHz_clock                        : std_logic;
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
	signal Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_left     : std_logic;
	signal Aurora_RocketIO_GTP_MGT_101_lane0_Receive_left     : std_logic;
	signal Aurora_lane0_transmit_data_bus                     : std_logic_vector(0 to 31);
	signal Aurora_lane0_transmit_source_ready_active_low      : std_logic;
	signal Aurora_lane0_transmit_destination_ready_active_low : std_logic;
	-- Stream RX Interface ------------------------------------------------------
	signal Aurora_lane0_receive_data_bus                      : std_logic_vector(0 to 31);
	signal Aurora_lane0_receive_source_ready_active_low       : std_logic;
	-- USB Interface-------------------------------------------------------------
	signal internal_USB_FIFO_CLK			: std_logic;
	signal internal_USB_FIFO_RST			: std_logic;
	signal internal_COMMAND_RX_DATA_BUS	: std_logic_vector(31 downto 0);
	signal internal_COMMAND_RX_RD_EN		: std_logic;
	signal internal_QEV_TX_DATA_BUS		: std_logic_vector(15 downto 0);
	signal internal_QEV_TX_WR_EN			: std_logic;
	signal internal_QEV_TX_RD_EN			: std_logic;
	signal internal_QEV_TX_FULL			: std_logic;
	signal internal_QEV_TX_EMPTY			: std_logic;

	-----------------------------------------------------------------------------	
	signal internal_UNKNOWN_COMMAND_RECEIVED_COUNTER      : std_logic_vector(7 downto 0);
	-- commands: ----------------------------------------------------------------
	signal internal_DESIRED_DAC_SETTINGS               : Board_Stack_Voltages;
	signal internal_COMMAND_ARGUMENT                   : std_logic_vector(31 downto 0) := x"00000000";
	signal internal_EVENT_NUMBER_SET                   : std_logic                     := '0';
	signal internal_ASIC_START_WINDOW                  : std_logic_vector( 8 downto 0) := (others => '0');
	signal internal_ASIC_END_WINDOW                    : std_logic_vector( 8 downto 0) := (others => '1');
	signal internal_WINDOWS_TO_LOOK_BACK               : std_logic_vector( 8 downto 0) := "000000100";
	signal internal_SAMPLING_RATE_FEEDBACK_ENABLE      : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_WILKINSON_RATE_FEEDBACK_ENABLE     : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_TRIGGER_WIDTH_FEEDBACK_ENABLE      : std_logic_vector(15 downto 0) := (others => '0');
	signal internal_SAMPLING_RATE_FEEDBACK_GOAL        : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_WILKINSON_RATE_FEEDBACK_GOAL       : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_TRIGGER_WIDTH_FEEDBACK_GOAL        : std_logic_vector(31 downto 0) := (others => '0');
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
	signal internal_acknowledge_execution_of_command   : std_logic := '0';
	
	signal internal_USB_CHIPSCOPE_CLK									: std_logic;
	
--	signal CHIPSCOPE_TRIG										: std_logic_vector(103 downto 0);
--	component usb_ila
--	  PORT (
--		 CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
--		 CLK : IN STD_LOGIC;
--		 TRIG0 : IN STD_LOGIC_VECTOR(103 DOWNTO 0));
--	end component;
--	-- Synplicity black box declaration
--	attribute syn_black_box : boolean;
--	attribute syn_black_box of usb_ila: component is true;

begin
--//Fiber-------------------------------------------------------------------------------------------------------------------
fiber_gen: if (USE_USB_READOUT = FALSE) generate
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
		-----------------------------------------------------------------------------
		UNKNOWN_COMMAND_RECEIVED_COUNTER                        => internal_UNKNOWN_COMMAND_RECEIVED_COUNTER,
		status_LEDs                                             => Aurora_RocketIO_GTP_MGT_101_status_LEDs,
		chipscope_ila                                           => open,
		chipscope_vio_buttons                                   => chipscope_vio_buttons,
		chipscope_vio_display                                   => chipscope_vio_display
	);
	
		PRCI : entity work.packet_receiver_and_command_interpreter
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE => unsigned(CURRENT_PROTOCOL_FREEZE_DATE)
	)
	port map (
		-- User Interface
		PACKET_IN       =>  Aurora_lane0_receive_data_bus,
		PACKET_WR_EN    =>  Aurora_lane0_receive_source_ready_active_low,  
		-- System Interface
		USER_CLK        =>  internal_Aurora_78MHz_clock,   
		RESET           =>  Aurora_data_link_reset,
--		CHANNEL_UP      =>  channel_up_i,
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
		-- commands -----------------------------------------------------------------
		COMMAND_ARGUMENT                               => internal_COMMAND_ARGUMENT,
		EVENT_NUMBER_SET                               => internal_EVENT_NUMBER_SET,
		REQUEST_A_GLOBAL_RESET                         => REQUEST_A_GLOBAL_RESET,
		DESIRED_DAC_SETTINGS                           => internal_DESIRED_DAC_SETTINGS,
		SOFT_TRIGGER_FROM_FIBER                        => SOFT_TRIGGER_FROM_FIBER,
		CLEAR_TRIGGER_VETO                             => CLEAR_TRIGGER_VETO,
		RESET_SCALER_COUNTERS                          => RESET_SCALER_COUNTERS,
		ASIC_START_WINDOW                              => internal_ASIC_START_WINDOW,
		ASIC_END_WINDOW                                => internal_ASIC_END_WINDOW,
		WINDOWS_TO_LOOK_BACK                           => internal_WINDOWS_TO_LOOK_BACK,
		SAMPLING_RATE_FEEDBACK_GOAL                    => internal_SAMPLING_RATE_FEEDBACK_GOAL,
		WILKINSON_RATE_FEEDBACK_GOAL                   => internal_WILKINSON_RATE_FEEDBACK_GOAL,
		TRIGGER_WIDTH_FEEDBACK_GOAL                    => internal_TRIGGER_WIDTH_FEEDBACK_GOAL,
		SAMPLING_RATE_FEEDBACK_ENABLE                  => internal_SAMPLING_RATE_FEEDBACK_ENABLE,
		WILKINSON_RATE_FEEDBACK_ENABLE                 => internal_WILKINSON_RATE_FEEDBACK_ENABLE,
		TRIGGER_WIDTH_FEEDBACK_ENABLE                  => internal_TRIGGER_WIDTH_FEEDBACK_ENABLE,
		-----------------------------------------------------------------------------
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_WILKINSON_CLOCK_RATE => FEEDBACK_WILKINSON_DAC_VALUE_C_R,
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJP  => FEEDBACK_VADJP_DAC_VALUE_C_R,
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJN  => FEEDBACK_VADJN_DAC_VALUE_C_R,
		acknowledge_execution_of_command               => internal_acknowledge_execution_of_command,
		UNKNOWN_COMMAND_RECEIVED_COUNTER               => internal_UNKNOWN_COMMAND_RECEIVED_COUNTER
	);
	
	READOUT_CLK <= internal_Aurora_78MHz_clock;

	QEF : entity work.quarter_event_fifo port map (
		rst    => RESET,
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

end generate;
---------------------------------------------------------------------------------------------------------------------
--//USB-------------------------------------------------------------------------------------------------------------------
usb_gen: if(USE_USB_READOUT = TRUE) generate
--Need this to sucessfully build
	IBUFDS_CLK_i : IBUFDS port map (I => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_P, IB => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_N, O => Aurora_RocketIO_GTP_MGT_101_CLOCK_156_MHz_left);
	IBUFDS_RX_i : IBUFDS port map (I => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_P, IB => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_N, O => Aurora_RocketIO_GTP_MGT_101_lane0_Receive_left);

	USB_data_link : entity work.usb_top
	port map(
		IFCLK							=> IFCLK,
		CTL0							=> CTL0,
		CTL1							=> CTL1,
		CTL2							=> CTL2,
		FDD							=> FDD,
		RDY0							=> RDY0,
		RDY1							=> RDY1,
		WAKEUP						=> WAKEUP,
		PA0							=> PA0,
		PA1							=> PA1,
		PA2							=> PA2,
		PA3							=> PA3,
		PA4							=> PA4,
		PA5							=> PA5,
		PA6							=> PA6,
		PA7							=> PA7,
		CLKOUT						=> CLKOUT,
		
		USB_FIFO_CLK				=> internal_USB_FIFO_CLK,
--		USB_CHIPSCOPE_CLK			=> internal_USB_CHIPSCOPE_CLK,
		USB_FIFO_RST				=> RESET,
--		NEW_DATA_RST				=> internal_START_BUILDING_A_QUARTER_EVENT,
		COMMAND_RX_DATA_BUS		=> internal_COMMAND_RX_DATA_BUS,
		COMMAND_RX_RD_EN			=> internal_COMMAND_RX_RD_EN,
		QEV_TX_DATA_BUS			=> internal_QEV_TX_DATA_BUS,
--		QEV_TX_WR_EN				=> internal_QEV_TX_WR_EN,
		QEV_TX_RD_EN				=> internal_QEV_TX_RD_EN,
--		QEV_TX_FULL					=> internal_QEV_TX_FULL,
		QEV_TX_EMPTY				=> internal_QEV_TX_EMPTY
--		CONTROL						=> CONTROL3
	);

	PRCI : entity work.packet_receiver_and_command_interpreter
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE => unsigned(CURRENT_PROTOCOL_FREEZE_DATE)
	)
	port map (
		-- User Interface
		PACKET_IN       =>  internal_COMMAND_RX_DATA_BUS,
		PACKET_WR_EN    =>  not internal_COMMAND_RX_RD_EN,  
		-- System Interface
		USER_CLK        =>  internal_USB_FIFO_CLK,   
		RESET           =>  RESET,
--		CHANNEL_UP      =>  channel_up_i,
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
		-- commands -----------------------------------------------------------------
		COMMAND_ARGUMENT                               => internal_COMMAND_ARGUMENT,
		EVENT_NUMBER_SET                               => internal_EVENT_NUMBER_SET,
		REQUEST_A_GLOBAL_RESET                         => REQUEST_A_GLOBAL_RESET,
		DESIRED_DAC_SETTINGS                           => internal_DESIRED_DAC_SETTINGS,
		SOFT_TRIGGER_FROM_FIBER                        => SOFT_TRIGGER_FROM_FIBER,
		CLEAR_TRIGGER_VETO                             => CLEAR_TRIGGER_VETO,
		RESET_SCALER_COUNTERS                          => RESET_SCALER_COUNTERS,
		ASIC_START_WINDOW                              => internal_ASIC_START_WINDOW,
		ASIC_END_WINDOW                                => internal_ASIC_END_WINDOW,
		WINDOWS_TO_LOOK_BACK                           => internal_WINDOWS_TO_LOOK_BACK,
		SAMPLING_RATE_FEEDBACK_GOAL                    => internal_SAMPLING_RATE_FEEDBACK_GOAL,
		WILKINSON_RATE_FEEDBACK_GOAL                   => internal_WILKINSON_RATE_FEEDBACK_GOAL,
		TRIGGER_WIDTH_FEEDBACK_GOAL                    => internal_TRIGGER_WIDTH_FEEDBACK_GOAL,
		SAMPLING_RATE_FEEDBACK_ENABLE                  => internal_SAMPLING_RATE_FEEDBACK_ENABLE,
		WILKINSON_RATE_FEEDBACK_ENABLE                 => internal_WILKINSON_RATE_FEEDBACK_ENABLE,
		TRIGGER_WIDTH_FEEDBACK_ENABLE                  => internal_TRIGGER_WIDTH_FEEDBACK_ENABLE,
		-----------------------------------------------------------------------------
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_WILKINSON_CLOCK_RATE => FEEDBACK_WILKINSON_DAC_VALUE_C_R,
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJP  => FEEDBACK_VADJP_DAC_VALUE_C_R,
		DESIRED_DAC_SETTING_FROM_FEEDBACK_FOR_SAMPLING_RATE_VADJN  => FEEDBACK_VADJN_DAC_VALUE_C_R,
		acknowledge_execution_of_command               => internal_acknowledge_execution_of_command,
		UNKNOWN_COMMAND_RECEIVED_COUNTER               => internal_UNKNOWN_COMMAND_RECEIVED_COUNTER
	);
	
	READOUT_CLK <= internal_USB_FIFO_CLK;

	QEF : entity work.fifo_32_to_16_bit port map (
--		rst    => (internal_START_BUILDING_A_QUARTER_EVENT or RESET),
		rst    => (RESET),
		wr_clk => QEB_AND_PB_CLOCK,
		rd_clk => internal_USB_FIFO_CLK,
		din    => internal_QUARTER_EVENT_FIFO_INPUT_DATA_BUS,
		wr_en  => internal_QUARTER_EVENT_FIFO_WRITE_ENABLE,
--		rd_en  => quarter_event_fifo_read_enable,
		rd_en  => internal_QEV_TX_RD_EN,
--		dout   => internal_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS,
		dout   => internal_QEV_TX_DATA_BUS,
		full   => open,
--		empty  => quarter_event_fifo_is_empty
		empty  => internal_QEV_TX_EMPTY
	);

--	quarter_event_fifo_read_enable <= (not quarter_event_fifo_is_empty) and (not internal_QEV_TX_FULL);
--	internal_QEV_TX_WR_EN <= quarter_event_fifo_read_enable;
--	quarter_event_fifo_read_enable <= internal_QEV_TX_RD_EN;
--	internal_QEV_TX_EMPTY <= quarter_event_fifo_is_empty;
--	internal_QEV_TX_DATA_BUS <= internal_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS;
	
end generate;	
---------------------------------------------------------------------------------------------------------------------

	QEB : entity work.quarter_event_builder
	generic map (
		CURRENT_PROTOCOL_FREEZE_DATE => CURRENT_PROTOCOL_FREEZE_DATE
	)
	port map (
		RESET                              => RESET,
		SCROD_SER								  => SCROD_SER,
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
		FEEDBACK_WILKINSON_COUNTER_C_R     => FEEDBACK_WILKINSON_COUNTER_C_R,
		FEEDBACK_SAMPLING_RATE_COUNTER_C_R => FEEDBACK_SAMPLING_RATE_COUNTER_C_R,
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
	internal_ADDRESS_OF_STARTING_WINDOW_IN_ASIC <= ADDRESS_OF_STARTING_WINDOW_IN_ASIC;
	internal_START_BUILDING_A_QUARTER_EVENT <= quarter_event_builder_enable and TRIGGER;
	quarter_event_builder_enable <= '1';
	DONE_BUILDING_A_QUARTER_EVENT <= internal_DONE_BUILDING_A_QUARTER_EVENT;
	CURRENTLY_BUILDING_A_QUARTER_EVENT <= internal_CURRENTLY_BUILDING_A_QUARTER_EVENT;
	Aurora_data_link_reset <= RESET;
	ASIC_START_WINDOW <= internal_ASIC_START_WINDOW;
	ASIC_END_WINDOW <= internal_ASIC_END_WINDOW;
	WINDOWS_TO_LOOK_BACK <= internal_WINDOWS_TO_LOOK_BACK;
	SAMPLING_RATE_FEEDBACK_GOAL    <= internal_SAMPLING_RATE_FEEDBACK_GOAL;
	WILKINSON_RATE_FEEDBACK_GOAL   <= internal_WILKINSON_RATE_FEEDBACK_GOAL;
	TRIGGER_WIDTH_FEEDBACK_GOAL    <= internal_TRIGGER_WIDTH_FEEDBACK_GOAL;
	SAMPLING_RATE_FEEDBACK_ENABLE  <= internal_SAMPLING_RATE_FEEDBACK_ENABLE;
	WILKINSON_RATE_FEEDBACK_ENABLE <= internal_WILKINSON_RATE_FEEDBACK_ENABLE;
	TRIGGER_WIDTH_FEEDBACK_ENABLE  <= internal_TRIGGER_WIDTH_FEEDBACK_ENABLE;
	DESIRED_DAC_SETTINGS <= internal_DESIRED_DAC_SETTINGS;


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

	
--	CHIPSCOPE_TRIG(31 downto 0) <= internal_QUARTER_EVENT_FIFO_INPUT_DATA_BUS;
--	CHIPSCOPE_TRIG(63 downto 32) <= internal_QUARTER_EVENT_FIFO_OUTPUT_DATA_BUS;
--	CHIPSCOPE_TRIG(64) <= internal_QUARTER_EVENT_FIFO_WRITE_ENABLE;
--	CHIPSCOPE_TRIG(65) <= quarter_event_fifo_read_enable;
--	CHIPSCOPE_TRIG(66) <= internal_START_BUILDING_A_QUARTER_EVENT;
--	CHIPSCOPE_TRIG(67) <= internal_QEV_TX_FULL;
--	CHIPSCOPE_TRIG(68) <= quarter_event_fifo_is_empty;
--	
--QEV : usb_ila
--  port map (
--    CONTROL => CONTROL4,
--    CLK => internal_USB_CHIPSCOPE_CLK,
--    TRIG0 => CHIPSCOPE_TRIG
--	);

end behavioral;
