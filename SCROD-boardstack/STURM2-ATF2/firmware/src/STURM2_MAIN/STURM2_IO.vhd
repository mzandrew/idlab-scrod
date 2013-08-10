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
--	Module name: STURM2_IO.vhd				  													--
--	Description : 																					--
-- 	General STURM2 I/O   																	--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity STURM2_IO is
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
		-- User I/O
		xRAMP	 		 : in  std_logic; 
		xTST_START 	 : in  std_logic; 
		xTST_CLR	 	 : in  std_logic; 
		xTST_OUT		 : out std_logic;
		xSMPL_SEL	 : in  std_logic_vector(4 downto 0);
		xDAT			 : out std_logic_vector(11 downto 0);
		xCH_SEL		 : in  std_logic_vector(3 downto 0);
		xTDC_START	 : in  std_logic; 
		xTDC_STOP	 : in  std_logic; 
		xTDC_CLR		 : in  std_logic; 
		xMRCO		 	 : out std_logic;
		xTSA_IN		 : out std_logic_vector(3 downto 0);
		xTSA_OUT		 : in  std_logic_vector(3 downto 0);
		xCAL			 : in  std_logic);
end STURM2_IO;

architecture Behavioral of STURM2_IO is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal preTST_OUT : std_logic;
	signal preMRCO : std_logic;
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
   component OBUFDS
      port ( I  : in    std_logic;  
             O  : out   std_logic;
				 OB : out   std_logic);
   end component;
   attribute BOX_TYPE of OBUFDS : component is "BLACK_BOX";	
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
	xOBUF_RAMP : OBUF 
	port map (
		I  => xRAMP,
		O  => RAMP);		
--------------------------------------------------------------------------------
	xIBUF_DAT : IBUF_BUS
	generic map(bus_width => 12)
	port map (
		I => DAT,
		O => xDAT);
--------------------------------------------------------------------------------	
	xOBUF_TST_START : OBUF 
	port map (
		I  => xTST_START,
		O  => TST_START);		
--------------------------------------------------------------------------------
	xOBUF_TST_CLR : OBUF 
	port map (
		I  => xTST_CLR,
		O  => TST_CLR);		
--------------------------------------------------------------------------------
	xIBUF_TST_OUT : IBUF 
	port map (
		I  => TST_OUT,
		O  => preTST_OUT);		
--------------------------------------------------------------------------------
	xBUF_TST_OUT : BUF 
	port map (
		I  => preTST_OUT,
		O  => xTST_OUT);		
--------------------------------------------------------------------------------
	xOBUF_SMPL_SEL : OBUF_BUS
	generic map(bus_width => 5)
	port map (
		I => xSMPL_SEL,
		O => SMPL_SEL);
--------------------------------------------------------------------------------	
	xOBUF_CH_SEL : OBUF_BUS
	generic map(bus_width => 4)
	port map (
		I => xCH_SEL,
		O => CH_SEL);
--------------------------------------------------------------------------------	
	xOBUF_TDC_START : OBUF 
	port map (
		I  => xTDC_START,
		O  => TDC_START);		
--------------------------------------------------------------------------------
	xOBUF_TDC_STOP : OBUF 
	port map (
		I  => xTDC_STOP,
		O  => TDC_STOP);		
--------------------------------------------------------------------------------			
	xOBUF_TDC_CLR : OBUF 
	port map (
		I  => xTDC_CLR,
		O  => TDC_CLR);		
--------------------------------------------------------------------------------
	xIBUF_MRCO : IBUF 
	port map (
		I  => MRCO,
		O  => preMRCO);		
--------------------------------------------------------------------------------
	xBUF_MRCO : BUF 
	port map (
		I  => preMRCO,
		O  => xMRCO);		
--------------------------------------------------------------------------------
	xIBUF_TSA_IN : IBUF_BUS
	generic map(bus_width => 4)
	port map (
		I => TSA_IN,
		O => xTSA_IN);
--------------------------------------------------------------------------------	
	xOBUF_TSA_IN : OBUF_BUS
	generic map(bus_width => 4)
	port map (
		I => xTSA_OUT,
		O => TSA_OUT);
--------------------------------------------------------------------------------	
	xOBUFDS_CAL : OBUFDS 
	port map (
		I  => xCAL,
		O  => CAL_P,
		OB => CAL_N);		
--------------------------------------------------------------------------------		
end Behavioral;