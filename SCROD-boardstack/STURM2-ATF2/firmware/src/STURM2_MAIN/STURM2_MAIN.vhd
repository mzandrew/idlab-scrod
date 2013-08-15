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
-- Design by: Larry L. Ruckman Jr. 															--
-- Modified by:  GSV					 															--
-- DATE : 03 Jan 2010																			--
-- Project name: STURM2 eval board firmware												--
--	Module name: STURM2_MAIN.vhd		  															--
--	Description : 																					--
-- 	CLK distribution/generation block													--
--		  											    												--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity STURM2_MAIN is
    port (
		-- STURM2 ASIC I/Os
		RAMP	 		 : out std_logic; 
		TST_START 	 : out std_logic; 
		TST_CLR	 	 : out std_logic; 
		TST_OUT		 : in  std_logic;
		SMPL_SEL		 : out std_logic_vector(4 downto 0);
		DAT			 : in  std_logic_vector(11 downto 0);
		CH_SEL		 : out std_logic_vector(3 downto 0);
		TDC_START	 : out std_logic; 
		TDC_STOP		 : out std_logic; 
		TDC_CLR		 : out std_logic; 
		MRCO		 	 : in  std_logic;
		TSA_IN		 : in  std_logic_vector(3 downto 0);
		TSA_OUT		 : out std_logic_vector(3 downto 0);
		CAL_P			 : out std_logic; 
		CAL_N			 : in std_logic;	--MCF; used to be out.  trying out CAL_P <= CAL_N in STURM2_IO instead
		-- User I/O
		xCLK			 : in std_logic;--150 MHz CLK
		xCLK_INV		 : in std_logic;--MCF
		xCLK_75MHz	 : in std_logic;--75  MHz CLK
		xEXT_TRIG	 : in  std_logic;
		xSOFT_TRIG	 : in  std_logic;
		xSOFTWARE_TRIGGERS_ARE_ENABLED : in std_logic;
		xEXTERNAL_TRIGGERS_ARE_ENABLED : in std_logic;
		xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM : out std_logic; -- mza
		xRAMP_DONE 	 : out std_logic;
		xDAT		 	 : out std_logic_vector(11 downto 0);
		xDONE		 	 : in  std_logic;
		xPED_EN	 	 : in  std_logic;
		xRAMP	 		 : out std_logic;	--MCF; not buffered. for debugging
		xADC			 : out std_logic_vector(11 downto 0);
		xRADDR    	 : in  std_logic_vector(9 downto 0);		
		xMON_HDR	 	 : out std_logic_vector(15 downto 0);
		xTST_START 	 : in  std_logic; 
		xTST_CLR	 	 : in  std_logic; 
		xTST_OUT		 : out std_logic;
		xMRCO		 	 : out std_logic;
		xCLR_ALL 	 : in  std_logic;
		TDC_START_NOT_BUFFERED	: out std_logic;	--MCF; for debugging
		TDC_STOP_NOT_BUFFERED	: out std_logic;	--MCF; for debugging
		TDC_CLR_NOT_BUFFERED	: out std_logic;	--MCF; for debugging
		TSA_OUT_NOT_BUFFERED : out std_logic);	--MCF; for debugging
-- 2011-01 mza - to be implemented:
--		xTRANSFER_DIGITIZED_DATA_TO_FPGA_RAM_BUFFER			: out std_logic; -- this gets done automatically right after the wilkonsoning
end STURM2_MAIN;

architecture Behavioral of STURM2_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xSTATUS	   : std_logic_vector(3 downto 0);
	signal xMON	 		: std_logic_vector(31 downto 0);
	signal RAMPING	 	: std_logic; 
	signal xSMPL_SEL	: std_logic_vector(4 downto 0);
	signal DATA			: std_logic_vector(11 downto 0);
	signal xCH_SEL	 	: std_logic_vector(3 downto 0);
	signal xTDC_START	: std_logic; 
	signal xTDC_STOP	: std_logic; 
	signal xTDC_CLR	: std_logic; 
	signal xTSA_IN	 	: std_logic_vector(3 downto 0);
	signal xTSA_OUT 	: std_logic_vector(3 downto 0);
--	signal xCAL			: std_logic;	--MCF; trying out CAL_P <= CAL_N in STURM2_IO instead
--	signal xNRUN	: std_logic; 
	signal RAMP_DONE	 : std_logic;
	signal xW_EN		 : std_logic;
--	signal xEXT_TRIG	 : std_logic;
	signal SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY				: std_logic; -- mza
	signal DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION	: std_logic; -- mza
	signal THERE_IS_NEW_DATA_IN_THE_FPGA_RAM						: std_logic; -- mza
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component STURM2_IO
   port( 
		-- STURM2 ASIC I/Os
		RAMP	 		 : out std_logic; 
		TST_START 	 : out std_logic; 
		TST_CLR	 	 : out std_logic; 
		TST_OUT		 : in  std_logic;
		SMPL_SEL		 : out std_logic_vector(4 downto 0);
		DAT			 : in  std_logic_vector(11 downto 0);
		CH_SEL		 : out std_logic_vector(3 downto 0);
		TDC_START	 : out std_logic; 
		TDC_STOP		 : out std_logic; 
		TDC_CLR		 : out std_logic; 
		MRCO		 	 : in  std_logic;
		TSA_IN		 : in  std_logic_vector(3 downto 0);
		TSA_OUT		 : out std_logic_vector(3 downto 0);
		CAL_P			 : out std_logic; 
		CAL_N			 : in std_logic;	--MCF; used to be out.  trying out CAL_P <= CAL_N instead
		-- User I/O
		xRAMP	 		 : in  std_logic; 
		xTST_START 	 : in  std_logic; 
		xTST_CLR	 	 : in  std_logic; 
		xTST_OUT		 : out std_logic;
		xSMPL_SEL	 : in  std_logic_vector(4 downto 0);
		xDAT			 : out std_logic_vector(11 downto 0);
		xCH_SEL		 : in  std_logic_vector(3 downto 0);
		xTDC_START	 : in  std_logic; 
		xTDC_STOP	 : in  std_logic; 
		xTDC_CLR		 : in  std_logic; 
		xMRCO		 	 : out std_logic;
		xTSA_IN		 : out std_logic_vector(3 downto 0);
		xTSA_OUT		 : in  std_logic_vector(3 downto 0));
--		xCAL			 : in  std_logic);	--MCF; trying out CAL_P <= CAL_N instead
   end component;
--------------------------------------------------------------------------------	
   component STURM2_WR
	Port( 	
		-- STURM2 ASIC I/Os
		xTSA_IN		 : in  std_logic_vector(3 downto 0);
		xTSA_OUT		 : out std_logic_vector(3 downto 0);
--		xCAL		 	 : out std_logic;	--MCF; trying out CAL_P <= CAL_N in STURM2_IO instead
		-- User I/O
--		xNRUN		 	 : out std_logic;
		xCLK			 : in std_logic;--150 MHz CLK
		xCLK_75MHz	 : in std_logic;--75  MHz CLK
		xPED_EN	 	 : in  std_logic;
		xEXT_TRIG 	 : in  std_logic;
		xSOFT_TRIG 	 : in  std_logic;
		xSAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY : out std_logic; -- mza
		xDIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION : out std_logic; -- mza
		xSOFTWARE_TRIGGERS_ARE_ENABLED : in std_logic;
		xEXTERNAL_TRIGGERS_ARE_ENABLED : in std_logic;
		xTRIGGER : out std_logic;
		xCLR_ALL 	 : in  std_logic);
   end component;
--------------------------------------------------------------------------------	
   component STURM2_RD
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
		xCLK			 : in std_logic;--150 MHz CLK
		xCLK_INV		 : in std_logic;--MCF
		xCLK_75MHz	 : in std_logic;--75  MHz CLK
		xADC			 : out std_logic_vector(11 downto 0);
		xSTATUS	    : out std_logic_vector(3 downto 0);
		xINITIATE_WILKINSON_AND_THEN_TRANSFER_TO_FPGA_RAM 	 : in  std_logic; -- mza
		xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM 	 					 : out std_logic; -- mza
		xDONE		 	 : in  std_logic;
		xRAMP_DONE 	 : out std_logic;
		xW_EN			 : out std_logic;
		xRADDR    	 : in  std_logic_vector(9 downto 0);		
		xCLR_ALL 	 : in  std_logic);
   end component;
--------------------------------------------------------------------------------
   component BUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component INV
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of INV : component is "BLACK_BOX";
--------------------------------------------------------------------------------
	component CHIPSCOPE_MON
	generic(
		xUSE_CHIPSCOPE	: integer := 1);  -- Set to 1 to use Chipscope 
	port ( 
		xMON	: in  std_logic_vector(31 downto 0);
		xCLK	: in  std_logic);	
   end component;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------	
	xMON_HDR <= xMON(15 downto 0);
	-- xTDC_START xTDC_STOP xTDC_CLR RAMP_DONE xW_EN
	xMON(0)  <= xCH_SEL(0); -- this is overridden by top.vhd
	xMON(1)  <= xCH_SEL(1); -- this is overridden by top.vhd
	xMON(2)  <= xCH_SEL(2);
	xMON(3)  <= xCH_SEL(3);
	xMON(4)  <= xSMPL_SEL(0);
	xMON(5)  <= xSMPL_SEL(1);
	xMON(6)  <= xSMPL_SEL(2);
	xMON(7)  <= xSMPL_SEL(3);
	xMON(8)  <= xSMPL_SEL(4);
--	xMON(9)  <= xCLK;
	xMON(9)  <= xEXT_TRIG; -- mza
--	xMON(10) <= '0';
	xMON(11) <= SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY; -- mza
	xMON(12) <= xEXTERNAL_TRIGGERS_ARE_ENABLED;
	xMON(13) <= DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION; -- mza
	xMON(14) <= xSOFTWARE_TRIGGERS_ARE_ENABLED;
	xMON(15) <= THERE_IS_NEW_DATA_IN_THE_FPGA_RAM; -- mza
--------------------------------------------------------------------------------	
--	xMON(16) <= xCLK;	MCF; caused gated clock errors
	xMON(17) <= xCLR_ALL;
	xMON(18) <= xDONE;
	xMON(19) <= RAMPING;
	--xMON(31 downto 20) <= DATA;
	xMON(31 downto 20) <= x"00" & xSTATUS;
	--xMON(31 downto 20) <= x"000";
--------------------------------------------------------------------------------	
	xCHIPSCOPE_MON : CHIPSCOPE_MON
	generic map(
		xUSE_CHIPSCOPE => 0)	--set to 1 to use the ILA
	port map (
		xCLK => xCLK,
		xMON => xMON);
--------------------------------------------------------------------------------	
	xSTURM2_IO : STURM2_IO 
	port map (
		-- STURM2 ASIC I/Os
		RAMP  		=> RAMP,
		TST_START  	=> TST_START,
		TST_CLR  	=> TST_CLR,
		TST_OUT  	=> TST_OUT,
		SMPL_SEL  	=> SMPL_SEL,
		DAT  			=> DAT,
		CH_SEL  		=> CH_SEL,
		TDC_START  	=> TDC_START,
		TDC_STOP  	=> TDC_STOP,
		TDC_CLR  	=> TDC_CLR,
		MRCO  		=> MRCO,
		TSA_IN  		=> TSA_IN,
		TSA_OUT  	=> TSA_OUT,
		CAL_P  		=> CAL_P,
		CAL_N  		=> CAL_N,
		-- User I/O
		xRAMP  		=> RAMPING,
		xTST_START  => xTST_START,
		xTST_CLR  	=> xTST_CLR,
		xTST_OUT  	=> xTST_OUT,
		xSMPL_SEL  	=> xSMPL_SEL,
		xDAT  		=> DATA,
		xCH_SEL  	=> xCH_SEL,
		xTDC_START  => xTDC_START,
		xTDC_STOP  	=> xTDC_STOP,
		xTDC_CLR  	=> xTDC_CLR,
		xMRCO  		=> xMRCO,
		xTSA_IN  	=> xTSA_IN,
		xTSA_OUT  	=> xTSA_OUT);
--		xCAL  		=> xCAL);	--MCF; trying out CAL_P <= CAL_N instead
--------------------------------------------------------------------------------
	xSTURM2_WR : STURM2_WR
	port map (
		-- STURM2 ASIC I/Os
		xTSA_IN			=> xTSA_IN,
		xTSA_OUT			=> xTSA_OUT,
--		xCAL				=> xCAL,	--MCF; trying out CAL_P <= CAL_N in STURM2_IO instead
		-- User I/O
--		xNRUN				=> xNRUN,
		xCLK				=> xCLK,
		xCLK_75MHz		=> xCLK_75MHz,
		xPED_EN			=> xPED_EN,
		xEXT_TRIG		=> xEXT_TRIG,
		xSOFT_TRIG		=> xSOFT_TRIG,
		xSAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY => SAMPLE_ANALOG_SIGNAL_TO_CAPACITOR_ARRAY, -- mza
		xDIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION => DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION, -- mza
		xSOFTWARE_TRIGGERS_ARE_ENABLED => xSOFTWARE_TRIGGERS_ARE_ENABLED,
		xEXTERNAL_TRIGGERS_ARE_ENABLED => xEXTERNAL_TRIGGERS_ARE_ENABLED,
		xTRIGGER => xMON(10),
		xCLR_ALL			=> xCLR_ALL);
--------------------------------------------------------------------------------			
	xSTURM2_RD : STURM2_RD
	port map (
		xCH_SEL  	=> xCH_SEL,
		xSMPL_SEL  	=> xSMPL_SEL,
		xRAMP  		=> RAMPING,
		xDAT  		=> DATA,
		xTDC_START  => xTDC_START,
		xTDC_STOP   => xTDC_STOP,
		xTDC_CLR  	=> xTDC_CLR,
		-- User I/O
		xCLK			=> xCLK,
		xCLK_INV		=> xCLK_INV,	--MCF
		xCLK_75MHz	=> xCLK_75MHz,
		xADC			=> xADC,
		xSTATUS 		=> xSTATUS,
--		xINITIATE_WILKINSON_AND_THEN_TRANSFER_TO_FPGA_RAM	=> xSOFT_TRIG,
		xINITIATE_WILKINSON_AND_THEN_TRANSFER_TO_FPGA_RAM	=> DIGITIZE_SAMPLED_SIGNAL_VIA_WILKINSON_CONVERSION, -- mza
		xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM		=> THERE_IS_NEW_DATA_IN_THE_FPGA_RAM, -- mza
--		xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM		=> open,
		xRAMP_DONE	=> RAMP_DONE,
		xW_EN 		=> xW_EN,
		xDONE			=> xDONE,
		xCLR_ALL		=> xCLR_ALL,
		xRADDR		=> xRADDR);
--------------------------------------------------------------------------------			
--	SAMPLING_IS_COMPLETE <= not xEXT_TRIG;
--------------------------------------------------------------------------------	
-- this is section is to assign output ports that weren't already assigned by the instances		
	xRAMP <= RAMPING;
	xDAT  <= DATA;
	xRAMP_DONE <= RAMP_DONE;
	xTHERE_IS_NEW_DATA_IN_THE_FPGA_RAM <= THERE_IS_NEW_DATA_IN_THE_FPGA_RAM; -- mza
	TDC_START_NOT_BUFFERED <= xTDC_START;	--MCF; for debugging
	TDC_STOP_NOT_BUFFERED <= xTDC_STOP;	--MCF; for debugging
	TDC_CLR_NOT_BUFFERED <= xTDC_CLR;	--MCF; for debugging
	TSA_OUT_NOT_BUFFERED <= xTSA_OUT(0);	--MCF; for debugging
--------------------------------------------------------------------------------
end Behavioral;
