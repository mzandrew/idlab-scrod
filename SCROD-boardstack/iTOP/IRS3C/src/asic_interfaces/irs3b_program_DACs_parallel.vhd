----For simulation only.  Also change libraries (see comment on line ~18)
----                      and comment/uncomment lines 364-461
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--package simulate_dac is
--	subtype DAC_setting_C_R_CH is std_logic_vector(11 downto 0);
--	subtype DAC_setting_C_R    is std_logic_vector(11 downto 0);
--	subtype DAC_setting        is std_logic_vector(11 downto 0);
--	subtype Timing_setting     is std_logic_vector(7 downto 0);
--	subtype Timing_setting_C_R is std_logic_vector(7 downto 0);
--end simulate_dac;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;
use work.IRS3B_CarrierRevB_DAC_definitions.all; -- Definitions in irs3b_carrierRevB_DAC_definitions.vhd
--use work.simulate_dac.all; --Simulation only... uncomment above if you're going to use this

entity irs3b_program_dacs_parallel is
   Port ( 
		CLK                          :  in STD_LOGIC;
		CE                           :  in STD_LOGIC;
		SST_CLK                      :  in STD_LOGIC;
		PCLK                         : out STD_LOGIC_VECTOR(15 downto 0);
		SCLK                         : out STD_LOGIC;
		SIN                          : out STD_LOGIC;
		SHOUT                        :  in STD_LOGIC;
		--ASIC DAC values
		--DAC_setting indicates a global for the whole boardstack
		--DAC_setting_C_R indicates a (4)(4) to set DACs separately by row/col
		--DAC_setting_C_R_CH indicates a (4)(4)(8) to set DACs separately by row/col/ch
		ASIC_TRIG_THRESH             : in DAC_setting_C_R_CH;
		ASIC_DAC_BUF_BIASES          : in DAC_setting;
		ASIC_DAC_BUF_BIAS_ISEL       : in DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJP      : in DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJN      : in DAC_setting;
		ASIC_VBIAS                   : in DAC_setting_C_R;
		ASIC_VBIAS2                  : in DAC_setting_C_R;
		ASIC_REG_TRG                 : in Timing_setting; --Not a DAC but set with the DACs.  Global for all ASICs.
		ASIC_WBIAS                   : in DAC_setting_C_R;
		ASIC_VADJP                   : in DAC_setting16_C_R;
		ASIC_VADJN                   : in DAC_setting16_C_R;
		ASIC_VDLY                    : in DAC_setting_C_R;
		ASIC_TRG_BIAS                : in DAC_setting;
		ASIC_TRG_BIAS2               : in DAC_setting;
		ASIC_TRGTHREF                : in DAC_setting;
		ASIC_CMPBIAS                 : in DAC_setting;
		ASIC_CMPBIAS2                 : in DAC_setting;
		ASIC_PUBIAS                  : in DAC_setting;
		ASIC_SBBIAS                  : in DAC_setting;
		ASIC_ISEL                    : in DAC_setting;
		--Timing settings go here too, since they're set with the DACs
		ASIC_TIMING_SSP_LEADING      : in Timing_setting_C_R;
		ASIC_TIMING_SSP_TRAILING     : in Timing_setting_C_R;
		ASIC_TIMING_WR_STRB_LEADING  : in Timing_setting_C_R;
		ASIC_TIMING_WR_STRB_TRAILING : in Timing_setting_C_R;
		ASIC_TIMING_S1_LEADING       : in Timing_setting_C_R;
		ASIC_TIMING_S1_TRAILING      : in Timing_setting_C_R;
		ASIC_TIMING_S2_LEADING       : in Timing_setting_C_R;
		ASIC_TIMING_S2_TRAILING      : in Timing_setting_C_R;
		ASIC_TIMING_PHASE_LEADING    : in Timing_setting_C_R;
		ASIC_TIMING_PHASE_TRAILING   : in Timing_setting_C_R;
		ASIC_TIMING_GENERATOR_REG    : in Timing_setting
	 );
end irs3b_program_dacs_parallel;

architecture Behavioral of irs3b_program_dacs_parallel is
	--State machine signals
	type dac_state is (IDLE, LOAD_BIT, SEND_BIT, NEXT_BIT, PREPARE_LATCH, LATCH_BUS_DATA, WAIT_FOR_LATCH_BUS_DATA, PREPARE_LOAD, LOAD_DESTINATION, WAIT_FOR_LOAD_DESTINATION, INCREMENT, LATCH_NEXT_VALUE);
	signal internal_STATE      : dac_state := IDLE;
	signal internal_NEXT_STATE : dac_state := IDLE;
	signal internal_STATE_MONITOR : std_logic_vector(3 downto 0);
	--PCLK state machine (on SST domain)
	type pclk_state is (IDLE, ARM, ACTIVE);
	signal internal_PCLK_STATE      : pclk_state := IDLE;
	signal internal_NEXT_PCLK_STATE : pclk_state := IDLE;
	--PCLK/SCLK signals.  PCLK is coordinated between two state machines
	--to sync up to SST.
	signal internal_SET_PCLK_SINGLE : std_logic;
	signal internal_PCLK_READY      : std_logic;
	signal internal_PCLK_SINGLE     : std_logic;
	signal internal_PCLK  : std_logic_vector(15 downto 0);
	signal internal_SCLK  : std_logic;
	signal internal_SIN   : std_logic;
	--Counter to grab row/col for settings that are unique
	signal internal_ROW_COL_COUNTER    : unsigned(3 downto 0) := (others => '0');
	signal internal_ROW                : integer := 0;
	signal internal_COL                : integer := 0;
	signal internal_INCREMENT_ROWCOL   : std_logic := '0';
	signal internal_RESET_ROWCOL       : std_logic := '0';
	--Determine what register address to read
	signal internal_REGISTER_COUNTER   : unsigned(5 downto 0) := (others => '0');
	signal internal_INCREMENT_REGISTER : std_logic := '0';
	signal internal_RESET_REGISTER     : std_logic := '0';
	signal internal_REG_ADDR           : std_logic_vector(5 downto 0);
	--Counter for choosing which bit to send
	signal internal_BIT_COUNTER        : integer range 0 to 17 := 0;
	signal internal_INCREMENT_BIT      : std_logic := '0';
	signal internal_RESET_BIT_COUNTER  : std_logic := '0';
	--Generic counter for delays
	signal internal_GENERIC_COUNTER    : unsigned(3 downto 0) := (others => '0');
	signal internal_INCREMENT_COUNTER  : std_logic := '0';
	signal internal_RESET_COUNTER      : std_logic := '0';
	--Types for different register updates
	type reg_type is (global, unique); 
	type all_reg_types is array(48 downto 0) of reg_type;
	signal reg_map : all_reg_types;
	--Register that has the DAC value we'd like to load
	signal internal_REG_VALUE_TO_LOAD : std_logic_vector(11 downto 0);
	signal internal_LATCHED_REG_VALUE : std_logic_vector(11 downto 0);
	signal internal_LATCH_REG_VALUE   : std_logic := '0';
	signal internal_SERIAL_VALUE      : std_logic_vector(17 downto 0);
	
--	--Chipscope debugging signals
--	signal internal_CHIPSCOPE_CONTROL : std_logic_vector(35 downto 0);
--	signal internal_CHIPSCOPE_ILA     : std_logic_vector(127 downto 0);
--	signal internal_CHIPSCOPE_ILA_REG : std_logic_vector(127 downto 0);
	

begin
	--Connections to the top
	PCLK <= internal_PCLK;
	SCLK <= internal_SCLK;
	SIN  <= internal_SIN;
	
	-------------------------
	--Primary state machine--
	-------------------------
	--Output logic
	process(internal_STATE,internal_SERIAL_VALUE,internal_REGISTER_COUNTER,reg_map,internal_BIT_COUNTER) begin
		--Defaults here
		internal_LATCH_REG_VALUE    <= '0';
		internal_SET_PCLK_SINGLE    <= '0';
		internal_SCLK               <= '0';
		internal_SIN                <= '0';
		internal_RESET_ROWCOL       <= '0';
		internal_RESET_BIT_COUNTER  <= '0';
		internal_RESET_ROWCOL       <= '0';
		internal_INCREMENT_BIT      <= '0';
		internal_INCREMENT_REGISTER <= '0';
		internal_RESET_REGISTER     <= '0';
		internal_INCREMENT_ROWCOL   <= '0';
		--
		case(internal_STATE) is
			when IDLE =>
				internal_LATCH_REG_VALUE    <= '1';
				internal_RESET_REGISTER     <= '1';
				internal_RESET_BIT_COUNTER  <= '1';
				internal_RESET_ROWCOL       <= '1';
			when LOAD_BIT =>
				internal_SIN                <= internal_SERIAL_VALUE(17-internal_BIT_COUNTER);
			when SEND_BIT => 
				internal_SIN                <= internal_SERIAL_VALUE(17-internal_BIT_COUNTER);
				internal_SCLK               <= '1';
			when NEXT_BIT =>
				internal_SIN                <= internal_SERIAL_VALUE(17-internal_BIT_COUNTER);
				internal_INCREMENT_BIT      <= '1';
			when PREPARE_LATCH =>
			when LATCH_BUS_DATA =>
				internal_SET_PCLK_SINGLE    <= '1';
			when WAIT_FOR_LATCH_BUS_DATA => 
			--
			when PREPARE_LOAD =>
				internal_SIN                <= '1';
			when LOAD_DESTINATION => 
				internal_SET_PCLK_SINGLE    <= '1';
				internal_SIN                <= '1';
				internal_RESET_BIT_COUNTER  <= '1';
			when WAIT_FOR_LOAD_DESTINATION =>
				internal_SIN                <= '1';
			when INCREMENT =>
				if (reg_map(to_integer(internal_REGISTER_COUNTER)) = unique) then
					if (internal_ROW_COL_COUNTER < 15) then
						internal_INCREMENT_ROWCOL   <= '1';
					else
						internal_INCREMENT_REGISTER <= '1';
						internal_RESET_ROWCOL       <= '1';
					end if;
				else 
					internal_RESET_ROWCOL       <= '1';
					internal_INCREMENT_REGISTER <= '1';
				end if;
			when LATCH_NEXT_VALUE =>
				internal_LATCH_REG_VALUE <= '1';
		end case;
	end process;

	--Next state selection logic
	process(internal_STATE, internal_BIT_COUNTER, internal_GENERIC_COUNTER,reg_map,internal_REGISTER_COUNTER, internal_ROW_COl_COUNTER) begin
		case(internal_STATE) is
			when IDLE =>      
				internal_NEXT_STATE <= LOAD_BIT;
			when LOAD_BIT =>
				internal_NEXT_STATE <= SEND_BIT;
			when SEND_BIT => 
				internal_NEXT_STATE <= NEXT_BIT;
			when NEXT_BIT =>
				if (internal_BIT_COUNTER < 17) then
					internal_NEXT_STATE <= LOAD_BIT;
				else
					internal_NEXT_STATE <= PREPARE_LATCH;
				end if;
			when PREPARE_LATCH =>
				internal_NEXT_STATE <= LATCH_BUS_DATA;
			when LATCH_BUS_DATA =>
				if (internal_PCLK_SINGLE = '0') then
					internal_NEXT_STATE <= LATCH_BUS_DATA;
				else 
					internal_NEXT_STATE <= WAIT_FOR_LATCH_BUS_DATA;
				end if;
			when WAIT_FOR_LATCH_BUS_DATA => 
				if (internal_PCLK_READY = '0') then
					internal_NEXT_STATE <= WAIT_FOR_LATCH_BUS_DATA;
				else 
					internal_NEXT_STATE <= PREPARE_LOAD;
				end if;
			when PREPARE_LOAD =>
				internal_NEXT_STATE <= LOAD_DESTINATION;
			when LOAD_DESTINATION => 
				if (internal_PCLK_SINGLE = '0') then
					internal_NEXT_STATE <= LOAD_DESTINATION;
				else 
					internal_NEXT_STATE <= WAIT_FOR_LOAD_DESTINATION;
				end if;
			when WAIT_FOR_LOAD_DESTINATION =>
				if (internal_PCLK_READY = '0') then
					internal_NEXT_STATE <= WAIT_FOR_LOAD_DESTINATION;
				else
					internal_NEXT_STATE <= INCREMENT;
				end if;
			when INCREMENT =>
				if (reg_map(to_integer(internal_REGISTER_COUNTER)) = global or internal_ROW_COL_COUNTER = 15) then
					if (internal_REGISTER_COUNTER < 48) then
						internal_NEXT_STATE <= LATCH_NEXT_VALUE;
					else
						internal_NEXT_STATE <= IDLE;
					end if;
				else 
					internal_NEXT_STATE <= LATCH_NEXT_VALUE;
				end if;
			when LATCH_NEXT_VALUE =>
				internal_NEXT_STATE <= LOAD_BIT;
			when others =>
				internal_NEXT_STATE <= IDLE;
		end case;
	end process;

	--Synchronous update to next state
	process(CLK, CE) begin
		if (CE = '1') then
			if (rising_edge(CLK)) then
				internal_STATE <= internal_NEXT_STATE;
			end if;
		end if;
	end process;


	-----------------
	--SUPPORT LOGIC--
	-----------------
	
	--List which registers should be done globally and which individually by ASIC
	--Numbers in the comments correspond to Gary's notation in the register map spreadsheet
	reg_map( 0) <= unique; -- 1: THR1
	reg_map( 1) <= unique; -- 2: THR2
	reg_map( 2) <= unique; -- 3: THR3
	reg_map( 3) <= unique; -- 4: THR4
	reg_map( 4) <= unique; -- 5: THR5
	reg_map( 5) <= unique; -- 6: THR6
	reg_map( 6) <= unique; -- 7: THR7
	reg_map( 7) <= unique; -- 8: THR8
	reg_map( 8) <= global; -- 9: VBDBIAS
	reg_map( 9) <= unique; --10: VBIAS
	reg_map(10) <= unique; --11: VBIAS2
	reg_map(11) <= global; --12: MiscReg (LSB: TRG_SIGN)
	reg_map(12) <= global; --13: WBDbias
	reg_map(13) <= unique; --14: Wbias
	reg_map(14) <= global; --15: TCDbias
	reg_map(15) <= global; --16: TRGbias
	reg_map(16) <= global; --17: THDbias
	reg_map(17) <= global; --18: Tbbias
	reg_map(18) <= global; --19: TRGDbias
	reg_map(19) <= global; --20: TRGbias2
	reg_map(20) <= global; --21: TRGthref
	reg_map(21) <= unique; --22: LeadSSPin
	reg_map(22) <= unique; --23: TrailSSPin
	reg_map(23) <= unique; --24: LeadS1
	reg_map(24) <= unique; --25: TrailS1
	reg_map(25) <= unique; --26: LeadS2
	reg_map(26) <= unique; --27: TrailS2
	reg_map(27) <= unique; --28: LeadPHASE
	reg_map(28) <= unique; --29: TrailPHASE
	reg_map(29) <= unique; --30: LeadWR_STRB
	reg_map(30) <= unique; --31: TrailWR_STRB
	reg_map(31) <= global; --32: TimGenReg
	reg_map(32) <= global; --33: PDDbias
	reg_map(33) <= global; --34: CMPbias
	reg_map(34) <= global; --35: PUDbias
	reg_map(35) <= global; --36: PUbias
	reg_map(36) <= global; --37: SBDbias
	reg_map(37) <= global; --38: Sbbias
	reg_map(38) <= global; --39: ISDbias
	reg_map(39) <= global; --40: ISEL
	reg_map(40) <= global; --41: VDDbias
	reg_map(41) <= unique; --42: Vdly
	reg_map(42) <= global; --43: VAPDbias
	reg_map(43) <= unique; --44: VadjP
	reg_map(44) <= global; --45: VANDbias
	reg_map(45) <= unique; --46: VadjN
	reg_map(46) <= global; --62: Start_WilkMon
	reg_map(47) <= global; --64: Pulse test trigger
	reg_map(48) <= global; --48: CMPbias2

	--Register increment
	process(CLK, CE, internal_INCREMENT_REGISTER) begin
		if (CE = '1') then
			if (rising_edge(CLK)) then
				if (internal_RESET_REGISTER = '1') then
					internal_REGISTER_COUNTER <= (others => '0');
				elsif (internal_INCREMENT_REGISTER = '1') then
					internal_REGISTER_COUNTER <= internal_REGISTER_COUNTER + 1;
				end if;
			end if;
		end if;
	end process;
	--Map out what we actually update on each cycle
	--Usually this is just the counter value, but after registers 0-45
	--  we skip ahead to register 61 to start the Wilk monitor.
	process(internal_REGISTER_COUNTER) 
	   constant reg47 : integer := 47;
		constant reg61 : integer := 61;
		constant reg63 : integer := 63;
	begin
		if (internal_REGISTER_COUNTER = 46) then
			internal_REG_ADDR <= std_logic_vector(to_unsigned(reg47,internal_REG_ADDR'length));
		elsif (internal_REGISTER_COUNTER = 47) then
			internal_REG_ADDR <= std_logic_vector(to_unsigned(reg61,internal_REG_ADDR'length));
		elsif (internal_REGISTER_COUNTER = 48) then
			internal_REG_ADDR <= std_logic_vector(to_unsigned(reg63,internal_REG_ADDR'length));
		else 
			internal_REG_ADDR <= std_logic_vector(internal_REGISTER_COUNTER);
		end if;
	end process;
	
	--Row/column counter increment
	process(CLK, CE, internal_INCREMENT_ROWCOL) begin
		if (CE = '1') then
			if (rising_edge(CLK)) then
				if (internal_RESET_ROWCOL = '1') then
					internal_ROW_COL_COUNTER <= (others => '0');
				elsif (internal_INCREMENT_ROWCOL = '1') then
					internal_ROW_COL_COUNTER <= internal_ROW_COL_COUNTER + 1;
				end if;
			end if;
		end if;
	end process;
	--Grab the row and col
	process(internal_ROW_COL_COUNTER) begin
		internal_ROW <= to_integer(unsigned(internal_ROW_COL_COUNTER(1 downto 0)));
		internal_COL <= to_integer(unsigned(internal_ROW_COL_COUNTER(3 downto 2)));
	end process;

	--Bit counter increment
	process(CLK,CE,internal_INCREMENT_BIT) begin
		if (CE = '1') then
			if (rising_edge(CLK)) then
				if (internal_RESET_BIT_COUNTER = '1') then
					internal_BIT_COUNTER <= 0;
				elsif (internal_INCREMENT_BIT = '1' and internal_BIT_COUNTER < 17) then
					internal_BIT_COUNTER <= internal_BIT_COUNTER + 1;
				end if;
			end if;
		end if;
	end process;

	--Generic counter for setting length of PCLK
	--This is done on the SST clock domain now
	process(SST_CLK,internal_INCREMENT_COUNTER) begin
		if (rising_edge(SST_CLK)) then
			if (internal_RESET_COUNTER = '1') then
				internal_GENERIC_COUNTER <= (others => '0');
			elsif (internal_INCREMENT_COUNTER = '1') then
				internal_GENERIC_COUNTER <= internal_GENERIC_COUNTER + 1;
			end if;
		end if;
	end process;	

	--Simple state machine for setting PCLK, coordinates between SST domain
	--domain and main clock domain
	process(internal_PCLK_STATE, internal_SET_PCLK_SINGLE, internal_GENERIC_COUNTER) 
		constant constant_PCLK_CYCLES_HIGH : integer := 10;
	begin
		case(internal_PCLK_STATE) is
			when IDLE =>
				internal_PCLK_READY        <= '1';
				internal_PCLK_SINGLE       <= '0';
				internal_RESET_COUNTER     <= '1';
				internal_INCREMENT_COUNTER <= '0';
				if (internal_SET_PCLK_SINGLE = '1') then
					internal_NEXT_PCLK_STATE <= ACTIVE;
				else
					internal_NEXT_PCLK_STATE <= IDLE;
				end if;
			when ARM =>
				internal_PCLK_READY        <= '0';
				internal_PCLK_SINGLE       <= '0';
				internal_RESET_COUNTER     <= '1';
				internal_INCREMENT_COUNTER <= '0';
				internal_NEXT_PCLK_STATE   <= ACTIVE;
			when ACTIVE =>
				internal_PCLK_READY        <= '0';
				internal_PCLK_SINGLE       <= '1';
				internal_RESET_COUNTER     <= '0';
				internal_INCREMENT_COUNTER <= '1';
				if (internal_GENERIC_COUNTER < constant_PCLK_CYCLES_HIGH) then
					internal_NEXT_PCLK_STATE <= ACTIVE;
				else
					internal_NEXT_PCLK_STATE <= IDLE;
				end if;
		end case;
	end process;
	process(SST_CLK) begin
		if (rising_edge(SST_CLK)) then
			internal_PCLK_STATE <= internal_NEXT_PCLK_STATE;
		end if;
	end process;
	
	--Choose PCLK outputs based on which register we're reading
	--This is done on the SST clock domain so that the timing register sync-ing
	--is done synchronously to the sampling.
	process(SST_CLK) begin
		if (rising_edge(SST_CLK)) then
			internal_PCLK(15 downto 0) <= (others => '0');
			if(reg_map(to_integer(internal_REGISTER_COUNTER)) = global) then
				internal_PCLK <= (others => internal_PCLK_SINGLE);
			else
				internal_PCLK(to_integer(internal_ROW_COL_COUNTER)) <= internal_PCLK_SINGLE;
			end if;
		end if;
	end process;	
	
	
	--Choose which register value to use
	--Numbers in the comments correspond to Gary's notation in the register map spreadsheet
	--Actual address choice is chosen by "internal_REG_ADDR" (see above)
	process(internal_ROW, internal_COL, internal_REG_ADDR, ASIC_TRIG_THRESH, internal_COL, internal_ROW,
	        ASIC_DAC_BUF_BIASES, ASIC_VBIAS, ASIC_VBIAS2, ASIC_REG_TRG, ASIC_WBIAS, ASIC_TRG_BIAS, 
	        ASIC_TRG_BIAS2, ASIC_TRGTHREF, ASIC_TIMING_SSP_LEADING, ASIC_TIMING_SSP_TRAILING, 
	        ASIC_TIMING_S1_LEADING, ASIC_TIMING_S1_TRAILING, ASIC_TIMING_S2_LEADING,
	        ASIC_TIMING_S2_TRAILING, ASIC_TIMING_PHASE_LEADING, ASIC_TIMING_PHASE_TRAILING, 
	        ASIC_TIMING_WR_STRB_LEADING, ASIC_TIMING_WR_STRB_TRAILING, ASIC_TIMING_GENERATOR_REG, 
	        ASIC_CMPBIAS, ASIC_CMPBIAS2, ASIC_PUBIAS, ASIC_SBBIAS, ASIC_DAC_BUF_BIAS_ISEL, ASIC_ISEL, 
	        ASIC_VDLY, ASIC_DAC_BUF_BIAS_VADJP, ASIC_VADJP, ASIC_DAC_BUF_BIAS_VADJN, ASIC_VADJN) begin
		case(to_integer(unsigned(internal_REG_ADDR))) is
			when  0 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(0); -- 1: THR1
			when  1 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(1); -- 2: THR2
			when  2 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(2); -- 3: THR3
			when  3 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(3); -- 4: THR4
			when  4 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(4); -- 5: THR5
			when  5 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(5); -- 6: THR6
			when  6 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(6); -- 7: THR7
			when  7 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH(internal_COL)(internal_ROW)(7); -- 8: THR8
			when  8 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             -- 9: VBDBIAS
			when  9 => internal_REG_VALUE_TO_LOAD <= ASIC_VBIAS(internal_COL)(internal_ROW);          --10: VBIAS
			when 10 => internal_REG_VALUE_TO_LOAD <= ASIC_VBIAS2(internal_COL)(internal_ROW);         --11: VBIAS2
			when 11 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_REG_TRG;                             --12: MiscReg (LSB: TRG_SIGN)
			when 12 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --13: WBDbias
			when 13 => internal_REG_VALUE_TO_LOAD <= ASIC_WBIAS(internal_COL)(internal_ROW);          --14: Wbias
			when 14 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --15: TCDbias
			when 15 => internal_REG_VALUE_TO_LOAD <= ASIC_TRG_BIAS;                                   --16: TRGbias
			when 16 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --17: THDbias
			when 17 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --18: Tbbias
			when 18 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --19: TRGDbias
			when 19 => internal_REG_VALUE_TO_LOAD <= ASIC_TRG_BIAS2;                                  --20: TRGbias2
			when 20 => internal_REG_VALUE_TO_LOAD <= ASIC_TRGTHREF;                                   --21: TRGthref
			when 21 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_SSP_LEADING(internal_COL)(internal_ROW);      --22: LeadSSPin
			when 22 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_SSP_TRAILING(internal_COL)(internal_ROW);     --23: TrailSSPin
			when 23 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S1_LEADING(internal_COL)(internal_ROW);       --24: LeadS1
			when 24 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S1_TRAILING(internal_COL)(internal_ROW);      --25: TrailS1
			when 25 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S2_LEADING(internal_COL)(internal_ROW);       --26: LeadS2
			when 26 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S2_TRAILING(internal_COL)(internal_ROW);      --27: TrailS2
			when 27 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_PHASE_LEADING(internal_COL)(internal_ROW);    --28: LeadPHASE
			when 28 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_PHASE_TRAILING(internal_COL)(internal_ROW);   --29: TrailPHASE
			when 29 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_WR_STRB_LEADING(internal_COL)(internal_ROW);  --30: LeadWR_STRB
			when 30 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_WR_STRB_TRAILING(internal_COL)(internal_ROW); --31: TrailWR_STRB
			when 31 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_GENERATOR_REG;              --32: TimGenReg
			when 32 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --33: PDDbias
			when 33 => internal_REG_VALUE_TO_LOAD <= ASIC_CMPBIAS;                                    --34: CMPbias
			when 34 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --35: PUDbias
			when 35 => internal_REG_VALUE_TO_LOAD <= ASIC_PUBIAS;                                     --36: PUbias
			when 36 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --37: SBDbias
			when 37 => internal_REG_VALUE_TO_LOAD <= ASIC_SBBIAS;                                     --38: Sbbias
			when 38 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIAS_ISEL;                          --39: ISDbias
			when 39 => internal_REG_VALUE_TO_LOAD <= ASIC_ISEL;                                       --40: ISEL
			when 40 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                             --41: VDDbias
			when 41 => internal_REG_VALUE_TO_LOAD <= ASIC_VDLY(internal_COL)(internal_ROW);           --42: Vdly
			when 42 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIAS_VADJP;                         --43: VAPDbias
			when 43 => internal_REG_VALUE_TO_LOAD <= ASIC_VADJP(internal_COL)(internal_ROW)(11 downto 0);      --44: VadjP
			when 44 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIAS_VADJN;                         --45: VANDbias
			when 45 => internal_REG_VALUE_TO_LOAD <= ASIC_VADJN(internal_COL)(internal_ROW)(11 downto 0);          --46: VadjN
			when 47 => internal_REG_VALUE_TO_LOAD <= ASIC_CMPBIAS2;                                    --48: CMPbias2
			when 61 => internal_REG_VALUE_TO_LOAD <= (others => '1');                                 --62: Start_WilkMon
			when 63 => internal_REG_VALUE_TO_LOAD <= (others => '1');                                 --64: Pulse test trigger
			when others => internal_REG_VALUE_TO_LOAD <= (others => '0');
			-------------------------
--			when  0 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 1: THR1
--			when  1 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 2: THR2
--			when  2 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 3: THR3
--			when  3 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 4: THR4
--			when  4 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 5: THR5
--			when  5 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 6: THR6
--			when  6 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 7: THR7
--			when  7 => internal_REG_VALUE_TO_LOAD <= ASIC_TRIG_THRESH;                      -- 8: THR8
--			when  8 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   -- 9: VBDBIAS
--			when  9 => internal_REG_VALUE_TO_LOAD <= ASIC_VBIAS;                            --10: VBIAS
--			when 10 => internal_REG_VALUE_TO_LOAD <= ASIC_VBIAS2;                           --11: VBIAS2
--			when 11 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_REG_TRG;                   --12: MiscReg (LSB: TRG_SIGN)
--			when 12 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --13: WBDbias
--			when 13 => internal_REG_VALUE_TO_LOAD <= ASIC_WBIAS;                            --14: Wbias
--			when 14 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --15: TCDbias
--			when 15 => internal_REG_VALUE_TO_LOAD <= ASIC_TRG_BIAS;                         --16: TRGbias
--			when 16 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --17: THDbias
--			when 17 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --18: Tbbias
--			when 18 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --19: TRGDbias
--			when 19 => internal_REG_VALUE_TO_LOAD <= ASIC_TRG_BIAS2;                        --20: TRGbias2
--			when 20 => internal_REG_VALUE_TO_LOAD <= ASIC_TRGTHREF;                         --21: TRGthref
--			when 21 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_SSP_LEADING;        --22: LeadSSPin
--			when 22 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_SSP_TRAILING;       --23: TrailSSPin
--			when 23 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S1_LEADING;         --24: LeadS1
--			when 24 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S1_TRAILING;        --25: TrailS1
--			when 25 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S2_LEADING;         --26: LeadS2
--			when 26 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_S2_TRAILING;        --27: TrailS2
--			when 27 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_PHASE_LEADING;      --28: LeadPHASE
--			when 28 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_PHASE_TRAILING;     --29: TrailPHASE
--			when 29 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_WR_STRB_LEADING;    --30: LeadWR_STRB
--			when 30 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_WR_STRB_TRAILING;   --31: TrailWR_STRB
--			when 31 => internal_REG_VALUE_TO_LOAD <= x"0" & ASIC_TIMING_GENERATOR_REG;      --32: TimGenReg
--			when 32 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --33: PDDbias
--			when 33 => internal_REG_VALUE_TO_LOAD <= ASIC_CMPBIAS;                          --34: CMPbias
--			when 34 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --35: PUDbias
--			when 35 => internal_REG_VALUE_TO_LOAD <= ASIC_PUBIAS;                           --36: PUbias
--			when 36 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --37: SBDbias
--			when 37 => internal_REG_VALUE_TO_LOAD <= ASIC_SBBIAS;                           --38: Sbbias
--			when 38 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIAS_ISEL;                --39: ISDbias
--			when 39 => internal_REG_VALUE_TO_LOAD <= ASIC_ISEL;                             --40: ISEL
--			when 40 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIASES;                   --41: VDDbias
--			when 41 => internal_REG_VALUE_TO_LOAD <= ASIC_VDLY;                             --42: Vdly
--			when 42 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIAS_VADJP;               --43: VAPDbias
--			when 43 => internal_REG_VALUE_TO_LOAD <= ASIC_VADJP;                            --44: VadjP
--			when 44 => internal_REG_VALUE_TO_LOAD <= ASIC_DAC_BUF_BIAS_VADJN;               --45: VANDbias
--			when 45 => internal_REG_VALUE_TO_LOAD <= ASIC_VADJN;                            --46: VadjN
--			when 61 => internal_REG_VALUE_TO_LOAD <= (others => '1');                       --62: Start_WilkMon
--			when 63 => internal_REG_VALUE_TO_LOAD <= (others => '1');                                 --64: Pulse test trigger
--			when others => internal_REG_VALUE_TO_LOAD <= (others => '0');
		end case;
	end process;
	--Latch that choice 
	process(CLK,CE,internal_LATCH_REG_VALUE) begin
		if (CE = '1' and internal_LATCH_REG_VALUE = '1') then
			if (rising_edge(CLK)) then
				internal_LATCHED_REG_VALUE <= internal_REG_VALUE_TO_LOAD;
			end if;
		end if;
	end process;
	--Map out the full register
	internal_SERIAL_VALUE <= internal_REG_ADDR & internal_LATCHED_REG_VALUE;
	
	--Signal to monitor the state machine internal state
	internal_STATE_MONITOR <= "0000" when internal_STATE = IDLE else
	                          "0001" when internal_STATE = LOAD_BIT else
	                          "0010" when internal_STATE = SEND_BIT else
	                          "0011" when internal_STATE = NEXT_BIT else
	                          "0100" when internal_STATE = PREPARE_LATCH else
	                          "0101" when internal_STATE = LATCH_BUS_DATA else
	                          "0110" when internal_STATE = PREPARE_LOAD else
	                          "0111" when internal_STATE = LOAD_DESTINATION else
	                          "1000" when internal_STATE = INCREMENT else
									  "1001" when internal_STATE = LATCH_NEXT_VALUE else
									  "1111";

--	--DEBUGGING CRAP
--	map_ILA : entity work.s6_ila
--	port map (
--		CONTROL => internal_CHIPSCOPE_CONTROL,
--		CLK     => CLK,
--		TRIG0   => internal_CHIPSCOPE_ILA_REG
--	);
--	map_ICON : entity work.s6_icon
--	port map (
--		CONTROL0 => internal_CHIPSCOPE_CONTROL
--	);
--	
--	--Workaround for CS/picoblaze stupidness
--	process(CLK) begin
--		if (rising_edge(CLK)) then
--			internal_CHIPSCOPE_ILA_REG <= internal_CHIPSCOPE_ILA;
--		end if;
--	end process;
--	
--	internal_CHIPSCOPE_ILA(           0) <= internal_SIN;
--	internal_CHIPSCOPE_ILA(           1) <= internal_SCLK;
--	internal_CHIPSCOPE_ILA(17 downto  2) <= internal_PCLK;
--	internal_CHIPSCOPE_ILA(21 downto 18) <= internal_STATE_MONITOR;
--	internal_CHIPSCOPE_ILA(39 downto 22) <= internal_SERIAL_VALUE;
	
end Behavioral;