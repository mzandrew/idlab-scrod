--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--								University of Hawaii at Manoa						         --
--						Instrumentation Development Lab / GARY S. VARNER				--
--   								Watanabe Hall Room 214								      --
--  								  2505 Correa Road										   --
--  								 Honolulu, HI 96822											--
--  								Lab: (808) 956-2920											--
--	 								Fax: (808) 956-2930										   --
--  						E-mail: idlab@phys.hawaii.edu									   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------	
-- Design by: Larry L. Ruckman Jr.															--
-- DATE : 16 JUNE 2007																			--
-- Project name: ICRR firmware																--
--	Module name: USBwrite   																	--
--	Description : 																					--
-- 	USB 2.0 writing data to PC module													--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity USB_MAIN is
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
		WRITE_BUSY  : out std_logic;
      xSTART     	: in  std_logic; 
      xDONE      	: out std_logic; 
      xIFCLK     	: out std_logic;--50 MHz CLK
		xADC       	: in  std_logic_vector(15 downto 0); 
		xPRCO_INT 	: in  std_logic_vector(11 downto 0);
		xPROVDD 		: in  std_logic_vector(11 downto 0);
		xRCO_INT 	: in  std_logic_vector(11 downto 0);
		xROVDD 		: in  std_logic_vector(11 downto 0);
		xWBIAS_INT	: in  std_logic_vector(11 downto 0);
		xWBIAS 		: in  std_logic_vector(11 downto 0);			 
		xPED_SCAN	: out std_logic_vector(11 downto 0);
		xPED_ADDR	: out std_logic_vector(14 downto 0);
		xDEBUG     	: out std_logic_vector(15 downto 0); 
      xRADDR     	: out std_logic_vector(11 downto 0); 
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
		SOFT_TIABIAS : out std_logic_vector(11 downto 0);
		MESS_BUSY	: out std_logic);
end USB_MAIN;

architecture BEHAVIORAL of USB_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
   signal xFIFOADR     : std_logic_vector (1 downto 0);
   signal xFLAGA       : std_logic;
   signal xFLAGB       : std_logic;
   signal xFLAGC       : std_logic;
   signal xFPGA_DATA   : std_logic_vector (15 downto 0);
   signal xPKTEND      : std_logic;
   signal xRBUSY       : std_logic;
   signal xSLOE        : std_logic;
   signal xSLRD        : std_logic;
   signal xSYNC_USB    : std_logic;
   signal xTOGGLE      : std_logic;
   signal xUSB_DATA    : std_logic_vector (15 downto 0);
   signal xWBUSY       : std_logic;
   signal SLWR  		  : std_logic;
   signal DONE  		  : std_logic;
	signal WAKE_UP	  	  : std_logic;
   signal USB_CLK		  : std_logic;
	signal RESET 		  : std_logic;
	signal CLR_ALL		  : std_logic;
   signal PED_SCAN     : std_logic_vector (11 downto 0);
   signal PED_ADDR     : std_logic_vector (14 downto 0);
   signal DEBUG    	  : std_logic_vector (15 downto 0);	
	signal xSOFT_RESET  : std_logic;
	signal internal_MESS_BUSY : std_logic;
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
	component MESS
   port( 
		xSLWR       : in  std_logic; 
      xSTART      : in  std_logic; 
      xDONE       : in  std_logic; 
      xCLR_ALL    : in  std_logic; 
      xADC        : in  std_logic_vector(15 downto 0); 
		xPRCO_INT 	: in  std_logic_vector(11 downto 0);
		xPROVDD 		: in  std_logic_vector(11 downto 0);
		xRCO_INT 	: in  std_logic_vector(11 downto 0);
		xROVDD 		: in  std_logic_vector(11 downto 0);
		xWBIAS_INT	: in  std_logic_vector(11 downto 0);
		xWBIAS 		: in  std_logic_vector(11 downto 0);			 
		xPED_SCAN  	: in  std_logic_vector(11 downto 0);
		xPED_ADDR  	: in  std_logic_vector(14 downto 0);
		xDEBUG 	  	: in  std_logic_vector(15 downto 0);
		xFPGA_DATA  : out std_logic_vector(15 downto 0); 
      xRADDR      : out std_logic_vector(11 downto 0);
		MESS_BUSY	: out std_logic);
   end component;
--------------------------------------------------------------------------------
	component USBread
   port ( 
		xIFCLK     		: in  std_logic;
      xDONE    		: in  std_logic;
      xUSB_DATA  		: in  std_logic_vector (15 downto 0);
      xFLAGA    		: in  std_logic;
		xRESET    		: in  std_logic;
      xWBUSY    		: in  std_logic;
      xFIFOADR  		: out std_logic_vector (1 downto 0);
      xRBUSY    		: out std_logic;
      xSLOE     		: out std_logic;
      xSLRD     		: out std_logic;
      xSYNC_USB 		: out std_logic;
      xSOFT_TRIG		: out std_logic;
		xVCAL				: out std_logic;
		xPED_SCAN		: out std_logic_vector (11 downto 0);
		xPED_ADDR		: out std_logic_vector (14 downto 0);
		xDEBUG 		  	: out std_logic_vector (15 downto 0);
      xTOGGLE   		: out std_logic;
		SOFT_VADJN1    : out std_logic_vector (11 downto 0);
		SOFT_VADJN2    : out std_logic_vector (11 downto 0);
		SOFT_VADJP1    : out std_logic_vector (11 downto 0);
		SOFT_VADJP2    : out std_logic_vector (11 downto 0);
		SOFT_RW_ADDR   : out std_logic_vector (8 downto 0);
		SOFT_PROVDD    : out std_logic_vector (11 downto 0);
		SOFT_TIABIAS   : out std_logic_vector (11 downto 0));
   end component;
--------------------------------------------------------------------------------
	component USBwrite
   port( 
		xIFCLK    : in  std_logic; 
      xFLAGB    : in  std_logic; 
      xFLAGC    : in  std_logic; 
      xRBUSY    : in  std_logic; 
      xRESET    : in  std_logic; 
      xSTART    : in  std_logic; 
      xSYNC_USB : in  std_logic; 
      xDONE     : out std_logic; 
      xPKTEND   : out std_logic; 
      xSLWR     : out std_logic; 
      xWBUSY    : out std_logic);
   end component;
--------------------------------------------------------------------------------
	component USB_IO
   port(
		IFCLK     : in  std_logic; 
      xSLOE     : in  std_logic; 
      xFIFOADR0 : in  std_logic; 
      xFIFOADR1 : in  std_logic; 
      xPKTEND   : in  std_logic; 
      xSLWR     : in  std_logic; 
      xSLRD     : in  std_logic; 
      WAKEUP    : in  std_logic; 
      CTL2      : in  std_logic; 
      CTL1      : in  std_logic; 
      CTL0      : in  std_logic; 
      PA7       : in  std_logic; 
      PA3       : in  std_logic; 
      PA1       : in  std_logic; 
      PA0       : in  std_logic; 
      CLKOUT    : in  std_logic; 
      xTOGGLE   : in  std_logic; 
      xDATA_OUT : in  std_logic_vector (15 downto 0); 
      xIFCLK    : out std_logic; 
      PA2       : out std_logic; 
      PA4       : out std_logic; 
      PA5       : out std_logic; 
      PA6       : out std_logic; 
      RDY1      : out std_logic; 
      RDY0      : out std_logic; 
      xFLAGA    : out std_logic; 
      xFLAGB    : out std_logic; 
      xFLAGC    : out std_logic; 
      xWAKEUP   : out std_logic; 
      xUSB_DATA : out std_logic_vector (15 downto 0); 
      FD        : inout std_logic_vector (15 downto 0));
   end component;
--------------------------------------------------------------------------------	
   component PROGRESET
    Port ( 	xCLK     : 	in  std_logic; 		
          	xWAKEUP  : 	in  std_logic; 		
				xSOFT_RESET : in std_logic;
				xCLR_ALL : 	out std_logic; 
           	xRESET   : 	out std_logic); 	
   end component;
--------------------------------------------------------------------------------
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
   xDONE 		<= DONE;
   xSLWR 		<= SLWR;
   xCLR_ALL 	<= CLR_ALL;
   xPED_SCAN	<= PED_SCAN;
	xPED_ADDR	<= PED_ADDR;
   xDEBUG		<= DEBUG;
	xIFCLK 		<= USB_CLK;
	xWAKEUP     <= WAKE_UP;
	WRITE_BUSY  <= xWBUSY;
	MESS_BUSY 	<= internal_MESS_BUSY;
--------------------------------------------------------------------------------
   xMESS : MESS
	port map(
		xADC			=> xADC,
      xCLR_ALL		=> CLR_ALL,
      xDONE			=> DONE,
		xPRCO_INT	=> xPRCO_INT,
		xPROVDD		=> xPROVDD,
		xRCO_INT		=> xRCO_INT,
		xROVDD		=> xROVDD,
		xWBIAS_INT	=> xWBIAS_INT,
		xWBIAS		=> xWBIAS,
      xPED_SCAN	=> PED_SCAN,
		xPED_ADDR	=> PED_ADDR,
      xDEBUG		=> DEBUG,
      xSLWR			=> SLWR,
      xSTART		=> xSTART,
      xFPGA_DATA	=> xFPGA_DATA,
      xRADDR		=> xRADDR,
		MESS_BUSY	=> internal_MESS_BUSY);
--------------------------------------------------------------------------------
   xUSBread : USBread
	port map(
		xFLAGA		=> xFLAGA,
      xDONE			=> DONE,
      xIFCLK		=> USB_CLK,
      xRESET		=> RESET,
      xUSB_DATA	=> xUSB_DATA,
      xWBUSY		=> xWBUSY,
      xDEBUG		=> DEBUG,
      xFIFOADR		=> xFIFOADR,
      xPED_SCAN	=> PED_SCAN,
		xPED_ADDR	=> PED_ADDR,
      xRBUSY		=> xRBUSY,
      xSLOE			=> xSLOE,
      xSLRD			=> xSLRD,
      xSOFT_TRIG	=> xSOFT_TRIG,
		xVCAL       => xVCAL,
      xSYNC_USB	=> xSYNC_USB,
      xTOGGLE		=> xTOGGLE,
		SOFT_VADJN1 => SOFT_VADJN1,
		SOFT_VADJN2 => SOFT_VADJN2,
		SOFT_VADJP1 => SOFT_VADJP1,
		SOFT_VADJP2 => SOFT_VADJP2,
		SOFT_RW_ADDR => SOFT_RW_ADDR,
		SOFT_PROVDD => SOFT_PROVDD,
		SOFT_TIABIAS => SOFT_TIABIAS);
--------------------------------------------------------------------------------
	xUSBwrite : USBwrite
   port map(
		xFLAGB		=> xFLAGB,
      xFLAGC		=> xFLAGC,
      xIFCLK		=> USB_CLK,
      xRBUSY		=> xRBUSY,
      xRESET		=> RESET,
      xSTART		=> xSTART,
      xSYNC_USB	=> xSYNC_USB,
      xDONE			=> DONE,
      xPKTEND		=> xPKTEND,
      xSLWR			=> SLWR,
      xWBUSY		=> xWBUSY);
--------------------------------------------------------------------------------
	xUSB_IO : USB_IO
   port map(
		CLKOUT		=> CLKOUT,
      CTL0			=> CTL0,
      CTL1			=> CTL1,
      CTL2			=> CTL2,
      IFCLK			=> IFCLK,
      PA0			=> PA0,
      PA1			=> PA1,
      PA3			=> PA3,
      PA7			=> PA7,
      WAKEUP		=> WAKEUP,
      xDATA_OUT	=> xFPGA_DATA,
      xFIFOADR0	=> xFIFOADR(0),
      xFIFOADR1	=> xFIFOADR(1),
      xPKTEND		=> xPKTEND,
      xSLOE			=> xSLOE,
      xSLRD			=> xSLRD,
      xSLWR			=> SLWR,
      xTOGGLE		=> xTOGGLE,
      PA2			=> PA2,
      PA4			=> PA4,
      PA5			=> PA5,
      PA6			=> PA6,
      RDY0			=> RDY0,
      RDY1			=> RDY1,
      xFLAGA		=> xFLAGA,
      xFLAGB 		=> xFLAGB,
      xFLAGC		=> xFLAGC,
      xIFCLK		=> USB_CLK,
      xUSB_DATA	=> xUSB_DATA,
      xWAKEUP		=> WAKE_UP,
      FD				=> FD);
--------------------------------------------------------------------------------			
	xPROGRESET : PROGRESET 
	port map (
		xCLK  	=> USB_CLK,
		xWAKEUP 	=> WAKE_UP,
		xSOFT_RESET => xSOFT_RESET,
		xCLR_ALL	=> CLR_ALL,
		xRESET	=> RESET);		
--------------------------------------------------------------------------------	
end BEHAVIORAL;