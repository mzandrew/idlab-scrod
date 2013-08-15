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
--		xCAL		 	 : out std_logic;	--MCF; trying out CAL_P <= CAL_N in STURM2_IO
		-- User I/O
--		xNRUN		 	 : out std_logic; -- mza - this did nothing
		xCLK			 : in  std_logic;--150 MHz CLK
		xCLK_75MHz	 : in  std_logic;--75  MHz CLK
		xPED_EN	 	 : in  std_logic;
		xEXT_TRIG 	 : in  std_logic;
		xSOFT_TRIG 	 : in  std_logic;
		xSAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY : out std_logic; -- mza
		xDIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION : out std_logic; -- mza
		xSOFTWARE_TRIGGERS_ARE_ENABLED : in std_logic;
		xEXTERNAL_TRIGGERS_ARE_ENABLED : in std_logic;
		xTRIGGER : out std_logic;
		xCLR_ALL 	 : in  std_logic);
end STURM2_WR;

architecture Behavioral of STURM2_WR is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xBLOCK 		: std_logic;
--	signal CAL			: std_logic;	--MCF; trying out CAL_P <= CAL_N in STURM2_IO
	signal TSA_OUT	: std_logic_vector(3 downto 0);
	signal SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY				: std_logic; -- mza
	signal DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION	: std_logic; -- mza
	signal SOFTWARE_TRIGGER_IF_ENABLED : std_logic;
	signal EXTERNAL_TRIGGER_IF_ENABLED : std_logic;
	signal TRIGGER : std_logic;
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------	
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
	-- mza:
	component pulse_to_short_pulse
		port (
			i     : in    std_logic;
			clock : in    std_logic;
			o     :   out std_logic
		);
	end component;
--------------------------------------------------------------------------------
   component BUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
   end component;
--------------------------------------------------------------------------------
begin
	xTRIGGER <= TRIGGER;
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
--	xBUF_CAL : BUF --MCF; trying out CAL_P <= CAL_N in STURM2_IO instead
--	port map (
--		I  => CAL,
--		O  => xCAL);
--------------------------------------------------------------------------------
--	CAL <= xCLK and not(xBLOCK);
--generate_short_cal_pulse : pulse_to_short_pulse	--MCF; Gary recommended this as an alternative to the previous line
--port map (
--	i => not(xBLOCK),
--	clock => xCLK,
--	o => CAL);
--------------------------------------------------------------------------------			
-- mza note:  got rid of this; it's not connected to anything
--	xBUF_NRUN : BUF 
--	port map (
--		I  => xSOFT_TRIG,
--		I  => xSOFT_TRIG or xEXT_TRIG,
--		O  => xNRUN);		
--------------------------------------------------------------------------------
	SOFTWARE_TRIGGER_IF_ENABLED <= xSOFT_TRIG and xSOFTWARE_TRIGGERS_ARE_ENABLED;
	EXTERNAL_TRIGGER_IF_ENABLED <=  xEXT_TRIG and xEXTERNAL_TRIGGERS_ARE_ENABLED;
	TRIGGER <= SOFTWARE_TRIGGER_IF_ENABLED or EXTERNAL_TRIGGER_IF_ENABLED;
--------------------------------------------------------------------------------
	-- this takes the actual external trigger input signal (which is delayed by 22ns)
	-- and outputs a short pulse (delayed further by 1ns) to initiate sampling
	-- this pulse is between 1 and 2 periods of the 150MHz clock (~7ns to ~14ns)
	generate_short_sampling_pulse : pulse_to_short_pulse
	port map (
		i => TRIGGER,
		clock => xCLK,
		o => SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY
	);
	xSAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY <= SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY;
--------------------------------------------------------------------------------
	-- this takes the sampling pulse above and generates another 7-14ns pulse that occurs
	-- right after the above pulse ends to initiate wilkinson conversion inside the ASIC
	generate_short_wilkinsoning_pulse : pulse_to_short_pulse
	port map (
		i => not SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY,
		clock => xCLK,
		o => DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION
	);
	xDIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION <= DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION;
--------------------------------------------------------------------------------
--		TSA_OUT <= xSOFT_TRIG & '1' & '1' & '1';
		TSA_OUT <= xSOFT_TRIG & xSOFT_TRIG & xSOFT_TRIG & xSOFT_TRIG;  -- GSV
--		TSA_OUT <= xEXT_TRIG & xEXT_TRIG & xEXT_TRIG & xEXT_TRIG;  -- GSV
--		TSA_OUT <= '0' & '0' & xEXT_TRIG & '0';
	-- TSA_OUT modified by mza to go back to the original behavior of only sampling a single batch of 8 samples:
--		TSA_OUT <= '0' & '0' & SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY & '0'; -- mza
--		TSA_OUT <= (0 => TRIGGER, others => '0');	--MCF
--------------------------------------------------------------------------------	
	-- mza's note to self:  a TSA delay scheme inside the FPGA will never work at 150MHz unless the sampling rate is ~1GHz
--------------------------------------------------------------------------------	
	xBUF_TSA_OUT : BUF_BUS
	generic map(bus_width => 4)
	port map (
		I => TSA_OUT,
		O => xTSA_OUT);
--------------------------------------------------------------------------------
end Behavioral;
