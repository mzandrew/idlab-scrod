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
-- 	Top Level for Trigger Dac Control	 												--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DAC_MAIN is
    port (
		xCLK			: in  std_logic;--150 MHz CLK
		xCLK_INV		: in  std_logic;--MCF
		xCLK_75MHz	: in  std_logic;--75  MHz CLK
		xCLK_10MHz 	: in  std_logic;--10  MHz CLK
		xCLK_10MHz_INV: in std_logic;--MCF
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
end DAC_MAIN;

architecture Behavioral of DAC_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal NSYNC	 	: std_logic;
	signal D_IN_0		: std_logic;
	signal D_IN_1		: std_logic;
	signal D_IN_2		: std_logic;
	signal UPDATE	 	: std_logic;
	
	signal DAC_A_0		: std_logic_vector(15 downto 0);
	signal DAC_B_0		: std_logic_vector(15 downto 0);
	signal DAC_C_0		: std_logic_vector(15 downto 0);
	signal DAC_D_0		: std_logic_vector(15 downto 0);
	
	signal DAC_A_1		: std_logic_vector(15 downto 0);
	signal DAC_B_1		: std_logic_vector(15 downto 0);
	signal DAC_C_1		: std_logic_vector(15 downto 0);
	signal DAC_D_1		: std_logic_vector(15 downto 0);

	signal DAC_A_2		: std_logic_vector(15 downto 0);
	signal DAC_B_2		: std_logic_vector(15 downto 0);
	signal DAC_C_2		: std_logic_vector(15 downto 0);
	signal DAC_D_2		: std_logic_vector(15 downto 0);
	
	signal PROVDD		: std_logic_vector(11 downto 0);
	signal PROGND		: std_logic_vector(11 downto 0);
	signal PRCO_INT	: std_logic_vector(11 downto 0);

	signal ROVDD		: std_logic_vector(11 downto 0);
	signal ROGND		: std_logic_vector(11 downto 0);
	signal RCO_INT		: std_logic_vector(11 downto 0);
	
	signal VDLY0		: std_logic_vector(11 downto 0);
	signal VDLY1		: std_logic_vector(11 downto 0);
	signal VDLY2		: std_logic_vector(11 downto 0);
	signal VDLY3		: std_logic_vector(11 downto 0);
	signal VDLY4		: std_logic_vector(11 downto 0);
	signal VDLY5		: std_logic_vector(11 downto 0);
	signal VDLY6		: std_logic_vector(11 downto 0);
	signal VDLY7		: std_logic_vector(11 downto 0);
--------------------------------------------------------------------------------
--   								components     		   						         --
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
Component ODDR2
	generic (
	  DDR_ALIGNMENT : string     := "NONE";	-- Sets output alignment to "NONE", "C0", "C1"
	  INIT          : integer    := 0;   		-- Sets initial state of the Q output to '0' or '1'
	  SRTYPE        : string     := "SYNC"		-- Specifies "SYNC" or "ASYNC" set/reset
				);
	port (
	  Q  	: out std_logic;
	  C0	: in std_logic;
	  C1 	: in std_logic;
	  CE 	: in std_logic;
	  D0 	: in std_logic;
	  D1 	: in std_logic;
	  R 	: in std_logic;
	  S 	: in std_logic
			);	
end component;
--------------------------------------------------------------------------------
   component DAC_SERIALIZER
   port ( 
		xCLK_10MHz	: in  std_logic;
		xUPDATE   	: in    std_logic;
		xDAC_A 		: in    std_logic_vector (15 downto 0);
		xDAC_B 		: in    std_logic_vector (15 downto 0);
		xDAC_C 		: in    std_logic_vector (15 downto 0);
		xDAC_D 		: in    std_logic_vector (15 downto 0);
		xNSYNC		: out   std_logic;
		xD_OUT	 	: out   std_logic);	
   end component;
--------------------------------------------------------------------------------
   component RCO_MAIN
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
   end component;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	--UPDATE <= xREF_1Hz;
	UPDATE <= xREF_10Hz;
	--UPDATE <= xREF_100Hz;
--------------------------------------------------------------------------------
	xRCO_MAIN : RCO_MAIN 
	port map (
		xREFRESH_CLK => UPDATE,
		xCLR_ALL    => xCLR_ALL,
		xCLK 		 	=> xCLK,
		xCLK_INV		=> xCLK_INV,	--MCF
		xCLK_75MHz 	=> xCLK_75MHz,
		xCLK_10MHz  => xCLK_10MHz,
		xREF_1kHz  	=> xREF_1kHz,
		xREF_100Hz  => xREF_100Hz,
		xREF_10Hz	=> xREF_10Hz,
		xREF_1Hz		=> xREF_1Hz,
		xDEBUG      => xDEBUG,
		xPRCO_INT   => PRCO_INT,
		xPROVDD    	=> PROVDD,
		xRCO_INT    => RCO_INT,
		xROVDD    	=> open,--ROVDD
--		xROVDD    	=> ROVDD,  Doesn't EXIST!!  GSV
		xTST_START  => xTST_START,
		xTST_CLR    => xTST_CLR,
		xTST_OUT    => xTST_OUT,
		xMRCO   		=> xMRCO);
--------------------------------------------------------------------------------
		xPRCO_INT   <= PRCO_INT;
		xPROVDD    	<= PROVDD;
		xRCO_INT    <= RCO_INT;
		xROVDD    	<= ROVDD;
--------------------------------------------------------------------------------
-- mza - original values were vdly0=4fe, vdly1=vdly0 - 4, vdly2=vdly1 - 0, vdly3=vdly1 - 0, vdly4=vdly1 - vdly5=vdly1 - 0, vdly6=vdly1 - 0, vdly7=vdly1 - 0
--	VDLY0 <= x"4FE"; -- was "FFF" then "7FF" (7FF not really working)
--	VDLY1 <= VDLY0 - x"005";
--	VDLY2 <= VDLY1 - x"005";
--	VDLY3 <= VDLY2 - x"005";
--	VDLY4 <= VDLY3 - x"005";
--	VDLY5 <= VDLY4 - x"005";
--	VDLY6 <= VDLY5 - x"005";
--	VDLY7 <= VDLY6 - x"005";
--------------------------------------------------------------------------------
	VDLY0 <= x"BAB";	--1.800V
	VDLY1 <= x"B9E";	--1.775V
	VDLY2 <= x"B58";	--1.750V
	VDLY3 <= x"B27";	--1.725V
	VDLY4 <= x"AFB";	--1.700V
	VDLY5 <= x"ADF";	--1.675V
	VDLY6 <= x"AC4";	--1.650V
	VDLY7 <= x"A64";	--1.625V
--------------------------------------------------------------------------------
--	VDLY0 <= x"898";	--1.36V
--	VDLY1 <= x"898";	--1.36V
--	VDLY2 <= x"898";	--1.36V
--	VDLY3 <= x"898";	--1.36V
--	VDLY4 <= x"898";	--1.36V
--	VDLY5 <= x"898";	--1.36V
--	VDLY6 <= x"898";	--1.36V
--	VDLY7 <= x"898";	--1.36V
--------------------------------------------------------------------------------

	DAC_A_0 <= x"3" & VDLY0;--VDLY0
	DAC_B_0 <= x"7" & VDLY1;--VDLY1
	DAC_C_0 <= x"B" & VDLY2;--VDLY2
	DAC_D_0 <= x"E" & VDLY3;--VDLY3
--------------------------------------------------------------------------------
	DAC_A_1 <= x"3" & VDLY4;--VDLY4
	DAC_B_1 <= x"7" & VDLY5;--VDLY5
	DAC_C_1 <= x"B" & VDLY6;--VDLY6
	DAC_D_1 <= x"E" & VDLY7;--VDLY7
--------------------------------------------------------------------------------	
	DAC_A_2 <= x"3" & x"D60";--MCF; used to be PROVDD; D60
	DAC_B_2 <= x"7" & x"000";--x"000"
	DAC_C_2 <= x"B" & x"000";--x"000"
	DAC_D_2 <= x"E" & xPED_SCAN;--xPED_SCAN, ADJUSTABLE VPED VOLTAGE 6FF = 1.16 Volts. maxes at 1.68 volts instead of 2.5
--------------------------------------------------------------------------------	
	xDAC_SERIALIZER_0 : DAC_SERIALIZER 
	port map (
		xCLK_10MHz 	=> xCLK_10MHz,
		xUPDATE 	=> UPDATE,
		xDAC_A 	=> DAC_A_0,
		xDAC_B 	=> DAC_B_0,
		xDAC_C 	=> DAC_C_0,
		xDAC_D 	=> DAC_D_0,
		xNSYNC 	=> NSYNC,
		xD_OUT 	=> D_IN_0);
--------------------------------------------------------------------------------	
	xDAC_SERIALIZER_1 : DAC_SERIALIZER 
	port map (
		xCLK_10MHz 	=> xCLK_10MHz,
		xUPDATE 	=> UPDATE,
		xDAC_A 	=> DAC_A_1,
		xDAC_B 	=> DAC_B_1,
		xDAC_C 	=> DAC_C_1,
		xDAC_D 	=> DAC_D_1,
		xNSYNC 	=> open,
		xD_OUT 	=> D_IN_1);
--------------------------------------------------------------------------------	
	xDAC_SERIALIZER_2 : DAC_SERIALIZER 
	port map (
		xCLK_10MHz 	=> xCLK_10MHz,
		xUPDATE 	=> UPDATE,
		xDAC_A 	=> DAC_A_2,
		xDAC_B 	=> DAC_B_2,
		xDAC_C 	=> DAC_C_2,
		xDAC_D 	=> DAC_D_2,
		xNSYNC 	=> open,
		xD_OUT 	=> D_IN_2);
--------------------------------------------------------------------------------	
xODDR2_SCLK : ODDR2 --MCF; clock forwarding technique which allows CLK_10MHz to be outputted as SCLK
generic map (
	  DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
	  INIT          => 0,    -- Sets initial state of the Q output to '0' or '1'
	  SRTYPE        => "SYNC"  -- Specifies "SYNC" or "ASYNC" set/reset
				)
port map (
	  Q  => SCLK,        -- 1-bit output data
	  C0 => xCLK_10MHz, -- 1-bit clock input
	  C1 => xCLK_10MHz_INV,   -- 1-bit clock input
	  CE => '1',          -- 1-bit clock enable input
	  D0 => '1',          -- 1-bit data input (associated with C0)
	  D1 => '0',          -- 1-bit data input (associated with C1)
	  R  => '0',          -- 1-bit reset input
	  S  => '0'           -- 1-bit set input
			);
--------------------------------------------------------------------------------
	xOBUF_SYNC : OBUF 
	port map (
		I  => NSYNC,
		O  => SYNC);	
--------------------------------------------------------------------------------
	xOBUF_DIN0 : OBUF 
	port map ( 
		I  => D_IN_0,
		O  => DIN0);	
--------------------------------------------------------------------------------
	xOBUF_DIN1 : OBUF 
	port map (
		I  => D_IN_1,
		O  => DIN1);	
--------------------------------------------------------------------------------
	xOBUF_DIN2 : OBUF 
	port map (
		I  => D_IN_2,
		O  => DIN2);	
--------------------------------------------------------------------------------
end Behavioral;