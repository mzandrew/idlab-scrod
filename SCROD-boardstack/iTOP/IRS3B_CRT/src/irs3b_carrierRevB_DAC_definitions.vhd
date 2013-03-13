----------------------------------------------------------------------------------
-- DAC definitions
--
-- Change log:
-- 2013-03-11 - New version for IRS3B-based board stack.  Includes definitions only for now. - Kurtis
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.asic_definitions_irs3b_carrier_revB.all;

package IRS3B_CarrierRevB_DAC_definitions is
	subtype DAC_setting is std_logic_vector(11 downto 0);
	-- various ways of sharing DACs (global, unique to ASIC, unique to a channel)
	--Global DAC setting
	subtype DAC_setting_G is DAC_setting;
	--A set of 4 and 4 (column, row) - for things that are unique by ASIC
	type    DAC_setting_R is array(ROWS_PER_COL-1 downto 0) of DAC_setting;
	type    DAC_setting_C_R is array(ASICS_PER_ROW-1 downto 0) of DAC_setting_R;
	--A set of 8 and 4 and 4 (column, row, ch) - for things that are unique by channel
	type    DAC_setting_CH is array(CHANNELS_PER_ASIC-1 downto 0) of DAC_setting;
	type    DAC_setting_R_CH is array(ROWS_PER_COL-1 downto 0) of DAC_setting_CH;
	type    DAC_setting_C_R_CH is array(ASICS_PER_ROW-1 downto 0) of DAC_setting_R_CH;
	--Timing register settings (not strictly DACs but they're programmed at the same time)
	subtype Timing_setting is std_logic_vector(7 downto 0);
	type    Timing_setting_R is array (ROWS_PER_COL-1 downto 0) of Timing_setting;
	type    Timing_setting_C_R is array(ASICS_PER_ROW-1 downto 0) of Timing_setting_R;


	--------------- Definitions for the external VadjP/N DACs
	-- A single LTC2637 has 8 DAC channels, each 12 bits
	type LTC2637_Voltages is array(7 downto 0) of DAC_Setting;
	-- There are two DACs per bus
	type bus_DAC_Values is array(1 downto 0) of LTC2637_Voltages;	
	-- Address conventions for the board stack DACs
	subtype LTC2637_Address is std_logic_vector(6 downto 0);
	constant DAC_Address_R02 : LTC2637_Address := "0010000";
	constant DAC_Address_R13 : LTC2637_Address := "0010001";
   constant DAC_Write_and_Update : std_logic_vector(3 downto 0) := "0011";
   constant DAC_Shutdown         : std_logic_vector(3 downto 0) := "0101"; --Power down all channels + ref
	---------------------------------------------------------------------------



end IRS3B_CarrierRevB_DAC_definitions;

package body IRS3B_CarrierRevB_DAC_definitions is
--Nothing in the body 
end IRS3B_CarrierRevB_DAC_definitions;
