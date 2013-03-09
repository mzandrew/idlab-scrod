----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:43:41 12/28/2012 
-- Design Name: 
-- Module Name:    Feedback_RCO - Behavioral 
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
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Feedback_RCO is
port(
clk : in std_logic;
num_T : in std_logic_vector(15 downto 0);
desirednumT : in std_logic_vector(15 downto 0);
newnumT : in std_logic;
update : out std_logic;
forcedVadjN: out  std_logic_vector(11 downto 0));
end Feedback_RCO;

architecture Behavioral of Feedback_RCO is

signal int_VadjN : std_logic_vector(11 downto 0) := "010111000000";
signal cnt_update : std_logic_vector(9 downto 0) := "0000000000";


begin

process(clk)
begin
if(rising_edge(clk)) then
	update <='0';
	if(newnumT = '1') then
		if cnt_update < 1000 then
			cnt_update <= cnt_update +1;
		else
			cnt_update <= (others => '0');
			update <='1';
			if num_T + 10 < desirednumT  then int_VadjN <= int_VadjN - 1;
			elsif (num_T > desirednumT + 10) then int_VadjN <= int_VadjN + 1;
			end if;
		end if;
	end if;
end if;
end process;
forcedVadjN <= int_VadjN;

end Behavioral;

