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
-- DATE : 18 Jan 2010																			--
-- Project name: STURM2eval firmware														--
--	Module name: TOP.vhd		  																	--
--	Description : 																					--
-- 	TOP block																					--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TOP is
	port( 
		-- STURM2 ASIC I/Os
		RAMP	 		 : out std_logic; 
		TST_START 	 : out std_logic; 
		TST_CLR	 	 : out std_logic; 
		TST_OUT		 : in  std_logic;
		SMPL_SEL		 : out std_logic_vector(4 downto 0);
		DAT			 : in  std_logic_vector(11 downto 0);
		CH_SEL		 : out std_logic_vector(3 downto 0);
		TDC_START	 : out std_logic; 
		TDC_STOP		 : out std_logic; 
		TDC_CLR		 : out std_logic; 
		MRCO		 	 : in  std_logic;
		TSA_IN		 : in  std_logic_vector(3 downto 0);
		TSA_OUT		 : out std_logic_vector(3 downto 0);
		CAL_P			 : out std_logic; 
		CAL_N			 : out std_logic; 
		-- USB I/O
      IFCLK      	: in    std_logic;--50 MHz CLK
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
      WAKEUP     	: in    std_logic; 
		-- DAC I/O
      SCLK    	 	: out std_logic;
      SYNC    	  	: out std_logic;
      DIN0    	   : out std_logic;
      DIN1    	   : out std_logic;
      DIN2    	   : out std_logic;
		-- User I/O
      BCLK		 	: in  std_logic;--150 MHz CLK
      EXT_TRIG 	: in  std_logic;
		MON			: out std_logic_vector(15 downto 0);
      LED_GREEN   : out std_logic;
		LED_RED		: out std_logic);
end TOP; 

architecture Behavioral of TOP is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xCLR_ALL		: std_logic;
	signal xCLK				: std_logic;
	signal xCLK_75MHz		: std_logic;
	signal xCLK_10MHz		: std_logic;
	signal xREF_1kHz		: std_logic;
	signal xREF_100Hz		: std_logic;
	signal xREF_10Hz		: std_logic;
	signal xREF_1Hz		: std_logic;
	signal xSTART			: std_logic;
	signal xNRUN			: std_logic;
	signal xDONE			: std_logic;
	signal xADC				: std_logic_vector(11 downto 0); 
	signal xPROVDD			: std_logic_vector(11 downto 0); 
	signal xPRCO_INT		: std_logic_vector(11 downto 0); 
	signal xROVDD			: std_logic_vector(11 downto 0); 
	signal xRCO_INT		: std_logic_vector(11 downto 0); 
	signal xPED_SCAN		: std_logic_vector(11 downto 0); 
	signal xDEBUG			: std_logic_vector(15 downto 0); 
	signal xRADDR			: std_logic_vector(9 downto 0); 
	signal xSLWR			: std_logic;
	signal xSOFT_TRIG		: std_logic;
	signal xEXT_TRIG		: std_logic;
	signal xMON				: std_logic_vector(15 downto 0); 
	signal xMON_HDR		: std_logic_vector(15 downto 0); 
	signal xWAKEUP			: std_logic;
	signal xRAMP			: std_logic;
	signal xRAMP_DONE		: std_logic;
	signal xDAT				: std_logic_vector(11 downto 0);
	signal xVCAL			: std_logic;
	signal xTST_START		: std_logic;
	signal xTST_CLR		: std_logic;
	signal xTST_OUT 		: std_logic;
	signal xMRCO 			: std_logic;
	signal xPED_EN			: std_logic;
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component CLK_MAIN
   port ( 
      BCLK		 	: in  std_logic;--150 MHz CLK
      EXT_TRIG 	: in  std_logic;
		xCLR_ALL		: in std_logic;
		xCLK			: out std_logic;--150 MHz CLK
		xCLK_75MHz	: out std_logic;--75  MHz CLK
		xCLK_10MHz 	: out std_logic;--10  MHz CLK	
		xREF_1kHz 	: out std_logic;	
		xREF_100Hz 	: out std_logic;	
		xREF_10Hz 	: out std_logic;					
		xREF_1Hz 	: out std_logic;
		xEXT_TRIG 	: out std_logic;	
      LED_GREEN   : out std_logic;
		LED_RED		: out std_logic);
    end component;
--------------------------------------------------------------------------------
    component DAC_MAIN
    port (
		xCLK			: in  std_logic;--150 MHz CLK
		xCLK_75MHz	: in  std_logic;--75  MHz CLK
		xCLK_10MHz 	: in  std_logic;--10  MHz CLK	
		xREF_1kHz	: in  std_logic;
		xREF_100Hz	: in  std_logic;
		xREF_10Hz	: in  std_logic;
		xREF_1Hz	 	: in  std_logic;
		xCLR_ALL	 	: in  std_logic;
		xPED_SCAN	: in  std_logic_vector(11 downto 0);
		xDEBUG 		: in  std_logic_vector(15 downto 0);
		xPRCO_INT 	: out std_logic_vector(11 downto 0);
		xPROVDD 		: out std_logic_vector(11 downto 0);
		xRCO_INT 	: out std_logic_vector(11 downto 0);
		xROVDD 		: out std_logic_vector(11 downto 0);
		xTST_START 	: out std_logic; 
		xTST_CLR	 	: out std_logic; 
		xTST_OUT		: in  std_logic;
		xMRCO		 	: in  std_logic;
		SCLK 			: out std_logic;
		SYNC 			: out std_logic;
		DIN0	 		: out std_logic;
		DIN1	 		: out std_logic;
		DIN2	 		: out std_logic);
	end component;
--------------------------------------------------------------------------------
    component STURM2_MAIN
    port (
		-- STURM2 ASIC I/Os
		RAMP	 		 : out std_logic; 
		TST_START 	 : out std_logic; 
		TST_CLR	 	 : out std_logic; 
		TST_OUT		 : in  std_logic;
		SMPL_SEL		 : out std_logic_vector(4 downto 0);
		DAT			 : in  std_logic_vector(11 downto 0);
		CH_SEL		 : out std_logic_vector(3 downto 0);
		TDC_START	 : out std_logic; 
		TDC_STOP		 : out std_logic; 
		TDC_CLR		 : out std_logic; 
		MRCO		 	 : in  std_logic;
		TSA_IN		 : in  std_logic_vector(3 downto 0);
		TSA_OUT		 : out std_logic_vector(3 downto 0);
		CAL_P			 : out std_logic; 
		CAL_N			 : out std_logic; 
		-- User I/O
		xCLK			 : in  std_logic;--150 MHz CLK
		xCLK_75MHz	 : in  std_logic;--75  MHz CLK
		xEXT_TRIG	 : in  std_logic;
		xSOFT_TRIG	 : in  std_logic;
		xSTART 	 	 : out std_logic;
		xRAMP_DONE 	 : out std_logic;
		xDAT		 	 : out std_logic_vector(11 downto 0);
		xDONE		 	 : in  std_logic;
		xPED_EN	 	 : in  std_logic;
		xRAMP	 		 : out std_logic; 
		xADC			 : out std_logic_vector(11 downto 0);
		xRADDR    	 : in  std_logic_vector(9 downto 0);		
		xMON_HDR	 	 : out std_logic_vector(15 downto 0);
		xTST_START 	 : in  std_logic; 
		xTST_CLR	 	 : in  std_logic; 
		xTST_OUT		 : out std_logic;
		xMRCO		 	 : out std_logic;
		xCLR_ALL 	 : in  std_logic);
	end component;
--------------------------------------------------------------------------------
	component USB_MAIN
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
		xPED_SCAN	: out std_logic_vector(11 downto 0);
		xPED_ADDR	: out std_logic_vector(14 downto 0);
		xDEBUG 		: out std_logic_vector (15 downto 0);
      xRADDR     	: out std_logic_vector(9 downto 0); 
		xPED_EN		: out std_logic;
		xSLWR      	: out std_logic; 
      xSOFT_TRIG  : out std_logic;
		xVCAL			: out std_logic;
		xWAKEUP	 	: out std_logic;
		xCLR_ALL   	: out std_logic);
    end component;
--------------------------------------------------------------------------------
   component IBUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component OBUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of OBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component IBUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
   component BUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
   component OBUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------	
	xCLK_MAIN : CLK_MAIN 
	port map (
		BCLK  		=> BCLK,
		EXT_TRIG 	=> EXT_TRIG,
		xCLR_ALL  	=> xCLR_ALL,
		xCLK			=> xCLK,
		xCLK_75MHz	=> xCLK_75MHz,
		xCLK_10MHz 	=> xCLK_10MHz,
		xREF_1kHz  	=> xREF_1kHz,
		xREF_100Hz  => xREF_100Hz,
		xREF_10Hz	=> xREF_10Hz,
		xREF_1Hz		=> xREF_1Hz,
--		xEXT_TRIG	=> open,
		xEXT_TRIG	=> xEXT_TRIG,
		LED_GREEN	=> LED_GREEN,
		LED_RED  	=> LED_RED);
--------------------------------------------------------------------------------	
	xDAC_MAIN : DAC_MAIN 
	port map (
		xCLK			=> xCLK,
		xCLK_75MHz	=> xCLK_75MHz,
		xCLK_10MHz  => xCLK_10MHz,
		xREF_1kHz  	=> xREF_1kHz,
      xREF_100Hz	=> xREF_100Hz,
		xREF_10Hz	=> xREF_10Hz,
		xREF_1Hz  	=> xREF_1Hz,
		xCLR_ALL		=> xCLR_ALL,
		xPED_SCAN  	=> xPED_SCAN,
		xDEBUG  		=> xDEBUG,
		xPRCO_INT	=> xPRCO_INT,
		xPROVDD		=> xPROVDD,
		xRCO_INT		=> xRCO_INT,
		xROVDD		=> xROVDD,
		xTST_START	=> xTST_START,
		xTST_CLR		=> xTST_CLR,
		xTST_OUT		=> xTST_OUT,
		xMRCO			=> xMRCO,
		SCLK			=> SCLK,
		SYNC			=> SYNC,
		DIN0			=> DIN0,
		DIN1			=> DIN1,
		DIN2  		=> DIN2);
--------------------------------------------------------------------------------	
	xSTURM2_MAIN : STURM2_MAIN 
	port map (
		-- STURM2 ASIC I/Os
		RAMP  			=> RAMP,
		TST_START  		=> TST_START,
		TST_CLR  		=> TST_CLR,
		TST_OUT			=> TST_OUT,
		SMPL_SEL  		=> SMPL_SEL,
		DAT  				=> DAT,
		CH_SEL  			=> CH_SEL,
		TDC_START  		=> TDC_START,
		TDC_STOP			=> TDC_STOP,
		TDC_CLR  		=> TDC_CLR,
		MRCO  			=> MRCO,
		TSA_IN  			=> TSA_IN,
		TSA_OUT  		=> TSA_OUT,
		CAL_P  			=> CAL_P,
		CAL_N  			=> CAL_N,
		-- User I/O
		xCLK				=> xCLK,
		xCLK_75MHz		=> xCLK_75MHz,
		xSOFT_TRIG		=> xSOFT_TRIG,
		xEXT_TRIG		=> xEXT_TRIG,
		xSTART  			=> xSTART,
		xRAMP_DONE		=> xRAMP_DONE,
		xDAT				=> xDAT,
		xDONE  			=> xDONE,
		xPED_EN			=> xPED_EN,
		xRAMP  			=> xRAMP,
		xADC  			=> xADC,
		xRADDR  			=> xRADDR,
		xMON_HDR			=> xMON_HDR,
		xTST_START		=> xTST_START,
		xTST_CLR			=> xTST_CLR,
		xTST_OUT			=> xTST_OUT,
		xMRCO				=> xMRCO,
		xCLR_ALL  		=> xCLR_ALL);
--------------------------------------------------------------------------------	
	xOBUF_MON : OBUF_BUS
	generic map(bus_width => 16)
	port map (
		I => xMON,
		O => MON);
	xMON(0)  <= xVCAL;--xVCAL
	xMON(1)  <= xVCAL;--xVCAL
	xMON(2)  <= xMON_HDR(2);--xMON_HDR(2)
	xMON(3)  <= xMON_HDR(3);--xMON_HDR(3)
	xMON(4)  <= xMON_HDR(4);--xMON_HDR(4)
	xMON(5)  <= xMON_HDR(5);--xMON_HDR(5)
	xMON(6)  <= xMON_HDR(6);--xMON_HDR(6)
	xMON(7)  <= xMON_HDR(7);--xMON_HDR(7)
	xMON(8)  <= xMON_HDR(8);
	xMON(9)  <= xMON_HDR(9);
	xMON(10) <= xMON_HDR(10);
	xMON(11) <= xMON_HDR(11);
	xMON(12) <= xMON_HDR(12);
	xMON(13) <= xMON_HDR(13);
	xMON(14) <= xMON_HDR(14);
	xMON(15) <= xMON_HDR(15);	
--------------------------------------------------------------------------------	
	xNRUN <= xSOFT_TRIG;
--------------------------------------------------------------------------------	
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
		xSTART  		=> xSTART,
		xDONE  		=> xDONE,
		xIFCLK  		=> open,
		xADC  		=> xADC,
		xPRCO_INT	=> xPRCO_INT,
		xPROVDD		=> xPROVDD,
		xRCO_INT		=> xRCO_INT,
		xROVDD		=> xROVDD,
      xPED_SCAN	=> xPED_SCAN,
		xDEBUG  		=> xDEBUG,
		xRADDR  		=> xRADDR,
		xSLWR  		=> xSLWR,
		xSOFT_TRIG	=> xSOFT_TRIG,
		xVCAL			=> xVCAL,
		xPED_EN		=> xPED_EN,
		xWAKEUP  	=> xWAKEUP,
		xCLR_ALL  	=> xCLR_ALL);		
--------------------------------------------------------------------------------	
end Behavioral;