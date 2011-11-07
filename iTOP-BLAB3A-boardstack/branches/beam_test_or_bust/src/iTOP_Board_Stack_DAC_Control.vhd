----------------------------------------------------------------------------------
-- DAC Control for the full board stack
-- Description:
--		Inputs/outputs:
--		
--		INTENDED_DAC_VALUES - input of type Board_Stack_Voltages (see Board_Stack_Definitions.vhd)
--									 These specify the target voltages for the board stack.
--		CURRENT_DAC_VALUES  - output of type Board_Stack_Voltages (see Board_Stack_Definitions.vhd)
--									 These specify the current known voltages for the board stack.
--		CLK_100kHz_MAX		  - iinput clock used to drive the IIC state machines.
--    SCL_C 		  		  - output bus for the four IIC SCL lines, ones for each column
--		SDA_C		  			  - inout bus for the four IIC SDA lines, one for each column
--
--		This module handles all the control to set DAC voltages on the various IIC
-- 	buses.  It does not control what the desired voltages are.  That should be 
--    set at a higher level or in a different module, for example from the command
--    parser that accepts fiberoptic commands.
--   
-- Change log:
-- 2011-09-?? - Created by Kurtis
-- 2011-09-29 - Comments/description added to describe basic functionality - Kurtis
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;


-------------------------
-------------------------
-- This part controls a single column of DACs.  Four of these entities are
-- instantiated (see below) to form the whole board stack's worth of DAC
-- control.
-- I'm not sure how to do something like declare a prototype so that this can
-- be used without it appearing above the main part of this block.
-- If you know how to do it, please tell me so we can modify this block for 
-- increased clarity.  -KN
-------------------------

entity Board_Stack_Column_DAC_Control is
    Port ( INTENDED_DAC_VALUES	: in Column_Voltages;
			  CURRENT_DAC_VALUES 	: out	Column_Voltages;
			  IIC_CLK        			: in  std_logic;
           SCL 						: out std_logic;
			  SDA		  					: inout std_logic;
			  STATE_MONITOR			: out std_logic_vector(2 downto 0)
			  );
end Board_Stack_Column_DAC_Control;

architecture Behavioral of Board_Stack_Column_DAC_Control is
---------------------------------------------------------------
	signal internal_INTENDED_DAC_VALUES : Column_Voltages;	
	signal internal_CURRENT_DAC_VALUES  : Column_Voltages;
	signal internal_SCL                 : std_logic;
	signal internal_SDA                 : std_logic;
	signal internal_ADDRESS		       	: std_logic_vector(6 downto 0);
	signal internal_COMMAND             : std_logic_vector(3 downto 0);
	signal internal_CHANNEL             : std_logic_vector(3 downto 0);
	signal internal_DAC_VALUE           : std_logic_vector(11 downto 0);
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
		SCL => internal_SCL,
		SDA => internal_SDA,
		IIC_CLK => IIC_CLK,
		UPDATE => internal_UPDATE,
		ADDRESS => internal_ADDRESS,
		COMMAND => internal_COMMAND,
		CHANNEL => internal_CHANNEL,
		DAC_VALUE => internal_DAC_VALUE,
		UPDATING => internal_UPDATING,
		UPDATE_SUCCEEDED => internal_UPDATE_SUCCEEDED
	);
   -----------------------------------------------------------
	SCL <= internal_SCL;
	SDA <= internal_SDA;
	internal_INTENDED_DAC_VALUES <= INTENDED_DAC_VALUES;
	CURRENT_DAC_VALUES <= internal_CURRENT_DAC_VALUES;
	internal_COMMAND <= DAC_Write_and_Update;
	
	STATE_MONITOR <= internal_DAC_STATE_MONITOR;
--------------------------------------------------------------
	
	process (IIC_CLK) 
		variable dac_channel : integer range 0 to 7 := 0;
		variable dac_address : integer range 0 to 7 := 0;
		constant dac_channels : integer := 8;
		constant dac_addresses: integer := 8;
	begin
		if (falling_edge(IIC_CLK)) then
			case DAC_STATE is
				when SEARCHING_FOR_UPDATES =>
					internal_DAC_STATE_MONITOR	<= "000";
--					if (internal_INTENDED_DAC_VALUES(dac_address)(dac_channel) /= internal_CURRENT_DAC_VALUES(dac_address)(dac_channel)) then
						DAC_STATE <= SETTING_UP_UPDATES;
--					else 
--						if (dac_channel < dac_channels - 1) then
--							dac_channel := dac_channel + 1;
--						else
--							dac_channel := 0;
--							if (dac_address < dac_addresses - 1) then
--								dac_address := dac_address + 1;
--							else
--								dac_address := 0;
--							end if;
--						end if;
--					end if;
				when SETTING_UP_UPDATES =>
					internal_DAC_STATE_MONITOR	<= "001";
					case dac_address is
						when 0 => internal_ADDRESS <= DAC_Address_R0_0;
						when 1 => internal_ADDRESS <= DAC_Address_R0_1;
						when 2 => internal_ADDRESS <= DAC_Address_R1_0;
						when 3 => internal_ADDRESS <= DAC_Address_R1_1;
						when 4 => internal_ADDRESS <= DAC_Address_R2_0;
						when 5 => internal_ADDRESS <= DAC_Address_R2_1;
						when 6 => internal_ADDRESS <= DAC_Address_R3_0;
						when 7 => internal_ADDRESS <= DAC_Address_R3_1;	
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
						if (internal_UPDATE_SUCCEEDED = '1') then
							internal_CURRENT_DAC_VALUES(dac_address)(dac_channel) <= internal_DAC_VALUE;
						end if;
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

use work.Board_Stack_Definitions.ALL;

entity iTOP_Board_Stack_DAC_Control is
	Port ( 
		INTENDED_DAC_VALUES	: in Board_Stack_Voltages;
		CURRENT_DAC_VALUES 	: out Board_Stack_Voltages;
		CLK_100kHz_MAX      	: in  std_logic;
      SCL_C 		  			: out std_logic_vector(3 downto 0);
		SDA_C		  				: inout std_logic_vector(3 downto 0)
	);
end iTOP_Board_Stack_DAC_Control;

architecture Behavioral of iTOP_Board_Stack_DAC_Control is

begin
	map_DAC_Control_COL_GEN : for i in 0 to 3 generate
		map_DAC_Control_COL : entity work.Board_Stack_Column_DAC_Control
			port map (
				INTENDED_DAC_VALUES	=> INTENDED_DAC_VALUES(i),
				CURRENT_DAC_VALUES	=> CURRENT_DAC_VALUES(i),
				IIC_CLK					=> CLK_100kHz_MAX,
				SCL						=> SCL_C(i),
				SDA						=> SDA_C(i),
				STATE_MONITOR			=> open
			);
	end generate;
end Behavioral;


