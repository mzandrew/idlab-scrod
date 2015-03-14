------------------------------------------------------------------------
--
--  m_count.vhd -- counter for TTD master
--
--  Mikihiko Nakao, KEK IPNS
--
--  20130813 new
--  20140403 don't reset counters by autorst
--  20140728 no more autorst
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- - m_cntdead
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_cntdead is
  port (
    clock   : in  std_logic;
    reset   : in  std_logic_vector (2  downto 0);
    clkfreq : in  std_logic_vector (26 downto 0);
    busy    : in  std_logic;
    cdead   : out std_logic_vector (26 downto 0);
    udead   : out std_logic_vector (15 downto 0) );
end m_cntdead;
------------------------------------------------------------------------
architecture implementation of m_cntdead is

  signal cnt_udead   : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_cdead   : std_logic_vector (26 downto 0) := (others => '0');
begin

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if reset /= 0 then
        cnt_cdead <= (others => '0');
        cnt_udead <= (others => '0');
      elsif busy = '1' and cnt_cdead = clkfreq then
        cnt_cdead <= (others => '0');
        cnt_udead <= cnt_udead + 1;
      elsif busy = '1' then
        cnt_cdead <= cnt_cdead + 1;
      end if;
    end if; -- event
  end process;

  -- out
  cdead <= cnt_cdead;
  udead <= cnt_udead;
  
end implementation;
------------------------------------------------------------------------
-- - m_count
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.tt_types.all;

entity m_count is
  port (
    clock    : in  std_logic;
    cntreset : in  std_logic;  -- clk_l domain
    runreset : in  std_logic;  -- clk_l domain
    snapshot : in  std_logic;  -- clk_l domain
    utime    : in  std_logic_vector (31 downto 0);
    ctime    : in  std_logic_vector (26 downto 0);
    clkfreq  : in  std_logic_vector (23 downto 0);
    trgin    : in  std_logic;
    trgout   : in  std_logic;
    busy     : in  std_logic;
    pipebusy : in  std_logic;
    err      : in  std_logic;
    fifoful  : in  std_logic;
    regbusy  : in  std_logic;
    obusy    : in  std_logic_vector (7 downto 0);
    xbusy    : in  std_logic_vector (4 downto 1);

    frozen   : out std_logic;
    cntutime : out std_logic_vector (31 downto 0);
    cntctime : out std_logic_vector (26 downto 0);
    cntudead : out std_logic_vector (31 downto 0);
    cntcdead : out std_logic_vector (26 downto 0);
    cntpdead : out std_logic_vector (31 downto 0); -- pipebusy
    cntedead : out std_logic_vector (31 downto 0); -- err
    cntfdead : out std_logic_vector (31 downto 0); -- fifoful
    cntrdead : out std_logic_vector (31 downto 0); -- regbusy
    cntodead : out long_vector (7 downto 0);
    cntxdead : out long_vector (4 downto 1);
    cnttrgi  : out std_logic_vector (31 downto 0);
    cnttrgo  : out std_logic_vector (31 downto 0);
    cnttrgol : out std_logic_vector (31 downto 0);
    rstutime : out std_logic_vector (31 downto 0);
    rstctime : out std_logic_vector (26 downto 0);
    rstsrc   : out std_logic_vector (2  downto 0) );
end m_count;
------------------------------------------------------------------------
architecture implementation of m_count is

  signal sta_frozen  : std_logic := '0';
  signal seq_freeze  : std_logic := '0';
  signal seq_reset   : std_logic_vector (2  downto 0) := "000";
  signal buf_ctime   : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_udead   : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_cdead   : std_logic_vector (26 downto 0) := (others => '0');

  signal cnt_upipe   : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_cpipe   : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_uerr    : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_cerr    : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_ufifo   : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_cfifo   : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_ureg    : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_creg    : std_logic_vector (26 downto 0) := (others => '0');
  
  signal reg_clkfreq : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_trgi    : std_logic_vector (31 downto 0) := (others => '0');
  signal cnt_trgo    : std_logic_vector (31 downto 0) := (others => '0');
  signal seq_trgo    : std_logic := '0';

  signal cnt_uo      : word_vector        (7 downto 0) := (others => x"0000");
  signal cnt_co      : std_logic27_vector (7 downto 0) := (others => ZEROx27);
  signal cnt_ux      : word_vector        (4 downto 1) := (others => x"0000");
  signal cnt_cx      : std_logic27_vector (4 downto 1) := (others => ZEROx27);
begin

  -- in
  reg_clkfreq <= ("111" & clkfreq) - 1;

  map_u: entity work.m_cntdead port map (
    clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
    busy => busy, cdead => cnt_cdead, udead => cnt_udead );

  map_p: entity work.m_cntdead port map (
    clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
    busy => pipebusy, cdead => cnt_cpipe, udead => cnt_upipe );

  map_e: entity work.m_cntdead port map (
    clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
    busy => err, cdead => cnt_cerr, udead => cnt_uerr );

  map_f: entity work.m_cntdead port map (
    clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
    busy => fifoful, cdead => cnt_cfifo, udead => cnt_ufifo );

  map_r: entity work.m_cntdead port map (
    clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
    busy => regbusy, cdead => cnt_creg, udead => cnt_ureg );

  gen_o: for i in 0 to 7 generate
    map_o: entity work.m_cntdead port map (
      clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
      busy => obusy(i), cdead => cnt_co(i), udead => cnt_uo(i) );
  end generate;
  
  gen_x: for i in 1 to 4 generate
    map_x: entity work.m_cntdead port map (
      clock => clock, reset => seq_reset, clkfreq => reg_clkfreq,
      busy => xbusy(i), cdead => cnt_cx(i), udead => cnt_ux(i) );
  end generate;
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- clock domain
      seq_freeze <= snapshot;
      seq_reset  <= '0' & runreset & cntreset;
      
      -- frozen (for 1 sec)
      if seq_freeze = '1' then
        sta_frozen <= '1';
      elsif ctime = buf_ctime then
        sta_frozen <= '0';
      end if;

      -- buffers
      if seq_freeze = '1' or sta_frozen = '0' then
        buf_ctime   <= ctime;
        cntutime    <= utime;
        cntudead    <= x"0000" & cnt_udead;
        cntcdead    <= cnt_cdead;
        cntpdead    <= cnt_upipe & cnt_cpipe(26 downto 11);
        cntedead    <= cnt_uerr  & cnt_cerr(26 downto 11);
        cntfdead    <= cnt_ufifo & cnt_cfifo(26 downto 11);
        cntrdead    <= cnt_ureg  & cnt_creg(26 downto 11);
        cntodead(7) <= cnt_uo(7) & cnt_co(7)(26 downto 11);
        cntodead(6) <= cnt_uo(6) & cnt_co(6)(26 downto 11);
        cntodead(5) <= cnt_uo(5) & cnt_co(5)(26 downto 11);
        cntodead(4) <= cnt_uo(4) & cnt_co(4)(26 downto 11);
        cntodead(3) <= cnt_uo(3) & cnt_co(3)(26 downto 11);
        cntodead(2) <= cnt_uo(2) & cnt_co(2)(26 downto 11);
        cntodead(1) <= cnt_uo(1) & cnt_co(1)(26 downto 11);
        cntodead(0) <= cnt_uo(0) & cnt_co(0)(26 downto 11);
        cntxdead(4) <= cnt_ux(4) & cnt_cx(4)(26 downto 11);
        cntxdead(3) <= cnt_ux(3) & cnt_cx(3)(26 downto 11);
        cntxdead(2) <= cnt_ux(2) & cnt_cx(2)(26 downto 11);
        cntxdead(1) <= cnt_ux(1) & cnt_cx(1)(26 downto 11);
        cnttrgi   <= cnt_trgi;
        cnttrgol  <= cnt_trgo;
      end if;

      -- cnt_trgi
      if seq_reset(1 downto 0) /= 0 then
        cnt_trgi <= (others => '0');
      elsif trgin = '1' then
        cnt_trgi <= cnt_trgi + 1;
      end if;
      
      -- cnt_trgo, seq_trgo
      seq_trgo <= trgout;
      if seq_reset(1 downto 0) /= 0 then
        cnt_trgo <= (others => '0');
      elsif seq_trgo = '1' and trgout = '0' then
        cnt_trgo <= cnt_trgo + 1;
      end if;

      -- reset
      if seq_reset(1 downto 0) /= 0 then
        rstutime <= utime;
        rstctime <= ctime;
        rstsrc   <= seq_reset;
      end if;

      -- -- rstsrc (somehow this doesn't work)
      -- if runreset = '1' or cntreset = '1' then
      --   buf_rstsrc <= runreset & cntreset;
      -- end if;

      -- rstsrc
      -- if runreset      = '1' then
      --   buf_rstsrc(1) <= '1';
      -- elsif cntreset   = '1' then
      --   buf_rstsrc(1) <= '0';
      -- end if;
      -- if cntreset      = '1' then
      --   buf_rstsrc(0) <= '1';
      -- elsif runreset   = '1' then
      --   buf_rstsrc(0) <= '0';
      -- end if;
      
    end if; -- event
  end process;

  -- out
  frozen   <= sta_frozen;
  cntctime <= buf_ctime;
  cnttrgo  <= cnt_trgo;
  
end implementation;
