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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity USBread is
   port ( 
		xIFCLK     		: in  std_logic;
      xDONE    		: in  std_logic;
      xUSB_DATA  		: in  std_logic_vector (15 downto 0);
      xFLAGA    		: in  std_logic;
		xRESET    		: in  std_logic;
      xWBUSY    		: in  std_logic;
      xFIFOADR  		: out std_logic_vector (1 downto 0);
      xRBUSY    		: out std_logic;
      xSLOE     		: out std_logic;
      xSLRD     		: out std_logic;
      xSYNC_USB 		: out std_logic;
      xSOFT_TRIG		: out std_logic;
		xVCAL				: out std_logic;
		xPED_SCAN		: out std_logic_vector (11 downto 0);
		xPED_ADDR		: out std_logic_vector (14 downto 0);
		xDEBUG 		  	: out std_logic_vector (15 downto 0);
      xTOGGLE   		: out std_logic;
		SOFT_VADJN1   : out std_logic_vector (11 downto 0);
		SOFT_VADJN2   : out std_logic_vector (11 downto 0);
		SOFT_VADJP1   : out std_logic_vector (11 downto 0);
		SOFT_VADJP2   : out std_logic_vector (11 downto 0);
		SOFT_RW_ADDR  : out std_logic_vector (8 downto 0);
		SOFT_PROVDD   : out std_logic_vector (11 downto 0);
		SOFT_TIABIAS  : out std_logic_vector (11 downto 0));
end USBread;

architecture BEHAVIORAL of USBread is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type State_type is(st1_WAIT,
							st1_READ, st2_READ, st3_READ,st4_READ,
							st1_SAVE, st1_TARGET, ENDDELAY);
	signal state: State_type;
	signal dbuffer			: std_logic_vector (15 downto 0);
	signal Locmd			: std_logic_vector (15 downto 0);
	signal Hicmd			: std_logic_vector (15 downto 0);
	signal again			: std_logic_vector (1 downto 0);
	signal TOGGLE			: std_logic;
	signal SOFT_TRIG		: std_logic;
	signal TRIG				: std_logic;
	signal VCAL				: std_logic;
	signal DEBUG	    	: std_logic_vector (15 downto 0);
   signal PED_SCAN    	: std_logic_vector (11 downto 0);
	signal PED_ADDR	   : std_logic_vector (14 downto 0);
	signal SYNC_USB		: std_logic;
	signal SLRD				: std_logic;
	signal SLOE				: std_logic;
	signal RBUSY			: std_logic;
	signal FIFOADR    	: std_logic_vector (1 downto 0);
	signal TX_LENGTH     : std_logic_vector (13 downto 0);
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
	xBUF_TOGGLE : BUF 
	port map (
		I  => TOGGLE,
		O  => xTOGGLE);	
--------------------------------------------------------------------------------	
	xBUF_SLOE : BUF 
	port map (
		I  => SLOE,
		O  => xSLOE);	
--------------------------------------------------------------------------------	
	xBUF_SLRD : BUF 
	port map (
		I  => SLRD,
		O  => xSLRD);	
--------------------------------------------------------------------------------	
	xBUF_RBUSY : BUF 
	port map (
		I  => RBUSY,
		O  => xRBUSY);	
--------------------------------------------------------------------------------	
	xBUF_SYNC_USB : BUF 
	port map (
		I  => SYNC_USB,
		O  => xSYNC_USB);	
--------------------------------------------------------------------------------
	xBUF_FIFOADR : BUF_BUS
	generic map(bus_width => 2)
	port map (
		I => FIFOADR,
		O => xFIFOADR);
--------------------------------------------------------------------------------		
	xBUF_SOFT_TRIG : BUF 
	port map (
		I  => TRIG,
		O  => xSOFT_TRIG);	
--------------------------------------------------------------------------------		
	xBUF_VCAL : BUF 
	port map (
		I  => VCAL,
		O  => xVCAL);	
--------------------------------------------------------------------------------	
	xBUF_DEBUG : BUF_BUS
	generic map(bus_width => 16)
	port map (
		I => DEBUG,
		O => xDEBUG);
--------------------------------------------------------------------------------
	xBUF_PED_SCAN : BUF_BUS
	generic map(bus_width => 12)
	port map (
		I => PED_SCAN,
		O => xPED_SCAN);
--------------------------------------------------------------------------------
	xBUF_PED_ADDR : BUF_BUS
	generic map(bus_width => 15)
	port map (
		I => PED_ADDR,
		O => xPED_ADDR);
--------------------------------------------------------------------------------
	process(xIFCLK, xRESET)
	variable delay : integer range 0 to 10;
	begin
		if xRESET = '0' then
			SYNC_USB		<= '0';
			SOFT_TRIG	<= '0';
			VCAL			<= '0';
			DEBUG			<= (others=>'0');
			PED_SCAN		<= x"8FF";
			SLRD 			<= '1';
			SLOE 			<= '1';
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			again 		<= "00";
			RBUSY 		<= '1';
			delay 		:= 0;	
			state       <= st1_WAIT;
			SOFT_VADJN1 <= x"3AC";
			SOFT_VADJN2 <= x"3AC";
			SOFT_VADJP1 <= x"000";
			SOFT_VADJP2 <= x"000";
			SOFT_PROVDD <= x"FFF";
			SOFT_TIABIAS <= x"348";
			SOFT_RW_ADDR(8 downto 0) <= (others => '0');
		elsif rising_edge(xIFCLK) then
			SLOE 			<= '1';
			SLRD 			<= '1';			
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			SOFT_TRIG	<= '0';
			RBUSY 		<= '1';
--------------------------------------------------------------------------------				
			case	state is	
--------------------------------------------------------------------------------
				when st1_WAIT =>
					RBUSY <= '0';						 
					if xFLAGA = '1' then	
						RBUSY <= '1';
						if xWBUSY = '0' then		
							RBUSY <= '1';
							state <= st1_READ;
						end if;
					end if;		 
--------------------------------------------------------------------------------		
				when st1_READ =>
					FIFOADR <= "00";	
					TOGGLE <= '1';		
					if delay = 2 then
						delay := 0;
						state <= st2_READ;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------					
				when st2_READ =>	
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						state <= st3_READ;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------						
				when st3_READ =>					
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					SLRD <= '0';
					dbuffer <= xUSB_DATA;
					if delay = 2 then
						delay := 0;
						state <= st4_READ;
					else
						delay := delay +1;
					end if;					
--------------------------------------------------------------------------------					   
				when st4_READ =>					
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						state <= st1_SAVE;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------	
				when st1_SAVE	=>
					FIFOADR <= "00";
					TOGGLE <= '1';	
--------------------------------------------------------------------------------						
					case again is 
						when "00" =>	
							again <="01";	
							Locmd <= dbuffer;
							state <= ENDDELAY;
--------------------------------------------------------------------------------	
						when "01" =>
							again <="00";	
							Hicmd <= dbuffer;	
							state <= st1_TARGET;
--------------------------------------------------------------------------------	
						when others =>				
							state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when st1_TARGET =>
					RBUSY <= '0';
					case Locmd(7 downto 0) is
--------------------------------------------------------------------------------
-----------       Software commands                                -------------
--------------------------------------------------------------------------------
						when x"01" =>	--USE SYNC signal
							SYNC_USB <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD "XXXX-XXXX-XXXX-XXXD"
							
						when x"02" =>	--SOFT_TRIG
							SOFT_TRIG <= '1';	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"
						
						when x"03" =>	--PED_SCAN, A.K.A "linearity via DAC SCAN"
							PED_SCAN <=  Hicmd(11 downto 0);	
							state <= st1_WAIT;		--HICMD =>"XXX-DDDD-DDDD-DDDD"

						when x"04" =>	--PED_ADDR
							PED_ADDR(14 downto 6) <=  Hicmd(14 downto 6);	
							PED_ADDR(5 downto 0)  <=  "00" & x"0";
							state <= st1_WAIT;		--HICMD =>"DDDD-DDDD-DDDD-DDDD"
							
						when x"05" =>	--VCAL signal
							VCAL <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD "XXXX-XXXX-XXXX-XXXD"

                  when x"06" =>  --Change VADJN1
							SOFT_VADJN1(11 downto 0) <= Hicmd(11 downto 0);
							state <= st1_WAIT;
							
                  when x"07" =>  --Change VADJN2
							SOFT_VADJN2(11 downto 0) <= Hicmd(11 downto 0);
							state <= st1_WAIT;
							
                  when x"08" =>  --Change VADJP1
							SOFT_VADJP1(11 downto 0) <= Hicmd(11 downto 0);
							state <= st1_WAIT;
							
                  when x"09" =>  --Change VADJP2
							SOFT_VADJP2(11 downto 0) <= Hicmd(11 downto 0);
							state <= st1_WAIT;
							
                  when x"0A" =>  --Change READ/WRITE address
							SOFT_RW_ADDR(8 downto 0) <= Hicmd(8 downto 0);
							state <= st1_WAIT;

                  when x"0B" =>  --Change PROVDD
                     SOFT_PROVDD(11 downto 0) <= Hicmd(11 downto 0);
                     state <= st1_WAIT;							
							
                  when x"0C" =>  --Change TIA bias
                     SOFT_TIABIAS(11 downto 0) <= Hicmd(11 downto 0);
                     state <= st1_WAIT;							
							
						when x"FF" =>	--W_STRB
							DEBUG <= Hicmd(15 downto 0);
							state <= st1_WAIT;		--HICMD "DDDD-DDDD-DDDD-DDDD"
							
--------------------------------------------------------------------------------
-----------       End of software commands   -------------
--------------------------------------------------------------------------------
						when others =>
							state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when ENDDELAY =>	
					FIFOADR <= "00"; 
					if delay = 2 then
						if xFLAGA = '1' then
							delay := 0;
							state <= st1_READ;
						else
							delay := 0;
							state <= st1_WAIT;
						end if;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------						
				when others =>
					state <= st1_WAIT;
			end case;	  
		end if;
	end process;
--------------------------------------------------------------------------------	
	process(xIFCLK,xRESET,xDONE) 
	begin
		if xRESET = '0' or xDONE = '1' then
			TRIG <= '0';
		elsif falling_edge(xIFCLK) then
			if SOFT_TRIG = '1' then
				TRIG <= '1';
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------	
end Behavioral;
