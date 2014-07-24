------------------------------------------------------------------------
--
--- b2tt.vhd --- Belle II TT-link receiver top
---
--  This firmware is a reference design for a frontend board
--  which is connected to ft3u firmware
--
--  (Note: there are still missing features,
--         marked with TBI = to be implemented.)
--
--  Mikihiko Nakao, KEK IPNS
--  20130530 0.01  first version
--     (there are many intermediate versions between 0.01 and 0.02)
--  20130926 0.02  revised (revo/revo9, b2ltag in ack packet)
--  20131002 0.03  revised (exprun, b2tt_ddr.vhd)
--  20131013 0.04  merging v5,v6,s6 versions
--  20131028 0.05  fixing b2tt_ddr
--  20131101 0.06  no more std_logic_arith
--  20131110 0.07  96-bit fifodata for final(?) header format
--  20131118 0.08  all open ports are connected to dummy signals
--  20131119 0.09  S6 iodelay2 fix
--  20131121 0.10  tested with S6/V5/V6, more iodelay monitor and control
--  20131127 0.11  duplicated header fix (bug in b2tt_fifo)
--  20131218 0.12  entagerr added
--  20140102 0.13  fix for one-pulse err signal, tagerr check ini.values
--  20140406 0.14  ttup error study
--  20140409 0.15  crc8 trial
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity b2tt is
  generic (
    VERSION  : integer := 15;
    DEFADDR  : std_logic_vector (19 downto 0) := x"00000";
    FLIPCLK  : std_logic := '0';
    FLIPTRG  : std_logic := '0';
    FLIPACK  : std_logic := '0';
    USEFIFO  : std_logic := '1';
    CLKDIV1  : integer range 1 to 72 := 3;
    CLKDIV2  : integer range 1 to 72 := 4;
    USEPLL   : std_logic := '0';
    USEICTRL : std_logic := '1';
    NBITTIM  : integer range 1 to 32 := 32;
    NBITTAG  : integer range 4 to 32 := 32;
    NBITID   : integer range 4 to 32 := 16;
    B2LRATE  : integer := 4 );  -- 127 Mbyte / s
  port (
    -- RJ-45
    clkp     : in  std_logic;
    clkn     : in  std_logic;
    trgp     : in  std_logic;
    trgn     : in  std_logic;
    rsvp     : out std_logic;
    rsvn     : out std_logic;
    ackp     : out std_logic;
    ackn     : out std_logic;

    -- board id
    id       : in  std_logic_vector (NBITID-1 downto 0);

    -- link status
    b2clkup  : out std_logic;
    b2ttup   : out std_logic;

    -- system clock and time
    sysclk   : out std_logic;
    sysclk2x : out std_logic;
    rawclk   : out std_logic;
    utime    : out std_logic_vector (NBITTIM-1 downto 0);
    ctime    : out std_logic_vector (26 downto 0);

    -- divided clock
    divclk1  : out std_logic_vector (1 downto 0);
    divclk2  : out std_logic_vector (1 downto 0);

    -- exp- / run-number
    exprun   : out std_logic_vector (31 downto 0);
    
    -- run reset
    runreset : out std_logic;
    feereset : out std_logic;
    b2lreset : out std_logic;
    gtpreset : out std_logic;
    
    -- trigger
    trgout   : out std_logic;
    trgtyp   : out std_logic_vector (3  downto 0);
    trgtag   : out std_logic_vector (31 downto 0);

    -- revolution
    revo     : out std_logic;
    revo9    : out std_logic;
    revoclk  : out std_logic_vector (10 downto 0);
    revogap  : out std_logic;                       -- TBI
    injveto  : out std_logic_vector (1 downto 0);   -- TBI
    
    -- busy and status return
    busy     : in  std_logic; -- to suspend the trigger
    err      : in  std_logic; -- to stop the run

    -- Belle2link status
    b2plllk  : in  std_logic;
    b2linkup : in  std_logic;
    b2linkwe : in  std_logic;
    b2lclk   : in  std_logic;

    -- SEU status (from virtex5_seu_controller)
    seuinit  : in  std_logic;  -- initialising
    seubusy  : in  std_logic;  -- busy
    seuactiv : in  std_logic;  -- acm_active
    seuscan  : in  std_logic;  -- end_of_scan
    seudet   : in  std_logic;  -- seu_detect
    seucrc   : in  std_logic;  -- crc_error
    seumbe   : in  std_logic;  -- mbe
    
    -- data for Belle2link header
    fifordy  : out std_logic;
    fifodata : out std_logic_vector (95 downto 0);
    fifonext : in  std_logic;

    -- b2tt-link status
    regdbg   : in  std_logic_vector (7 downto 0);
    octet    : out std_logic_vector (7 downto 0);  -- decode
    isk      : out std_logic;                      -- decode
    cntbit2  : out std_logic_vector (2 downto 0);  -- decode
    sigbit2  : out std_logic_vector (1 downto 0);  -- decode
    bitddr   : out std_logic;                      -- encode
    dbg      : out std_logic_vector (31 downto 0);
    dbg2     : out std_logic_vector (31 downto 0) );

end b2tt;

architecture implementation of b2tt is

  signal sig_clkin    : std_logic := '0';
  signal clk_i        : std_logic := '0';
  signal clk_inv      : std_logic := '0';
  ------ clk_254      : std_logic := '0';
  ------ sig_254s     : std_logic := '0';
  
  signal regin        : std_logic_vector (5  downto 0) := (others => '0');
  signal reg_imanual  : std_logic := '0';
  signal clr_idelay   : std_logic := '0';
  signal set_idelay   : std_logic := '0';
  signal reg_slip     : std_logic := '0';
  signal sig_caldelay : std_logic := '0';
  signal sig_decdelay : std_logic := '0';

  signal sta_dcm      : std_logic := '0';
  signal buf_myaddr   : std_logic_vector (19 downto 0) := DEFADDR;

  signal sta_utime    : std_logic_vector (31 downto 0) := (others => '0');
  signal sta_ctime    : std_logic_vector (26 downto 0) := (others => '0');
  signal sta_timerr   : std_logic := '0';
  signal sig_runreset : std_logic := '0';
  signal sig_trig     : std_logic := '0';
  signal sta_trgtyp   : std_logic_vector (3  downto 0) := (others => '0');
  signal sta_trgtag   : std_logic_vector (31 downto 0) := (others => '0');
  signal sta_tagerr   : std_logic := '0';

  signal sta_trgshort : std_logic := '0';
  signal sta_octet    : std_logic := '0';
  signal sta_link     : std_logic := '0';
  signal cnt_linkrst  : std_logic_vector (7  downto 0) := (others => '0');
  signal sig_frame    : std_logic := '0';
  signal sig_frame9   : std_logic := '0';
  signal buf_payload  : std_logic_vector (76 downto 0) := (others => '0');
  signal sig_payload  : std_logic := '0';
  signal sig_idle     : std_logic := '0';

  signal cnt_packet   : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_delay    : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_slip     : std_logic_vector (1  downto 0) := (others => '0');
  signal sta_slip     : std_logic := '0';
  signal sig_bitddr   : std_logic := '0';

  signal sig_dbg2     : std_logic_vector (31 downto 0) := (others => '0');
  signal sig_rawclk   : std_logic := '0';

  signal sta_fifoful  : std_logic := '0';
  signal sta_fifoemp  : std_logic := '0'; -- unused
  signal sta_fifoerr  : std_logic := '0';
  signal sta_seu      : std_logic_vector (6  downto 0) := (others => '0');

  signal sig_trgdat   : std_logic_vector (95 downto 0) := (others => '0');

  -- unused signals defined for poor simulator
  signal open_stat    : std_logic_vector (1  downto 0) := (others => '0');
  signal open_drd     : std_logic_vector (95 downto 0) := (others => '0');
  signal open_dbg     : std_logic_vector (17 downto 0) := (others => '0');
  signal open_bit10   : std_logic_vector (9  downto 0) := (others => '0');
  signal open_cnt2    : std_logic_vector (2  downto 0) := (others => '0');
  signal open_cnto    : std_logic_vector (3  downto 0) := (others => '0');
  signal open_isk     : std_logic := '0';
  signal open_octet   : std_logic_vector (7  downto 0) := (others => '0');
  signal open_bit2    : std_logic_vector (1  downto 0) := (others => '0');
  signal open_bitddr  : std_logic := '0';
begin

  -- in
  regin <= regdbg(5 downto 0);
  reg_imanual  <= regin(0);
  reg_slip     <= regin(1);
  set_idelay   <= regin(2);
  clr_idelay   <= regin(3);
  sig_caldelay <= regin(4);
  sig_decdelay <= regin(5);
  sta_seu <= seuinit & seubusy & seuactiv & seuscan & seudet & seucrc & seumbe;

  map_clk: entity work.b2tt_clk
    generic map (
      FLIPCLK  => FLIPCLK,
      USEPLL   => USEPLL,
      USEICTRL => USEICTRL )
    port map (
      clkp     => clkp,
      clkn     => clkn,
      reset    => '0', -- (probably there's no way to reset)
      rawclk   => sig_rawclk,  -- out
      clock    => clk_i,       -- out
      invclock => clk_inv,     -- out
      clk254   => sysclk2x, --bmk
      locked   => sta_dcm,     -- out
      stat     => open_stat ); -- out

  sig_trgdat <= sta_fifoerr & sta_ctime(26 downto 0) & sta_trgtyp(3 downto 0) &
                sta_trgtag(31 downto 0) &
                sta_utime(31 downto 0);
  
  map_fifo: entity work.b2tt_fifo
    port map (
      -- input
      clock  => clk_i,
      enfifo => USEFIFO,
      clr    => sig_runreset,
      wr     => sig_trig,
      din    => sig_trgdat,
      rd     => fifonext,
      ready  => fifordy,
      dout   => fifodata,      -- out
      drd    => open_drd,      -- out
      err    => sta_fifoerr,   -- out
      dbg    => open_dbg,      -- out
      empty  => sta_fifoemp,   -- out
      full   => sta_fifoful ); -- out
      
      
  
  map_decode: entity work.b2tt_decode
    generic map (
      FLIPTRG => FLIPTRG,
      DEFADDR => DEFADDR,
      CLKDIV1 => CLKDIV1,
      CLKDIV2 => CLKDIV2 )
    port map (
      -- input
      clock      => clk_i,
      invclock   => clk_inv,
      en         => sta_dcm,
      trgp       => trgp,
      trgn       => trgn,

      -- system time
      utime      => sta_utime,    -- out
      ctime      => sta_ctime,    -- out
      timerr     => sta_timerr,   -- out

      -- exp- / run-number
      exprun     => exprun,       -- out
      myaddr     => buf_myaddr,   -- out
      
      -- reset out
      runreset   => sig_runreset, -- out
      feereset   => feereset, -- out
      b2lreset   => b2lreset, -- out
      gtpreset   => gtpreset, -- out
      
      -- trigger out
      trgout     => sig_trig,     -- out
      trgtyp     => sta_trgtyp,   -- out
      trgtag     => sta_trgtag,   -- out
      tagerr     => sta_tagerr,   -- out
      trgshort   => sta_trgshort, -- out
      
      -- status out
      staoctet   => sta_octet,    -- out
      stalink    => sta_link,     -- out
      cntlinkrst => cnt_linkrst,  -- out
      
      -- revolution signal
      frame      => sig_frame,    -- out
      frame9     => sig_frame9,   -- out
      cntrevoclk => revoclk,      -- out
      divclk1    => divclk1,      -- out
      divclk2    => divclk2,      -- out
      
      -- data out
      octet      => octet,        -- out
      isk        => isk,          -- out
      payload    => buf_payload (76 downto 0), -- out
      sigpayload => sig_payload,  -- out
      sigidle    => sig_idle,     -- out
      cntbit2    => cntbit2,      -- out
      cntpacket  => cnt_packet,   -- out
      
      -- debug input
      manual   => reg_imanual,
      clrdelay => clr_idelay,
      sigdelay => set_idelay,
      regslip  => reg_slip,
      decdelay => sig_decdelay,
      caldelay => sig_caldelay,
      
      -- debug output
      staslip    => sta_slip,   -- out
      bitddr     => sig_bitddr, -- out
      bit2       => sigbit2,    -- out
      bit10      => open_bit10, -- out
      cntslip    => cnt_slip,   -- out
      cntdelay   => cnt_delay,  -- out
      dbg        => dbg,        -- out
      dbg2       => sig_dbg2 ); -- out

  --- map: b2tt_encode -------------------------------------------------

  map_encode: entity work.b2tt_encode
    generic map (
      FLIPACK => FLIPACK )
    port map (
      clock    => clk_i,
      invclock => clk_inv,
      frame    => sig_frame,
      id       => id,
      myaddr   => buf_myaddr,
      b2clkup  => sta_dcm,
      b2ttup   => sta_link,
      b2plllk  => b2plllk,
      b2linkup => b2linkup,
      b2linkwe => b2linkwe,
      b2lnext  => fifonext,
      b2lclk   => b2lclk,
      runreset => sig_runreset,
      busy     => busy,
      err      => err,
      moreerrs => "00",
      tag      => sta_trgtag,
      tagerr   => sta_tagerr,
      fifoerr  => sta_fifoerr,
      fifoful  => sta_fifoful,
      seu      => sta_seu,
      cntdelay => cnt_delay,
      timerr   => sta_timerr,
      regdbg   => (others => '0'),
      
      -- to RJ-45
      ackp     => ackp,   -- out
      ackn     => ackn,   -- out
      
      -- debug output
      cntbit2  => open_cnt2,  -- out
      cntoctet => open_cnto,  -- out
      isk      => open_isk,   -- out
      octet    => open_octet, -- out
      bit2     => open_bit2,  -- out
      bitddr   => open_bitddr ); -- out

  
  -- out (async)
  bitddr   <= sig_bitddr;
  sysclk   <= clk_i;
  revo     <= sig_frame;
  revo9    <= sig_frame9;
  b2clkup  <= sta_dcm;
  b2ttup   <= sta_link;
  rsvp     <= '0';
  rsvn     <= '0';
  utime    <= sta_utime(NBITTIM-1 downto 0);
  ctime    <= sta_ctime;
  runreset <= sig_runreset;
  trgout   <= sig_trig;
  trgtyp   <= sta_trgtyp;
  trgtag   <= sta_trgtag;

  rawclk <= sig_rawclk;
  --dbg <= sig_dbg72 & sta_dcm & sig_rawclk;
  dbg2 <= cnt_linkrst & sig_bitddr & sta_slip & cnt_slip & sig_dbg2(19 downto 0);
  
end implementation;
