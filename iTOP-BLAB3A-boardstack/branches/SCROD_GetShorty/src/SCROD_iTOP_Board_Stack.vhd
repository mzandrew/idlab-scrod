----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:16:07 06/03/2011 
-- Design Name: 
-- Module Name:    SCROD_iTOP_Board_Stack - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

--use work.Board_Stack_Definitions.ALL;

entity SCROD_iTOP_Board_Stack is
	Port ( 
		CLOCK_4NS_P  : in STD_LOGIC;
		CLOCK_4NS_N  : in STD_LOGIC;

		SCROD_SIGNAL : inout std_logic_vector(153 downto 0) 
	);

end SCROD_iTOP_Board_Stack;

architecture Behavioral of SCROD_iTOP_Board_Stack is
   ---------------------------------------------------------
	component IBUF_BUS
	generic(bus_width : integer := 154);
	PORT( 
		I  : in    STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O  : out   STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
	end component;	
	---------------------------------------------------------
	component OBUF_BUS
	generic(bus_width : integer := 154);
	PORT( 
		I  : in    STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O  : out   STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
	end component;	
	---------------------------------------------------------
	component Chipscope_Core
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	end component;	
	attribute BOX_TYPE of Chipscope_Core : component is "BLACK_BOX";	
	---------------------------------------------------------
	component Chipscope_VIO
	  PORT (
		 CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		 CLK : IN STD_LOGIC;
		 ASYNC_IN : IN STD_LOGIC_VECTOR(161 DOWNTO 0);
		 SYNC_IN : IN STD_LOGIC_VECTOR(153 DOWNTO 0);
		 SYNC_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
	end component;
	attribute BOX_TYPE of Chipscope_VIO : component is "BLACK_BOX";	
	--------SIGNAL DEFINITIONS-------------------------------
	signal internal_CLOCK_4NS : std_logic;
	signal internal_COUNTER : std_logic_vector(31 downto 0) := (others => '0');

	signal internal_CHIPSCOPE_CONTROL : std_logic_vector(35 downto 0);
	signal internal_CHIPSCOPE_VIO_IN_SYNC  : std_logic_vector(153 downto 0);
	signal internal_CHIPSCOPE_VIO_IN_ASYNC  : std_logic_vector(161 downto 0);
	signal internal_CHIPSCOPE_VIO_OUT : std_logic_vector(3 downto 0);

	signal internal_BIT_FILLER           : std_logic;
	signal internal_BIT_SHIFT_DIRECTION  : std_logic;
	signal internal_BIT_SHIFT_MANUALLY   : std_logic;
	signal internal_BIT_SHIFT_AUTOMATICALLY : std_logic;
	signal internal_AUTOMATIC_CLOCK : std_logic;
	signal internal_SHIFT_CLOCK : std_logic;

	signal internal_DESIRED_OUTPUTS : std_logic_vector(153 downto 0);
	signal internal_MEASURED_OUTPUTS : std_logic_vector(153 downto 0);	
	signal internal_CURRENT_SIGNAL_BEING_PROBED : std_logic_vector(7 downto 0);
   ---------------------------------------------------------	
begin
   ---------------------------------------------------------
	IBUF_OF_OUTPUTS : IBUF_BUS
	generic map(bus_width => 154)
	port map(
		I	=> SCROD_SIGNAL,
      O	=> internal_MEASURED_OUTPUTS);
   ---------------------------------------------------------
	OBUF_TO_OUTPUTS : OBUF_BUS
	generic map(bus_width => 154)
	port map(
		I	=> internal_DESIRED_OUTPUTS,
      O	=> SCROD_SIGNAL);
   ---------------------------------------------------------
	IBUFGDS_CLOCK_4NS : IBUFGDS
      port map (O  => internal_CLOCK_4NS,
                I  => CLOCK_4NS_P,
                IB => CLOCK_4NS_N); 
	---------------------------------------------------------	
	instance_CHIPSCOPE_CORE : Chipscope_Core
		port map (CONTROL0 => internal_CHIPSCOPE_CONTROL);
	---------------------------------------------------------
	instance_CHIPSCOPE_VIO : Chipscope_VIO
		port map (
			CONTROL => internal_CHIPSCOPE_CONTROL,
			CLK => internal_COUNTER(8),
			ASYNC_IN => internal_CHIPSCOPE_VIO_IN_ASYNC,
			SYNC_IN => internal_CHIPSCOPE_VIO_IN_SYNC,
			SYNC_OUT => internal_CHIPSCOPE_VIO_OUT);
	---------------------------------------------------------

	internal_BIT_FILLER <= internal_CHIPSCOPE_VIO_OUT(0);
	internal_BIT_SHIFT_DIRECTION <= internal_CHIPSCOPE_VIO_OUT(1);
	internal_BIT_SHIFT_MANUALLY <= internal_CHIPSCOPE_VIO_OUT(2);
	internal_BIT_SHIFT_AUTOMATICALLY <= internal_CHIPSCOPE_VIO_OUT(3);

	internal_CHIPSCOPE_VIO_IN_SYNC(153 downto 0) <= internal_MEASURED_OUTPUTS;
	internal_CHIPSCOPE_VIO_IN_ASYNC(153 downto 0) <= internal_DESIRED_OUTPUTS;
	internal_CHIPSCOPE_VIO_IN_ASYNC(161 downto 154) <= internal_CURRENT_SIGNAL_BEING_PROBED;

	internal_AUTOMATIC_CLOCK <= internal_BIT_SHIFT_AUTOMATICALLY and internal_COUNTER(26);
	internal_SHIFT_CLOCK <= internal_BIT_SHIFT_MANUALLY or internal_AUTOMATIC_CLOCK;

	process(internal_BIT_SHIFT_DIRECTION, internal_SHIFT_CLOCK)
	variable active_bit : integer range 0 to 153;
	begin	
		if (rising_edge(internal_SHIFT_CLOCK)) then
			if (internal_BIT_SHIFT_DIRECTION = '0') then
				if (active_bit = 153) then
					active_bit := 0;
				else
					active_bit := (active_bit + 1);
				end if;
			else
				if (active_bit = 0) then
					active_bit := 153;
				else
					active_bit := (active_bit - 1);
				end if;
			end if;

			for i in 0 to 153 loop
				if (i = active_bit) then
					internal_DESIRED_OUTPUTS(i) <= not(internal_BIT_FILLER);
				else
					internal_DESIRED_OUTPUTS(i) <= internal_BIT_FILLER;
				end if;
			end loop;

			internal_CURRENT_SIGNAL_BEING_PROBED <= std_logic_vector( to_unsigned( active_bit , 8 ) );
		end if;
	end process;
	
	process(internal_CLOCK_4NS) begin
		if (rising_edge(internal_CLOCK_4NS)) then
			internal_COUNTER <= std_logic_vector( unsigned(internal_COUNTER) + 1 );
		end if;
	end process;
	
end Behavioral;

