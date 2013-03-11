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

end IRS3B_CarrierRevB_DAC_definitions;

package body IRS3B_CarrierRevB_DAC_definitions is
--Nothing in the body 
end IRS3B_CarrierRevB_DAC_definitions;
