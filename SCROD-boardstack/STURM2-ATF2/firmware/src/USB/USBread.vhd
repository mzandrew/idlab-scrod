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
		xRESET    		: in  std_logic;	--MCF; active low
      xWBUSY    		: in  std_logic;
      xFIFOADR  		: out std_logic_vector (1 downto 0);
      xRBUSY    		: out std_logic;
      xSLOE     		: out std_logic;
      xSLRD     		: out std_logic;
      xSYNC_USB 		: out std_logic;
      xSOFT_TRIG		: out std_logic;
-- 2011-01 mza - to be implemented:
--		xSOFTWARE_REQUESTS_THAT_WE__SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY				: out std_logic;
--		xSOFTWARE_REQUESTS_THAT_WE__DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION	: out std_logic;
--		xSOFTWARE_REQUESTS_THAT_WE__TRANSFER_DIGITIZED_DATA_TO_FPGA_RAM_BUFFER			: out std_logic;
--		xSOFTWARE_REQUESTS_THAT_WE__TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB				: out std_logic;
		xVCAL				: out std_logic;
		xPED_SCAN		: out std_logic_vector (11 downto 0);
		xPED_EN			: out std_logic;
		xSOFTWARE_TRIGGERS_ARE_ENABLED : out std_logic;
		xEXTERNAL_TRIGGERS_ARE_ENABLED : out std_logic;
		xTRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB : out std_logic;
		xDEBUG 		  	: out std_logic_vector (15 downto 0);
      xTOGGLE   		: out std_logic;
		Locmd_DEBUG		: out std_logic_vector(3 downto 0);	--MCF; for debugging
		Hicmd_DEBUG		: out std_logic);	--MCF; for debugging
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
	signal SOFT_TRIG		: std_logic; -- SOFT_TRIG = a request to set TRIG, below, which in turn drives xSOFT_TRIG
	signal TRIG				: std_logic;
	signal VCAL				: std_logic;
	signal DEBUG	    	: std_logic_vector (15 downto 0);
   signal PED_SCAN    	: std_logic_vector (11 downto 0);
	signal PED_EN	   	: std_logic;
	signal SYNC_USB		: std_logic;
	signal SLRD				: std_logic;
	signal SLOE				: std_logic;
	signal RBUSY			: std_logic;
	signal FIFOADR    	: std_logic_vector (1 downto 0);
	signal TX_LENGTH     : std_logic_vector (13 downto 0);
	signal SOFTWARE_TRIGGERS_ARE_ENABLED : std_logic;
	signal EXTERNAL_TRIGGERS_ARE_ENABLED : std_logic;
	signal REQUEST_TO_TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB : std_logic;
	signal TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB : std_logic;
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
	xBUF_PED_EN : BUF
	port map (
		I => PED_EN,
		O => xPED_EN);
--------------------------------------------------------------------------------
Locmd_DEBUG <=	Locmd(3 downto 0);
Hicmd_DEBUG <= Hicmd(0);
--------------------------------------------------------------------------------
	xSOFTWARE_TRIGGERS_ARE_ENABLED <= SOFTWARE_TRIGGERS_ARE_ENABLED;
	xEXTERNAL_TRIGGERS_ARE_ENABLED <= EXTERNAL_TRIGGERS_ARE_ENABLED;
	xTRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB <= TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB;
--------------------------------------------------------------------------------
	software_state_machine : process(xIFCLK, xRESET, xDONE)
	variable delay : integer range 0 to 10;
	begin
		if xRESET = '0' then
			SYNC_USB		<= '0';
			SOFT_TRIG	<= '0';
			VCAL			<= '0';
			PED_EN		<= '0';
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
			SOFTWARE_TRIGGERS_ARE_ENABLED <= '0';
			EXTERNAL_TRIGGERS_ARE_ENABLED <= '1';
			REQUEST_TO_TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB <= '0';	--MCF; moved from trigger_control process
		elsif rising_edge(xIFCLK) then
			SLOE 			<= '1';
			SLRD 			<= '1';			
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			SOFT_TRIG	<= '0';
			RBUSY 		<= '1';
			SOFTWARE_TRIGGERS_ARE_ENABLED <= '1';	--MCF; forcing this to be 1 unless RESET is active
--------------------------------------------------------------------------------				
			case	state is	
--------------------------------------------------------------------------------
				when st1_WAIT =>
					RBUSY <= '0';						 
					if xFLAGA = '1' then	
--						RBUSY <= '1';	--MCF; redundant line?
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
-----------       Software People only care about this part :-p    -------------
--------------------------------------------------------------------------------
						when x"01" =>	--USE SYNC signal
							SYNC_USB <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD "XXXX-XXXX-XXXX-XXXD"
							
						when x"02" =>	--SOFT_TRIG
							SOFT_TRIG <= '1';	 		
							state <= st1_WAIT;		--HICMD =>"XXXX-XXXX-XXXX-XXXX"
						
						when x"03" =>	--PED_SCAN, A.K.A "linearity via DAC SCAN"
							PED_SCAN <=  Hicmd(11 downto 0);	
							state <= st1_WAIT;		--HICMD =>"XXXX-DDDD-DDDD-DDDD"

						when x"04" =>  -- en_ped / ped_en
							PED_EN <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD =>"DDDD-DDDD-DDDD-DDDD"
							
						when x"05" =>	--VCAL signal
							VCAL <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD "XXXX-XXXX-XXXX-XXXD"

						when x"06" =>	-- fetch data from fpga's buffer
							if xDONE <= '0' then	--MCF; added to gain the functionality of trigger_control
								REQUEST_TO_TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB <= '1';	 		
							end if;
							state <= st1_WAIT;		--HICMD =>"XXXX-XXXX-XXXX-XXXX"

						when x"07" =>	-- enableÅ@/ disable software triggers' ability to sample data, wilkinson it and transfer it to fpga ram
							--SOFTWARE_TRIGGERS_ARE_ENABLED <= Hicmd(0);	--MCF; temporary change to make software work
							state <= st1_WAIT;		--HICMD =>"XXXX-XXXX-XXXX-XXXX"

						when x"08" =>	-- enableÅ@/ disable external triggers' ability to sample data, wilkinson it and transfer it to fpga ram
							EXTERNAL_TRIGGERS_ARE_ENABLED <= Hicmd(0);
							state <= st1_WAIT;		--HICMD =>"XXXX-XXXX-XXXX-XXXX"
							
						when x"FF" =>	--W_STRB
							DEBUG <= Hicmd(15 downto 0);
							state <= st1_WAIT;		--HICMD "DDDD-DDDD-DDDD-DDDD"
							
--------------------------------------------------------------------------------
-----------       Software People stop caring at this point  ^_^   -------------
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
	end process software_state_machine;
--------------------------------------------------------------------------------	
	trigger_control : process(xIFCLK,xRESET,xDONE) 
	begin
		if xRESET = '0' or xDONE = '1' then
			TRIG <= '0';
			--REQUEST_TO_TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB <= '0';	--MCF; moved to software_state_machine process
		elsif falling_edge(xIFCLK) then
			if SOFT_TRIG = '1' then
				TRIG <= '1';
			end if;
			if REQUEST_TO_TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB = '1' then
				TRANSFER_FPGA_RAM_BUFFER_TO_PC_VIA_USB <= '1';	--MCF; noticed that this never becomes 0 ever again
			end if;
		end if;
	end process trigger_control;
--------------------------------------------------------------------------------	
end Behavioral;
