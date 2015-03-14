------------------------------------------------------------------------
--
-- tt_ictrl.vhd --- FTSW2 Virtex5 IODELAYCTRL
--
-- Mikihiko Nakao, KEK IPNS
--
-- 20120409 0.01  new
-- 20130411 0.02  renamed from mnictrl
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;

entity tt_idelayctrl is
  port (
    clock : in  std_logic;
    reset : in  std_logic;
    stat  : out std_logic_vector (1 downto 0) );

end tt_idelayctrl;

architecture implementation of tt_idelayctrl is
  signal sig_clk0  : std_logic := '0';
  signal sig_clkfx : std_logic := '0';
  signal clk_fb    : std_logic := '0';
  signal clk_200   : std_logic := '0';

  signal sta_dcm      : std_logic := '0';
  signal clr_dcm      : std_logic := '0';
  signal sta_ictrl    : std_logic := '0';
  signal clr_ictrl    : std_logic := '0';
  signal cnt_dcmreset : std_logic_vector (3  downto 0) := (others => '0');
  signal cnt_dcmlock  : std_logic_vector (13 downto 0) := (others => '0');
  signal cnt_ictrl    : std_logic_vector (9  downto 0) := (others => '0');
begin

  -- in
  stat <= sta_ictrl & sta_dcm;

  ------------------------------------------------------------------------
  -- DCM
  ------------------------------------------------------------------------
  map_fb: bufg port map ( i => sig_clk0,  o => clk_fb );
  map_fx: bufg port map ( i => sig_clkfx, o => clk_200 );

  map_dcm: dcm_base
    generic map (
      CLKFX_MULTIPLY => 8,
      CLKFX_DIVIDE   => 5,
      DFS_FREQUENCY_MODE => "HIGH",
      DLL_FREQUENCY_MODE => "HIGH",
      DCM_PERFORMANCE_MODE => "MAX_SPEED" )
    port map (
      rst    => clr_dcm,
      locked => sta_dcm,
      clkin  => clock,
      clk0   => sig_clk0,
      clkfx  => sig_clkfx,
      clkfb  => clk_fb );

  ------------------------------------------------------------------------
  -- idelayctrl (refclk: 200+-10 MHz)
  ------------------------------------------------------------------------
  map_ic: idelayctrl
    port map ( refclk => clk_200, rst => clr_ictrl, rdy => sta_ictrl );

  ------------------------------------------------------------------------
  -- reset
  --  idelayctrl initial reset (>3us or >385clk)
  --  dcm at least 3 clkin to reset, several thousand clocks to lock
  ------------------------------------------------------------------------
  proc_reset: process (clock)
  begin
    if clock'event and clock = '1' then
      -- DCM reset
      if cnt_dcmreset(3) = '0' then
        clr_dcm      <= '1';
        cnt_dcmreset <= cnt_dcmreset + 1;
        cnt_dcmlock  <= (others => '0');
      elsif cnt_dcmlock(13) = '0' then
        clr_dcm      <= '0';
        cnt_dcmlock  <= cnt_dcmlock + 1;
      elsif reset = '1' or sta_dcm = '0' then
        cnt_dcmreset <= (others => '0');
      end if;

      -- IDELAYCTRL reset
      if clr_dcm = '1' or sta_dcm = '0' then
        cnt_ictrl <= (others => '0');
      elsif cnt_ictrl(9) = '0' then
        clr_ictrl <= '1';
        cnt_ictrl <= cnt_ictrl + 1;
      else
        clr_ictrl <= '0';
      end if;
    end if;
  end process;
  
end implementation;
