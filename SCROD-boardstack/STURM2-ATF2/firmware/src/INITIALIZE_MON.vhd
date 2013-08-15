----------------------------------------------------------------------------------
-- Company: idlab
-- Engineer: Matthew Fall
-- 
-- Create Date:    12:50:44 07/26/2013 
-- Design Name: 
-- Module Name:    INITIALIZE_MON - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This purpose of this module is to create a pulse of TST_CLR followed by a pulse of TST_START.  This should properly initialize the RCO,
--						causing the TST_START signal to oscillate.
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

entity INITIALIZE_MON is
    Port ( xCLR_ALL : in  STD_LOGIC;
           xCLK_10MHz : in  STD_LOGIC;
           TST_CLR : out  STD_LOGIC;
           TST_START : out  STD_LOGIC);
end INITIALIZE_MON;

architecture Behavioral of INITIALIZE_MON is
type STATE_TYPE is (PRE_CLEAR, WAIT_FOR_RCO_TO_STABILIZE, BRING_DOWN_TST_CLR, TST_START_PULSE, IDLE);
signal STATE : STATE_TYPE := PRE_CLEAR;

begin

process(xCLR_ALL, xCLK_10MHz)
variable wait_count : integer := 0;
begin
	if rising_edge(xCLK_10MHz) then
		case STATE is
			when PRE_CLEAR =>	--wait until falling edge of xCLR_ALL
				TST_CLR <= '1';
				TST_START <= '0';
				if xCLR_ALL'event and xCLR_ALL = '0' then
					STATE <= WAIT_FOR_RCO_TO_STABILIZE;
				else
					STATE <= PRE_CLEAR;
				end if;
			when WAIT_FOR_RCO_TO_STABILIZE =>	--allow time for RCO to start responding to TST_CLR and TST_START
				TST_CLR <= '1';
				TST_START <= '0';
				wait_count := wait_count + 1;
				if wait_count = 700 then	--about 70us
					STATE <= BRING_DOWN_TST_CLR;
				else
					STATE <= WAIT_FOR_RCO_TO_STABILIZE;
				end if;
			when BRING_DOWN_TST_CLR =>
				TST_CLR <= '0';
				TST_START <= '0';
				STATE <= TST_START_PULSE;
			when TST_START_PULSE =>	--create a short pulse of TST_START to initialize the RCO
				TST_CLR <= '0';
				TST_START <= '1';
				STATE <= IDLE;
			when IDLE =>	--stay idle forever so that the FSM doesn't keep repeating
				TST_CLR <= '0';
				TST_START <= '0';
		end case;
	end if;
end process;

end Behavioral;

