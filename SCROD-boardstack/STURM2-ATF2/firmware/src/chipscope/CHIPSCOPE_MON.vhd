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
-- DATE : 22 OCT 2007																			--
-- Project name: BLAB1 firmware			    					 							--
--	Module name: BLAB1_RAM_TIMING																--
--	Description : 																					--
-- 	BLAB1 RAM timing firmware																--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CHIPSCOPE_MON is
	generic(
		xUSE_CHIPSCOPE      : integer := 1);  -- Set to 1 to use Chipscope 
	port( 
		xMON				: in  std_logic_vector(31 downto 0);	
		xCLK		 		: in  std_logic);	
end CHIPSCOPE_MON;

architecture Behavioral of CHIPSCOPE_MON is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal CONTROL	  		: std_logic_vector(35 downto 0);
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component ICON
      port( 
			CONTROL0 : inout STD_LOGIC_VECTOR (35 downto 0));
   end component;
   attribute BOX_TYPE of ICON : component is "BLACK_BOX";
--------------------------------------------------------------------------------	
component ILA
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;	--MCF; used to have := 'X'
    TRIG0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0));

end component;
   attribute BOX_TYPE of ILA : component is "BLACK_BOX";
--------------------------------------------------------------------------------	
begin
--------------------------------------------------------------------------------	
	chipscope : if xUSE_CHIPSCOPE = 1 generate 	
--------------------------------------------------------------------------------	
		xICON : ICON
		port map (
			CONTROL0  => CONTROL);
--------------------------------------------------------------------------------	
		xILA : ILA
		port map (
			CONTROL => CONTROL,
			CLK => xCLK,
			TRIG0 => xMON);
--------------------------------------------------------------------------------	
	end generate chipscope;
--------------------------------------------------------------------------------	
end Behavioral;