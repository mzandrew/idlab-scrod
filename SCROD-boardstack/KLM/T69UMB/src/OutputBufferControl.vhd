----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:44:03 03/02/2014 
-- Design Name: 
-- Module Name:    OutputBufferControl - Behavioral 
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

entity OutputBufferControl is
    Port ( clk : in  STD_LOGIC;
           REQUEST_PACKET 			: in  STD_LOGIC;
			  EVTBUILD_DONE 			: in  STD_LOGIC;
           BUFFER_FIFO_RESET 		: out  STD_LOGIC;
           BUFFER_FIFO_WR_CLK 	: out  STD_LOGIC;
           BUFFER_FIFO_WR_EN 		: out  STD_LOGIC;
           BUFFER_FIFO_DIN 		: out  STD_LOGIC_VECTOR (31 downto 0);
			  EVTBUILD_START 			: out  STD_LOGIC;
			  EVTBUILD_MAKE_READY 	: out  STD_LOGIC
	 );
end OutputBufferControl;

architecture Behavioral of OutputBufferControl is

signal internal_REQUEST_PACKET 					: std_logic := '0';
signal internal_REQUEST_PACKET_reg 				: std_logic_vector := "00";
signal internal_EVTBUILD_DONE		 				: std_logic := '0';
signal INTERNAL_COUNTER 							: UNSIGNED(15 downto 0) :=  x"0000";

begin

BUFFER_FIFO_RESET <= '0';
BUFFER_FIFO_WR_CLK <= clk;
BUFFER_FIFO_DIN <= x"ABCDEF12";

--latch signals to local clock domain
process(clk)
	begin
		if (clk'event and clk = '1') then
			internal_REQUEST_PACKET <= REQUEST_PACKET;
			internal_EVTBUILD_DONE 	<= EVTBUILD_DONE;
	end if;
end process;


--detect REQUEST rising edge
process(smp_clk)
begin
if (smp_clk'event and smp_clk = '1') then
	internal_REQUEST_PACKET_reg(1) <= internal_REQUEST_PACKET_reg(0);
	internal_REQUEST_PACKET_reg(0) <= internal_REQUEST_PACKET;
end if;
end process;

--place data in BUFFER-FIFO after REQUEST_PACKET goes high
process(clk)
begin
if (clk'event and clk = '1') then

  Case next_state is
  
  When Idle =>
    BUFFER_FIFO_WR_EN		<= '0';
    EVTBUILD_START  	      <= '0';
    EVTBUILD_MAKE_READY    <= '0';
	 EVTBUILD_START			<= '0';
	 EVTBUILD_MAKE_READY		<= '0';
    INTERNAL_COUNTER <= (Others => '0');
    if( internal_REQUEST_PACKET_reg = "01") then
      next_state 		  <= WaitStart;
    else
      next_state 		<= Idle;
    end if;
	
   When Load =>
    BUFFER_FIFO_WR_EN 		<= '1';
	 INTERNAL_COUNTER			<= INTERNAL_COUNTER + '1';
    if(INTERNAL_COUNTER < x"10") then
      next_state 	<= Load;
    else
		next_state 	<= START_EVTBUILD;
    end if;
	
	--start event builder
	When START_EVTBUILD =>
		BUFFER_FIFO_WR_EN		<= '0';
		EVTBUILD_START <= '1';
			next_trig_state <= WAIT_EVTBUILD_DONE;
			
	--wait for event builder to finish
	When WAIT_EVTBUILD_DONE =>
	if( internal_EVTBUILD_DONE = '0' ) then 
		next_trig_state <= WAIT_EVTBUILD_DONE;
	else
		next_trig_state <= SET_EVTBUILD_MAKE_READY;
	end if;
	
	--send MAKE_READY signal, hand shake for event builder finishing
	When SET_EVTBUILD_MAKE_READY =>
		EVTBUILD_MAKE_READY <= '1';
			next_trig_state <= WAIT_READOUT_RESET;
	
	When Others =>
		BUFFER_FIFO_WR_EN		<= '0';
		EVTBUILD_START  	      <= '0';
		EVTBUILD_MAKE_READY    <= '0';
		EVTBUILD_START			<= '0';
		EVTBUILD_MAKE_READY		<= '0';
		INTERNAL_COUNTER <= (Others => '0');
			next_trig_state <= Idle;
		
	end Case;
end if;
end process;

end Behavioral;

