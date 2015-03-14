------------------------------------------------------------------------
--
-- m_genbusy component --- busy generator
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_genbusy is
  port (
    clock   : in  std_logic;
    reset   : in  std_logic;
    trig    : in  std_logic;
    clkerr  : in  std_logic;
    errin   : in  std_logic;
    linkerr : in  std_logic;
    b2lup   : in  std_logic;
    busyin1 : in  std_logic;
    busyin2 : in  std_logic;
    fullin  : in  std_logic;
    usetlu  : in  std_logic;
    tlubusy : in  std_logic;
    regbusy : in  std_logic;
    tshort  : in  std_logic;
    errout  : out std_logic;
    errsrc  : out std_logic_vector (3 downto 0);
    nontlu  : out std_logic;
    busyout : out std_logic;
    busysrc : out std_logic_vector (5 downto 0) );
end m_genbusy;

architecture implementation of m_genbusy is
  signal sig_busy1 : std_logic := '0';
  signal cnt_interval : std_logic_vector (4 downto 0) := "00000";
  signal sta_anybsy : std_logic := '0';
  signal sta_anyerr : std_logic := '0';
  signal sta_bsysrc : std_logic_vector (5 downto 0) := (others => '0');
  signal sig_bsysrc : std_logic_vector (5 downto 0) := (others => '0');
  signal sta_errsrc : std_logic_vector (3 downto 0) := (others => '0');
  signal sig_errsrc : std_logic_vector (3 downto 0) := (others => '0');
  signal sta_error  : std_logic := '0';
begin
  -- in
  sta_anybsy <= busyin1   or busyin2 or trig or
                sig_busy1 or regbusy or fullin;
  sig_bsysrc <= busyin1   &  busyin2 &  trig &
                sig_busy1 &  regbusy &  fullin;
  sta_anyerr <= clkerr or errin or linkerr or tshort;
  sig_errsrc <= clkerr &  errin &  linkerr &  tshort;
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- cnt_interval
      if trig = '1' then
        cnt_interval <= "10110"; -- 22 (to generate 24 clock long busy)
      elsif cnt_interval /= 0 then
        cnt_interval <= cnt_interval - 1;
      end if;

      -- sig_busy1
      if trig = '1' or cnt_interval /= 0 then
        sig_busy1 <= '1';
      else
        sig_busy1 <= '0';
      end if;

      -- sta_err, sta_errsrc
      if reset = '1' then
        sta_error  <= sta_anyerr;
        sta_errsrc <= sig_errsrc;
      else
        sta_error  <= sta_anyerr or sta_error;
        sta_errsrc <= sta_errsrc or sig_errsrc;
      end if;

      -- sta_bsysrc
      sta_bsysrc <= sig_bsysrc;
      
    end if; -- event
  end process;
  
  -- out
  errout  <= sta_anyerr or sta_error;
  errsrc  <= sta_errsrc;

  nontlu  <= sta_anybsy and usetlu;
  busyout <= sta_anybsy or (usetlu and tlubusy);
  busysrc <= sta_bsysrc;
  
end implementation;

