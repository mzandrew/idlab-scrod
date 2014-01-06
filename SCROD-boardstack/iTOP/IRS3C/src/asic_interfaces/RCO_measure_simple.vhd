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

entity RCO_measure_simple is
port(clk: in std_logic;
RCO_in : in std_logic;
new_num_T : out std_logic;
num_T : out std_logic_vector(15 downto 0);
TC_debug : out std_logic);
end RCO_measure_simple;

architecture Behavioral of RCO_measure_simple is
signal TC, TC_sync, TC_sync_del, TC_ack : std_logic;
signal num_RCO : std_logic_vector(15 downto 0);
signal num_RCO_Gray : std_logic_vector(16 downto 0);
signal num_RCO_Gray_latched : std_logic_vector(15 downto 0);
signal num_RCO_latched : std_logic_vector(15 downto 0);

signal internal_num_T :  std_logic_vector(15 downto 0);
signal internal_num_T_old :  std_logic_vector(15 downto 0);
signal one_ms_counter :  std_logic_vector(15 downto 0);

signal state : std_logic_vector(1 downto 0) := "00";

constant NUMBER_T_PER_MS : integer := 50000;

begin

--process(clk)
--begin
--if(rising_edge(clk)) then
--	new_num_T <= '0';
--	state <= "00";
--	if one_ms_counter < NUMBER_T_PER_MS then
--		one_ms_counter <= one_ms_counter + 1;
--		TC <= '0';
--		state <="00";
--	elsif state = "00" then
--		TC <= '1';
--		state <= "01";
--	elsif state = "01" then
--		TC <= '1';
--		if TC_ack = '1' then
--			internal_num_T<=num_RCO;
--			state <= "10";
--			internal_num_T_old <=internal_num_T;
--		end if;
--	elsif state = "10" then
--			state <= "11";
--			new_num_T <= '1';
--	else
--		one_ms_counter <= (others => '0');		
--	end if;
--	num_T <= internal_num_T - internal_num_T_old;
--end if;
--end process;


--process(RCO_in) -- non pure free-running due to sync - acknowledgement based (try Gray code later)
--begin
--	if(rising_edge(RCO_in)) then
--		if TC = '0' then
--			num_RCO <= num_RCO +1;
--			TC_ack<='0';			
--		else
--			TC_ack<='1';
--		end if;
--	end if;
--end process;

process(RCO_in) --  pure free-running : Gray code converted
begin
	if(rising_edge(RCO_in)) then
		num_RCO <= num_RCO +1;	
		num_RCO_Gray <= (num_RCO & '0') xor ('0' & num_RCO);
	end if;
end process;



process(clk) --latch the Gray code on internal clock domain
begin
if(rising_edge(clk)) then
	num_RCO_Gray_latched <= num_RCO_Gray(16 downto 1);
end if;
end process;


process(num_RCO_Gray_latched) -- convert the latched Gray code to binary
begin
	num_RCO_latched(15) <= num_RCO_Gray_latched(15);	
	num_RCO_latched(14) <= num_RCO_Gray_latched(15) xor num_RCO_Gray_latched(14);	
	for i in 13 downto 0 loop
	num_RCO_latched(i) <= num_RCO_Gray_latched(i) xor num_RCO_latched(i+1);
	end loop;
end process;


process(clk)
begin
if(rising_edge(clk)) then
	new_num_T <= '0';
	if one_ms_counter < NUMBER_T_PER_MS then
		one_ms_counter <= one_ms_counter + 1;
		TC <= '0';
	else
		internal_num_T<=num_RCO_latched;
		internal_num_T_old <=internal_num_T;
		one_ms_counter <= (others => '0');		
		new_num_T <= '1';
	end if;
	num_T <= internal_num_T - internal_num_T_old;
end if;
end process;


--process(clk)
--begin
--if(rising_edge(clk)) then
--	TC_sync <=TC;
--	TC_sync_del <=TC_sync;
--end if;
--end process;
--
--TC_debug <= TC;

end Behavioral;

