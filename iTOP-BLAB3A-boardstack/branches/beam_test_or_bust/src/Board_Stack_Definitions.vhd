--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Board_Stack_Definitions is

	-------------------DAC RELATED DEFINITIONS----------------------------------
	-- A single LTC2637 has 8 DAC channels, each 12 bits
	type LTC2637_Voltages is array(7 downto 0) of std_logic_vector(11 downto 0);
	-- There are 2 LTC2637 DACs per daughter card, so 8 per column.
   type Column_Voltages is array(7 downto 0) of LTC2637_Voltages;
	type Board_Stack_Voltages is array(3 downto 0) of Column_Voltages;

	-- Address Conventions for the temperature sensors
	subtype TMP112_Address is std_logic_vector(1 downto 0);
	constant TMP112_Address_R1	: TMP112_Address := "01"; --ADD0 pin tied high (2.5 V)

	-- Address conventions for the board stack DACs
	subtype LTC2637_Address is std_logic_vector(6 downto 0);
	-- The following are the chosen address conventions
	-- Please note that the "row" refers to the carrier level
	-- and the index 0/1 correspond to which DAC on the daughter
	-- card.  
	-- Index 0 : DAC1
	-- Index 1 : DAC2  
	-- *Recommend a name change on the schematic for consistency.
	-- 
	-- Name (R<row>_(0/1))								IIC Address		CA(2)	CA(1)	CA(0)
	constant DAC_Address_R3_0	: LTC2637_Address := "0010000";--GND	GND	GND
	constant DAC_Address_R3_1	: LTC2637_Address := "0010001";--GND	GND	FLT
	constant DAC_Address_R2_0	: LTC2637_Address := "0110001";--FLT	GND	GND
	constant DAC_Address_R2_1	: LTC2637_Address := "0110010";--FLT	GND	FLT
	constant DAC_Address_R1_0	: LTC2637_Address := "0010011";--GND	FLT	GND
	constant DAC_Address_R1_1	: LTC2637_Address := "0100000";--GND	FLT	FLT
	constant DAC_Address_R0_0	: LTC2637_Address := "1000000";--FLT	FLT	GND
	constant DAC_Address_R0_1	: LTC2637_Address := "1000001";--FLT	FLT	FLT 
   constant DAC_Write_and_Update : std_logic_vector(3 downto 0) := "0011";
	---------------------------------------------------------------------------
	-----------------ASIC FEEDBACK RELATED SIGNALS-----------------------------
	type Wilkinson_Rate_Counters_Column_R	is array(3 downto 0) of std_logic_vector(15 downto 0);
	type Wilkinson_Rate_Counters_C_R is array(3 downto 0) of Wilkinson_Rate_Counters_Column_R;	
	type Wilkinson_Rate_DAC_Column_R is array(3 downto 0) of std_logic_vector(11 downto 0);
	type Wilkinson_Rate_DAC_C_R is array(3 downto 0) of Wilkinson_Rate_DAC_Column_R;
	---------------------------------------------------------------------------
	-----------------ASIC TRIGGER SIGNALS--------------------------------------
	type ASIC_Trigger_Bits_R_CH is array(3 downto 0) of std_logic_vector(7 downto 0);
	type ASIC_Trigger_Bits_C_R_CH is array(3 downto 0) of ASIC_Trigger_Bits_R_CH;
	subtype ASIC_Scaler is std_logic_vector(15 downto 0);
	type ASIC_Scalers_CH is array(7 downto 0) of ASIC_Scaler;
	type ASIC_Scalers_R_CH is array(3 downto 0) of ASIC_Scalers_CH;
	type ASIC_Scalers_C_R_CH is array(3 downto 0) of ASIC_Scalers_R_CH;
	subtype ASIC_Trigger_Stream is std_logic_vector(15 downto 0);
	type ASIC_Trigger_Stream_CH is array(7 downto 0) of ASIC_Trigger_Stream;
	type ASIC_Trigger_Stream_R_CH is array(3 downto 0) of ASIC_Trigger_Stream_CH;
	type ASIC_Trigger_Stream_C_R_CH is array(3 downto 0) of ASIC_Trigger_Stream_R_CH;
	---------------------------------------------------------------------------
	-----------------ASIC READOUT SIGNALS--------------------------------------
	type ASIC_BLOCKRAM_DATA is array(3 downto 0) of std_logic_vector(15 downto 0);
	---------------------------------------------------------------------------
  
end Board_Stack_Definitions;

--package body Board_Stack_Definitions is
--
--end package body;