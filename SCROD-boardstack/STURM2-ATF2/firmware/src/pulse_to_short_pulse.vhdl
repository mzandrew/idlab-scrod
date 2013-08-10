-- 2011-01-28 mza

library ieee;
use ieee.std_logic_1164.all;

entity pulse_to_short_pulse is
port (
		i     : in    std_logic;
		clock : in    std_logic;
		o     :   out std_logic
	);
end pulse_to_short_pulse;

architecture behavioral of pulse_to_short_pulse is
	signal i1 : std_logic;
	signal i2 : std_logic;
begin
	process (clock, i)
	begin
		if rising_edge(clock) then
			i1 <= i;
			i2 <= i1;
		end if;
	end process;
	o <= i and (not i2);
end behavioral;
