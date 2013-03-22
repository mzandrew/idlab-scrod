--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:59:37 03/18/2013
-- Design Name:   
-- Module Name:   C:/cygwin/home/Dr Kurtis/idlab-scrod/SCROD-boardstack/iTOP/IRS3B_CRT/src/asic_interfaces/simulation/parallel_dac_test.vhd
-- Project Name:  scrod-boardstack-new-daq-interface
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: irs3b_program_dacs_parallel
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY parallel_dac_test IS
END parallel_dac_test;
 
ARCHITECTURE behavior OF parallel_dac_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT irs3b_program_dacs_parallel
    PORT(
         CLK : IN  std_logic;
         CE : IN  std_logic;
         PCLK : OUT  std_logic_vector(15 downto 0);
         SCLK : OUT  std_logic;
         SIN : OUT  std_logic;
         SHOUT : IN  std_logic;
         ASIC_TRIG_THRESH : IN  std_logic_vector(11 downto 0);
         ASIC_DAC_BUF_BIASES : IN  std_logic_vector(11 downto 0);
         ASIC_DAC_BUF_BIAS_ISEL : IN  std_logic_vector(11 downto 0);
         ASIC_DAC_BUF_BIAS_VADJP : IN  std_logic_vector(11 downto 0);
         ASIC_DAC_BUF_BIAS_VADJN : IN  std_logic_vector(11 downto 0);
         ASIC_VBIAS : IN  std_logic_vector(11 downto 0);
         ASIC_VBIAS2 : IN  std_logic_vector(11 downto 0);
         ASIC_REG_TRG : IN  std_logic_vector(7 downto 0);
         ASIC_WBIAS : IN  std_logic_vector(11 downto 0);
         ASIC_VADJP : IN  std_logic_vector(11 downto 0);
         ASIC_VADJN : IN  std_logic_vector(11 downto 0);
         ASIC_VDLY : IN  std_logic_vector(11 downto 0);
         ASIC_TRG_BIAS : IN  std_logic_vector(11 downto 0);
         ASIC_TRG_BIAS2 : IN  std_logic_vector(11 downto 0);
         ASIC_TRGTHREF : IN  std_logic_vector(11 downto 0);
         ASIC_CMPBIAS : IN  std_logic_vector(11 downto 0);
         ASIC_PUBIAS : IN  std_logic_vector(11 downto 0);
         ASIC_SBBIAS : IN  std_logic_vector(11 downto 0);
         ASIC_ISEL : IN  std_logic_vector(11 downto 0);
         ASIC_TIMING_SSP_LEADING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_SSP_TRAILING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_WR_STRB_LEADING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_WR_STRB_TRAILING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_S1_LEADING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_S1_TRAILING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_S2_LEADING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_S2_TRAILING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_PHASE_LEADING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_PHASE_TRAILING : IN  std_logic_vector(7 downto 0);
         ASIC_TIMING_GENERATOR_REG : IN  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal CE : std_logic := '1';
   signal SHOUT : std_logic := '0';
   signal ASIC_TRIG_THRESH : std_logic_vector(11 downto 0)        := "111111111110";
   signal ASIC_DAC_BUF_BIASES : std_logic_vector(11 downto 0)     := "111111111101";
   signal ASIC_DAC_BUF_BIAS_ISEL : std_logic_vector(11 downto 0)  := "111111111011";
   signal ASIC_DAC_BUF_BIAS_VADJP : std_logic_vector(11 downto 0) := "111111110111";
   signal ASIC_DAC_BUF_BIAS_VADJN : std_logic_vector(11 downto 0) := "111111101111";
   signal ASIC_VBIAS : std_logic_vector(11 downto 0)              := "111111011111";
   signal ASIC_VBIAS2 : std_logic_vector(11 downto 0)             := "111110111111";
   signal ASIC_REG_TRG : std_logic_vector(7 downto 0)             := "11111110";
   signal ASIC_WBIAS : std_logic_vector(11 downto 0)              := "111011111111";
   signal ASIC_VADJP : std_logic_vector(11 downto 0)              := "110111111111";
   signal ASIC_VADJN : std_logic_vector(11 downto 0)              := "101111111111";
   signal ASIC_VDLY : std_logic_vector(11 downto 0)               := "011111111111";
   signal ASIC_TRG_BIAS : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_TRG_BIAS2 : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_TRGTHREF : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_CMPBIAS : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_PUBIAS : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_SBBIAS : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_ISEL : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_TIMING_SSP_LEADING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_SSP_TRAILING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_WR_STRB_LEADING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_WR_STRB_TRAILING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_S1_LEADING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_S1_TRAILING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_S2_LEADING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_S2_TRAILING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_PHASE_LEADING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_PHASE_TRAILING : std_logic_vector(7 downto 0) := (others => '0');
   signal ASIC_TIMING_GENERATOR_REG : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal PCLK : std_logic_vector(15 downto 0);
   signal SCLK : std_logic;
   signal SIN : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: irs3b_program_dacs_parallel PORT MAP (
          CLK => CLK,
          CE => CE,
          PCLK => PCLK,
          SCLK => SCLK,
          SIN => SIN,
          SHOUT => SHOUT,
          ASIC_TRIG_THRESH => ASIC_TRIG_THRESH,
          ASIC_DAC_BUF_BIASES => ASIC_DAC_BUF_BIASES,
          ASIC_DAC_BUF_BIAS_ISEL => ASIC_DAC_BUF_BIAS_ISEL,
          ASIC_DAC_BUF_BIAS_VADJP => ASIC_DAC_BUF_BIAS_VADJP,
          ASIC_DAC_BUF_BIAS_VADJN => ASIC_DAC_BUF_BIAS_VADJN,
          ASIC_VBIAS => ASIC_VBIAS,
          ASIC_VBIAS2 => ASIC_VBIAS2,
          ASIC_REG_TRG => ASIC_REG_TRG,
          ASIC_WBIAS => ASIC_WBIAS,
          ASIC_VADJP => ASIC_VADJP,
          ASIC_VADJN => ASIC_VADJN,
          ASIC_VDLY => ASIC_VDLY,
          ASIC_TRG_BIAS => ASIC_TRG_BIAS,
          ASIC_TRG_BIAS2 => ASIC_TRG_BIAS2,
          ASIC_TRGTHREF => ASIC_TRGTHREF,
          ASIC_CMPBIAS => ASIC_CMPBIAS,
          ASIC_PUBIAS => ASIC_PUBIAS,
          ASIC_SBBIAS => ASIC_SBBIAS,
          ASIC_ISEL => ASIC_ISEL,
          ASIC_TIMING_SSP_LEADING => ASIC_TIMING_SSP_LEADING,
          ASIC_TIMING_SSP_TRAILING => ASIC_TIMING_SSP_TRAILING,
          ASIC_TIMING_WR_STRB_LEADING => ASIC_TIMING_WR_STRB_LEADING,
          ASIC_TIMING_WR_STRB_TRAILING => ASIC_TIMING_WR_STRB_TRAILING,
          ASIC_TIMING_S1_LEADING => ASIC_TIMING_S1_LEADING,
          ASIC_TIMING_S1_TRAILING => ASIC_TIMING_S1_TRAILING,
          ASIC_TIMING_S2_LEADING => ASIC_TIMING_S2_LEADING,
          ASIC_TIMING_S2_TRAILING => ASIC_TIMING_S2_TRAILING,
          ASIC_TIMING_PHASE_LEADING => ASIC_TIMING_PHASE_LEADING,
          ASIC_TIMING_PHASE_TRAILING => ASIC_TIMING_PHASE_TRAILING,
          ASIC_TIMING_GENERATOR_REG => ASIC_TIMING_GENERATOR_REG
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
