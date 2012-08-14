----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:01:23 10/03/2011 
-- Design Name: 
-- Module Name:    trigger_scaler - Behavioral 
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

entity trigger_scaler is
    Port ( TRIGGER_BIT 	: in  std_logic;
			  RESET			: in 	std_logic;
			  LATCH_VALUE	: in 	std_logic;
           SCALER 		: out ASIC_Scaler);
end trigger_scaler;

architecture Behavioral of trigger_scaler is
	signal internal_SCALER 				: ASIC_Scaler := (others => '0');
	signal internal_SCALER_LATCHED 	: ASIC_Scaler := (others => '0');
begin
	SCALER <= internal_SCALER_LATCHED;

	process(RESET, TRIGGER_BIT) begin
		if (RESET = '1') then
			internal_SCALER 			<= (others => '0');
		elsif (rising_edge(trigger_bit)) then
			if ( unsigned(internal_SCALER) < x"FFFF" ) then
				internal_SCALER 			<= std_logic_vector( unsigned(internal_SCALER) + 1);
			end if;
		end if;
	end process;
	
	process(RESET, LATCH_VALUE) begin
		if (RESET = '1') then
			internal_SCALER_LATCHED <= (others => '0');
		elsif ( rising_edge(LATCH_VALUE) ) then
			internal_SCALER_LATCHED <= internal_SCALER;
		end if;
	end process;

end Behavioral;

