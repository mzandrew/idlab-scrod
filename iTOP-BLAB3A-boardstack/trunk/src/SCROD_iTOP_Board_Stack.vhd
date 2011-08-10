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
    Port ( LEDS : out STD_LOGIC_VECTOR(15 downto 0);
			  MONITOR : out STD_LOGIC_VECTOR(15 downto 0);
			  SCL_DC1 : out STD_LOGIC;
			  SDA_DC1 : inout STD_LOGIC;
           CLOCK_4NS_P : in STD_LOGIC;
			  CLOCK_4NS_N : in STD_LOGIC;
			  ---FTSW I/Os (from RJ45)
			  RJ45_ACK_P			: out std_logic;
			  RJ45_ACK_N			: out std_logic;			  
			  RJ45_TRG_P			: in std_logic;
			  RJ45_TRG_N			: in std_logic;			  			  
			  RJ45_RSV_P			: out std_logic;
			  RJ45_RSV_N			: out std_logic;
			  RJ45_CLK_P			: in std_logic;
			  RJ45_CLK_N			: in std_logic;				  
			  ---ASIC I/Os
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

	--------SIGNAL DEFINITIONS-------------------------------
	signal internal_CLOCK_4NS   : std_logic;
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
	signal internal_ASIC_SSP_IN	    : std_logic;
	signal internal_ASIC_SST_IN	    : std_logic;
	signal internal_ASIC_SSP_OUT		 : std_logic;
	signal internal_SOFT_WRITE_ADDR	 : std_logic_vector(8 downto 0);
	signal internal_SOFT_READ_ADDR 	 : std_logic_vector(8 downto 0);	
	signal internal_ASIC_DATA_TO_USB  : std_logic_vector(15 downto 0);	
	signal internal_ASIC_TRIGGER_BITS : std_logic_vector(7 downto 0);
	signal internal_ASIC_trigger_sign : std_logic;

	signal internal_CAL_ENABLE			 : std_logic;
	
	signal internal_RAM_READ_ADDR     : std_logic_vector(11 downto 0);
	signal internal_USB_START			 : std_logic;
	signal internal_USB_DONE          : std_logic;
	signal internal_USB_SLWR          : std_logic;
	signal internal_USB_CLR_ALL       : std_logic;
	signal internal_SOFT_TRIG			 : std_logic;

	signal internal_COUNTER : std_logic_vector(31 downto 0) := x"00000000";
	signal internal_DCM_LOCKED : std_logic;
	signal internal_CLOCK_SSP : std_logic;
	signal internal_CLOCK_SST : std_logic;	
	signal internal_CLOCK_WRITE_STROBE : std_logic;	
	
	signal internal_FTSW_INTERFACE_READY : std_logic;
	signal internal_CLK127		: std_logic;
	signal internal_CLK21		: std_logic;
	signal internal_TRIGGER127	: std_logic;
	signal internal_TRIGGER21	: std_logic;	
   ---------------------------------------------------------	
begin
	---------------------------------------------------------
	map_FTSW_interface: entity work.bpid
    port map (
      ack_p  => RJ45_ACK_P,
      ack_n  => RJ45_ACK_N,
      trg_p  => RJ45_TRG_P,
      trg_n  => RJ45_TRG_N,
		rsv_p  => RJ45_RSV_P,
		rsv_n  => RJ45_RSV_N,
		clk_p  => RJ45_CLK_P,
		clk_n  => RJ45_CLK_N,
		clk127 => internal_CLK127,
		clk21  => internal_CLK21,
		trg127 => internal_TRIGGER127,
		trg21  => internal_TRIGGER21,
		ready  => internal_FTSW_INTERFACE_READY,
		monitor => open);
--		monitor => internal_MONITOR);
   ---------------------------------------------------------
	IBUFGDS_CLOCK_4NS : IBUFGDS
      port map (O  => internal_CLOCK_4NS,
                I  => CLOCK_4NS_P,
                IB => CLOCK_4NS_N); 
	---------------------------------------------------------
	------SAMPLING CLOCKS GENERATED HERE---------------------
	internal_CLOCK_SST <= internal_CLK21;
	---------
	CLOCK_GEN : entity work.Clock_Generator
	  port map
		(-- Clock in ports
		CLK_IN1            => internal_CLOCK_SST,
		-- Clock out ports
		CLK_OUT1           => internal_CLOCK_SSP,
		CLK_OUT2           => internal_CLOCK_WRITE_STROBE,
		-- Status and control signals
		RESET              => '0',
		LOCKED             => internal_DCM_LOCKED);	
	-------END SAMPLING CLOCK GENERATION--------------------
	---------------------------------------------------------	
	DAC_CONTROL : entity work.iTOP_Board_Stack_DAC_Control
		port map (	INTENDED_DAC_VALUES	=>	internal_INTENDED_DAC_VALUES_DC1,
						CURRENT_DAC_VALUES => internal_CURRENT_DAC_VALUES_DC1,
						IIC_CLK		=> internal_IIC_CLK,
						SCL_DC1     => internal_SCL_DC1,
						SDA_DC1		=> internal_SDA_DC1,
						STATE_MONITOR => internal_DAC_STATE_MONITOR);
	---------------------------------------------------------
	single_ASIC_control : entity work.BLAB3_IRS2_MAIN
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
			ASIC_SSP_IN	      => internal_ASIC_SSP_IN,
			ASIC_SST_IN	      => internal_ASIC_SST_IN,
			ASIC_SSP_OUT		=> internal_ASIC_SSP_OUT,
			ASIC_TRIGGER_BITS => internal_ASIC_TRIGGER_BITS,
			SOFT_WRITE_ADDR   => internal_SOFT_WRITE_ADDR,
			SOFT_READ_ADDR    => internal_SOFT_READ_ADDR,
			-- User I/O
			CLK_SSP 				=> internal_CLOCK_SSP,
			CLK_SST 				=> internal_CLOCK_SST,			
			CLK_WRITE_STROBE 	=> internal_CLOCK_WRITE_STROBE,			
			START_USB_XFER	   => internal_USB_START,
			DONE_USB_XFER 	   => internal_USB_DONE,
			MONITOR		 	   => internal_MONITOR,
--			MONITOR		 	   => open,			
			CLR_ALL		 	   => internal_USB_CLR_ALL,
			TRIGGER			   => internal_SOFT_TRIG,
			RAM_READ_ADDRESS  => internal_RAM_READ_ADDR,
			DATA_TO_USB       => internal_ASIC_DATA_TO_USB);
   ---------------------------------------------------------
	xUSB_MAIN : entity work.USB_MAIN 
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
			CLK => internal_COUNTER(7),
			SYNC_IN => internal_CHIPSCOPE_VIO_IN,
			SYNC_OUT => internal_CHIPSCOPE_VIO_OUT);	
	---------------------------------------------------------
	LEDS <= internal_LEDS;
	MONITOR(15 downto 0) <= internal_MONITOR(15 downto 0);
	internal_LEDS(0) <= internal_DCM_LOCKED;
	internal_LEDS(1) <= internal_FTSW_INTERFACE_READY;
	internal_LEDS(15 downto 2) <= (others => '0');
	--   internal_MONITOR(15 downto 0) <= (others => '0');
	--	internal_IIC_CLK <= internal_COUNTER(11);  --This line is appropriate when we're using 250 MHz base clock
	internal_IIC_CLK <= internal_COUNTER(8);	    --This line is for when we're using 21 MHz base clock

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
--	internal_sample_strobe_width_vector(7 downto 0) <= internal_CHIPSCOPE_VIO_OUT(218 downto 211);
--	internal_autotrigger_enabled <= internal_CHIPSCOPE_VIO_OUT(219);
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
	internal_ASIC_TRIGGER_BITS <= ASIC_TRIGGER;
	ASIC_TDC_START    <= internal_ASIC_TDC_START;
	ASIC_TDC_CLR	   <= internal_ASIC_TDC_CLR;

	ASIC_WR_STRB	   <= internal_ASIC_WR_STRB;
	ASIC_SSP_IN	      <= internal_ASIC_SSP_IN;
	ASIC_SST_IN	      <= internal_ASIC_SST_IN;
	ASIC_WR_ADDR(0)   <= internal_ASIC_WR_ADDR(0);

	ASIC_WR_ADDR(9 downto 1) <= internal_ASIC_WR_ADDR(9 downto 1);
	internal_ASIC_TRIGGER_BITS <= ASIC_TRIGGER;
	ASIC_DC1_DISABLE  <= '0';
	ASIC_trigger_sign <= internal_ASIC_trigger_sign;
	
	ASIC_CARRIER1_CAL_OUT <= (internal_COUNTER(2) and internal_CAL_ENABLE);

--	process(internal_CLOCK_4NS) begin
	process(internal_CLK21) begin
--		if (rising_edge(internal_CLOCK_4NS)) then
		if (rising_edge(internal_CLK21)) then		
			internal_COUNTER <= std_logic_vector( unsigned(internal_COUNTER) + 1 );
		end if;
	end process;
	
end Behavioral;
