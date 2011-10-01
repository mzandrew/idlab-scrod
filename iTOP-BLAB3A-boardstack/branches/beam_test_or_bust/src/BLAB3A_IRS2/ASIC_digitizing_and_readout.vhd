----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:51:48 09/15/2011 
-- Design Name: 
-- Module Name:    ASIC_digitizing_and_readout - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Board_Stack_Definitions.ALL;

entity ASIC_digitizing_and_readout is
	Generic (
				WIDTH_OF_BLOCKRAM_DATA_BUS		: integer := 16;
				WIDTH_OF_BLOCKRAM_ADDRESS_BUS : integer := 13;
				use_chipscope_ila					: boolean := false
	);
	Port (
				AsicIn_DATA_BUS_CHANNEL_ADDRESS			: out std_logic_vector(2 downto 0);		
				AsicIn_DATA_BUS_SAMPLE_ADDRESS			: out std_logic_vector(5 downto 0);
				AsicIn_DATA_BUS_OUTPUT_ENABLE				: out std_logic;
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C0_R		: out std_logic_vector(3 downto 0);	
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C1_R		: out std_logic_vector(3 downto 0);
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C2_R		: out std_logic_vector(3 downto 0);
				AsicIn_DATA_BUS_OUTPUT_DISABLE_C3_R		: out std_logic_vector(3 downto 0);
				AsicIn_STORAGE_TO_WILK_ADDRESS			: out std_logic_vector(8 downto 0);
				AsicIn_STORAGE_TO_WILK_ADDRESS_ENABLE	: out std_logic;
				AsicIn_STORAGE_TO_WILK_ENABLE				: out std_logic;
				AsicIn_WILK_COUNTER_RESET					: out std_logic;
				AsicIn_WILK_COUNTER_START_C				: out std_logic_vector(3 downto 0);
				AsicIn_WILK_RAMP_ACTIVE						: out std_logic;
				AsicOut_DATA_BUS_C0							: in std_logic_vector(11 downto 0);
				AsicOut_DATA_BUS_C1							: in std_logic_vector(11 downto 0);
				AsicOut_DATA_BUS_C2							: in std_logic_vector(11 downto 0);	
				AsicOut_DATA_BUS_C3							: in std_logic_vector(11 downto 0);
				BLOCKRAM_COLUMN_SELECT						: in std_logic_vector(1 downto 0);
				BLOCKRAM_READ_ADDRESS						: in std_logic_vector(WIDTH_OF_BLOCKRAM_ADDRESS_BUS-1 downto 0);
				BLOCKRAM_READ_DATA							: out std_logic_vector(WIDTH_OF_BLOCKRAM_DATA_BUS-1 downto 0);
				LAST_ADDRESS_WRITTEN 						: in std_logic_vector(8 downto 0);
				TRIGGER_DIGITIZING							: in std_logic;
				CONTINUE_ANALOG_WRITING						: out std_logic;
				
				DONE_DIGITIZING								: out std_logic;
				DAQ_BUSY											: in std_logic;
				
				CLOCK_SST										: in std_logic;
				CLOCK_DAQ_INTERFACE							: in std_logic;
				
				CHIPSCOPE_CONTROL								: inout std_logic_vector(35 downto 0)
		);
end ASIC_digitizing_and_readout;

architecture Behavioral of ASIC_digitizing_and_readout is
	type STATE_TYPE is ( NOMINAL_SAMPLING, POST_TRIGGER_SAMPLING,
								ARM_WILKINSON,PERFORM_WILKINSON,
								ARM_READING,READ_TO_RAM,WAIT_FOR_READ_SETTLING,INCREMENT_ADDRESSES,
								START_READOUT_TO_DAQ, WAIT_FOR_READOUT_TO_DAQ);	
	signal internal_STATE          			: STATE_TYPE := NOMINAL_SAMPLING;

	signal internal_ASIC_DATA_BUS_ADDRESS_FLATTENED 	: std_logic_vector(8 downto 0);
	signal internal_ASIC_DATA_BUS_OUTPUT_ENABLE 			: std_logic;
	signal internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R		: std_logic_vector(3 downto 0);
	signal internal_ASIC_STORAGE_TO_WILK_ADDRESS			: std_logic_vector(8 downto 0);
	signal internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE : std_logic;
	signal internal_ASIC_STORAGE_TO_WILK_ENABLE			: std_logic;
	signal internal_ASIC_WILK_COUNTER_RESET				: std_logic;
	signal internal_ASIC_WILK_COUNTER_START				: std_logic;
	signal internal_ASIC_WILK_RAMP_ACTIVE					: std_logic;

	signal internal_BLOCKRAM_DATA_IN_ALL					: ASIC_BLOCKRAM_DATA;	
	signal internal_BLOCKRAM_DATA_OUT						: std_logic_vector(WIDTH_OF_BLOCKRAM_DATA_BUS-1 downto 0);
	signal internal_BLOCKRAM_DATA_OUT_ALL					: ASIC_BLOCKRAM_DATA;
	signal internal_BLOCKRAM_READ_ENABLE_R					: std_logic_vector(3 downto 0);
	signal internal_BLOCKRAM_WRITE_ENABLE 					: std_logic;
	signal internal_BLOCKRAM_WRITE_ENABLE_VEC				: std_logic_vector(0 downto 0);
	signal internal_BLOCKRAM_WRITE_ADDRESS					: std_logic_vector(WIDTH_OF_BLOCKRAM_ADDRESS_BUS-1 downto 0);
	
	signal internal_CONTINUE_ANALOG_WRITING				: std_logic;
	signal internal_DONE_DIGITIZING							: std_logic;
	
	signal internal_CHIPSCOPE_ILA_SIGNALS					: std_logic_vector(255 downto 0);	
begin
	-----------------------------------------------------------------------------
	--Signal mapping
	-----------------------------------------------------------------------------
	AsicIn_DATA_BUS_CHANNEL_ADDRESS			<= internal_ASIC_DATA_BUS_ADDRESS_FLATTENED(8 downto 6);
	AsicIn_DATA_BUS_SAMPLE_ADDRESS			<= internal_ASIC_DATA_BUS_ADDRESS_FLATTENED(5 downto 0);
	AsicIn_DATA_BUS_OUTPUT_ENABLE				<= internal_ASIC_DATA_BUS_OUTPUT_ENABLE;
	AsicIn_DATA_BUS_OUTPUT_DISABLE_C0_R		<= internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R;
	AsicIn_DATA_BUS_OUTPUT_DISABLE_C1_R		<= internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R;
	AsicIn_DATA_BUS_OUTPUT_DISABLE_C2_R		<= internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R;
	AsicIn_DATA_BUS_OUTPUT_DISABLE_C3_R		<= internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R;
	AsicIn_STORAGE_TO_WILK_ADDRESS			<= internal_ASIC_STORAGE_TO_WILK_ADDRESS;
	AsicIn_STORAGE_TO_WILK_ADDRESS_ENABLE	<= internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE;
	AsicIn_STORAGE_TO_WILK_ENABLE				<= internal_ASIC_STORAGE_TO_WILK_ENABLE;
	AsicIn_WILK_COUNTER_RESET					<= internal_ASIC_WILK_COUNTER_RESET;
	AsicIn_WILK_COUNTER_START_C				<= (others => internal_ASIC_WILK_COUNTER_START);
	AsicIn_WILK_RAMP_ACTIVE						<= internal_ASIC_WILK_RAMP_ACTIVE;
	CONTINUE_ANALOG_WRITING						<= internal_CONTINUE_ANALOG_WRITING;
	internal_BLOCKRAM_DATA_IN_ALL(0)			<= x"0" & AsicOut_DATA_BUS_C0;
	internal_BLOCKRAM_DATA_IN_ALL(1)			<= x"0" & AsicOut_DATA_BUS_C1;
	internal_BLOCKRAM_DATA_IN_ALL(2)			<= x"0" & AsicOut_DATA_BUS_C2;
	internal_BLOCKRAM_DATA_IN_ALL(3)			<= x"0" & AsicOut_DATA_BUS_C3;	
	internal_BLOCKRAM_WRITE_ENABLE_VEC(0)	<= internal_BLOCKRAM_WRITE_ENABLE;
	DONE_DIGITIZING 								<= internal_DONE_DIGITIZING;
	BLOCKRAM_READ_DATA							<= internal_BLOCKRAM_DATA_OUT;
	-----------------------------------------------------------------------------
	--Instantiate the four BLOCKRAMs that we need to store the ASIC data
	-----------------------------------------------------------------------------
	gen_blockram_for_ASIC_column : for i in 0 to 3 generate
		map_blockram_for_ASIC_C : entity work.blockram_for_ASIC_column
		  PORT MAP (
			 clka => CLOCK_SST,
			 wea => internal_BLOCKRAM_WRITE_ENABLE_VEC,
			 addra => internal_BLOCKRAM_WRITE_ADDRESS,
			 dina => internal_BLOCKRAM_DATA_IN_ALL(i),
			 clkb => CLOCK_DAQ_INTERFACE,
			 enb => internal_BLOCKRAM_READ_ENABLE_R(i),
			 addrb => BLOCKRAM_READ_ADDRESS,
			 doutb => internal_BLOCKRAM_DATA_OUT_ALL(i)
		  );	
	end generate;
	-----------------------------------------------------------------------------
	--Multiplex the data from one of the four blockrams out to the main block,
	--Including setting the read enable high for the blockram of interest.
	-----------------------------------------------------------------------------
	process(BLOCKRAM_COLUMN_SELECT,internal_BLOCKRAM_DATA_OUT_ALL) begin
		internal_BLOCKRAM_DATA_OUT <= internal_BLOCKRAM_DATA_OUT_ALL( to_integer(unsigned(BLOCKRAM_COLUMN_SELECT)) );
		for i in 0 to 3 loop 
			if (i = to_integer(unsigned(BLOCKRAM_COLUMN_SELECT))) then
				internal_BLOCKRAM_READ_ENABLE_R(i) <= '1';
			else
				internal_BLOCKRAM_READ_ENABLE_R(i) <= '0';
			end if;
		end loop;
	end process;

	-----------------------------------------------------
	--Perform the actual digitizing and readout here-----
	-----------------------------------------------------
	process(CLOCK_SST)
		variable delay_counter : integer range 0 to 1023 := 0;
		constant time_to_arm_wilkinson : integer := 3; -- A guess... should just buy some extra time for logic to settle
		constant time_to_wilkinson : integer := 128; -- 6.2 us @ 21.2 MHz	
		constant read_to_ram_settling_time : integer := 3; --May be able to trim this down to 1 clock cycle, but needs to be checked
		variable windows_read_out : integer range 0 to 1023 := 0;
		variable samples_read_out_this_window : integer range 0 to 1023;
		variable asic_to_read_out : integer range 0 to 8 := 0;
		constant asics_to_read_out : integer := 4;
		constant windows_to_sample_after_trigger : integer := 0;	
		constant windows_to_read_out : integer := 4;
	begin
		if (falling_edge(CLOCK_SST)) then
			case internal_STATE is
				when NOMINAL_SAMPLING =>
					internal_ASIC_DATA_BUS_ADDRESS_FLATTENED 		<= (others => '0');
					internal_ASIC_DATA_BUS_OUTPUT_ENABLE 			<= '0';
					internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R		<= (others => '1');
					internal_ASIC_STORAGE_TO_WILK_ADDRESS			<= (others => '0');
					internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE <= '0';
					internal_ASIC_STORAGE_TO_WILK_ENABLE			<= '0';
					internal_ASIC_WILK_COUNTER_RESET					<= '1';
					internal_ASIC_WILK_COUNTER_START					<= '0';
					internal_ASIC_WILK_RAMP_ACTIVE					<= '0';
					internal_BLOCKRAM_WRITE_ENABLE					<= '0';
					internal_DONE_DIGITIZING							<= '0';	
					internal_CONTINUE_ANALOG_WRITING					<= '1';
					if (TRIGGER_DIGITIZING = '1') then
						--Move to the next state where we might want to continue sampling 
						--a bit after the trigger.
						internal_STATE <= POST_TRIGGER_SAMPLING;						
						delay_counter := 0;
					end if;
				when POST_TRIGGER_SAMPLING =>
					--After extra time to let the LAST_ADDRESS_WRITTEN bus settle, move to the next state
					--Two cycles appears to be the minimum here.
					if (delay_counter >= windows_to_sample_after_trigger + 2) then
						internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE <= '1';
						internal_ASIC_STORAGE_TO_WILK_ADDRESS 			<= std_logic_vector(unsigned(LAST_ADDRESS_WRITTEN) - to_unsigned(windows_to_read_out - 1,9));
						internal_ASIC_STORAGE_TO_WILK_ENABLE 			<= '1';
						asic_to_read_out 					:= 0;
						windows_read_out 					:= 0;						
						samples_read_out_this_window 	:= 0;
						internal_STATE <= ARM_WILKINSON;
					elsif (delay_counter >= windows_to_sample_after_trigger) then
						--Send the signal to the sampling block to stop writing to analog memory
						internal_CONTINUE_ANALOG_WRITING			<= '0';
						delay_counter := delay_counter + 1;
					else
						delay_counter := delay_counter + 1;
					end if;
				when ARM_WILKINSON =>
					internal_ASIC_WILK_COUNTER_RESET <= '0';
					if (delay_counter >= time_to_arm_wilkinson) then
						delay_counter := 0;
						internal_STATE <= PERFORM_WILKINSON;
					else
						delay_counter := delay_counter + 1;
					end if;
				when PERFORM_WILKINSON =>
					internal_ASIC_WILK_COUNTER_START <= '1';
					internal_ASIC_WILK_RAMP_ACTIVE <= '1';
					if (delay_counter >= time_to_wilkinson) then
						delay_counter := 0;			
						samples_read_out_this_window := 0;
						internal_ASIC_WILK_COUNTER_START <= '0';
						internal_ASIC_WILK_RAMP_ACTIVE <= '0';
						internal_STATE <= ARM_READING;
					else
						delay_counter := delay_counter + 1;
					end if;
				when ARM_READING =>
					internal_ASIC_DATA_BUS_ADDRESS_FLATTENED  <= (others => '0');	
					internal_ASIC_DATA_BUS_OUTPUT_ENABLE 		<= '1';
					for i in 0 to 3 loop
						if (i = asic_to_read_out) then
							internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R(i) <= '0';
						else
							internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R(i) <= '1';
						end if;
					end loop;
					internal_STATE <= READ_TO_RAM;				
				when READ_TO_RAM =>
					internal_BLOCKRAM_WRITE_ENABLE <= '0';
					-- If we've read out 512 samples or more then we can move on to the next
					-- ASIC, same window.
					if ( samples_read_out_this_window >= 512 ) then
						samples_read_out_this_window := 0;
						asic_to_read_out := asic_to_read_out + 1;					
						-- If we've already read 4 ASICs then we can move on to the next window,
						-- starting again at asic 0.
						if (asic_to_read_out >= asics_to_read_out) then
							asic_to_read_out := 0;
							windows_read_out := windows_read_out + 1;
							-- If we've already read all windows, we're done
							if (windows_read_out >= windows_to_read_out) then
								windows_read_out := 0;
								delay_counter := 0;
								internal_STATE <= START_READOUT_TO_DAQ;
							-- We haven't read out all windows yet.  Restart from ASIC 0 and
							-- move to the next window and digitize.
							else
								internal_ASIC_STORAGE_TO_WILK_ADDRESS(8 downto 0) <= std_logic_vector( unsigned(internal_ASIC_STORAGE_TO_WILK_ADDRESS(8 downto 0)) + 1);
								delay_counter := 0;
								internal_ASIC_DATA_BUS_OUTPUT_ENABLE <= '0';
								internal_ASIC_WILK_COUNTER_RESET <= '1';
								internal_STATE <= ARM_WILKINSON;
							end if;
						-- We haven't read all 4 ASICs.  Set the data bus enables and continue
						-- with the next ASIC.
						else
							for i in 0 to 3 loop
								if (i = asic_to_read_out) then
									internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R(i) <= '0';
								else
									internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R(i) <= '1';
								end if;
							end loop;
							internal_STATE <= WAIT_FOR_READ_SETTLING;
						end if;
					-- We haven't finished this ASIC yet, move on to the next sample
					else
						delay_counter := 0;
						internal_STATE <= WAIT_FOR_READ_SETTLING;
					end if;				
				when WAIT_FOR_READ_SETTLING =>
					if (delay_counter = read_to_ram_settling_time) then	
						internal_BLOCKRAM_WRITE_ENABLE <= '1';
						delay_counter := delay_counter + 1;
					elsif (delay_counter > read_to_ram_settling_time) then
						internal_BLOCKRAM_WRITE_ENABLE <= '0';
						internal_STATE <= INCREMENT_ADDRESSES;
						delay_counter := 0;					
					else
						delay_counter := delay_counter + 1;
					end if;				
				when INCREMENT_ADDRESSES =>
					internal_BLOCKRAM_WRITE_ADDRESS <= std_logic_vector(unsigned(internal_BLOCKRAM_WRITE_ADDRESS) + 1);
					samples_read_out_this_window := samples_read_out_this_window + 1;
					internal_ASIC_DATA_BUS_ADDRESS_FLATTENED <= std_logic_vector(unsigned(internal_ASIC_DATA_BUS_ADDRESS_FLATTENED) + 1);
					internal_STATE <= READ_TO_RAM;				
				when START_READOUT_TO_DAQ =>
					internal_DONE_DIGITIZING <= '1';
					if (DAQ_BUSY = '1') then
						internal_STATE <= WAIT_FOR_READOUT_TO_DAQ;
					end if;
				when WAIT_FOR_READOUT_TO_DAQ =>
					internal_DONE_DIGITIZING <= '0';				
					if (DAQ_BUSY = '0') then
						internal_STATE <= NOMINAL_SAMPLING;
					end if;
				when others =>
					internal_STATE <= NOMINAL_SAMPLING;
			end case;
		end if;
	end process;
	
	
	-----------------------------------------------------------------
	-----Diagnostic access through ILA-------------------------------
	-----------------------------------------------------------------
	--Diagnostic access through ILA----------------
	gen_Chipscope_ILA : if (use_chipscope_ila = true) generate
		map_Chipscope_ILA : entity work.Chipscope_ILA
			port map (
				CONTROL => CHIPSCOPE_CONTROL,
				CLK => CLOCK_SST,
				TRIG0 => internal_CHIPSCOPE_ILA_SIGNALS 
			);
		internal_CHIPSCOPE_ILA_SIGNALS(2 downto 0) 	<= internal_ASIC_DATA_BUS_ADDRESS_FLATTENED(8 downto 6); --CH
		internal_CHIPSCOPE_ILA_SIGNALS(8 downto 3) 	<= internal_ASIC_DATA_BUS_ADDRESS_FLATTENED(5 downto 0); --SAMPLE
		internal_CHIPSCOPE_ILA_SIGNALS(9) 				<= internal_ASIC_DATA_BUS_OUTPUT_ENABLE;
		internal_CHIPSCOPE_ILA_SIGNALS(13 downto 10) <= internal_ASIC_DATA_BUS_OUTPUT_DISABLE_R;
		internal_CHIPSCOPE_ILA_SIGNALS(22 downto 14) <= internal_ASIC_STORAGE_TO_WILK_ADDRESS;
		internal_CHIPSCOPE_ILA_SIGNALS(23)				<= internal_ASIC_STORAGE_TO_WILK_ADDRESS_ENABLE;
		internal_CHIPSCOPE_ILA_SIGNALS(24)				<= internal_ASIC_STORAGE_TO_WILK_ENABLE;
		internal_CHIPSCOPE_ILA_SIGNALS(25)				<= internal_ASIC_WILK_COUNTER_RESET;
		internal_CHIPSCOPE_ILA_SIGNALS(26)				<= internal_ASIC_WILK_COUNTER_START;
		internal_CHIPSCOPE_ILA_SIGNALS(27)				<= internal_ASIC_WILK_RAMP_ACTIVE;
		internal_CHIPSCOPE_ILA_SIGNALS(28)				<= internal_CONTINUE_ANALOG_WRITING;
		internal_CHIPSCOPE_ILA_SIGNALS(40 downto 29)	<= AsicOut_DATA_BUS_C0;
		internal_CHIPSCOPE_ILA_SIGNALS(52 downto 41)	<= AsicOut_DATA_BUS_C1;
		internal_CHIPSCOPE_ILA_SIGNALS(64 downto 53)	<= AsicOut_DATA_BUS_C2;
		internal_CHIPSCOPE_ILA_SIGNALS(76 downto 65)	<= AsicOut_DATA_BUS_C3;
		internal_CHIPSCOPE_ILA_SIGNALS(77) 				<= internal_BLOCKRAM_WRITE_ENABLE;
		internal_CHIPSCOPE_ILA_SIGNALS(78)				<= internal_DONE_DIGITIZING;
		internal_CHIPSCOPE_ILA_SIGNALS(94 downto 79)	<= internal_BLOCKRAM_DATA_OUT;
		internal_CHIPSCOPE_ILA_SIGNALS(103 downto 95)<= LAST_ADDRESS_WRITTEN;
		internal_CHIPSCOPE_ILA_SIGNALS(104)				<= TRIGGER_DIGITIZING;
		internal_CHIPSCOPE_ILA_SIGNALS(106 downto 105) 	<= BLOCKRAM_COLUMN_SELECT;
		internal_CHIPSCOPE_ILA_SIGNALS(119 downto 107) 	<= BLOCKRAM_READ_ADDRESS;
		internal_CHIPSCOPE_ILA_SIGNALS(255 downto 120)	<= (others => '0');
	end generate;
	--Or connect up to ground if we don't want ILA
	nogen_Chipscope_ILA : if (use_chipscope_ila = false) generate
		internal_CHIPSCOPE_ILA_SIGNALS(255 downto 0) <= (others => '0');
		CHIPSCOPE_CONTROL <= (others => 'Z');
	end generate;
	----------------------------------------------	

end Behavioral;

