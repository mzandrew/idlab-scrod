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
-- DATE : 23 Jan 2010																			--
-- Project name: STURM2 eval firmware														--
--	Module name: CTRL_LOOP_PRCO.vhd  														--
--	Description : 																					--
-- 	throttles Wilk. CLK to 730 MHz: xTST_OUT = 178 kHz								--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------	

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CTRL_LOOP_PRCO is
   port ( 
		xCLK				: in  std_logic;--150 MHz CLK
		xCLK_INV			: in  std_logic;--MCF
		xCLK_10MHz		: in  std_logic;--10  MHz CLK
		xCLR_ALL			: in  std_logic;
		xREFRESH_CLK	: in  std_logic;
		xTST_OUT			: in  std_logic;--Nominally 125 kHz
		xPRCO_INT		: out std_logic_vector(11 downto 0);
		xPROVDD			: out std_logic_vector(11 downto 0));	
end CTRL_LOOP_PRCO;

architecture Behavioral of CTRL_LOOP_PRCO is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type CNT_TYPE is ( IDLE,COUNT,LOAD_RAM);
	signal CNT_STATE	: CNT_TYPE;
	signal CNT 		: std_logic_vector(15 downto 0);	
	signal WADDR	: std_logic_vector(9 downto 0);	
	signal W_EN		: std_logic;
	type STATE_TYPE is ( IDLE,INTIALIZE,ADD_UP,
								BIT_SHIFT,CALC);
	signal STATE 		   : STATE_TYPE;
	signal xREAD	: std_logic_vector(15 downto 0);	
	signal RADDR	: std_logic_vector(9 downto 0);	
	signal xADD_UP	: std_logic_vector(23 downto 0);	
	signal xSTORE	: std_logic_vector(23 downto 0);	
	signal COMPARE_INT	: std_logic_vector(11 downto 0);
	signal PRCO_INT	: std_logic_vector(11 downto 0);
	signal PROVDD		: std_logic_vector(11 downto 0);
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
	component RAM_BLOCK
   port ( xRADDR 	: in    std_logic_vector(9 downto 0);
			 xREAD  	: out   std_logic_vector(15 downto 0);
          xRCLK 	: in    std_logic; 
          xR_EN  	: in    std_logic; 
          xWADDR 	: in    std_logic_vector(9 downto 0); 
          xWRITE 	: in    std_logic_vector(15 downto 0); 
          xWCLK 	: in    std_logic; 
          xW_EN  	: in    std_logic);
   end component;
--------------------------------------------------------------------------------
   component BUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
   component BUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	process(xCLK_INV,xCLR_ALL)
	begin
		if xCLR_ALL = '1' then
			CNT_STATE <= IDLE;
		elsif rising_edge(xCLK_INV) then	--MCF; used to be falling_edge(xCLK) which would cause gated clock errors
--------------------------------------------------------------------------------			
			case CNT_STATE is
--------------------------------------------------------------------------------	
				when IDLE =>			
					W_EN <= '0';
					CNT <= (others=>'0');
					if xTST_OUT = '1' then
						CNT_STATE <= COUNT;
					end if;
--------------------------------------------------------------------------------	
				when COUNT =>			
					if CNT <	1300 then
						CNT <= CNT + 1;
					end if;
					if xTST_OUT = '0' then
						WADDR <= WADDR + 1;
						CNT_STATE <= LOAD_RAM;
					end if;
--------------------------------------------------------------------------------	
				when LOAD_RAM =>			
					W_EN <= '1';
					CNT_STATE <= IDLE;
--------------------------------------------------------------------------------	
				when others =>	CNT_STATE<=IDLE;																
			end case;
		end if;
	end process;	
--------------------------------------------------------------------------------	
	xRAM_BLOCK : RAM_BLOCK 
	port map (
		xRADDR  	=> RADDR,
		xREAD 	=> xREAD,
		xRCLK  	=> xCLK_10MHz,
		xR_EN  	=> '1',
		xWADDR	=> WADDR,
		xWRITE  	=> CNT,
		xWCLK  	=> xCLK,
		xW_EN  	=> W_EN);			
--------------------------------------------------------------------------------
	process(xCLK_10MHz,xCLR_ALL)
	begin
		if xCLR_ALL = '1' then
			PROVDD <= x"AFF";
			STATE <= IDLE;
		elsif falling_edge(xCLK_10MHz) then
--------------------------------------------------------------------------------			
			case STATE is
--------------------------------------------------------------------------------	
				when IDLE =>			
					if xREFRESH_CLK = '1' then
						STATE <= INTIALIZE;
					end if;
--------------------------------------------------------------------------------	
				when INTIALIZE =>			
					if xREFRESH_CLK = '0' then
						RADDR <= (others=>'1');
						xADD_UP <= (others=>'0');
						STATE <= ADD_UP;
					end if;		
--------------------------------------------------------------------------------	
				when ADD_UP =>
					xADD_UP <= xADD_UP + (x"00" & xREAD);
					if RADDR = 0 then
						STATE <= BIT_SHIFT;
					else
						RADDR <= RADDR - 1;
					end if;		
--------------------------------------------------------------------------------	
				when BIT_SHIFT =>			
					PRCO_INT	<= xADD_UP(21 downto 10);
					STATE 	<= CALC;
--------------------------------------------------------------------------------	
				when CALC =>			
					if PRCO_INT > COMPARE_INT and PROVDD < x"FFE" then--measured upper limit
						PROVDD <= PROVDD + 1;
					elsif PRCO_INT < COMPARE_INT and PROVDD > x"3FF" then--measured lower limit
						PROVDD <= PROVDD - 1;
					end if;
--					PROVDD <= x"AFF";
					STATE	<= IDLE;
--------------------------------------------------------------------------------	
				when others =>	STATE<=IDLE;																
			end case;
		end if;
	end process;	
---------------------


-----------------------------------------------------------	
	COMPARE_INT <= x"184";--x"184"  658 almost perfect current ramp
--------------------------------------------------------------------------------	
	xBUF_PRCO_INT : BUF_BUS
	generic map(bus_width => 12)
	port map (
		I => PRCO_INT,
		O => xPRCO_INT);
--------------------------------------------------------------------------------
	xBUF_PROVDD : BUF_BUS
	generic map(bus_width => 12)
	port map (
		I => PROVDD,
		O => xPROVDD);
--------------------------------------------------------------------------------
end Behavioral;