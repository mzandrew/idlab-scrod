-- 2011-09-03 mza

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity pseudo_data_block_ram is
	generic (
		WIDTH_OF_DATA_BUS                                   : integer := 16;
		WIDTH_OF_ADDRESS_BUS                                : integer := 15;
		LOG_BASE_2_OF_NUMBER_OF_VALUES_IN_REPEATING_PATTERN : integer :=  5
	);
	port (
		CLOCK      : in    std_logic;
		ADDRESS_IN : in    std_logic_vector(WIDTH_OF_ADDRESS_BUS-1 downto 0);
		DATA_OUT   :   out std_logic_vector(WIDTH_OF_DATA_BUS-1 downto 0)
	);
end pseudo_data_block_ram;

architecture pseudo_data_block_ram_architecture of pseudo_data_block_ram is
	signal least_significant_part_of_address : unsigned(LOG_BASE_2_OF_NUMBER_OF_VALUES_IN_REPEATING_PATTERN-1 downto 0) := "0" & x"6";
	signal internal_DATA_OUT : std_logic_vector(WIDTH_OF_DATA_BUS-1 downto 0) := x"0123";
begin
	DATA_OUT <= internal_DATA_OUT;
	process (CLOCK)
	begin
		if falling_edge(CLOCK) then
			least_significant_part_of_address <= unsigned(ADDRESS_IN(LOG_BASE_2_OF_NUMBER_OF_VALUES_IN_REPEATING_PATTERN-1 downto 0));
		end if;
		if rising_edge(CLOCK) then
			if    (least_significant_part_of_address =  0) then
				internal_DATA_OUT <= x"0000";
			elsif (least_significant_part_of_address =  1) then
				internal_DATA_OUT <= x"1111";
			elsif (least_significant_part_of_address =  2) then
				internal_DATA_OUT <= x"2222";
			elsif (least_significant_part_of_address =  3) then
				internal_DATA_OUT <= x"3333";
			elsif (least_significant_part_of_address =  4) then
				internal_DATA_OUT <= x"4444";
			elsif (least_significant_part_of_address =  5) then
				internal_DATA_OUT <= x"5555";
			elsif (least_significant_part_of_address =  6) then
				internal_DATA_OUT <= x"6666";
			elsif (least_significant_part_of_address =  7) then
				internal_DATA_OUT <= x"7777";
			elsif (least_significant_part_of_address =  8) then
				internal_DATA_OUT <= x"8888";
			elsif (least_significant_part_of_address =  9) then
				internal_DATA_OUT <= x"9999";
			elsif (least_significant_part_of_address = 10) then
				internal_DATA_OUT <= x"aaaa";
			elsif (least_significant_part_of_address = 11) then
				internal_DATA_OUT <= x"bbbb";
			elsif (least_significant_part_of_address = 12) then
				internal_DATA_OUT <= x"cccc";
			elsif (least_significant_part_of_address = 13) then
				internal_DATA_OUT <= x"dddd";
			elsif (least_significant_part_of_address = 14) then
				internal_DATA_OUT <= x"eeee";
			elsif (least_significant_part_of_address = 15) then
				internal_DATA_OUT <= x"ffff";
			elsif (least_significant_part_of_address = 16) then
				internal_DATA_OUT <= x"eeee";
			elsif (least_significant_part_of_address = 17) then
				internal_DATA_OUT <= x"dddd";
			elsif (least_significant_part_of_address = 18) then
				internal_DATA_OUT <= x"cccc";
			elsif (least_significant_part_of_address = 19) then
				internal_DATA_OUT <= x"bbbb";
			elsif (least_significant_part_of_address = 20) then
				internal_DATA_OUT <= x"aaaa";
			elsif (least_significant_part_of_address = 21) then
				internal_DATA_OUT <= x"9999";
			elsif (least_significant_part_of_address = 22) then
				internal_DATA_OUT <= x"8888";
			elsif (least_significant_part_of_address = 23) then
				internal_DATA_OUT <= x"7777";
			elsif (least_significant_part_of_address = 24) then
				internal_DATA_OUT <= x"6666";
			elsif (least_significant_part_of_address = 25) then
				internal_DATA_OUT <= x"5555";
			elsif (least_significant_part_of_address = 26) then
				internal_DATA_OUT <= x"4444";
			elsif (least_significant_part_of_address = 27) then
				internal_DATA_OUT <= x"3333";
			elsif (least_significant_part_of_address = 28) then
				internal_DATA_OUT <= x"2222";
			elsif (least_significant_part_of_address = 29) then
				internal_DATA_OUT <= x"1111";
			elsif (least_significant_part_of_address = 30) then
				internal_DATA_OUT <= x"0000";
			elsif (least_significant_part_of_address = 31) then
				internal_DATA_OUT <= x"5aa5";
			else
				internal_DATA_OUT <= x"0340";
			end if;
		end if;
	end process;
end architecture pseudo_data_block_ram_architecture;

