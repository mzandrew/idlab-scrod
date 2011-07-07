----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:41:38 07/06/2011 
-- Design Name: 
-- Module Name:    Packet_Receiver - Behavioral 
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

entity Packet_Receiver is
port
(
    -- User Interface
    RX_D            : in  std_logic_vector(31 downto 0); 
    RX_SRC_RDY_N    : in  std_logic;

    -- System Interface
    USER_CLK        : in  std_logic;   
    RESET           : in  std_logic;
    CHANNEL_UP      : in  std_logic;
    ERR_COUNT       : out std_logic_vector(7 downto 0)
  
);
end Packet_Receiver;

architecture Behavioral of Packet_Receiver is

	type RECEIVE_STATE_TYPE is ( WAITING_FOR_HEADER, READING_PACKET_SIZE, READING_PACKET_TYPE, READING_PROTOCOL_DATE);
	signal internal_RX_D : std_logic_vector(31 downto 0);
	signal internal_WRONG_PACKET_TYPE : std_logic_vector(
	signal RECEIVE_STATE : RECEIVE_STATE_TYPE := WAITING_FOR_HEADER;

begin

	internal_RX_D <= RX_D;

	process (USER_CLK, RX_SRC_RDY_N) 
		variable packet_size : unsigned(15 downto 0);
		variable checksum    : unsigned(31 downto 0);
		variable values_read : integer range 0 to 255 := 0;
	begin
		if (rising_edge(USER_CLK) and internal_RX_SRC_RDY_N = '0') then
			case RECEIVE_STATE is
				when WAITING_FOR_HEADER =>
					values_read := 0;
					if (internal_RX_D = x"00BE11E2") then
						checksum := x"00BE11E2";					
						RECEIVE_STATE <= WAITING_FOR_PACKET_SIZE;
					end if;
				when READING_PACKET_SIZE =>
					packet_size <= unsigned(internal_RX_D);
					checksum := checksum + packet_size;
					if (packet_size < 
					RECEIVE_STATE <= WAITING_FOR_PACKET_TYPE;					
				when READING_PACKET_TYPE =>
					checksum := checksum + unsigned(internal_RX_D);
					if (internal_RX_D = x"B01DFACE") then
						RECEIVE_STATE <= READING_PROTOCOL_DATE;
					else
						RECEIVE_STATE <= WAITING_FOR_HEADER;
					end if;
				when READING_PROTOCOL_DATE =>

				when READING_VALUES =>
					
				when READING_CHECKSUM =>
				when READING_FOOTER =>
				when SET_SEND_EVENT_FLAG =>
				when others =>
					RECEIVE_STATE <= WAITING_FOR_HEADER;
			end case;
		end if;
	end process;

end Behavioral;

