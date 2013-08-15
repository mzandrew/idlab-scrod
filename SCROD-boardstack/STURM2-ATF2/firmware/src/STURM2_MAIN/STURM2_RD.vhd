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
		xCLK_INV		 : in  std_logic;--MCF
		xCLK_75MHz   : in  std_logic;--75  MHz CLK
		xADC			 : out std_logic_vector(11 downto 0);
		xSTATUS	    : out std_logic_vector(3 downto 0);
		xINITIATE_WILKINSON_AND_THEN_TRANSFER_TO_FPGA_RAM 	 : in  std_logic; -- mza
		xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM 	 					 : out std_logic; -- mza
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
								WAIT_FOR_BUS_SETTLING,WAIT_FOR_CLR_TDC_SETTLING,
								SPACE_BETWEEN_TDC_CLR_AND_TDC_START);
	signal STATE 		   : STATE_TYPE := IDLE;
	signal W_EN				: std_logic;
	signal xWRITE			: std_logic_vector(15 downto 0);
	signal WADDR			: std_logic_vector(9 downto 0);
	signal xWADDR			: std_logic_vector(9 downto 0);
	signal RAMP	 		 	: std_logic; 
	signal TDC_START	 	: std_logic; 
	signal TDC_STOP		: std_logic; 
	signal TDC_CLR		 	: std_logic; 	
	signal THERE_IS_NEW_DATA_IN_THE_FPGA_RAM		 	: std_logic; -- mza
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
	-- mza:
	xBUF_START : BUF 
	port map (
		I  => THERE_IS_NEW_DATA_IN_THE_FPGA_RAM,
		O  => xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM);	
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
	DATA <= x"0" & xDAT;  -- GSV
--	DATA <= x"0" & "00" & xWADDR;
--------------------------------------------------------------------------------
	process(xCLK_INV,xCLR_ALL,xDONE)
	begin
		if xCLR_ALL = '1' or xDONE = '1' or PHASE_CNT > 6 then
			STATE_CNT	<= x"0000";
			PHASE_CNT	<= "000";
			WADDR			<= "1111111111";
			RAMP 			<= '0';
			RAMP_DONE	<= '0';
			THERE_IS_NEW_DATA_IN_THE_FPGA_RAM <= '0'; -- mza
			TDC_START 	<= '0';
			TDC_STOP 	<= '0';	--MCF; used to be '1'.  setting to '0' so we don't get any funny business
			TDC_CLR 		<= '1';
			W_EN 			<= '0';
			STATE 		<= IDLE;
		elsif rising_edge(xCLK_INV) then	--MCF; used to be falling_edge(xCLK) which resulted in gated clock errors
--------------------------------------------------------------------------------			
			case STATE is
--------------------------------------------------------------------------------	
				when IDLE =>			
					if xINITIATE_WILKINSON_AND_THEN_TRANSFER_TO_FPGA_RAM = '1' then -- mza
						STATE 		<= CLR_TDC;
					end if;
--------------------------------------------------------------------------------	
				when CLR_TDC =>			
					TDC_CLR		<= '1';
					TDC_STOP		<= '0';
					PHASE_CNT	<= "000";  -- GSV modified	
					STATE 		<= WAIT_FOR_CLR_TDC_SETTLING;
--------------------------------------------------------------------------------	
				when WAIT_FOR_CLR_TDC_SETTLING =>			
					PHASE_CNT <= PHASE_CNT + 1;
					if PHASE_CNT >= 2 then
						TDC_CLR     <= '0';
						PHASE_CNT	<= "000";
						STATE_CNT	<= x"0000";
						STATE 		<= SPACE_BETWEEN_TDC_CLR_AND_TDC_START;
					end if;
--------------------------------------------------------------------------------
				when SPACE_BETWEEN_TDC_CLR_AND_TDC_START =>	--MCF; added this state	
					STATE_CNT <= STATE_CNT + 1;
					if STATE_CNT >= 100 then
						PHASE_CNT	<= "000";
						STATE_CNT	<= x"0000";
						STATE 		<= START_TDC;
					end if; 
--------------------------------------------------------------------------------	
				when START_TDC =>
					STATE_CNT <= STATE_CNT + 1;   
--					TDC_START 	<= '1'; --4.0 us long ramp
					TDC_START 	<= '1'; --~3.9 us long ramp
					RAMP 			<= '1'; -- ISEL = 20 kohm & CEXT = 150 pF (cpad)
					if STATE_CNT >= 600 then	--MCF; used to be 8000. (3.9 us + 0.1 us) * 150MHz = 600 oscillations
						RAMP_DONE	 <= '1';
						WADDR		 	 <= "0000000000";
						STATE 		 <= STORE_to_RAM;
					end if;
--------------------------------------------------------------------------------	
				when STORE_to_RAM =>			
					W_EN 	<= '0';
--					WADDR <= WADDR + 1;
-- was WADDR >= 287
					if WADDR >= 256 then -- see STATE3 in usbwrite.vhd and state ADC in mess.vhd
						STATE <= START_USB_READOUT;
					else
						STATE <= WAIT_FOR_BUS_SETTLING;
					end if;		
--------------------------------------------------------------------------------				
				when WAIT_FOR_BUS_SETTLING =>			
					PHASE_CNT <= PHASE_CNT + 1;
						W_EN 	<= '1';	
					if PHASE_CNT >= 3 then
						W_EN 	<= '0';
						PHASE_CNT	<= "000";
						STATE <= STORE_to_RAM; 
						WADDR <= WADDR + 1;
					end if;
--------------------------------------------------------------------------------				
				when START_USB_READOUT =>			
					THERE_IS_NEW_DATA_IN_THE_FPGA_RAM <= '1'; -- mza
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
	process(STATE)	--encodes the states and outputs them
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
