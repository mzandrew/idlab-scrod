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

use work.Board_Stack_Definitions.ALL;

entity SCROD_iTOP_Board_Stack is
    Port ( 
--			  LEDS : out STD_LOGIC_VECTOR(15 downto 0);
--			  MONITOR : out STD_LOGIC_VECTOR(15 downto 0);
--			  SCL_DC1 : out STD_LOGIC;
--			  SDA_DC1 : inout STD_LOGIC;
           CLOCK_4NS_P : in STD_LOGIC;
			  CLOCK_4NS_N : in STD_LOGIC;
			  ---BLAB3A I/Os
--			  ASIC_CH_SEL	 	  : out std_logic_vector(2 downto 0);
			  ASIC_RD_ADDR	 	  : inout std_logic_vector(9 downto 0);
--			  ASIC_SMPL_SEL 	  : out std_logic_vector(5 downto 0);
--			  ASIC_SMPL_SEL_ALL : out std_logic;
--			  ASIC_RD_ENA	 	  : out std_logic;
--			  ASIC_RAMP	 	 	  : out std_logic;
--			  ASIC_DAT		     : in std_logic_vector(11 downto 0);
--			  ASIC_TDC_START    : out std_logic;
--			  ASIC_TDC_CLR	     : out std_logic;
--			  ASIC_WR_STRB	     : out std_logic;
			  ASIC_WR_ADDR	     : inout std_logic_vector(9 downto 0) );
--			  ASIC_SSP_IN	     : out std_logic;
--			  ASIC_SST_IN	     : out std_logic;
--			  ASIC_SSP_OUT		  : in  std_logic;
--			  ASIC_TRIGGER		  : in std_logic_vector(7 downto 0);
--			  ASIC_DC1_DISABLE  : out std_logic;
--			  ASIC_trigger_sign : out std_logic;
			  -- Pulse output
--			  ASIC_CARRIER1_CAL_OUT : out std_logic;			  
			  -- USB I/O
--			  IFCLK      	: in    std_logic; --50 MHz CLK
--			  CLKOUT     	: in    std_logic; 
--			  FD         	: inout std_logic_vector(15 downto 0);
--			  PA0        	: in    std_logic; 
--			  PA1        	: in    std_logic; 
--			  PA2        	: out   std_logic; 
--			  PA3        	: in    std_logic; 
--			  PA4        	: out   std_logic; 
--			  PA5        	: out   std_logic; 
--			  PA6        	: out   std_logic; 
--			  PA7        	: in    std_logic; 
--			  CTL0       	: in    std_logic; 
--			  CTL1       	: in    std_logic; 
--			  CTL2       	: in    std_logic; 
--			  RDY0       	: out   std_logic; 
--			  RDY1       	: out   std_logic; 
--			  WAKEUP     	: in    std_logic );
end SCROD_iTOP_Board_Stack;

architecture Behavioral of SCROD_iTOP_Board_Stack is
   ---------------------------------------------------------
	component IBUF_BUS
	generic(bus_width : integer := 10);
	PORT( 
		I  : in    STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O  : out   STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
	end component;	
	---------------------------------------------------------
	component OBUF_BUS
	generic(bus_width : integer := 10);
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
		SYNC_IN : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
		SYNC_OUT : OUT STD_LOGIC_VECTOR(255 DOWNTO 0));
	end component;
	attribute BOX_TYPE of Chipscope_VIO : component is "BLACK_BOX";	
	--------SIGNAL DEFINITIONS-------------------------------
	signal internal_CLOCK_4NS : std_logic;
	signal internal_COUNTER : std_logic_vector(31 downto 0) := (others => '0');

	signal internal_CHIPSCOPE_CONTROL : std_logic_vector(35 downto 0);
	signal internal_CHIPSCOPE_VIO_IN  : std_logic_vector(255 downto 0);
	signal internal_CHIPSCOPE_VIO_OUT : std_logic_vector(255 downto 0);

	signal desired_ASIC_RD_ADDR	 	 : std_logic_vector(9 downto 0);
	signal measured_ASIC_RD_ADDR      : std_logic_vector(9 downto 0);
	signal desired_ASIC_WR_ADDR	 	 : std_logic_vector(9 downto 0);
	signal measured_ASIC_WR_ADDR      : std_logic_vector(9 downto 0);
   ---------------------------------------------------------	
begin
   ---------------------------------------------------------
	ASIC_RD_ADDR_IBUF : IBUF_BUS
	generic map(bus_width => 10)
	port map(
		I	=> ASIC_RD_ADDR,
      O	=> measured_ASIC_RD_ADDR);
   ---------------------------------------------------------
	ASIC_WR_ADDR_IBUF : IBUF_BUS
	generic map(bus_width => 10)
	port map(
		I	=> ASIC_WR_ADDR,
      O	=> measured_ASIC_WR_ADDR);
   ---------------------------------------------------------
	ASIC_RD_ADDR_OBUF : OBUF_BUS
	generic map(bus_width => 10)
	port map(
		I	=> desired_ASIC_RD_ADDR,
      O	=> ASIC_RD_ADDR);
   ---------------------------------------------------------
	ASIC_WR_ADDR_OBUF : OBUF_BUS
	generic map(bus_width => 10)
	port map(
		I	=> desired_ASIC_WR_ADDR,
      O	=> ASIC_WR_ADDR);
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
			CLK => internal_COUNTER(10),
			SYNC_IN => internal_CHIPSCOPE_VIO_IN,
			SYNC_OUT => internal_CHIPSCOPE_VIO_OUT);	
	---------------------------------------------------------
	desired_ASIC_RD_ADDR <= internal_CHIPSCOPE_VIO_OUT(9 downto 0);
	desired_ASIC_WR_ADDR <= internal_CHIPSCOPE_VIO_OUT(19 downto 10);

	internal_CHIPSCOPE_VIO_IN(9 downto 0)    <= desired_ASIC_RD_ADDR and measured_ASIC_RD_ADDR;
	internal_CHIPSCOPE_VIO_IN(19 downto 10)   <= desired_ASIC_WR_ADDR and measured_ASIC_WR_ADDR;
	internal_CHIPSCOPE_VIO_IN(255 downto 20) <= (others => '0');
	
	process(internal_CLOCK_4NS) begin
		if (rising_edge(internal_CLOCK_4NS)) then
			internal_COUNTER <= std_logic_vector( unsigned(internal_COUNTER) + 1 );
		end if;
	end process;
	
end Behavioral;

