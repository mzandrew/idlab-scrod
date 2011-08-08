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
-- DATE : 10 March 2007																			--
-- Project name: FDIRC_CAMAC firmware														--
-- FPGA chip :	Xilinx's SPARTAN3	xc3s200-208											   --
-- USB chip : CYPRESS CY7C68013  															--
--	Module name: PROGRESET        															--
--	Description : 																					--
-- 	progreset will be reset other module                        				--
--																										--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PROGRESET is
    Port ( 	xCLK     : 	in std_logic; 		
          	xWAKEUP  : 	in std_logic; 		
				xSOFT_RESET : in std_logic;
				xCLR_ALL : 	out std_logic; 
           	xRESET   : 	out std_logic); 	
end PROGRESET;

architecture Behavioral of PROGRESET is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is(RESETD, NORMAL);
	signal STATE	: STATE_TYPE := RESETD;	
	signal RESET 	: std_logic := '0';
	signal CLR_ALL : std_logic := '1';
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
    component BUF
    port (
		I  : in  std_logic;
      O 	: out std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------	
	process(xCLK,xWAKEUP,xSOFT_RESET) 
	variable i: integer range 0 to 100000001 :=0;
	begin	
		if xWAKEUP = '0' or xSOFT_RESET = '1' then
			RESET 	<= '0';
			CLR_ALL 	<= '1';		 				
			STATE <= RESETD;		
		elsif rising_edge(xCLK) then
			case	STATE is
--------------------------------------------------------------------------------				
				when RESETD =>
					i:= i + 1;
					if i = 100000000 then
						i:=0;
						STATE <= NORMAL;
					end if;
--------------------------------------------------------------------------------
				when NORMAL =>
					RESET 	<= '1';
					CLR_ALL 	<= '0';		 				
--------------------------------------------------------------------------------
				when others =>
					STATE <= RESETD;
			end case;	
--------------------------------------------------------------------------------	
		end if;
	end process;
--------------------------------------------------------------------------------	
	xBUF_RESET : BUF 
	port map (
		I  	=> RESET,
		O		=> xRESET);			
--------------------------------------------------------------------------------	
	xBUF_CLR_ALL : BUF 
	port map (
		I  	=> CLR_ALL,
		O		=> xCLR_ALL);			
--------------------------------------------------------------------------------	
end Behavioral;