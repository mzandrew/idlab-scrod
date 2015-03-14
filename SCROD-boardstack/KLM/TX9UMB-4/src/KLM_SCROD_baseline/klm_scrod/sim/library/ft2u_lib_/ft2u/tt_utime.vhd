------------------------------------------------------------------------
-- - tt_utime
--   utime: number of seconds since 1970-01-01-00:00 in unsigned 32-bit,
--          which is almost unix time, but in unsigned to avoid year 2038
--          overflow
--   ctime: number of clocks within every second
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tt_utime is
  port (
    clock   : in  std_logic;
    cntclk  : in  std_logic_vector (10 downto 0);
    set     : in  std_logic;
    val     : in  std_logic_vector (31 downto 0);
    clkfreq : in  std_logic_vector (23 downto 0); -- range [117.4,134.2] MHz
    utset   : out std_logic;
    utime   : out std_logic_vector (31 downto 0);
    ctime   : out std_logic_vector (26 downto 0);
    utimer  : out std_logic_vector (31 downto 0);
    ctimer  : out std_logic_vector (26 downto 0) );
end tt_utime;
------------------------------------------------------------------------
architecture implementation of tt_utime is
  signal buf_utime   : std_logic_vector (31 downto 0) := (others => '0');
  signal cnt_utimer  : std_logic_vector (31 downto 0) := (others => '0');
  signal cnt_sec     : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_ctime   : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_ctimer  : std_logic_vector (26 downto 0) := (others => '0');
  signal reg_clkfreq : std_logic_vector (26 downto 0) := (others => '0');
  signal seq_set     : std_logic_vector (1  downto 0) := (others => '0');
begin
  -- in
  reg_clkfreq <= ("111" & clkfreq) - 1;

  -- proc
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- buf_utime, seq_set
      if set = '1' then
        buf_utime  <= val;
        seq_set    <= "01";
        utset      <= '1';
      elsif seq_set = "01" and cntclk = 1200 then
        seq_set    <= "10";
      elsif seq_set = "10" and cntclk = 1279 then
        seq_set    <= "00";
      end if;

      -- cnt_utimer, cnt_ctimer
      if seq_set = "01" and cntclk = 1200 then
        cnt_utimer <= buf_utime;
        cnt_ctimer <= (others => '0');
      elsif cnt_ctimer = reg_clkfreq then
        cnt_utimer <= cnt_utimer + 1;
        cnt_ctimer <= (others => '0');
      else
        cnt_ctimer <= cnt_ctimer + 1;
      end if;
      
      -- utime, cnt_ctime
      if seq_set = "10" and cntclk = 1279 then
        cnt_ctime <= (others => '0');
        utime     <= cnt_utimer;
      elsif cnt_ctime = reg_clkfreq then
        cnt_ctime <= (others => '0');
        utime     <= cnt_utimer;
      else
        cnt_ctime <= cnt_ctime + 1;
      end if;
      
    end if;
  end process;

  -- out
  utimer <= cnt_utimer;
  ctime  <= cnt_ctime;
  ctimer <= cnt_ctimer;
  
end implementation;
