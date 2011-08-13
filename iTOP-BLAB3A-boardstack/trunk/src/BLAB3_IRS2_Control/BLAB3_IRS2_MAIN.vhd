--------------------------------------------------------	
-- Design by: Kurtis Nishimura
-- Last updated: 2011-08-10
-- Notes: Stripping down firmware to work with FTSW
--------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

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
		ASIC_TRIGGER_BITS : in  std_logic_vector(7 downto 0);
		
		SOFT_WRITE_ADDR   : in  std_logic_vector(8 downto 0);
		SOFT_READ_ADDR    : in  std_logic_vector(8 downto 0);		
		-- User I/O
		CLK_SSP          : in  std_logic;--Sampling rate / 128
		CLK_SST          : in  std_logic;--Sampling rate / 128
		CLK_WRITE_STROBE : in  std_logic;--Sampling rate / 64

		START_USB_XFER	   : out std_logic;--Signal to start sending data to USB
		DONE_USB_XFER 	   : in  std_logic;
		MONITOR		 	   : out std_logic_vector(15 downto 0); 
		CLR_ALL		 	   : in  std_logic;
		TRIGGER			   : in  std_logic;
		RAM_READ_ADDRESS  : in std_logic_vector(11 downto 0);
		RAM_READ_CLOCK		: in std_logic;
		DATA_TO_USB       : out std_logic_vector(15 downto 0));
end BLAB3_IRS2_MAIN;

architecture implementation of BLAB3_IRS2_MAIN is
   attribute BOX_TYPE   : string ;
	--------------------------------------------------------------------------------
	--   								signals		     		   						         --
	--------------------------------------------------------------------------------
	signal internal_ASIC_WR_STRB	: std_logic;
	signal internal_ASIC_SSP_IN	: std_logic;
	signal internal_ASIC_SST_IN	: std_logic;
	signal internal_ASIC_WR_ADDR	: std_logic_vector(9 downto 0);	
	signal internal_MONITOR			: std_logic_vector(15 downto 0);

	type STATE_TYPE is ( WAITING, NOMINAL_SAMPLING,
								ARM_WILKINSON,PERFORM_WILKINSON,
								ARM_READING,READ_TO_RAM,WAIT_FOR_READ_SETTLING,INCREMENT_ADDRESSES,
								READOUT_BY_USB);	
	signal internal_STATE          : STATE_TYPE;


	signal internal_RAM_OUTPUT_DATA        : std_logic_vector(15 downto 0);
	signal internal_RAM_READ_ENABLE        : std_logic;
	signal internal_RAM_WRITE_ADDRESS      : std_logic_vector(11 downto 0);
	signal internal_RAM_INPUT_DATA         : std_logic_vector(15 downto 0);
	signal internal_RAM_WRITE_ENABLE       : std_logic;
	signal internal_RAM_WRITE_ENABLE_VEC   : std_logic_vector(0 downto 0);
	signal internal_RAM_READ_CLOCK			: std_logic;
	
	signal internal_ASIC_CH_SEL	 	 : std_logic_vector(2 downto 0);
	signal internal_ASIC_RD_ADDR	 	 : std_logic_vector(9 downto 0) := (others => '0');
	signal internal_ASIC_SMPL_SEL 	 : std_logic_vector(5 downto 0);
	signal internal_ASIC_SMPL_SEL_ALL : std_logic; 
	signal internal_ASIC_RD_ENA	 	 : std_logic; 
	signal internal_ASIC_RAMP	 	 	 : std_logic; 
	signal internal_ASIC_DAT		    : std_logic_vector(11 downto 0);
	signal internal_ASIC_TDC_START    : std_logic; 
	signal internal_ASIC_TDC_CLR	    : std_logic; 
	signal internal_ASIC_SSP_OUT	    : std_logic;
	signal internal_ASIC_TRIGGER_BITS : std_logic_vector(7 downto 0);
	signal internal_SOFT_WRITE_ADDR   : std_logic_vector(8 downto 0);
	signal internal_SOFT_READ_ADDR    : std_logic_vector(8 downto 0);		
	
	signal internal_TRIGGER           : std_logic;
	signal internal_BUSY              : std_logic;

	signal internal_CLK_STATE_MACHINE_DIV_BY_2 : std_logic;
-------------------------------------------------------------------------
-------------------------------------------------------------------------
begin
-------------------------------------------------------------------------			

	-------WIRING BETWEEN INTERNALS AND IOs-------------
	--The following are covered by ODDR2 blocks since they're
	--  based on clock signals.
	--ASIC_WR_STRB 	<= internal_ASIC_WR_STRB;
	--ASIC_SSP_IN		<= internal_ASIC_SSP_IN;
	--ASIC_SST_IN		<= internal_ASIC_SST_IN;
	--ASIC_WR_ADDR(0)	<= internal_ASIC_WR_ADDR(0);

	--The rest go here
	ASIC_CH_SEL   <= internal_ASIC_CH_SEL;
	ASIC_RD_ADDR  <= internal_ASIC_RD_ADDR;
	ASIC_SMPL_SEL <= internal_ASIC_SMPL_SEL;
	ASIC_SMPL_SEL_ALL <= internal_ASIC_SMPL_SEL_ALL; 
	ASIC_RD_ENA <= internal_ASIC_RD_ENA; 
	ASIC_RAMP <= internal_ASIC_RAMP; 
	ASIC_TDC_START <= internal_ASIC_TDC_START; 
	ASIC_TDC_CLR <= internal_ASIC_TDC_CLR; 
	ASIC_WR_ADDR(9 downto 1) <= internal_ASIC_WR_ADDR(9 downto 1);
	internal_ASIC_DAT <= ASIC_DAT;
	internal_ASIC_SSP_OUT <= ASIC_SSP_OUT;
	internal_SOFT_WRITE_ADDR <= SOFT_WRITE_ADDR;
	internal_SOFT_READ_ADDR <= SOFT_READ_ADDR;		
	internal_ASIC_TRIGGER_BITS <= ASIC_TRIGGER_BITS;

	internal_TRIGGER <= TRIGGER;

	internal_RAM_WRITE_ENABLE_VEC(0) <= internal_RAM_WRITE_ENABLE;
	
	internal_RAM_READ_CLOCK <= RAM_READ_CLOCK;
	----------------------------------------------------

	-------LOGIC TO RUN ASIC SAMPLING------
	internal_ASIC_WR_STRB <= CLK_WRITE_STROBE;
	internal_ASIC_SSP_IN <= CLK_SSP;
	internal_ASIC_SST_IN <= CLK_SST;
	internal_ASIC_WR_ADDR(0) <= CLK_SST;

	-------MONITOR HEADER------------------
	internal_MONITOR(0) <= internal_ASIC_SST_IN;
	internal_MONITOR(1) <= CLK_WRITE_STROBE;
	internal_MONITOR(7 downto 2) <= internal_ASIC_SMPL_SEL;
	internal_MONITOR(9 downto 8) <= internal_RAM_WRITE_ADDRESS(1 downto 0);
	internal_MONITOR(10) <= internal_RAM_WRITE_ADDRESS(6);
	internal_MONITOR(11) <= internal_ASIC_SMPL_SEL_ALL;
	internal_MONITOR(12) <= internal_RAM_WRITE_ENABLE;
	internal_MONITOR(15 downto 13) <= internal_RAM_INPUT_DATA(2 downto 0);
	
	--Signals 15 downto 4 are simple pass throughs.
	--Signals 3 downto 0 come from clocks, 
	--  so must be driven by ODDR2 primitives.
	MONITOR(15 downto 4) <= internal_MONITOR(15 downto 4);
	---------------------------------------	

	-------------------------------------------------------------------------			
	READOUT_RAM_BLOCK : entity work.MULTI_WINDOW_RAM_BLOCK
		port map (
			clka => CLK_SST,
			ena => '1',
			wea => internal_RAM_WRITE_ENABLE_VEC,
			addra => internal_RAM_WRITE_ADDRESS,
			dina => internal_RAM_INPUT_DATA,
--			clkb => internal_RAM_READ_CLOCK,
			clkb => CLK_WRITE_STROBE,
--			enb => internal_RAM_READ_ENABLE,
			enb => '1',
			addrb => RAM_READ_ADDRESS,
			doutb => DATA_TO_USB);		
			
	internal_RAM_INPUT_DATA(15 downto 12) <= (others => '0');
	internal_RAM_INPUT_DATA(11 downto 0) <= internal_ASIC_DAT;
	-------------------------------------------------------------------------
	---------------------------------------------------------
	ODDR2_MON0 : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => MONITOR(0), -- 1-bit output data
			C0 => internal_MONITOR(0), -- 1-bit clock input
			C1 => not(internal_MONITOR(0)), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------
	ODDR2_MON1 : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => MONITOR(1), -- 1-bit output data
			C0 => internal_MONITOR(1), -- 1-bit clock input
			C1 => not(internal_MONITOR(1)), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------
	ODDR2_MON2 : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => MONITOR(2), -- 1-bit output data
			C0 => internal_MONITOR(2), -- 1-bit clock input
			C1 => not(internal_MONITOR(2)), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------	
	ODDR2_MON3 : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => MONITOR(3), -- 1-bit output data
			C0 => internal_MONITOR(3), -- 1-bit clock input
			C1 => not(internal_MONITOR(3)), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------		

	---------------------------------------------------------		
	ODDR2_SSP_IN : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => ASIC_SSP_IN, -- 1-bit output data
			C0 => internal_ASIC_SSP_IN, -- 1-bit clock input
			C1 => not(internal_ASIC_SSP_IN), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------
	ODDR2_SST_IN : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => ASIC_SST_IN, -- 1-bit output data
			C0 => internal_ASIC_SST_IN, -- 1-bit clock input
			C1 => not(internal_ASIC_SST_IN), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------
	ODDR2_WR_STRB : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => ASIC_WR_STRB, -- 1-bit output data
			C0 => internal_ASIC_WR_STRB, -- 1-bit clock input
			C1 => not(internal_ASIC_WR_STRB), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	---------------------------------------------------------
	ODDR2_WR_ADDR0 : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => ASIC_WR_ADDR(0), -- 1-bit output data
			C0 => internal_ASIC_WR_ADDR(0), -- 1-bit clock input
			C1 => not(internal_ASIC_WR_ADDR(0)), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);
	-----------------------------------

--------------------------------------------------------------------------------
process(CLK_SST, internal_STATE, CLR_ALL, DONE_USB_XFER, internal_BUSY)
	variable delay_counter : integer range 0 to 1023 := 0;
	constant time_to_arm_wilkinson : integer := 3; -- A guess... should just buy some extra time for logic to settle
--	constant time_to_wilkinson : integer := 97; -- 6.2 us @ 15.625 MHz
	constant time_to_wilkinson : integer := 128; -- 6.2 us @ 21.2 MHz	
	constant read_to_ram_settling_time : integer := 1; --In principle we should only need 1 clock cycle here.
	variable windows_sampled_after_trigger : integer range 0 to 1023 := 0;
	variable windows_read_out : integer range 0 to 1023 := 0;
	variable samples_read_out_this_window : integer range 0 to 1023;
	constant windows_to_sample : integer := 8;
	constant trigger_arming_time : integer := 2;
begin
------------Asynchronous reset state------------------------
	if (CLR_ALL = '1' or DONE_USB_XFER = '1') then
		internal_STATE <= WAITING;
		internal_CLK_STATE_MACHINE_DIV_BY_2 <= not(internal_CLK_STATE_MACHINE_DIV_BY_2);
		internal_ASIC_CH_SEL(2 downto 0) <= (others => '0');
		internal_ASIC_RD_ADDR(9) <= '0';
		internal_ASIC_RD_ADDR(8 downto 0) <= internal_SOFT_READ_ADDR;
		internal_ASIC_SMPL_SEL(5 downto 0) <= (others => '0');
		internal_ASIC_SMPL_SEL_ALL <= '0'; 
		internal_ASIC_RD_ENA <= '0'; 
		internal_ASIC_RAMP <= '0'; 
		internal_ASIC_TDC_START <= '0'; 
		internal_ASIC_TDC_CLR <= '1'; 
		internal_ASIC_WR_ADDR(9) <= '0';
		internal_ASIC_WR_ADDR(8 downto 1) <= internal_SOFT_WRITE_ADDR(8 downto 1);
		internal_BUSY <= '0';
		delay_counter := 0;		
--------The rest of the state machine here---------------
	elsif falling_edge(CLK_SST) then
		case internal_STATE is
--------------------
			when WAITING =>
				if (internal_TRIGGER <= '1') then
				   internal_BUSY <= '1';
					internal_ASIC_WR_ADDR(9) <= '1';
					internal_RAM_WRITE_ENABLE <= '0';					
					if (delay_counter >= trigger_arming_time) then
						internal_STATE <= NOMINAL_SAMPLING;
						windows_sampled_after_trigger := 2;
						delay_counter := 0;
					else
						delay_counter := delay_counter + 1;
					end if;
				end if;
--------------------
			when NOMINAL_SAMPLING =>
				internal_ASIC_WR_ADDR(8 downto 1) <= std_logic_vector( unsigned(internal_ASIC_WR_ADDR(8 downto 1)) + 1 );
				if (windows_sampled_after_trigger >= windows_to_sample) then
					--Switches from writing to reading mode.
					internal_ASIC_WR_ADDR(9) <= '0';
					internal_ASIC_RD_ADDR(9) <= '1';
					internal_ASIC_RD_ENA <= '1';
					--We should look back to where we started the writing in the first place.
					internal_ASIC_RD_ADDR(8 downto 0) <= internal_SOFT_READ_ADDR(8 downto 0);
					--Set the RAM address to be 0
					internal_RAM_WRITE_ADDRESS(11 downto 0) <= (others => '0');
					--Move to the state where we start digitizing
					internal_STATE <= ARM_WILKINSON;
					delay_counter := 0;
					windows_read_out := 0;
				else
					windows_sampled_after_trigger := windows_sampled_after_trigger + 2;
				end if;
--------------------
			when ARM_WILKINSON =>
				internal_ASIC_TDC_CLR <= '0';
				if (delay_counter >= time_to_arm_wilkinson) then
					delay_counter := 0;
					internal_STATE <= PERFORM_WILKINSON;
				else
					delay_counter := delay_counter + 1;
				end if;
--------------------
			when PERFORM_WILKINSON =>
				internal_ASIC_TDC_START <= '1';
				internal_ASIC_RAMP <= '1';
				if (delay_counter >= time_to_wilkinson) then
					delay_counter := 0;			
					samples_read_out_this_window := 0;
					internal_ASIC_TDC_START <= '0';
					internal_ASIC_RAMP <= '0';
					internal_STATE <= ARM_READING;
				else
					delay_counter := delay_counter + 1;
				end if;
--------------------
			when ARM_READING =>
				internal_ASIC_SMPL_SEL_ALL <= '1';
				internal_STATE <= READ_TO_RAM;
				internal_RAM_READ_ENABLE <= '0';
--------------------
			when READ_TO_RAM =>	
				internal_RAM_WRITE_ENABLE <= '0';
				if ( samples_read_out_this_window > 511 ) then
					windows_read_out := windows_read_out + 1;
					internal_ASIC_SMPL_SEL_ALL <= '0';
					if (windows_read_out >= windows_to_sample) then
						internal_STATE <= READOUT_BY_USB;
					else
						internal_ASIC_RD_ADDR(8 downto 0) <= std_logic_vector( unsigned(internal_ASIC_RD_ADDR(8 downto 0)) + 1);
						delay_counter := 0;
						internal_ASIC_TDC_CLR <= '1';
						internal_STATE <= ARM_WILKINSON;
					end if;
				else
					delay_counter := 0;
					internal_STATE <= WAIT_FOR_READ_SETTLING;
				end if;
--------------------
			when WAIT_FOR_READ_SETTLING =>
				if (delay_counter >= read_to_ram_settling_time) then	
					internal_RAM_WRITE_ENABLE <= '1';
					delay_counter := 0;					
					internal_STATE <= INCREMENT_ADDRESSES;
				else
					delay_counter := delay_counter + 1;
				end if;
--------------------
			when INCREMENT_ADDRESSES =>
				internal_RAM_WRITE_ENABLE <= '0';
				internal_RAM_WRITE_ADDRESS <= std_logic_vector(unsigned(internal_RAM_WRITE_ADDRESS) + 1);
				samples_read_out_this_window := samples_read_out_this_window + 1;
				if ( unsigned(internal_ASIC_SMPL_SEL) = 63) then
					internal_ASIC_SMPL_SEL(5 downto 0) <= (others => '0');
					if ( unsigned(internal_ASIC_CH_SEL) = 7) then
						internal_ASIC_CH_SEL(2 downto 0) <= (others => '0');
					else
						internal_ASIC_CH_SEL <= std_logic_vector(unsigned(internal_ASIC_CH_SEL) + 1);
					end if;
				else
					internal_ASIC_SMPL_SEL <= std_logic_vector(unsigned(internal_ASIC_SMPL_SEL) + 1);
				end if;
				internal_STATE <= READ_TO_RAM;
--------------------
			when READOUT_BY_USB =>
				internal_RAM_READ_ENABLE <= '1';			
				START_USB_XFER <= '1';
--------------------
			when others => --Catch for undefined state
--------------------
		end case;
	end if;
end process;
--------------------------------------------------------------------------------
end implementation;
