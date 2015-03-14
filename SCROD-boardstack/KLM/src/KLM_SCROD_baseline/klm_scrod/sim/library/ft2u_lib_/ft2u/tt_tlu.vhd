------------------------------------------------------------------------
--
-- tt_tlu component
--
-- 20131206 comments added on polarity
--
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity tt_tlu is
  port (
    clock    : in    std_logic;
    runreset : in    std_logic;
    bsyin    : in    std_logic;
    trgen    : in    std_logic;
    utime    : in    std_logic_vector (31 downto 0);
    ctime    : in    std_logic_vector (26 downto 0);
    tludelay : in    std_logic_vector (1  downto 0);
    skip1st  : in    std_logic;
    tluout   : in    std_logic_vector (3 downto 2);
    tluin    : out   std_logic_vector (1 downto 0);
    tlumon   : out   std_logic_vector (3  downto 0);
    tlutrg   : out   std_logic;
    tlurst   : out   std_logic;
    rstcnt   : out   std_logic_vector (7  downto 0);
    tlutag   : out   std_logic_vector (15 downto 0);
    tlubsy   : out   std_logic;
    tluutim  : out   std_logic_vector (31 downto 0);
    tluctim  : out   std_logic_vector (26 downto 0);
    dbg      : out   std_logic_vector (31 downto 0) );
end tt_tlu;

architecture implementation of tt_tlu is
  signal sig_tluin  : std_logic_vector (1  downto 0) := (others => '0');

  signal sig_trig   : std_logic := '0';
  signal cnt_trig   : std_logic_vector (15 downto 0) := (others => '0');

  signal seq_rst    : std_logic_vector (1  downto 0) := (others => '0');
  signal cnt_rst    : std_logic_vector (7  downto 0) := (others => '0');
  
  signal seq_busy   : std_logic_vector (1  downto 0) := "00";
  signal cnt_tluclk : std_logic_vector (8  downto 0) := "000000000";
  signal cnt_tludat : std_logic_vector (8  downto 0) := "000000000";
  signal sig_tluclk : std_logic := '0';
  signal buf_tludat : std_logic_vector (15 downto 0) := (others => '0');

  signal sta_delay  : std_logic_vector (7  downto 0) := (others => '0');
  
  signal cnt_dbg1   : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_dbg2   : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_dbg3   : std_logic_vector (15 downto 0) := (others => '0');

  signal sta_skip   : std_logic := '0';
begin
  -- in
  sta_delay <= ("000" & tludelay & "000");

  -- proc
  --
  -- drive tlu at 8 MHz
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      if runreset = '1' then
        sta_skip <= skip1st;
      elsif seq_busy = "11" and cnt_tludat = 0 and bsyin = '0' then
        sta_skip <= '0';
      end if;
      
      -- sig_trig
      --   TLU 7-8 pair polarity is opposite to FTSW's polarity,
      --   7: TRIGGER- / 8: TRIGGER+
      sig_trig <= not tluout(3);

      -- seq_busy
      if seq_busy = 0 and sig_trig = '1' then
        seq_busy <= "01";
      elsif seq_busy = "01" and cnt_tludat(8 downto 7) /= 0 then
        seq_busy <= "11";
      elsif seq_busy = "11" and cnt_tludat = 0 and bsyin = '0' then
        seq_busy <= "00";
      end if;

      -- cnt_tluclk / cnt_tludat
      if seq_busy = "01" and cnt_tluclk(8 downto 7) = 0 and sig_trig = '0' then
        --t_tluclk <= "100000000"; -- for 16 clocks
        cnt_tluclk <= "011110000"; -- for 17 clocks
        cnt_tludat <= "011110000" - sta_delay;
        cnt_trig <= cnt_trig + 1;
      else
        if cnt_tluclk /= 0 then -- increment until wrap up to 0
          cnt_tluclk <= cnt_tluclk + 1;
        end if;
        if cnt_tludat /= 0 then
          cnt_tludat <= cnt_tludat + 1;
        end if;
      end if;

      -- sig_tluclk
      sig_tluclk <= cnt_tluclk(3);

      -- buf_tludat
      if cnt_tludat(3 downto 0) = "1111" then
        buf_tludat <= sig_trig & buf_tludat(buf_tludat'left downto 1);
        cnt_dbg1 <= cnt_dbg1 + 1;
      end if;

      -- seq_rst, cnt_rst
      if seq_rst = "01" then
        cnt_rst <= cnt_rst + 1;
        tluutim <= utime;
        tluctim <= ctime;
      end if;
      seq_rst <= seq_rst(0) & tluout(2);
      
    end if;
  end process;

  -- out
  
  -- sig_tluin
  --   TLU 1-2 and 3-6 pair polarity is opposite to FTSW's polarity,
  --   1: DATA_CLOCK- / 2: DATA_CLOCK+ / 3: BUSY- / 6: BUSY+
  sig_tluin(0) <= not sig_tluclk;
  sig_tluin(1) <= not seq_busy(0);
  tluin <= sig_tluin;

  tlumon(3) <= tluout(3); -- Trigger or DATA from TLU
  tlumon(2) <= tluout(2); -- Reset           from TLU
  tlumon(1) <= sig_tluin(1); -- BUSY            to TLU
  tlumon(0) <= sig_tluin(0); -- DATA clock      to TLU

  -- for 16 clocks
  --gtag <= cnt_trig(15 downto 0) & buf_tludat(0) & buf_tludat(15 downto 1);
  -- for 17 clocks
  tlutag <= buf_tludat(15 downto 0);
  tlutrg <= sig_trig when seq_busy = 0 and sta_skip = '0' else '0';
  tlurst <= seq_rst(0);
  rstcnt <= cnt_rst;
  --fifod  <= buf_d(7 downto 0);
  tlubsy <= '1' when bsyin = '1' or trgen = '0' or
                     seq_busy = "01" or cnt_tluclk(8 downto 7) /= 0 else '0';

  dbg    <= cnt_dbg3 & cnt_dbg2 & cnt_dbg1;
end implementation;
