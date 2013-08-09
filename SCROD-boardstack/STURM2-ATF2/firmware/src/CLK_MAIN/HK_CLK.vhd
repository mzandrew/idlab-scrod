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
-- DATE : 27 JUNE 2007																			--
-- Project name: ICRR firmware																--
--	Module name: HK_CLK			  																--
--	Description : 																					--
-- 	House Keeping clock control module													--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HK_CLK is
	Port( 	
		xCLK_75MHz	: in std_logic;
		xREF_1kHz 	: out std_logic;	
		xREF_100Hz 	: out std_logic;	
		xREF_10Hz 	: out std_logic;					
		xREF_1Hz 	: out std_logic);
end HK_CLK;

architecture Behavioral of HK_CLK is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is (HI_STATE,LO_STATE);								

	signal STATE_1Hz  	: STATE_TYPE;
	signal CLK_1Hz			: std_logic;
	
	signal STATE_10Hz  	: STATE_TYPE;
	signal CLK_10Hz		: std_logic;
	
	signal STATE_100Hz	: STATE_TYPE;
	signal CLK_100Hz		: std_logic;
	
	signal STATE_1kHz		: STATE_TYPE;
	signal CLK_1kHz		: std_logic;

--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component BUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin 
--------------------------------------------------------------------------------	
	xBUF_CLK_1Hz : BUF
	port map (
		I  	=> CLK_1Hz,
		O		=> xREF_1Hz);	
--------------------------------------------------------------------------------	
	xBUF_CLK_10Hz : BUF
	port map (
		I  	=> CLK_10Hz,
		O		=> xREF_10Hz);	
--------------------------------------------------------------------------------	
	xBUF_CLK_100Hz : BUF
	port map (
		I  	=> CLK_100Hz,
		O		=> xREF_100Hz);	
--------------------------------------------------------------------------------	
	xBUF_CLK_1kHz : BUF
	port map (
		I  	=> CLK_1kHz,
		O		=> xREF_1kHz);	
--------------------------------------------------------------------------------	
	process(xCLK_75MHz)
	variable i : integer range 37500001 downto 0;
	begin
		if rising_edge(xCLK_75MHz) then
--------------------------------------------------------------------------------			
			case STATE_1Hz is
--------------------------------------------------------------------------------	
				when HI_STATE =>			
					CLK_1Hz <= '1';
					i := i + 1;
					if i = 37500000 then
						i := 1;
						STATE_1Hz <= LO_STATE;
					end if;
--------------------------------------------------------------------------------	
				when LO_STATE =>			
					CLK_1Hz <= '0';
					i := i + 1;
					if i = 37500000 then
						i := 1;
						STATE_1Hz <= HI_STATE;
					end if;
--------------------------------------------------------------------------------	
				when others =>	STATE_1Hz<=HI_STATE;																
			end case;
		end if;
	end process;	
--------------------------------------------------------------------------------	
	process(xCLK_75MHz)
	variable i : integer range 3750001 downto 0;
	begin
		if rising_edge(xCLK_75MHz) then
--------------------------------------------------------------------------------			
			case STATE_10Hz is
--------------------------------------------------------------------------------	
				when HI_STATE =>			
					CLK_10Hz <= '1';
					i := i + 1;
					if i = 3750000 then
						i := 1;
						STATE_10Hz <= LO_STATE;
					end if;
--------------------------------------------------------------------------------	
				when LO_STATE =>			
					CLK_10Hz <= '0';
					i := i + 1;
					if i = 3750000 then
						i := 1;
						STATE_10Hz <= HI_STATE;
					end if;
--------------------------------------------------------------------------------	
				when others =>	STATE_10Hz<=HI_STATE;																
			end case;
		end if;
	end process;	
--------------------------------------------------------------------------------	
	process(xCLK_75MHz)
	variable i : integer range 375001 downto 0;
	begin
		if rising_edge(xCLK_75MHz) then
--------------------------------------------------------------------------------			
			case STATE_100Hz is
--------------------------------------------------------------------------------	
				when HI_STATE =>			
					CLK_100Hz <= '1';
					i := i + 1;
					if i = 375000 then
						i := 1;
						STATE_100Hz <= LO_STATE;
					end if;
--------------------------------------------------------------------------------	
				when LO_STATE =>			
					CLK_100Hz <= '0';
					i := i + 1;
					if i = 375000 then
						i := 1;
						STATE_100Hz <= HI_STATE;
					end if;
--------------------------------------------------------------------------------	
				when others =>	STATE_100Hz<=HI_STATE;																
			end case;
		end if;
	end process;	
--------------------------------------------------------------------------------
	process(xCLK_75MHz)
	variable i : integer range 37501 downto 0;
	begin
		if rising_edge(xCLK_75MHz) then
--------------------------------------------------------------------------------			
			case STATE_1kHz is
--------------------------------------------------------------------------------	
				when HI_STATE =>			
					CLK_1kHz <= '1';
					i := i + 1;
					if i = 37500 then
						i := 1;
						STATE_1kHz <= LO_STATE;
					end if;
--------------------------------------------------------------------------------	
				when LO_STATE =>			
					CLK_1kHz <= '0';
					i := i + 1;
					if i = 37500 then
						i := 1;
						STATE_1kHz <= HI_STATE;
					end if;
--------------------------------------------------------------------------------	
				when others =>	STATE_1kHz<=HI_STATE;																
			end case;
		end if;
	end process;	
--------------------------------------------------------------------------------
end Behavioral;