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

entity STURM2_RD is
   port ( 
		-- STURM2 ASIC I/Os
		xCH_SEL		 	: out std_logic_vector(3 downto 0);
		xSMPL_SEL	 	: out std_logic_vector(4 downto 0);
		xRAMP	 		 	: out std_logic; 
		xDAT			 	: in  std_logic_vector(11 downto 0);
		xTDC_START	 	: out std_logic; 
		xTDC_STOP	 	: out std_logic; 
		xTDC_CLR		 	: out std_logic; 
		-- User I/O
		xCLK			 : in  std_logic;--150 MHz CLK
		xCLK_75MHz   : in  std_logic;--75  MHz CLK
		xADC			 : out std_logic_vector(11 downto 0);
		xSTATUS	    : out std_logic_vector(3 downto 0);
		xINITIATE 	 : in  std_logic;
		xSTART 	 	 : out std_logic;
		xDONE		 	 : in  std_logic;
		xRAMP_DONE 	 : out std_logic;
		xW_EN			 : out std_logic;
		xRADDR    	 : in  std_logic_vector(9 downto 0);		
		xCLR_ALL 	 : in  std_logic);
end STURM2_RD;

architecture Behavioral of STURM2_RD is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is ( IDLE,CLR_TDC,START_TDC,STORE_to_RAM,
								START_USB_READOUT,
								WAIT_FOR_BUS_SETTLING,WAIT_FOR_CLR_TDC_SETTLING);
	signal STATE 		   : STATE_TYPE := IDLE;
	signal W_EN				: std_logic;
	signal xWRITE			: std_logic_vector(15 downto 0);
	signal WADDR			: std_logic_vector(9 downto 0);
	signal xWADDR			: std_logic_vector(9 downto 0);
	signal RAMP	 		 	: std_logic; 
	signal TDC_START	 	: std_logic; 
	signal TDC_STOP		: std_logic; 
	signal TDC_CLR		 	: std_logic; 	
	signal START		 	: std_logic; 
	signal ADC				: std_logic_vector(15 downto 0);
	signal DATA				: std_logic_vector(15 downto 0);
	signal RAMP_DONE	 	: std_logic; 
	signal STATE_CNT	 	: std_logic_vector(15 downto 0);
	signal PHASE_CNT	 	: std_logic_vector(2 downto 0);
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
	xBUF_CH_SEL : BUF_BUS
	generic map(bus_width => 4)
	port map (
		I => xWADDR(8 downto 5),
		O => xCH_SEL);
--------------------------------------------------------------------------------	
	xBUF_SMPL_SEL : BUF_BUS
	generic map(bus_width => 5)
	port map (
		I => xWADDR(4 downto 0),
		O => xSMPL_SEL);
--------------------------------------------------------------------------------	
	xBUF_ADC : BUF_BUS
	generic map(bus_width => 12)
	port map (
		I => ADC(11 downto 0),
		O => xADC);
--------------------------------------------------------------------------------	
	xBUF_RAMP : BUF 
	port map (
		I  => RAMP,
		O  => xRAMP);	
--------------------------------------------------------------------------------	
	xBUF_TDC_START : BUF 
	port map (
		I  => TDC_START,
		O  => xTDC_START);	
--------------------------------------------------------------------------------	
	xBUF_TDC_STOP : BUF 
	port map (
		I  => TDC_STOP,
		O  => xTDC_STOP);	
--------------------------------------------------------------------------------	
	xBUF_TDC_CLR : BUF 
	port map (
		I  => TDC_CLR,
		O  => xTDC_CLR);	
--------------------------------------------------------------------------------	
	xBUF_START : BUF 
	port map (
		I  => START,
		O  => xSTART);	
--------------------------------------------------------------------------------	
	xBUF_RAMP_DONE : BUF 
	port map (
		I  => RAMP_DONE,
		O  => xRAMP_DONE);	
--------------------------------------------------------------------------------	
	xBUF_W_EN : BUF 
	port map (
		I  => W_EN,
		O  => xW_EN);	
--------------------------------------------------------------------------------	
	xBUF_WADDR : BUF_BUS
	generic map(bus_width => 10)
	port map (
		I => WADDR,
		O => xWADDR);
--------------------------------------------------------------------------------	
	xBUF_DATA : BUF_BUS
	generic map(bus_width => 16)
	port map (
		I => DATA,		
		O => xWRITE);
--------------------------------------------------------------------------------	
	DATA <= x"0" & xDAT;
	--DATA <= x"0" & "00" & xWADDR;
--------------------------------------------------------------------------------
	process(xCLK,xCLR_ALL,xDONE)
	begin
		if xCLR_ALL = '1' or xDONE = '1' then
			STATE_CNT	<= (others=>'0');
			PHASE_CNT	<= (others=>'0');
			WADDR			<= (others=>'1');
			RAMP 			<= '0';
			RAMP_DONE	<= '0';
			START 		<= '0';
			TDC_START 	<= '0';
			TDC_STOP 	<= '1';
			TDC_CLR 		<= '1';
			W_EN 			<= '0';
			STATE 		<= IDLE;
		elsif falling_edge(xCLK) then
--------------------------------------------------------------------------------			
			case STATE is
--------------------------------------------------------------------------------	
				when IDLE =>			
					if xINITIATE = '1' then
						STATE 		<= CLR_TDC;
					end if;
--------------------------------------------------------------------------------	
				when CLR_TDC =>			
					TDC_CLR		<= '0';
					TDC_STOP		<= '0';
					STATE 		<= WAIT_FOR_CLR_TDC_SETTLING;
--------------------------------------------------------------------------------	
				when WAIT_FOR_CLR_TDC_SETTLING =>			
					PHASE_CNT <= PHASE_CNT + 1;
					if PHASE_CNT > 3 then
						PHASE_CNT	<= (others=>'0');
						STATE 		<= START_TDC;
					end if;
--------------------------------------------------------------------------------	
				when START_TDC =>
					STATE_CNT <= STATE_CNT + 1;   
					TDC_START 	<= '1'; --4.0 us long ramp
					RAMP 			<= '1'; -- ISEL = 20 kohm & CEXT = 100 pF
					if STATE_CNT = 6000 then
						RAMP_DONE	 <= '1';
						STATE 		 <= STORE_to_RAM;
					end if;
--------------------------------------------------------------------------------	
				when STORE_to_RAM =>			
					W_EN 	<= '0';
					WADDR <= WADDR + 1;
					if WADDR = 287 then
						STATE <= START_USB_READOUT;
					else
						STATE <= WAIT_FOR_BUS_SETTLING;
					end if;		
--------------------------------------------------------------------------------				
				when WAIT_FOR_BUS_SETTLING =>			
					PHASE_CNT <= PHASE_CNT + 1;
					if PHASE_CNT > 2 then
						W_EN 	<= '1';
						PHASE_CNT	<= (others=>'0');
						STATE <= STORE_to_RAM; 
					end if;
--------------------------------------------------------------------------------				
				when START_USB_READOUT =>			
					START <= '1';
--------------------------------------------------------------------------------						
				when others =>
					state <= IDLE;
			end case;	  
		end if;
	end process;
--------------------------------------------------------------------------------	
	xRAM_BLOCK : RAM_BLOCK 
	port map (
		xRADDR  	=> xRADDR,
		xREAD 	=> ADC,
		xRCLK  	=> xCLK,
		xR_EN  	=> '1',
		xWADDR	=> WADDR,
		xWRITE  	=> xWRITE,
		xWCLK  	=> xCLK,
		xW_EN  	=> W_EN);		
--------------------------------------------------------------------------------	
	process(STATE)
	begin
		if STATE = IDLE then
			xSTATUS <= x"0";
		elsif STATE = CLR_TDC then
			xSTATUS <= x"1";
		elsif STATE = WAIT_FOR_CLR_TDC_SETTLING then
			xSTATUS <= x"2";
		elsif STATE = START_TDC then
			xSTATUS <= x"3";
		elsif STATE = STORE_to_RAM then
			xSTATUS <= x"4";
		elsif STATE = WAIT_FOR_BUS_SETTLING then
			xSTATUS <= x"5";
		elsif STATE = START_USB_READOUT then
			xSTATUS <= x"6";
		else
			xSTATUS <= x"F";
		end if;
	end process;	
--------------------------------------------------------------------------------
end Behavioral;
