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
-- DATE : 03 Jan 2010																			--
-- Project name: Belle2 TOP firmware														--
--	Module name: CLK_MAIN.vhd		  															--
--	Description : 																					--
-- 	CLK distribution/generation block													--
--		  											    												--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CLK_MAIN is
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
end CLK_MAIN;

architecture Behavioral of CLK_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal CLK				: std_logic;
	signal preCLK			: std_logic;
	signal N_CLR_ALL		: std_logic;
	signal preEXT_TRIG	: std_logic;
	signal CLK0				: std_logic;
	signal CLKFB			: std_logic;
	signal CLKDV			: std_logic;
	signal LOCKED			: std_logic;
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component IBUFG
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUFG : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component IBUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component IBUFGDS
      port ( I  : in    std_logic;
				 IB : in    std_logic;		
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUFGDS : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component IBUFDS
      port ( I  : in    std_logic;
				 IB : in    std_logic;		
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUFDS : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUFG
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUFG : component is "BLACK_BOX";
--------------------------------------------------------------------------------	
   component OBUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of OBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------	
   component HK_CLK
	Port( 	
		xCLK_75MHz	: in std_logic;
		xREF_1kHz 	: out std_logic;	
		xREF_100Hz 	: out std_logic;	
		xREF_10Hz 	: out std_logic;					
		xREF_1Hz 	: out std_logic);
   end component;
--------------------------------------------------------------------------------	
	component DCM
	generic(
		CLKDV_DIVIDE            : real       := 2.0;
      CLKFX_DIVIDE            : integer    := 8;
      CLKFX_MULTIPLY          : integer    := 2;
      CLKIN_DIVIDE_BY_2       : boolean    := false;
      CLKIN_PERIOD            : real       := 8.0;--non-simulatable
      CLKOUT_PHASE_SHIFT      : string     := "NONE";
      CLK_FEEDBACK            : string     := "1X";
      DESKEW_ADJUST           : string     := "SYSTEM_SYNCHRONOUS";--non-simulatable
      DFS_FREQUENCY_MODE      : string     := "LOW";
      DLL_FREQUENCY_MODE      : string     := "LOW";
      DSS_MODE                : string     := "NONE";--non-simulatable
      DUTY_CYCLE_CORRECTION   : boolean    := true;
      FACTORY_JF              : bit_vector := X"C080";--non-simulatable
      PHASE_SHIFT             : integer    := 0;
      STARTUP_WAIT            : boolean    := false);--non-simulatable
	port(
		CLK0     : out std_ulogic                   := '0';
      CLK180   : out std_ulogic                   := '0';
      CLK270   : out std_ulogic                   := '0';
      CLK2X    : out std_ulogic                   := '0';
      CLK2X180 : out std_ulogic                   := '0';
      CLK90    : out std_ulogic                   := '0';
      CLKDV    : out std_ulogic                   := '0';
      CLKFX    : out std_ulogic                   := '0';
      CLKFX180 : out std_ulogic                   := '0';
      LOCKED   : out std_ulogic                   := '0';
      PSDONE   : out std_ulogic                   := '0';
      STATUS   : out std_logic_vector(7 downto 0) := "00000000";
      CLKFB    : in std_ulogic                    := '0';
      CLKIN    : in std_ulogic                    := '0';
      DSSEN    : in std_ulogic                    := '0';
      PSCLK    : in std_ulogic                    := '0';
      PSEN     : in std_ulogic                    := '0';
      PSINCDEC : in std_ulogic                    := '0';
      RST      : in std_ulogic                    := '0');
   end component;
   attribute BOX_TYPE of DCM : component is "BLACK_BOX";
--------------------------------------------------------------------------------	
begin
--------------------------------------------------------------------------------			
	xIBUFG_BCLK : IBUFG
	port map (
		I  	=> BCLK,
		O		=> preCLK);				
--------------------------------------------------------------------------------
	xBUFG_BCLK : BUFG
	port map (
		I  	=> preCLK,
		O		=> CLK);			
--------------------------------------------------------------------------------
	xIBUF_EXT_TRIG : IBUF
	port map (
		I  	=> EXT_TRIG,
		O		=> preEXT_TRIG);			
--------------------------------------------------------------------------------	
	xBUF_EXT_TRIG : BUF
	port map (
		I  	=> preEXT_TRIG,
		O		=> xEXT_TRIG);					
--------------------------------------------------------------------------------
	xOBUF_GREEN : OBUF
	port map (
		I  	=> LOCKED,
		O		=> LED_GREEN);				
--------------------------------------------------------------------------------
	xOBUF_RED : OBUF
	port map (
		I  	=> xCLR_ALL,
		O		=> LED_RED);				
--------------------------------------------------------------------------------
	xDCM : DCM
	generic map(
		CLKIN_PERIOD => 6.667,
		CLKIN_DIVIDE_BY_2 => true,
		CLKDV_DIVIDE => 7.5)
	port map(
		CLK0     => CLK0,
      CLK180   => open,
      CLK270   => open,
      CLK2X    => open,
      CLK2X180 => open,
      CLK90    => open,
      CLKDV    => CLKDV,
      CLKFX    => open,
      CLKFX180 => open,
      LOCKED   => LOCKED,
      PSDONE   => open,
      STATUS   => open,
      CLKFB    => CLKFB,
      CLKIN    => CLK,
      DSSEN    => '0',
      PSCLK    => '0',
      PSEN     => '0',
      PSINCDEC => '0',
      RST      => xCLR_ALL);
--------------------------------------------------------------------------------	
	xBUFG_CLKFB : BUFG
	port map (
		I  	=> CLK0,
		O		=> CLKFB);	
--------------------------------------------------------------------------------	
	xBUFG_CLKDV : BUFG
	port map (
		I  	=> CLKDV,
		O		=> xCLK_10MHz);	
--------------------------------------------------------------------------------	
	xHK_CLK : HK_CLK
	port map (
		xCLK_75MHz	=> CLKFB,
		xREF_1kHz  	=> xREF_1kHz,
		xREF_100Hz  => xREF_100Hz,
		xREF_10Hz  	=> xREF_10Hz,
		xREF_1Hz		=> xREF_1Hz);
--------------------------------------------------------------------------------
	N_CLR_ALL <= xCLR_ALL;
	xCLK		 	<= CLK;
	xCLK_75MHz	<= CLKFB;
--------------------------------------------------------------------------------
end Behavioral;