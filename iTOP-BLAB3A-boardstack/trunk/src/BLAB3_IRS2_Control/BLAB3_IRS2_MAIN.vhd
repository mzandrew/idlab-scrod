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
-- Design by: Kurtis Nishimura
-- Last updated: 2011-06-05
-- Notes: This firmware is to operate IRS2 or BLAB3 in 
--        "one-shot" mode, where the sample signal is 
--        given only when a software trigger is received.
--        It is primarily for simple evaluation.
--------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.numeric_std.all;

entity BLAB3_IRS2_MAIN is
    port (
		-- IRS ASIC I/Os
		ASIC_CH_SEL	 	  : out std_logic_vector(2 downto 0);
		ASIC_RD_ADDR	 	  : out std_logic_vector(9 downto 0);
		ASIC_SMPL_SEL 	  : out std_logic_vector(5 downto 0);
		ASIC_SMPL_SEL_ALL : out std_logic; 
		ASIC_RD_ENA	 	  : out std_logic; 
		ASIC_RAMP	 	 	  : out std_logic; 
		ASIC_DAT		     : in  std_logic_vector(11 downto 0);
		ASIC_TDC_START    : out std_logic; 
		ASIC_TDC_CLR	     : out std_logic; 
		ASIC_WR_STRB	     : out std_logic; 
		ASIC_WR_ADDR	     : out std_logic_vector(9 downto 0);
		sample_strobe_width_vector : in std_logic_vector(7 downto 0);
		autotrigger_enabled : in std_logic;
		ASIC_SSP_IN	     : out std_logic;
		ASIC_SST_IN	     : out std_logic;		
		ASIC_SSP_OUT	  : in std_logic;
		ASIC_TRIGGER     : in std_logic_vector(7 downto 0);
		SOFT_WRITE_ADDR     : in std_logic_vector(8 downto 0);
		SOFT_READ_ADDR     : in std_logic_vector(8 downto 0);		
		-- User I/O
		CLK			     : in  std_logic;--150 MHz CLK
		CLK_75MHz		  : in  std_logic;   --75  MHz CLK
		notCLK_75MHz		  : in  std_logic;--75  MHz CLK		
		START_USB_XFER	  : out std_logic;--Signal to start sending data to USB
		DONE_USB_XFER 	  : in  std_logic;
		MON_HDR		 	  : out std_logic_vector(15 downto 0); 
		CLR_ALL		 	  : in  std_logic;
		TRIGGER			  : in  std_logic;
		RAM_READ_ADDRESS : in std_logic_vector(9 downto 0);
		DATA_TO_USB      : out std_logic_vector(15 downto 0));
end BLAB3_IRS2_MAIN;

architecture Behavioral of BLAB3_IRS2_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is ( IDLE,
								START_SAMPLING,
								WAIT_FOR_SAMPLING,
								ADDRESS_TO_STORAGE1,
								WRITE_TO_STORAGE1,
								ADDRESS_TO_STORAGE2,
								WRITE_TO_STORAGE2,
								ARM_WILKINSON,
								PERFORM_WILKINSON,
								STORE_TO_RAM,
								ARM_READING,
								READ_TO_RAM,
								WAIT_FOR_READ_SETTLING,
								READOUT_BY_USB );
	signal xSTATE                  : STATE_TYPE;
	signal xCHIPSCOPE_MONITOR_BITS : std_logic_vector(31 downto 0);
	signal xRAM_OUTPUT_DATA        : std_logic_vector(15 downto 0);
	signal xRAM_READ_ENABLE        : std_logic;
	signal xRAM_WRITE_ADDRESS      : std_logic_vector(9 downto 0);
	signal xRAM_INPUT_DATA         : std_logic_vector(15 downto 0);
	signal xRAM_WRITE_ENABLE       : std_logic;
	signal xASIC_CH_SEL				 : std_logic_vector(2 downto 0);
	signal xASIC_SMPL_SEL				 : std_logic_vector(5 downto 0);
	
	signal csASIC_SSP_IN       : std_logic;
	signal csASIC_SST_IN       : std_logic;
   signal csASIC_WR_STRB      : std_logic;
   signal csASIC_RD_ENA       : std_logic;
	signal csASIC_TDC_CLR      : std_logic; 
	signal csASIC_TDC_START    : std_logic;
	signal csASIC_RAMP         : std_logic;
	signal csASIC_SMPL_SEL_ALL : std_logic;
	signal csSTART_USB_XFER   : std_logic;
	signal csDONE_USB_XFER    : std_logic;
	signal csCLR_ALL          : std_logic;
	signal csTRIGGER          : std_logic;
	signal csASIC_DAT          : std_logic_vector(11 downto 0);
	signal csRAM_READ_ADDR    : std_logic_vector(9 downto 0);
	
	signal internal_CLOCK_MONITOR : std_logic;
	signal this_trigger_was_an_autotrigger : std_logic;

--	signal xASIC_RD_ADDR       : std_logic_vector(8 downto 0);
--	signal xASIC_WR_ADDR       : std_logic_vector(8 downto 0);
-------------------------------------------------------------------------------
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
      port ( I  : in    std_logic;  
             O  : out   std_logic);
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
--	component CHIPSCOPE_MON
--	generic(
--		xUSE_CHIPSCOPE	: integer := 1);  -- Set to 1 to use Chipscope 
--	port ( 
--		xMON	: in  std_logic_vector(31 downto 0);
--		xCLK	: in  std_logic);	
--   end component;
--------------------------------------------------------------------------------
--	signal sample_strobe_width_vector : std_logic_vector(7 downto 0) := x"08";
begin
--------------------------------------------------------------------------------	
--	xBUF_CH_SEL : BUF_BUS
--	generic map(bus_width => 3)
--	port map (
--		I => xRAM_WRITE_ADDRESS(8 downto 6),
--		O => ASIC_CH_SEL);
--------------------------------------------------------------------------------	
--	xBUF_SMPL_SEL : BUF_BUS
--	generic map(bus_width => 6)
--	port map (
--		I => xRAM_WRITE_ADDRESS(5 downto 0),
--		O => ASIC_SMPL_SEL);
--------------------------------------------------------------------------------	
	xBUF_CH_SEL : BUF_BUS
	generic map(bus_width => 3)
	port map (
		I => xASIC_CH_SEL,
		O => ASIC_CH_SEL);
-------------------------------------------------------------------------------	
	xBUF_SMPL_SEL : BUF_BUS
	generic map(bus_width => 6)
	port map (
		I => xASIC_SMPL_SEL,
		O => ASIC_SMPL_SEL);
--------------------------------------------------------------------------------	
csTRIGGER <= TRIGGER;
csRAM_READ_ADDR <= RAM_READ_ADDRESS;
csCLR_ALL <= CLR_ALL;
csDONE_USB_XFER <= DONE_USB_XFER;
csASIC_DAT <= ASIC_DAT;
--------------------------------------------------------------------------------
xCHIPSCOPE_MONITOR_BITS(0)  <= csASIC_SSP_IN;    --
xCHIPSCOPE_MONITOR_BITS(1)  <= csASIC_SST_IN;   --
xCHIPSCOPE_MONITOR_BITS(2)  <= csASIC_WR_STRB;    --
xCHIPSCOPE_MONITOR_BITS(3)  <= csASIC_TDC_CLR;   --
xCHIPSCOPE_MONITOR_BITS(4)  <= csASIC_TDC_START; --
--xCHIPSCOPE_MONITOR_BITS(5)  <= csASIC_RAMP;      --
xCHIPSCOPE_MONITOR_BITS(5)  <= csASIC_SMPL_SEL_ALL; --
xCHIPSCOPE_MONITOR_BITS(6)  <= csSTART_USB_XFER; --
xCHIPSCOPE_MONITOR_BITS(7)  <= csDONE_USB_XFER; --
xCHIPSCOPE_MONITOR_BITS(8)  <= csCLR_ALL;       --
xCHIPSCOPE_MONITOR_BITS(9) <= csTRIGGER;       --
--xCHIPSCOPE_MONITOR_BITS(19 downto 10) <= csRAM_READ_ADDR; --
xCHIPSCOPE_MONITOR_BITS(19 downto 10) <= xRAM_WRITE_ADDRESS; --
xCHIPSCOPE_MONITOR_BITS(31 downto 20) <= csASIC_DAT;  --

	MON_HDR(0) <= csASIC_SSP_IN;
	MON_HDR(1) <= csASIC_SST_IN;
	MON_HDR(2) <= ASIC_SSP_OUT;
	MON_HDR(3) <= csASIC_WR_STRB;
	MON_HDR(4) <= csASIC_TDC_CLR;
	MON_HDR(5) <= csASIC_TDC_START;
	MON_HDR(6) <= csASIC_SMPL_SEL_ALL;
	MON_HDR(7) <= csSTART_USB_XFER;
	MON_HDR(15 downto 8) <= ASIC_TRIGGER(7 downto 0);
--------------------------------------------------------------------------------	
--	xCHIPSCOPE_MON : CHIPSCOPE_MON
--	generic map(
--		xUSE_CHIPSCOPE => 1)
--	port map (
--		xCLK => CLK_75MHz,
--		xMON => xCHIPSCOPE_MONITOR_BITS);
--------------------------------------------------------------------------------			
	xRAM_BLOCK : RAM_BLOCK 
	port map (
		xRADDR  	=> RAM_READ_ADDRESS,
		xREAD 	=> DATA_TO_USB,
		xRCLK  	=> CLK_75MHz,--xSLWR
		xR_EN  	=> '1',
		xWADDR	=> xRAM_WRITE_ADDRESS,
		xWRITE  	=> xRAM_INPUT_DATA,
		xWCLK  	=> notCLK_75MHz,
		xW_EN  	=> xRAM_WRITE_ENABLE);
--------------------------------------------------------------------------------	
xRAM_INPUT_DATA(15 downto 12) <= (others => '0');
xRAM_INPUT_DATA(11 downto 0) <= ASIC_DAT;

ASIC_WR_ADDR(8 downto 0) <= SOFT_WRITE_ADDR;
ASIC_RD_ADDR(8 downto 0) <= SOFT_READ_ADDR;
--------------------------------------------------------------------------------
process(CLK,CLR_ALL,TRIGGER,DONE_USB_XFER,xSTATE) --xCLK = 150 MHz, CLK_75MHz
	variable cnt : integer range 0 to 10000 := 0;
	--The following worked when CLK_75MHz was actually a 10MHz clock.
--	variable sample_strobe_width : integer := 2; --20.000 ns @ 150 MHz (probably 16 ns is okay...)
--	variable time_to_sample : integer := 5;     --66.667 ns @ 150 MHz (actually 250 ps x 128 samples = 32 ns)
--	variable write_strobe_width : integer := 3;  --32 ns @ 150 MHz (will need to squeeze this down later)
--	variable wilkinson_arming_time  : integer := 3;  --32 ns @ 150 MHz (guess to start)
--	variable time_to_wilkinson  : integer := 465;  --6.2 us @ 150 MHz (taken from Larry's existing code)
--	variable read_to_ram_settling_time : integer := 3; --Rough guess?

--Appropriate (or minimally working, at least...) values for 75 MHz clock
--   variable idle_count : integer range 0 to 1000000 := 0;		
--	variable sample_strobe_width : integer := 1; --20.000 ns @ 150 MHz (probably 16 ns is okay...)
--	variable time_to_sample : integer := 10;     --66.667 ns @ 150 MHz (actually 250 ps x 128 samples = 32 ns)
--	variable write_strobe_width : integer := 3;  --32 ns @ 150 MHz (will need to squeeze this down later)
--	variable wilkinson_arming_time  : integer := 3;  --32 ns @ 150 MHz (guess to start)
--	variable time_to_wilkinson  : integer := 465;  --6.2 us @ 150 MHz (taken from Larry's existing code)
--	variable read_to_ram_settling_time : integer := 3; --Rough guess?

   variable idle_count : integer range 0 to 1000000 := 0;		
--	constant sample_strobe_width : integer := 4;
--	constant sample_strobe_width : integer := 40;
	variable sample_strobe_width : integer := 13;
--	constant time_to_sample : integer := 20;     
	constant time_to_sample : integer := 40;
	constant write_strobe_width : integer := 6;  --6 was okay on IRS2/BLAB3A eval boards
	constant wilkinson_arming_time  : integer := 6;
	constant time_to_wilkinson  : integer := 930;
	constant read_to_ram_settling_time : integer := 6;
	constant autotrigger_number_of_cycles_for_timeout : integer range 0 to 250000000 := 37500000;
	variable autotrigger_cycles_remaining_before_autotriggering : integer range 0 to 250000000 := autotrigger_number_of_cycles_for_timeout;

begin
------------Asynchronous reset state------------------------
	if (CLR_ALL = '1' or DONE_USB_XFER = '1' or cnt > 2000) then
		xSTATE <= IDLE;
		ASIC_SMPL_SEL_ALL <= '0'; csASIC_SMPL_SEL_ALL <= '0';		
		ASIC_RD_ENA <= '0'; csASIC_RD_ENA <= '0';
--		ASIC_RD_ADDR(9 downto 0) <= (others => '0');
		ASIC_RD_ADDR(9) <= '0';
		ASIC_RAMP <= '0'; csASIC_RAMP <= '0';
		ASIC_TDC_START <= '0'; csASIC_TDC_START <= '0';
		ASIC_TDC_CLR <= '1'; csASIC_TDC_CLR <= '1';		
		ASIC_WR_STRB <= '0'; csASIC_WR_STRB <= '0';		
		ASIC_WR_ADDR(9) <= '0';
--		sample_strobe_width_vector <= x"08";
--		sample_strobe_width_vector <= internal_sample_strobe_width_vector;
		ASIC_SSP_IN <= '0'; csASIC_SSP_IN <= '0';
		ASIC_SST_IN <= '0'; csASIC_SST_IN <= '0';
		START_USB_XFER <= '0'; csSTART_USB_XFER <= '0';		
		xRAM_WRITE_ENABLE <= '0';
		xRAM_READ_ENABLE <= '0';
		xRAM_WRITE_ADDRESS(9 downto 0) <= (others => '0');
		xASIC_CH_SEL <= "000";
		xASIC_SMPL_SEL(5 downto 0) <= (others => '0');
		cnt := 0;
--------Asynchronous start, from external trigger------------
--	elsif (TRIGGER = '1' and xSTATE = IDLE) then
--		xSTATE <= START_SAMPLING; --Normal operating mode
--------The rest of the state machine here---------------
	elsif rising_edge(CLK) then
		case xSTATE is
--------------------
			when IDLE => 
				xSTATE <= IDLE;
				ASIC_SMPL_SEL_ALL <= '0';
				csASIC_SMPL_SEL_ALL <= '0';				
				ASIC_RD_ENA <= '0';
				csASIC_RD_ENA <= '0';
--				ASIC_RD_ADDR(9 downto 0) <= (others => '0');
				ASIC_RD_ADDR(9) <= '0';
				ASIC_RAMP <= '0'; csASIC_RAMP <= '0';
				ASIC_TDC_START <= '0'; csASIC_TDC_START <= '0';
				ASIC_TDC_CLR <= '1'; csASIC_TDC_CLR <= '1';				
				ASIC_WR_STRB <= '0'; csASIC_WR_STRB <= '0';
				ASIC_WR_ADDR(9) <= '0';
--				sample_strobe_width := to_unsigned( to_integer( sample_strobe_width_vector ) );
--				sample_strobe_width := conv_std_logic_vector( sample_strobe_width_vector );
				if (sample_strobe_width_vector = 1) then
					sample_strobe_width := 1;
				elsif (sample_strobe_width_vector = 2) then
					sample_strobe_width := 2;
				elsif (sample_strobe_width_vector = 3) then
					sample_strobe_width := 3;
				elsif (sample_strobe_width_vector = 4) then
					sample_strobe_width := 4;
				elsif (sample_strobe_width_vector = 5) then
					sample_strobe_width := 5;
				elsif (sample_strobe_width_vector = 6) then
					sample_strobe_width := 6;
				elsif (sample_strobe_width_vector = 7) then
					sample_strobe_width := 7;
				elsif (sample_strobe_width_vector = 8) then
					sample_strobe_width := 8;
				elsif (sample_strobe_width_vector = 9) then
					sample_strobe_width := 9;
				else
					sample_strobe_width := 10;
				end if;
--				ASIC_SSP_IN <= '1'; csASIC_SSP_IN <= '1';    
				ASIC_SSP_IN <= '0'; csASIC_SSP_IN <= '0';
				ASIC_SST_IN <= '0'; csASIC_SST_IN <= '0';				
				START_USB_XFER <= '0'; csSTART_USB_XFER <= '0';	
				xRAM_WRITE_ENABLE <= '0';
				xRAM_READ_ENABLE <= '0';
				xRAM_WRITE_ADDRESS(9 downto 0) <= (others => '0');
				xASIC_CH_SEL <= "000";
				xASIC_SMPL_SEL(5 downto 0) <= (others => '0');
				cnt := 0;
				if (TRIGGER = '1') then
					autotrigger_cycles_remaining_before_autotriggering := autotrigger_number_of_cycles_for_timeout;
					this_trigger_was_an_autotrigger <= '0';
					xSTATE <= START_SAMPLING; -- trigger here
				end if;
				if (autotrigger_enabled = '1') then
					if (autotrigger_cycles_remaining_before_autotriggering > 0) then
						autotrigger_cycles_remaining_before_autotriggering := autotrigger_cycles_remaining_before_autotriggering - 1;
					else
						autotrigger_cycles_remaining_before_autotriggering := autotrigger_number_of_cycles_for_timeout;
						this_trigger_was_an_autotrigger <= '1';
						xSTATE <= START_SAMPLING; -- autotrigger here
					end if;
				else
					autotrigger_cycles_remaining_before_autotriggering := autotrigger_number_of_cycles_for_timeout;
				end if;
--				if (idle_count > 75000) then
--				   idle_count := 0;
--					xSTATE <= START_SAMPLING;
--				else
--					idle_count := idle_count + 1;
--				end if;
--------------------
			when START_SAMPLING =>
				-- this rising edge propagating through the sampling array puts it in TRACK mode:
				ASIC_SSP_IN <= '1'; csASIC_SSP_IN <= '1';
				if (cnt < sample_strobe_width) then
					cnt := cnt + 1;
				else
					-- this rising edge propagating through the sampling array puts it in HOLD mode:
					ASIC_SST_IN <= '1'; csASIC_SST_IN <= '1';
					xSTATE <= WAIT_FOR_SAMPLING;
					cnt := 0;
				end if;
--------------------
			when WAIT_FOR_SAMPLING =>
--				ASIC_SSP_IN <= '0'; csASIC_SSP_IN <= '0';
				if (cnt < time_to_sample + sample_strobe_width) then
					cnt := cnt + 1;
				else
					ASIC_SSP_IN <= '0'; csASIC_SSP_IN <= '0';
					ASIC_SST_IN <= '0'; csASIC_SST_IN <= '0';
					xSTATE <= ADDRESS_TO_STORAGE1;
					cnt := 0;
				end if;
--------------------
			when ADDRESS_TO_STORAGE1 =>
				ASIC_WR_ADDR(9) <= '1';
--				ASIC_WR_ADDR(8 downto 0) <= SOFT_WRITE_ADDR;
				xSTATE <= WRITE_TO_STORAGE1;
--------------------
			when WRITE_TO_STORAGE1 =>
				ASIC_WR_STRB <= '1';
				csASIC_WR_STRB <= '1';
				if (cnt >= write_strobe_width) then
					ASIC_WR_STRB <= '0';
					csASIC_WR_STRB <= '0';
--					xSTATE <= ADDRESS_TO_STORAGE2;  --This was the normal operating condition
					xSTATE <= ARM_WILKINSON;  --This is for testing one set of 64 samples at a time
					cnt := 0;
				else
					cnt := cnt + 1;
				end if;
--------------------
			when ADDRESS_TO_STORAGE2 =>
				ASIC_WR_ADDR(9) <= '1';
--				ASIC_WR_ADDR(8 downto 0) <= SOFT_WRITE_ADDR; --This is wrong... fix me
				xSTATE <= WRITE_TO_STORAGE2;
--------------------
			when WRITE_TO_STORAGE2 =>
				ASIC_WR_STRB <= '1';
				csASIC_WR_STRB <= '1';
				if (cnt >= write_strobe_width) then
					ASIC_WR_STRB <= '0';
					csASIC_WR_STRB <= '0';
					xSTATE <= ARM_WILKINSON;
					cnt := 0;
				else
					cnt := cnt + 1;
				end if;				
--------------------
			when ARM_WILKINSON =>
				ASIC_WR_ADDR(9) <= '0';
				ASIC_TDC_CLR <= '0';
				csASIC_TDC_CLR <= '0';
				ASIC_RD_ADDR(9) <= '1';
				--ASIC_RD_ADDR(8 downto 0) <= (others => '0');
--				ASIC_RD_ADDR(8 downto 1) <= (others => '0');
--				ASIC_RD_ADDR(0) <= '1';
--				ASIC_RD_ADDR(8 downto 0) <= SOFT_READ_ADDR;
				ASIC_RD_ENA <= '1';
				csASIC_RD_ENA <= '1';
				if (cnt >= wilkinson_arming_time) then
					cnt := 0;
					xSTATE <= PERFORM_WILKINSON;
				else
					cnt := cnt + 1;
				end if;
--------------------
			when PERFORM_WILKINSON =>
				ASIC_TDC_START <= '1';
				csASIC_TDC_START <= '1';
				ASIC_RAMP <= '1';
				csASIC_RAMP <= '1';
				if (cnt >= time_to_wilkinson) then
					cnt := 0;
					ASIC_TDC_START <= '0';
					csASIC_TDC_START <= '0';
					ASIC_RAMP <= '0';
					csASIC_RAMP <= '0';
					ASIC_RD_ADDR(9) <= '0';
					ASIC_RD_ENA <= '0';
					csASIC_RD_ENA <= '0';
					xSTATE <= ARM_READING;
				else
					cnt := cnt + 1;
				end if;
--------------------
			when ARM_READING =>
				ASIC_SMPL_SEL_ALL <= '1';
				csASIC_SMPL_SEL_ALL <= '1';
				xRAM_WRITE_ADDRESS(9 downto 0) <= (others => '0');
				xSTATE <= READ_TO_RAM;
--------------------
			when READ_TO_RAM =>	
				xRAM_WRITE_ENABLE <= '0';
				if (xRAM_WRITE_ADDRESS > 511) then
					ASIC_SMPL_SEL_ALL <= '0';
					csASIC_SMPL_SEL_ALL <= '0';
					xSTATE <= READOUT_BY_USB;
				else
					xSTATE <= WAIT_FOR_READ_SETTLING;
				end if;
--------------------
			when WAIT_FOR_READ_SETTLING =>
				xRAM_WRITE_ENABLE <= '1';
				if (cnt >= read_to_ram_settling_time) then					
					xRAM_WRITE_ADDRESS <= xRAM_WRITE_ADDRESS + 1;
					if (xASIC_SMPL_SEL = 63) then
						xASIC_SMPL_SEL(5 downto 0) <= (others => '0');
						if (xASIC_CH_SEL = 7) then
							xASIC_CH_SEL(2 downto 0) <= (others => '0');
						else
							xASIC_CH_SEL <= xASIC_CH_SEL + 1;
						end if;
					else
						xASIC_SMPL_SEL <= xASIC_SMPL_SEL + 1;
					end if;
					xSTATE <= READ_TO_RAM;
					cnt := 0;
				else
					cnt := cnt + 1;
				end if;
--------------------
			when READOUT_BY_USB =>
				if (this_trigger_was_an_autotrigger = '0') then
					START_USB_XFER <= '1';
					csSTART_USB_XFER <= '1';
				end if;
--------------------
			when others => --Catch for undefined state
				xSTATE <= IDLE;
		end case;
	end if;
end process;
--------------------------------------------------------------------------------
process (CLK) begin
	if (rising_edge(CLK)) then
		internal_CLOCK_MONITOR <= not(internal_CLOCK_MONITOR);
	end if;
end process;
--------------------------------------------------------------------------------
end Behavioral;
