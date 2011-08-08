--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Board_Stack_Definitions is
	-- A single LTC2637 has 8 DAC channels, each 12 bits
	type LTC2637_Voltages is array(7 downto 0) of std_logic_vector(11 downto 0);
	-- There are 2 LTC2637 DACs per daughter card.
   type Daughter_Card_Voltages is array(1 downto 0) of LTC2637_Voltages;
  
end Board_Stack_Definitions;

--package body Board_Stack_Definitions is
--
--end package body;