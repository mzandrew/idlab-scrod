-- 2011-06 Xilinx coregen
-- 2011-06 kurtis
-- 2011-07 modified by mza
---------------------------------------------------------------------------------------------
--  Aurora Generator
--  Description: Sample Instantiation of a 1 4-byte lane module.
--               Only tests initialization in hardware.
---------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_MISC.all;
--use IEEE.STD_LOGIC_unsigned.all;
use ieee.numeric_std.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
-- synthesis translate_on

entity Aurora_IP_Core_A_example_design is
	generic(
		USE_CHIPSCOPE        : integer := 1;
		SIM_GTPRESET_SPEEDUP : integer := 1  --Set to 1 to speed up sim reset
	);
	port (
		-- User I/O
--		RESET             : in    std_logic;
		HARD_ERR          :   out std_logic;
		SOFT_ERR          :   out std_logic;
		ERR_COUNT         :   out std_logic_vector(0 to 7); -- is 0 to 7 a bug?
		LANE_UP           :   out std_logic;
		CHANNEL_UP        :   out std_logic;
--		INIT_CLK          : in    std_logic;
--		GT_RESET_IN       : in    std_logic;
		-- Clocks
		GTPD2_P    : in  std_logic;
		GTPD2_N    : in  std_logic;
		-- V5 I/O
		RXP               : in    std_logic;
		RXN               : in    std_logic;
		TXP               :   out std_logic;
		TXN               :   out std_logic;
		-- fiber optic transceiver 0 I/O
		FIBER_TRANSCEIVER_0_LASER_FAULT_DETECTED_IN_TRANSMITTER : in    std_logic;
		FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER : in    std_logic;
 		FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT  : in    std_logic;
		FIBER_TRANSCEIVER_0_DISABLE_MODULE                      :   out std_logic;
		-- fiber optic transceiver 1 I/O
		FIBER_TRANSCEIVER_1_DISABLE_MODULE                      :   out std_logic;
		-- other I/O
		board_clock_250MHz_P	: in    std_logic;
		board_clock_250MHz_N	: in    std_logic;
		LEDS                 :   out std_logic_vector(15 downto 0);
		MONITOR_HEADER       :   out std_logic_vector(15 downto 0)
	);
end Aurora_IP_Core_A_example_design;

architecture MAPPED of Aurora_IP_Core_A_example_design is
	attribute core_generation_info           : string;
	attribute core_generation_info of MAPPED : architecture is "Aurora_IP_Core_A,aurora_8b10b_v5_2,{backchannel_mode=Sidebands, c_aurora_lanes=1, c_column_used=None, c_gt_clock_1=GTPD2, c_gt_clock_2=None, c_gt_loc_1=X, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=X, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=1, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=4, c_line_rate=3.125, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=156.25, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex}";
-- Parameter Declarations --
	constant DLY : time := 1 ns;
-- External Register Declarations --
	signal HARD_ERR_Buffer    : std_logic;
	signal SOFT_ERR_Buffer    : std_logic;
	signal LANE_UP_Buffer     : std_logic;
	signal CHANNEL_UP_Buffer  : std_logic;
	signal TXP_Buffer         : std_logic;
	signal TXN_Buffer         : std_logic;
-- Internal Register Declarations --
	signal gt_reset_i         : std_logic; 
	signal system_reset_i     : std_logic;
-- Wire Declarations --
-- Stream TX Interface
	signal tx_d_i             : std_logic_vector(0 to 31);
	signal tx_src_rdy_n_i     : std_logic;
	signal tx_dst_rdy_n_i     : std_logic;
-- Stream RX Interface
	signal rx_d_i             : std_logic_vector(0 to 31);
	signal rx_src_rdy_n_i     : std_logic;
-- V5 Reference Clock Interface
	signal GTPD2_left_i      : std_logic;
-- Error Detection Interface
	signal hard_err_i       : std_logic;
	signal soft_err_i       : std_logic;
-- Status
	signal channel_up_i       : std_logic;
	signal lane_up_i          : std_logic;
-- Clock Compensation Control Interface
	signal warn_cc_i          : std_logic;
	signal do_cc_i            : std_logic;
-- System Interface
	signal pll_not_locked_i   : std_logic;
	signal user_clk_i         : std_logic;
	signal sync_clk_i         : std_logic;
	signal reset_i            : std_logic;
	signal power_down_i       : std_logic;
	signal loopback_i         : std_logic_vector(2 downto 0);
	signal tx_lock_i          : std_logic;
	signal gtpclkout_i        : std_logic;
	signal buf_gtpclkout_i    : std_logic;
--Frame check signals
	signal err_count_i      : std_logic_vector(0 to 7);
	signal ERR_COUNT_Buffer : std_logic_vector(0 to 7);
-- VIO Signals
	signal icon_to_vio_i       : std_logic_vector (35 downto 0);
	signal sync_in_i           : std_logic_vector (63 downto 0);
	signal sync_out_i          : std_logic_vector (63 downto 0);
	signal lane_up_i_i  	      : std_logic;
	signal tx_lock_i_i  	      : std_logic;
	signal lane_up_reduce_i    : std_logic;
	attribute ASYNC_REG        : string;
	attribute ASYNC_REG of tx_lock_i  : signal is "TRUE";
-------Kurtis additions------------
	signal internal_clock_250MHz : std_logic;
	signal internal_COUNTER : std_logic_vector(31 downto 0);
	signal INIT_CLK : std_logic;
	signal AURORA_RESET_IN : std_logic := '1';
	signal GT_RESET_IN     : std_logic := '1';
	signal rx_char_is_comma_i : std_logic_vector(3 downto 0);
	signal lane_init_state_i  : std_logic_vector(6 downto 0);
	signal reset_lanes_i : std_logic;
	signal tx_pe_data_i : std_logic_vector(31 downto 0);
	signal internal_PACKET_GENERATOR_ENABLE : std_logic_vector(1 downto 0);
	signal internal_DATA_GENERATOR_STATE : std_logic_vector(2 downto 0);
	signal internal_VARIABLE_DELAY_BETWEEN_EVENTS : std_logic_vector(31 downto 0);
-----------------------------------
-- Component Declarations --
	component IBUFDS
	port (
		O : out std_ulogic;
		I : in std_ulogic;
		IB : in std_ulogic
	);
	end component;

	component IBUFGDS
	port (
		O  :  out STD_ULOGIC;
		I  : in STD_ULOGIC;
		IB : in STD_ULOGIC
	);
	end component;

	component BUFIO2 
	generic(
		DIVIDE_BYPASS : boolean := TRUE;  -- TRUE, FALSE
		DIVIDE        : integer := 1;     -- {1..8}
		I_INVERT      : boolean := FALSE; -- TRUE, FALSE
		USE_DOUBLER   : boolean := FALSE  -- TRUE, FALSE
	);
	port(
		DIVCLK       : out std_ulogic;
		IOCLK        : out std_ulogic;
		SERDESSTROBE : out std_ulogic;
		I            : in  std_ulogic
	);
	end component;

	component IBUFG
	port (
		O : out std_ulogic;
		I : in  std_ulogic
	);
	end component;

	component Aurora_IP_Core_A_CLOCK_MODULE
	port (
		GT_CLK                  : in std_logic;
		GT_CLK_LOCKED           : in std_logic;
		USER_CLK                : out std_logic;
		SYNC_CLK                : out std_logic;
		PLL_NOT_LOCKED          : out std_logic
	);
	end component;

	component Aurora_IP_Core_A_RESET_LOGIC
	port (
		RESET                  : in std_logic;
		USER_CLK               : in std_logic;
		INIT_CLK               : in std_logic;
		GT_RESET_IN            : in std_logic;
		TX_LOCK_IN             : in std_logic;
		PLL_NOT_LOCKED         : in std_logic;
		SYSTEM_RESET           : out std_logic;
		GT_RESET_OUT           : out std_logic
	);
	end component;

	component Aurora_IP_Core_A
	generic (
		SIM_GTPRESET_SPEEDUP : integer := 1
	);
	port (
		-- LocalLink TX Interface
		TX_D             : in std_logic_vector(0 to 31);
		TX_SRC_RDY_N     : in std_logic;
		TX_DST_RDY_N     : out std_logic;
		-- LocalLink RX Interface
		RX_D             : out std_logic_vector(0 to 31);
		RX_SRC_RDY_N     : out std_logic;
		-- V5 Serial I/O
		RXP              : in std_logic;
		RXN              : in std_logic;
		TXP              : out std_logic;
		TXN              : out std_logic;
		-- V5 Reference Clock Interface
		GTPD2    : in std_logic;
		-- Error Detection Interface
		HARD_ERR       : out std_logic;
		SOFT_ERR       : out std_logic;
		-- Status
		CHANNEL_UP       : out std_logic;
		LANE_UP          : out std_logic;
		-- Clock Compensation Control Interface
		WARN_CC          : in std_logic;
		DO_CC            : in std_logic;
		-- System Interface
		USER_CLK         : in std_logic;
		SYNC_CLK         : in std_logic;
		GT_RESET         : in std_logic;
		RESET            : in std_logic;
		POWER_DOWN       : in std_logic;
		LOOPBACK         : in std_logic_vector(2 downto 0);
		GTPCLKOUT        : out std_logic;
		TX_LOCK          : out std_logic;
		--Kurtis added
		RX_CHAR_IS_COMMA : out std_logic_vector(3 downto 0);
		LANE_INIT_STATE  : out std_logic_vector(6 downto 0);
		RESET_LANES      : out std_logic;
		TX_PE_DATA			: out std_logic_vector(31 downto 0)
	);
	end component;

	component Aurora_IP_Core_A_STANDARD_CC_MODULE
	port (
		-- Clock Compensation Control Interface
		WARN_CC        : out std_logic;
		DO_CC          : out std_logic;
		-- System Interface
		PLL_NOT_LOCKED : in std_logic;
		USER_CLK       : in std_logic;
		RESET          : in std_logic
	);
	end component;

--	component Aurora_IP_Core_A_FRAME_GEN
--	port (
--		-- User Interface
--		TX_D            : out  std_logic_vector(0 to 31); 
--		TX_SRC_RDY_N    : out  std_logic;
--		TX_DST_RDY_N    : in   std_logic;  
--		-- System Interface
--		USER_CLK        : in  std_logic;   
--		RESET           : in  std_logic;
--		CHANNEL_UP      : in  std_logic
--	); 
--	end component;
 
	component Packet_Generator is
	port ( 
		TX_DST_RDY_N 	: in  STD_LOGIC;
		USER_CLK 		: in  STD_LOGIC;
		RESET 			: in  STD_LOGIC;
		CHANNEL_UP 		: in  STD_LOGIC;
		ENABLE 			: in  STD_LOGIC_VECTOR(1 downto 0);
		TX_SRC_RDY_N 	: out  STD_LOGIC;
		TX_D 				: out  STD_LOGIC_VECTOR (31 downto 0);
		DATA_GENERATOR_STATE : out STD_LOGIC_VECTOR(2 downto 0);
		VARIABLE_DELAY_BETWEEN_EVENTS : in STD_LOGIC_VECTOR(31 downto 0)
	);
	end component;	
  
--	component Aurora_IP_Core_A_FRAME_CHECK
	component Packet_Receiver
	port (
		-- User Interface
		RX_D            : in    std_logic_vector(0 to 31); 
		RX_SRC_RDY_N    : in    std_logic; 
		-- System Interface
		USER_CLK        : in    std_logic;   
		RESET           : in    std_logic;
		CHANNEL_UP      : in    std_logic;
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
		start_event_transfer               :   out std_logic;
		acknowledge_start_event_transfer   : in    std_logic;
		ERR_COUNT       :   out std_logic_vector(0 to 7)
	);
	end component;

  -------------------------------------------------------------------
  --  ICON core component declaration
  -------------------------------------------------------------------
	component s6_icon
	port (
		control0    :   out std_logic_vector(35 downto 0)
	);
	end component;

  -------------------------------------------------------------------
  --  VIO core component declaration
  -------------------------------------------------------------------
	component s6_vio
	port (
		control     : in    std_logic_vector(35 downto 0);
		clk         : in    std_logic;
		sync_in     : in    std_logic_vector(63 downto 0);
		sync_out    : out   std_logic_vector(63 downto 0)
	);
	end component;
                                                                                
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
	signal chipscope_aurora_reset : std_logic;
	signal spill_active    : std_logic;
	signal recharge_active : std_logic;
--	signal stupid_counter : std_logic_vector(31 downto 0);
	signal transmit_always : std_logic;
	signal should_transmit : std_logic;
begin
--	internal_acknowledge_start_event_transfer <= '0';
	lane_up_reduce_i    <=  lane_up_i;

	HARD_ERR    <= HARD_ERR_Buffer;
	SOFT_ERR    <= SOFT_ERR_Buffer;
	ERR_COUNT   <= ERR_COUNT_Buffer;
	LANE_UP     <= LANE_UP_Buffer;
	CHANNEL_UP  <= CHANNEL_UP_Buffer;
	TXP         <= TXP_Buffer;
	TXN         <= TXN_Buffer;

	INIT_CLK <= internal_COUNTER(2);
	FIBER_TRANSCEIVER_0_DISABLE_MODULE <= reset_i;	
	FIBER_TRANSCEIVER_1_DISABLE_MODULE <= '1';

------------------------------------------
	LEDS(0) <= LANE_UP_Buffer;
	LEDS(1) <= CHANNEL_UP_Buffer;
	LEDS(2) <= HARD_ERR_Buffer;
	LEDS(3) <= SOFT_ERR_Buffer;

	LEDS(4) <= FIBER_TRANSCEIVER_0_LASER_FAULT_DETECTED_IN_TRANSMITTER;
	LEDS(5) <= FIBER_TRANSCEIVER_0_LOSS_OF_SIGNAL_DETECTED_BY_RECEIVER;
	LEDS(6) <= tx_lock_i;
	LEDS(7) <= pll_not_locked_i;
--	LEDS(7) <= internal_COUNTER(26);

	LEDS(8) <= FIBER_TRANSCEIVER_0_MODULE_DEFINITION_0_LOW_IF_PRESENT;
	LEDS(11 downto 9) <= internal_DATA_GENERATOR_STATE;

	LEDS(15 downto 12) <= internal_number_of_sent_events(3 downto 0);
--	LEDS(15 downto 12) <= ERR_COUNT_Buffer(0 downto 3);

	MONITOR_HEADER(0) <= tx_src_rdy_n_i;
	MONITOR_HEADER(15 downto 1) <= (others => '0');
------------------------------------------
	process(internal_clock_250MHz, reset_i)
		variable counter_250_MHz  : integer range 0 to  250 := 0;
		variable counter_1_MHz    : integer range 0 to 1000 := 0;
		variable counter_1_kHz    : integer range 0 to 1000 := 0;
		variable counter_1_Hz     : integer range 0 to 3600 := 0;
		variable spill_counter            : integer range 0 to 60 := 0;
		constant spill_counter_maximum    : integer range 0 to 60 := 9;
		variable recharge_counter         : integer range 0 to 60 := 0;
		constant recharge_counter_maximum : integer range 0 to 60 := 40;
	begin
		if (reset_i = '1') then
			spill_active    <= '1';
			recharge_active <= '0';
			counter_250_MHz  := 0;
			counter_1_MHz    := 0;
			counter_1_kHz    := 0;
			counter_1_Hz     := 0;
			spill_counter    := 0;
			recharge_counter := 0;
		elsif rising_edge(internal_clock_250MHz) then
			counter_250_MHz := counter_250_MHz + 1;
			if (counter_250_MHz > 249) then
				counter_250_MHz := 0;
				counter_1_MHz := counter_1_MHz + 1;
			end if;
			if (counter_1_MHz > 999) then
				counter_1_MHz := 0;
				counter_1_kHz := counter_1_kHz + 1;
			end if;
			if (counter_1_kHz > 999) then
				counter_1_kHz := 0;
				counter_1_Hz := counter_1_Hz + 1;
--				stupid_counter <= std_logic_vector(unsigned(stupid_counter) + 1);
				if (spill_counter < spill_counter_maximum) then
					spill_counter := spill_counter + 1;
				else
					spill_active    <= '0';
					recharge_active <= '1';
					if (recharge_counter < recharge_counter_maximum) then
						recharge_counter := recharge_counter + 1;
					else
						spill_active    <= '1';
						recharge_active <= '0';
						spill_counter    := 0;
						recharge_counter := 0;
					end if;
				end if;
			end if;
		end if;
	end process;
	process(internal_clock_250MHz)
		variable internal_COUNTER  : integer range 0 to 250000000 := 0;
	begin
--		AURORA_RESET_IN <= '1'; -- aurora
--		GT_RESET_IN     <= '1'; -- aurora
		if (rising_edge(internal_clock_250MHz)) then
			internal_COUNTER := internal_COUNTER + 1;
			if (internal_COUNTER > 200000000) then
				AURORA_RESET_IN <= '0'; -- aurora
				GT_RESET_IN     <= '0'; -- aurora
			end if;
		end if;
	end process;
--	process(internal_COUNTER(27)) begin
--		if rising_edge(internal_COUNTER(27)) then
--			RESET <= '0';
--			GT_RESET_IN <= '0';
--		end if;
--	end process;
---------------------------------------
	should_transmit <= spill_active or transmit_always;
	internal_PACKET_GENERATOR_ENABLE(1) <= should_transmit;

	IBUFGDS_i :  IBUFGDS port map (I  => board_clock_250MHz_P, IB => board_clock_250MHz_N, O  => internal_clock_250MHz);
	IBUFDS_i  :  IBUFDS  port map (I  => GTPD2_P, IB => GTPD2_N, O  => GTPD2_left_i);

	BUFIO2_i : BUFIO2 generic map (
		DIVIDE         =>      1,
		DIVIDE_BYPASS  =>      TRUE
	) port map (
		I              =>      gtpclkout_i,
		DIVCLK         =>      buf_gtpclkout_i,
		IOCLK          =>      open,
		SERDESSTROBE   =>      open
	);

	-- Instantiate a clock module for clock division
	clock_module_i : Aurora_IP_Core_A_CLOCK_MODULE
	port map (
		GT_CLK          => buf_gtpclkout_i,
		GT_CLK_LOCKED   => tx_lock_i,
		USER_CLK        => user_clk_i,
		SYNC_CLK        => sync_clk_i,
		PLL_NOT_LOCKED  => pll_not_locked_i
	);

    -- Register User I/O --
    -- Register User Outputs from core.
	process (user_clk_i)
	begin
		if (user_clk_i 'event and user_clk_i = '1') then
			HARD_ERR_Buffer    <= hard_err_i;
			SOFT_ERR_Buffer    <= soft_err_i;
			ERR_COUNT_Buffer   <= err_count_i;
			LANE_UP_Buffer     <= lane_up_i;
			CHANNEL_UP_Buffer  <= channel_up_i;
		end if;
	end process;

    -- System Interface
	power_down_i     <= '0';
	loopback_i       <= "000";

	-- Connect a frame checker to the user interface
--	frame_check_i : Aurora_IP_Core_A_FRAME_CHECK

	frame_check_i : Packet_Receiver
	port map (
		-- User Interface
		RX_D            =>  rx_d_i, 
		RX_SRC_RDY_N    =>  rx_src_rdy_n_i,  
		-- System Interface
		USER_CLK        =>  user_clk_i,   
		RESET           =>  reset_i,
		CHANNEL_UP      =>  channel_up_i,
		WRONG_PACKET_SIZE_COUNTER => internal_WRONG_PACKET_SIZE_COUNTER,
		WRONG_PACKET_TYPE_COUNTER => internal_WRONG_PACKET_TYPE_COUNTER,
		WRONG_PROTOCOL_FREEZE_DATE_COUNTER => internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER,
		WRONG_SCROD_ADDRESSED_COUNTER => internal_WRONG_SCROD_ADDRESSED_COUNTER,
		WRONG_CHECKSUM_COUNTER => internal_WRONG_CHECKSUM_COUNTER,
		WRONG_FOOTER_COUNTER => internal_WRONG_FOOTER_COUNTER,
		UNKNOWN_ERROR_COUNTER => internal_UNKNOWN_ERROR_COUNTER,
		MISSING_ACKNOWLEDGEMENT_COUNTER => internal_MISSING_ACKNOWLEDGEMENT_COUNTER,
		number_of_sent_events => internal_number_of_sent_events,
		NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR => internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR,
		resynchronizing_with_header => internal_resynchronizing_with_header,
		start_event_transfer => internal_start_event_transfer,
		acknowledge_start_event_transfer => internal_acknowledge_start_event_transfer,
		ERR_COUNT       =>  err_count_i
	);

--    --Connect a frame generator to the user interface
--    frame_gen_i : Aurora_IP_Core_A_FRAME_GEN
--    port map
--    (
--        -- User Interface
--        TX_D            =>  tx_d_i,
--        TX_SRC_RDY_N    =>  tx_src_rdy_n_i,
--        TX_DST_RDY_N    =>  tx_dst_rdy_n_i,    
--
--
--        -- System Interface
--        USER_CLK        =>  user_clk_i,
--        RESET           =>  reset_i,
--        CHANNEL_UP      =>  channel_up_i
--    ); 

	Packet_Generator_A : Packet_Generator
	port map
	( 
		TX_DST_RDY_N 	=> tx_dst_rdy_n_i,
		USER_CLK 		=> user_clk_i,
		RESET 			=> reset_i,
		CHANNEL_UP 		=> channel_up_i,
		ENABLE 			=> internal_PACKET_GENERATOR_ENABLE,
		TX_SRC_RDY_N 	=> tx_src_rdy_n_i,
		TX_D 				=> tx_d_i,
		DATA_GENERATOR_STATE => internal_DATA_GENERATOR_STATE,
		VARIABLE_DELAY_BETWEEN_EVENTS => internal_VARIABLE_DELAY_BETWEEN_EVENTS
	);

    -- Module Instantiations --
	aurora_module_i : Aurora_IP_Core_A
	generic map(
		SIM_GTPRESET_SPEEDUP => SIM_GTPRESET_SPEEDUP
	)
	port map (
		-- LocalLink TX Interface
		TX_D             => tx_d_i,
		TX_SRC_RDY_N     => tx_src_rdy_n_i,
		TX_DST_RDY_N     => tx_dst_rdy_n_i,
		-- LocalLink RX Interface
		RX_D             => rx_d_i,
		RX_SRC_RDY_N     => rx_src_rdy_n_i,
		-- V5 Serial I/O
		RXP              => RXP,
		RXN              => RXN,
		TXP              => TXP_Buffer,
		TXN              => TXN_Buffer,
		-- V5 Reference Clock Interface
		GTPD2    => GTPD2_left_i,
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
		USER_CLK         => user_clk_i,
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

	standard_cc_module_i : Aurora_IP_Core_A_STANDARD_CC_MODULE
		port map (
		-- Clock Compensation Control Interface
		WARN_CC        => warn_cc_i,
		DO_CC          => do_cc_i,
		-- System Interface
		PLL_NOT_LOCKED => pll_not_locked_i,
		USER_CLK       => user_clk_i,
		RESET          => not(lane_up_reduce_i)
	);

	reset_logic_i : Aurora_IP_Core_A_RESET_LOGIC
	port map (
		RESET            => AURORA_RESET_IN,
		USER_CLK         => user_clk_i,
		INIT_CLK         => INIT_CLK,
		GT_RESET_IN      => GT_RESET_IN,
		TX_LOCK_IN       => tx_lock_i,
		PLL_NOT_LOCKED   => pll_not_locked_i,
		SYSTEM_RESET     => system_reset_i,
		GT_RESET_OUT     => gt_reset_i
	);

	chipscope1 : if USE_CHIPSCOPE = 1 generate
		lane_up_i_i    <=  lane_up_i;
		tx_lock_i_i    <= '1'  and tx_lock_i;
		-- aurora status:
		sync_in_i(6 downto 0) <= lane_init_state_i;
		sync_in_i(7)          <= lane_up_i_i;
		sync_in_i(8)          <= channel_up_i;
--		sync_in_i(9)          <= pll_not_locked_i;
		-- data generator status:
		sync_in_i(11 downto 9) <= internal_DATA_GENERATOR_STATE;
		-- data receiver status:
		sync_in_i(19 downto 12) <= internal_NUMBER_OF_WORDS_IN_THIS_PACKET_RECEIVED_SO_FAR(7 downto 0);
		sync_in_i(20)           <= internal_resynchronizing_with_header;
		sync_in_i(21)           <= internal_start_event_transfer;
		sync_in_i(22)           <= tx_src_rdy_n_i;
		sync_in_i(23)           <= reset_i;
		sync_in_i(27 downto 24) <= internal_WRONG_PACKET_SIZE_COUNTER(3 downto 0);
		sync_in_i(31 downto 28) <= internal_WRONG_PACKET_TYPE_COUNTER(3 downto 0);
		sync_in_i(35 downto 32) <= internal_WRONG_PROTOCOL_FREEZE_DATE_COUNTER(3 downto 0);
		sync_in_i(39 downto 36) <= internal_WRONG_SCROD_ADDRESSED_COUNTER(3 downto 0);
		sync_in_i(43 downto 40) <= internal_WRONG_CHECKSUM_COUNTER(3 downto 0);
		sync_in_i(47 downto 44) <= internal_WRONG_FOOTER_COUNTER(3 downto 0);
		sync_in_i(51 downto 48) <= internal_UNKNOWN_ERROR_COUNTER(3 downto 0);
		sync_in_i(55 downto 52) <= internal_number_of_sent_events(3 downto 0);
		sync_in_i(59 downto 56) <= internal_MISSING_ACKNOWLEDGEMENT_COUNTER(3 downto 0);
		sync_in_i(60)           <= spill_active;
		sync_in_i(61)           <= recharge_active;
--		sync_in_i(63 downto 62) <= stupid_counter(1 downto 0);
		sync_in_i(63 downto 62) <= (others => '0');
		
		internal_acknowledge_start_event_transfer <= sync_out_i(35);

		-------------------------------------------------------------------
		--  ICON core instance
		-------------------------------------------------------------------
		i_icon : s6_icon
		port map (
			control0    => icon_to_vio_i
		);

		-------------------------------------------------------------------
		--  VIO core instance
		-------------------------------------------------------------------
		i_vio : s6_vio
		port map (
			control   => icon_to_vio_i,
			clk       => user_clk_i,
			sync_in   => sync_in_i,
			sync_out  => sync_out_i
		);
	end generate chipscope1;

	no_chipscope1 : if USE_CHIPSCOPE = 0 generate
		sync_in_i  <= (others=>'0');
	end generate no_chipscope1;

	chipscope2 : if USE_CHIPSCOPE = 1 generate
		-- Shared VIO Outputs
		reset_i <= system_reset_i or chipscope_aurora_reset;
		chipscope_aurora_reset                 <= sync_out_i(0);
		transmit_always                        <= sync_out_i(1);
		internal_PACKET_GENERATOR_ENABLE(0)    <= sync_out_i(2);
		internal_VARIABLE_DELAY_BETWEEN_EVENTS <= sync_out_i(34 downto 3);
	end generate chipscope2;

	no_chipscope2 : if USE_CHIPSCOPE = 0 generate
		-- Shared VIO Outputs
		reset_i <= system_reset_i;
	end generate no_chipscope2;

end MAPPED;
