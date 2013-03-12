----------------------------------------------------------------------------------
-- Interfaces to the IRS3B, carrier RevB DAC
-- Should include the multiplexing signals to use the DAC values from the user 
-- registers or the ones from the feedback sources.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.IRS3B_CarrierRevB_DAC_definitions.all;
use work.asic_definitions_irs3b_carrier_revB.all;

entity irs3b_dac_interface is
	Port ( 
		--Clock and clock enable used to run the interface
		CLOCK        : in std_logic;
		CLOCK_ENABLE : in std_logic;
		--Direct connections to the IRS3B register programming interface
		AsicIn_PARALLEL_CLOCK_C0_R : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C1_R : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C2_R : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C3_R : out std_logic_vector(3 downto 0);
		AsicIn_CLEAR_ALL_REGISTERS : out std_logic;
		AsicIn_SERIAL_SHIFT_CLOCK  : out std_logic;
		AsicIn_SERIAL_INPUT        : out std_logic;		
		--Connections to the external DACs for VADJP/VADJN
		I2C_DAC_SCL_R01            : inout std_logic;
		I2C_DAC_SDA_R01            : inout std_logic;
		I2C_DAC_SCL_R23            : inout std_logic;
		I2C_DAC_SDA_R23            : inout std_logic;
		--A toggle to select the internal or external DACs
		USE_EXTERNAL_VADJ_DACS   : in  std_logic;
		--DAC values coming from general purpose registers
		ASIC_TRIG_THRESH         : in  DAC_setting_C_R_CH;
		ASIC_DAC_BUF_BIASES      : in  DAC_setting;
		ASIC_DAC_BUF_BIAS_ISEL   : in  DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJP  : in  DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJN  : in  DAC_setting;
		ASIC_VBIAS               : in  DAC_setting_C_R;
		ASIC_VBIAS2              : in  DAC_setting_C_R;
		ASIC_WBIAS               : in  DAC_setting_C_R;
		ASIC_VADJP               : in  DAC_setting_C_R;
		ASIC_VADJN               : in  DAC_setting_C_R;
		ASIC_VDLY                : in  DAC_setting_C_R;
		ASIC_TRG_BIAS            : in  DAC_setting;
		ASIC_TRG_BIAS2           : in  DAC_setting;
		ASIC_TRGTHREF            : in  DAC_setting;
		ASIC_CMPBIAS             : in  DAC_setting;
		ASIC_PUBIAS              : in  DAC_setting;
		ASIC_SBBIAS              : in  DAC_setting;
		ASIC_ISEL                : in  DAC_setting;
		--DAC values coming from feedback loops
		WBIAS_FB                 : in  DAC_setting_C_R;
		VDLY_FB                  : in  DAC_setting_C_R;
		VADJP_FB                 : in  DAC_setting_C_R;
		VADJN_FB                 : in  DAC_setting_C_R;		
		--Multiplex enables to choose between the two above categories
		VDLY_FEEDBACK_ENABLES    : in  Column_Row_Enables;
		VADJ_FEEDBACK_ENABLES    : in  Column_Row_Enables;
		WBIAS_FEEDBACK_ENABLES   : in  Column_Row_Enables;
		--Other registers and timing-related signals that live in the ASIC internal registers
		ASIC_TIMING_SSP_LEADING    : in  Timing_setting_C_R;
		ASIC_TIMING_SSP_TRAILING   : in  Timing_setting_C_R;
		ASIC_TIMING_S1_LEADING     : in  Timing_setting_C_R;
		ASIC_TIMING_S1_TRAILING    : in  Timing_setting_C_R;
		ASIC_TIMING_S2_LEADING     : in  Timing_setting_C_R;
		ASIC_TIMING_S2_TRAILING    : in  Timing_setting_C_R;
		ASIC_TIMING_PHASE_LEADING  : in  Timing_setting_C_R;
		ASIC_TIMING_PHASE_TRAILING : in  Timing_setting_C_R;
		ASIC_TIMING_GENERATOR_REG  : in  Timing_setting;
		ASIC_REG_TRG               : in  Timing_setting
	);
end irs3b_dac_interface;

architecture Behavioral of irs3b_dac_interface is

begin
	AsicIn_PARALLEL_CLOCK_C0_R <= (others => '0');
	AsicIn_PARALLEL_CLOCK_C1_R <= (others => '0');
	AsicIn_PARALLEL_CLOCK_C2_R <= (others => '0');
	AsicIn_PARALLEL_CLOCK_C3_R <= (others => '0');
	AsicIn_CLEAR_ALL_REGISTERS <= '0';
	AsicIn_SERIAL_SHIFT_CLOCK  <= '0';
	AsicIn_SERIAL_INPUT        <= '0';
	I2C_DAC_SCL_R01            <= '0';
	I2C_DAC_SDA_R01            <= '0';
	I2C_DAC_SCL_R23            <= '0';
	I2C_DAC_SDA_R23            <= '0';
	
end Behavioral;