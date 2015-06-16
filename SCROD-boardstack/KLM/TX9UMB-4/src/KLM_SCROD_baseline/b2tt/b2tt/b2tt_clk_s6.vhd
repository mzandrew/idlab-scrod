------------------------------------------------------------------------
--
-- b2tt_clk_s6.vhd --- clock for Spartan 6
--
-- Mikihiko Nakao, KEK IPNS
--
-- 20120409 0.01  new
-- 20130411 0.02  renamed from mnictrl
-- 20130718 0.03  packed into b2tt_clk
-- 20131011 0.04  renamed to b2tt_clk_v5 for virtex5
-- 20131012 0.05  unification with v6 as much as possible
-- 20131101 0.06  no more std_logic_arith
-- 20141008 0.08  rawclkg
-- 20150105 0.09  rawclk after bufg (no more rawclkg) / no more FLIPCLK
------------------------------------------------------------------------

------------------------------------------------------------------------
-- b2tt_clk
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity b2tt_clk is
  generic (
    USEPLL   : std_logic := '1'; -- unused flag, PLL is always used in s6
    USEICTRL : std_logic := '0' );
  port (
    clkp     : in  std_logic;
    clkn     : in  std_logic;
    reset    : in  std_logic;
    rawclk   : out std_logic;
    clock    : out std_logic;
    invclock : out std_logic;  -- (only for Spartan-6)
    dblclock : out std_logic;  -- (only for Virtex-6)
    dblclockb : out std_logic; -- (only for Virtex-6)
    hlfclock : out std_logic;
    locked   : out std_logic;
    stat     : out std_logic_vector (1 downto 0) );
end b2tt_clk;

architecture implementation of b2tt_clk is
  signal clk_127      : std_logic := '0';
  signal sig_127      : std_logic := '0';

  signal sig_fbout    : std_logic := '0';
  signal sig_xcm203   : std_logic := '0';
  signal clk_fb       : std_logic := '0';
  signal clk_203      : std_logic := '0';

  signal sta_xcm      : std_logic := '0';
  signal clr_xcm      : std_logic := '0';
  signal sta_ictrl    : std_logic := '1';
  signal clr_ictrl    : std_logic := '0';
  signal cnt_xcmreset : std_logic_vector (3  downto 0) := (others => '0');
  signal cnt_xcmlock  : std_logic_vector (13 downto 0) := (others => '0');
  signal cnt_ictrl    : std_logic_vector (9  downto 0) := (others => '0');

  signal clk_xcm127   : std_logic := '0';
  signal sig_xcm127   : std_logic := '0';
  signal sig_xcm127b  : std_logic := '0';
  signal sig_inv127   : std_logic := '0';
  signal sig_xcm254   : std_logic := '0';  --!uncomment
  signal sig_clk3     : std_logic := '0';  --!add
begin
  ------------------------------------------------------------------------
  -- clock buffers
  ------------------------------------------------------------------------
  rawclk <= clk_127;
  map_ick: ibufds port map ( o => sig_127,    i => clkp, ib => clkn );
  map_ig:   bufg  port map ( i => sig_127,    o => clk_127 );

  map_fb:   bufg  port map ( i => sig_fbout,  o => clk_fb  );
  map_203g: bufg  port map ( i => sig_xcm203, o => clk_203 );
  
  ------------------------------------------------------------------------
  -- PLL (always needed in Spartan 6)
  ------------------------------------------------------------------------

  -- unused in the Spartan 6 design
--  dblclock  <= '0'; --!comment
  dblclockb <= '0';
  
  clock  <= clk_xcm127;
  map_127g: bufg  port map ( i => sig_xcm127,  o => clk_xcm127 );
  map_invg: bufg  port map ( i => sig_xcm127b, o => invclock );
  map_254g: bufg  port map ( i => sig_xcm254, o => dblclock );--!add  
  map_64g: bufg  port map ( i => sig_clk3, o => hlfclock );--!add
  
  map_pll: pll_base
    generic map (
      CLKIN_PERIOD   => 7.8,  -- F_VCO has to be between 400 - 1000 MHz
      CLKFBOUT_MULT  => 8,    -- F_VCO = F_CLKIN * CLKFBOUT_MULT
      DIVCLK_DIVIDE  => 1,    --         / DIVCLK_DIVIDE
      CLKOUT0_DIVIDE => 8,    -- F_OUT = F_VCO / CLKOUTn_DIVIDE
      CLKOUT1_DIVIDE => 8,
      CLKOUT1_PHASE  => 180.0,
      CLKOUT2_DIVIDE => 4,    --!uncomment
      CLKOUT2_PHASE  => 0.0,  --!add
      CLKOUT3_DIVIDE => 16,   --!uncomment
      CLKOUT3_PHASE  => 0.0,  --!add
      --CLKOUT4_DIVIDE => 5,
      BANDWIDTH => "OPTIMIZED" )
    port map (
      clkin    => clk_127,
      rst      => reset,
      clkfbout => sig_fbout,
      clkout0  => sig_xcm127,
      clkout1  => sig_xcm127b,
      clkout2  => sig_xcm254,--!uncomment
      clkout3  => sig_clk3,  --!uncomment
      --clkout4  => sig_clk4,
      locked   => sta_xcm,
      clkfbin  => clk_fb );

  ------------------------------------------------------------------------
  -- no idelayctrl for Spartan 6
  ------------------------------------------------------------------------
  sta_ictrl <= '1';
  
  ------------------------------------------------------------------------
  -- reset
  --  idelayctrl initial reset (>3us or >385clk)
  --  XCM at least 3 clkin to reset, several thousand clocks to lock
  ------------------------------------------------------------------------
  proc_reset: process (clk_127)
  begin
    if clk_127'event and clk_127 = '1' then
      -- XCM reset
      if cnt_xcmreset(3) = '0' then
        clr_xcm      <= '1';
        cnt_xcmreset <= cnt_xcmreset + 1;
        cnt_xcmlock  <= (others => '0');
      elsif cnt_xcmlock(13) = '0' then
        clr_xcm      <= '0';
        cnt_xcmlock  <= cnt_xcmlock + 1;
      elsif reset = '1' or sta_xcm = '0' then
        cnt_xcmreset <= (others => '0');
      end if;

      -- IDELAYCTRL reset
      if clr_xcm = '1' or sta_xcm = '0' then
        cnt_ictrl <= (others => '0');
      elsif cnt_ictrl(9) = '0' then
        clr_ictrl <= '1';
        cnt_ictrl <= cnt_ictrl + 1;
      else
        clr_ictrl <= '0';
      end if;
    end if;
  end process;

  -- out
  stat   <= sta_ictrl &   sta_xcm;
  locked <= sta_ictrl and sta_xcm;

end implementation;
