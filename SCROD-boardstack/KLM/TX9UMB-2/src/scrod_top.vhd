----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:20:38 10/25/2012 
-- Design Name: 
-- Module Name:    scrod_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;
    use work.tdc_pkg.all;

--use work.asic_definitions_irs2_carrier_revA.all;
--use work.CarrierRevA_DAC_definitions.all;

entity scrod_top is
	Port(
		BOARD_CLOCKP                : in  STD_LOGIC;
		BOARD_CLOCKN                : in  STD_LOGIC;
		LEDS                        : out STD_LOGIC_VECTOR(15 downto 0);
		------------------FTSW pins------------------
		RJ45_ACK_P                  : out std_logic;
		RJ45_ACK_N                  : out std_logic;			  
		RJ45_TRG_P                  : in std_logic;
		RJ45_TRG_N                  : in std_logic;			  			  
		RJ45_RSV_P                  : in std_logic;-- should be output 
		RJ45_RSV_N                  : in std_logic;
		RJ45_CLK_P                  : in std_logic;
		RJ45_CLK_N                  : in std_logic;
		---------Jumper for choosing FTSW clock------
		MONITOR_INPUT               : in  std_logic_vector(0 downto 0);
		
		----------------------------------------------
		------------Fiberoptic Pins-------------------
		----------------------------------------------
		FIBER_0_RXP                 : in  STD_LOGIC;
		FIBER_0_RXN                 : in  STD_LOGIC;
		FIBER_1_RXP                 : in  STD_LOGIC;
		FIBER_1_RXN                 : in  STD_LOGIC;
		FIBER_0_TXP                 : out STD_LOGIC;
		FIBER_0_TXN                 : out STD_LOGIC;
		FIBER_1_TXP                 : out STD_LOGIC;
		FIBER_1_TXN                 : out STD_LOGIC;
		FIBER_REFCLKP               : in  STD_LOGIC;
		FIBER_REFCLKN               : in  STD_LOGIC;
		FIBER_0_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_1_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_0_LINK_UP             : out STD_LOGIC;
		FIBER_1_LINK_UP             : out STD_LOGIC;
		FIBER_0_LINK_ERR            : out STD_LOGIC;
		FIBER_1_LINK_ERR            : out STD_LOGIC;
		---------------------------------------------
		------------------USB pins-------------------
		---------------------------------------------
		USB_IFCLK                   : in  STD_LOGIC;
		USB_CTL0                    : in  STD_LOGIC;
		USB_CTL1                    : in  STD_LOGIC;
		USB_CTL2                    : in  STD_LOGIC;
		USB_FDD                     : inout STD_LOGIC_VECTOR(15 downto 0);
		USB_PA0                     : out STD_LOGIC;
		USB_PA1                     : out STD_LOGIC;
		USB_PA2                     : out STD_LOGIC;
		USB_PA3                     : out STD_LOGIC;
		USB_PA4                     : out STD_LOGIC;
		USB_PA5                     : out STD_LOGIC;
		USB_PA6                     : out STD_LOGIC;
		USB_PA7                     : in  STD_LOGIC;
		USB_RDY0                    : out STD_LOGIC;
		USB_RDY1                    : out STD_LOGIC;
		USB_WAKEUP                  : in  STD_LOGIC;
		USB_CLKOUT		             : in  STD_LOGIC;
		
		--MB Specific Signals
		EX_TRIGGER1						 : out STD_LOGIC;
		EX_TRIGGER2						 : out STD_LOGIC;
		
		--Global Bus Signals
		
		--ASIC related
		
		--BUS A Specific Signals
		BUS_REGCLR						 : out STD_LOGIC;
--		BUSA_REGCLR						 : out STD_LOGIC;
--		BUSA_SCLK						 : out STD_LOGIC;
		BUSA_WR_ADDRCLR				 : out STD_LOGIC;
		BUSA_RD_ENA						 : out STD_LOGIC;
		BUSA_RD_ROWSEL_S				 : out STD_LOGIC_VECTOR(2 downto 0);
		BUSA_RD_COLSEL_S				 : out STD_LOGIC_VECTOR(5 downto 0);
		BUSA_CLR							 : out STD_LOGIC;
--		BUSA_START						 : out STD_LOGIC;
		BUSA_RAMP						 : out STD_LOGIC;
		BUSA_SAMPLESEL_S				 : out STD_LOGIC_VECTOR(4 downto 0);
		BUSA_SR_CLEAR					 : out STD_LOGIC;
		BUSA_SR_SEL						 : out STD_LOGIC;
		BUSA_DO							 : in STD_LOGIC_VECTOR(15 downto 0);
		
		--Bus B Specific Signals
--		BUSB_REGCLR						 : out STD_LOGIC;
--		BUSB_SCLK						 : out STD_LOGIC;
		BUSB_WR_ADDRCLR				 : out STD_LOGIC;
		BUSB_RD_ENA						 : out STD_LOGIC;
		BUSB_RD_ROWSEL_S				 : out STD_LOGIC_VECTOR(2 downto 0);
		BUSB_RD_COLSEL_S				 : out STD_LOGIC_VECTOR(5 downto 0);
		BUSB_CLR							 : out STD_LOGIC;
--		BUSB_START						 : out STD_LOGIC;
		BUSB_RAMP						 : out STD_LOGIC;
		BUSB_SAMPLESEL_S				 : out STD_LOGIC_VECTOR(4 downto 0);
		BUSB_SR_CLEAR					 : out STD_LOGIC;
		BUSB_SR_SEL						 : out STD_LOGIC;
		BUSB_DO							 : in STD_LOGIC_VECTOR(15 downto 0);
		
		--ASIC DAC Update Signals
		SIN								 : out STD_LOGIC_VECTOR(9 downto 0);
		PCLK								 : out STD_LOGIC_VECTOR(9 downto 0);
		SHOUT						 	    : in STD_LOGIC_VECTOR(9 downto 0);
		
		--Sampling Signals
--		SSTIN								 : out STD_LOGIC_VECTOR(9 downto 0);
--		SSPIN								 : out STD_LOGIC_VECTOR(9 downto 0);
--		WR_STRB 							 : out STD_LOGIC_VECTOR(9 downto 0);
--		WR_ADVCLK 						 : out STD_LOGIC_VECTOR(9 downto 0);
--		WR_ENA 						 	 : out STD_LOGIC_VECTOR(9 downto 0);
		
		--Digitization Signals
		
		--Serial Readout Signals
		SR_CLOCK							 : out STD_LOGIC_VECTOR(9 downto 0);
		SAMPLESEL_ANY 					 : out STD_LOGIC_VECTOR(9 downto 0);
		
		-- HV DAC
		BUSA_SCK_DAC		          : out STD_LOGIC;
		BUSA_DIN_DAC		          : out STD_LOGIC;

		BUSB_SCK_DAC		          : out STD_LOGIC;
		BUSB_DIN_DAC		          : out STD_LOGIC;
		TDC_CS_DAC                  : out STD_LOGIC_VECTOR(9 downto 0);
--		HV_DISABLE                  : out STD_LOGIC;
		TDC_AMUX_S                  : out STD_LOGIC_VECTOR(3 downto 0);
		TOP_AMUX_S                  : out STD_LOGIC_VECTOR(3 downto 0);
		
		--TRIGGER SIGNALS
		TDC1_TRG_16						 : in STD_LOGIC;
		TDC1_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC2_TRG_16						 : in STD_LOGIC;
		TDC2_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC3_TRG_16						 : in STD_LOGIC;
		TDC3_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC4_TRG_16						 : in STD_LOGIC;
		TDC4_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC5_TRG_16						 : in STD_LOGIC;
		TDC5_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC6_TRG_16						 : in STD_LOGIC;
		TDC6_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC7_TRG_16						 : in STD_LOGIC;
		TDC7_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC8_TRG_16						 : in STD_LOGIC;
		TDC8_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC9_TRG_16						 : in STD_LOGIC;
		TDC9_TRG							 : in STD_LOGIC_VECTOR(3 downto 0);
		
		TDC10_TRG_16					 : in STD_LOGIC;
		TDC10_TRG						 : in STD_LOGIC_VECTOR(3 downto 0);
		
		--New Stuff for TargetX:
		--RAM:
		BUS_RAM_RS_A						: out STD_LOGIC_VECTOR(10 downto 0);                       
		RAM1_CE1							 	: out STD_LOGIC :='1';                                         
		RAM1_CE2							   : out STD_LOGIC := '0';                           
		RAM1_OE				            : out std_logic := '1';                       
		RAM1_WE				            : out std_logic := '1';                         
		RAM2_CE1				            : out STD_LOGIC := '1';                     
		RAM2_CE2				            : out STD_LOGIC := '0';                       
		RAM2_OE				            : out std_logic := '1';		
		RAM2_WE				            : out std_logic := '1';                       

		SCLK								: out STD_LOGIC_VECTOR(9 downto 0);
		WL_CLK_N								: out STD_LOGIC_VECTOR(9 downto 0);
		WL_CLK_P								: out STD_LOGIC_VECTOR(9 downto 0);
		WR1_ENA								: out STD_LOGIC_VECTOR(9 downto 0);
		WR2_ENA								: out STD_LOGIC_VECTOR(9 downto 0);

--		BUS_REGCLR						: in STD_LOGIC;
		SSTIN_N								 : out STD_LOGIC_VECTOR(9 downto 0);
		SSTIN_P								 : out STD_LOGIC_VECTOR(9 downto 0);
		
		SCL_MON								 : out STD_LOGIC;
		SDA_MON								 : inout STD_LOGIC;
		TDC_DONE								: in STD_LOGIC_VECTOR(9 downto 0);
		TDC_MON_TIMING						: in STD_LOGIC_VECTOR(9 downto 0)

	);
end scrod_top;

architecture Behavioral of scrod_top is
	signal internal_BOARD_CLOCK      : std_logic;
	signal internal_CLOCK_50MHz_BUFG : std_logic;
	signal internal_CLOCK_4MHz_BUFG  : std_logic;
	signal internal_CLOCK_ENABLE_I2C : std_logic;
	signal internal_CLOCK_SST_BUFG   : std_logic;
	signal internal_CLOCK_8xSST_BUFG : std_logic;
	signal internal_CLOCK_8xSST_OBUFDS_N : std_logic_vector(9 downto 0);
	signal internal_CLOCK_8xSST_OBUFDS_P : std_logic_vector(9 downto 0);

	signal internal_OUTPUT_REGISTERS : GPR;
	signal internal_INPUT_REGISTERS  : RR;
	signal i_register_update         : RWT;
	
	--Trigger readout
	signal internal_SOFTWARE_TRIGGER : std_logic;
	signal internal_HARDWARE_TRIGGER : std_logic;
	signal internal_TRIGGER : std_logic;
	signal internal_TRIGGER_OUT : std_logic;
	
	--Vetoes for the triggers
	signal internal_SOFTWARE_TRIGGER_VETO : std_logic;
	signal internal_HARDWARE_TRIGGER_ENABLE : std_logic;
	
	--SCROD ID and REVISION Number
	signal internal_SCROD_REV_AND_ID_WORD        : STD_LOGIC_VECTOR(31 downto 0);
   signal internal_EVENT_NUMBER_TO_SET          : STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); --This is what event number will be set to when set event number is enabled
   signal internal_SET_EVENT_NUMBER             : STD_LOGIC;
   signal internal_EVENT_NUMBER                 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

	--Event builder + readout interface waveform data flow related
	signal internal_WAVEFORM_FIFO_DATA_OUT       : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_WAVEFORM_FIFO_EMPTY          : std_logic := '0';
	signal internal_WAVEFORM_FIFO_DATA_VALID     : std_logic := '0';
	signal internal_WAVEFORM_FIFO_READ_CLOCK     : std_logic := '0';
	signal internal_WAVEFORM_FIFO_READ_ENABLE    : std_logic := '0';
	signal internal_WAVEFORM_PACKET_BUILDER_BUSY	: std_logic := '0';
	signal internal_WAVEFORM_PACKET_BUILDER_VETO : std_logic := '0';
	
	signal internal_EVTBUILD_FIFO_DATA_OUT					: std_logic_vector(31 downto 0) := (others => '0');
	signal internal_EVTBUILD_FIFO_EMPTY          : std_logic := '0';
	signal internal_EVTBUILD_FIFO_DATA_VALID     : std_logic := '0';
	signal internal_EVTBUILD_FIFO_READ_CLOCK     : std_logic := '0';
	signal internal_EVTBUILD_FIFO_READ_ENABLE    : std_logic := '0';
	
	signal internal_READOUT_DATA_OUT					: std_logic_vector(31 downto 0) := (others => '0');
	signal internal_READOUT_DATA_VALID				: std_logic := '0';
	signal internal_READOUT_EMPTY						: std_logic := '0';
	signal internal_READOUT_READ_CLOCK     : std_logic := '0';
	signal internal_READOUT_READ_ENABLE				: std_logic := '0';
	
	signal internal_EVTBUILD_DATA_OUT       : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_EVTBUILD_EMPTY          : std_logic := '0';
	signal internal_EVTBUILD_DATA_VALID     : std_logic := '0';
	signal internal_EVTBUILD_READ_CLOCK     : std_logic := '0';
	signal internal_EVTBUILD_READ_ENABLE    : std_logic := '0';
	signal internal_EVTBUILD_PACKET_BUILDER_BUSY	: std_logic := '0';
	signal internal_EVTBUILD_PACKET_BUILDER_VETO : std_logic := '0';
	signal internal_EVTBUILD_START_BUILDING_EVENT : std_logic := '0';
	signal internal_EVTBUILD_DONE_SENDING_EVENT : std_logic := '0';
	
	--ASIC TRIGGER CONTROL
	signal internal_TRIGGER_ALL : std_logic := '0';
	signal internal_TRIGGER_ASIC : std_logic_vector(9 downto 0) := "0000000000";
	signal internal_TRIGGER_ASIC_control_word : std_logic_vector(9 downto 0) := "0000000000";
	signal internal_TRIGCOUNT_ena : std_logic := '0';
	signal internal_TRIGCOUNT_rst : std_logic := '0';
	constant TRIGGER_SCALER_BIT_WIDTH      : integer := 16;
	type TARGET6_TRIGGER_SCALERS is array(9 downto 0) of std_logic_vector(TRIGGER_SCALER_BIT_WIDTH-1 downto 0);	
	signal internal_TRIGCOUNT_scaler : TARGET6_TRIGGER_SCALERS;
	signal internal_READ_ENABLE_TIMER : std_logic_vector (9 downto 0);
	signal internal_TXDCTRIG : tb_vec_type;-- All triger bits from all ASICs are here
	
	--ASIC DAC CONTROL
	signal internal_DAC_CONTROL_UPDATE : std_logic := '0';
	signal internal_DAC_CONTROL_REG_DATA : std_logic_vector(18 downto 0) := (others => '0');
	signal internal_DAC_CONTROL_TDCNUM : std_logic_vector(9 downto 0) := (others => '0');
	signal internal_DAC_CONTROL_SIN : std_logic := '0';
	signal internal_DAC_CONTROL_SCLK : std_logic := '0';
	signal internal_DAC_CONTROL_PCLK : std_logic := '0';
	signal internal_DAC_CONTROL_LOAD_PERIOD : std_logic_vector(15 downto 0)  := (others => '0');
	signal internal_DAC_CONTROL_LATCH_PERIOD : std_logic_vector(15 downto 0)  := (others => '0');
	signal internal_WL_CLK_N						: std_logic := '0';

	--READOUT CONTROL
	signal internal_READCTRL_trigger : std_logic := '0';
	signal internal_READCTRL_trig_delay : std_logic_vector(11 downto 0) := (others => '0');
	signal internal_READCTRL_dig_offset : std_logic_vector(8 downto 0) := (others => '0');
	signal internal_READCTRL_win_num_to_read : std_logic_vector(8 downto 0) := (others => '0');
	signal internal_READCTRL_asic_enable_bits : std_logic_vector(9 downto 0) := (others => '0');
	signal internal_READCTRL_readout_reset : std_logic := '0';
	signal internal_READCTRL_readout_continue : std_logic := '0';
	signal internal_READCTRL_busy_status : std_logic := '0';
	signal internal_READCTRL_smp_stop : std_logic := '0';
	signal internal_READCTRL_dig_start  : std_logic := '0';
	signal internal_READCTRL_DIG_RD_ROWSEL : std_logic_vector(2 downto 0) := (others => '0');
	signal internal_READCTRL_DIG_RD_COLSEL : std_logic_vector(5 downto 0) := (others => '0');
	signal internal_READCTRL_srout_start  : std_logic := '0';
	signal internal_READCTRL_evtbuild_start  : std_logic := '0';
	signal internal_READCTRL_evtbuild_make_ready  : std_logic := '0';
	signal internal_READCTRL_LATCH_SMP_MAIN_CNT : std_logic_vector(8 downto 0) := (others => '0');
	signal internal_READCTRL_LATCH_DONE : std_logic := '0';
	signal internal_READCTRL_ASIC_NUM : std_logic_vector(3 downto 0) := (others => '0');
	signal internal_READCTRL_RESET_EVENT_NUM : std_logic := '0';
	signal internal_READCTRL_EVENT_NUM : std_logic_vector(31 downto 0) := x"00000000";
	signal internal_READCTRL_READOUT_DONE : std_logic := '0';
	
	signal internal_CMDREG_SOFTWARE_trigger : std_logic := '0';
	signal internal_CMDREG_SOFTWARE_TRIGGER_VETO : std_logic := '0';
	signal internal_CMDREG_HARDWARE_TRIGGER_ENABLE : std_logic := '0';
	signal internal_CMDREG_SMP_START : std_logic := '0';
	signal internal_CMDREG_SMP_STOP : std_logic := '0';
	signal internal_CMDREG_READCTRL_trig_delay : std_logic_vector(11 downto 0) := (others => '0');
	signal internal_CMDREG_READCTRL_dig_offset : std_logic_vector(8 downto 0) := (others => '0');
	signal internal_CMDREG_READCTRL_win_num_to_read : std_logic_vector(8 downto 0) := (others => '0');
	signal internal_CMDREG_READCTRL_asic_enable_bits : std_logic_vector(9 downto 0) := (others => '0');
	signal internal_CMDREG_READCTRL_readout_reset : std_logic := '0';
	signal internal_CMDREG_READCTRL_readout_continue : std_logic := '0';
	signal internal_CMDREG_DIG_STARTDIG : std_logic := '0';
	signal internal_CMDREG_DIG_RD_ROWSEL_S : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
	signal internal_CMDREG_DIG_RD_COLSEL_S : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
	signal internal_CMDREG_SROUT_START : std_logic := '0';
	signal internal_CMDREG_WAVEFORM_FIFO_RST : std_logic := '0';
	signal internal_CMDREG_EVTBUILD_START_BUILDING_EVENT : std_logic := '0';
	signal internal_CMDREG_EVTBUILD_MAKE_READY : std_logic := '0';
	signal internal_CMDREG_EVTBUILD_DONE_SENDING_EVENT : std_logic := '0';
	signal internal_CMDREG_EVTBUILD_PACKET_BUILDER_BUSY : std_logic := '0';
	signal internal_CMDREG_READCTRL_toggle_manual : std_logic := '0';
	signal internal_CMDREG_READCTRL_RESET_EVENT_NUM : std_logic := '0';

	--ASIC SAMPLING CONTROL
	signal internal_SMP_START 				: std_logic := '0';
	signal internal_SMP_STOP 				: std_logic := '0';
	signal internal_SMP_IDLE_status 		: std_logic := '0';
	signal internal_SMP_MAIN_CNT 			: std_logic_vector(8 downto 0) := (others => '0');
	signal internal_SSTIN 					: std_logic := '0';
	signal internal_SSPIN 					: std_logic := '0';
	signal internal_WR_STRB 				: std_logic := '0';
	signal internal_WR_ADVCLK 				: std_logic := '0';
	signal internal_WR_ENA 					: std_logic := '1';
	signal internal_WR_ADDRCLR 			: std_logic := '0';
	
	--ASIC DIGITIZATION CONTROL
	signal internal_DIG_STARTDIG 			: std_logic := '0';
	signal internal_DIG_IDLE_status 		: std_logic := '0';
	signal internal_DIG_RD_ENA 			: std_logic := '0';
	signal internal_DIG_CLR 				: std_logic := '0';
	signal internal_DIG_RD_ROWSEL_S 		: STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
	signal internal_DIG_RD_COLSEL_S 		: STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
	signal internal_DIG_START 				: STD_LOGIC := '0';
	signal internal_DIG_RAMP 				: STD_LOGIC := '0';
	
	--ASIC SERIAL READOUT
	signal internal_SROUT_START 			: std_logic := '0';
	signal internal_SROUT_IDLE_status 	: std_logic := '0';
	signal internal_SROUT_SAMP_DONE 		: std_logic := '0';
	signal internal_SROUT_SR_CLR 			: std_logic := '0';
	signal internal_SROUT_SR_CLK 			: std_logic := '0';
	signal internal_SROUT_SR_SEL 			: std_logic := '0';
	signal internal_SROUT_SAMPLESEL 		: std_logic_vector(4 downto 0) := (others => '0');
	signal internal_SROUT_SAMPLESEL_ANY : std_logic := '0';
	signal internal_SROUT_FIFO_WR_CLK   : std_logic := '0';
	signal internal_SROUT_FIFO_WR_EN    : std_logic := '0';
	signal internal_SROUT_FIFO_DATA_OUT : std_logic_vector(31 downto 0) := (others => '0');
	signal internal_SROUT_dout 			: std_logic_vector(15 downto 0) := (others => '0');
	signal internal_SROUT_ASIC_CONTROL_WORD : std_logic_vector(9 downto 0) := (others => '0');
	
	--WAVEFORM DATA FIFO
	signal internal_WAVEFORM_FIFO_RST 	: std_logic := '0';
	signal internal_EVTBUILD_MAKE_READY : std_logic := '0';
	
	--BUFFER CONTROL
	signal internal_BUFFERCTRL_FIFO_RESET	: std_logic := '0';
	signal internal_BUFFERCTRL_FIFO_WR_CLK : std_logic := '0';
	signal internal_BUFFERCTRL_FIFO_WR_EN 	: std_logic := '0';
	signal internal_BUFFERCTRL_FIFO_DIN 	: std_logic_vector(31 downto 0) := (others => '0');
	
	--MPPC Current Read ADCs
	signal internal_CurrentADC_reset			: std_logic;
	signal internal_SDA							: std_logic;
	signal internal_SCL							: std_logic;
	signal internal_runADC						: std_logic;
	signal internal_enOutput					: std_logic;
	signal internal_ADCOutput 					: std_logic_vector(11 downto 0);
	
	-- MPPC DAC
	signal i_dac_number : std_logic_vector(3 downto 0);
	signal i_dac_addr   : std_logic_vector(3 downto 0);
	signal i_dac_value  : std_logic_vector(7 downto 0);
	signal i_dac_update : std_logic;
	signal i_dac_update_extended : std_logic;
	signal i_hv_sck_dac : std_logic;
	signal i_hv_din_dac : std_logic;

	--Waveform FIFO component
	COMPONENT waveform_fifo_wr32_rd32
	PORT (
		rst : IN STD_LOGIC;
		wr_clk : IN STD_LOGIC;
		rd_clk : IN STD_LOGIC;
		din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		wr_en : IN STD_LOGIC;
		rd_en : IN STD_LOGIC;
		dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		full : OUT STD_LOGIC;
		empty : OUT STD_LOGIC;
		valid : OUT STD_LOGIC
	);
   END COMPONENT;
	
	COMPONENT buffer_fifo_wr32_rd32
	PORT (
		rst : IN STD_LOGIC;
		wr_clk : IN STD_LOGIC;
		rd_clk : IN STD_LOGIC;
		din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		wr_en : IN STD_LOGIC;
		rd_en : IN STD_LOGIC;
		dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		full : OUT STD_LOGIC;
		empty : OUT STD_LOGIC;
		valid : OUT STD_LOGIC
	);
	END COMPONENT;
	
begin

	--Overall Signal Routing
	--debug/diag route:
   --EX_TRIGGER1 <= internal_TRIGGER_ALL;
   EX_TRIGGER2 <= internal_TRIGGER_ASIC(9);
	EX_TRIGGER1 <= internal_READ_ENABLE_TIMER(9);
--   EX_TRIGGER1 <= TDC_MON_TIMING(9);
--  EX_TRIGGER2 <= internal_DAC_CONTROL_SCLK;
--   internal_TXDCTRIG(0)(0) <=TDC1_TRG(0);
	
	internal_TRIGGER_ASIC(0) <= TDC1_TRG_16 OR TDC1_TRG(0) OR TDC1_TRG(1) OR TDC1_TRG(2) OR TDC1_TRG(3);
	internal_TRIGGER_ASIC(1) <= TDC2_TRG_16 OR TDC2_TRG(0) OR TDC2_TRG(1) OR TDC2_TRG(2) OR TDC2_TRG(3);
	internal_TRIGGER_ASIC(2) <= TDC3_TRG_16 OR TDC3_TRG(0) OR TDC3_TRG(1) OR TDC3_TRG(2) OR TDC3_TRG(3);
	internal_TRIGGER_ASIC(3) <= TDC4_TRG_16 OR TDC4_TRG(0) OR TDC4_TRG(1) OR TDC4_TRG(2) OR TDC4_TRG(3);
	internal_TRIGGER_ASIC(4) <= TDC5_TRG_16 OR TDC5_TRG(0) OR TDC5_TRG(1) OR TDC5_TRG(2) OR TDC5_TRG(3);
	internal_TRIGGER_ASIC(5) <= TDC6_TRG_16 OR TDC6_TRG(0) OR TDC6_TRG(1) OR TDC6_TRG(2) OR TDC6_TRG(3);
	internal_TRIGGER_ASIC(6) <= TDC7_TRG_16 OR TDC7_TRG(0) OR TDC7_TRG(1) OR TDC7_TRG(2) OR TDC7_TRG(3);
	internal_TRIGGER_ASIC(7) <= TDC8_TRG_16 OR TDC8_TRG(0) OR TDC8_TRG(1) OR TDC8_TRG(2) OR TDC8_TRG(3);
	internal_TRIGGER_ASIC(8) <= TDC9_TRG_16 OR TDC9_TRG(0) OR TDC9_TRG(1) OR TDC9_TRG(2) OR TDC9_TRG(3);
	internal_TRIGGER_ASIC(9) <= TDC10_TRG_16 OR TDC10_TRG(0) OR TDC10_TRG(1) OR TDC10_TRG(2) OR TDC10_TRG(3);
	--internal_TRIGGER_ALL <= internal_TRIGGER_ASIC(0) OR internal_TRIGGER_ASIC(1);
	internal_TRIGGER_ALL <= (internal_TRIGGER_ASIC(0) --AND internal_TRIGGER_ASIC_control_word(0)
	)
		OR ( internal_TRIGGER_ASIC(1) --AND internal_TRIGGER_ASIC_control_word(1)
		)
		OR ( internal_TRIGGER_ASIC(2) --AND internal_TRIGGER_ASIC_control_word(2) 
		)
		OR ( internal_TRIGGER_ASIC(3) --AND internal_TRIGGER_ASIC_control_word(3) 
		)
		OR ( internal_TRIGGER_ASIC(4) --AND internal_TRIGGER_ASIC_control_word(4) 
		)
		OR ( internal_TRIGGER_ASIC(5) --AND internal_TRIGGER_ASIC_control_word(5) 
		)
		OR ( internal_TRIGGER_ASIC(6) --AND internal_TRIGGER_ASIC_control_word(6) 
		)
		OR ( internal_TRIGGER_ASIC(7) --AND internal_TRIGGER_ASIC_control_word(7) 
		)
		OR ( internal_TRIGGER_ASIC(8) --AND internal_TRIGGER_ASIC_control_word(8) 
		)
		OR ( internal_TRIGGER_ASIC(9) --AND internal_TRIGGER_ASIC_control_word(9) 
		);
	
	--Clock generation
	map_clock_generation : entity work.clock_generation
	port map ( 
		--Raw boad clock input
		BOARD_CLOCKP      => BOARD_CLOCKP,
		BOARD_CLOCKN      => BOARD_CLOCKN,
		--FTSW inputs
		RJ45_ACK_P        => RJ45_ACK_P,
		RJ45_ACK_N        => RJ45_ACK_N,			  
		RJ45_TRG_P        => RJ45_TRG_P,
		RJ45_TRG_N        => RJ45_TRG_N,			  			  
		RJ45_RSV_P        => RJ45_RSV_P,
		RJ45_RSV_N        => RJ45_RSV_N,
		RJ45_CLK_P        => RJ45_CLK_P,
		RJ45_CLK_N        => RJ45_CLK_N,
		--Trigger outputs from FTSW
		FTSW_TRIGGER      => open,
		--Select signal between the two
		USE_LOCAL_CLOCK   => MONITOR_INPUT(0),
		--General output clocks
		CLOCK_50MHz_BUFG  => internal_CLOCK_50MHz_BUFG,
		CLOCK_4MHz_BUFG   => internal_CLOCK_4MHz_BUFG,
		--ASIC control clocks
		--IM/GSV: Modify to it will run LVDS:
		CLOCK_SSTx8_BUFG  => internal_CLOCK_8xSST_BUFG,
		CLOCK_SST_BUFG    => internal_CLOCK_SST_BUFG,
		--ASIC output clocks
		ASIC_SST          => open,
		ASIC_SSP          => open,
		ASIC_WR_STRB      => open,
		ASIC_WR_ADDR_LSB  => open,
		ASIC_WR_ADDR_LSB_RAW => open,
		--Output clock enable for I2C things
		I2C_CLOCK_ENABLE  => internal_CLOCK_ENABLE_I2C
	);  

	--Interface to the DAQ devices
	map_readout_interfaces : entity work.readout_interface
	port map ( 
		CLOCK                        => internal_CLOCK_50MHz_BUFG,

		OUTPUT_REGISTERS             => internal_OUTPUT_REGISTERS,
		INPUT_REGISTERS              => internal_INPUT_REGISTERS,
		REGISTER_UPDATED             => i_register_update,
	
		--NOT original implementation - KLM specific
		WAVEFORM_FIFO_DATA_IN        => internal_READOUT_DATA_OUT,
		WAVEFORM_FIFO_EMPTY          => internal_READOUT_EMPTY,
		WAVEFORM_FIFO_DATA_VALID     => internal_READOUT_DATA_VALID,
		WAVEFORM_FIFO_READ_CLOCK     => internal_READOUT_READ_CLOCK,
		WAVEFORM_FIFO_READ_ENABLE    => internal_READOUT_READ_ENABLE,
		WAVEFORM_PACKET_BUILDER_BUSY => internal_READCTRL_busy_status,
		--WAVEFORM_PACKET_BUILDER_BUSY => '0',
		WAVEFORM_PACKET_BUILDER_VETO => internal_EVTBUILD_PACKET_BUILDER_VETO,
		
		--WAVEFORM ROI readout disable - command packets only
		--WAVEFORM_FIFO_DATA_IN        => (others=>'0'),
		--WAVEFORM_FIFO_EMPTY          => '1',
		--WAVEFORM_FIFO_DATA_VALID     => '0',
		--WAVEFORM_FIFO_READ_CLOCK     => open,
		--WAVEFORM_FIFO_READ_ENABLE    => open,
		--WAVEFORM_PACKET_BUILDER_BUSY => '0',
		--WAVEFORM_PACKET_BUILDER_VETO => open,

		FIBER_0_RXP                  => FIBER_0_RXP,
		FIBER_0_RXN                  => FIBER_0_RXN,
		FIBER_1_RXP                  => FIBER_1_RXP,
		FIBER_1_RXN                  => FIBER_1_RXN,
		FIBER_0_TXP                  => FIBER_0_TXP,
		FIBER_0_TXN                  => FIBER_0_TXN,
		FIBER_1_TXP                  => FIBER_1_TXP,
		FIBER_1_TXN                  => FIBER_1_TXN,
		FIBER_REFCLKP                => FIBER_REFCLKP,
		FIBER_REFCLKN                => FIBER_REFCLKN,
		FIBER_0_DISABLE_TRANSCEIVER  => FIBER_0_DISABLE_TRANSCEIVER,
		FIBER_1_DISABLE_TRANSCEIVER  => FIBER_1_DISABLE_TRANSCEIVER,
		FIBER_0_LINK_UP              => FIBER_0_LINK_UP,
		FIBER_1_LINK_UP              => FIBER_1_LINK_UP,
		FIBER_0_LINK_ERR             => FIBER_0_LINK_ERR,
		FIBER_1_LINK_ERR             => FIBER_1_LINK_ERR,

		USB_IFCLK                    => USB_IFCLK,
		USB_CTL0                     => USB_CTL0,
		USB_CTL1                     => USB_CTL1,
		USB_CTL2                     => USB_CTL2,
		USB_FDD                      => USB_FDD,
		USB_PA0                      => USB_PA0,
		USB_PA1                      => USB_PA1,
		USB_PA2                      => USB_PA2,
		USB_PA3                      => USB_PA3,
		USB_PA4                      => USB_PA4,
		USB_PA5                      => USB_PA5,
		USB_PA6                      => USB_PA6,
		USB_PA7                      => USB_PA7,
		USB_RDY0                     => USB_RDY0,
		USB_RDY1                     => USB_RDY1,
		USB_WAKEUP                   => USB_WAKEUP,
		USB_CLKOUT		              => USB_CLKOUT
	);
---------------------------------------------------------------
---------KLM_SCROD: interface for Trigger using FTSW-----------
---------------------------------------------------------------

--	klm_scrod_trig_interface : entity work.KLM_SCROD;
--		port map ( 
	
			
			   -- TTD/FTSW interface
--    ttdclkp  => RJ45_CLK_P,
--    ttdclkn  => RJ45_CLK_N,
--    ttdtrgp  => RJ45_TRG_P,
--    ttdtrgn  => RJ45_TRG_N,    
--    ttdrsvp  => RJ45_RSV_P,  
--    ttdrsvn  => RJ45_RSV_N,
--    ttdackp  => RJ45_ACK_P,
--    ttdackn  => RJ45_ACK_N
    -- ASIC Interface
--    target_tb                   : in tb_vec_type; 
--    target_tb16                 : in std_logic_vector(1 to TDC_NUM_CHAN); 
--    -- SFP interface
--    mgttxfault                  : in std_logic_vector(1 to NUM_GTS);
--    mgtmod0                     : in std_logic_vector(1 to NUM_GTS);
--    mgtlos                      : in std_logic_vector(1 to NUM_GTS);
--    mgttxdis                    : out std_logic_vector(1 to NUM_GTS);
--    mgtmod2                     : out std_logic_vector(1 to NUM_GTS);
--    mgtmod1                     : out std_logic_vector(1 to NUM_GTS);
--    mgtrxp                      : in std_logic;
--    mgtrxn                      : in std_logic;
--    mgttxp                      : out std_logic;
--    mgttxn                      : out std_logic;
--    status_fake                 : out std_logic;
--    control_fake                : out std_logic);
--			
			
--			);
			




	--------------------------------------------------
	-------General registers interfaced to DAQ -------
	--------------------------------------------------

	--LEDS
	LEDS <= internal_OUTPUT_REGISTERS(0);
	--LEDS <= internal_WAVEFORM_FIFO_EMPTY & internal_SROUT_IDLE_status & internal_DIG_IDLE_status & internal_SMP_IDLE_STATUS & "000" & internal_SMP_MAIN_CNT;
	
	--DAC CONTROL SIGNALS
	internal_DAC_CONTROL_UPDATE <= internal_OUTPUT_REGISTERS(1)(0);
	internal_DAC_CONTROL_REG_DATA <= internal_OUTPUT_REGISTERS(2)(6 downto 0) 
												& internal_OUTPUT_REGISTERS(3)(11 downto 0);
   internal_DAC_CONTROL_TDCNUM <= internal_OUTPUT_REGISTERS(4)(9 downto 0);
	internal_DAC_CONTROL_LOAD_PERIOD <= internal_OUTPUT_REGISTERS(5)(15 downto 0);
	internal_DAC_CONTROL_LATCH_PERIOD <= internal_OUTPUT_REGISTERS(6)(15 downto 0);
	
	--Sampling Signals
	internal_CMDREG_SMP_STOP <= internal_OUTPUT_REGISTERS(10)(0);
	internal_CMDREG_SMP_START <= internal_OUTPUT_REGISTERS(11)(0);

	--Digitization Signals
   internal_CMDREG_DIG_STARTDIG <= internal_OUTPUT_REGISTERS(20)(0);
   internal_CMDREG_DIG_RD_ROWSEL_S <= internal_OUTPUT_REGISTERS(21)(8 downto 6);
	internal_CMDREG_DIG_RD_COLSEL_S <= internal_OUTPUT_REGISTERS(21)(5 downto 0);
	
	--Serial Readout Signals
	internal_CMDREG_SROUT_START <=  internal_OUTPUT_REGISTERS(30)(0);
	
	--Event builder signals
	internal_CMDREG_WAVEFORM_FIFO_RST <= internal_OUTPUT_REGISTERS(40)(0);
	internal_CMDREG_EVTBUILD_START_BUILDING_EVENT <= internal_OUTPUT_REGISTERS(44)(0);
	internal_CMDREG_EVTBUILD_MAKE_READY <= internal_OUTPUT_REGISTERS(45)(0);
	internal_CMDREG_EVTBUILD_PACKET_BUILDER_BUSY <= internal_OUTPUT_REGISTERS(46)(0);
	
	--Readout control signals
	internal_CMDREG_SOFTWARE_trigger <= internal_OUTPUT_REGISTERS(50)(0);
	--internal_CMDREG_SOFTWARE_TRIGGER_VETO <= internal_OUTPUT_REGISTERS(51)(0);
	internal_CMDREG_READCTRL_asic_enable_bits <= internal_OUTPUT_REGISTERS(51)(9 downto 0);
	internal_CMDREG_HARDWARE_TRIGGER_ENABLE <= internal_OUTPUT_REGISTERS(52)(0);
	internal_CMDREG_READCTRL_trig_delay <= internal_OUTPUT_REGISTERS(53)(11 downto 0);
	internal_CMDREG_READCTRL_dig_offset <= internal_OUTPUT_REGISTERS(54)(8 downto 0);
	internal_CMDREG_READCTRL_readout_reset <= internal_OUTPUT_REGISTERS(55)(0);
	internal_CMDREG_READCTRL_toggle_manual <= internal_OUTPUT_REGISTERS(56)(0);
	internal_CMDREG_READCTRL_win_num_to_read <= internal_OUTPUT_REGISTERS(57)(8 downto 0);
	internal_CMDREG_READCTRL_readout_continue <= internal_OUTPUT_REGISTERS(58)(0);
	internal_CMDREG_READCTRL_RESET_EVENT_NUM <= internal_OUTPUT_REGISTERS(59)(0);
	
	--Internal current readout ADC connecitons:
	internal_CurrentADC_reset	<= internal_OUTPUT_REGISTERS(63)(0);
	internal_runADC	<= internal_OUTPUT_REGISTERS(63)(1);
	--internal_SDA  <=SDA_MON;
	SCL_MON <=internal_SCL;
--	internal_enOutput	<= internal_OUTPUT_REGISTERS(63)(2);
--	internal_ADCOutput 	<= internal_OUTPUT_REGISTERS(64)(11 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 21)(11 downto 0) <= internal_ADCOutput(11 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 22)(0) <= internal_enOutput;
	TDC_AMUX_S   <= internal_OUTPUT_REGISTERS(62)(3 downto 0);--channel within a daughtercard
	TOP_AMUX_S   <= internal_OUTPUT_REGISTERS(62)(7 downto 4);-- Daughter Card Number
	
	
	
	-- HV dac signals
	i_dac_number <= internal_OUTPUT_REGISTERS(60)(15 downto 12);
	i_dac_addr   <= internal_OUTPUT_REGISTERS(60)(11 downto 8);
	i_dac_value  <= internal_OUTPUT_REGISTERS(60)(7 downto 0);
	i_dac_update <= i_register_update(60);
--	HV_DISABLE   <= not internal_OUTPUT_REGISTERS(61)(0);

	--Trigger control
	internal_TRIGCOUNT_ena <= internal_OUTPUT_REGISTERS(70)(0);
	internal_TRIGCOUNT_rst <= internal_OUTPUT_REGISTERS(71)(0);
	internal_TRIGGER_ASIC_control_word <= internal_OUTPUT_REGISTERS(72)(9 downto 0);

	--------Input register mapping--------------------
	--Map the first N_GPR output registers to the first set of read registers
	gen_OUTREG_to_INREG: for i in 0 to N_GPR-1 generate
		gen_BIT: for j in 0 to 15 generate
			map_BUF_RR : BUF 
			port map( 
				I => internal_OUTPUT_REGISTERS(i)(j), 
				O => internal_INPUT_REGISTERS(i)(j) 
			);
		end generate;
	end generate;
	--- The register numbers must be updated for the following if N_GPR is changed.
	internal_INPUT_REGISTERS(N_GPR + 0 ) <= "0000000" & internal_SMP_MAIN_CNT(8 downto 0 );
	internal_INPUT_REGISTERS(N_GPR + 1 ) <= internal_WAVEFORM_FIFO_DATA_OUT(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 2 ) <= "000000000000000" & internal_WAVEFORM_FIFO_EMPTY;
	internal_INPUT_REGISTERS(N_GPR + 3 ) <= "000000000000000" & internal_WAVEFORM_FIFO_DATA_VALID;
	internal_INPUT_REGISTERS(N_GPR + 4 ) <= "0000000" & internal_READCTRL_DIG_RD_COLSEL & internal_READCTRL_DIG_RD_ROWSEL;
	internal_INPUT_REGISTERS(N_GPR + 5 ) <= "0000000" & internal_READCTRL_LATCH_SMP_MAIN_CNT;
	internal_INPUT_REGISTERS(N_GPR + 6 ) <= "0000000000" & internal_EVTBUILD_MAKE_READY & internal_EVTBUILD_DONE_SENDING_EVENT & internal_WAVEFORM_FIFO_EMPTY & internal_SROUT_IDLE_status 
										& internal_DIG_IDLE_status & internal_SMP_IDLE_STATUS;
   internal_INPUT_REGISTERS(N_GPR + 7 ) (9 downto 0) <= SHOUT(9 downto 0);
   
	internal_INPUT_REGISTERS(N_GPR + 10 ) <= internal_TRIGCOUNT_scaler(0)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 11 ) <= internal_TRIGCOUNT_scaler(1)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 12 ) <= internal_TRIGCOUNT_scaler(2)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 13 ) <= internal_TRIGCOUNT_scaler(3)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 14 ) <= internal_TRIGCOUNT_scaler(4)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 15 ) <= internal_TRIGCOUNT_scaler(5)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 16 ) <= internal_TRIGCOUNT_scaler(6)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 17 ) <= internal_TRIGCOUNT_scaler(7)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 18 ) <= internal_TRIGCOUNT_scaler(8)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 19 ) <= internal_TRIGCOUNT_scaler(9)(15 downto 0);
	internal_INPUT_REGISTERS(N_GPR + 20) <= x"002c"; -- ID of the board

   --ASIC control processes
	
	--TARGET6 DAC Control
	u_TARGET6_DAC_CONTROL: entity work.TARGET6_DAC_CONTROL PORT MAP(
			CLK 				=> internal_CLOCK_50MHz_BUFG,
			LOAD_PERIOD 	=> internal_DAC_CONTROL_LOAD_PERIOD,
			LATCH_PERIOD 	=> internal_DAC_CONTROL_LATCH_PERIOD,
			UPDATE 			=> internal_DAC_CONTROL_UPDATE,
			REG_DATA 		=> internal_DAC_CONTROL_REG_DATA,
			SIN 				=> internal_DAC_CONTROL_SIN,
			SCLK 				=> internal_DAC_CONTROL_SCLK,
			PCLK 				=> internal_DAC_CONTROL_PCLK
   );
	--end generate;

	gen_wl_clk_to_asic : for i in 0 to 9 generate
		map_wlclkn : ODDR2
			generic map(
				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
			port map (
				Q  => WL_CLK_N(i),        -- 1-bit output data
				C0 => not(internal_CLOCK_50MHz_BUFG),      -- 1-bit clock input
				C1 => internal_CLOCK_50MHz_BUFG, -- 1-bit clock input
				CE => '1',                     -- 1-bit clock enable input
				D0 => '1',                     -- 1-bit data input (associated with C0)
				D1 => '0',                     -- 1-bit data input (associated with C1)
				R  => '0',                     -- 1-bit reset input
				S  => '0'                      -- 1-bit set input
		);
		
			map_wlclkp : ODDR2
			generic map(
				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
			port map (
				Q  => WL_CLK_P(i),        -- 1-bit output data
				C0 => internal_CLOCK_50MHz_BUFG,      -- 1-bit clock input
				C1 => not(internal_CLOCK_50MHz_BUFG), -- 1-bit clock input
				CE => '1',                     -- 1-bit clock enable input
				D0 => '1',                     -- 1-bit data input (associated with C0)
				D1 => '0',                     -- 1-bit data input (associated with C1)
				R  => '0',                     -- 1-bit reset input
				S  => '0'                      -- 1-bit set input
		);
		
--			map_tmpsstin_n : ODDR2
--			generic map(
--				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
--				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
--				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
--			port map (
--				Q  => SSTIN_N(i),        -- 1-bit output data
--				C0 => not(internal_CLOCK_50MHz_BUFG),      -- 1-bit clock input
--				C1 => internal_CLOCK_50MHz_BUFG, -- 1-bit clock input
--				CE => '1',                     -- 1-bit clock enable input
--				D0 => '1',                     -- 1-bit data input (associated with C0)
--				D1 => '0',                     -- 1-bit data input (associated with C1)
--				R  => '0',                     -- 1-bit reset input
--				S  => '0'                      -- 1-bit set input
--		);	
--		
--		map_tmpsstin_p : ODDR2
--			generic map(
--				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
--				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
--				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
--			port map (
--				Q  => SSTIN_P(i),        -- 1-bit output data
--				C0 => internal_CLOCK_50MHz_BUFG,      -- 1-bit clock input
--				C1 => not(internal_CLOCK_50MHz_BUFG), -- 1-bit clock input
--				CE => '1',                     -- 1-bit clock enable input
--				D0 => '1',                     -- 1-bit data input (associated with C0)
--				D1 => '0',                     -- 1-bit data input (associated with C1)
--				R  => '0',                     -- 1-bit reset input
--				S  => '0'                      -- 1-bit set input
--		);	
		end generate;
			
	BUS_REGCLR <= '0';
--	BUSA_REGCLR <= '0';
--	BUSB_REGCLR <= '0';
--	BUSA_SCLK <= internal_DAC_CONTROL_SCLK;
--	BUSB_SCLK <= internal_DAC_CONTROL_SCLK;
	--Only specified DC gets serial data signals, uses bit mask
	gen_DAC_CONTROL: for i in 0 to 9 generate
		SIN(i) <= internal_DAC_CONTROL_SIN and internal_DAC_CONTROL_TDCNUM(i);
		PCLK(i) <= internal_DAC_CONTROL_PCLK and internal_DAC_CONTROL_TDCNUM(i);
		SCLK(i) <= internal_DAC_CONTROL_SCLK and internal_DAC_CONTROL_TDCNUM(i);
	end generate;
	
	--Control the sampling, digitization and serial resout processes following trigger
	u_ReadoutControl: entity work.ReadoutControl PORT MAP(
		clk 					=> internal_CLOCK_50MHz_BUFG,
		smp_clk 				=> internal_CLOCK_8xSST_BUFG,
		trigger 				=> internal_READCTRL_trigger,
		trig_delay 			=> internal_READCTRL_trig_delay,
		dig_offset 			=> internal_READCTRL_dig_offset,
		win_num_to_read 	=> internal_READCTRL_win_num_to_read,
		asic_enable_bits  => internal_READCTRL_asic_enable_bits,
		SMP_MAIN_CNT 		=> internal_SMP_MAIN_CNT,
		SMP_IDLE_status 	=> internal_SMP_IDLE_STATUS,
		DIG_IDLE_status 	=> internal_DIG_IDLE_status,
		SROUT_IDLE_status => internal_SROUT_IDLE_status,
		fifo_empty 			=> internal_WAVEFORM_FIFO_EMPTY,
		EVTBUILD_DONE_SENDING_EVENT => internal_EVTBUILD_DONE_SENDING_EVENT,
		LATCH_SMP_MAIN_CNT => internal_READCTRL_LATCH_SMP_MAIN_CNT,
		LATCH_DONE 			=> internal_READCTRL_LATCH_DONE,
		READOUT_RESET 		=> internal_READCTRL_readout_reset,
		READOUT_CONTINUE 	=> internal_READCTRL_readout_continue,
		RESET_EVENT_NUM 	=> internal_READCTRL_RESET_EVENT_NUM,
		ASIC_NUM 			=> internal_READCTRL_ASIC_NUM,
		busy_status 		=> internal_READCTRL_busy_status,
		smp_stop 			=> internal_READCTRL_smp_stop,
		dig_start 			=> internal_READCTRL_dig_start,
		DIG_RD_ROWSEL_S 	=> internal_READCTRL_DIG_RD_ROWSEL,
		DIG_RD_COLSEL_S 	=> internal_READCTRL_DIG_RD_COLSEL,
		srout_start 		=> internal_READCTRL_srout_start,
		EVTBUILD_start 	=> open,
		EVTBUILD_MAKE_READY => open,
		EVENT_NUM 			=> internal_READCTRL_EVENT_NUM,
		READOUT_DONE 		=> internal_READCTRL_READOUT_DONE
	);
	internal_SOFTWARE_TRIGGER_VETO <= internal_CMDREG_SOFTWARE_TRIGGER_VETO;
	internal_HARDWARE_TRIGGER_ENABLE <= internal_CMDREG_HARDWARE_TRIGGER_ENABLE;
	internal_SOFTWARE_TRIGGER <= internal_CMDREG_SOFTWARE_trigger AND NOT internal_SOFTWARE_TRIGGER_VETO;
	internal_HARDWARE_TRIGGER <= internal_TRIGGER_ALL AND internal_HARDWARE_TRIGGER_ENABLE;
	internal_READCTRL_trigger <= internal_SOFTWARE_TRIGGER OR internal_HARDWARE_TRIGGER;
	--internal_READCTRL_trigger <= internal_SOFTWARE_TRIGGER;
	internal_READCTRL_trig_delay <= internal_CMDREG_READCTRL_trig_delay;
	internal_READCTRL_dig_offset <= internal_CMDREG_READCTRL_dig_offset;
	internal_READCTRL_win_num_to_read <= internal_CMDREG_READCTRL_win_num_to_read;
	internal_READCTRL_asic_enable_bits <= internal_CMDREG_READCTRL_asic_enable_bits;
	internal_READCTRL_readout_reset <= internal_CMDREG_READCTRL_readout_reset;
	internal_READCTRL_RESET_EVENT_NUM <= internal_CMDREG_READCTRL_RESET_EVENT_NUM;
	
	--sampling logic - specifically SSPIN/SSTIN + write address control
	u_SamplingLgc : entity work.SamplingLgc
   Port map (
		clk 			=> internal_CLOCK_8xSST_BUFG,
		start 		=> internal_SMP_START,
		stop 			=> internal_SMP_STOP,
		IDLE_status => internal_SMP_IDLE_STATUS,
		MAIN_CNT_out => internal_SMP_MAIN_CNT,
		sspin_out 	=> open,--internal_SSPIN,
		sstin_out 	=> internal_SSTIN,-- GV: 6/9/14 we do not want to shut down this part of the chip!
		wr_advclk_out 	=> internal_WR_ADVCLK,
		wr_addrclr_out => internal_WR_ADDRCLR,
		wr_strb_out => internal_WR_STRB,
		wr_ena_out 	=> open--internal_WR_ENA
	);
	internal_SMP_START <= internal_CMDREG_SMP_START;
	internal_SMP_STOP <= internal_READCTRL_smp_stop when internal_CMDREG_READCTRL_toggle_manual = '0' else
							 internal_CMDREG_SMP_STOP;
	BUSA_WR_ADDRCLR 	<= internal_WR_ADDRCLR;
	BUSB_WR_ADDRCLR 	<= internal_WR_ADDRCLR;	
	--SamplingLgc signals just get fanned out identically to each daughter card
	gen_SamplingLgcSignals : for i in 0 to 9 generate
		--SSPIN(i) 		<= internal_SSPIN;
--		SSTIN(i) 		<= internal_CLOCK_8xSST_BUFG;-- GV: 6/9/14 still needed to be fixed to LVDS, pending if we can route out of ports + and - pins of clocks
		SSTIN_N(i) 		<= internal_SSTIN;-- GV: 6/9/14 still needed to be fixed to LVDS, pending if we can route out of ports + and - pins of clocks
		SSTIN_P(i) 		<= not(internal_SSTIN);-- GV: 6/9/14 still needed to be fixed to LVDS, pending if we can route out of ports + and - pins of clocks
--		WR_ADVCLK(i) 	<= internal_WR_ADVCLK;
--		WR_STRB(i) 		<= internal_WR_STRB;
--		WR_ENA(i) 		<= internal_WR_ENA;
		WR1_ENA(i) 		<= internal_WR_ENA;
		WR2_ENA(i) 		<= internal_WR_ENA;
	end generate;


	--sampling logic - specifically SSPIN/SSTIN + write address control
	--ripped old sampling ligic which was designed for T6 and replaced with TX
--	u_SamplingLgc : entity work.SamplingLgicTX
--   Port map (
--		clk 			=> internal_CLOCK_8xSST_BUFG,
--		rst 			=> '0',
--		Enable 		=> internal_SMP_START,
--		SamplSpeed 	=> '0',
--		Test_sampling => '0',
--		Test_setup		=> '0';
--		stop 			=> internal_SMP_STOP,
--		samp_wr_ena => '1',
--		
--		cur_COL_l => MAIN_CNT_out(
--		
--		
--		IDLE_status => internal_SMP_IDLE_STATUS,
--		MAIN_CNT_out => internal_SMP_MAIN_CNT,
--		sspin_out 	=> open,--internal_SSPIN,
--		sstin_out 	=> internal_SSTIN,-- GV: 6/9/14 we do not want to shut down this part of the chip!
--		wr_advclk_out 	=> internal_WR_ADVCLK,
--		wr_addrclr_out => internal_WR_ADDRCLR,
--		wr_strb_out => internal_WR_STRB,
--		wr_ena_out 	=> open--internal_WR_ENA
--	);
--	internal_SMP_START <= internal_CMDREG_SMP_START;
--	internal_SMP_STOP <= internal_READCTRL_smp_stop when internal_CMDREG_READCTRL_toggle_manual = '0' else
--							 internal_CMDREG_SMP_STOP;
--	BUSA_WR_ADDRCLR 	<= internal_WR_ADDRCLR;
--	BUSB_WR_ADDRCLR 	<= internal_WR_ADDRCLR;	
--	
--	--SamplingLgc signals just get fanned out identically to each daughter card
--	gen_SamplingLgcSignals : for i in 0 to 9 generate
--		--SSPIN(i) 		<= internal_SSPIN;
----		SSTIN(i) 		<= internal_CLOCK_8xSST_BUFG;-- GV: 6/9/14 still needed to be fixed to LVDS, pending if we can route out of ports + and - pins of clocks
--		SSTIN_N(i) 		<= internal_SSTIN;-- GV: 6/9/14 still needed to be fixed to LVDS, pending if we can route out of ports + and - pins of clocks
--		SSTIN_P(i) 		<= not(internal_SSTIN);-- GV: 6/9/14 still needed to be fixed to LVDS, pending if we can route out of ports + and - pins of clocks
----		WR_ADVCLK(i) 	<= internal_WR_ADVCLK;
----		WR_STRB(i) 		<= internal_WR_STRB;
----		WR_ENA(i) 		<= internal_WR_ENA;
--		WR1_ENA(i) 		<= internal_WR_ENA;
--		WR2_ENA(i) 		<= internal_WR_ENA;
--	end generate;


-- IM: 6/12/14 Save this for later when LVDS problem on PCB is fixed- they need to be routed to the correct bank
--gen_sstin : for i in 0 to 9 generate
-- OBUFDS_inst : OBUFDS
-- --  generic map (
-- --     IOSTANDARD => "DEFAULT")
--   port map (
--      O => internal_CLOCK_8xSST_OBUFDS_P(i),     -- Diff_p output (connect directly to top-level port)
--      OB => internal_CLOCK_8xSST_OBUFDS_N(i),   -- Diff_n output (connect directly to top-level port)
--      I => internal_CLOCK_8xSST_BUFG      -- Buffer input 
--   );
--end generate;

	--digitizing logic
	u_DigitizingLgc: entity work.DigitizingLgcTX PORT MAP(
		clk 				=> internal_CLOCK_50MHz_BUFG,
		IDLE_status 	=> internal_DIG_IDLE_status,
		StartDig 		=> internal_DIG_STARTDIG,
		ramp_length 	=> X"400",
		rd_ena 			=> internal_DIG_RD_ENA,
		clr 				=> internal_DIG_CLR,
		startramp 		=> internal_DIG_RAMP
	);
	internal_DIG_STARTDIG 	<= internal_READCTRL_dig_start when internal_CMDREG_READCTRL_toggle_manual = '0' else
							internal_CMDREG_DIG_STARTDIG;
	--BUSA and BUSB Digitzation signals are identical
	BUSA_RD_ENA			<= internal_DIG_RD_ENA;
	BUSA_RD_ROWSEL_S 	<= internal_READCTRL_DIG_RD_ROWSEL when internal_CMDREG_READCTRL_toggle_manual = '0' else
	                 internal_CMDREG_DIG_RD_ROWSEL_S;
	BUSA_RD_COLSEL_S 	<= internal_READCTRL_DIG_RD_COLSEL when internal_CMDREG_READCTRL_toggle_manual = '0' else
	                 internal_CMDREG_DIG_RD_COLSEL_S;				
	BUSA_CLR 			<= internal_DIG_CLR;
--	BUSA_START 			<= internal_DIG_RAMP;
	BUSA_RAMP 			<= internal_DIG_RAMP;
	BUSB_RD_ENA			<= internal_DIG_RD_ENA;
	BUSB_RD_ROWSEL_S 	<= internal_READCTRL_DIG_RD_ROWSEL when internal_CMDREG_READCTRL_toggle_manual = '0' else
	                 internal_CMDREG_DIG_RD_ROWSEL_S;
	BUSB_RD_COLSEL_S 	<= internal_READCTRL_DIG_RD_COLSEL when internal_CMDREG_READCTRL_toggle_manual = '0' else
	                 internal_CMDREG_DIG_RD_COLSEL_S;
	BUSB_CLR 			<= internal_DIG_CLR;
--	BUSB_START 			<= internal_DIG_RAMP;
	BUSB_RAMP 			<= internal_DIG_RAMP;	
	
	u_SerialDataRout: entity work.SerialDataRout PORT MAP(
		clk 			=> internal_CLOCK_50MHz_BUFG,
		start		 	=> internal_SROUT_START,
		EVENT_NUM 	=> internal_READCTRL_EVENT_NUM,
		WIN_ADDR 	=> internal_READCTRL_DIG_RD_COLSEL & internal_READCTRL_DIG_RD_ROWSEL,
		ASIC_NUM 	=> internal_READCTRL_ASIC_NUM,
		IDLE_status => internal_SROUT_IDLE_status,
		busy 			=> open,
		samp_done 	=> open,
		dout 			=> internal_SROUT_dout,
		sr_clr 		=> internal_SROUT_SR_CLR,
		sr_clk 		=> internal_SROUT_SR_CLK,
		sr_sel 		=> internal_SROUT_SR_SEL,
		samplesel 	=> internal_SROUT_SAMPLESEL,
		smplsi_any 	=> internal_SROUT_SAMPLESEL_ANY,
		fifo_wr_en 	=> internal_SROUT_FIFO_WR_EN,
		fifo_wr_clk => internal_SROUT_FIFO_WR_CLK,
		fifo_wr_din => internal_SROUT_FIFO_DATA_OUT
	);
	internal_SROUT_START <= internal_READCTRL_srout_start when internal_CMDREG_READCTRL_toggle_manual = '0' else
							internal_CMDREG_SROUT_START;
	--make serial readout bus signals identical
	BUSA_SAMPLESEL_S 	<= internal_SROUT_SAMPLESEL;
	BUSA_SR_CLEAR 		<= internal_SROUT_SR_CLR;
	BUSA_SR_SEL			<= internal_SROUT_SR_SEL;
	BUSB_SAMPLESEL_S 	<= internal_SROUT_SAMPLESEL;
	BUSB_SR_CLEAR 		<=  internal_SROUT_SR_CLR;
	BUSB_SR_SEL			<= internal_SROUT_SR_SEL;
	
	--Serial readout DO signal switches between buses based on internal_READCTRL_ASIC_NUM signal
	internal_SROUT_dout <= BUSA_DO when (internal_READCTRL_ASIC_NUM < x"6") else
								BUSB_DO;
	
	--multiplex DC specific serial readout signal to ASIC specified by internal_READCTRL_ASIC_NUM signal
	internal_SROUT_ASIC_CONTROL_WORD 		<= "0000000001" when (internal_READCTRL_ASIC_NUM = x"1") else
															"0000000010" when (internal_READCTRL_ASIC_NUM = x"2") else
															"0000000100" when (internal_READCTRL_ASIC_NUM = x"3") else
															"0000001000" when (internal_READCTRL_ASIC_NUM = x"4") else
															"0000010000" when (internal_READCTRL_ASIC_NUM = x"5") else
															"0000100000" when (internal_READCTRL_ASIC_NUM = x"6") else
															"0001000000" when (internal_READCTRL_ASIC_NUM = x"7") else
															"0010000000" when (internal_READCTRL_ASIC_NUM = x"8") else
															"0100000000" when (internal_READCTRL_ASIC_NUM = x"9") else
															"1000000000" when (internal_READCTRL_ASIC_NUM = x"A") else
															"0000000000";
	
	--Only specified DC gets serial data signals, uses bit mask
	gen_SAMPLESEL_ANY_CONTROL: for i in 0 to 9 generate
		SR_CLOCK(i)			<= internal_SROUT_SR_CLK 			and internal_SROUT_ASIC_CONTROL_WORD(i);
		SAMPLESEL_ANY(i) 	<= internal_SROUT_SAMPLESEL_ANY 	and internal_SROUT_ASIC_CONTROL_WORD(i);
	end generate;
	
	--FIFO receives waveform samples produced by serial readout process
   u_waveform_fifo_wr32_rd32 : waveform_fifo_wr32_rd32
   PORT MAP (
		rst => internal_WAVEFORM_FIFO_RST,
		wr_clk => internal_SROUT_FIFO_WR_CLK,
		rd_clk => internal_WAVEFORM_FIFO_READ_CLOCK,
		din => internal_SROUT_FIFO_DATA_OUT,
		wr_en => internal_SROUT_FIFO_WR_EN,
		rd_en => internal_WAVEFORM_FIFO_READ_ENABLE,
		dout => internal_WAVEFORM_FIFO_DATA_OUT,
		empty => internal_WAVEFORM_FIFO_EMPTY,
		valid => internal_WAVEFORM_FIFO_DATA_VALID
   );
	
	--Module reads out from waveform FIFO and places ASIC window-sized packets into buffer FIFO
	u_OutputBufferControl: entity work.OutputBufferControl PORT MAP(
		clk => internal_CLOCK_50MHz_BUFG,
		REQUEST_PACKET 				=> internal_READCTRL_readout_continue,
		EVTBUILD_DONE					=> internal_EVTBUILD_DONE_SENDING_EVENT,
		WAVEFORM_FIFO_READ_CLOCK 	=> internal_WAVEFORM_FIFO_READ_CLOCK,
		WAVEFORM_FIFO_READ_ENABLE 	=> internal_WAVEFORM_FIFO_READ_ENABLE,
		WAVEFORM_FIFO_DATA_OUT 		=> internal_WAVEFORM_FIFO_DATA_OUT,
		WAVEFORM_FIFO_EMPTY 			=> internal_WAVEFORM_FIFO_EMPTY,
		WAVEFORM_FIFO_DATA_VALID 	=> internal_WAVEFORM_FIFO_DATA_VALID,
		--WAVEFORM_FIFO_READ_CLOCK 	=> internal_WAVEFORM_FIFO_READ_CLOCK,
		--WAVEFORM_FIFO_READ_ENABLE 	=> open,
		--WAVEFORM_FIFO_DATA_OUT 		=> (others=>'0'),
		--WAVEFORM_FIFO_EMPTY 			=> '1',
		--WAVEFORM_FIFO_DATA_VALID 	=> '0',
		BUFFER_FIFO_RESET 	=> internal_BUFFERCTRL_FIFO_RESET,
		BUFFER_FIFO_WR_CLK 	=> internal_BUFFERCTRL_FIFO_WR_CLK,
		BUFFER_FIFO_WR_EN 	=> internal_BUFFERCTRL_FIFO_WR_EN,
		BUFFER_FIFO_DIN 		=> internal_BUFFERCTRL_FIFO_DIN,
		EVTBUILD_START	 		=> internal_READCTRL_evtbuild_start,
		EVTBUILD_MAKE_READY	=> internal_READCTRL_evtbuild_make_ready
	);
	internal_READCTRL_readout_continue <= internal_CMDREG_READCTRL_readout_continue;
	
	--Buffer FIFO, contains up to 512 32-bit words (will not lead to USB packet drops)
	u_buffer_wr32_rd32 : buffer_fifo_wr32_rd32
   PORT MAP (
		rst 		=> internal_BUFFERCTRL_FIFO_RESET,
		wr_clk	=> internal_BUFFERCTRL_FIFO_WR_CLK,
		rd_clk 	=> internal_EVTBUILD_FIFO_READ_CLOCK,
		din 		=> internal_BUFFERCTRL_FIFO_DIN,
		wr_en 	=> internal_BUFFERCTRL_FIFO_WR_EN,
		rd_en 	=> internal_EVTBUILD_FIFO_READ_ENABLE,
		dout 		=> internal_EVTBUILD_FIFO_DATA_OUT,
		full 		=> open,
		empty 	=> internal_EVTBUILD_FIFO_EMPTY,
		valid 	=> internal_EVTBUILD_FIFO_DATA_VALID
	);
	
	--Event builder provides ordered waveform data to readout_interfaces module
	map_event_builder: entity work.event_builder PORT MAP(
		READ_CLOCK 					=> internal_READOUT_READ_CLOCK,
		SCROD_REV_AND_ID_WORD 	=> internal_SCROD_REV_AND_ID_WORD,
		EVENT_NUMBER_WORD 		=> internal_READCTRL_EVENT_NUM,
		EVENT_TYPE_WORD 			=> x"65766e74",
		EVENT_FLAG_WORD 			=> x"00000000",
		NUMBER_OF_WAVEFORM_PACKETS_WORD => x"00000000",
		START_BUILDING_EVENT 	=> internal_EVTBUILD_START_BUILDING_EVENT,
		DONE_SENDING_EVENT 		=> internal_EVTBUILD_DONE_SENDING_EVENT,
		MAKE_READY 					=> internal_EVTBUILD_MAKE_READY,
		WAVEFORM_FIFO_DATA 		=> internal_EVTBUILD_FIFO_DATA_OUT,
		WAVEFORM_FIFO_DATA_VALID => internal_EVTBUILD_FIFO_DATA_VALID,
		WAVEFORM_FIFO_EMPTY 		=> internal_EVTBUILD_FIFO_EMPTY,
		WAVEFORM_FIFO_READ_ENABLE => internal_EVTBUILD_FIFO_READ_ENABLE,
		WAVEFORM_FIFO_READ_CLOCK => internal_EVTBUILD_FIFO_READ_CLOCK,
		FIFO_DATA_OUT 				=> internal_READOUT_DATA_OUT,
		FIFO_DATA_VALID 			=> internal_READOUT_DATA_VALID,
		FIFO_EMPTY					=> internal_READOUT_EMPTY,
		FIFO_READ_ENABLE 			=> internal_READOUT_READ_ENABLE
	);
	internal_EVTBUILD_START_BUILDING_EVENT <= internal_READCTRL_evtbuild_start when internal_CMDREG_READCTRL_toggle_manual = '0' else
							 internal_CMDREG_EVTBUILD_START_BUILDING_EVENT;
	internal_EVTBUILD_MAKE_READY <= internal_READCTRL_evtbuild_make_ready when internal_CMDREG_READCTRL_toggle_manual = '0' else
							 internal_CMDREG_EVTBUILD_MAKE_READY;
	internal_SCROD_REV_AND_ID_WORD <= x"00" & x"A3" & x"002c";
	--internal_EVTBUILD_START_BUILDING_EVENT <= internal_CMDREG_EVTBUILD_START_BUILDING_EVENT;
	--internal_EVTBUILD_MAKE_READY <= internal_CMDREG_EVTBUILD_MAKE_READY;
	
	gen_trigger_counters : for i in 0 to 9 generate
		--u_trigger_scaler_single_channel: entity work.trigger_scaler_single_channel Port Map ( 
		u_trigger_scaler_single_channel_w_timing_gen: entity work.trigger_scaler_single_channel_w_timing_gen Port Map ( --IM 6/5/14: now using the combined trigger scaler timing gen block inctead

			SIGNAL_TO_COUNT => internal_TRIGGER_ASIC(i),
			CLOCK           => internal_CLOCK_50MHz_BUFG,
			READ_ENABLE_IN     => internal_TRIGCOUNT_ena,
			RESET_COUNTER   => internal_TRIGCOUNT_rst,
			READ_ENABLE_TIMER => internal_READ_ENABLE_TIMER(i),
			SCALER          => internal_TRIGCOUNT_scaler(i)
		);
	end generate;

---------------------------
-- MPPC Current measurement ADC: MPC3221
---------------------------
	inst_mpc_adc: entity work.Module_ADC_MCP3221_I2C_new
	port map(
		clock			 => internal_CLOCK_50MHz_BUFG,
		reset			=>	internal_CurrentADC_reset,
		
		sda	=> SDA_MON,--internal_SDA,
		scl	=> internal_SCL,
		 
		runADC		=> internal_runADC,
		enOutput		=> internal_enOutput,
		ADCOutput	=> internal_ADCOutput

	);


	--------------
	-- MPPC DACs
	--------------
	inst_mpps_dacs : entity work.mppc_dacs
	Port map(
		------------CLOCK-----------------
		CLOCK			 => internal_CLOCK_4MHz_BUFG,
		------------DAC PARAMETERS--------
		DAC_NUMBER   => i_dac_number,
		DAC_ADDR     => i_dac_addr,
		DAC_VALUE    => i_dac_value,
		WRITE_STROBE => i_dac_update_extended,
		------------HW INTERFACE----------
		SCK_DAC		 => i_hv_sck_dac,
		DIN_DAC		 => i_hv_din_dac,
		CS_DAC       => TDC_CS_DAC
	);
   --TDC_CS_DAC <= "0000000000";
	BUSA_SCK_DAC <= i_hv_sck_dac;
	BUSB_SCK_DAC <= i_hv_sck_dac;
	BUSA_DIN_DAC <= i_hv_din_dac;
	BUSB_DIN_DAC <= i_hv_din_dac;

	inst_pulse_extent : entity work.pulse_transition
	Generic map(
		CLOCK_RATIO  => 20
	)
	Port map(
		CLOCK_IN     => internal_CLOCK_50MHz_BUFG,
		D_IN         => i_dac_update,
		CLOCK_OUT    => internal_CLOCK_4MHz_BUFG,
		D_OUT        => i_dac_update_extended
	);

end Behavioral;
