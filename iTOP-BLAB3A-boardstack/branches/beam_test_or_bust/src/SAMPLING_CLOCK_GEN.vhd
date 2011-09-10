------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- Copied basic functionality from the Xilinx coregen 
--
------------------------------------------------------------------------------
-- Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
-- Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
------------------------------------------------------------------------------
-- CLK_OUT1    21.200    315.000    50.000      445.260    289.441
-- CLK_OUT2    42.401     90.000    50.000      387.435    289.441
--
------------------------------------------------------------------------------
-- Input Clock   Input Freq (MHz)   Input Jitter (UI)
------------------------------------------------------------------------------
-- primary            21.2            0.005

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity SAMPLING_CLOCK_GEN is
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  CLK_OUT2          : out    std_logic;
  CLK_OUT3			  : out	  std_logic;
  -- Status and control signals
  RESET             : in     std_logic;
  LOCKED            : out    std_logic
 );
end SAMPLING_CLOCK_GEN;

architecture behavioral of SAMPLING_CLOCK_GEN is
  -- Input clock buffering / unused connectors
  signal clkin1      : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout         : std_logic;
  signal clkfbout_buf     : std_logic;
  signal clkout0          : std_logic;
  signal clkout1          : std_logic;
  signal clkout2_unused	  : std_logic;
  signal clkout3_unused   : std_logic;
  signal clkout4_unused   : std_logic;
  signal clkout5_unused   : std_logic;
  -- Unused status signals

begin


  -- Input buffering
  --------------------------------------
  clkin1_buf : BUFG
  port map
   (O => clkin1,
    I => CLK_IN1);


  -- Clocking primitive
  --------------------------------------
  -- Instantiation of the PLL primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused

  pll_base_inst : PLL_BASE
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLK_FEEDBACK         => "CLKFBOUT",
    COMPENSATION         => "SYSTEM_SYNCHRONOUS",
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT        => 20,
    CLKFBOUT_PHASE       => 0.000,
    CLKOUT0_DIVIDE       => 20,
    CLKOUT0_PHASE        => 315.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT1_DIVIDE       => 10,
    CLKOUT1_PHASE        => 90.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
    CLKIN_PERIOD         => 47.169,
    REF_JITTER           => 0.005)
  port map
    -- Output clocks
   (CLKFBOUT            => clkfbout,
    CLKOUT0             => clkout0,
    CLKOUT1             => clkout1,
    CLKOUT2             => clkout2_unused,
    CLKOUT3             => clkout3_unused,
    CLKOUT4             => clkout4_unused,
    CLKOUT5             => clkout5_unused,
    -- Status and control signals
    LOCKED              => LOCKED,
    RST                 => RESET,
    -- Input clock control
    CLKFBIN             => clkfbout_buf,
    CLKIN               => clkin1);

  -- Output buffering
  -------------------------------------
  clkf_buf : BUFG
  port map
   (O => clkfbout_buf,
    I => clkfbout);


  --Trying to save a clock buffer here.
--  CLK_OUT1 <= clkout0;
  clkout1_buf : BUFG
  port map
   (O   => CLK_OUT1,
    I   => clkout0);

  --Trying to save another clock buffer here.
--  CLK_OUT2 <= clkout1;
  clkout2_buf : BUFG
  port map
   (O   => CLK_OUT2,
    I   => clkout1);

  CLK_OUT3 <= clkin1;

end behavioral;
