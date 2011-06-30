----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:58:00 06/29/2011 
-- Design Name: 
-- Module Name:    Packet_Generator - Behavioral 
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

entity Packet_Generator is
    Port ( 
				TX_DST_RDY_N 	: in  STD_LOGIC;
				USER_CLK 		: in  STD_LOGIC;
				RESET 			: in  STD_LOGIC;
				CHANNEL_UP 		: in  STD_LOGIC;
				ENABLE 			: in  STD_LOGIC_VECTOR(1 downto 0);

				TX_SRC_RDY_N 	: out  STD_LOGIC;
				TX_D 				: out  STD_LOGIC_VECTOR (31 downto 0);
				
				DATA_GENERATOR_STATE	:	out  STD_LOGIC_VECTOR(2 downto 0)
			);
end Packet_Generator;

architecture Behavioral of Packet_Generator is

	----------------------------------------------
	component data_generator
		port (
			ENABLE						: IN STD_LOGIC;
			TX_DST_RDY_N				: IN STD_LOGIC;
			FIFO_DATA_COUNT			: IN STD_LOGIC_VECTOR(9 downto 0);
			USER_CLK						: IN STD_LOGIC;
			DATA_TO_FIFO				: OUT STD_LOGIC_VECTOR(31 downto 0);
			WRITE_DATA_TO_FIFO_CLK	: OUT STD_LOGIC;
			TX_SRC_RDY_N				: OUT STD_LOGIC;
			READ_FROM_FIFO_ENABLE	: OUT STD_LOGIC;
			DATA_GENERATOR_STATE		: out STD_LOGIC_VECTOR(2 downto 0);
			FIFO_EMPTY					: out STD_LOGIC
		);
	end component;
	----------------------------------------------
	component packet_fifo
		port (
			rst				: IN std_logic;
			wr_clk			: IN std_logic;
			rd_clk			: IN std_logic;
			din				: IN std_logic_VECTOR(31 downto 0);
			wr_en				: IN std_logic;
			rd_en				: IN std_logic;
			dout				: OUT std_logic_VECTOR(31 downto 0);
			full				: OUT std_logic;
			empty				: OUT std_logic;
			valid				: OUT std_logic;
			wr_data_count	: OUT std_logic_VECTOR(9 downto 0));
	end component;
	----------------------------------------------
	signal internal_TX_DST_RDY_N 	: std_logic;
	signal internal_TX_SRC_RDY_N 	: std_logic;	
	signal internal_TX_D 			: std_logic_vector(31 downto 0);
	signal internal_RESET 			: std_logic;
	signal internal_CHANNEL_UP 	: std_logic;
	signal internal_ENABLE 			: std_logic_vector(1 downto 0);
	signal internal_ENABLED 		: std_logic;
	
	signal internal_WORD_TO_WRITE_TO_FIFO	: std_logic_vector(31 downto 0);
	signal internal_FIFO_DATA_OUT_VALID		: std_logic;
	signal internal_FIFO_DATA_COUNT 			: std_logic_vector(9 downto 0);
	signal internal_WRITE_DATA_TO_FIFO_CLK : std_logic;
	signal internal_READ_FROM_FIFO_ENABLE	: std_logic;
	signal internal_FIFO_FULL					: std_logic;
	signal internal_FIFO_EMPTY					: std_logic;
	signal internal_DATA_GENERATOR_STATE	: std_logic_vector(2 downto 0);

begin
	------------------------------------------
	data_generator_A : DATA_GENERATOR
		port map (
			ENABLE						=> internal_ENABLED,
			TX_DST_RDY_N				=> internal_TX_DST_RDY_N,
			FIFO_DATA_COUNT			=> internal_FIFO_DATA_COUNT,
			USER_CLK						=> USER_CLK,
			DATA_TO_FIFO				=> internal_WORD_TO_WRITE_TO_FIFO,
			WRITE_DATA_TO_FIFO_CLK	=> internal_WRITE_DATA_TO_FIFO_CLK,
			TX_SRC_RDY_N				=> internal_TX_SRC_RDY_N,
			READ_FROM_FIFO_ENABLE	=> internal_READ_FROM_FIFO_ENABLE,
			DATA_GENERATOR_STATE		=> internal_DATA_GENERATOR_STATE,
			FIFO_EMPTY					=> internal_FIFO_EMPTY);
	------------------------------------------
	packet_cache_A : packet_fifo
		port map (
			rst 				=> internal_RESET,
			wr_clk 			=> internal_WRITE_DATA_TO_FIFO_CLK,
			rd_clk 			=> USER_CLK,
			din 				=> internal_WORD_TO_WRITE_TO_FIFO,
			wr_en 			=> '1',
			rd_en 			=> internal_READ_FROM_FIFO_ENABLE,
			dout 				=> internal_TX_D,
			full 				=> internal_FIFO_FULL,
			empty 			=> internal_FIFO_EMPTY,
			valid 			=> internal_FIFO_DATA_OUT_VALID,
			wr_data_count 	=> internal_FIFO_DATA_COUNT);			
	------------------------------------------
	internal_CHANNEL_UP <= CHANNEL_UP;
	internal_RESET <= RESET;
	internal_TX_DST_RDY_N <= TX_DST_RDY_N;
	TX_SRC_RDY_N <= internal_TX_SRC_RDY_N;
	TX_D <= internal_TX_D;
	internal_ENABLE <= ENABLE;
	internal_ENABLED <= internal_ENABLE(0) and internal_ENABLE(1);
	
	DATA_GENERATOR_STATE <= internal_DATA_GENERATOR_STATE;

end Behavioral;