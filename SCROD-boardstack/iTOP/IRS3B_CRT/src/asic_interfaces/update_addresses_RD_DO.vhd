----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:58:41 02/01/2013 
-- Design Name: 
-- Module Name:    update_addresses_RD_DO - Behavioral 
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
use work.asic_definitions_irs3b_carrier_revB.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
	entity update_read_addr is
	port(
		CLOCK         					 			: in std_logic;
		CLOCK_ENABLE                        : in std_logic;
		new_address_reached						: out std_logic; --LM: updating address feedback
		START_NEW_ADDRESS							: in std_logic; --LM: start new address update
		NEW_ADDRESS  : in std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);
		AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK  : out std_logic;
		AsicIn_STORAGE_TO_WILK_ADDRESS_DIR : out std_logic;
		AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT : out std_logic
		);
	end update_read_addr;
	architecture Behavioral of update_read_addr is
	constant zero : std_logic := '0';
	signal raddr_i :  std_logic_vector(8 downto 0);
	
	signal NEW_ADDRESS_scrambled  :  std_logic_vector(ANALOG_MEMORY_ADDRESS_BITS-1 downto 0);

	begin
	 
	 
	 NEW_ADDRESS_scrambled<= NEW_ADDRESS(8 downto 3) &  NEW_ADDRESS(0) &  NEW_ADDRESS(2 downto 1);
	 
inst_irs_block_readout_addr_v3b :  entity work.irs_block_readout_addr_v3b
port map(

 clk_i => CLOCK, 							--% System clock.
 clk_en => CLOCK_ENABLE,
 rst_i => zero,							--% Local reset.
 

 raddr_i => NEW_ADDRESS,					--% Address that we're selecting.
-- raddr_i => NEW_ADDRESS_scrambled,					--% Address that we're selecting.
 raddr_stb_i => START_NEW_ADDRESS,					--% If '1', go to "raddr_i" address
 raddr_reached_o => new_address_reached,				--% If '1', we have reached "raddr_i" (but no Wilkinson)

 irs_rd_sclk_o => AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_SHIFT_CLOCK,				--% RD_SCLK output, for an IRS3
 irs_rd_dir_o => AsicIn_STORAGE_TO_WILK_ADDRESS_DIR,					--% RD_DIR output, for an IRS3
 irs_rd_sin_o => AsicIn_STORAGE_TO_WILK_ADDRESS_SERIAL_INPUT			--% RD_SIN output, for an IRS3
);
end Behavioral;
	
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.asic_definitions_irs3b_carrier_revB.all;
	entity update_sample_addr is
		port(
		CLOCK         					 			: in std_logic;
		CLOCK_ENABLE                        : in std_logic;
		new_sample_address_reached						: out std_logic; --LM: updating sample address 
		START_NEW_SAMPLE_ADDRESS							: in std_logic; --LM: start new sample address update
		SAMPLE_COUNTER_RESET								: in std_logic;
		ASIC_READOUT_CHANNEL_ADDRESS       			: in std_logic_vector(CH_SELECT_BITS-1 downto 0);
		ASIC_READOUT_SAMPLE_ADDRESS         		: in std_logic_vector(SAMPLE_SELECT_BITS-1 downto 0);
		AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK  :	  out std_logic;
		AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR : out std_logic;
		AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT  : out std_logic
		);
	end update_sample_addr;
	architecture Behavioral of update_sample_addr is
	constant zero : std_logic := '0';
	begin
	
	
	 
	
	
		
inst_irs_readout_control_v4 : entity work.irs_readout_control_v4
port map(
 clk_i => CLOCK, 							--% System clock
 clk_en => CLOCK_ENABLE,
 rst_i => zero, 							--% Local reset
 start_i => START_NEW_SAMPLE_ADDRESS,							--% Signal to begin readout.
 increment => SAMPLE_COUNTER_RESET, -- it restarts at the beginning of the channel indicated by ASIC_READOUT_CHANNEL_ADDRESS
 new_sample_address_reached => new_sample_address_reached,
 
-- dat_o => DATA,					--% The output data --
-- valid_o => DATA_VALID,						--% Output data is valid
-- done_o => DONE,							--% Output data is complete (asserted with valid_o on last data)
		
 sel_channel => ASIC_READOUT_CHANNEL_ADDRESS,				--channel select for exclusive reading
		
 DO_DIR => AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_DIR,
 DO_SIN => AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_INPUT,
 DO_SCLK => AsicIn_CHANNEL_AND_SAMPLE_ADDRESS_SERIAL_SHIFT_CLOCK
--		output irs_smpall_o,					//% Data output enable.
--		input [11:0] irs_dat_i				//% DAT[11:0] inputs
);
		
		
		
		
	end Behavioral;

