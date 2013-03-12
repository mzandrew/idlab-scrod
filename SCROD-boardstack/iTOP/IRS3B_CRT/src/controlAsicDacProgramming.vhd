----------------------------------------------------------------------------------
-- Module to interface with Luca's ASIC DAC programming module.
--
-- 2013-03-11 Written by Brian Kirby.  First version uses same DAC values for all ASICs.
-- 2013-03-12 Integrated into IRS3B Board Stack RevB firmware by Kurtis Nishimura.
--            Tested by Kurtis Nishimura and Lynn Wood.  Verified to work for turning on/off
--            internal DAC buffer biases.
-- 2013-03-12 Edits made by Kurtis to latch input values before embarking on DAC
--            programming, so that changes mid-update are handled gracefully.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;

use work.IRS3B_CarrierRevB_DAC_definitions.all; -- Definitions in irs3b_carrierRevB_DAC_definitions.vhd

entity controlAsicDacProgramming is
   Port ( 
		CLK                     :  in STD_LOGIC;
		LOAD_DACS               :  in STD_LOGIC;
		ENABLE_DAC_AUTO_LOADING :  in STD_LOGIC;
		PCLK                    : out STD_LOGIC_VECTOR(15 downto 0);
		CLEAR_ALL_REGISTERS     : out STD_LOGIC;
		SCLK                    : out STD_LOGIC;
		SIN                     : out STD_LOGIC;
		SHOUT                   :  in STD_LOGIC;
		--ASIC DAC values
		--DAC_setting indicates a global for the whole boardstack
		--DAC_setting_C_R indicates a (4)(4) to set DACs separately by row/col
		--DAC_setting_C_R_CH indicates a (4)(4)(8) to set DACs separately by row/col/ch
		ASIC_TRIG_THRESH         : in DAC_setting_C_R_CH;
		ASIC_DAC_BUF_BIASES      : in DAC_setting;
		ASIC_DAC_BUF_BIAS_ISEL   : in DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJP  : in DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJN  : in DAC_setting;
		ASIC_VBIAS               : in DAC_setting_C_R;
		ASIC_VBIAS2              : in DAC_setting_C_R;
		ASIC_REG_TRG             : in Timing_setting; --Not a DAC but set with the DACs.  Global for all ASICs.
		ASIC_WBIAS               : in DAC_setting_C_R;
		ASIC_VADJP               : in DAC_setting_C_R;
		ASIC_VADJN               : in DAC_setting_C_R;
		ASIC_VDLY                : in DAC_setting_C_R;
		ASIC_TRG_BIAS            : in DAC_setting;
		ASIC_TRG_BIAS2           : in DAC_setting;
		ASIC_TRGTHREF            : in DAC_setting;
		ASIC_CMPBIAS             : in DAC_setting;
		ASIC_PUBIAS              : in DAC_setting;
		ASIC_SBBIAS              : in DAC_setting;
		ASIC_ISEL                : in DAC_setting;
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
end controlAsicDacProgramming;

architecture Behavioral of controlAsicDacProgramming is

	type state_type is (st1_idle, st2_waitcounter, st3_program, st4_waitdone); 
   signal state : state_type := st1_idle;
	signal next_state : state_type := st1_idle;

	signal do_load_in : std_logic := '0';
	signal init_done_out : std_logic;
	signal PCLK_out : std_logic;
	signal flag_done_out : std_logic;
	signal DAC_updating_out : std_logic;
	
	signal colNum : integer range 0 to 3 := 0;
	signal rowNum : integer range 0 to 3 := 0;
	
	signal enable_counter : std_logic := '0';
	signal INTERNAL_COUNTER					: UNSIGNED(31 downto 0) := x"00000000";

	--Signal to control latching of register values to use for this
	--programming cycle
	signal internal_REG_LATCH_ENABLE  : std_logic;
	signal internal_INCREMENT_ROW_COL : std_logic;
	--Internal latched versions of the signals to be registered
	signal internal_reg_ASIC_TRIG_THRESH             : DAC_setting_C_R_CH;
	signal internal_reg_ASIC_DAC_BUF_BIASES          : DAC_setting;
	signal internal_reg_ASIC_DAC_BUF_BIAS_ISEL       : DAC_setting;
	signal internal_reg_ASIC_DAC_BUF_BIAS_VADJP      : DAC_setting;
	signal internal_reg_ASIC_DAC_BUF_BIAS_VADJN      : DAC_setting;
	signal internal_reg_ASIC_VBIAS                   : DAC_setting_C_R;
	signal internal_reg_ASIC_VBIAS2                  : DAC_setting_C_R; 
	signal internal_reg_ASIC_REG_TRG                 : Timing_setting;
	signal internal_reg_ASIC_WBIAS                   : DAC_setting_C_R; 
	signal internal_reg_ASIC_VADJP                   : DAC_setting_C_R; 
	signal internal_reg_ASIC_VADJN                   : DAC_setting_C_R; 
	signal internal_reg_ASIC_VDLY                    : DAC_setting_C_R; 
	signal internal_reg_ASIC_TRG_BIAS                : DAC_setting; 
	signal internal_reg_ASIC_TRG_BIAS2               : DAC_setting; 
	signal internal_reg_ASIC_TRGTHREF                : DAC_setting; 
	signal internal_reg_ASIC_CMPBIAS                 : DAC_setting; 
	signal internal_reg_ASIC_PUBIAS                  : DAC_setting; 
	signal internal_reg_ASIC_SBBIAS                  : DAC_setting; 
	signal internal_reg_ASIC_ISEL                    : DAC_setting; 
	signal internal_reg_ASIC_TIMING_SSP_LEADING      : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_SSP_TRAILING     : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_WR_STRB_LEADING  : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_WR_STRB_TRAILING : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_S1_LEADING       : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_S1_TRAILING      : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_S2_LEADING       : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_S2_TRAILING      : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_PHASE_LEADING    : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_PHASE_TRAILING   : Timing_setting_C_R;
	signal internal_reg_ASIC_TIMING_GENERATOR_REG    : Timing_setting;
	
	
begin
	--declare constant signals
	CLEAR_ALL_REGISTERS <= '0';
	
	--counter process
	process (CLK) begin
		if (rising_edge(CLK)) then
			if enable_counter = '1' then
				INTERNAL_COUNTER <= INTERNAL_COUNTER + 1;
			else
				INTERNAL_COUNTER <= (others=>'0');
			end if;
		end if;
	end process;
	
	--SYNC process latches input/output signals to local clock domain
   SYNC_PROC: process (CLK)
   begin
      if (CLK'event and CLK = '1') then
			state <= next_state;
      end if;
   end process;
 
   --MOORE State-Machine - Outputs based on state only
   OUTPUT_DECODE: process (state)
   begin
      --insert statements to decode internal output signals
		if state = st1_idle then
			internal_REG_LATCH_ENABLE  <= '1';
			internal_INCREMENT_ROW_COL <= '1';
		else
			internal_REG_LATCH_ENABLE  <= '0';
			internal_INCREMENT_ROW_COL <= '0';
		end if;
		if state = st2_waitcounter then
         enable_counter <= '1';
      else
         enable_counter <= '0';
      end if;
		if state = st3_program then
			do_load_in <= '1';
		else
			do_load_in <= '0';
      end if;
   end process;
	
	--simple state machine that permanently loops over ASIC dac writing process
	NEXT_STATE_DECODE: process (state, INTERNAL_COUNTER,DAC_updating_out)
   begin
      --declare default state for next_state to avoid latches
      next_state <= state;  --default is to stay in current state
      --insert statements to decode next_state
      --below is a simple example
      case (state) is
         when st1_idle =>
               next_state <= st2_waitcounter;
         when st2_waitcounter =>
--				if INTERNAL_COUNTER > x"1DCE0000"  then --corresponds to ~10 seconds between updates
				if INTERNAL_COUNTER > x"0000C350"  then --corresponds to ~1 msecond between updates
					next_state <= st3_program;
				end if;
         when st3_program =>
				if DAC_updating_out = '1' then
					next_state <= st4_waitdone;
				end if;
			when st4_waitdone =>
				if DAC_updating_out = '0' then
					next_state <= st1_idle;
				end if;
         when others =>
            next_state <= st1_idle;
      end case;      
   end process;


	--Increment the row and column that are being used for this readout
	process(CLK, internal_INCREMENT_ROW_COL) begin
		if (internal_INCREMENT_ROW_COL = '1') then
			if (rising_edge(CLK)) then
				if (rowNum < 3) then
					rowNum <= rowNum + 1;
				else
					rowNum <= 0;
					if (colNum < 3) then
						colNum <= colNum + 1;
					else
						colNum <= 0;
					end if;
				end if;
			end if;
		end if;
	end process;

	--Keep latched versions of the input register values so that they
	--don't change in the middle of an update.
	process(CLK, internal_REG_LATCH_ENABLE) begin
		if (internal_REG_LATCH_ENABLE = '1') then
			if (rising_edge(CLK)) then
				internal_reg_ASIC_TRIG_THRESH             <= ASIC_TRIG_THRESH             ;
				internal_reg_ASIC_DAC_BUF_BIASES          <= ASIC_DAC_BUF_BIASES          ;
				internal_reg_ASIC_DAC_BUF_BIAS_ISEL       <= ASIC_DAC_BUF_BIAS_ISEL       ;
				internal_reg_ASIC_DAC_BUF_BIAS_VADJP      <= ASIC_DAC_BUF_BIAS_VADJP      ;
				internal_reg_ASIC_DAC_BUF_BIAS_VADJN      <= ASIC_DAC_BUF_BIAS_VADJN      ;
				internal_reg_ASIC_VBIAS                   <= ASIC_VBIAS                   ;
				internal_reg_ASIC_VBIAS2                  <= ASIC_VBIAS2                  ;
				internal_reg_ASIC_REG_TRG                 <= ASIC_REG_TRG                 ;
				internal_reg_ASIC_WBIAS                   <= ASIC_WBIAS                   ;
				internal_reg_ASIC_VADJP                   <= ASIC_VADJP                   ;
				internal_reg_ASIC_VADJN                   <= ASIC_VADJN                   ;
				internal_reg_ASIC_VDLY                    <= ASIC_VDLY                    ;
				internal_reg_ASIC_TRG_BIAS                <= ASIC_TRG_BIAS                ;
				internal_reg_ASIC_TRG_BIAS2               <= ASIC_TRG_BIAS2               ;
				internal_reg_ASIC_TRGTHREF                <= ASIC_TRGTHREF                ;
				internal_reg_ASIC_CMPBIAS                 <= ASIC_CMPBIAS                 ;
				internal_reg_ASIC_PUBIAS                  <= ASIC_PUBIAS                  ;
				internal_reg_ASIC_SBBIAS                  <= ASIC_SBBIAS                  ;
				internal_reg_ASIC_ISEL                    <= ASIC_ISEL                    ;
				internal_reg_ASIC_TIMING_SSP_LEADING      <= ASIC_TIMING_SSP_LEADING      ;
				internal_reg_ASIC_TIMING_SSP_TRAILING     <= ASIC_TIMING_SSP_TRAILING     ;
				internal_reg_ASIC_TIMING_WR_STRB_LEADING  <= ASIC_TIMING_WR_STRB_LEADING  ;
				internal_reg_ASIC_TIMING_WR_STRB_TRAILING <= ASIC_TIMING_WR_STRB_TRAILING ;
				internal_reg_ASIC_TIMING_S1_LEADING       <= ASIC_TIMING_S1_LEADING       ;
				internal_reg_ASIC_TIMING_S1_TRAILING      <= ASIC_TIMING_S1_TRAILING      ;
				internal_reg_ASIC_TIMING_S2_LEADING       <= ASIC_TIMING_S2_LEADING       ;
				internal_reg_ASIC_TIMING_S2_TRAILING      <= ASIC_TIMING_S2_TRAILING      ;
				internal_reg_ASIC_TIMING_PHASE_LEADING    <= ASIC_TIMING_PHASE_LEADING    ;
				internal_reg_ASIC_TIMING_PHASE_TRAILING   <= ASIC_TIMING_PHASE_TRAILING   ;
				internal_reg_ASIC_TIMING_GENERATOR_REG    <= ASIC_TIMING_GENERATOR_REG    ;			
			end if;
		end if;
	end process;

	--declare DAC writing module
	Inst_program_DACs: entity work.program_DACs PORT MAP(
		clk => CLK,
		do_load      => do_load_in,
		THR1         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(0),
		THR2         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(1),
		THR3         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(2),
		THR4         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(3),
		THR5         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(4),
		THR6         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(5),
		THR7         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(6),
		THR8         => internal_reg_ASIC_TRIG_THRESH(colNum)(rowNum)(7),
		VBDBIAS      => internal_reg_ASIC_DAC_BUF_BIASES, 
		VBIAS        => internal_reg_ASIC_VBIAS(colNum)(rowNum),
		VBIAS2       => internal_reg_ASIC_VBIAS2(colNum)(rowNum),
		MiscReg      => internal_reg_ASIC_REG_TRG,
		WBDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		Wbias        => internal_reg_ASIC_WBIAS(colNum)(rowNum),
		TCDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		TRGbias      => internal_reg_ASIC_TRG_BIAS,
		THDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		Tbbias       => internal_reg_ASIC_DAC_BUF_BIASES,
		TRGDbias     => internal_reg_ASIC_DAC_BUF_BIASES,
		TRGbias2     => internal_reg_ASIC_TRG_BIAS2,
		TRGthref     => internal_reg_ASIC_TRGTHREF,
		LeadSSPin    => internal_reg_ASIC_TIMING_SSP_LEADING(colNum)(rowNum),
		TrailSSPin   => internal_reg_ASIC_TIMING_SSP_TRAILING(colNum)(rowNum),
		LeadS1       => internal_reg_ASIC_TIMING_S1_LEADING(colNum)(rowNum),
		TrailS1      => internal_reg_ASIC_TIMING_S1_TRAILING(colNum)(rowNum),
		LeadS2       => internal_reg_ASIC_TIMING_S2_LEADING(colNum)(rowNum),
		TrailS2      => internal_reg_ASIC_TIMING_S2_TRAILING(colNum)(rowNum),
		LeadPHASE    => internal_reg_ASIC_TIMING_PHASE_LEADING(colNum)(rowNum),
		TrailPHASE   => internal_reg_ASIC_TIMING_PHASE_TRAILING(colNum)(rowNum),
		LeadWR_STRB  => internal_reg_ASIC_TIMING_WR_STRB_LEADING(colNum)(rowNum),
		TrailWR_STRB => internal_reg_ASIC_TIMING_WR_STRB_TRAILING(colNum)(rowNum),
		TimGenReg    => internal_reg_ASIC_TIMING_GENERATOR_REG,
		PDDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		CMPbias      => internal_reg_ASIC_CMPBIAS,
		PUDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		PUbias       => internal_reg_ASIC_PUBIAS,
		SBDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		Sbbias       => internal_reg_ASIC_SBBIAS,
		ISDbias      => internal_reg_ASIC_DAC_BUF_BIAS_ISEL,
		ISEL         => internal_reg_ASIC_ISEL,
		VDDbias      => internal_reg_ASIC_DAC_BUF_BIASES,
		Vdly         => internal_reg_ASIC_VDLY(colNum)(rowNum),
		VAPDbias     => internal_reg_ASIC_DAC_BUF_BIAS_VADJP,
		VadjP        => internal_reg_ASIC_VADJP(colNum)(rowNum),
		VANDbias     => internal_reg_ASIC_DAC_BUF_BIAS_VADJN,
		VadjN        => internal_reg_ASIC_VADJN(colNum)(rowNum),
		init_done    => init_done_out,
		PCLK         => PCLK_out,
		SCLK         => SCLK,
		SIN          => SIN,
		SHOUT        => SHOUT,
		flag_done    => flag_done_out,
		DAC_updating => DAC_updating_out
	);

	--Only send PCLK for the ASIC we're trying to update right now.
	process(colNum,rowNum,PCLK_out) begin
		--Cycle through and check 
		for col in 0 to 3 loop
			for row in 0 to 3 loop
				if (col = colNum and row = rowNum) then
					PCLK(row+col*4) <= PCLK_out;
				else
					PCLK(row+col*4) <= '0';
				end if;
			end loop;
		end loop;
	end process;

end Behavioral;