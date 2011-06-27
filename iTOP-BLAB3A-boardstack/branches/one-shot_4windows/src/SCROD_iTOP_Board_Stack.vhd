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
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity SCROD_iTOP_Board_Stack is
    Port ( LEDS : out STD_LOGIC_VECTOR(15 downto 0);
			  MONITOR : out STD_LOGIC_VECTOR(15 downto 0);
			  SCL_DC1 : out STD_LOGIC;
			  SDA_DC1 : inout STD_LOGIC;
           CLOCK_4NS_P : in STD_LOGIC;
			  CLOCK_4NS_N : in STD_LOGIC;
			  ---BLAB3A I/Os
			  ASIC_CH_SEL	 	  : out std_logic_vector(2 downto 0);
			  ASIC_RD_ADDR	 	  : out std_logic_vector(9 downto 0);
			  ASIC_SMPL_SEL 	  : out std_logic_vector(5 downto 0);
			  ASIC_SMPL_SEL_ALL : out std_logic;
			  ASIC_RD_ENA	 	  : out std_logic;
			  ASIC_RAMP	 	 	  : out std_logic;
			  ASIC_DAT		     : in std_logic_vector(11 downto 0);
			  ASIC_TDC_START    : out std_logic;
			  ASIC_TDC_CLR	     : out std_logic;
			  ASIC_WR_STRB	     : out std_logic;
			  ASIC_WR_ADDR	     : out std_logic_vector(9 downto 0);
			  ASIC_SSP_IN	     : out std_logic;
			  ASIC_SST_IN	     : out std_logic;
			  ASIC_SSP_OUT		  : in  std_logic;
			  ASIC_TRIGGER		  : in std_logic_vector(7 downto 0);
			  ASIC_DC1_DISABLE  : out std_logic;
			  ASIC_trigger_sign : out std_logic;
			  -- Pulse output
			  ASIC_CARRIER1_CAL_OUT : out std_logic;			  
			  -- USB I/O
			  IFCLK      	: in    std_logic; --50 MHz CLK
			  CLKOUT     	: in    std_logic; 
			  FD         	: inout std_logic_vector(15 downto 0);
			  PA0        	: in    std_logic; 
			  PA1        	: in    std_logic; 
			  PA2        	: out   std_logic; 
			  PA3        	: in    std_logic; 
			  PA4        	: out   std_logic; 
			  PA5        	: out   std_logic; 
			  PA6        	: out   std_logic; 
			  PA7        	: in    std_logic; 
			  CTL0       	: in    std_logic; 
			  CTL1       	: in    std_logic; 
			  CTL2       	: in    std_logic; 
			  RDY0       	: out   std_logic; 
			  RDY1       	: out   std_logic; 
			  WAKEUP     	: in    std_logic );
end SCROD_iTOP_Board_Stack;

architecture Behavioral of SCROD_iTOP_Board_Stack is
	attribute BOX_TYPE 	: string;
	---------------------------------------------------------
	component IBUFGDS
		port (O  : out STD_ULOGIC;
				I  : in STD_ULOGIC;
				IB : in STD_ULOGIC);
	end component; 
	attribute BOX_TYPE of IBUFGDS : component is "BLACK_BOX";
   ---------------------------------------------------------
	component iTOP_Board_Stack_DAC_Control is
		Port ( INTENDED_DAC_VALUES : in Daughter_Card_Voltages;
				 CURRENT_DAC_VALUES  : out Daughter_Card_Voltages; 
				 IIC_CLK        : in  std_logic;
				 SCL_DC1 		 : out std_logic;
				 SDA_DC1		    : inout std_logic;
				 STATE_MONITOR  : out std_logic_vector(2 downto 0)
			  );
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
	---------------------------------------------------------
	component BLAB3_IRS2_MAIN is
   port (
		-- IRS ASIC I/Os
		ASIC_CH_SEL	 	  : out std_logic_vector(2 downto 0);
		ASIC_RD_ADDR	 	  : out std_logic_vector(9 downto 0);
		ASIC_SMPL_SEL 	  : out std_logic_vector(5 downto 0);
		ASIC_SMPL_SEL_ALL : out std_logic; 
		ASIC_RD_ENA	 	  : out std_logic; 
		ASIC_RAMP	 	 	  : out std_logic; 
		ASIC_DAT		     : in  std_logic_vector(11 downto 0);
		ASIC_TDC_START    : out std_logic; 
		ASIC_TDC_CLR	     : out std_logic; 
		ASIC_WR_STRB	     : out std_logic; 
		ASIC_WR_ADDR	     : out std_logic_vector(9 downto 0);
		sample_strobe_width_vector : in std_logic_vector(7 downto 0);
		autotrigger_enabled : in std_logic;
		ASIC_SSP_IN	     : out std_logic;
		ASIC_SST_IN	     : out std_logic;
		ASIC_SSP_OUT	  : in std_logic;
		ASIC_TRIGGER     : in std_logic_vector(7 downto 0);
		SOFT_WRITE_ADDR     : in std_logic_vector(8 downto 0);
		SOFT_READ_ADDR     : in std_logic_vector(8 downto 0);
--		ASIC_trigger_sign : out std_logic;
		-- User I/O
		CLK			     : in  std_logic;--150 MHz CLK
		CLK_75MHz		  : in  std_logic;   --75  MHz CLK
		notCLK_75MHz		  : in  std_logic;--75  MHz CLK		
		START_USB_XFER	  : out std_logic;--Signal to start sending data to USB
		DONE_USB_XFER 	  : in  std_logic;
		MON_HDR		 	  : out std_logic_vector(15 downto 0); 
		CLR_ALL		 	  : in  std_logic;
		TRIGGER			  : in  std_logic;
		RAM_READ_ADDRESS : in std_logic_vector(9 downto 0);
		DATA_TO_USB      : out std_logic_vector(15 downto 0));
	end component;
	---------------------------------------------------------
	component USB_MAIN is
   port( 
		-- USB I/O
      IFCLK      	: in  std_logic;--50 MHz CLK
		CLKOUT     	: in  std_logic; 
      FD         	: inout std_logic_vector(15 downto 0);
      PA0        	: in  std_logic; 
      PA1        	: in  std_logic; 
      PA2        	: out std_logic; 
      PA3        	: in  std_logic; 
      PA4        	: out std_logic; 
      PA5        	: out std_logic; 
      PA6        	: out std_logic; 
      PA7        	: in  std_logic; 
      CTL0       	: in  std_logic; 
      CTL1       	: in  std_logic; 
      CTL2       	: in  std_logic; 
      RDY0       	: out std_logic; 
      RDY1       	: out std_logic; 
      WAKEUP     	: in  std_logic; 
		-- USER I/O
      xSTART     	: in  std_logic; 
      xDONE      	: out std_logic; 
      xIFCLK     	: out std_logic;--50 MHz CLK
		xADC       	: in  std_logic_vector(11 downto 0); 
		xPRCO_INT 	: in  std_logic_vector(11 downto 0);
		xPROVDD 		: in  std_logic_vector(11 downto 0);
		xRCO_INT 	: in  std_logic_vector(11 downto 0);
		xROVDD 		: in  std_logic_vector(11 downto 0);
		xWBIAS_INT	: in  std_logic_vector(11 downto 0);
		xWBIAS 		: in  std_logic_vector(11 downto 0);			 
		xPED_SCAN	: out std_logic_vector(11 downto 0);
		xPED_ADDR	: out std_logic_vector(14 downto 0);
		xDEBUG     	: out std_logic_vector(15 downto 0); 
      xRADDR     	: out std_logic_vector(9 downto 0); 
		xSLWR      	: out std_logic; 
      xSOFT_TRIG  : out std_logic;
		xVCAL			: out std_logic;
		xWAKEUP	 	: out std_logic;
		xCLR_ALL   	: out std_logic;
		SOFT_VADJN1 : out std_logic_vector(11 downto 0);
		SOFT_VADJN2 : out std_logic_vector(11 downto 0);
		SOFT_VADJP1 : out std_logic_vector(11 downto 0);
		SOFT_VADJP2 : out std_logic_vector(11 downto 0);
		SOFT_RW_ADDR : out std_logic_vector(8 downto 0);
		SOFT_PROVDD : out std_logic_vector(11 downto 0);
		SOFT_TIABIAS : out std_logic_vector(11 downto 0));
	end component;	
	---------------------------------------------------------
	component DCM_Core_A
	port
		(-- Clock in ports
			CLK_IN1           : in     std_logic;
		 -- Clock out ports
			CLK_OUT1          : out    std_logic;
			CLK_OUT2          : out    std_logic;
			CLK_OUT3          : out    std_logic;
		 -- Status and control signals
			RESET             : in     std_logic;
			LOCKED            : out    std_logic);
	end component;
	--------SIGNAL DEFINITIONS-------------------------------
	signal internal_CLOCK_4NS   : std_logic := '0';
	signal internal_LEDS        : std_logic_vector(15 downto 0);
	signal internal_MONITOR     : std_logic_vector(15 downto 0);
	signal internal_SCL_DC1     : std_logic;
	signal internal_SDA_DC1     : std_logic;
	signal internal_INTENDED_DAC_VALUES_DC1 : Daughter_Card_Voltages;
	signal internal_CURRENT_DAC_VALUES_DC1 : Daughter_Card_Voltages;	
	signal internal_IIC_CLK		 : std_logic;

	signal internal_DAC_STATE_MONITOR : std_logic_vector(2 downto 0);

	signal internal_CHIPSCOPE_CONTROL : std_logic_vector(35 downto 0);
	signal internal_CHIPSCOPE_VIO_IN  : std_logic_vector(255 downto 0);
	signal internal_CHIPSCOPE_VIO_OUT : std_logic_vector(255 downto 0);

		-- IRS ASIC I/Os
	signal internal_ASIC_CH_SEL	 	 : std_logic_vector(2 downto 0);
	signal internal_ASIC_RD_ADDR	 	 : std_logic_vector(9 downto 0);
	signal internal_ASIC_SMPL_SEL 	 : std_logic_vector(5 downto 0);
	signal internal_ASIC_SMPL_SEL_ALL : std_logic;
	signal internal_ASIC_RD_ENA	 	 : std_logic;
	signal internal_ASIC_RAMP	 	 	 : std_logic;
	signal internal_ASIC_DAT		    : std_logic_vector(11 downto 0);
	signal internal_ASIC_TDC_START    : std_logic;
	signal internal_ASIC_TDC_CLR	    : std_logic;
	signal internal_ASIC_WR_STRB	    : std_logic;
	signal internal_ASIC_WR_ADDR	    : std_logic_vector(9 downto 0);
	signal internal_sample_strobe_width_vector : std_logic_vector(7 downto 0) := x"08";
	signal internal_autotrigger_enabled : std_logic := '0';
	signal internal_ASIC_SSP_IN	    : std_logic;
	signal internal_ASIC_SST_IN	    : std_logic;
	signal internal_ASIC_SSP_OUT		 : std_logic;
	signal internal_SOFT_WRITE_ADDR	 : std_logic_vector(8 downto 0);
	signal internal_SOFT_READ_ADDR 	 : std_logic_vector(8 downto 0);	
	signal internal_ASIC_DATA_TO_USB  : std_logic_vector(15 downto 0);	
	signal internal_ASIC_TRIGGER      : std_logic_vector(7 downto 0);
	signal internal_ASIC_trigger_sign : std_logic;

	signal internal_CAL_ENABLE			 : std_logic;
	
	signal internal_RAM_READ_ADDR     : std_logic_vector(9 downto 0);
	signal internal_USB_START			 : std_logic;
	signal internal_USB_DONE          : std_logic;
	signal internal_USB_SLWR          : std_logic;
	signal internal_USB_CLR_ALL       : std_logic;
	signal internal_SOFT_TRIG			 : std_logic;

	signal internal_COUNTER : std_logic_vector(31 downto 0) := x"00000000";
	signal internal_CLOCK_150MHz : std_logic;
	signal internal_CLOCK_75MHz : std_logic;	
	signal internal_CLOCK_75MHz_180deg : std_logic;	
	signal internal_DCM_LOCKED : std_logic;
   ---------------------------------------------------------	
begin
   ---------------------------------------------------------
	IBUFGDS_CLOCK_4NS : IBUFGDS
      port map (O  => internal_CLOCK_4NS,
                I  => CLOCK_4NS_P,
                IB => CLOCK_4NS_N); 
	---------------------------------------------------------
	DCM_150_and_75_from_250: DCM_Core_A
	port map
		(-- Clock in ports
		 CLK_IN1            => internal_CLOCK_4NS,
		 -- Clock out ports
		 CLK_OUT1           => internal_CLOCK_150MHz,
		 CLK_OUT2           => internal_CLOCK_75MHz,
		 CLK_OUT3           => internal_CLOCK_75MHz_180deg,
		 -- Status and control signals
		 RESET              => '0',
		 LOCKED             => internal_DCM_LOCKED);
	---------------------------------------------------------
	DAC_CONTROL : iTOP_Board_Stack_DAC_Control
		port map (	INTENDED_DAC_VALUES	=>	internal_INTENDED_DAC_VALUES_DC1,
						CURRENT_DAC_VALUES => internal_CURRENT_DAC_VALUES_DC1,
						IIC_CLK		=> internal_IIC_CLK,
						SCL_DC1     => internal_SCL_DC1,
						SDA_DC1		=> internal_SDA_DC1,
						STATE_MONITOR => internal_DAC_STATE_MONITOR);
	---------------------------------------------------------
	single_ASIC_control : BLAB3_IRS2_MAIN
		port map (	
			-- IRS ASIC I/Os
			ASIC_CH_SEL	 	   => internal_ASIC_CH_SEL,
			ASIC_RD_ADDR	   => internal_ASIC_RD_ADDR,
			ASIC_SMPL_SEL 	   => internal_ASIC_SMPL_SEL,
			ASIC_SMPL_SEL_ALL => internal_ASIC_SMPL_SEL_ALL,
			ASIC_RD_ENA	 	   => internal_ASIC_RD_ENA,
			ASIC_RAMP	 	 	=> internal_ASIC_RAMP,
			ASIC_DAT		      => internal_ASIC_DAT,
			ASIC_TDC_START    => internal_ASIC_TDC_START,
			ASIC_TDC_CLR	   => internal_ASIC_TDC_CLR,
			ASIC_WR_STRB	   => internal_ASIC_WR_STRB,
			ASIC_WR_ADDR	   => internal_ASIC_WR_ADDR,
			sample_strobe_width_vector => internal_sample_strobe_width_vector,
			autotrigger_enabled => internal_autotrigger_enabled,
--			ASIC_trigger_sign => internal_ASIC_trigger_sign,
			ASIC_SSP_IN	      => internal_ASIC_SSP_IN,
			ASIC_SST_IN	      => internal_ASIC_SST_IN,
			ASIC_SSP_OUT		=> internal_ASIC_SSP_OUT,
			ASIC_TRIGGER		=> internal_ASIC_TRIGGER,
			SOFT_WRITE_ADDR   => internal_SOFT_WRITE_ADDR,
			SOFT_READ_ADDR    => internal_SOFT_READ_ADDR,
			-- User I/O
			CLK			     => internal_CLOCK_150MHz,
			CLK_75MHz		  => internal_CLOCK_75MHz,
			notCLK_75MHz	  => internal_CLOCK_75MHz_180deg,
			START_USB_XFER	  => internal_USB_START,
			DONE_USB_XFER 	  => internal_USB_DONE,
			MON_HDR		 	  => internal_MONITOR,
			CLR_ALL		 	  => internal_USB_CLR_ALL,
			TRIGGER			  => internal_SOFT_TRIG,
			RAM_READ_ADDRESS => internal_RAM_READ_ADDR,
			DATA_TO_USB      => internal_ASIC_DATA_TO_USB);
   ---------------------------------------------------------
	xUSB_MAIN : USB_MAIN 
	port map (
		-- USB I/O
		IFCLK  	=> IFCLK,
		CLKOUT  	=> CLKOUT,
		FD		  	=> FD,
		PA0	  	=> PA0,
		PA1	  	=> PA1,
		PA2	  	=> PA2,
		PA3	  	=> PA3,
		PA4	  	=> PA4,
		PA5	  	=> PA5,
		PA6	  	=> PA6,
		PA7	  	=> PA7,
		CTL0  	=> CTL0,
		CTL1  	=> CTL1,
		CTL2  	=> CTL2,
		RDY0  	=> RDY0,
		RDY1  	=> RDY1,
		WAKEUP  	=> WAKEUP,
		-- USER I/O
		xSTART  		=> internal_USB_START,
		xDONE  		=> internal_USB_DONE,
		xIFCLK  		=> open,
		xADC  		=> internal_ASIC_DATA_TO_USB(11 downto 0),
		xPRCO_INT	=> x"D0A",
		xPROVDD		=> x"D0A",
		xRCO_INT		=> x"D0A",
		xROVDD		=> x"D0A",
		xWBIAS_INT	=> x"D0A",
		xWBIAS		=> x"D0A",
      xPED_SCAN	=> open,
		xPED_ADDR	=> open,
		xDEBUG  		=> open,
		xRADDR  		=> internal_RAM_READ_ADDR,
		xSLWR  		=> internal_USB_SLWR,
		xSOFT_TRIG	=> internal_SOFT_TRIG,
		xVCAL			=> open,
		xWAKEUP  	=> open,
		xCLR_ALL  	=> internal_USB_CLR_ALL,
		SOFT_VADJN1 => open,
		SOFT_VADJN2 => open,
		SOFT_VADJP1 => open,
		SOFT_VADJP2 => open,
		SOFT_RW_ADDR => open,
		SOFT_PROVDD  => open,
		SOFT_TIABIAS => open);		
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
	LEDS <= internal_LEDS;
	MONITOR <= internal_MONITOR;
	internal_LEDS(0) <= internal_DCM_LOCKED;
	internal_LEDS(15 downto 1) <= (others => '0');
	--   internal_MONITOR(15 downto 0) <= (others => '0');
	internal_IIC_CLK <= internal_COUNTER(11);

	internal_INTENDED_DAC_VALUES_DC1(0)(0) <= internal_CHIPSCOPE_VIO_OUT(11 downto 0);
	internal_INTENDED_DAC_VALUES_DC1(0)(1) <= internal_CHIPSCOPE_VIO_OUT(23 downto 12);
	internal_INTENDED_DAC_VALUES_DC1(0)(2) <= internal_CHIPSCOPE_VIO_OUT(35 downto 24);
	internal_INTENDED_DAC_VALUES_DC1(0)(3) <= internal_CHIPSCOPE_VIO_OUT(47 downto 36);
	internal_INTENDED_DAC_VALUES_DC1(0)(4) <= internal_CHIPSCOPE_VIO_OUT(59 downto 48);
	internal_INTENDED_DAC_VALUES_DC1(0)(5) <= internal_CHIPSCOPE_VIO_OUT(71 downto 60);
	internal_INTENDED_DAC_VALUES_DC1(0)(6) <= internal_CHIPSCOPE_VIO_OUT(83 downto 72);
	internal_INTENDED_DAC_VALUES_DC1(0)(7) <= internal_CHIPSCOPE_VIO_OUT(95 downto 84);
	internal_INTENDED_DAC_VALUES_DC1(1)(0) <= internal_CHIPSCOPE_VIO_OUT(107 downto 96);
	internal_INTENDED_DAC_VALUES_DC1(1)(1) <= internal_CHIPSCOPE_VIO_OUT(119 downto 108);	
	internal_INTENDED_DAC_VALUES_DC1(1)(2) <= internal_CHIPSCOPE_VIO_OUT(131 downto 120);
	internal_INTENDED_DAC_VALUES_DC1(1)(3) <= internal_CHIPSCOPE_VIO_OUT(143 downto 132);	
	internal_INTENDED_DAC_VALUES_DC1(1)(4) <= internal_CHIPSCOPE_VIO_OUT(155 downto 144);
	internal_INTENDED_DAC_VALUES_DC1(1)(5) <= internal_CHIPSCOPE_VIO_OUT(167 downto 156);
	internal_INTENDED_DAC_VALUES_DC1(1)(6) <= internal_CHIPSCOPE_VIO_OUT(179 downto 168);
	internal_INTENDED_DAC_VALUES_DC1(1)(7) <= internal_CHIPSCOPE_VIO_OUT(191 downto 180);
	internal_SOFT_WRITE_ADDR(8 downto 0) <= internal_CHIPSCOPE_VIO_OUT(200 downto 192);
	internal_SOFT_READ_ADDR(8 downto 0) <= internal_CHIPSCOPE_VIO_OUT(209 downto 201);
	internal_CAL_ENABLE <= internal_CHIPSCOPE_VIO_OUT(210);
	internal_sample_strobe_width_vector(7 downto 0) <= internal_CHIPSCOPE_VIO_OUT(218 downto 211);
	internal_autotrigger_enabled <= internal_CHIPSCOPE_VIO_OUT(219);
	internal_ASIC_trigger_sign <= internal_CHIPSCOPE_VIO_OUT(220);

	internal_CHIPSCOPE_VIO_IN(11 downto 0)    <= internal_CURRENT_DAC_VALUES_DC1(0)(0);
	internal_CHIPSCOPE_VIO_IN(23 downto 12)   <= internal_CURRENT_DAC_VALUES_DC1(0)(1);
	internal_CHIPSCOPE_VIO_IN(35 downto 24)   <= internal_CURRENT_DAC_VALUES_DC1(0)(2);
	internal_CHIPSCOPE_VIO_IN(47 downto 36)   <= internal_CURRENT_DAC_VALUES_DC1(0)(3);
	internal_CHIPSCOPE_VIO_IN(59 downto 48)   <= internal_CURRENT_DAC_VALUES_DC1(0)(4);
	internal_CHIPSCOPE_VIO_IN(71 downto 60)   <= internal_CURRENT_DAC_VALUES_DC1(0)(5);
	internal_CHIPSCOPE_VIO_IN(83 downto 72)   <= internal_CURRENT_DAC_VALUES_DC1(0)(6);
	internal_CHIPSCOPE_VIO_IN(95 downto 84)   <= internal_CURRENT_DAC_VALUES_DC1(0)(7);
	internal_CHIPSCOPE_VIO_IN(107 downto 96)  <= internal_CURRENT_DAC_VALUES_DC1(1)(0);
	internal_CHIPSCOPE_VIO_IN(119 downto 108)	<= internal_CURRENT_DAC_VALUES_DC1(1)(1);
	internal_CHIPSCOPE_VIO_IN(131 downto 120) <= internal_CURRENT_DAC_VALUES_DC1(1)(2);
	internal_CHIPSCOPE_VIO_IN(143 downto 132) <= internal_CURRENT_DAC_VALUES_DC1(1)(3);
	internal_CHIPSCOPE_VIO_IN(155 downto 144) <= internal_CURRENT_DAC_VALUES_DC1(1)(4);
	internal_CHIPSCOPE_VIO_IN(167 downto 156) <= internal_CURRENT_DAC_VALUES_DC1(1)(5);
	internal_CHIPSCOPE_VIO_IN(179 downto 168) <= internal_CURRENT_DAC_VALUES_DC1(1)(6);
	internal_CHIPSCOPE_VIO_IN(191 downto 180) <= internal_CURRENT_DAC_VALUES_DC1(1)(7);
	internal_CHIPSCOPE_VIO_IN(251 downto 192) <= (others => '0');
	internal_CHIPSCOPE_VIO_IN(254 downto 252) <= internal_DAC_STATE_MONITOR;
	internal_CHIPSCOPE_VIO_IN(255) <= (internal_COUNTER(2) and internal_CAL_ENABLE);
	
	SCL_DC1 <= internal_SCL_DC1;
	SDA_DC1 <= internal_SDA_DC1;

	ASIC_CH_SEL	 	   <= internal_ASIC_CH_SEL;
	ASIC_RD_ADDR	 	<= internal_ASIC_RD_ADDR;
	ASIC_SMPL_SEL 	   <= internal_ASIC_SMPL_SEL;
	ASIC_SMPL_SEL_ALL <= internal_ASIC_SMPL_SEL_ALL;
	ASIC_RD_ENA	 	   <= internal_ASIC_RD_ENA;
	ASIC_RAMP	 	 	<= internal_ASIC_RAMP;
	internal_ASIC_DAT <= ASIC_DAT;
	internal_ASIC_SSP_OUT <= ASIC_SSP_OUT;
	ASIC_TDC_START    <= internal_ASIC_TDC_START;
	ASIC_TDC_CLR	   <= internal_ASIC_TDC_CLR;
	ASIC_WR_STRB	   <= internal_ASIC_WR_STRB;
	ASIC_WR_ADDR	   <= internal_ASIC_WR_ADDR;
	ASIC_SSP_IN	      <= internal_ASIC_SSP_IN;
	ASIC_SST_IN	      <= internal_ASIC_SST_IN;
	internal_ASIC_TRIGGER <= ASIC_TRIGGER;
	ASIC_DC1_DISABLE  <= '0';
	ASIC_trigger_sign <= internal_ASIC_trigger_sign;
	
	ASIC_CARRIER1_CAL_OUT <= (internal_COUNTER(2) and internal_CAL_ENABLE);

	process(internal_CLOCK_4NS) begin
		if (rising_edge(internal_CLOCK_4NS)) then
			internal_COUNTER <= std_logic_vector( unsigned(internal_COUNTER) + 1 );
		end if;
	end process;
	
end Behavioral;

