----------------------------------------------------------------------------------
-- Company: UH Manoa
-- Engineer: Isar Mostafanezhad
-- 
-- Create Date:    10:50:43 09/23/2014 
-- Design Name: 
-- Module Name:    KLMRunControl - Behavioral 
-- Project Name:    SCROD Rev A3/4 for BELLE II KLM	
-- Target Devices: SP6
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
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;

entity KLMRunControl is

port (
        clk		 			 : in   std_logic;
        start	    		 : in   std_logic;  -- starting the run control stream- read from input, convert from LL to AXI and then either store in FIFO to be sent to command interpreter or pedestal RAM 
		  din   			   : in 	std_logic_vector(15 downto 0);-- input stream, connects to conc interface ouput
		  busy				 : out std_logic; -- busy working 
		  error				: out std_logic; --error
		
		-- output path to command interpreter
		dout 					: out std_logic_vector(31 downto 0); -- this is the data streem that goes into the command interpreter
		rd_en_cmdfifo 		: in std_logic; --read enable for  command fifo- this is coming from the processor logic
		
		
		--RAM interface for pedestals
		
		
     );



end KLMRunControl;

architecture Behavioral of KLMRunControl is

begin


end Behavioral;

