----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:19:12 03/11/2013 
-- Design Name: 
-- Module Name:    controlAsicDacProgramming - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;

use work.IRS3B_CarrierRevB_DAC_definitions.all; -- Definitions in irs3b_carrierRevB_DAC_definitions.vhd

entity controlAsicDacProgramming is
    Port ( 
	 CLK : in  STD_LOGIC;
	 LOAD_DACS : in  STD_LOGIC;
	 ENABLE_DAC_AUTO_LOADING : in  STD_LOGIC;
	 PCLK	: out STD_LOGIC_VECTOR(15 downto 0);
	 CLEAR_ALL_REGISTERS : out STD_LOGIC;
	 SCLK : out STD_LOGIC;
	 SIN : out STD_LOGIC;
	 SHOUT : in STD_LOGIC;
	 --ASIC DAC values
	 --DAC_setting indicates a global for the whole boardstack
	 --DAC_setting_C_R indicates a (4)(4) to set DACs separately by row/col
	 --DAC_setting_C_R_CH indicates a (4)(4)(8) to set DACs separately by row/col/ch
	 internal_ASIC_TRIG_THRESH         : in DAC_setting_C_R_CH;
	 internal_ASIC_DAC_BUF_BIASES      : in DAC_setting;
	 internal_ASIC_DAC_BUF_BIAS_ISEL   : in DAC_setting;
	 internal_ASIC_DAC_BUF_BIAS_VADJP  : in DAC_setting;
	 internal_ASIC_DAC_BUF_BIAS_VADJN  : in DAC_setting;
	 internal_ASIC_VBIAS               : in DAC_setting_C_R;
	 internal_ASIC_VBIAS2              : in DAC_setting_C_R;
	 internal_ASIC_REG_TRG             : in Timing_setting; --Not a DAC but set with the DACs.  Global for all ASICs.
	 internal_ASIC_WBIAS               : in DAC_setting_C_R;
	 internal_ASIC_VADJP               : in DAC_setting_C_R;
	 internal_ASIC_VADJN               : in DAC_setting_C_R;
	 internal_ASIC_VDLY                : in DAC_setting_C_R;
	 internal_ASIC_TRG_BIAS            : in DAC_setting;
	 internal_ASIC_TRG_BIAS2           : in DAC_setting;
	 internal_ASIC_TRGTHREF            : in DAC_setting;
	 internal_ASIC_CMPBIAS             : in DAC_setting;
	 internal_ASIC_PUBIAS              : in DAC_setting;
	 internal_ASIC_SBBIAS              : in DAC_setting;
	 internal_ASIC_ISEL                : in DAC_setting;
	--Timing settings go here too, since they're set with the DACs
	 internal_ASIC_TIMING_SSP_LEADING    : in Timing_setting_C_R;
	 internal_ASIC_TIMING_SSP_TRAILING   : in Timing_setting_C_R;
	 internal_ASIC_TIMING_S1_LEADING     : in Timing_setting_C_R;
	 internal_ASIC_TIMING_S1_TRAILING    : in Timing_setting_C_R;
	 internal_ASIC_TIMING_S2_LEADING     : in Timing_setting_C_R;
	 internal_ASIC_TIMING_S2_TRAILING    : in Timing_setting_C_R;
	 internal_ASIC_TIMING_PHASE_LEADING  : in Timing_setting_C_R;
	 internal_ASIC_TIMING_PHASE_TRAILING : in Timing_setting_C_R;
	 internal_ASIC_TIMING_GENERATOR_REG  : in Timing_setting
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
	
	signal colNum : integer := 0;
	signal rowNum : integer := 0;
	
	signal enable_counter : std_logic := '0';
	signal INTERNAL_COUNTER					: UNSIGNED(31 downto 0) := x"00000000";
	
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
				if INTERNAL_COUNTER > x"1DCE0000"  then --corresponds to ~10 seconds between updates
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

	--declare DAC writing module
	Inst_program_DACs: entity work.program_DACs PORT MAP(
		clk => CLK,
		do_load => do_load_in,
		THR1 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(0),
		THR2 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(1),
		THR3 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(2),
		THR4 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(3),
		THR5 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(4),
		THR6 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(5),
		THR7 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(6),
		THR8 => internal_ASIC_TRIG_THRESH(colNum)(rowNum)(7),
		VBDBIAS => internal_ASIC_DAC_BUF_BIASES, 
		VBIAS => internal_ASIC_VBIAS(colNum)(rowNum),
		VBIAS2 => internal_ASIC_VBIAS2(colNum)(rowNum),
		MiscReg => internal_ASIC_REG_TRG,
		WBDbias => internal_ASIC_DAC_BUF_BIASES,
		Wbias => internal_ASIC_WBIAS(colNum)(rowNum),
		TCDbias => internal_ASIC_DAC_BUF_BIASES,
		TRGbias => internal_ASIC_TRG_BIAS,
		THDbias => internal_ASIC_DAC_BUF_BIASES,
		Tbbias => internal_ASIC_DAC_BUF_BIASES,
		TRGDbias => internal_ASIC_DAC_BUF_BIASES,
		TRGbias2 => internal_ASIC_TRG_BIAS2,
		TRGthref => internal_ASIC_TRGTHREF,
		LeadSSPin => internal_ASIC_TIMING_SSP_LEADING(colNum)(rowNum),
		TrailSSPin => internal_ASIC_TIMING_SSP_TRAILING(colNum)(rowNum),
		LeadS1 => internal_ASIC_TIMING_S1_LEADING(colNum)(rowNum),
		TrailS1 => internal_ASIC_TIMING_S1_TRAILING(colNum)(rowNum),
		LeadS2 => internal_ASIC_TIMING_S2_LEADING(colNum)(rowNum),
		TrailS2 => internal_ASIC_TIMING_S2_TRAILING(colNum)(rowNum),
		LeadPHASE => internal_ASIC_TIMING_PHASE_LEADING(colNum)(rowNum),
		TrailPHASE => internal_ASIC_TIMING_PHASE_TRAILING(colNum)(rowNum),
		LeadWR_STRB => x"00",
		TrailWR_STRB => x"00",
		TimGenReg => internal_ASIC_TIMING_GENERATOR_REG,
		PDDbias => internal_ASIC_DAC_BUF_BIASES,
		CMPbias => internal_ASIC_CMPBIAS,
		PUDbias => internal_ASIC_DAC_BUF_BIASES,
		PUbias => internal_ASIC_PUBIAS,
		SBDbias => internal_ASIC_DAC_BUF_BIASES,
		Sbbias => internal_ASIC_SBBIAS,
		ISDbias => internal_ASIC_DAC_BUF_BIAS_ISEL,
		ISEL => internal_ASIC_ISEL,
		VDDbias => internal_ASIC_DAC_BUF_BIASES,
		Vdly => internal_ASIC_VDLY(colNum)(rowNum),
		VAPDbias => internal_ASIC_DAC_BUF_BIAS_VADJP,
		VadjP => internal_ASIC_VADJP(colNum)(rowNum),
		VANDbias => internal_ASIC_DAC_BUF_BIAS_VADJN,
		VadjN => internal_ASIC_VADJN(colNum)(rowNum),
		init_done => init_done_out,
		PCLK => PCLK_out,
		SCLK => SCLK,
		SIN => SIN,
		SHOUT => SHOUT,
		flag_done => flag_done_out,
		DAC_updating => DAC_updating_out
	);

	--TEMPORARY- FAN SAME DACS TO ALL ASICS At SAME TIME
	--should be case statement to allow programmig specific DAC values to specific ASICs
	PCLK <= (others=>PCLK_out);

end Behavioral;