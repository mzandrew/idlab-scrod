------------------------------------------------------------------------
--
--  b2tt_ddr_s6.vhd -- TT-link DDR and delay hander for Belle2link
--                     frontend for Spartan-6
--
--  Mikihiko Nakao, KEK IPNS
--
--  20131002 separated from b2tt_decode.vhd and b2tt_encode.vhd
--  20131013 Spartan-6 support
--  20131101 no more std_logic_arith
--  20131113 merging changes to ddr_v5 into ddr_s6
--  20131119 bitddr output from dataout2, sig_inc was forgotten
--  20131120 cal to be asserted with data - once in 1024 times of sig_inc
--
--  tap calibration based on SP605 (sp605_b2tt09.bit)
--    2.32 ns per 100 inc => about 170 inc to cover (7.86ns/2)
--
--   VARIABLE_FROM_HALF_MAX resets to somewhere not zero
--   DIFF_PHASE_DETECTOR does not increment
--   VARIABLE_FROM_ZERO resets to zero at 163 inc (maybe internally measured)
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- - b2tt_iddr
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;

entity b2tt_iddr is
  generic (
    FLIPIN    : std_logic := '0';
    REFFREQ   : real      := 203.546;
    WRAPCOUNT : integer   := 170 ); -- 51 for vertex, 75 for spartan-6
  port (
    clock    : in  std_logic;
    invclock : in  std_logic; -- spartan6 only
    inp      : in  std_logic;
    inn      : in  std_logic;
    incdelay : in  std_logic;
    clrdelay : in  std_logic;
    sigslip  : in  std_logic;
    enslip   : in  std_logic;
    autoslip : in  std_logic;
    decdelay : in  std_logic; -- debug only (decrement instead of increment)
    caldelay : in  std_logic; -- spartan6 only
    staslip  : out std_logic;
    bitddr   : out std_logic;
    bit2     : out std_logic_vector (1  downto 0);
    cntdelay : out std_logic_vector (11 downto 0) );

end b2tt_iddr;
------------------------------------------------------------------------
architecture implementation of b2tt_iddr is
  signal sig_q      : std_logic := '0';
  signal sig_i      : std_logic := '0';
  signal seq_inc    : std_logic_vector (1 downto 0) := "00";
  signal sig_inc    : std_logic := '0';
  signal sig_clr    : std_logic := '0';
  signal cnt_delay  : std_logic_vector (7 downto 0) := "00000000";
  signal cnt_delay2 : std_logic_vector (2 downto 0) := "000";
  signal sig_bit2   : std_logic_vector (1 downto 0) := "00";
  signal sig_raw2   : std_logic_vector (1 downto 0) := "00";
  signal sta_slip   : std_logic := '0';
  signal buf_bit    : std_logic := '0';
  signal sig_incdir   : std_logic := '1';

  -- spartan6 only
  signal open_d2    : std_logic := '0';
  signal open_do    : std_logic := '0';
  signal open_to    : std_logic := '0';
  signal open_fo    : std_logic := '0';
  signal sig_busy   : std_logic := '0';
  signal cnt_caldelay : std_logic_vector (9  downto 0) := (others => '0');
  signal seq_caldelay : std_logic_vector (1  downto 0) := "00";
  signal sig_caldelay : std_logic := '0';
begin
  -- in
  sig_caldelay <= caldelay or (seq_caldelay(0) and (not seq_caldelay(1)));
  sig_incdir   <= not decdelay;
  
  map_ibufds: ibufds
    port map ( o => sig_i, i => inp, ib => inn );

  map_idelay: iodelay2
    generic map (
      IDELAY_VALUE       => 0,
      IDELAY2_VALUE      => 0,
      IDELAY_MODE        => "NORMAL",
      --IDELAY_TYPE        => "DIFF_PHASE_DETECTOR",
      --IDELAY_TYPE        => "VARIABLE_FROM_HALF_MAX",
      IDELAY_TYPE        => "VARIABLE_FROM_ZERO",
      DATA_RATE          => "DDR",
      COUNTER_WRAPAROUND => "WRAPAROUND",
      DELAY_SRC          => "IDATAIN" )
    port map (
      idatain  => sig_i,
      odatain  => '0',
      dataout  => sig_q,
      ioclk0   => clock,
      ioclk1   => invclock,
      clk      => clock,
      ce       => sig_inc,
      rst      => sig_clr,       -- auto-reset after wrapcount
      --rst    => clrdelay,      -- by hand only
      inc      => sig_incdir,
      t        => '1',           -- 1 for input only / 0 for output only
      cal      => sig_caldelay,  -- auto-calibration after 1024 sig_inc
      --cal    => caldelay,      -- by hand only
      dataout2 => bitddr,
      busy     => sig_busy,
      dout     => open_do,
      tout     => open_to );

  map_id: iddr2
    generic map (
      DDR_ALIGNMENT => "C0" )
    port map (
      s  => '0',
      d  => sig_q,
      ce => '1',
      c0 => clock,
      c1 => invclock,
      r  => '0',
      q0 => sig_raw2(0),
      q1 => sig_raw2(1) );

  sig_bit2(0) <= sig_raw2(0) xor FLIPIN;
  sig_bit2(1) <= sig_raw2(1) xor FLIPIN;
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- incdelay / clrdelay combination
      
      seq_inc <= seq_inc(0) & incdelay;

      -- VIRTEX5 / VIRTEX6: idelayctrl clock tick = 7.8 ns / (8/5)
      -- tap = 7.8 ns / ((8/5*64))
      -- to cover half clock width (3.9ns): (8/5)*64/2 = about 51 (WRAPCOUNT)
      -- [for V6, one iodelay can cover only up to 31 taps]
      --
      -- SPARTAN6 has 255 taps
      --http://nahitafu.cocolog-nifty.com/nahitafu/2010/08/spartan-6io-be0.html
      --  "cal" signal has to be asserted once, when data is present
      --  (also confirmed with test setup)
      --
      --  TAP length:
      --   from nahitafu site (URL above)  => O(30ps)
      --   from ds162(v3.0) p.47 table 39  => < 52 ps
      --   from measurement (sp605_b2tt09.bit) => ~23 ps
      --
      --  actual tap delay length is not clear from ds162(v3.0) p.47 table 39

      if cnt_caldelay = 0 then
        seq_caldelay <= seq_caldelay(0) & '1';
      else
        seq_caldelay <= seq_caldelay(0) & '0';
      end if;

      if sig_inc = '1' then
        cnt_caldelay <= cnt_caldelay + 1;
      end if;

      if clrdelay = '1' then
        sig_clr <= '1';
        cnt_delay2 <= (others => '0');
      elsif sig_incdir = '1' and seq_inc = "01" and cnt_delay = WRAPCOUNT then
        sig_clr <= '1';
        cnt_delay2 <= cnt_delay2 + 1;
      else
        sig_clr <= '0';
      end if;

      if sig_incdir = '1' and seq_inc = "01" and cnt_delay /= WRAPCOUNT then
        sig_inc <= '1';
      elsif sig_incdir = '0' and seq_inc = "01" and cnt_delay /= 0 then
        sig_inc <= '1';
      else
        sig_inc <= '0';
      end if;

      if sig_clr = '1' then
        cnt_delay <= (others => '0');
      elsif sig_inc = '1' then
        if sig_incdir = '1' then
          cnt_delay <= cnt_delay + 1;
        else
          cnt_delay <= cnt_delay - 1;
        end if;
      end if;

      -- slip logic
      if autoslip = '1' and sigslip = '1' then
        sta_slip <= not sta_slip;
      elsif autoslip = '0' then
        sta_slip <= enslip;
      end if;
      buf_bit <= sig_bit2(0);

      -- bit2
      if sta_slip = '0' then
        bit2 <= sig_bit2;
      else
        bit2 <= buf_bit & sig_bit2(1);
      end if;
      
    end if; -- event
  end process;

  -- bit2 was generated here up to b2tt 0.11, but it is a bit timing-tight
  --   -- out (buf_bit is sync, sig_bit2 is async)
  --   bit2 <= sig_bit2 when sta_slip = '0' else buf_bit & sig_bit2(1);
  
  -- out
  --bitddr <= '0';
  staslip  <= sta_slip;
  cntdelay <= sta_slip & cnt_delay2 & cnt_delay;
  
end implementation;

------------------------------------------------------------------------
-- b2tt_oddr
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;

entity b2tt_oddr is
  generic (
    FLIPOUT : std_logic := '0';
    REFFREQ : real      := 203.546 );
  port (
    clock    : in  std_logic;
    invclock : in  std_logic;
    mask     : in  std_logic;
    bit2     : in  std_logic_vector (1 downto 0);
    bitddr   : out std_logic;
    outp     : out std_logic;
    outn     : out std_logic
  );
end b2tt_oddr;
------------------------------------------------------------------------
architecture implementation of b2tt_oddr is
  signal sig_o    : std_logic := '0';
  signal sig_oq   : std_logic := '0';
  signal sig_bit2 : std_logic_vector (1 downto 0) := "00";
begin
  -- in
  sig_bit2(0) <= bit2(0) xor FLIPOUT;
  sig_bit2(1) <= bit2(1) xor FLIPOUT;
  
  map_obufds: obuftds
    port map ( i => sig_o, o => outp, ob => outn, t => mask );

  map_odelay: iodelay2
    generic map (
      ODELAY_VALUE       => 0,
      DELAY_SRC          => "ODATAIN" )
    port map (
      idatain => '0',
      t       => '0',
      odatain => sig_oq,
      cal    => '0',
      ioclk0 => '0',
      ioclk1 => '0',
      clk => '0',
      inc => '1',
      ce  => '0',
      rst => '0',
      dataout2 => bitddr,
      dout => sig_o );

  map_od: oddr2
    generic map (
      DDR_ALIGNMENT => "C0",
      SRTYPE        => "ASYNC" )
    port map (
      s => '0',
      d0 => sig_bit2(1), -- order: d1 first, d2 second
      d1 => sig_bit2(0), -- (10b: left-most-bit first, right-most last)
      ce => '1',
      c0 => clock,
      c1 => invclock,
      r  => '0',
      q  => sig_oq );

  -- out
  --bitddr <= sig_o;
  --bitddr <= '0';
  
end implementation;
