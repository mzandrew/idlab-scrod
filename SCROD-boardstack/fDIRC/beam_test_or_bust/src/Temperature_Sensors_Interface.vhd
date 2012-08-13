----------------------------------------------------------------------------------
-- Interface to the temperature sensors on the full board stack
-- Description:
--		Inputs/outputs:
--		
--		READ_TEMP_NOW 		  - input bit which is checked during the idle state of the temperature 
--               				 sensor interface state machine(s) to begin a readout
--		CLK_100kHz_MAX		  - input clock used to drive the IIC state machines
--    TMP_SCL 			  	  - output bit for the TMP IIC SCL lines
--		TMP_SDA				  - inout bit for the TMP IIC SDA lines
--		TEMP_R1		  		  - 12 bit output for the temperature on carrier level 1
--
--		This module interfaces to the temperature control sensors on the board stack,
--    Texas Instruments model TMP112 ( http://www.ti.com/lit/ds/symlink/tmp112.pdf ).
--		As of this writing, the board stack has only one sensor on level 1, but this module
--    is deliberately left with a (currently wasted) heirarchical structure so that we
--    can add control for the other temperature sensor that was intended for level 3.
--   
-- Change log:
-- 2011-09-29 - Created by Kurtis
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity Temperature_Sensors_Interface is
	Port (
			READ_TEMP_NOW 	: in		std_logic;
			CLK_100kHz_MAX : in		std_logic;
			TMP_SCL 			: out		std_logic;
			TMP_SDA			: inout	std_logic;
			TEMP_R1			: out		std_logic_vector(11 downto 0)
		  );
end Temperature_Sensors_Interface;

architecture Behavioral of Temperature_Sensors_Interface is
	signal IIC_ADDRESS_R1 : std_logic_vector(1 downto 0);
begin
	IIC_ADDRESS_R1 <= TMP112_Address_R1;
	
	map_TMP112_INTERFACE_R1 : entity work.TMP112_I2C_INTERFACE 
	port map(
		CLK				=> CLK_100kHz_MAX,			
		READ_NOW			=> READ_TEMP_NOW,
		ADDRESS			=> IIC_ADDRESS_R1,
		SCL				=> TMP_SCL,
		SDA				=> TMP_SDA,
		LAST_TEMP_READ	=> TEMP_R1
	);

end Behavioral;

