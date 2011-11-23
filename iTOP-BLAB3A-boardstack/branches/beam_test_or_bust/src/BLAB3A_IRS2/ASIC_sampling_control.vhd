----------------------------------------------------------------------------------
-- ASIC sampling control
-- Description:
--   This module handles the sampling and transfer to analog
--   storage.  The following are the ports used:
--
--		CONTINUE_WRITING - input - this block will continue to write to analog
--                               storage as long as this is high
--		CLOCK_SST - input - puts switches in hold mode
--		CLOCK_SSP - input - puts switches in track mode
--		CLOCK_WRITE_STROBE - input - performs the write from sampling to storage
--		FIRST_ADDRESS_ALLOWED - input bus, 8-wide - the lowest address that will be written to
--		LAST_ADDRESS_ALLOWED	- input bus, 8-wide - the highest address that will be written to
--		LAST_ADDRESS_WRITTEN - output bus, 8-wide - the last address that was written to after a trigger
--		AsicIn_SAMPLING_HOLD_MODE_C - output bus, 4-wide - signals to ASICs, 1 per column (SST)
--		AsicIn_SAMPLING_TO_STORAGE_ADDRESS - output bus, 8-wide - address to all ASICs
--		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE	- output - same for all ASICs
--		AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C - output bus, 4-wide - signals to ASICs, 1 per column (WR_STRB)
--		AsicIn_SAMPLING_TRACK_MODE_C - output bus, 4-wide - signals to ASICs, 1 per column (SSP)
--		CHIPSCOPE_CONTROL - output bus, 36-wide - connect at top level to get ILA access
--
--   Under normal operation, CONTINUE_WRITING is high.  The ASIC readout block should
--   handle a received trigger and set CONTINUE_WRITING to high.
--   After writing has stopped (which happens by setting SAMPLING_TO_STORAGE_ADDRESS_ENABLE 
--   low in this module), the LAST_ADDRESS_WRITTEN is modified to reflect the last
--   window that was moved to analog storage.  This allows the ASIC readout block
--   to look back however many windows desired from there for readout.
--   Two other signals, LAST_ADDRESS_ALLOWED and FIRST_ADDRESS_ALLOWED, are 
--   a way to reduce the number of storage windows being uesd, or to force
--   pedestal sampling.
--   At the moment, since this block is clocked on the falling edge of SST, the
--   least significant bit of the last written address is always 1, regardless 
--   of the values of the above parameters.
--   So FIRST_ADDRESS_ALLOWED should be even, with LSB 0, and 
--   LAST_ADDRESS_ALLOWED should be odd, with LSB 1.
--
-- Change log:
-- 2011-09-10 - Created by Kurtis
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity ASIC_sampling_control is
	Generic ( 
		use_chipscope_ila		: boolean := false
	);
	Port (
		CONTINUE_WRITING                          : in std_logic;
		CLOCK_SST                                 : in std_logic;
		CLOCK_SSP                                 : in std_logic;
		CLOCK_WRITE_STROBE                        : in std_logic;
		FIRST_ADDRESS_ALLOWED                     : in std_logic_vector(8 downto 0);
		LAST_ADDRESS_ALLOWED                      : in std_logic_vector(8 downto 0);
		WINDOWS_TO_LOOK_BACK                      : in std_logic_vector(8 downto 0);		
		LAST_ADDRESS_WRITTEN                      : out std_logic_vector(8 downto 0);
		FIRST_ADDRESS_WRITTEN                     : out std_logic_vector(8 downto 0);
		AsicIn_SAMPLING_HOLD_MODE_C               : out	std_logic_vector(3 downto 0);
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS        : out	std_logic_vector(8 downto 0);
		AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : out	std_logic;
		AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C     : out	std_logic_vector(3 downto 0);
		AsicIn_SAMPLING_TRACK_MODE_C              : out	std_logic_vector(3 downto 0);
		CHIPSCOPE_CONTROL                         : inout std_logic_vector(35 downto 0)
	);
end ASIC_sampling_control;

architecture Behavioral of ASIC_sampling_control is
	signal internal_LAST_ADDRESS_WRITTEN                      : std_logic_vector(8 downto 0);
	signal internal_FIRST_ADDRESS_WRITTEN                     : std_logic_vector(8 downto 0);
	signal internal_CONTINUE_WRITING                          : std_logic;
	signal internal_FIRST_ADDRESS_ALLOWED                     : std_logic_vector(8 downto 0);
	signal internal_LAST_ADDRESS_ALLOWED                      : std_logic_vector(8 downto 0);
	signal internal_AsicIn_SAMPLING_HOLD_MODE_C               : std_logic_vector(3 downto 0);
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS        : std_logic_vector(8 downto 0);
	signal internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE : std_logic;
	signal internal_AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C     : std_logic_vector(3 downto 0);
	signal internal_AsicIn_SAMPLING_TRACK_MODE_C              : std_logic_vector(3 downto 0);
	signal internal_CHIPSCOPE_ILA_SIGNALS                     : std_logic_vector(255 downto 0);
	signal internal_WINDOWS_TO_LOOK_BACK                      : unsigned(8 downto 0);

begin
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1) <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1);
	AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE	<= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE;
	LAST_ADDRESS_WRITTEN             <= internal_LAST_ADDRESS_WRITTEN;
	FIRST_ADDRESS_WRITTEN            <= internal_FIRST_ADDRESS_WRITTEN;
	internal_CONTINUE_WRITING        <= CONTINUE_WRITING;
	internal_FIRST_ADDRESS_ALLOWED   <= FIRST_ADDRESS_ALLOWED;
	internal_LAST_ADDRESS_ALLOWED    <= LAST_ADDRESS_ALLOWED;
	internal_WINDOWS_TO_LOOK_BACK    <= unsigned(WINDOWS_TO_LOOK_BACK);
	
	--Diagnostic access through ILA----------------
	gen_Chipscope_ILA : if (use_chipscope_ila = true) generate
		map_Chipscope_ILA : entity work.Chipscope_ILA
			port map (
				CONTROL => CHIPSCOPE_CONTROL,
				CLK => CLOCK_SST,
				TRIG0 => internal_CHIPSCOPE_ILA_SIGNALS );
		internal_CHIPSCOPE_ILA_SIGNALS(0) <= '0';
		internal_CHIPSCOPE_ILA_SIGNALS(8 downto 1) <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1);
		internal_CHIPSCOPE_ILA_SIGNALS(9) <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE;
		internal_CHIPSCOPE_ILA_SIGNALS(10) <= internal_CONTINUE_WRITING;
		internal_CHIPSCOPE_ILA_SIGNALS(19 downto 11) <= internal_LAST_ADDRESS_WRITTEN;
		internal_CHIPSCOPE_ILA_SIGNALS(28 downto 20) <= internal_FIRST_ADDRESS_WRITTEN;
		internal_CHIPSCOPE_ILA_SIGNALS(37 downto 29) <= internal_FIRST_ADDRESS_ALLOWED;
		internal_CHIPSCOPE_ILA_SIGNALS(46 downto 38) <= internal_LAST_ADDRESS_ALLOWED;
		internal_CHIPSCOPE_ILA_SIGNALS(255 downto 47) <= (others => '0');
	end generate;
	nogen_Chipscope_ILA : if (use_chipscope_ila = false) generate
		internal_CHIPSCOPE_ILA_SIGNALS(255 downto 0) <= (others => '0');
		CHIPSCOPE_CONTROL <= (others => 'Z');
	end generate;
	----------------------------------------------

	--The signals here are controlled by clock logic, so are wired appropriately
	internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(0) <= CLOCK_SST;	
	process(CLOCK_SST) begin
		for i in 0 to 3 loop
			internal_AsicIn_SAMPLING_HOLD_MODE_C(i) <= CLOCK_SST;
		end loop;
	end process;
	process(CLOCK_SSP) begin
		for i in 0 to 3 loop
			internal_AsicIn_SAMPLING_TRACK_MODE_C(i) <= CLOCK_SSP;
		end loop;
	end process;
	process(CLOCK_WRITE_STROBE) begin
		for i in 0 to 3 loop
			internal_AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C(i) <= CLOCK_WRITE_STROBE;
		end loop;
	end process;
	ODDR2_SST_GEN : for i in 0 to 3 generate
		ODDR2_SST_IN : ODDR2
			generic map(
				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
			port map (
				Q => AsicIn_SAMPLING_HOLD_MODE_C(i), -- 1-bit output data
				C0 => internal_AsicIn_SAMPLING_HOLD_MODE_C(i), -- 1-bit clock input
				C1 => not(internal_AsicIn_SAMPLING_HOLD_MODE_C(i)), -- 1-bit clock input
				CE => '1', -- 1-bit clock enable input
				D0 => '1', -- 1-bit data input (associated with C0)
				D1 => '0', -- 1-bit data input (associated with C1)
				R => '0', -- 1-bit reset input
				S => '0' -- 1-bit set input
		);
	end generate;
	ODDR2_SSP_GEN : for i in 0 to 3 generate
		ODDR2_SSP_IN : ODDR2
			generic map(
				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
			port map (
				Q => AsicIn_SAMPLING_TRACK_MODE_C(i), -- 1-bit output data
				C0 => internal_AsicIn_SAMPLING_TRACK_MODE_C(i), -- 1-bit clock input
				C1 => not(internal_AsicIn_SAMPLING_TRACK_MODE_C(i)), -- 1-bit clock input
				CE => '1', -- 1-bit clock enable input
				D0 => '1', -- 1-bit data input (associated with C0)
				D1 => '0', -- 1-bit data input (associated with C1)
				R => '0', -- 1-bit reset input
				S => '0' -- 1-bit set input		
		);
	end generate;
	ODDR2_WR_STRB_GEN : for i in 0 to 3 generate
		ODDR2_WR_STRB_IN : ODDR2
			generic map(
				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
			port map (
				Q => AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C(i), -- 1-bit output data
				C0 => internal_AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C(i), -- 1-bit clock input
				C1 => not(internal_AsicIn_SAMPLING_TO_STORAGE_TRANSFER_C(i)), -- 1-bit clock input
				CE => '1', -- 1-bit clock enable input
				D0 => '1', -- 1-bit data input (associated with C0)
				D1 => '0', -- 1-bit data input (associated with C1)
				R => '0', -- 1-bit reset input
				S => '0' -- 1-bit set input		
		);
	end generate;
	ODDR2_LSB_OF_WRITE_ADDR : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => AsicIn_SAMPLING_TO_STORAGE_ADDRESS(0), -- 1-bit output data
			C0 => internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(0), -- 1-bit clock input
			C1 => not(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(0)), -- 1-bit clock input
			CE => '1', -- 1-bit clock enable input
			D0 => '1', -- 1-bit data input (associated with C0)
			D1 => '0', -- 1-bit data input (associated with C1)
			R => '0', -- 1-bit reset input
			S => '0' -- 1-bit set input
	);	
	---------------------------------------------------------

	--Control the flow of writing to new blocks
	process(CLOCK_SST) 
		variable last_written : unsigned(8 downto 0) := (others => '0');
		variable underage     : unsigned(8 downto 0) := (others => '0');
	begin
		if falling_edge(CLOCK_SST) then
			if (internal_CONTINUE_WRITING = '1') then
				internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '1';
				if ( unsigned(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1)) >= unsigned(internal_LAST_ADDRESS_ALLOWED(8 downto 1)) ) then
					internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1) <= internal_FIRST_ADDRESS_ALLOWED(8 downto 1);
				else
					internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1) <= std_logic_vector( unsigned(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1)) + 1 );
				end if;
			else
				internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS_ENABLE <= '0';				
				internal_LAST_ADDRESS_WRITTEN <= internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1) & '1';
				last_written := unsigned(internal_AsicIn_SAMPLING_TO_STORAGE_ADDRESS(8 downto 1)) & '1';
-- This is the original version that enforced a lookback of 3
--				if (last_written >= unsigned(internal_FIRST_ADDRESS_ALLOWED) + 3) then				
--					internal_FIRST_ADDRESS_WRITTEN <= std_logic_vector(last_written - 3);
--				else
--					underage := last_written - unsigned(internal_FIRST_ADDRESS_ALLOWED);
--					internal_FIRST_ADDRESS_WRITTEN <= std_logic_vector(unsigned(internal_LAST_ADDRESS_ALLOWED) - underage);
--				end if;
-- This is the new version that allows a variable lookback
				if (last_written >= unsigned(internal_FIRST_ADDRESS_ALLOWED) + (internal_WINDOWS_TO_LOOK_BACK - 1) ) then				
					internal_FIRST_ADDRESS_WRITTEN <= std_logic_vector(last_written - (internal_WINDOWS_TO_LOOK_BACK - 1) );
				else
					underage := (internal_WINDOWS_TO_LOOK_BACK)-(last_written - unsigned(internal_FIRST_ADDRESS_ALLOWED));
					internal_FIRST_ADDRESS_WRITTEN <= std_logic_vector(unsigned(internal_LAST_ADDRESS_ALLOWED) - underage + 2);
				end if;
			end if;
		end if;
	end process;

end Behavioral;

