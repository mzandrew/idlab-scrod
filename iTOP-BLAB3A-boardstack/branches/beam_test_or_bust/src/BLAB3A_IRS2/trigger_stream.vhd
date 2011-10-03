----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:24:44 10/03/2011 
-- Design Name: 
-- Module Name:    trigger_stream - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity trigger_stream is
    Port ( TRIGGER_BIT 	: in  std_logic;
			  CLOCK_4xSST	: in 	std_logic;
			  CONTINUE_WRITING : in 	std_logic;
           STREAM_OUT	: out ASIC_Trigger_Stream);
end trigger_stream;

architecture Behavioral of trigger_stream is
	signal internal_TRIGGER_STREAM : std_logic_vector(15 downto 0) := x"0000";
begin
	
	STREAM_OUT <= internal_TRIGGER_STREAM;

	process(CLOCK_4xSST) begin
		if ( rising_edge(CLOCK_4xSST) ) then
			--Only shift in the trigger stream bit if we're still sampling
			if (CONTINUE_WRITING = '1') then
				--Shift all bits by one spot, except for lowest bit...
				for i in 15 downto 1 loop
					internal_TRIGGER_STREAM(i) <= internal_TRIGGER_STREAM(i-1);
				end loop;
				--Lowest bit should be the current status of the trigger bit.
				internal_TRIGGER_STREAM(0) <= TRIGGER_BIT;
			end if;
		end if;
	end process;

end Behavioral;

