------------------------------------------------------------------------
--
-- m_gentrig component --- trigger selector and generator
--
-- 20130925 fix: cnt_last <= limit even if en=0 (when last = -1)
-- 20131206 err is added / trgsrc3(TLU) is allowed even when busy
-- 20130102 clear tlast at runreset
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_gentrig is
  port (
    clock   : in  std_logic;
    reset   : in  std_logic;
    busy    : in  std_logic;
    err     : in  std_logic;
    start   : in  std_logic;
    stop    : in  std_logic;
    limit   : in  std_logic_vector (31 downto 0);
    last    : out std_logic_vector (31 downto 0);
    seltrg  : in  std_logic_vector (2  downto 0);
    genbor  : in  std_logic;
    trgsrc1 : in  std_logic;
    trgsrc2 : in  std_logic;
    trgsrc3 : in  std_logic;
    dumtrg  : in  std_logic;
    en      : out std_logic;
    trgin   : out std_logic;
    trig    : out std_logic;
    trgtyp  : out std_logic_vector (3  downto 0);
    dbg     : out std_logic_vector (31 downto 0) );
end m_gentrig;

architecture behavior of m_gentrig is
  signal sig_trgin   : std_logic := '0';
  signal sig_trig    : std_logic := '0';
  signal cnt_last    : std_logic_vector (31 downto 0) := x"ffffffff";
  signal seq_start   : std_logic_vector (1 downto 0) := "00";
  signal sta_en      : std_logic := '1';
  signal cnt_dbg1    : std_logic_vector (7 downto 0) := x"00";
  signal cnt_dbg2    : std_logic_vector (7 downto 0) := x"00";
  signal cnt_dbg3    : std_logic_vector (7 downto 0) := x"00";
  signal cnt_dbg4    : std_logic_vector (7 downto 0) := x"00";
  signal seq_trgsrc1 : std_logic := '0';
  signal seq_trgsrc2 : std_logic := '0';
  signal seq_trgsrc3 : std_logic := '0';
begin
  proc: process(clock)
  begin
    if clock'event and clock = '1' then
      -- sta_en
      -- (sta_en = '0' is needed in the first condition since
      --  it takes one clock longer to get sta_en = 0 after limit <= 0)
      if sta_en = '0' and seq_start = "01" and limit /= 0 then
        sta_en <= '1';
      elsif cnt_last = 0 or stop = '1' then
        sta_en <= '0';
      end if;

      -- cnt_last
      -- (while debugging ft2u057)
      if limit = 0 then
        cnt_last <= (others => '0');
      elsif (sta_en = '0' or cnt_last = 0) and seq_start = "01" then
        cnt_last <= limit;
      elsif sig_trig = '1' and cnt_last(cnt_last'left) = '0' and
            cnt_last(cnt_last'left-1 downto 0) /= 0 then
        cnt_last <= cnt_last - 1;
      end if;
      
      --if reset = '1' then
      --  cnt_last <= (others => '0');
      --elsif (sta_en = '0' or limit = 0 or cnt_last(cnt_last'left) = '1') and
      --    seq_start = "01" and cnt_last = 0 then
      --  cnt_last <= limit; 
      --elsif sig_trig = '1' and cnt_last(cnt_last'left) = '0' and
      --      cnt_last(cnt_last'left-1 downto 0) /= 0 then
      --  cnt_last <= cnt_last - 1;
      --end if;

      -- seq_start
      seq_start   <= seq_start(0) & start;

      -- sig_trgin
      if sig_trgin = '1' then
        sig_trgin <= '0';
      elsif seltrg = 1 and seq_trgsrc1 = '0' and trgsrc1 = '1' then
        sig_trgin <= '1';
      elsif seltrg = 2 and seq_trgsrc2 = '0' and trgsrc2 = '1' then
        sig_trgin <= '1';
      elsif seltrg = 3 and seq_trgsrc3 = '0' and trgsrc3 = '1' then
        sig_trgin <= '1';
      elsif seltrg(2) = '1' and dumtrg = '1' then
        sig_trgin <= '1';
      end if;
      
      -- sig_trig, trgtyp
      if sta_en = '0' then
        if seq_start = "01" and limit /= 0 and genbor = '1' then
          sig_trig <= '1';
        else
          sig_trig <= '0';
        end if;
        trgtyp   <= TTYP_NONE;
      elsif sig_trig = '1' then
        sig_trig <= '0';
      elsif err = '1' then
        sig_trig <= '0';
      elsif seltrg = 3 and seq_trgsrc3 = '0' and trgsrc3 = '1' then
        -- At least one trgsrc3 (TLU trigger) should be accepted even if
        -- the system is busy.  More than one trigger will not be generated
        -- in tt_tlu component when busy.
        sig_trig <= '1';
        trgtyp   <= TTYP_TEST;
      elsif busy = '1' then
        sig_trig <= '0';
      elsif seltrg = 1 and seq_trgsrc1 = '0' and trgsrc1 = '1' then
        sig_trig <= '1';
        trgtyp   <= TTYP_TEST;
      elsif seltrg = 2 and seq_trgsrc2 = '0' and trgsrc2 = '1' then
        sig_trig <= '1';
        trgtyp   <= TTYP_TEST;
      elsif seltrg(2) = '1' and dumtrg = '1' then
        sig_trig <= '1';
        trgtyp   <= TTYP_RAND;
      end if;

      -- sig_trgtyp

      -- seq_trgsrc1,2,3
      seq_trgsrc1 <= trgsrc1;
      seq_trgsrc2 <= trgsrc2;
      seq_trgsrc3 <= trgsrc3;
    end if;
    
  end process;

  -- out
  en    <= sta_en;
  trig  <= sig_trig;
  trgin <= sig_trgin;
  last  <= cnt_last;
  dbg   <= cnt_dbg4 & cnt_dbg3 & cnt_dbg2 & cnt_dbg1;
  --dbg <= cnt_dbg2 & cnt_dbg1;
  
end behavior;
