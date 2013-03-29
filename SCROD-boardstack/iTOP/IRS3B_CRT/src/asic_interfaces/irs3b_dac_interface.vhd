----------------------------------------------------------------------------------
-- Interfaces to the IRS3B, carrier RevB DAC
-- Should include the multiplexing signals to use the DAC values from the user 
-- registers or the ones from the feedback sources.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.IRS3B_CarrierRevB_DAC_definitions.all;
use work.asic_definitions_irs3b_carrier_revB.all;

entity irs3b_dac_interface is
	Port ( 
		--Clock and clock enable used to run the interface
		CLOCK                        : in std_logic;
		CLOCK_ENABLE                 : in std_logic;
		--SST clock for generating PCLK for ASIC sync purposes
		SST_CLOCK                    : in std_logic;
		--Direct connections to the IRS3B register programming interface
		AsicIn_PARALLEL_CLOCK_C0_R   : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C1_R   : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C2_R   : out std_logic_vector(3 downto 0);
		AsicIn_PARALLEL_CLOCK_C3_R   : out std_logic_vector(3 downto 0);
		AsicIn_CLEAR_ALL_REGISTERS   : out std_logic;
		AsicIn_SERIAL_SHIFT_CLOCK    : out std_logic;
		AsicIn_SERIAL_INPUT          : out std_logic;		
		--Connections to the external DACs for VADJP/VADJN
		I2C_DAC_SCL_R01              : inout std_logic;
		I2C_DAC_SDA_R01              : inout std_logic;
		I2C_DAC_SCL_R23              : inout std_logic;
		I2C_DAC_SDA_R23              : inout std_logic;
		--A toggle to select the internal or external DACs
		USE_EXTERNAL_VADJ_DACS       : in  std_logic;
		--DAC values coming from general purpose registers
		ASIC_TRIG_THRESH             : in  DAC_setting_C_R_CH;
		ASIC_DAC_BUF_BIASES          : in  DAC_setting;
		ASIC_DAC_BUF_BIAS_ISEL       : in  DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJP      : in  DAC_setting;
		ASIC_DAC_BUF_BIAS_VADJN      : in  DAC_setting;
		ASIC_VBIAS                   : in  DAC_setting_C_R;
		ASIC_VBIAS2                  : in  DAC_setting_C_R;
		ASIC_WBIAS                   : in  DAC_setting_C_R;
		ASIC_VADJP                   : in  DAC_setting_C_R;
		ASIC_VADJN                   : in  DAC_setting_C_R;
		ASIC_VDLY                    : in  DAC_setting_C_R;
		ASIC_TRG_BIAS                : in  DAC_setting;
		ASIC_TRG_BIAS2               : in  DAC_setting;
		ASIC_TRGTHREF                : in  DAC_setting;
		ASIC_CMPBIAS                 : in  DAC_setting;
		ASIC_PUBIAS                  : in  DAC_setting;
		ASIC_SBBIAS                  : in  DAC_setting;
		ASIC_ISEL                    : in  DAC_setting;
		--DAC values coming from feedback loops
		WBIAS_FB                     : in  DAC_setting_C_R;
		VDLY_FB                      : in  DAC_setting_C_R;
		VADJP_FB                     : in  DAC_setting_C_R;
		VADJN_FB                     : in  DAC_setting_C_R;		
		--Multiplex enables to choose between the two above categories
		VDLY_FEEDBACK_ENABLES        : in  Column_Row_Enables;
		VADJ_FEEDBACK_ENABLES        : in  Column_Row_Enables;
		WBIAS_FEEDBACK_ENABLES       : in  Column_Row_Enables;
		--Other registers and timing-related signals that live in the ASIC internal registers
		ASIC_TIMING_SSP_LEADING      : in  Timing_setting_C_R;
		ASIC_TIMING_SSP_TRAILING     : in  Timing_setting_C_R;
		ASIC_TIMING_WR_STRB_LEADING  : in  Timing_setting_C_R;
		ASIC_TIMING_WR_STRB_TRAILING : in  Timing_setting_C_R;
		ASIC_TIMING_S1_LEADING       : in  Timing_setting_C_R;
		ASIC_TIMING_S1_TRAILING      : in  Timing_setting_C_R;
		ASIC_TIMING_S2_LEADING       : in  Timing_setting_C_R;
		ASIC_TIMING_S2_TRAILING      : in  Timing_setting_C_R;
		ASIC_TIMING_PHASE_LEADING    : in  Timing_setting_C_R;
		ASIC_TIMING_PHASE_TRAILING   : in  Timing_setting_C_R;
		ASIC_TIMING_GENERATOR_REG    : in  Timing_setting;
		ASIC_REG_TRG                 : in  Timing_setting
	);
end irs3b_dac_interface;

architecture Behavioral of irs3b_dac_interface is
	--Internal signal for keeping track of ASIC-to-ASIC PCLKs
	signal internal_PCLK_OUT : std_logic_vector(15 downto 0);

	--These allow multiplexing between DACs on a feedback loop
	signal internal_ASIC_WBIAS_TO_USE : DAC_setting_C_R;
	signal internal_ASIC_VADJP_TO_USE : DAC_setting_C_R;
	signal internal_ASIC_VADJN_TO_USE : DAC_setting_C_R;
	signal internal_ASIC_VDLY_TO_USE  : DAC_setting_C_R;	

	--These allow multiplexing between internal and external VadjP/N DACs
	signal internal_ASIC_DAC_BUF_BIAS_VADJP_TO_USE : DAC_setting;
	signal internal_ASIC_DAC_BUF_BIAS_VADJN_TO_USE : DAC_setting;

	--Clock enable for slowing down the ASIC DAC interface
	signal internal_ASIC_DAC_CE : std_logic := '0';
	
begin

	--Control for the external DACs that control VadjP/N
	map_external_dac_control : entity work.IRS3B_CarrierRevB_External_I2C_DAC_Control
	port map( 
		VADJP_VALUES      => internal_ASIC_VADJP_TO_USE,
		VADJN_VALUES      => internal_ASIC_VADJN_TO_USE,
		USE_EXTERNAL_DACS => USE_EXTERNAL_VADJ_DACS,
		CLK               => CLOCK,
		CLK_ENABLE        => CLOCK_ENABLE,
      SCL_R01	         => I2C_DAC_SCL_R01,
		SDA_R01           => I2C_DAC_SDA_R01,
      SCL_R23	         => I2C_DAC_SCL_R23,
		SDA_R23           => I2C_DAC_SDA_R23
	);
	--MUX to turn off the internal VADJP/N biases
	internal_ASIC_DAC_BUF_BIAS_VADJP_TO_USE <= ASIC_DAC_BUF_BIAS_VADJP when USE_EXTERNAL_VADJ_DACS = '0' else
			                                     (others => '0');
	internal_ASIC_DAC_BUF_BIAS_VADJN_TO_USE <= ASIC_DAC_BUF_BIAS_VADJN when USE_EXTERNAL_VADJ_DACS = '0' else
			                                     (others => '0');

	--Map out PCLK to the appropriate pins
	AsicIn_PARALLEL_CLOCK_C0_R <= internal_PCLK_OUT( 3 downto  0);
	AsicIn_PARALLEL_CLOCK_C1_R <= internal_PCLK_OUT( 7 downto  4);
	AsicIn_PARALLEL_CLOCK_C2_R <= internal_PCLK_OUT(11 downto  8);
	AsicIn_PARALLEL_CLOCK_C3_R <= internal_PCLK_OUT(15 downto 12);	
	
--	--ASIC DAC writing module (round-robin-by-ASIC)
--	Inst_controlAsicDacProgramming : entity work.controlAsicDacProgramming
--	port map ( 
--		CLK                          => CLOCK,
--		PCLK	                       => internal_PCLK_OUT,
--		CLEAR_ALL_REGISTERS          => AsicIn_CLEAR_ALL_REGISTERS,
--		SCLK                         => AsicIn_SERIAL_SHIFT_CLOCK,
--		SIN                          => AsicIn_SERIAL_INPUT,
--		SHOUT                        => '0',
--		ASIC_TRIG_THRESH             => ASIC_TRIG_THRESH,
--		ASIC_DAC_BUF_BIASES          => ASIC_DAC_BUF_BIASES,
--		ASIC_DAC_BUF_BIAS_ISEL       => ASIC_DAC_BUF_BIAS_ISEL,
--		ASIC_DAC_BUF_BIAS_VADJP      => internal_ASIC_DAC_BUF_BIAS_VADJP_TO_USE,
--		ASIC_DAC_BUF_BIAS_VADJN      => internal_ASIC_DAC_BUF_BIAS_VADJN_TO_USE,
--		ASIC_VBIAS                   => ASIC_VBIAS,
--		ASIC_VBIAS2                  => ASIC_VBIAS2,
--		ASIC_REG_TRG                 => ASIC_REG_TRG,
--		ASIC_WBIAS                   => internal_ASIC_WBIAS_TO_USE,
--		ASIC_VADJP                   => internal_ASIC_VADJP_TO_USE,
--		ASIC_VADJN                   => internal_ASIC_VADJN_TO_USE,
--		ASIC_VDLY                    => internal_ASIC_VDLY_TO_USE,
--		ASIC_TRG_BIAS                => ASIC_TRG_BIAS,
--		ASIC_TRG_BIAS2               => ASIC_TRG_BIAS2,
--		ASIC_TRGTHREF                => ASIC_TRGTHREF,
--		ASIC_CMPBIAS                 => ASIC_CMPBIAS,
--		ASIC_PUBIAS                  => ASIC_PUBIAS,
--		ASIC_SBBIAS                  => ASIC_SBBIAS,
--		ASIC_ISEL                    => ASIC_ISEL,
--		ASIC_TIMING_SSP_LEADING      => ASIC_TIMING_SSP_LEADING,
--		ASIC_TIMING_SSP_TRAILING     => ASIC_TIMING_SSP_TRAILING,
--		ASIC_TIMING_WR_STRB_LEADING  => ASIC_TIMING_WR_STRB_LEADING,
--		ASIC_TIMING_WR_STRB_TRAILING => ASIC_TIMING_WR_STRB_TRAILING,
--		ASIC_TIMING_S1_LEADING       => ASIC_TIMING_S1_LEADING,
--		ASIC_TIMING_S1_TRAILING      => ASIC_TIMING_S1_TRAILING,
--		ASIC_TIMING_S2_LEADING       => ASIC_TIMING_S2_LEADING,
--		ASIC_TIMING_S2_TRAILING      => ASIC_TIMING_S2_TRAILING,
--		ASIC_TIMING_PHASE_LEADING    => ASIC_TIMING_PHASE_LEADING,
--		ASIC_TIMING_PHASE_TRAILING   => ASIC_TIMING_PHASE_TRAILING,
--		ASIC_TIMING_GENERATOR_REG    => ASIC_TIMING_GENERATOR_REG
--	 );

	--ASIC DAC writing module (round-robin-by-register, parallel when appropriate to a register)
	AsicIn_CLEAR_ALL_REGISTERS <= '0';
	--Generate a clock enable for the DAC interface
	process(CLOCK) begin
		if (rising_edge(CLOCK)) then
			internal_ASIC_DAC_CE <= not(internal_ASIC_DAC_CE);
		end if;
	end process;
	--
	map_irs3b_program_dacs_parallel : entity work.irs3b_program_dacs_parallel
	port map(
		CLK                          => CLOCK,
		CE                           => internal_ASIC_DAC_CE,
		SST_CLK                      => SST_CLOCK,
		PCLK                         => internal_PCLK_OUT,
		SCLK                         => AsicIn_SERIAL_SHIFT_CLOCK,
		SIN                          => AsicIn_SERIAL_INPUT,
		SHOUT                        => '0',
		ASIC_TRIG_THRESH             => ASIC_TRIG_THRESH,
		ASIC_DAC_BUF_BIASES          => ASIC_DAC_BUF_BIASES,
		ASIC_DAC_BUF_BIAS_ISEL       => ASIC_DAC_BUF_BIAS_ISEL,
		ASIC_DAC_BUF_BIAS_VADJP      => internal_ASIC_DAC_BUF_BIAS_VADJP_TO_USE,
		ASIC_DAC_BUF_BIAS_VADJN      => internal_ASIC_DAC_BUF_BIAS_VADJN_TO_USE,
		ASIC_VBIAS                   => ASIC_VBIAS,
		ASIC_VBIAS2                  => ASIC_VBIAS2,
		ASIC_REG_TRG                 => ASIC_REG_TRG,
		ASIC_WBIAS                   => internal_ASIC_WBIAS_TO_USE,
		ASIC_VADJP                   => internal_ASIC_VADJP_TO_USE,
		ASIC_VADJN                   => internal_ASIC_VADJN_TO_USE,
		ASIC_VDLY                    => internal_ASIC_VDLY_TO_USE,
		ASIC_TRG_BIAS                => ASIC_TRG_BIAS,
		ASIC_TRG_BIAS2               => ASIC_TRG_BIAS2,
		ASIC_TRGTHREF                => ASIC_TRGTHREF,
		ASIC_CMPBIAS                 => ASIC_CMPBIAS,
		ASIC_PUBIAS                  => ASIC_PUBIAS,
		ASIC_SBBIAS                  => ASIC_SBBIAS,
		ASIC_ISEL                    => ASIC_ISEL,
		ASIC_TIMING_SSP_LEADING      => ASIC_TIMING_SSP_LEADING,
		ASIC_TIMING_SSP_TRAILING     => ASIC_TIMING_SSP_TRAILING,
		ASIC_TIMING_WR_STRB_LEADING  => ASIC_TIMING_WR_STRB_LEADING,
		ASIC_TIMING_WR_STRB_TRAILING => ASIC_TIMING_WR_STRB_TRAILING,
		ASIC_TIMING_S1_LEADING       => ASIC_TIMING_S1_LEADING,
		ASIC_TIMING_S1_TRAILING      => ASIC_TIMING_S1_TRAILING,
		ASIC_TIMING_S2_LEADING       => ASIC_TIMING_S2_LEADING,
		ASIC_TIMING_S2_TRAILING      => ASIC_TIMING_S2_TRAILING,
		ASIC_TIMING_PHASE_LEADING    => ASIC_TIMING_PHASE_LEADING,
		ASIC_TIMING_PHASE_TRAILING   => ASIC_TIMING_PHASE_TRAILING,
		ASIC_TIMING_GENERATOR_REG    => ASIC_TIMING_GENERATOR_REG
	);

	
	--------------------------------------------------
	-------Multiplexing to turn feedbacks on/off------
	--------------------------------------------------
	gen_vdly_fb_mux_col : for col in 0 to 3 generate
		gen_vdly_fb_mux_row : for row in 0 to 3 generate
			internal_ASIC_VDLY_TO_USE(col)(row) <= VDLY_FB(col)(row)   when VDLY_FEEDBACK_ENABLES(col)(row) = '1' else
			                                       ASIC_VDLY(col)(row) when VDLY_FEEDBACK_ENABLES(col)(row) = '0' else
																(others => 'X');
		end generate;	
	end generate;
	gen_wbias_fb_mux_col : for col in 0 to 3 generate
		gen_wbias_fb_mux_row : for row in 0 to 3 generate
			internal_ASIC_WBIAS_TO_USE(col)(row) <= WBIAS_FB(col)(row)   when WBIAS_FEEDBACK_ENABLES(col)(row) = '1' else
			                                        ASIC_WBIAS(col)(row) when WBIAS_FEEDBACK_ENABLES(col)(row) = '0' else
																(others => 'X');
		end generate;	
	end generate;
	gen_vadj_fb_mux_col : for col in 0 to 3 generate
		gen_vadj_fb_mux_row : for row in 0 to 3 generate
			internal_ASIC_VADJN_TO_USE(col)(row) <= VADJN_FB(col)(row)   when VADJ_FEEDBACK_ENABLES(col)(row) = '1' else
			                                        ASIC_VADJN(col)(row) when VADJ_FEEDBACK_ENABLES(col)(row) = '0' else
																(others => 'X');
			internal_ASIC_VADJP_TO_USE(col)(row) <= ASIC_VADJP(col)(row);
		end generate;	
	end generate;
	
	
end Behavioral;