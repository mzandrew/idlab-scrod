----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:14:50 10/03/2011 
-- Design Name: 
-- Module Name:    ASIC_trigger_interface - Behavioral 
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

entity ASIC_trigger_interface is
    Port ( TRIGGER_BITS			: in  ASIC_Trigger_Bits_C_R_CH;
			  RESET_SCALERS		: in 	std_logic;
			  LATCH_SCALERS		: in 	std_logic;
           SCALERS 				: out ASIC_Scalers_C_R_CH;
			  CLOCK_4xSST			: in	std_logic;
			  CONTINUE_WRITING	: in 	std_logic;
			  TRIGGER_STREAMS		: out ASIC_Trigger_Stream_C_R_CH
	);	
end ASIC_trigger_interface;

architecture Behavioral of ASIC_trigger_interface is

begin

	gen_ASIC_trigger_scalers_C : for i in 0 to 3 generate
		gen_ASIC_trigger_scalers_R : for j in 0 to 3 generate
			gen_ASIC_trigger_scalers_CH : for k in 0 to 7 generate
				map_trigger_scaler_for_ASIC_C_R_CH : entity work.trigger_scaler
					PORT MAP (
						TRIGGER_BIT => TRIGGER_BITS(i)(j)(k),
						RESET			=> RESET_SCALERS,
						LATCH_VALUE	=> LATCH_SCALERS,
						SCALER 		=> SCALERS(i)(j)(k)
				);	
			end generate;
		end generate;
	end generate;
	
	gen_ASIC_trigger_stream_C : for i in 0 to 3 generate
		gen_ASIC_trigger_stream_R : for j in 0 to 3 generate
			gen_ASIC_trigger_stream_CH : for k in 0 to 3 generate
				map_trigger_stream_for_ASIC_C_R_CH : entity work.trigger_stream
					PORT MAP (
						TRIGGER_BIT 		=> TRIGGER_BITS(i)(j)(k),
						CLOCK_4xSST			=> CLOCK_4xSST,
						CONTINUE_WRITING	=> CONTINUE_WRITING,
						STREAM_OUT 			=> TRIGGER_STREAMS(i)(j)(k)
				);	
			end generate;
		end generate;
	end generate;	

end Behavioral;

