----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:37:33 06/29/2011 
-- Design Name: 
-- Module Name:    data_generator - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_generator is
    Port ( 	ENABLE 						: in  STD_LOGIC;
				TX_DST_RDY_N 				: in  STD_LOGIC;
				FIFO_DATA_COUNT 			: in  STD_LOGIC_VECTOR (9 downto 0);
				FIFO_EMPTY					: in	STD_LOGIC;
				USER_CLK						: in 	STD_LOGIC;			  
				DATA_TO_FIFO 				: out STD_LOGIC_VECTOR (31 downto 0);
				WRITE_DATA_TO_FIFO_CLK 	: out STD_LOGIC;
				TX_SRC_RDY_N 				: out STD_LOGIC;
				READ_FROM_FIFO_ENABLE	: out STD_LOGIC;
				DATA_GENERATOR_STATE		: out STD_LOGIC_VECTOR(2 downto 0));
end data_generator;

architecture Behavioral of data_generator is

	type STATE_TYPE is ( IDLE, MAKE_DATA_READY_FOR_FIFO, CLOCK_DATA_INTO_FIFO, SEND_DATA);

	signal internal_STATE 						: STATE_TYPE;
	signal internal_ENABLE 						: std_logic;
	signal internal_TX_DST_RDY_N 				: std_logic;
	signal internal_FIFO_DATA_COUNT			: std_logic_vector(9 downto 0);
	signal internal_DATA_TO_FIFO				: std_logic_vector(31 downto 0);
	signal internal_WRITE_DATA_TO_FIFO_CLK	: std_logic;
	signal internal_TX_SRC_RDY_N				: std_logic;
	signal internal_CHECKSUM					: std_logic_vector(31 downto 0);
	signal internal_READ_FROM_FIFO_ENABLE	: std_logic;
	signal internal_DATA_GENERATOR_STATE	: std_logic_vector(2 downto 0);
	signal internal_FIFO_EMPTY					: std_logic;

begin

	internal_ENABLE 				<= ENABLE;
	internal_TX_DST_RDY_N 		<= TX_DST_RDY_N;
	internal_FIFO_DATA_COUNT 	<= FIFO_DATA_COUNT;
	DATA_TO_FIFO 					<= internal_DATA_TO_FIFO;
	WRITE_DATA_TO_FIFO_CLK 		<= internal_WRITE_DATA_TO_FIFO_CLK;
	TX_SRC_RDY_N 					<= internal_TX_SRC_RDY_N;
	READ_FROM_FIFO_ENABLE		<= internal_READ_FROM_FIFO_ENABLE;
	DATA_GENERATOR_STATE			<= internal_DATA_GENERATOR_STATE;
	internal_FIFO_EMPTY			<= FIFO_EMPTY;

	process(USER_CLK) 
		variable word_number : integer range 0 to 139 := 0;
	begin
		if (rising_edge(USER_CLK)) then
			case internal_STATE is
				when IDLE =>
					internal_DATA_GENERATOR_STATE <= "000";
					internal_TX_SRC_RDY_N <= '1';				
					internal_READ_FROM_FIFO_ENABLE <= '0';
					if (internal_ENABLE = '1') then
						word_number := 0;
						internal_CHECKSUM <= (others => '0');
						internal_STATE <= MAKE_DATA_READY_FOR_FIFO;
					end if;
				when MAKE_DATA_READY_FOR_FIFO =>
					internal_DATA_GENERATOR_STATE <= "001";				
					internal_WRITE_DATA_TO_FIFO_CLK <= '0';				
					internal_STATE <= CLOCK_DATA_INTO_FIFO;					
					if (word_number = 0) then
						internal_DATA_TO_FIFO <= x"00BE11E2";
					elsif (word_number = 1) then
						internal_DATA_TO_FIFO <= x"0000008C";
					elsif (word_number = 2) then
						internal_DATA_TO_FIFO <= x"00C0FFEE";
					elsif (word_number = 3) then
						internal_DATA_TO_FIFO <= x"20110629";
					elsif (word_number >= 4 and word_number <= 137) then
						internal_DATA_TO_FIFO <= x"DEADBEEF";
					elsif (word_number = 138) then
						internal_DATA_TO_FIFO <= std_logic_vector(unsigned(internal_CHECKSUM) + x"62504944");
					elsif (word_number = 139) then
						internal_DATA_TO_FIFO <= x"62504944";					
					end if;
				when CLOCK_DATA_INTO_FIFO => 
					internal_DATA_GENERATOR_STATE <= "010";				
					internal_WRITE_DATA_TO_FIFO_CLK <= '1';
					internal_CHECKSUM <= std_logic_vector(unsigned(internal_CHECKSUM) + unsigned(internal_DATA_TO_FIFO));
					if (word_number = 139) then
						internal_STATE <= SEND_DATA;
					else
						word_number := word_number + 1;
						internal_STATE <= MAKE_DATA_READY_FOR_FIFO;
					end if;
				when SEND_DATA =>
					internal_DATA_GENERATOR_STATE <= "011";				
					internal_TX_SRC_RDY_N <= '0';
					internal_READ_FROM_FIFO_ENABLE <= '1';
					if (internal_FIFO_EMPTY = '1') then
						internal_STATE <= IDLE;
					end if;
				when others =>
					internal_DATA_GENERATOR_STATE <= "100";				
					internal_STATE <= IDLE;
			end case;
		end if;
	end process;

end Behavioral;

