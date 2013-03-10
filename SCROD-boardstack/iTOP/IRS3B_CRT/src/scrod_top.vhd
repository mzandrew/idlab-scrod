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
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;
use work.asic_definitions_irs2_carrier_revA.all;
use work.CarrierRevA_DAC_definitions.all;

entity scrod_top is
	Port(
		BOARD_CLOCKP                : in  STD_LOGIC;
		BOARD_CLOCKN                : in  STD_LOGIC;
		LEDS                        : out STD_LOGIC_VECTOR(15 downto 0);
		------------------FTSW/CLK_FIN pins------------------
		RJ45_ACK_P                  : out std_logic;
		RJ45_ACK_N                  : out std_logic;			  
		RJ45_TRG_P                  : in std_logic;
		RJ45_TRG_N                  : in std_logic;			  			  
		RJ45_RSV_P                  : out std_logic;
		RJ45_RSV_N                  : out std_logic;
		RJ45_CLK_P                  : in std_logic;
		RJ45_CLK_N                  : in std_logic;
		---------Jumper for choosing distributed clock------
		MONITOR_INPUT               : in  std_logic_vector(0 downto 0);
		------------------I2C pins-------------------
		--Bus A handles SCROD temperature sensor and SCROD EEPROM
		I2C_BUSA_SCL                : inout STD_LOGIC;
		I2C_BUSA_SDA                : inout STD_LOGIC;
		--Bus B handles SCROD fiberoptic transceiver 0
		I2C_BUSB_SCL                : inout STD_LOGIC;
		I2C_BUSB_SDA                : inout STD_LOGIC;
		--Bus C handles SCROD fiberoptic transceiver 1
		I2C_BUSC_SCL                : inout STD_LOGIC;
		I2C_BUSC_SDA                : inout STD_LOGIC;
		--Bus D handles carrier level temperature sensor
		--I2C_BUSD_SCL                : inout STD_LOGIC;
		--I2C_BUSD_SDA                : inout STD_LOGIC;
		--BUS E - GPIOs to read ASIC shregs rows 0 and 1
		I2C_SCL_GPIO12_R01						: inout STD_LOGIC;
		I2C_SDA_GPIO12_R01						: inout STD_LOGIC;
		--BUS F - GPIOs to read ASIC shregs rosw 2 and 3
		I2C_SCL_GPIO12_R23						: inout STD_LOGIC;
		I2C_SDA_GPIO12_R23						: inout STD_LOGIC;
		--BUS G - Temp, EEPROMs, CAL,SMPLSEL,AMP rows 0 and 1
		I2C_SCL_temperature_eeprom_GPIO0_R01						: inout STD_LOGIC;
		I2C_SDA_temperature_eeprom_GPIO0_R01						: inout STD_LOGIC;
		--BUS H - Temp, EEPROMs, CAL,SMPLSEL,AMP rows 2 and 3
		I2C_SCL_temperature_eeprom_GPIO0_R23						: inout STD_LOGIC;
		I2C_SDA_temperature_eeprom_GPIO0_R23						: inout STD_LOGIC;
		--BUS I - Vadjn/p rows 0 and 1 -- need to not activate internal - reg 43 and reg 45 set to 0?
		I2C_DAC_SCL_R01						: inout STD_LOGIC;
		I2C_DAC_SDA_R01						: inout STD_LOGIC;
		--BUS J - Vadjn/p rows 2 and 3
		I2C_DAC_SCL_R23						: inout STD_LOGIC;
		I2C_DAC_SDA_R23						: inout STD_LOGIC;
		--BUS K - channel calibration signals
      I2C_CAL_SDA                 : inout STD_LOGIC;
      I2C_CAL_SCL                 : inout STD_LOGIC;

		----------------------------------------------
		------------ASIC Related Pins-----------------
		----------------------------------------------
		--ASIC trigger interface signals
		AsicOut_TRIG_OUTPUT_R0_C0_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R0_C1_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R0_C2_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R0_C3_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R1_C0_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R1_C1_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R1_C2_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R1_C3_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R2_C0_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R2_C1_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R2_C2_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R2_C3_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R3_C0_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R3_C1_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R3_C2_CH	: in std_logic_vector(7 downto 0);
		AsicOut_TRIG_OUTPUT_R3_C3_CH	: in std_logic_vector(7 downto 0);
		--ASIC sampling and analog storage signals
		AsicIn_SAMPLING_HOLD_MODE_C               : out std_logic_vector(ASICS_PER_ROW-1 downto 0);
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS        : out std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 1);
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : out std_logic;
		AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C     : out std_logic_vector(ASICS_PER_ROW-1 downto 0);
		--ASIC digitization signals
		AsicIn_STORAGE_TO_WILK_ENABLE             : out std_logic;
		AsicIn_WILK_COUNTER_RESET                 : out std_logic;
		AsicIn_WILK_COUNTER_START_C               : out std_logic_vector(ASICS_PER_ROW-1 downto 0);
		AsicIn_WILK_RAMP_ACTIVE                   : out std_logic;
		--ASIC readout signals
		AsicOut_DATA_BUS_C0                       : in  std_logic_vector(11 downto 0);
		AsicOut_DATA_BUS_C1                       : in  std_logic_vector(11 downto 0);
		AsicOut_DATA_BUS_C2                       : in  std_logic_vector(11 downto 0);
		AsicOut_DATA_BUS_C3                       : in  std_logic_vector(11 downto 0);
		AsicIn_DATA_OUTPUT_DISABLE_R     			: out std_logic_vector(ASICS_PER_ROW-1 downto 0);
		--ASIC Wilkinson monitoring pins
		AsicOut_MONITOR_WILK_COUNTER_C0_R : in std_logic_vector(3 downto 0);
		AsicOut_MONITOR_WILK_COUNTER_C1_R : in std_logic_vector(3 downto 0);
		AsicOut_MONITOR_WILK_COUNTER_C2_R : in std_logic_vector(3 downto 0);
		AsicOut_MONITOR_WILK_COUNTER_C3_R : in std_logic_vector(3 downto 0);
		--Internal ASIC DAC shift register control
		AsicIn_CLEAR_ALL_REGISTERS : out std_logic;
		AsicIn_SERIAL_SHIFT_CLOCK : out std_logic;
		AsicIn_SERIAL_INPUT  : out std_logic;
		AsicIn_PARALLEL_CLOCK_C0_R : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C1_R : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C2_R : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C3_R : out std_logic_vector(3 downto 0);
		--DO shift register control (serial/increment interface for sample / channel select)
		AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK  : out std_logic;
		AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR : out std_logic;
		AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT  : out std_logic;
		--RD shift register control (serial/increment interface for storage to wilkinson address)
		AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK  : out std_logic;
		AsicIn_STORAGE_TO_WILK_ADDRESS_DIR: out std_logic;
		AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT : out std_logic;
		
		---------------------------------------------
		-- Monitorinf/feedbacks----------------------
		---------------------------------------------	
		--SSXMON	
		AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C0_R : in  STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C1_R : in  STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C2_R : in  STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C3_R : in  STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		--MONTIMING
		AsicOut_SAMPLING_TIMING_MONITOR_C0_R : in STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		AsicOut_SAMPLING_TIMING_MONITOR_C1_R : in STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		AsicOut_SAMPLING_TIMING_MONITOR_C2_R : in STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED
		AsicOut_SAMPLING_TIMING_MONITOR_C3_R : in STD_LOGIC_VECTOR(3 downto 0); --LM: TBIMPLEMENTED

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
		USB_CLKOUT		             : in  STD_LOGIC
		
		------------------------------------------------------------------------
		-- Monitorin pins - TO BE CHANGED FOR Intctc REVB!----------------------
		------------------------------------------------------------------------		
		
		--MON0 : out std_logic;
		--MON1 : out std_logic;
		--MON2 : out std_logic;
		--MON3 : out std_logic
		
	);
end scrod_top;

architecture Behavioral of scrod_top is
	signal internal_BOARD_CLOCK      : std_logic;
	signal internal_CLOCK_50MHz_BUFG : std_logic;
	signal internal_CLOCK_4MHz_BUFG  : std_logic;
	signal internal_CLOCK_ENABLE_I2C : std_logic;
	signal internal_CLOCK_SST_BUFG   : std_logic;
	signal internal_CLOCK_4xSST_BUFG : std_logic;
	
	signal internal_OUTPUT_REGISTERS : GPR;
	signal internal_INPUT_REGISTERS  : RR;
	signal internal_SAMPLING_TO_STORAGE_ADDRESS    :  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
 
	--Trigger readout
	signal internal_SOFTWARE_TRIGGER : std_logic;
	signal internal_HARDWARE_TRIGGER : std_logic;
	--Vetoes for the triggers
	signal internal_SOFTWARE_TRIGGER_VETO : std_logic;
	signal internal_HARDWARE_TRIGGER_VETO : std_logic;
	--ASIC trigger signals
	signal internal_ASIC_TRIGGER_BITS_C_R_CH  : COL_ROW_TRIGGER_BITS;
	signal internal_TRIGGER_SCALER_ROW_SELECT : std_logic_vector(ROW_SELECT_BITS-1 downto 0);
	signal internal_TRIGGER_SCALER_COL_SELECT : std_logic_vector(COL_SELECT_BITS-1 downto 0);
	signal internal_ASIC_SCALERS_TO_READ      : ASIC_TRIGGER_SCALERS;
	--ASIC Wilkinson feedback signals
	signal internal_WILKINSON_TARGETS         : Column_Row_Wilkinson_Counters;
	signal internal_WILKINSON_COUNTERS        : Column_Row_Wilkinson_Counters;
	--ASIC readout signals
	signal internal_ASIC_READOUT_TRISTATE_DISABLE : Column_Row_Enables;
	signal internal_ASIC_READOUT_DATA             : ASIC_DATA_C;
	--indirectly related to ASIC readout
	signal internal_WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER : std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0);
	signal internal_ROI_ADDRESS_ADJUST           : std_logic_vector(TRIGGER_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_WAVEFORM_FIFO_DATA_OUT       : std_logic_vector(31 downto 0);
	signal internal_WAVEFORM_FIFO_EMPTY          : std_logic;
	signal internal_WAVEFORM_FIFO_DATA_VALID     : std_logic;
	signal internal_WAVEFORM_FIFO_READ_CLOCK     : std_logic;
	signal internal_WAVEFORM_FIFO_READ_ENABLE    : std_logic;
	signal internal_WAVEFORM_PACKET_BUILDER_BUSY : std_logic;
	signal internal_WAVEFORM_PACKET_BUILDER_VETO : std_logic;
	signal internal_SAMPLING_TO_STORAGE_ADDRESS_LSB : std_logic;
	signal internal_STORAGE_TO_WILK_ADDRESS            :  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0); --LM now internal - converted into RD_SH*
	signal internal_STORAGE_TO_WILK_ADDRESS_ENABLE     :  std_logic; --LM:  now internal - uses RD_SH* signals
	signal internal_STORAGE_TO_WILK_ENABLE             :  std_logic;
	signal internal_DATA_BUS_OUTPUT_ENABLE             :  std_logic; --LM now sampselany - from a GPIO...
	signal internal_DATA_BUS_SAMPLE_ADDRESS            :  std_logic_vector(SAMPLE_SELECT_BITS-1 downto 0); --LM now DO_SHfts
	signal internal_DATA_BUS_CHANNEL_ADDRESS           :  std_logic_vector(CH_SELECT_BITS-1 downto 0);
		 
	--registers related to ASIC readout
	signal internal_FIRST_ALLOWED_WINDOW         : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_LAST_ALLOWED_WINDOW          : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_MAX_WINDOWS_TO_LOOK_BACK     : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_MIN_WINDOWS_TO_LOOK_BACK     : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_PEDESTAL_WINDOW              : STD_LOGIC_VECTOR(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_PEDESTAL_MODE                : STD_LOGIC;
	signal internal_SCROD_REV_AND_ID_WORD        : STD_LOGIC_VECTOR(31 downto 0);
	signal internal_EVENT_NUMBER_TO_SET          : STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); --This is what event number will be set to when set event number is enabled
	signal internal_SET_EVENT_NUMBER             : STD_LOGIC;
	signal internal_EVENT_NUMBER                 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	signal internal_FORCE_CHANNEL_MASK           : STD_LOGIC_VECTOR(TOTAL_TRIGGER_BITS-1 downto 0);
	signal internal_IGNORE_CHANNEL_MASK          : STD_LOGIC_VECTOR(TOTAL_TRIGGER_BITS-1 downto 0);

	--ASIC related, but actually I2C signals
	signal internal_DESIRED_DAC_VOLTAGES      : Board_Stack_Voltages;
	signal internal_DAC_UPDATE_STATUSES       : Board_Stack_DAC_Statuses;
	signal internal_WILK_DAC_VALUES_STATIC    : Column_Row_DAC_Values;
	signal internal_WILK_DAC_VALUES_FEEDBACK  : Column_Row_DAC_Values;
	signal internal_WILK_FEEDBACK_ENABLES     : Column_Row_Enables;
	signal internal_VADJP_DAC_VALUES_STATIC   : Column_Row_DAC_Values;
	signal internal_VADJP_DAC_VALUES_FEEDBACK : Column_Row_DAC_Values;
	signal internal_VADJN_DAC_VALUES_STATIC   : Column_Row_DAC_Values;
	signal internal_VADJN_DAC_VALUES_FEEDBACK : Column_Row_DAC_Values;
	signal internal_VADJ_FEEDBACK_ENABLES     : Column_Row_Enables;
	signal internal_WBIAS_DAC_VALUES_STATIC   : Column_Row_DAC_Values;
	signal internal_WBIAS_DAC_VALUES_FEEDBACK : Column_Row_DAC_Values;
	signal internal_WBIAS_FEEDBACK_ENABLES    : Column_Row_Enables;
	signal internal_CLK_SSTx2 : std_logic;
	
	--I2C signals
	signal internal_I2C_BUSA_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSA_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSA_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSA_SEND_START       : std_logic;
	signal internal_I2C_BUSA_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSA_READ_BYTE        : std_logic;
	signal internal_I2C_BUSA_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSA_SEND_STOP        : std_logic;
	signal internal_I2C_BUSA_BUSY             : std_logic;
	signal internal_I2C_BUSB_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSB_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSB_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSB_SEND_START       : std_logic;
	signal internal_I2C_BUSB_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSB_READ_BYTE        : std_logic;
	signal internal_I2C_BUSB_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSB_SEND_STOP        : std_logic;
	signal internal_I2C_BUSB_BUSY             : std_logic;
	signal internal_I2C_BUSC_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSC_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSC_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSC_SEND_START       : std_logic;
	signal internal_I2C_BUSC_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSC_READ_BYTE        : std_logic;
	signal internal_I2C_BUSC_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSC_SEND_STOP        : std_logic;
	signal internal_I2C_BUSC_BUSY             : std_logic;
	
	signal internal_I2C_BUSD_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSD_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSD_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSD_SEND_START       : std_logic;
	signal internal_I2C_BUSD_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSD_READ_BYTE        : std_logic;
	signal internal_I2C_BUSD_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSD_SEND_STOP        : std_logic;
	signal internal_I2C_BUSD_BUSY             : std_logic;
	
	signal internal_I2C_BUSE_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSE_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSE_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSE_SEND_START       : std_logic;
	signal internal_I2C_BUSE_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSE_READ_BYTE        : std_logic;
	signal internal_I2C_BUSE_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSE_SEND_STOP        : std_logic;
	signal internal_I2C_BUSE_BUSY             : std_logic;
	
	signal internal_I2C_BUSF_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSF_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSF_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSF_SEND_START       : std_logic;
	signal internal_I2C_BUSF_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSF_READ_BYTE        : std_logic;
	signal internal_I2C_BUSF_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSF_SEND_STOP        : std_logic;
	signal internal_I2C_BUSF_BUSY             : std_logic;
	
	signal internal_I2C_BUSG_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSG_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSG_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSG_SEND_START       : std_logic;
	signal internal_I2C_BUSG_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSG_READ_BYTE        : std_logic;
	signal internal_I2C_BUSG_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSG_SEND_STOP        : std_logic;
	signal internal_I2C_BUSG_BUSY             : std_logic;
	
	signal internal_I2C_BUSH_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSH_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSH_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSH_SEND_START       : std_logic;
	signal internal_I2C_BUSH_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSH_READ_BYTE        : std_logic;
	signal internal_I2C_BUSH_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSH_SEND_STOP        : std_logic;
	signal internal_I2C_BUSH_BUSY             : std_logic;

	signal internal_I2C_BUSI_UPDATE 				: std_logic;
	signal internal_I2C_BUSI_ADDRESS 			: std_logic_vector(6 downto 0);
	signal internal_I2C_BUSI_COMMAND 			: std_logic_vector(3 downto 0);
	signal internal_I2C_BUSI_CHANNEL 			: std_logic_vector(3 downto 0);
	signal internal_I2C_BUSI_DAC_VALUE 			: std_logic_vector(11 downto 0);
	signal internal_I2C_BUSI_BUSY					: std_logic;
	signal internal_I2C_BUSI_SUCCEEDED			: std_logic;
	
	signal internal_I2C_BUSJ_UPDATE 				: std_logic;
	signal internal_I2C_BUSJ_ADDRESS 			: std_logic_vector(6 downto 0);
	signal internal_I2C_BUSJ_COMMAND 			: std_logic_vector(3 downto 0);
	signal internal_I2C_BUSJ_CHANNEL 			: std_logic_vector(3 downto 0);
	signal internal_I2C_BUSJ_DAC_VALUE 			: std_logic_vector(11 downto 0);
	signal internal_I2C_BUSJ_BUSY					: std_logic;
	signal internal_I2C_BUSJ_SUCCEEDED			: std_logic;

	signal internal_I2C_BUSK_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSK_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSK_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSK_SEND_START       : std_logic;
	signal internal_I2C_BUSK_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSK_READ_BYTE        : std_logic;
	signal internal_I2C_BUSK_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSK_SEND_STOP        : std_logic;
	signal internal_I2C_BUSK_BUSY             : std_logic;

	signal       FEEDBACK_SAMPLING_RATE_ENABLE                :  std_logic_vector(15 downto 0);
	signal 		BOARD_CLOCK :   STD_LOGIC;
	signal internal_LAST_WINDOW_SAMPLED : std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
	signal internal_DONE_SENDING_EVENT : std_logic;
	signal wait_for_trigger_counter : std_logic_vector(3 downto 0) := (others => '1');
	signal ready_for_new_trigger : std_logic := '1';
	signal waiting_end_count : std_logic := '0';
	signal trigger_start : std_logic := '0';
	signal internal_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : std_logic;
	signal debug_CLOCK_SST :std_logic;
	signal debug_CLOCK_SST_out :std_logic;

	signal internal_TEMP_OUT :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_0 :std_logic_vector(15 downto 0);	
	signal internal_TEMP_OUT_1 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_2 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_3 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_4 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_5 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_6 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_7 :std_logic_vector(15 downto 0);
	
	signal internal_TEMP_OUT_8 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_9 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_10 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_11 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_12 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_13 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_14 :std_logic_vector(15 downto 0);
	signal internal_TEMP_OUT_15 :std_logic_vector(15 downto 0);
	
	signal FORCE_ADDRESS_ASIC : std_logic_vector(3 downto 0);
	signal FORCE_ADDRESS_CHANNEL : std_logic_vector(2 downto 0);
	
	--Internal ASIC DAC loading signals, likely temporary
	signal load_ASIC_DACs : std_logic;
	signal THR1 : std_logic_vector(11 downto 0);
	signal THR2 : std_logic_vector(11 downto 0);
	signal THR3 : std_logic_vector(11 downto 0);
	signal THR4 : std_logic_vector(11 downto 0);
	signal THR5 : std_logic_vector(11 downto 0);
	signal THR6 : std_logic_vector(11 downto 0);
	signal THR7 : std_logic_vector(11 downto 0);
	signal THR8 : std_logic_vector(11 downto 0);
	signal VBDBIAS : std_logic_vector(11 downto 0);
	signal VBIAS : std_logic_vector(11 downto 0);
	signal VBIAS2 : std_logic_vector(11 downto 0);
	signal MiscReg : std_logic_vector(7 downto 0);
	signal WBDbias : std_logic_vector(11 downto 0);
	signal Wbias : std_logic_vector(11 downto 0);
	signal TCDbias : std_logic_vector(11 downto 0);
	signal TRGbias : std_logic_vector(11 downto 0);
	signal THDbias : std_logic_vector(11 downto 0);
	signal Tbbias : std_logic_vector(11 downto 0);
	signal TRGDbias : std_logic_vector(11 downto 0);
	signal TRGbias2 : std_logic_vector(11 downto 0);
	signal TRGthref : std_logic_vector(11 downto 0);
	signal LeadSSPin : std_logic_vector(7 downto 0);
	signal TrailSSPin : std_logic_vector(7 downto 0);
	signal LeadS1 : std_logic_vector(7 downto 0);
	signal TrailS1 : std_logic_vector(7 downto 0);
	signal LeadS2 : std_logic_vector(7 downto 0);
	signal TrailS2 : std_logic_vector(7 downto 0);
	signal LeadPHASE : std_logic_vector(7 downto 0);
	signal TrailPHASE : std_logic_vector(7 downto 0);
	signal LeadWR_STRB : std_logic_vector(7 downto 0);
	signal TrailWR_STRB : std_logic_vector(7 downto 0);
	signal TimGenReg : std_logic_vector(7 downto 0);
	signal PDDbias : std_logic_vector(11 downto 0);
	signal CMPbias : std_logic_vector(11 downto 0);
	signal PUDbias : std_logic_vector(11 downto 0);
	signal PUbias : std_logic_vector(11 downto 0);
	signal SBDbias : std_logic_vector(11 downto 0);
	signal Sbbias : std_logic_vector(11 downto 0);
	signal ISDbias : std_logic_vector(11 downto 0);
	signal ISEL : std_logic_vector(11 downto 0);
	signal VDDbias : std_logic_vector(11 downto 0);
	signal Vdly : std_logic_vector(11 downto 0);
	signal VAPDbias : std_logic_vector(11 downto 0);
	signal VadjP : std_logic_vector(11 downto 0);
	signal VANDbias : std_logic_vector(11 downto 0);
	signal VadjN : std_logic_vector(11 downto 0);
	signal PCLK_All : std_logic;
	signal SCLK_All : std_logic;
	signal SIN_All : std_logic;
	signal SHOUT : std_logic;
	signal DAC_done : std_logic;
	signal DAC_updating : std_logic;
	
begin 

	--Temporary! Following input/output signals set constant while associated modules are disabled
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK <= '0';
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK <= '0';
	AsicIn_STORAGE_TO_WILK_ENABLE <= '0';
	AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT <= '0';
	AsicIn_WILK_RAMP_ACTIVE <= '0';
	AsicIn_WILK_COUNTER_RESET <= '0';
	AsicIn_CLEAR_ALL_REGISTERS <= '0';
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR <= '0';
	AsicIn_STORAGE_TO_WILK_ADDRESS_DIR <= '0';
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT <= '0';
	AsicIn_WILK_COUNTER_START_C <= (others=>'0');
	AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK <= '0';
	AsicIn_DATA_OUTPUT_DISABLE_R <= (others=>'0');
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= (others=>'0');
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK <= '0';
	AsicIn_STORAGE_TO_WILK_ENABLE <= '0';
	AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT <= '0';
	AsicIn_WILK_RAMP_ACTIVE <= '0';
	AsicIn_WILK_COUNTER_RESET <= '0';
	AsicIn_CLEAR_ALL_REGISTERS <= '0';
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR <= '0';
	AsicIn_STORAGE_TO_WILK_ADDRESS_DIR <= '0';
	AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT <= '0';
	AsicIn_WILK_COUNTER_START_C <= (others=>'0');
	AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK <= '0';
	AsicIn_DATA_OUTPUT_DISABLE_R <= (others=>'0');
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= (others=>'0');
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '0';

	--AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE<=internal_SAMPLING_TO_STORAGE_ADDRESS_ENABLE;
	--Monitoring pins
	--MON0 <= AsicOut_SAMPLING_TIMING_MONITOR_C0_R(1); -- MONTIMING for chip 1 column 0
	--MON1 <= debug_CLOCK_SST_out; -- SSTin 
	--MON2 <= AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C0_R(1); -- RCO_SSX for chip 1 column 0
	--MON3 <= internal_SAMPLING_TO_STORAGE_ADDRESS(1); --WRADDR (LS)
	--MON1 <= internal_SAMPLING_TO_STORAGE_ADDRESS_ENABLE; -- WR_EN
	--MON1 <= AsicOut_MONITOR_WILK_COUNTER_C0_R(0); -- TSTout for chip 0 column 0
	--MON2 <= internal_STORAGE_TO_WILK_ENABLE; -- RD_EN!
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
		EXT_TRIGGER       => internal_HARDWARE_TRIGGER,
		--Select signal between the two
		USE_LOCAL_CLOCK   => MONITOR_INPUT(0),
		--General output clocks
		CLOCK_50MHz_BUFG  => internal_CLOCK_50MHz_BUFG,
		CLOCK_4MHz_BUFG   => internal_CLOCK_4MHz_BUFG,
		--ASIC control clocks
		CLOCK_SSTx4_BUFG  => internal_CLOCK_4xSST_BUFG,
		CLOCK_SST_BUFG    => internal_CLOCK_SST_BUFG,
		--ASIC output clocks
		ASIC_SST          => AsicIn_SAMPLING_HOLD_MODE_C,
		--ASIC_SSP          => AsicIn_SAMPLING_TRACK_MODE_C, --LM: not used now
		--ASIC_WR_STRB      => open, -- LM WRSTRB written internally
		CLK_SSTx2			=> internal_CLK_SSTx2, --LM Added - "almost" equivalent to WR_STRB, but used as a clock to sample PHAB
		ASIC_WR_ADDR_LSB  => internal_SAMPLING_TO_STORAGE_ADDRESS(0),
		ASIC_WR_ADDR_LSB_RAW => internal_SAMPLING_TO_STORAGE_ADDRESS_LSB,
		--Output clock enable for I2C things
		I2C_CLOCK_ENABLE  => internal_CLOCK_ENABLE_I2C,
		BOARD_CLOCK => BOARD_CLOCK,
		debug_CLOCK_SST => debug_CLOCK_SST
	);	
	
	--Interface to I2C bus A
	map_i2c_busA : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSA_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSA_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSA_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSA_SEND_START,
		SEND_BYTE         => internal_I2C_BUSA_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSA_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSA_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSA_SEND_STOP,
		BUSY              => internal_I2C_BUSA_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_BUSA_SCL,
		SDA               => I2C_BUSA_SDA
	);	
	--Interface to I2C bus B
	map_i2c_busB : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSB_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSB_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSB_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSB_SEND_START,
		SEND_BYTE         => internal_I2C_BUSB_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSB_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSB_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSB_SEND_STOP,
		BUSY              => internal_I2C_BUSB_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_BUSB_SCL,
		SDA               => I2C_BUSB_SDA
	);	
	--Interface to I2C bus C
	map_i2c_busC : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSC_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSC_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSC_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSC_SEND_START,
		SEND_BYTE         => internal_I2C_BUSC_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSC_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSC_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSC_SEND_STOP,
		BUSY              => internal_I2C_BUSC_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_BUSC_SCL,
		SDA               => I2C_BUSC_SDA
	);
	--Interface to I2C bus E - GPIOs to read ASIC shregs rows 0 and 1
	map_i2c_busE : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSE_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSE_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSE_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSE_SEND_START,
		SEND_BYTE         => internal_I2C_BUSE_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSE_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSE_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSE_SEND_STOP,
		BUSY              => internal_I2C_BUSE_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_SCL_GPIO12_R01,
		SDA               => I2C_SDA_GPIO12_R01
	);
	--Interface to I2C bus F -
	map_i2c_busF : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSF_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSF_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSF_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSF_SEND_START,
		SEND_BYTE         => internal_I2C_BUSF_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSF_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSF_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSF_SEND_STOP,
		BUSY              => internal_I2C_BUSF_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_SCL_GPIO12_R23,
		SDA               => I2C_SDA_GPIO12_R23
	);
	--Interface to I2C bus G - 
	map_i2c_busG : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSG_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSG_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSG_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSG_SEND_START,
		SEND_BYTE         => internal_I2C_BUSG_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSG_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSG_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSG_SEND_STOP,
		BUSY              => internal_I2C_BUSG_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_SCL_temperature_eeprom_GPIO0_R01,
		SDA               => I2C_SDA_temperature_eeprom_GPIO0_R01
	);
	--Interface to I2C bus H - 
	map_i2c_busH : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSH_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSH_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSH_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSH_SEND_START,
		SEND_BYTE         => internal_I2C_BUSH_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSH_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSH_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSH_SEND_STOP,
		BUSY              => internal_I2C_BUSH_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_SCL_temperature_eeprom_GPIO0_R23,
		SDA               => I2C_SDA_temperature_eeprom_GPIO0_R23
	);
	
	--BUS I - Vadjn/p rows 0 and 1
	Inst_LTC2637_I2C_Interface_BusI: entity work.LTC2637_I2C_Interface PORT MAP(
		SCL => I2C_DAC_SCL_R01,
		SDA => I2C_DAC_SDA_R01,
		CLK => internal_CLOCK_4MHz_BUFG,
		CLK_ENABLE => internal_CLOCK_ENABLE_I2C,
		ADDRESS => internal_I2C_BUSI_ADDRESS,
		COMMAND => internal_I2C_BUSI_COMMAND,
		CHANNEL => internal_I2C_BUSI_CHANNEL,
		DAC_VALUE => internal_I2C_BUSI_DAC_VALUE,
		UPDATE => internal_I2C_BUSI_UPDATE,
		UPDATING => internal_I2C_BUSI_BUSY,
		UPDATE_SUCCEEDED => internal_I2C_BUSI_SUCCEEDED
	);
	
	--BUS J - Vadjn/p rows 2 and 3
	Inst_LTC2637_I2C_Interface_BusJ: entity work.LTC2637_I2C_Interface PORT MAP(
		SCL => I2C_DAC_SCL_R23,
		SDA => I2C_DAC_SDA_R23,
		CLK => internal_CLOCK_4MHz_BUFG,
		CLK_ENABLE => internal_CLOCK_ENABLE_I2C,
		ADDRESS => internal_I2C_BUSJ_ADDRESS,
		COMMAND => internal_I2C_BUSJ_COMMAND,
		CHANNEL => internal_I2C_BUSJ_CHANNEL,
		DAC_VALUE => internal_I2C_BUSJ_DAC_VALUE,
		UPDATE => internal_I2C_BUSJ_UPDATE,
		UPDATING => internal_I2C_BUSJ_BUSY,
		UPDATE_SUCCEEDED => internal_I2C_BUSJ_SUCCEEDED
	);
	
	--Interface to I2C bus K - channel calibration signals
	map_i2c_busK : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSK_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSK_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSK_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSK_SEND_START,
		SEND_BYTE         => internal_I2C_BUSK_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSK_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSK_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSK_SEND_STOP,
		BUSY              => internal_I2C_BUSK_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               =>  I2C_CAL_SCL,
		SDA               =>  I2C_CAL_SDA
	);
	
	--program to load ASIC internal DACs
	instance_Internal_ASIC_DAC_write : entity work.program_DACs port map(
		CLK => internal_CLOCK_50MHz_BUFG,
		do_load=> load_ASIC_DACs,
		--addr_load => addr_load,
		THR1 => THR1, --1
		THR2=>THR2, --2
		THR3=>THR3, --3
		THR4=>THR4, --4
		THR5=>THR5, --5
		THR6=>THR6, --6
		THR7=>THR7, --7
		THR8=>THR8, --8
		VBDBIAS=>VBDBIAS, --9
		VBIAS=>VBIAS, --10
		VBIAS2=>VBIAS2, --11
		MiscReg=>MiscReg, --12(incl. SGN)
		WBDbias=>WBDbias, --13
		Wbias=>Wbias, --14
		TCDbias=>TCDbias, --15
		TRGbias=>TRGbias,--16
		THDbias=>THDbias,--17
		Tbbias=>Tbbias,--18
		TRGDbias=>TRGDbias,--19
		TRGbias2=>TRGbias2,--20
		TRGthref=>TRGthref,--21
		LeadSSPin=>LeadSSPin,--22
		TrailSSPin=>TrailSSPIN,--23
		LeadS1=>LeadS1,--24
		TrailS1=>TrailS1,--25
		LeadS2=>LeadS2,--26
		TrailS2=>TrailS2,--27
		LeadPHASE=>LeadPHASE,--28
		TrailPHASE=>TrailPHASE,--29
		LeadWR_STRB=>LeadWR_STRB,--30
		TrailWR_STRB=>TrailWR_STRB,--31
		TimGenReg=>TimGenReg,--32
		PDDbias=>PDDbias,--33
		CMPbias=>CMPbias,--34
		PUDbias=>PUDbias,--35
		PUbias=>PUbias,--36
		SBDbias=>SBDbias,--37
		Sbbias=>Sbbias,--38
		ISDbias=>ISDbias,--39
		ISEL=>ISEL,--40 
		VDDbias=>VDDbias,--41
		Vdly=>Vdly,--42
		VAPDbias=>VAPDbias,--43
		VadjP=>VadjP,--44
		VANDbias=>VANDbias,--45
		VadjN=>VadjN,--46

		init_done => open,

		PCLK=>PCLK_All,
		SCLK=>SCLK_All,
		SIN=>SIN_All,
		SHOUT=>SHOUT,
		flag_done=>open,
		DAC_updating=>open
	);
	AsicIn_PARALLEL_CLOCK_C0_R<= (others => PCLK_All);
	AsicIn_PARALLEL_CLOCK_C1_R<= (others => PCLK_All);
	AsicIn_PARALLEL_CLOCK_C2_R<= (others => PCLK_All);
	AsicIn_PARALLEL_CLOCK_C3_R<= (others => PCLK_All);
	AsicIn_SERIAL_SHIFT_CLOCK <= SCLK_All;
	AsicIn_SERIAL_INPUT <= SIN_All;
	SHOUT <= '0'; --LM: now not connected - need FW for the GPIO

	--Scaler monitors for the ASIC channels
	--First we need to map the scalers into rows/cols
	--internal_ASIC_TRIGGER_BITS_C_R_CH(0)(0) <= AsicOut_TRIG_OUTPUT_R0_C0_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(0)(1) <= AsicOut_TRIG_OUTPUT_R1_C0_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(0)(2) <= AsicOut_TRIG_OUTPUT_R2_C0_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(0)(3) <= AsicOut_TRIG_OUTPUT_R3_C0_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(1)(0) <= AsicOut_TRIG_OUTPUT_R0_C1_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(1)(1) <= AsicOut_TRIG_OUTPUT_R1_C1_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(1)(2) <= AsicOut_TRIG_OUTPUT_R2_C1_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(1)(3) <= AsicOut_TRIG_OUTPUT_R3_C1_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(2)(0) <= AsicOut_TRIG_OUTPUT_R0_C2_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(2)(1) <= AsicOut_TRIG_OUTPUT_R1_C2_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(2)(2) <= AsicOut_TRIG_OUTPUT_R2_C2_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(2)(3) <= AsicOut_TRIG_OUTPUT_R3_C2_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(3)(0) <= AsicOut_TRIG_OUTPUT_R0_C3_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(3)(1) <= AsicOut_TRIG_OUTPUT_R1_C3_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(3)(2) <= AsicOut_TRIG_OUTPUT_R2_C3_CH;
	--internal_ASIC_TRIGGER_BITS_C_R_CH(3)(3) <= AsicOut_TRIG_OUTPUT_R3_C3_CH;
	--Then we instantiate the trigger scaler block
	--map_asic_trigger_scalers : entity work.trigger_scaler_top
	--port map (
	--	TRIGGER_BITS_IN => internal_ASIC_TRIGGER_BITS_C_R_CH,
	--	CLOCK           => internal_CLOCK_50MHz_BUFG,
	--	ROW_SELECT      => internal_TRIGGER_SCALER_ROW_SELECT,
	--	COL_SELECT      => internal_TRIGGER_SCALER_COL_SELECT,
	--	SCALERS         => internal_ASIC_SCALERS_TO_READ
	--);

	--ASIC monitoring and control for potential feedback paths
	--map_asic_feedback_and_monitoring : entity work.feedback_and_monitoring
	--port map (
	--	AsicOut_SAMPLING_TRACK_MODE_C0_R          => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C0_R,
	--	AsicOut_SAMPLING_TRACK_MODE_C1_R          => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C1_R,
	--	AsicOut_SAMPLING_TRACK_MODE_C2_R          => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C2_R,
	--	AsicOut_SAMPLING_TRACK_MODE_C3_R          => AsicOut_SAMPLING_TIMING_OUTPUT_SIGNAL_C3_R,
				
	--	FEEDBACK_SAMPLING_RATE_ENABLE            => FEEDBACK_SAMPLING_RATE_ENABLE, --LM: to fill with appropriate...? 
	--	--FEEDBACK_SAMPLING_RATE_COUNTER_C_R       => open,
	--	FEEDBACK_SAMPLING_RATE_VADJP_C_R         => open,
	--	FEEDBACK_SAMPLING_RATE_VADJN_C_R         => internal_VADJN_DAC_VALUES_FEEDBACK,
	
	--	AsicOut_MONITOR_WILK_COUNTERS_C0_R => AsicOut_MONITOR_WILK_COUNTER_C0_R,
	--	AsicOut_MONITOR_WILK_COUNTERS_C1_R => AsicOut_MONITOR_WILK_COUNTER_C1_R,
	--	AsicOut_MONITOR_WILK_COUNTERS_C2_R => AsicOut_MONITOR_WILK_COUNTER_C2_R,
	--	AsicOut_MONITOR_WILK_COUNTERS_C3_R => AsicOut_MONITOR_WILK_COUNTER_C3_R,
	--	FEEDBACK_WILKINSON_ENABLES_C_R     => internal_WILK_FEEDBACK_ENABLES,
	--	FEEDBACK_WILKINSON_GOALS_C_R       => internal_WILKINSON_TARGETS,
	--	FEEDBACK_WILKINSON_COUNTERS_C_R    => internal_WILKINSON_COUNTERS,
	--	FEEDBACK_WILKINSON_DAC_VALUES_C_R  => internal_WILK_DAC_VALUES_FEEDBACK,
		
	--	CLOCK                              => internal_CLOCK_50MHz_BUFG
	--);

	--ASIC sampling, digitization, and readout (SDR)
	--This includes sampling, selection of ROIs, digitizing, and readout
	--gen_asic_boe : for row in 0 to 3 generate
	--	AsicIn_DATA_BUS_OUTPUT_DISABLE_C0_R(row) <= internal_ASIC_READOUT_TRISTATE_DISABLE(0)(row);
	--	AsicIn_DATA_BUS_OUTPUT_DISABLE_C1_R(row) <= internal_ASIC_READOUT_TRISTATE_DISABLE(1)(row);
	--	AsicIn_DATA_BUS_OUTPUT_DISABLE_C2_R(row) <= internal_ASIC_READOUT_TRISTATE_DISABLE(2)(row);
	--	AsicIn_DATA_BUS_OUTPUT_DISABLE_C3_R(row) <= internal_ASIC_READOUT_TRISTATE_DISABLE(3)(row);
	--end generate;
	--internal_ASIC_READOUT_DATA(0) <= AsicOut_DATA_BUS_C0;
	--internal_ASIC_READOUT_DATA(1) <= AsicOut_DATA_BUS_C1;
	--internal_ASIC_READOUT_DATA(2) <= AsicOut_DATA_BUS_C2;
	--internal_ASIC_READOUT_DATA(3) <= AsicOut_DATA_BUS_C3;
	--AsicIn_SAMPLING_TO_STORAGE_ADDRESS <= internal_SAMPLING_TO_STORAGE_ADDRESS(ANALOG_MEMORY_ADDRESS_BITS-1 downto 1); --LSB not used - generated internally in IRS3B
	--AsicIn_STORAGE_TO_WILK_ENABLE <= internal_STORAGE_TO_WILK_ENABLE;
	
	--map_irs2_sdr : entity work.irs2_sampling_digitizing_readout
	--port map (
	--	--Clock for running the analog memory manager
	--	CLOCK_SAMPLING_HOLD_MODE              => internal_CLOCK_SST_BUFG,
	--	--Clock for monitoring the trigger memory and phase
	--	CLOCK_TRIGGER_MEMORY                  => internal_CLOCK_4xSST_BUFG,
	--	--Primary clock for ROI and digitizing (set nominally for 50 MHz)
	--	CLOCK                                 => internal_CLOCK_50MHz_BUFG,
	--	--Clock to sample PHAB - needs to be at least 2xSST
	--	internal_CLK_SSTx2 						  => internal_CLK_SSTx2,
	--	--Trigger inputs
	--	SOFTWARE_TRIGGER_IN                   => internal_SOFTWARE_TRIGGER,
	--	HARDWARE_TRIGGER_IN                   => internal_HARDWARE_TRIGGER,
	--	--Trigger vetoes
	--	SOFTWARE_TRIGGER_VETO                 => internal_SOFTWARE_TRIGGER_VETO,
	--	HARDWARE_TRIGGER_VETO                 => internal_HARDWARE_TRIGGER_VETO,		
	--	--User registers
	--	FIRST_ALLOWED_WINDOW                  => internal_FIRST_ALLOWED_WINDOW,
	--	LAST_ALLOWED_WINDOW                   => internal_LAST_ALLOWED_WINDOW,
	--	ROI_ADDRESS_ADJUST                    => internal_ROI_ADDRESS_ADJUST,
	--	MAX_WINDOWS_TO_LOOK_BACK              => internal_MAX_WINDOWS_TO_LOOK_BACK,
	--	MIN_WINDOWS_TO_LOOK_BACK              => internal_MIN_WINDOWS_TO_LOOK_BACK,
	--	WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER  => internal_WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER,
	--	PEDESTAL_WINDOW                       => internal_PEDESTAL_WINDOW,
	--	PEDESTAL_MODE                         => internal_PEDESTAL_MODE,
	--	SCROD_REV_AND_ID_WORD                 => internal_SCROD_REV_AND_ID_WORD,
	--	EVENT_NUMBER_TO_SET                   => internal_EVENT_NUMBER_TO_SET,
	--	SET_EVENT_NUMBER                      => internal_SET_EVENT_NUMBER,
	--	EVENT_NUMBER                          => internal_EVENT_NUMBER,
	--	FORCE_CHANNEL_MASK                    => internal_FORCE_CHANNEL_MASK,
	--	IGNORE_CHANNEL_MASK                   => internal_IGNORE_CHANNEL_MASK,
	--	--Sampling signals and controls for writing to analog memory
	--	ASIC_SAMPLING_TO_STORAGE_ADDRESS_NO_LSB => internal_SAMPLING_TO_STORAGE_ADDRESS(ANALOG_MEMORY_ADDRESS_BITS-1 downto 1),
	--	  --The LSB here is handled by the clocking block.  We take a copy so we have access to it
	--	  --in the trigger memory logic.
	--	ASIC_SAMPLING_TO_STORAGE_ADDRESS_LSB    => internal_SAMPLING_TO_STORAGE_ADDRESS_LSB,
	--	ASIC_SAMPLING_TO_STORAGE_ENABLE         => internal_SAMPLING_TO_STORAGE_ADDRESS_ENABLE,
	--	PHAB => AsicOut_SAMPLING_TIMING_MONITOR_C0_R(0), -- LM added one MONTIMING that should be
																											-- will it be ok for all chips?
	--	LAST_WINDOW_SAMPLED => internal_LAST_WINDOW_SAMPLED,
	--	DONE_SENDING_EVENT => internal_DONE_SENDING_EVENT,
	--	--Digitization signals
	--	ASIC_STORAGE_TO_WILK_ADDRESS          => AsicIn_STORAGE_TO_WILK_ADDRESS,
	--	ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE   => AsicIn_STORAGE_TO_WILK_ADDRESS_ENABLE,
	--	ASIC_STORAGE_TO_WILK_ENABLE           => internal_STORAGE_TO_WILK_ENABLE,
	--	ASIC_STORAGE_TO_WILK_ADDRESS          => internal_STORAGE_TO_WILK_ADDRESS,
	--	ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE   => internal_STORAGE_TO_WILK_ADDRESS_ENABLE,
	--	ASIC_STORAGE_TO_WILK_ENABLE           => internal_STORAGE_TO_WILK_ENABLE,		
	--	ASIC_WILK_COUNTER_RESET               => AsicIn_WILK_COUNTER_RESET,
	--	ASIC_WILK_COUNTER_START               => AsicIn_WILK_COUNTER_START_C,
	--	ASIC_WILK_RAMP_ACTIVE                 => AsicIn_WILK_RAMP_ACTIVE,
	--	
	-- RD (serial/increment interface for storage to wilkinson address)
	-- - AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK  => AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK, --: out std_logic;
	-- - AsicIn_STORAGE_TO_WILK_ADDRESS_DIR => AsicIn_STORAGE_TO_WILK_ADDRESS_DIR, --out std_logic;
	-- AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT => AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT, -- : out std_logic;		
	--	--Readout signals
	--	ASIC_READOUT_CHANNEL_ADDRESS          => internal_DATA_BUS_CHANNEL_ADDRESS,
	--	ASIC_READOUT_SAMPLE_ADDRESS           => internal_DATA_BUS_SAMPLE_ADDRESS,
	--	ASIC_READOUT_ENABLE                   => internal_DATA_BUS_OUTPUT_ENABLE,
	--	ASIC_READOUT_TRISTATE_DISABLE         => internal_ASIC_READOUT_TRISTATE_DISABLE,
	--	ASIC_READOUT_DATA                     => internal_ASIC_READOUT_DATA,
	-- DO (serial/increment interface for sample / channel select)
	--	GPIO_CAL_SCL							=>  SCL_temperature_eeprom_GPIO0_R01_dummy,-- To change SMPSELANY
	--	GPIO_CAL_SDA							=> SDA_temperature_eeprom_GPIO0_R01_dummy,
	--	GPIO_CAL_SCL01							=>  I2C_SCL_temperature_eeprom_GPIO0_R01,-- To change SMPSELANY carriers 2 and 3
	--	GPIO_CAL_SDA01							=> I2C_SDA_temperature_eeprom_GPIO0_R01,
	--	GPIO_CAL_SCL23							=>  I2C_SCL_temperature_eeprom_GPIO0_R23,-- To change SMPSELANY carriers 2 and 3
	--	GPIO_CAL_SDA23							=> I2C_SDA_temperature_eeprom_GPIO0_R23,
	-- AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK  => AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK,-- out std_logic;
	-- AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR => AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR, --: out std_logic;
	-- AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT  => AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT, --: out std_logic;
	--	--Trigger bits in to determine ROIs
	--	ASIC_TRIGGER_BITS                     => internal_ASIC_TRIGGER_BITS_C_R_CH,
	--	--FIFO data to send off as an event
	--	EVENT_FIFO_DATA_OUT                   => internal_WAVEFORM_FIFO_DATA_OUT,
	--	EVENT_FIFO_DATA_VALID                 => internal_WAVEFORM_FIFO_DATA_VALID,
	--	EVENT_FIFO_EMPTY                      => internal_WAVEFORM_FIFO_EMPTY,
	--	EVENT_FIFO_READ_CLOCK                 => internal_WAVEFORM_FIFO_READ_CLOCK,
	--	EVENT_FIFO_READ_ENABLE                => internal_WAVEFORM_FIFO_READ_ENABLE,
	--	EVENT_PACKET_BUILDER_BUSY             => internal_WAVEFORM_PACKET_BUILDER_BUSY,
	--	EVENT_PACKET_BUILDER_VETO             => internal_WAVEFORM_PACKET_BUILDER_VETO,
--		internal_CHIPSCOPE_CONTROL				  => CONTROL0,
--		ready_for_new_trigger					  => ready_for_new_trigger,
--		TEMP_OUT_chipscope						  => internal_TEMP_OUT,
--		TEMP_OUT_0_chipscope						  => internal_TEMP_OUT_0,
--		TEMP_OUT_1_chipscope						  => internal_TEMP_OUT_1,
--		TEMP_OUT_2_chipscope						  => internal_TEMP_OUT_2,
--		TEMP_OUT_3_chipscope						  => internal_TEMP_OUT_3,
--		TEMP_OUT_4_chipscope						  => internal_TEMP_OUT_4,
--		TEMP_OUT_5_chipscope						  => internal_TEMP_OUT_5,
--		TEMP_OUT_6_chipscope						  => internal_TEMP_OUT_6,
--		TEMP_OUT_7_chipscope						  => internal_TEMP_OUT_7,
--		TEMP_OUT_8_chipscope						  => internal_TEMP_OUT_8,
--		TEMP_OUT_9_chipscope						  => internal_TEMP_OUT_9,
--		TEMP_OUT_10_chipscope						  => internal_TEMP_OUT_10,
--		TEMP_OUT_11_chipscope						  => internal_TEMP_OUT_11,
--		TEMP_OUT_12_chipscope						  => internal_TEMP_OUT_12,
--		TEMP_OUT_13_chipscope						  => internal_TEMP_OUT_13,
--		TEMP_OUT_14_chipscope						  => internal_TEMP_OUT_14,
--		TEMP_OUT_15_chipscope						  => internal_TEMP_OUT_15,		
--		state_debug_temp							  => state_debug_temp2,
--		debug_state_i2c_busB						  => debug_state_i2c_busC,
--		address_debug								 => address_debug2,
--		pos_debug									=> pos_debug2,
--		FORCE_ADDRESS_CHANNEL					=> FORCE_ADDRESS_CHANNEL,
--		FORCE_ADDRESS_ASIC					=> FORCE_ADDRESS_ASIC		
--		new_address_reached				 		  => new_address_reached, --LM: updating address feedback
--		START_NEW_ADDRESS							  =>  START_NEW_ADDRESS --LM: start new address update
	--);

	--Interface to the DAQ devices
	map_readout_interfaces : entity work.readout_interface
	port map ( 
		CLOCK                        => internal_CLOCK_50MHz_BUFG,

		OUTPUT_REGISTERS             => internal_OUTPUT_REGISTERS,
		INPUT_REGISTERS              => internal_INPUT_REGISTERS,
	
		--super temporary -- disable waveform interface to event builder
		--WAVEFORM_FIFO_DATA_IN        => internal_WAVEFORM_FIFO_DATA_OUT,
		--WAVEFORM_FIFO_EMPTY          => internal_WAVEFORM_FIFO_EMPTY,
		--WAVEFORM_FIFO_DATA_VALID     => internal_WAVEFORM_FIFO_DATA_VALID,
		--WAVEFORM_FIFO_READ_CLOCK     => internal_WAVEFORM_FIFO_READ_CLOCK,
		--WAVEFORM_FIFO_READ_ENABLE    => internal_WAVEFORM_FIFO_READ_ENABLE,
		--WAVEFORM_PACKET_BUILDER_BUSY => internal_WAVEFORM_PACKET_BUILDER_BUSY,
		--WAVEFORM_PACKET_BUILDER_VETO => internal_WAVEFORM_PACKET_BUILDER_VETO,
		--WAVEFORM ROI readout disable for now
		WAVEFORM_FIFO_DATA_IN        => (others=>'0'),
		WAVEFORM_FIFO_EMPTY          => '1',
		WAVEFORM_FIFO_DATA_VALID     => '0',
		WAVEFORM_FIFO_READ_CLOCK     => open,
		WAVEFORM_FIFO_READ_ENABLE    => open,
		WAVEFORM_PACKET_BUILDER_BUSY => '0',
		WAVEFORM_PACKET_BUILDER_VETO => open,

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

	--------------------------------------------------
	-------Multiplexing to turn feedbacks on/off------
	--------------------------------------------------
	--proc_wilk_enables : process(internal_WILK_FEEDBACK_ENABLES, internal_WILK_DAC_VALUES_STATIC, internal_WILK_DAC_VALUES_FEEDBACK ) begin
	--	for col in 0 to 3 loop
	--		for row in 0 to 3 loop
	--			case internal_WILK_FEEDBACK_ENABLES(col)(row) is
	--				when '0' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(4) <= internal_WILK_DAC_VALUES_STATIC(col)(row);
	--				when '1' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(4) <= internal_WILK_DAC_VALUES_FEEDBACK(col)(row);
	--				when others => internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(4) <= (others => 'X');
	--			end case;
	--		end loop;
	--	end loop;
	--end process;
	--proc_vadjp_enables : process(internal_VADJ_FEEDBACK_ENABLES, internal_VADJP_DAC_VALUES_STATIC, internal_VADJP_DAC_VALUES_FEEDBACK ) begin
	--	for col in 0 to 3 loop
	--		for row in 0 to 3 loop
	--			case internal_VADJ_FEEDBACK_ENABLES(col)(row) is
	--				when '0' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(2) <= internal_VADJP_DAC_VALUES_STATIC(col)(row);
	--				when '1' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(2) <= internal_VADJP_DAC_VALUES_FEEDBACK(col)(row);
	--				when others => internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(2) <= (others => 'X');
	--			end case;
	--		end loop;
	--	end loop;
	--end process;
	--proc_vadjn_enables : process(internal_VADJ_FEEDBACK_ENABLES, internal_VADJN_DAC_VALUES_STATIC, internal_VADJN_DAC_VALUES_FEEDBACK ) begin
	--	for col in 0 to 3 loop
	--		for row in 0 to 3 loop
	--			case internal_VADJ_FEEDBACK_ENABLES(col)(row) is
	--				when '0' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(3) <= internal_VADJN_DAC_VALUES_STATIC(col)(row);
	--				when '1' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(3) <= internal_VADJN_DAC_VALUES_FEEDBACK(col)(row);
	--				when others => internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(3) <= (others => 'X');
	--			end case;
	--		end loop;
	--	end loop;
	--end process;
	--proc_wbias_enables : process(internal_WBIAS_FEEDBACK_ENABLES, internal_WBIAS_DAC_VALUES_STATIC, internal_WBIAS_DAC_VALUES_FEEDBACK ) begin
	--	for col in 0 to 3 loop
	--		for row in 0 to 3 loop
	--			case internal_WBIAS_FEEDBACK_ENABLES(col)(row) is
	--				when '0' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(7) <= internal_WBIAS_DAC_VALUES_STATIC(col)(row);
	--				when '1' => internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(7) <= internal_WBIAS_DAC_VALUES_FEEDBACK(col)(row);
	--				when others => internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(7) <= (others => 'X');
	--			end case;
	--		end loop;
	--	end loop;
	--end process;

	--------------------------------------------------
	-------General registers interfaced to DAQ -------
	--------------------------------------------------

	--------Output register mapping-------------------
	LEDS <= internal_OUTPUT_REGISTERS(0);                                               --Register 0: LEDs
	internal_I2C_BUSA_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(1)(7 downto 0); --Register 1: I2C BusA interfaces
	internal_I2C_BUSA_SEND_START           <= internal_OUTPUT_REGISTERS(1)(8);
	internal_I2C_BUSA_SEND_BYTE            <= internal_OUTPUT_REGISTERS(1)(9);
	internal_I2C_BUSA_READ_BYTE            <= internal_OUTPUT_REGISTERS(1)(10);
	internal_I2C_BUSA_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(1)(11);
	internal_I2C_BUSA_SEND_STOP            <= internal_OUTPUT_REGISTERS(1)(12);
	internal_I2C_BUSB_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(2)(7 downto 0); --Register 2: I2C BusB interfaces
	internal_I2C_BUSB_SEND_START           <= internal_OUTPUT_REGISTERS(2)(8);
	internal_I2C_BUSB_SEND_BYTE            <= internal_OUTPUT_REGISTERS(2)(9);
	internal_I2C_BUSB_READ_BYTE            <= internal_OUTPUT_REGISTERS(2)(10);
	internal_I2C_BUSB_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(2)(11);
	internal_I2C_BUSB_SEND_STOP            <= internal_OUTPUT_REGISTERS(2)(12);
	internal_I2C_BUSC_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(3)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSC_SEND_START           <= internal_OUTPUT_REGISTERS(3)(8);
	internal_I2C_BUSC_SEND_BYTE            <= internal_OUTPUT_REGISTERS(3)(9);
	internal_I2C_BUSC_READ_BYTE            <= internal_OUTPUT_REGISTERS(3)(10);
	internal_I2C_BUSC_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(3)(11);
	internal_I2C_BUSC_SEND_STOP            <= internal_OUTPUT_REGISTERS(3)(12);
	--Skip I2C Bus D
	internal_I2C_BUSE_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(5)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSE_SEND_START           <= internal_OUTPUT_REGISTERS(5)(8);
	internal_I2C_BUSE_SEND_BYTE            <= internal_OUTPUT_REGISTERS(5)(9);
	internal_I2C_BUSE_READ_BYTE            <= internal_OUTPUT_REGISTERS(5)(10);
	internal_I2C_BUSE_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(5)(11);
	internal_I2C_BUSE_SEND_STOP            <= internal_OUTPUT_REGISTERS(5)(12);
	internal_I2C_BUSF_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(6)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSF_SEND_START           <= internal_OUTPUT_REGISTERS(6)(8);
	internal_I2C_BUSF_SEND_BYTE            <= internal_OUTPUT_REGISTERS(6)(9);
	internal_I2C_BUSF_READ_BYTE            <= internal_OUTPUT_REGISTERS(6)(10);
	internal_I2C_BUSF_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(6)(11);
	internal_I2C_BUSF_SEND_STOP            <= internal_OUTPUT_REGISTERS(6)(12);
	internal_I2C_BUSG_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(7)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSG_SEND_START           <= internal_OUTPUT_REGISTERS(7)(8);
	internal_I2C_BUSG_SEND_BYTE            <= internal_OUTPUT_REGISTERS(7)(9);
	internal_I2C_BUSG_READ_BYTE            <= internal_OUTPUT_REGISTERS(7)(10);
	internal_I2C_BUSG_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(7)(11);
	internal_I2C_BUSG_SEND_STOP            <= internal_OUTPUT_REGISTERS(7)(12);
	internal_I2C_BUSH_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(8)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSH_SEND_START           <= internal_OUTPUT_REGISTERS(8)(8);
	internal_I2C_BUSH_SEND_BYTE            <= internal_OUTPUT_REGISTERS(8)(9);
	internal_I2C_BUSH_READ_BYTE            <= internal_OUTPUT_REGISTERS(8)(10);
	internal_I2C_BUSH_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(8)(11);
	internal_I2C_BUSH_SEND_STOP            <= internal_OUTPUT_REGISTERS(8)(12);
	--BUS I - note slightly different I2C interface for LTC2637
	internal_I2C_BUSI_UPDATE  <= internal_OUTPUT_REGISTERS(9)(11);
	internal_I2C_BUSI_ADDRESS <= internal_OUTPUT_REGISTERS(9)(6 downto 0);
	internal_I2C_BUSI_COMMAND <= internal_OUTPUT_REGISTERS(9)(10 downto 7);
	internal_I2C_BUSI_CHANNEL <= internal_OUTPUT_REGISTERS(10)(3 downto 0);
	internal_I2C_BUSI_DAC_VALUE <= internal_OUTPUT_REGISTERS(10)(15 downto 4);
	--Bus J - note slightly different I2C interface for LTC2637
	internal_I2C_BUSJ_UPDATE  <= internal_OUTPUT_REGISTERS(11)(11);
	internal_I2C_BUSJ_ADDRESS <= internal_OUTPUT_REGISTERS(11)(6 downto 0);
	internal_I2C_BUSJ_COMMAND <= internal_OUTPUT_REGISTERS(11)(10 downto 7);
	internal_I2C_BUSJ_CHANNEL <= internal_OUTPUT_REGISTERS(12)(3 downto 0);
	internal_I2C_BUSJ_DAC_VALUE <= internal_OUTPUT_REGISTERS(12)(15 downto 4);

	internal_I2C_BUSK_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(11)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSK_SEND_START           <= internal_OUTPUT_REGISTERS(11)(8);
	internal_I2C_BUSK_SEND_BYTE            <= internal_OUTPUT_REGISTERS(11)(9);
	internal_I2C_BUSK_READ_BYTE            <= internal_OUTPUT_REGISTERS(11)(10);
	internal_I2C_BUSK_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(11)(11);
	internal_I2C_BUSK_SEND_STOP            <= internal_OUTPUT_REGISTERS(11)(12);
	
	--Internal ASIC DAC writing signals, temporary implementation
	load_ASIC_DACs <= internal_OUTPUT_REGISTERS(19)(0);
	THR1 <= internal_OUTPUT_REGISTERS(20)(11 downto 0);
	THR2 <= internal_OUTPUT_REGISTERS(21)(11 downto 0);
	THR3 <= internal_OUTPUT_REGISTERS(22)(11 downto 0);
	THR4 <= internal_OUTPUT_REGISTERS(23)(11 downto 0);
	THR5 <= internal_OUTPUT_REGISTERS(24)(11 downto 0);
	THR6 <= internal_OUTPUT_REGISTERS(25)(11 downto 0);
	THR7 <= internal_OUTPUT_REGISTERS(26)(11 downto 0);
	THR8 <= internal_OUTPUT_REGISTERS(27)(11 downto 0);
	VBDBIAS <= internal_OUTPUT_REGISTERS(28)(11 downto 0);
	VBIAS <= internal_OUTPUT_REGISTERS(29)(11 downto 0);
	VBIAS2 <= internal_OUTPUT_REGISTERS(30)(11 downto 0);
	MiscReg <= internal_OUTPUT_REGISTERS(31)(7 downto 0);
	WBDbias <= internal_OUTPUT_REGISTERS(32)(11 downto 0);
	Wbias <= internal_OUTPUT_REGISTERS(33)(11 downto 0);
	TCDbias <= internal_OUTPUT_REGISTERS(34)(11 downto 0);
	TRGbias <= internal_OUTPUT_REGISTERS(35)(11 downto 0);
	THDbias <= internal_OUTPUT_REGISTERS(36)(11 downto 0);
	Tbbias <= internal_OUTPUT_REGISTERS(37)(11 downto 0);
	TRGDbias <= internal_OUTPUT_REGISTERS(38)(11 downto 0);
	TRGbias2 <= internal_OUTPUT_REGISTERS(39)(11 downto 0);
	TRGthref <= internal_OUTPUT_REGISTERS(40)(11 downto 0);
	LeadSSPin <= internal_OUTPUT_REGISTERS(41)(7 downto 0);
	TrailSSPin <= internal_OUTPUT_REGISTERS(42)(7 downto 0);
	LeadS1 <= internal_OUTPUT_REGISTERS(43)(7 downto 0);
	TrailS1 <= internal_OUTPUT_REGISTERS(44)(7 downto 0);
	LeadS2 <= internal_OUTPUT_REGISTERS(45)(7 downto 0);
	TrailS2 <= internal_OUTPUT_REGISTERS(46)(7 downto 0);
	LeadPHASE <= internal_OUTPUT_REGISTERS(47)(7 downto 0);
	TrailPHASE <= internal_OUTPUT_REGISTERS(48)(7 downto 0);
	LeadWR_STRB <= internal_OUTPUT_REGISTERS(49)(7 downto 0);
	TrailWR_STRB <= internal_OUTPUT_REGISTERS(50)(7 downto 0);
	TimGenReg <= internal_OUTPUT_REGISTERS(51)(7 downto 0);
	PDDbias <= internal_OUTPUT_REGISTERS(52)(11 downto 0);
	CMPbias <= internal_OUTPUT_REGISTERS(53)(11 downto 0);
	PUDbias <= internal_OUTPUT_REGISTERS(54)(11 downto 0);
	PUbias <= internal_OUTPUT_REGISTERS(55)(11 downto 0);
	SBDbias <= internal_OUTPUT_REGISTERS(56)(11 downto 0);
	Sbbias <= internal_OUTPUT_REGISTERS(57)(11 downto 0);
	ISDbias <= internal_OUTPUT_REGISTERS(58)(11 downto 0);
	ISEL <= internal_OUTPUT_REGISTERS(59)(11 downto 0);
	VDDbias <= internal_OUTPUT_REGISTERS(60)(11 downto 0);
	Vdly <= internal_OUTPUT_REGISTERS(61)(11 downto 0);
	VAPDbias <= internal_OUTPUT_REGISTERS(62)(11 downto 0);
	VadjP <= internal_OUTPUT_REGISTERS(63)(11 downto 0);
	VANDbias <= internal_OUTPUT_REGISTERS(64)(11 downto 0);
	VadjN <= internal_OUTPUT_REGISTERS(65)(11 downto 0);
	
	--	AsicIn_TRIG_ON_RISING_EDGE             <= internal_OUTPUT_REGISTERS(4)(15);         --Register 4: Select trigger polarity and which ASIC to read scalers from: PXXX XXXX XXXX CCRR, where P is 1/0 for rising/falling edge triggering, and C/R are column and row
	--internal_TRIGGER_SCALER_ROW_SELECT     <= internal_OUTPUT_REGISTERS(4)(ROW_SELECT_BITS-1 downto 0); 
	--internal_TRIGGER_SCALER_COL_SELECT     <= internal_OUTPUT_REGISTERS(4)(ROW_SELECT_BITS+COL_SELECT_BITS-1 downto ROW_SELECT_BITS);
	--gen_dac_common_col : for col in 0 to 3 generate
	--	gen_dac_common_row : for row in 0 to 3 generate 
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(4) <= internal_OUTPUT_REGISTERS( 5)(11 downto 0); --Register  5: TRG_BIAS for all ASICs
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(5) <= internal_OUTPUT_REGISTERS( 6)(11 downto 0); --Register  6: VBIAS for all ASICs
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(0) <= internal_OUTPUT_REGISTERS( 7)(11 downto 0); --Register  7: TRGTHREF for all ASICs	
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(1) <= internal_OUTPUT_REGISTERS( 8)(11 downto 0); --Register  8: ISEL for all ASICs	
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(2) <= internal_OUTPUT_REGISTERS( 9)(11 downto 0); --Register  9: SBBIAS for all ASICs	
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(3) <= internal_OUTPUT_REGISTERS(10)(11 downto 0); --Register 10: PUBIAS for all ASICs	
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(5) <= internal_OUTPUT_REGISTERS(11)(11 downto 0); --Register 11: CMPBIAS for all ASICs	
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+1)(6) <= internal_OUTPUT_REGISTERS(12)(11 downto 0); --Register 12: PAD_G (spare) for all ASICs	
	--	end generate;
	--end generate;
	--gen_dac_independent_col : for col in 0 to 3 generate
	--	gen_dac_independent_row : for row in 0 to 3 generate
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(0) <= internal_OUTPUT_REGISTERS( 13+col*4+row)(11 downto 0); --Registers 13 - 28: TRG thresh for channel 0,1; increasing ASIC by row, then col
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(1) <= internal_OUTPUT_REGISTERS( 29+col*4+row)(11 downto 0); --Registers 29 - 44: TRG thresh for channel 2,3; increasing ASIC by row, then col
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(6) <= internal_OUTPUT_REGISTERS( 45+col*4+row)(11 downto 0); --Registers 45 - 60: TRG thresh for channel 4,5; increasing ASIC by row, then col
	--		internal_DESIRED_DAC_VOLTAGES(col)(row*2+0)(7) <= internal_OUTPUT_REGISTERS( 61+col*4+row)(11 downto 0); --Registers 61 - 76: TRG thresh for channel 6,7; increasing ASIC by row, then col

	--		internal_WILK_DAC_VALUES_STATIC(col)(row)      <= internal_OUTPUT_REGISTERS( 77+col*4+row)(11 downto 0); --Registers 77 - 92: VDLY (Wilkinson count rate bias), used when feedback is disabled
	--		internal_VADJP_DAC_VALUES_STATIC(col)(row)     <= internal_OUTPUT_REGISTERS( 93+col*4+row)(11 downto 0); --Registers 93 - 108: VADJP (Sampling rate PFET bias), used when feedback is disabled
	--		internal_VADJN_DAC_VALUES_STATIC(col)(row)     <= internal_OUTPUT_REGISTERS(109+col*4+row)(11 downto 0); --Registers 109 - 124: VADJN (Sampling rate NFET bias), used when feedback is disabled
	--		internal_WBIAS_DAC_VALUES_STATIC(col)(row)     <= internal_OUTPUT_REGISTERS(125+col*4+row)(11 downto 0); --Registers 125 - 140: WBIAS (trigger width bias), used when feedback is disabled
	--	end generate;
	--end generate;
	--gen_feedback_enables_col : for col in 0 to 3 generate
	--	gen_feedback_enables_row : for row in 0 to 3 generate
	--		internal_WILK_FEEDBACK_ENABLES(col)(row)  <= internal_OUTPUT_REGISTERS(141)(col*4+row); --Registers 141: Wilkinson count rate enable bits, increasing by row, then col
	--		internal_VADJ_FEEDBACK_ENABLES(col)(row)  <= internal_OUTPUT_REGISTERS(142)(col*4+row); --Registers 142: Sampling rate feedback enable bits, increasing by row, then col
	--		internal_WBIAS_FEEDBACK_ENABLES(col)(row) <= internal_OUTPUT_REGISTERS(143)(col*4+row); --Registers 143: Trigger width  feedback enable bits, increasing by row, then col
	--	end generate;
	--end generate;
--	AsicIn_MONITOR_WILK_COUNTER_START <= internal_OUTPUT_REGISTERS(144)(0); --Register 144: Bit 0: start wilkinson monitoring counter (edge sensitive)
--	AsicIn_MONITOR_WILK_COUNTER_RESET <= internal_OUTPUT_REGISTERS(144)(1); --              Bit 1: reset wilkinson monitoring counter
	--gen_feedback_targets_col : for col in 0 to 3 generate
	--	gen_feedback_targets_row : for row in 0 to 3 generate
	--		internal_WILKINSON_TARGETS(col)(row) <= internal_OUTPUT_REGISTERS(145+col*4+row); --Registers 145-160: wilkinson counter target values for feedback
	--	end generate;
	--end generate;
	internal_FIRST_ALLOWED_WINDOW     <= internal_OUTPUT_REGISTERS(161)(internal_FIRST_ALLOWED_WINDOW'length-1 downto 0);     --Register 161: Bits 8-0: First allowed analog storage window
	internal_LAST_ALLOWED_WINDOW      <= internal_OUTPUT_REGISTERS(162)(internal_LAST_ALLOWED_WINDOW'length-1 downto 0);      --         162: Bits 8-0: Last allowed analog storage window
	internal_MAX_WINDOWS_TO_LOOK_BACK <= internal_OUTPUT_REGISTERS(163)(internal_MAX_WINDOWS_TO_LOOK_BACK'length-1 downto 0); --Register 163: Bits 8-0: Maximum number of windows to look back
	internal_MIN_WINDOWS_TO_LOOK_BACK <= internal_OUTPUT_REGISTERS(164)(internal_MIN_WINDOWS_TO_LOOK_BACK'length-1 downto 0); --         164: Bits 8-0: Minimum number of windows to look back
	internal_PEDESTAL_WINDOW          <= internal_OUTPUT_REGISTERS(165)(internal_PEDESTAL_WINDOW'length-1 downto 0);          --Register 165: Bits 8-0:  Window to read out in pedestal mode
	internal_PEDESTAL_MODE            <= internal_OUTPUT_REGISTERS(165)(15);                                                  --              Bit  15:   Operate in pedestal mode    
	internal_SOFTWARE_TRIGGER         <= internal_OUTPUT_REGISTERS(165)(14);                                                  --              Bit  14:   Software trigger
	internal_SOFTWARE_TRIGGER_VETO    <= internal_OUTPUT_REGISTERS(165)(13);                                                  --              Bit  13:   Software trigger veto
	internal_HARDWARE_TRIGGER_VETO    <= internal_OUTPUT_REGISTERS(165)(12);                                                  --              Bit  12:   Hardware trigger veto
	internal_SCROD_REV_AND_ID_WORD(15 downto  0) <= internal_OUTPUT_REGISTERS(166);    --Register 166: copy of the SCROD ID
	internal_SCROD_REV_AND_ID_WORD(31 downto 16) <= internal_OUTPUT_REGISTERS(167);    --Register 167: copy of the SCORD revision
	internal_EVENT_NUMBER_TO_SET(15 downto  0)   <= internal_OUTPUT_REGISTERS(168);    --Register 168: LSBs of event number to set
	internal_EVENT_NUMBER_TO_SET(31 downto 16)   <= internal_OUTPUT_REGISTERS(169);    --Register 169: MSBs of event number to set
	internal_SET_EVENT_NUMBER                    <= internal_OUTPUT_REGISTERS(170)(0); --Register 170: bit 0 - set the event number
	internal_FORCE_CHANNEL_MASK( 15 downto   0)  <= internal_OUTPUT_REGISTERS(171);    --Registers 171-178: Force channel masks
	internal_FORCE_CHANNEL_MASK( 31 downto  16)  <= internal_OUTPUT_REGISTERS(172);
	internal_FORCE_CHANNEL_MASK( 47 downto  32)  <= internal_OUTPUT_REGISTERS(173);
	internal_FORCE_CHANNEL_MASK( 63 downto  48)  <= internal_OUTPUT_REGISTERS(174);
	internal_FORCE_CHANNEL_MASK( 79 downto  64)  <= internal_OUTPUT_REGISTERS(175);
	internal_FORCE_CHANNEL_MASK( 95 downto  80)  <= internal_OUTPUT_REGISTERS(176);
	internal_FORCE_CHANNEL_MASK(111 downto  96)  <= internal_OUTPUT_REGISTERS(177);
	internal_FORCE_CHANNEL_MASK(127 downto 112)  <= internal_OUTPUT_REGISTERS(178);
	internal_IGNORE_CHANNEL_MASK( 15 downto   0) <= internal_OUTPUT_REGISTERS(179);    ----Registers 179-186: Ignore channel masks
	internal_IGNORE_CHANNEL_MASK( 31 downto  16) <= internal_OUTPUT_REGISTERS(180);
	internal_IGNORE_CHANNEL_MASK( 47 downto  32) <= internal_OUTPUT_REGISTERS(181);
	internal_IGNORE_CHANNEL_MASK( 63 downto  48) <= internal_OUTPUT_REGISTERS(182);
	internal_IGNORE_CHANNEL_MASK( 79 downto  64) <= internal_OUTPUT_REGISTERS(183);
	internal_IGNORE_CHANNEL_MASK( 95 downto  80) <= internal_OUTPUT_REGISTERS(184);
	internal_IGNORE_CHANNEL_MASK(111 downto  96) <= internal_OUTPUT_REGISTERS(185);
	internal_IGNORE_CHANNEL_MASK(127 downto 112) <= internal_OUTPUT_REGISTERS(186);
	internal_ROI_ADDRESS_ADJUST                   <= internal_OUTPUT_REGISTERS(187)(TRIGGER_MEMORY_ADDRESS_BITS-1 downto 0);  --Register 187: 10-bit signed adjust window for the trigger memory
	internal_WINDOW_PAIRS_TO_SAMPLE_AFTER_TRIGGER <= internal_OUTPUT_REGISTERS(188)(ANALOG_MEMORY_ADDRESS_BITS-2 downto 0);  --Register 188: 9 bit unsigned number of window pairs to sample after receiving a trigger

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
	internal_INPUT_REGISTERS(N_GPR   ) <= internal_I2C_BUSA_ACKNOWLEDGED & internal_I2C_BUSA_BUSY & "000000" & internal_I2C_BUSA_BYTE_RECEIVED; --Register 256: I2C BusA interfaces
	internal_INPUT_REGISTERS(N_GPR+ 1) <= internal_I2C_BUSB_ACKNOWLEDGED & internal_I2C_BUSB_BUSY & "000000" & internal_I2C_BUSB_BYTE_RECEIVED; --Register 257: I2C BusB interfaces
	internal_INPUT_REGISTERS(N_GPR+ 2) <= internal_I2C_BUSC_ACKNOWLEDGED & internal_I2C_BUSC_BUSY & "000000" & internal_I2C_BUSC_BYTE_RECEIVED; --Register 258: I2C BusC interfaces
	--skip bus D
	internal_INPUT_REGISTERS(N_GPR+ 4) <= internal_I2C_BUSE_ACKNOWLEDGED & internal_I2C_BUSE_BUSY & "000000" & internal_I2C_BUSE_BYTE_RECEIVED; --Register 260: I2C BusE interfaces
	internal_INPUT_REGISTERS(N_GPR+ 5) <= internal_I2C_BUSF_ACKNOWLEDGED & internal_I2C_BUSF_BUSY & "000000" & internal_I2C_BUSF_BYTE_RECEIVED; --Register 261: I2C BusF interfaces
	internal_INPUT_REGISTERS(N_GPR+ 6) <= internal_I2C_BUSG_ACKNOWLEDGED & internal_I2C_BUSG_BUSY & "000000" & internal_I2C_BUSG_BYTE_RECEIVED; --Register 262: I2C BusG interfaces
	internal_INPUT_REGISTERS(N_GPR+ 7) <= internal_I2C_BUSH_ACKNOWLEDGED & internal_I2C_BUSH_BUSY & "000000" & internal_I2C_BUSH_BYTE_RECEIVED; --Register 263: I2C BusH interfaces
	internal_INPUT_REGISTERS(N_GPR+ 8) <= internal_I2C_BUSI_SUCCEEDED & internal_I2C_BUSI_BUSY & "000000" & x"00"; 										--Register 264: I2C BusI interfaces
	internal_INPUT_REGISTERS(N_GPR+ 9) <= internal_I2C_BUSJ_SUCCEEDED & internal_I2C_BUSJ_BUSY & "000000" & x"00"; 										--Register 265: I2C BusJ interfaces
	internal_INPUT_REGISTERS(N_GPR+ 10) <= internal_I2C_BUSK_ACKNOWLEDGED & internal_I2C_BUSK_BUSY & "000000" & internal_I2C_BUSK_BYTE_RECEIVED; --Register 266: I2C BusK interfaces
	
	--TEMPORARY! COMMENT OUT REMAINING READ REGISTERS
	--internal_INPUT_REGISTERS(N_GPR+ 3) <= internal_ASIC_SCALERS_TO_READ(0);                                                                     --Register 258: Trigger scalers, ch0
	--internal_INPUT_REGISTERS(N_GPR+ 4) <= internal_ASIC_SCALERS_TO_READ(1);                                                                     --Register 259: Trigger scalers, ch1
	--internal_INPUT_REGISTERS(N_GPR+ 5) <= internal_ASIC_SCALERS_TO_READ(2);                                                                     --Register 260: Trigger scalers, ch2
	--internal_INPUT_REGISTERS(N_GPR+ 6) <= internal_ASIC_SCALERS_TO_READ(3);                                                                     --Register 261: Trigger scalers, ch3
	--internal_INPUT_REGISTERS(N_GPR+ 7) <= internal_ASIC_SCALERS_TO_READ(4);                                                                     --Register 262: Trigger scalers, ch4
	--internal_INPUT_REGISTERS(N_GPR+ 8) <= internal_ASIC_SCALERS_TO_READ(5);                                                                     --Register 263: Trigger scalers, ch5
	--internal_INPUT_REGISTERS(N_GPR+ 9) <= internal_ASIC_SCALERS_TO_READ(6);                                                                     --Register 264: Trigger scalers, ch6
	--internal_INPUT_REGISTERS(N_GPR+10) <= internal_ASIC_SCALERS_TO_READ(7);                                                                     --Register 265: Trigger scalers, ch7
	--internal_INPUT_REGISTERS(N_GPR+11) <= internal_DAC_UPDATE_STATUSES(0)(1) & internal_DAC_UPDATE_STATUSES(0)(0);                              --Register 267: DAC statuses for col0, row0, upper 8 bits are dac2, lower are dac1
	--internal_INPUT_REGISTERS(N_GPR+12) <= internal_DAC_UPDATE_STATUSES(0)(3) & internal_DAC_UPDATE_STATUSES(0)(2);                              --Register 268: DAC statuses for col0, row1
	--internal_INPUT_REGISTERS(N_GPR+13) <= internal_DAC_UPDATE_STATUSES(0)(5) & internal_DAC_UPDATE_STATUSES(0)(4);                              --Register 269: DAC statuses for col0, row2
	--internal_INPUT_REGISTERS(N_GPR+14) <= internal_DAC_UPDATE_STATUSES(0)(7) & internal_DAC_UPDATE_STATUSES(0)(6);                              --Register 270: DAC statuses for col0, row3
	--internal_INPUT_REGISTERS(N_GPR+15) <= internal_DAC_UPDATE_STATUSES(1)(1) & internal_DAC_UPDATE_STATUSES(1)(0);                              --Register 271: DAC statuses for col1, row0
	--internal_INPUT_REGISTERS(N_GPR+16) <= internal_DAC_UPDATE_STATUSES(1)(3) & internal_DAC_UPDATE_STATUSES(1)(2);                              --Register 272: DAC statuses for col1, row1
	--internal_INPUT_REGISTERS(N_GPR+17) <= internal_DAC_UPDATE_STATUSES(1)(5) & internal_DAC_UPDATE_STATUSES(1)(4);                              --Register 273: DAC statuses for col1, row2
	--internal_INPUT_REGISTERS(N_GPR+18) <= internal_DAC_UPDATE_STATUSES(1)(7) & internal_DAC_UPDATE_STATUSES(1)(6);                              --Register 274: DAC statuses for col1, row3
	--internal_INPUT_REGISTERS(N_GPR+19) <= internal_DAC_UPDATE_STATUSES(2)(1) & internal_DAC_UPDATE_STATUSES(2)(0);                              --Register 275: DAC statuses for col2, row0
	--internal_INPUT_REGISTERS(N_GPR+20) <= internal_DAC_UPDATE_STATUSES(2)(3) & internal_DAC_UPDATE_STATUSES(2)(2);                              --Register 276: DAC statuses for col2, row1
	--internal_INPUT_REGISTERS(N_GPR+21) <= internal_DAC_UPDATE_STATUSES(2)(5) & internal_DAC_UPDATE_STATUSES(2)(4);                              --Register 277: DAC statuses for col2, row2
	--internal_INPUT_REGISTERS(N_GPR+22) <= internal_DAC_UPDATE_STATUSES(2)(7) & internal_DAC_UPDATE_STATUSES(2)(6);                              --Register 278: DAC statuses for col2, row3
	--internal_INPUT_REGISTERS(N_GPR+23) <= internal_DAC_UPDATE_STATUSES(3)(1) & internal_DAC_UPDATE_STATUSES(3)(0);                              --Register 279: DAC statuses for col3, row0
	--internal_INPUT_REGISTERS(N_GPR+24) <= internal_DAC_UPDATE_STATUSES(3)(3) & internal_DAC_UPDATE_STATUSES(3)(2);                              --Register 280: DAC statuses for col3, row1
	--internal_INPUT_REGISTERS(N_GPR+25) <= internal_DAC_UPDATE_STATUSES(3)(5) & internal_DAC_UPDATE_STATUSES(3)(4);                              --Register 281: DAC statuses for col3, row2
	--internal_INPUT_REGISTERS(N_GPR+26) <= internal_DAC_UPDATE_STATUSES(3)(7) & internal_DAC_UPDATE_STATUSES(3)(6);                              --Register 282: DAC statuses for col3, row3
	--gen_feedback_readbacks_col : for col in 0 to 3 generate
	--	gen_feedback_readbacks_row : for row in 0 to 3 generate                                                                                  --All the following increase by row, then by col
	--		internal_INPUT_REGISTERS(N_GPR+27+col*4+row) <= "0000" & internal_WILK_DAC_VALUES_FEEDBACK(col)(row);                                 --Registers 283-298: Feedback DAC values for VDLY  (Wilkinson count rate)
	--		internal_INPUT_REGISTERS(N_GPR+43+col*4+row) <= "0000" & internal_VADJP_DAC_VALUES_FEEDBACK(col)(row);                                --Registers 299-314: Feedback DAC values for VADJP (sampling rate PFET)
	--		internal_INPUT_REGISTERS(N_GPR+59+col*4+row) <= "0000" & internal_VADJN_DAC_VALUES_FEEDBACK(col)(row);                                --Registers 315-330: Feedback DAC values for VADJN (sampling rate NFET)
	--		internal_INPUT_REGISTERS(N_GPR+75+col*4+row) <= "0000" & internal_WBIAS_DAC_VALUES_FEEDBACK(col)(row);                                --Registers 331-346: Feedback DAC values for WBIAS (Trigger width adjust)
	--		internal_INPUT_REGISTERS(N_GPR+91+col*4+row) <= internal_WILKINSON_COUNTERS(col)(row);                                                --Registers 347-362: Wilkinson counters
	--	end generate;
	--end generate;
	--internal_INPUT_REGISTERS(N_GPR+107) <= internal_EVENT_NUMBER(15 downto  0);                                                                 --Register 363: LSBs of current event number
	--internal_INPUT_REGISTERS(N_GPR+108) <= internal_EVENT_NUMBER(31 downto 16);                                                                 --Register 364: MSBs of current event number
end Behavioral;
