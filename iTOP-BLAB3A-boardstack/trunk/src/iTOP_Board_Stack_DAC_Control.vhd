----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:24:04 06/03/2011 
-- Design Name: 
-- Module Name:    iTOP_Board_Stack_BAC_Control - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity iTOP_Board_Stack_DAC_Control is
    Port ( INTENDED_DAC_VALUES	: in Daughter_Card_Voltages;
			  CURRENT_DAC_VALUES 	: out Daughter_Card_Voltages;
			  IIC_CLK        : in  std_logic;
           SCL_DC1 		  : out std_logic;
			  SDA_DC1		  : inout std_logic;
			  STATE_MONITOR  : out std_logic_vector(2 downto 0)
			  );
end iTOP_Board_Stack_DAC_Control;

architecture Behavioral of iTOP_Board_Stack_DAC_Control is
---------------------------------------------------------------
	component LTC2637_I2C_Interface is
		 Port ( SCL				: out STD_LOGIC;
				  SDA				: inout STD_LOGIC;
				  IIC_CLK      : in STD_LOGIC;
				  ADDRESS      : in STD_LOGIC_VECTOR(6 downto 0);
				  COMMAND      : in STD_LOGIC_VECTOR(3 downto 0);
				  CHANNEL      : in STD_LOGIC_VECTOR(3 downto 0);
				  DAC_VALUE    : in STD_LOGIC_VECTOR(11 downto 0);
				  UPDATE       : in STD_LOGIC;				  
				  UPDATING     : out STD_LOGIC;
				  UPDATE_SUCCEEDED    : out STD_LOGIC);
	end component;
   ----------------------------------------------------------
	signal internal_INTENDED_DAC_VALUES_DC1 : Daughter_Card_Voltages;	
	signal internal_CURRENT_DAC_VALUES_DC1  : Daughter_Card_Voltages;
	signal internal_SCL_DC1                 : std_logic;
	signal internal_SDA_DC1                 : std_logic;
	signal internal_ADDRESS_DC1		       : std_logic_vector(6 downto 0);
	signal internal_COMMAND_DC1             : std_logic_vector(3 downto 0);
	signal internal_CHANNEL_DC1             : std_logic_vector(3 downto 0);
	signal internal_DAC_VALUE_DC1           : std_logic_vector(11 downto 0);
	signal internal_UPDATE_DC1              : std_logic;
	signal internal_UPDATING_DC1 				 : std_logic;
	signal internal_UPDATE_SUCCEEDED_DC1    : std_logic;
	
	signal internal_ADDRESS1_DC1            : std_logic_vector(6 downto 0);
	signal internal_ADDRESS2_DC1            : std_logic_vector(6 downto 0);

	signal internal_DAC_STATE_MONITOR       : std_logic_vector(2 downto 0);

	type DAC_STATE_TYPE is (SEARCHING_FOR_UPDATES, SETTING_UP_UPDATES, START_UPDATING, WAIT_FOR_UPDATE);
	signal DAC_STATE      : DAC_STATE_TYPE := SEARCHING_FOR_UPDATES;
	
--------------------------------------------------------------	
begin
   ----------------------------------------------------------
	DC1_LTC2637 : LTC2637_I2C_Interface
	port map (
		SCL => internal_SCL_DC1,
		SDA => internal_SDA_DC1,
		IIC_CLK => IIC_CLK,
		UPDATE => internal_UPDATE_DC1,
		ADDRESS => internal_ADDRESS_DC1,
		COMMAND => internal_COMMAND_DC1,
		CHANNEL => internal_CHANNEL_DC1,
		DAC_VALUE => internal_DAC_VALUE_DC1,
		UPDATING => internal_UPDATING_DC1,
		UPDATE_SUCCEEDED => internal_UPDATE_SUCCEEDED_DC1
	);
   -----------------------------------------------------------
	SCL_DC1 <= internal_SCL_DC1;
	SDA_DC1 <= internal_SDA_DC1;
	internal_INTENDED_DAC_VALUES_DC1 <= INTENDED_DAC_VALUES;
	CURRENT_DAC_VALUES <= internal_CURRENT_DAC_VALUES_DC1;
	internal_ADDRESS1_DC1 <= "1000000"; -- For BLAB3A DC card 2	
	internal_ADDRESS2_DC1 <= "1000001"; -- For BLAB3A DC card 2
--	internal_ADDRESS1_DC1 <= "0010000"; -- For BLAB3A DC card 1	
--	internal_ADDRESS2_DC1 <= "0110010"; -- For BLAB3A DC card 1
	internal_COMMAND_DC1  <= "0010";
	
	STATE_MONITOR <= internal_DAC_STATE_MONITOR;
--------------------------------------------------------------
	
	process (IIC_CLK) 
		variable dac_channel : integer range 0 to 7 := 0;
		variable dac_address : integer range 0 to 1 := 0;
	begin
		if (falling_edge(IIC_CLK)) then
			case DAC_STATE is
				when SEARCHING_FOR_UPDATES =>
					internal_DAC_STATE_MONITOR	<= "000";
					if (internal_INTENDED_DAC_VALUES_DC1(dac_address)(dac_channel) /= internal_CURRENT_DAC_VALUES_DC1(dac_address)(dac_channel)) then
						DAC_STATE <= SETTING_UP_UPDATES;
					else 
						if (dac_channel < 7) then
							dac_channel := dac_channel + 1;
						else
							dac_channel := 0;
							if (dac_address < 1) then
								dac_address := dac_address + 1;
							else
								dac_address := 0;
							end if;
						end if;
					end if;
				when SETTING_UP_UPDATES =>
					internal_DAC_STATE_MONITOR	<= "001";
					if (dac_address = 0) then
						internal_ADDRESS_DC1 <= internal_ADDRESS1_DC1;
					elsif (dac_address = 1) then
						internal_ADDRESS_DC1 <= internal_ADDRESS2_DC1;						
					end if;
					internal_CHANNEL_DC1 <= std_logic_vector(to_unsigned(dac_channel, 4));
					internal_DAC_VALUE_DC1 <= internal_INTENDED_DAC_VALUES_DC1(dac_address)(dac_channel);
					DAC_STATE <= START_UPDATING;
				when START_UPDATING =>
					internal_DAC_STATE_MONITOR	<= "010";				
					internal_UPDATE_DC1 <= '1';
					if (internal_UPDATING_DC1 = '1') then
						internal_UPDATE_DC1 <= '0';
						DAC_STATE <= WAIT_FOR_UPDATE;
					end if;
				when WAIT_FOR_UPDATE =>
					internal_DAC_STATE_MONITOR	<= "011";
					if (internal_UPDATING_DC1 = '0') then
						if (internal_UPDATE_SUCCEEDED_DC1 = '1') then
							internal_CURRENT_DAC_VALUES_DC1(dac_address)(dac_channel) <= INTENDED_DAC_VALUES(dac_address)(dac_channel);
						end if;
						if (dac_channel < 7) then
							dac_channel := dac_channel + 1;
						else
							dac_channel := 0;
							if (dac_address < 1) then
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

