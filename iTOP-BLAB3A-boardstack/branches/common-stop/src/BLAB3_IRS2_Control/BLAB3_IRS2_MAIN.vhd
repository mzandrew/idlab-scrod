--------------------------------------------------------	
-- Design by: Kurtis Nishimura
-- Last updated: 2011-06-12
-- Notes: This firmware is to operate IRS2 or BLAB3 in 
--        "one-shot" mode, where the sample signal is 
--        given only when a software trigger is received.
--        It is primarily for simple evaluation.
--------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BLAB3_IRS2_MAIN is
    port (
		-- IRS ASIC I/Os
		ASIC_CH_SEL	 	   : out std_logic_vector(2 downto 0);
		ASIC_RD_ADDR	 	: out std_logic_vector(9 downto 0);
		ASIC_SMPL_SEL 	   : out std_logic_vector(5 downto 0);
		ASIC_SMPL_SEL_ALL : out std_logic; 
		ASIC_RD_ENA	 	   : out std_logic; 
		ASIC_RAMP	 	 	: out std_logic; 
		ASIC_DAT		      : in  std_logic_vector(11 downto 0);
		ASIC_TDC_START    : out std_logic; 
		ASIC_TDC_CLR	   : out std_logic; 
		ASIC_WR_STRB	   : out std_logic; 
		ASIC_WR_ADDR	   : out std_logic_vector(9 downto 0);
		ASIC_SSP_IN	      : out std_logic;
		ASIC_SST_IN	      : out std_logic;		
		ASIC_SSP_OUT	   : in  std_logic;
		SOFT_WRITE_ADDR   : in  std_logic_vector(8 downto 0);
		SOFT_READ_ADDR    : in  std_logic_vector(8 downto 0);		
		-- User I/O
		CLK_SSP          : in  std_logic;--Sampling rate / 128 (0 deg)
		CLK_SST          : in  std_logic;--Sampling rate / 128 (90 deg)
		CLK_WRITE_STROBE : in  std_logic;--Sampling rate / 64  (270 deg)

		START_USB_XFER	   : out std_logic;--Signal to start sending data to USB
		DONE_USB_XFER 	   : in  std_logic;
		MON_HDR		 	   : out std_logic_vector(15 downto 0); 
		CLR_ALL		 	   : in  std_logic;
		TRIGGER			   : in  std_logic;
		RAM_READ_ADDRESS  : in std_logic_vector(9 downto 0);
		DATA_TO_USB       : out std_logic_vector(15 downto 0));
end BLAB3_IRS2_MAIN;

architecture Behavioral of BLAB3_IRS2_MAIN is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is ( NOMINAL_SAMPLING );
	
	signal internal_STATE          : STATE_TYPE;

--	signal xRAM_OUTPUT_DATA        : std_logic_vector(15 downto 0);
--	signal xRAM_READ_ENABLE        : std_logic;
--	signal xRAM_WRITE_ADDRESS      : std_logic_vector(9 downto 0);
--	signal xRAM_INPUT_DATA         : std_logic_vector(15 downto 0);
--	signal xRAM_WRITE_ENABLE       : std_logic;
	
	signal internal_ASIC_CH_SEL	 	 : std_logic_vector(2 downto 0);
	signal internal_ASIC_RD_ADDR	 	 : std_logic_vector(9 downto 0) := (others => '0');
	signal internal_ASIC_SMPL_SEL 	 : std_logic_vector(5 downto 0);
	signal internal_ASIC_SMPL_SEL_ALL : std_logic; 
	signal internal_ASIC_RD_ENA	 	 : std_logic; 
	signal internal_ASIC_RAMP	 	 	 : std_logic; 
	signal internal_ASIC_DAT		    : std_logic_vector(11 downto 0);
	signal internal_ASIC_TDC_START    : std_logic; 
	signal internal_ASIC_TDC_CLR	    : std_logic; 
	signal internal_ASIC_WR_STRB	    : std_logic; 
	signal internal_ASIC_WR_ADDR	    : std_logic_vector(9 downto 0) := (others => '0');
	signal internal_ASIC_SSP_IN	    : std_logic;
	signal internal_ASIC_SST_IN	    : std_logic;		
	signal internal_ASIC_SSP_OUT	    : std_logic;
	signal internal_SOFT_WRITE_ADDR   : std_logic_vector(8 downto 0);
	signal internal_SOFT_READ_ADDR    : std_logic_vector(8 downto 0);		
	
	signal internal_TRIGGER           : std_logic;
	signal internal_BUSY              : std_logic;

	signal internal_CLK_STATE_MACHINE_DIV_BY_2 : std_logic;

-------------------------------------------------------------------------------
--	component RAM_BLOCK
--   port ( xRADDR 	: in    std_logic_vector(9 downto 0);
--			 xREAD  	: out   std_logic_vector(15 downto 0);
--          xRCLK 	: in    std_logic; 
--          xR_EN  	: in    std_logic; 
--          xWADDR 	: in    std_logic_vector(9 downto 0); 
--          xWRITE 	: in    std_logic_vector(15 downto 0); 
--          xWCLK 	: in    std_logic; 
--          xW_EN  	: in    std_logic);
--   end component;
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------			
--	xRAM_BLOCK : RAM_BLOCK 
--	port map (
--		xRADDR  	=> RAM_READ_ADDRESS,
--		xREAD 	=> DATA_TO_USB,
--		xRCLK  	=> CLK_75MHz,--xSLWR
--		xR_EN  	=> '1',
--		xWADDR	=> xRAM_WRITE_ADDRESS,
--		xWRITE  	=> xRAM_INPUT_DATA,
--		xWCLK  	=> notCLK_75MHz,
--		xW_EN  	=> xRAM_WRITE_ENABLE);
------------------------------------------------------------------------------	
--xRAM_INPUT_DATA(15 downto 12) <= (others => '0');
--xRAM_INPUT_DATA(11 downto 0) <= internal_ASIC_DAT;
MON_HDR(0) <= internal_ASIC_SSP_IN;
MON_HDR(1) <= internal_ASIC_SST_IN;
MON_HDR(2) <= internal_ASIC_WR_STRB;
MON_HDR(3) <= internal_ASIC_WR_ADDR(0);
MON_HDR(14 downto 4) <= (others => '0');
MON_HDR(15) <= internal_CLK_STATE_MACHINE_DIV_BY_2;

ASIC_CH_SEL   <= internal_ASIC_CH_SEL;
ASIC_RD_ADDR  <= internal_ASIC_RD_ADDR;
ASIC_SMPL_SEL <= internal_ASIC_SMPL_SEL;
ASIC_SMPL_SEL_ALL <= internal_ASIC_SMPL_SEL_ALL; 
ASIC_RD_ENA <= internal_ASIC_RD_ENA; 
ASIC_RAMP <= internal_ASIC_RAMP; 
ASIC_TDC_START <= internal_ASIC_TDC_START; 
ASIC_TDC_CLR <= internal_ASIC_TDC_CLR; 
ASIC_WR_ADDR <= internal_ASIC_WR_ADDR;
ASIC_WR_STRB <= internal_ASIC_WR_STRB;
ASIC_SSP_IN <= internal_ASIC_SSP_IN;
ASIC_SST_IN <= internal_ASIC_SST_IN;

internal_ASIC_DAT <= ASIC_DAT;
internal_ASIC_SSP_OUT <= ASIC_SSP_OUT;
internal_SOFT_WRITE_ADDR <= SOFT_WRITE_ADDR;
internal_SOFT_READ_ADDR <= SOFT_READ_ADDR;		

internal_TRIGGER <= TRIGGER;

-------LOGIC TO RUN ASIC SAMPLING------
internal_ASIC_WR_STRB <= CLK_WRITE_STROBE;
internal_ASIC_SSP_IN <= CLK_SSP;
internal_ASIC_SST_IN <= CLK_SST;
internal_ASIC_WR_ADDR(0) <= CLK_SST;
---------------------------------------

--------------------------------------------------------------------------------
process(CLK_SST, internal_STATE, CLR_ALL, DONE_USB_XFER)
begin
------------Asynchronous reset state------------------------
	if (CLR_ALL = '1' or DONE_USB_XFER = '1') then
		internal_STATE <= NOMINAL_SAMPLING;
		internal_ASIC_CH_SEL(2 downto 0) <= (others => '0');
		internal_ASIC_RD_ADDR(9 downto 0) <= (others => '0');
		internal_ASIC_SMPL_SEL(5 downto 0) <= (others => '0');
		internal_ASIC_SMPL_SEL_ALL <= '0'; 
		internal_ASIC_RD_ENA <= '0'; 
		internal_ASIC_RAMP <= '0'; 
		internal_ASIC_TDC_START <= '0'; 
		internal_ASIC_TDC_CLR <= '1'; 
		internal_ASIC_WR_ADDR(9) <= '1';
		internal_ASIC_WR_ADDR(8 downto 1) <= (others => '0');
		internal_BUSY <= '0';
--------Check for the trigger here-----------------------
--------The rest of the state machine here---------------
	elsif falling_edge(CLK_SST) then
		internal_CLK_STATE_MACHINE_DIV_BY_2 <= not(internal_CLK_STATE_MACHINE_DIV_BY_2);
		case internal_STATE is
--------------------
			when NOMINAL_SAMPLING =>
				internal_ASIC_WR_ADDR(9) <= '1';
				internal_ASIC_WR_ADDR(8 downto 1) <= std_logic_vector( unsigned(internal_ASIC_WR_ADDR(8 downto 1)) + 1 );
--------------------
			when others => --Catch for undefined state
--------------------
		end case;
	end if;
end process;
--------------------------------------------------------------------------------
end Behavioral;
