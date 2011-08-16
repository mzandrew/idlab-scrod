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
-- DATE : 10 SEPT 2007																			--
-- Project name: ICRR firmware																--
--	Module name: MESS	  																			--
--	Description : 																					--
-- 	Master Event Synchronous Sequencer (MESS) module								--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MESS is
   port ( 
		xSLWR       : in  std_logic; 
      xSTART      : in  std_logic; 
      xDONE       : in  std_logic; 
      xCLR_ALL    : in  std_logic; 
      xADC        : in  std_logic_vector(15 downto 0); 
		xPRCO_INT 	: in  std_logic_vector(11 downto 0);
		xPROVDD 		: in  std_logic_vector(11 downto 0);
		xRCO_INT 	: in  std_logic_vector(11 downto 0);
		xROVDD 		: in  std_logic_vector(11 downto 0);
		xWBIAS_INT	: in  std_logic_vector(11 downto 0);
		xWBIAS 		: in  std_logic_vector(11 downto 0);			 
		xPED_SCAN  	: in  std_logic_vector(11 downto 0);
		xPED_ADDR  	: in  std_logic_vector(14 downto 0);
		xDEBUG 	  	: in  std_logic_vector(15 downto 0);
		xFPGA_DATA  : out std_logic_vector(15 downto 0); 
      xRADDR      : out std_logic_vector(11 downto 0));
end MESS; 

architecture Behavioral of MESS is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is ( HDR_START,	ADC,
								PRCO_INT,	PROVDD,
								RCO_INT,		ROVDD,
								WBIAS_INT, 	WBIAS,
								PED_SCAN,	PED_ADDR,	DEBUG,
								HDR_END,		GND_STATE);
	signal STATE 			: STATE_TYPE;
	signal RADDR			: std_logic_vector(11 downto 0);
	signal FPGA_DATA		: std_logic_vector(15 downto 0);
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component BUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	xBUF_FPGA_DATA : BUF_BUS
	generic map(bus_width => 16)
	port map (
		I => FPGA_DATA,
		O => xFPGA_DATA);
--------------------------------------------------------------------------------
	xBUF_RADDR : BUF_BUS
	generic map(bus_width => 12)
	port map (
		I => RADDR,
		O => xRADDR);
--------------------------------------------------------------------------------
	process(xSLWR,xSTART,xDONE,xCLR_ALL)
	begin
		if xCLR_ALL = '1' or xDONE = '1' then
			RADDR 		<= (others=>'0');
			FPGA_DATA 	<= (others=>'0');
			STATE 		<= HDR_START;
		elsif falling_edge(xSLWR) and xSTART = '1' then
--------------------------------------------------------------------------------			
			case STATE is
--------------------------------------------------------------------------------	
				when HDR_START =>	
					FPGA_DATA <= x"1234";
					RADDR <= (others=>'0');
					STATE <= ADC;	
--------------------------------------------------------------------------------					
				when ADC =>	
					FPGA_DATA <= xADC;
					RADDR <= RADDR + 1;
					if RADDR = 4095 then --8 windows
--					if RADDR = 3071 then --6 windows
						RADDR <= (others=>'0');
						STATE <= PRCO_INT;	
					end if;
--------------------------------------------------------------------------------			
				when PRCO_INT =>	
					FPGA_DATA <= x"0" & xPRCO_INT;		
					STATE <= PROVDD;	
--------------------------------------------------------------------------------			
				when PROVDD =>	
					FPGA_DATA <= x"0" & xPROVDD;		
					STATE <= RCO_INT;	
--------------------------------------------------------------------------------			
				when RCO_INT =>	
					FPGA_DATA <= x"0" & xRCO_INT;		
					STATE <= ROVDD;	
--------------------------------------------------------------------------------			
				when ROVDD =>	
					FPGA_DATA <= x"0" & xROVDD;		
					STATE <= WBIAS_INT;	
--------------------------------------------------------------------------------			
				when WBIAS_INT =>	
					FPGA_DATA <= x"0" & xWBIAS_INT;		
					STATE <= WBIAS;	
--------------------------------------------------------------------------------			
				when WBIAS =>	
					FPGA_DATA <= x"0" & xWBIAS;		
					STATE <= PED_SCAN;	
--------------------------------------------------------------------------------			
				when PED_SCAN =>	
					FPGA_DATA <= x"0" & xPED_SCAN;		
					STATE <= PED_ADDR;	
--------------------------------------------------------------------------------	
				when PED_ADDR =>	
					FPGA_DATA <= '0' & xPED_ADDR;		
					STATE <= DEBUG;	
--------------------------------------------------------------------------------	
				when DEBUG =>	
					FPGA_DATA <= xDEBUG;		
					STATE <= HDR_END;	
--------------------------------------------------------------------------------	
				when HDR_END =>	
					FPGA_DATA <= x"4321";		
					STATE <= GND_STATE;	
--------------------------------------------------------------------------------	
				when GND_STATE =>			
					FPGA_DATA <= (others=>'0');
--------------------------------------------------------------------------------	
				when others =>	STATE<=HDR_START;																
			end case;
		end if;
	end process;		
--------------------------------------------------------------------------------		
end Behavioral;