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
-- DATE : 29 JUNE 2007																			--
-- Project name: ROBUSTv3 firmware															--
--	Module name: TRIG_DAC		  																--
--	Description : 																					--
-- 	Top Level for Trigger Dac Control													--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RCO_MAIN is
   port ( 
		xREFRESH_CLK : in  std_logic;
		xCLK			: in  std_logic;--150 MHz CLK
		xCLK_INV		: in  std_logic;--MCF
		xCLK_75MHz	: in  std_logic;--75  MHz CLK
		xCLK_10MHz 	: in  std_logic;--10  MHz CLK	
		xREF_1kHz	: in  std_logic;
		xREF_100Hz	: in  std_logic;
		xREF_10Hz	: in  std_logic;
		xREF_1Hz	 	: in  std_logic;
		xCLR_ALL	 	: in  std_logic;
		xDEBUG 		: in  std_logic_vector(15 downto 0);
	   xPRCO_INT 	: out std_logic_vector(11 downto 0);
	   xPROVDD 		: out std_logic_vector(11 downto 0);
	   xRCO_INT 	: out std_logic_vector(11 downto 0);
	   xROVDD 		: out std_logic_vector(11 downto 0);
		xTST_START 	: out std_logic; 
		xTST_CLR	 	: out std_logic; 
		xTST_OUT		: in  std_logic;
		xMRCO		 	: in  std_logic);
end RCO_MAIN;

architecture Behavioral of RCO_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
--	signal nCLR_ALL   : std_logic;	--MCF; TST_START should be connected to xCLR_ALL
--------------------------------------------------------------------------------
--   								components     		   						         --
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
	component INITIALIZE_MON
	port (
		xCLR_ALL : in  STD_LOGIC;
		xCLK_10MHz : in  STD_LOGIC;
		TST_CLR : out  STD_LOGIC;
		TST_START : out  STD_LOGIC);
	end component;
--------------------------------------------------------------------------------
   component CTRL_LOOP_PRCO
   port ( 
		xCLK				: in  std_logic;--150 MHz CLK
		xCLK_INV			: in  std_logic;--MCF
		xCLK_10MHz		: in  std_logic;--10  MHz CLK
		xCLR_ALL			: in  std_logic;
		xREFRESH_CLK	: in  std_logic;
		xTST_OUT			: in  std_logic;--Nominally 125 kHz
		xPRCO_INT		: out std_logic_vector(11 downto 0);
		xPROVDD			: out std_logic_vector(11 downto 0));	
   end component;
--------------------------------------------------------------------------------
   component CTRL_LOOP_RCO
	port ( 
		xCLK				: in  std_logic;--150 MHz CLK
		xCLK_INV			: in  std_logic;--MCF
		xCLK_10MHz		: in  std_logic;--10  MHz CLK
		xMRCO 			: in  std_logic;
		xCLR_ALL			: in  std_logic;
		xREFRESH_CLK	: in  std_logic;
		xROVDD_INT		: out std_logic_vector(11 downto 0);
		xROVDD			: out std_logic_vector(11 downto 0));	
   end component;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	xCTRL_LOOP_RCO : CTRL_LOOP_RCO 
	port map (
		xCLK 		 	=> xCLK,
		xCLK_INV		=> xCLK_INV,
		xCLK_10MHz 	=> xCLK_10MHz,
		xMRCO			=> xMRCO,
		xCLR_ALL    => xCLR_ALL,
		xREFRESH_CLK => xREFRESH_CLK,
		xROVDD_INT	=> xRCO_INT,
		xROVDD 		=> xROVDD);	
--------------------------------------------------------------------------------
	xCTRL_LOOP_PRCO : CTRL_LOOP_PRCO 
	port map (
		xCLK 		 	=> xCLK,
		xCLK_INV		=> xCLK_INV,	--MCF
		xCLK_10MHz 	=> xCLK_10MHz,
		xREFRESH_CLK  => xREFRESH_CLK,
		xCLR_ALL    => xCLR_ALL,
		xTST_OUT  	=> xTST_OUT,
		xPRCO_INT	=> xPRCO_INT,
		xPROVDD 		=> xPROVDD);
--------------------------------------------------------------------------------
	xINITIALIZE_MON : INITIALIZE_MON
	port map (
		xCLR_ALL => xCLR_ALL,
		xCLK_10MHz => xCLK_10MHz,
		TST_CLR => xTST_CLR,
		TST_START => xTST_START);
--------------------------------------------------------------------------------
--	xOBUF_TST_CLR : BUF	--MCF; replacing with INITIALIZE_MON
--	port map (
--		I  => '0',
--		O  => xTST_CLR);		
--------------------------------------------------------------------------------
--	xOBUF_TST_START : BUF	--MCF; replacing with INITIALIZE_MON
--	port map (
--		I  => nCLR_ALL,
--		O  => xTST_START);		
--------------------------------------------------------------------------------
--	nCLR_ALL <= not(xCLR_ALL);	--MCF; TST_START should be connected to xCLR_ALL
--------------------------------------------------------------------------------
end Behavioral;