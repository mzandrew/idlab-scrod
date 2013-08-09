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

entity STURM2_WR is
	Port( 	
		-- STURM2 ASIC I/Os
		xTSA_IN		 : in  std_logic_vector(3 downto 0);
		xTSA_OUT		 : out std_logic_vector(3 downto 0);
		xCAL		 	 : out std_logic;
		-- User I/O
		xNRUN		 	 : out std_logic;
		xCLK			 : in  std_logic;--150 MHz CLK
		xCLK_75MHz	 : in  std_logic;--75  MHz CLK
		xPED_EN	 	 : in  std_logic;
		xEXT_TRIG 	 : in  std_logic;
		xSOFT_TRIG 	 : in  std_logic;
		xCLR_ALL 	 : in  std_logic);
end STURM2_WR;

architecture Behavioral of STURM2_WR is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xBLOCK 		: std_logic;
	signal CAL			: std_logic;
	signal TSA_OUT	: std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------	
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------			
	process(xSOFT_TRIG,xPED_EN)
	begin
		if xSOFT_TRIG = '1' or xPED_EN = '1' then
			xBLOCK <= '1';
		else
			xBLOCK <= '0';
		end if;
	end process;
--------------------------------------------------------------------------------			
	xBUF_CAL : BUF 
	port map (
		I  => CAL,
		O  => xCAL);		
--------------------------------------------------------------------------------
	CAL <= xCLK and not(xBLOCK);
--------------------------------------------------------------------------------			
	xBUF_NRUN : BUF 
	port map (
		I  => xSOFT_TRIG,
		O  => xNRUN);		
--------------------------------------------------------------------------------
	TSA_OUT <= xSOFT_TRIG & xSOFT_TRIG & xSOFT_TRIG & xSOFT_TRIG;
--------------------------------------------------------------------------------	
	xBUF_TSA_OUT : BUF_BUS
	generic map(bus_width => 4)
	port map (
		I => TSA_OUT,
		O => xTSA_OUT);
--------------------------------------------------------------------------------
end Behavioral;