----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:01:07 12/28/2012 
-- Design Name: 
-- Module Name:    RCO_measure - Behavioral 
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

entity RCO_measure is
port(clk: in std_logic;
RCO_in : in std_logic;
new_num_T : out std_logic;
num_T : out std_logic_vector(15 downto 0);
TC_debug : out std_logic);
end RCO_measure;

architecture Behavioral of RCO_measure is
signal TC, TC_sync, TC_sync_del : std_logic;
signal num_RCO : std_logic_vector(14 downto 0);
signal internal_num_T :  std_logic_vector(15 downto 0);

constant NUMBER_RCO_T_PER_COUNT : integer := 7500;

begin

process(clk)
begin
if(rising_edge(clk)) then
	if(TC_sync = '1') and (TC_sync_del = '0') then 
		internal_num_T <= (others => '0');
		num_T <= internal_num_T;
		new_num_T <= '1';
	else
--		num_T <= internal_num_T; --LM only for debug
		if(internal_num_T <= X"FFFF") then -- saturating count -- the count will be reset by a fake TC below
			internal_num_T <= internal_num_T + 1;
		end if;
		new_num_T <= '0';
	end if;
end if;
end process;


process(RCO_in, internal_num_T)
begin
	if (internal_num_T > X"FFF0") then -- if count saturates - stop.
		TC <='1';
		num_RCO <= (others => '0');
	elsif(rising_edge(RCO_in)) then
		if(num_RCO = NUMBER_RCO_T_PER_COUNT)  then 
			TC <='1';
			num_RCO <= (others => '0');
		else
			TC <='0';
			num_RCO <= num_RCO +1;
	end if;
end if;
end process;

process(clk)
begin
if(rising_edge(clk)) then
	TC_sync <=TC;
	TC_sync_del <=TC_sync;
end if;
end process;

TC_debug <= TC;

end Behavioral;

