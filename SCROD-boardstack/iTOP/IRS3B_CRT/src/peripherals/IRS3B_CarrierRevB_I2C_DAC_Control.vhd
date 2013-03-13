----------------------------------------------------------------------------------
-- External DAC VadjP/N control for the IRS3B board stack
--   
-- Change log:
-- 2013-03-13 - Created by Kurtis based on modifying old IRS2 board stack version.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.IRS3B_CarrierRevB_DAC_definitions.ALL;

entity Board_Stack_Bus_DAC_Control is
	Port ( 
		INTENDED_DAC_VALUES : in  bus_DAC_Values;
--		UPDATE_STATUSES     : out Column_DAC_Statuses;
		USE_DAC             : in  std_logic;
		CLK                 : in  std_logic;
		CLK_ENABLE          : in  std_logic;
		SCL                 : out std_logic;
		SDA                 : inout std_logic;
		STATE_MONITOR       : out std_logic_vector(2 downto 0)
	);
end Board_Stack_Bus_DAC_Control;

architecture Behavioral of Board_Stack_Bus_DAC_Control is
---------------------------------------------------------------
	signal internal_INTENDED_DAC_VALUES : bus_DAC_Values;	
--	signal internal_UPDATE_STATUSES     : Column_DAC_Statuses;
	signal internal_SCL                 : std_logic;
	signal internal_SDA                 : std_logic;
	signal internal_ADDRESS		       	: std_logic_vector(6 downto 0);
	signal internal_COMMAND             : std_logic_vector(3 downto 0);
	signal internal_CHANNEL             : std_logic_vector(3 downto 0);
	signal internal_DAC_VALUE           : DAC_setting;
	signal internal_UPDATE              : std_logic;
	signal internal_UPDATING 				: std_logic;
	signal internal_UPDATE_SUCCEEDED    : std_logic;

	signal internal_DAC_STATE_MONITOR	: std_logic_vector(2 downto 0);

	type DAC_STATE_TYPE is (SEARCHING_FOR_UPDATES, SETTING_UP_UPDATES, START_UPDATING, WAIT_FOR_UPDATE);
	signal DAC_STATE      : DAC_STATE_TYPE := SEARCHING_FOR_UPDATES;
	
--------------------------------------------------------------	
begin
   ----------------------------------------------------------
	COL_LTC2637 : entity work.LTC2637_I2C_Interface
	port map (
		SCL              => internal_SCL,
		SDA              => internal_SDA,
		CLK              => CLK,
		CLK_ENABLE       => CLK_ENABLE,
		UPDATE           => internal_UPDATE,
		ADDRESS          => internal_ADDRESS,
		COMMAND          => internal_COMMAND,
		CHANNEL          => internal_CHANNEL,
		DAC_VALUE        => internal_DAC_VALUE,
		UPDATING         => internal_UPDATING,
		UPDATE_SUCCEEDED => internal_UPDATE_SUCCEEDED
	);
   -----------------------------------------------------------
	SCL <= internal_SCL;
	SDA <= internal_SDA;
	internal_INTENDED_DAC_VALUES <= INTENDED_DAC_VALUES;
--	UPDATE_STATUSES <= internal_UPDATE_STATUSES;

	internal_COMMAND <= DAC_Write_and_Update when USE_DAC = '1' else
	                    DAC_Shutdown;
	
	STATE_MONITOR <= internal_DAC_STATE_MONITOR;
--------------------------------------------------------------
	
	process (CLK, CLK_ENABLE) 
		variable dac_channel : integer range 0 to 7 := 0;
		variable dac_address : integer range 0 to 1 := 1;
		constant dac_channels : integer := 8;
		constant dac_addresses: integer := 2;
	begin
		if (CLK_ENABLE = '1') then
			if (falling_edge(CLK)) then
				case DAC_STATE is
					when SEARCHING_FOR_UPDATES =>
						internal_DAC_STATE_MONITOR	<= "000";
--						if (internal_UPDATE_STATUSES(dac_address)(dac_channel) /= '1') then
							DAC_STATE <= SETTING_UP_UPDATES;
--						else 
--							if (dac_channel < dac_channels - 1) then
--								dac_channel := dac_channel + 1;
--							else
--								dac_channel := 0;
--								if (dac_address < dac_addresses - 1) then
--									dac_address := dac_address + 1;
--								else
--									dac_address := 0;
--								end if;
--							end if;
--						end if;
					when SETTING_UP_UPDATES =>
						internal_DAC_STATE_MONITOR	<= "001";
						case dac_address is
							when 0 => internal_ADDRESS <= DAC_Address_R02;
							when 1 => internal_ADDRESS <= DAC_Address_R13;
						end case;
						internal_CHANNEL <= std_logic_vector(to_unsigned(dac_channel, 4));
						internal_DAC_VALUE <= internal_INTENDED_DAC_VALUES(dac_address)(dac_channel);
						DAC_STATE <= START_UPDATING;
					when START_UPDATING =>
						internal_DAC_STATE_MONITOR	<= "010";				
						internal_UPDATE <= '1';
						if (internal_UPDATING = '1') then
							internal_UPDATE <= '0';
							DAC_STATE <= WAIT_FOR_UPDATE;
						end if;
					when WAIT_FOR_UPDATE =>
						internal_DAC_STATE_MONITOR	<= "011";
						if (internal_UPDATING = '0') then
--							if (internal_UPDATE_SUCCEEDED = '1') then
--								internal_UPDATE_STATUSES(dac_address)(dac_channel) <= '1';
--							else
--								internal_UPDATE_STATUSES(dac_address)(dac_channel) <= '0';
--							end if;
							if (dac_channel < dac_channels - 1) then
								dac_channel := dac_channel + 1;
							else
								dac_channel := 0;
								if (dac_address < dac_addresses - 1) then
									dac_address := dac_address + 1;
								else
									dac_address := 0;
								end if;
							end if;						
							DAC_STATE <= SEARCHING_FOR_UPDATES;
						end if;
					when others =>
						DAC_STATE <= SEARCHING_FOR_UPDATES;
				end case;
			end if;
		end if;
	end process;
	
end Behavioral;

-------------------------
-------------------------
-- This part is the highest level of this module, and forms the
-- connections to the top level.
-------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.IRS3B_CarrierRevB_DAC_definitions.ALL;

entity IRS3B_CarrierRevB_External_I2C_DAC_Control is
	Port ( 
		VADJP_VALUES          : in    DAC_setting_C_R;
		VADJN_VALUES          : in    DAC_setting_C_R;
		USE_EXTERNAL_DACS     : in    std_logic;
		CLK                   : in    std_logic;
		CLK_ENABLE            : in    std_logic;
      SCL_R01	             : inout std_logic;
		SDA_R01               : inout std_logic;
      SCL_R23	             : inout std_logic;
		SDA_R23               : inout std_logic		
	);
end IRS3B_CarrierRevB_External_I2C_DAC_Control;

architecture Behavioral of IRS3B_CarrierRevB_External_I2C_DAC_Control is
	signal internal_INTENDED_DAC_VALUES_01 : bus_DAC_Values;
	signal internal_INTENDED_DAC_VALUES_23 : bus_DAC_Values;	
begin
	internal_INTENDED_DAC_VALUES_01(0)(0) <= VADJP_VALUES(0)(0);
	internal_INTENDED_DAC_VALUES_01(0)(1) <= VADJN_VALUES(0)(0);
	internal_INTENDED_DAC_VALUES_01(0)(2) <= VADJP_VALUES(1)(0);
	internal_INTENDED_DAC_VALUES_01(0)(3) <= VADJN_VALUES(1)(0);
	internal_INTENDED_DAC_VALUES_01(0)(4) <= VADJP_VALUES(2)(0);
	internal_INTENDED_DAC_VALUES_01(0)(5) <= VADJN_VALUES(2)(0);
	internal_INTENDED_DAC_VALUES_01(0)(6) <= VADJP_VALUES(3)(0);
	internal_INTENDED_DAC_VALUES_01(0)(7) <= VADJN_VALUES(3)(0);

	internal_INTENDED_DAC_VALUES_01(1)(0) <= VADJP_VALUES(0)(1);
	internal_INTENDED_DAC_VALUES_01(1)(1) <= VADJN_VALUES(0)(1);
	internal_INTENDED_DAC_VALUES_01(1)(2) <= VADJP_VALUES(1)(1);
	internal_INTENDED_DAC_VALUES_01(1)(3) <= VADJN_VALUES(1)(1);
	internal_INTENDED_DAC_VALUES_01(1)(4) <= VADJP_VALUES(2)(1);
	internal_INTENDED_DAC_VALUES_01(1)(5) <= VADJN_VALUES(2)(1);
	internal_INTENDED_DAC_VALUES_01(1)(6) <= VADJP_VALUES(3)(1);
	internal_INTENDED_DAC_VALUES_01(1)(7) <= VADJN_VALUES(3)(1);

	internal_INTENDED_DAC_VALUES_23(0)(0) <= VADJP_VALUES(0)(2);
	internal_INTENDED_DAC_VALUES_23(0)(1) <= VADJN_VALUES(0)(2);
	internal_INTENDED_DAC_VALUES_23(0)(2) <= VADJP_VALUES(1)(2);
	internal_INTENDED_DAC_VALUES_23(0)(3) <= VADJN_VALUES(1)(2);
	internal_INTENDED_DAC_VALUES_23(0)(4) <= VADJP_VALUES(2)(2);
	internal_INTENDED_DAC_VALUES_23(0)(5) <= VADJN_VALUES(2)(2);
	internal_INTENDED_DAC_VALUES_23(0)(6) <= VADJP_VALUES(3)(2);
	internal_INTENDED_DAC_VALUES_23(0)(7) <= VADJN_VALUES(3)(2);

	internal_INTENDED_DAC_VALUES_23(1)(0) <= VADJP_VALUES(0)(3);
	internal_INTENDED_DAC_VALUES_23(1)(1) <= VADJN_VALUES(0)(3);
	internal_INTENDED_DAC_VALUES_23(1)(2) <= VADJP_VALUES(1)(3);
	internal_INTENDED_DAC_VALUES_23(1)(3) <= VADJN_VALUES(1)(3);
	internal_INTENDED_DAC_VALUES_23(1)(4) <= VADJP_VALUES(2)(3);
	internal_INTENDED_DAC_VALUES_23(1)(5) <= VADJN_VALUES(2)(3);
	internal_INTENDED_DAC_VALUES_23(1)(6) <= VADJP_VALUES(3)(3);
	internal_INTENDED_DAC_VALUES_23(1)(7) <= VADJN_VALUES(3)(3);


	map_dac_bus_row01 : entity work.Board_Stack_Bus_DAC_Control
	port map (
		INTENDED_DAC_VALUES => internal_INTENDED_DAC_VALUES_01,
		USE_DAC             => USE_EXTERNAL_DACS,
		CLK                 => CLK,
		CLK_ENABLE          => CLK_ENABLE,
		SCL                 => SCL_R01,
		SDA                 => SDA_R01,
		STATE_MONITOR       => open
	);
	map_dac_bus_row23 : entity work.Board_Stack_Bus_DAC_Control
	port map (
		INTENDED_DAC_VALUES => internal_INTENDED_DAC_VALUES_23,
		USE_DAC             => USE_EXTERNAL_DACS,
		CLK                 => CLK,
		CLK_ENABLE          => CLK_ENABLE,
		SCL                 => SCL_R23,
		SDA                 => SDA_R23,
		STATE_MONITOR       => open
	);


end Behavioral;


