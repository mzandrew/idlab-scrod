------------------------------------------------------------------------
--
--- ft2u.vhd --- FTSW2 Virtex5 for user-master
---
--  This firmware includes various functions for test users, who directly
--  connect an FTSW with this firmware to their readout boards.
--
--  Mikihiko Nakao, KEK IPNS
--  20130404 0.01  new start, ft3u only (regs+ioswitch only)
--  20130407 0.02  unified ft2u+ft3u    (regs+ioswitch only)
--  20130408 0.03  id+jitterspi
--  20130408 0.04  phasedet
--  20130411 0.05  m_encode and related components
--  20130513 0.06  tt_utime
--  20130514 0.07  odelay doesn't work / o_ledg / ft3s008 / regs rearrange
--  20130610 0.08  m_decode implementation
--  20130625 0.09  cntreset/runreset/gentrig
--  20130626 0.10  dumtrig/gentrig/revo
--  20130626 0.11  utime
--  20130705 0.12  dumtrig with multi-pulse
--  20130719 0.13  migrating ft3x (encode)
--  20130727 0.14  migrating ft3x (decode)  [from ft3u]
--  20130729 0.15  register remapping
--  20130803 0.16  fix depacket
--  20130815 0.17  register remapping, busy and err checks
--  20130830 0.18  fifo data debug
--  20130906 0.19  ostatb reuse for cdcv3b2l debug
--  20130909 0.20  fifo at high rate not fully fixed, need to check empty
--  20130920 0.21  i_aux(3) for trigger input
--  20130925 0.22  autojtag / autorst / ucf(o_rsv) fix
--  20130926 0.23  m_pipeline, tlast fix, tagdone
--  20130929 0.24  unstable ttlink test
--  20131001 0.25  m_pipeline fix
--  20131002 0.26  exp/run number, begin of run, trigger type (regs rearranged)
--  20131003 0.27  feereset, baddr
--  20131004 0.28  trgdelay
--  20131005 0.29  handwait
--  20131010 0.30  more x_decode monitoring
--  20131010 0.31  tlu
--  20131014 0.32  jtag register and flipped tdo
--  20131017 0.33  baddr initial value should be 10000, tlubsy fix
--  20131020 0.34  run reset to x_encode
--  20131021 0.35  tlu busy handling
--  20131024 0.36  xbusy debug
--  20131027 0.37  slip fix, b2tt_ddr, irsv out
--  20131104 0.38  no more std_logic_arith
--  20131121 0.39  cntdelay of FEE in sig_odbg / incdelay+caldelay cmd
--  20131122 0.40  broken header debug, move tlu registers
--  20131224 0.41  tlu busy, error to stop, clkerr, linkerr debug, nopayload
--  20140102 0.42  m_decode fix for busy octet, fifo tag fix, tlast fix
--  20140103 0.43  incdelay by linkerr
--  20140106 0.44  error bit handling, O16/irsv for TLU trgin thru ttio9108
--                 tludelay
--  20140109 0.45  tluno1st, reset bits, no tlast reset
--  20140114 0.46  seq_inc at xlinkup goes to zero / clock with maskt to X
--  20140117 0.47  PXD special, no busy / error to stop trigger
--  20140403 0.48  0.46 + no autorst in m_count
--  20140407 0.49  olinkdn
--  20140412 0.50  chksum trial
--  20140415 0.51  sort out ostatus bits
--  20140417 0.52  TTCMD_RST rearrangement
--  20140505 0.53  clock to ttrx5 at o_rsv
--  20140627 0.54  chipscope
--  20140702 0.55a chipscope revised (for next release)
--  20140708 0.55b tagdiff negated (for next release)
--  20140709 0.55  crc8 for m_encode
--  20140715 0.56  stareset
--  20140718 0.57  ttrxrst (no autorst)
--  20140727 0.58  disparity control and cmd/address
--  20140728 0.59  disparity fix, O16/irsv as nominal
--  20140804 0.60  block write to jtag tdi
--  20140810 0.61  iscan for all input
--  20140810 0.62  tt_phasedet fix, more chipscope
--  20140811 0.63  crc error debug
--  20140813 0.64  tt_phasedet update, autorst revived (no ttrxrst)
--  20140903 0.65  reg_oignore, m_decode -> o_decode fix
--
------------------------------------------------------------------------

------------------------------------------------------------------------
--- entity -------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;
library work;
use work.tt_types.all;

entity ft2u is
  generic (
    VERSION       : integer   :=  65;
    B2TTVER       : integer   :=  29;
    DATE          : std_logic_vector (31 downto 0) := x"20140903";
    LCK_ENABLE    : std_logic := '1';
    TTIN_ENABLE   : std_logic := '0';
    USE_CHIPSCOPE : std_logic := '1';
    ID : std_logic_vector (31 downto 0) := x"46543255" ); -- "FT2U"

  port (
    -- FTSW2 only (dummy pin in FTSW3)
    f_led1y_b  : out   std_logic;  -- only in ft2u
    -- FTSW3 only (dummy pins in FTSW2)
    f_led1g    : out   std_logic;  -- for clock source
    f_led1y    : out   std_logic;  -- G:IN/Y:FTOR, blink if PLL unlock
    f_led2g    : out   std_logic;  -- G for ft3u
    f_led2y    : out   std_logic;  -- only in ft3u
    --c_led0     : out   std_logic;
    --c_led1     : out   std_logic;
    --f_testin   : in    std_logic;  -- for test trigger input
    --c_gpio0    : inout std_logic;

    -- local bus and local clock
    f_d        : inout std_logic_vector (31 downto 0);
    f_a        : in    std_logic_vector (15 downto 4);
    f_ads      : in    std_logic;
    f_wr       : in    std_logic;
    f_irq      : out   std_logic;  -- unused, set to L

    -- misc
    c_id1      : in    std_logic;
    c_id2      : in    std_logic;
    f_xen      : out   std_logic;
    f_ckmux    : in    std_logic_vector (1  downto 0);
    --f_testin_p : in    std_logic;
    --f_testin_n : in    std_logic;

    -- test jtag-in
    f_tck      : in    std_logic;  -- tck
    f_tms      : in    std_logic;  -- tms
    f_tdi      : in    std_logic;  -- tdi
    f_tdo      : out   std_logic;  -- tdo

    -- jitter cleaner control
    j_pd_b     : out   std_logic;
    j_plllock  : in    std_logic;
    j_spiclk   : out   std_logic;
    j_spile    : out   std_logic;
    j_spimiso  : in    std_logic;
    j_spimosi  : out   std_logic;
    j_testsync : out   std_logic;

    -- clock input
    f_ick_p    : in    std_logic;  -- for phase detection
    f_ick_n    : in    std_logic;
    f_lck_p    : in    std_logic;
    f_lck_n    : in    std_logic;
    s_jck_p    : in    std_logic;  -- main system clock
    s_jck_n    : in    std_logic;

    -- AUX (same set of pins, switch the direction by UCF pin assignment)
    o_aux_n    : out   std_logic_vector (1 downto 0);
    o_aux_p    : out   std_logic_vector (1 downto 0);
    i_aux_n    : in    std_logic_vector (3 downto 2);
    i_aux_p    : in    std_logic_vector (3 downto 2);

    -- IN
    i_trg_n    : out   std_logic;  -- opposite to nominal direction
    i_trg_p    : out   std_logic;  -- opposite to nominal direction
    i_ack_n    : in    std_logic;  -- opposite to nominal direction
    i_ack_p    : in    std_logic;  -- opposite to nominal direction
    i_rsv_n    : out   std_logic;
    i_rsv_p    : out   std_logic;

    -- OUT
    o_clk_n    : out   std_logic_vector (20 downto 1);
    o_clk_p    : out   std_logic_vector (20 downto 1);
    o_trg_n    : out   std_logic_vector (20 downto 1);
    o_trg_p    : out   std_logic_vector (20 downto 1);
    o_ack_n    : in    std_logic_vector (20 downto 1);
    o_ack_p    : in    std_logic_vector (20 downto 1);
    o_rsv_n    : out   std_logic_vector (20 downto 1);
    o_rsv_p    : out   std_logic_vector (20 downto 1);
    
    i_ledy_b   : out   std_logic;
    i_ledg_b   : out   std_logic;
    o_ledy_b   : out   std_logic_vector (20 downto 1);
    o_ledg_b   : out   std_logic_vector (20 downto 1);

    -- FMC control and I/O
    --m_rst      : out   std_logic;
    --m_scl      : out   std_logic;
    --m_sda      : out   std_logic;
    --m_prsnt    : in    std_logic;
    m_a        : out   std_logic_vector (6 downto 0);
    m_d        : inout std_logic_vector (7 downto 0);
    --m_io       : out   std_logic_vector (7 downto 0);
    m_wr       : out   std_logic;
    m_ads      : out   std_logic;
    m_lck      : out   std_logic;

    -- spartan3 control (only in FTSW3 / dummy in FTSW2)
    f_enable   : out   std_logic_vector (9 downto 0);
    f_entck    : inout std_logic_vector (9 downto 0);
    f_ftop     : out   std_logic;
    f_query    : out   std_logic;
    f_prsnt_b  : out   std_logic;

    -- ethernet
    e_rst_b       : out   std_logic;
    e_txen        : out   std_logic );

end ft2u;
--- architecture -------------------------------------------------------

architecture implementation of ft2u is

  constant FTSWVERSION : std_logic_vector (3 downto 0) := ID(11 downto 8);

  --- signal: clock ----------------------------------------------------

  signal sig_lck       : std_logic := '0';          -- 31 MHz
  signal sig_ick       : std_logic := '0';          -- 127 MHz
  signal sig_sck       : std_logic := '0';          -- 127 MHz
  signal clk_l         : std_logic := '0';
  signal clk_i         : std_logic := '0';
  signal clk_s         : std_logic := '0';
  signal cnt_l         : std_logic_vector (1 downto 0) := (others => '0');
  signal cnt_i         : std_logic_vector (1 downto 0) := (others => '0');
  signal cnt_s         : std_logic_vector (1 downto 0) := (others => '0');
  signal sig_blink     : std_logic := '0';

  signal cnt_lckfreq   : long_t    := (others => '0');
  signal buf_utim0     : std_logic := '0';

  --- signal: m_count --------------------------------------------------
  
  signal cnt_trgout    : long_t := (others => '0');
  signal sig_trgstart  : std_logic := '0';
  
  --- signal: id -------------------------------------------------------

  signal seq_id        : std_logic16 := (others => '0');
  
  --- signal: phasedet -------------------------------------------------
  
  signal sig_pd        : std_logic := '0';
  
  --- signal: utime ----------------------------------------------------

  --signal sta_utset     : std_logic   := '0';
  signal sta_utime     : long_t      := (others => '0');
  signal sta_ctime     : std_logic27 := (others => '0');

  --- signal: jtag -----------------------------------------------------

  signal sig_tdi : std_logic := '0';
  signal sig_tck : std_logic := '0';
  signal sig_tms : std_logic := '0';
  
  --- signal: x_encode -------------------------------------------------

  signal sig_xbit2   : std_logic2 := "00";
  signal sig_xsub2   : std_logic2 := "00";
  signal sig_xdum2   : std_logic2 := "00";

  --- signal: m_encode -------------------------------------------------

  signal sig_trgin   : std_logic := '0';
  --signal sig_bit2    : std_logic2 := "00";
  --signal sig_sub2    : std_logic2 := "00";
  signal sig_revo    : std_logic := '0';
  signal sig_frame   : std_logic := '0';
  signal sta_frame3  : std_logic := '0';
  signal sta_frame9  : std_logic := '0';
  signal sta_ctimer  : std_logic27 := (others => '0');
  signal sta_utimer  : long_t      := (others => '0');
  signal cnt_clk     : std_logic11 := (others => '0');
  
  --- signal: m_collect ------------------------------------------------

  signal sig_oackp     : std_logic8 := (others => '0');
  signal sig_oackn     : std_logic8 := (others => '0');
  signal sig_xackp     : std_logic4 := (others => '0');
  signal sig_xackn     : std_logic4 := (others => '0');
  signal sig_runreset  : std_logic := '0';
  signal sta_runreset  : std_logic := '0';
  signal sig_errreset  : std_logic := '0';
  signal sta_tagdone   : byte_vector (7 downto 0) := (others => x"00");

  signal sta_omask     : std_logic_vector (7 downto 0) := x"00";
  
  --- signal: m_gentrig ------------------------------------------------

  signal sig_trig    : std_logic  := '0';
  signal sig_trgtyp  : std_logic4 := "1111"; -- TTYP_NONE
  --signal sig_trgraw1 : std_logic  := '0';
  signal sig_trgsrc1 : std_logic  := '0';
  signal sig_trgsrc2 : std_logic  := '0';
  signal sig_dumtrg  : std_logic  := '0';
  signal sig_idbg : std_logic_vector (3 downto 0) := (others => '0');
  signal sig_oaux : std_logic_vector (1 downto 0) := (others => '0');
  signal sig_iaux : std_logic_vector (3 downto 2) := (others => '0');
  
  --- signal: tt_tlu ---------------------------------------------------

  signal sig_tluin     : std_logic_vector (1 downto 0) := "00";
  signal sig_tluout    : std_logic_vector (3 downto 2) := "00";

  --- signal: tt_dump --------------------------------------------------
  signal sig_dump2 : std_logic2_vector (15 downto 0) := (others => "00");
  signal cnt_dump2 : std_logic3_vector (15 downto 0) := (others => "000");
  signal sig_dumpo : byte_vector       (15 downto 0) := (others => x"00");
  signal sig_dumpk : std_logic_vector  (15 downto 0) := (others => '0');
  signal cnt_dumpo : std_logic5_vector (15 downto 0) := (others => "00000");
  signal sig_dump  : std_logic   := '0';
  
  --- signal: unused for poor simulator --------------------------------

  signal open_dbg : long_vector (6 downto 0) := (others => x"00000000");
  
  --- signal: for chipscope --------------------------------------------
  signal sig_ilacontrol : std_logic_vector (35 downto 0) := (others => '0');
  signal sig_ilam       : std_logic_vector (95 downto 0) := (others => '0');
  signal sig_ilau       : std_logic_vector (95 downto 0) := (others => '0');
  signal sig_ila        : std_logic_vector (95 downto 0) := (others => '0');
  signal sig_bitrd      : std_logic;
  signal sig_subrd      : std_logic;

  
  --- signal: registers ------------------------------------------------

  -- constants
  constant MAX_REG : integer := 16#9F#;
  constant MIN_REG : integer := 16#10#;
  constant XVERSION : long_t := std_logic_vector(to_unsigned(VERSION, 32));
  constant INI_REG : long_vector (255 downto 0) := (
    16#10# => ID,
    16#13# => x"07952980", -- clkfreq 127216000
    ---  30*(14+517*2^13)+1 (x"1e5" x"d") = 1.0012 Hz pulse trigger
    16#1a# => x"00000100", -- AUTOJTAG
    16#20# => x"c0000000", -- NOFIFO (TTRXRST or AUTORST is enabled)
    16#28# => x"000205d1", -- trgset
    16#29# => x"ffffffff", -- tlimit
    16#50# => x"0c00b000", -- maxtrig=12 / latency=45056(351us)
    16#9c# => x"00000800", -- dump
    16#9f# => x"00000f21", -- selila / irsvsel / itrgsel
    others => x"00000000" );
  constant CLR_REG : long_vector (255 downto 0) := (
    16#1a# => x"00008800", -- SETTCK, SETBLK
    16#20# => x"0000ff3b", -- CNTRESET, RUNSTOP, RUNSTART, RUNRESET
    16#7c# => x"0000ffff", -- DELAY
    16#7d# => x"000000ff", -- XDELAY
   others => x"00000000" );
  constant RW_REG : std_logic_vector (255 downto 0) := (
    16#10# => '1', -- ID
    16#12# => '1', -- UTIME
    16#13# => '1', -- CLKFREQ
    16#16# => '1', -- RUNEXP
    16#18# => '1', -- OMASK
    16#1a# => '1', -- JTAG
    16#1c# => '1', -- JREG
    16#1e# => '1', -- JCTRL
    16#20# => '1', -- RESET
    16#28# => '1', -- TRGSET
    16#29# => '1', -- TLIMIT
    16#31# => '1', -- REVOPOS
    16#34# => '1', -- BADDR
    16#50# => '1', -- MAXTRIG/LATENCY
    16#7c# => '1', -- MANUAL
    16#7d# => '1', -- XMANUAL
    16#9c# => '1', -- DUMP
    16#9f# => '1', -- ITRGSEL

    others => '0' );
  
  -- signals
  signal set_reg : std_logic_vector (MAX_REG downto MIN_REG)
                                                          := (others => '0');
  signal get_reg : std_logic_vector (MAX_REG downto MIN_REG)
                                                          := (others => '0');
  signal buf_reg : long_vector (MAX_REG downto MIN_REG)
                                                  := (others => x"00000000");
  signal sta_reg : long_vector (MAX_REG downto MIN_REG) := (
    16#11# => XVERSION,
    others => x"00000000" );

  signal sig_din  : long_t := (others => '0');
  signal sig_dout : long_t := (others => '0');
  
  --- registers: id
  alias  sta_id        : std_logic16 is sta_reg(16#11#)(31 downto 16);

  --- registers: timestamps (#120 to #150)
  alias  set_utime     : std_logic   is set_reg(16#12#);
  alias  reg_utime     : long_t      is buf_reg(16#12#);
  alias  reg_query     : std_logic   is buf_reg(16#13#)(31);
  alias  reg_clkfreq   : std_logic24 is buf_reg(16#13#)(23 downto 0);
  alias  sig_snapshot  : std_logic   is set_reg(16#14#);
  alias  buf_utime     : long_t      is sta_reg(16#14#);
  alias  buf_ctime     : std_logic27 is sta_reg(16#15#)(26 downto 0);
  alias  sta_frozen    : std_logic   is sta_reg(16#15#)(31);
  
  --- registers: run (#160)
  alias  reg_exprun    : long_t      is buf_reg(16#16#);
  
  --- registers: FT-switch control (#180 to #190)
  alias  reg_oignore   : std_logic   is buf_reg(16#18#)(31);
  alias  reg_selcpr    : std_logic3  is buf_reg(16#18#)(30 downto 28);
  alias  reg_clkmask   : std_logic8  is buf_reg(16#18#)(23 downto 16);
  alias  reg_xmask     : std_logic4  is buf_reg(16#18#)(15 downto 12);
  alias  reg_omask     : std_logic8  is buf_reg(16#18#)(7  downto 0);

  alias  sta_link      : std_logic8  is sta_reg(16#19#)(7  downto 0);
  alias  sta_s3        : std_logic10 is sta_reg(16#19#)(25 downto 16);

  --- registers: JTAG (#1a0 to #1b0)
  alias  reg_tdiblk    : std_logic8  is buf_reg(16#1a#)(31  downto 24);
  alias  reg_fliptdo   : std_logic8  is buf_reg(16#1a#)(23  downto 16);
  alias  set_tck       : std_logic   is buf_reg(16#1a#)(15);
  alias  reg_tck       : std_logic   is buf_reg(16#1a#)(14);
  alias  reg_tms       : std_logic   is buf_reg(16#1a#)(13);
  alias  reg_tdi       : std_logic   is buf_reg(16#1a#)(12);
  alias  set_tdiblk    : std_logic   is buf_reg(16#1a#)(11);
  alias  reg_seljtag   : std_logic   is buf_reg(16#1a#)(9);
  alias  reg_autojtag  : std_logic   is buf_reg(16#1a#)(8);
  alias  reg_enjtag    : std_logic8  is buf_reg(16#1a#)(7  downto 0);
  -- 16#1b# for FTSWREG_JTDO

  alias  sig_tdo       : std_logic   is sta_reg(16#1b#)(0);
  alias  sta_jtagerr   : std_logic5  is sta_reg(16#1b#)(7  downto 3);
  
  --- registers: jitterspi (#1c0 to #1f0)
  alias  reg_jspi      : long_t      is buf_reg(16#1c#);
  alias  set_jspi      : std_logic   is set_reg(16#1c#);
  alias  sta_jspi      : long_t      is sta_reg(16#1d#);
  alias  reg_pd        : std_logic   is buf_reg(16#1e#)(31);
  alias  reg_jreset    : std_logic   is buf_reg(16#1e#)(1);
  alias  reg_jphase    : std_logic   is buf_reg(16#1e#)(0);
  alias  sta_jpll      : std_logic   is sta_reg(16#1f#)(31);
  alias  sta_jdcm      : std_logic   is sta_reg(16#1f#)(30);
  alias  sta_ckmux     : std_logic2  is sta_reg(16#1f#)(29 downto 28);
  alias  sta_jphase    : std_logic4  is sta_reg(16#1f#)(27 downto 24);
  alias  sta_jretry    : std_logic8  is sta_reg(16#1f#)(23 downto 16);
  alias  sta_jcount    : std_logic16 is sta_reg(16#1f#)(15 downto 0);

  --- registers: reset (#200 to #260)  -- (*) for short pulse
  alias  reg_nofifo    : std_logic   is buf_reg(16#20#)(31);
  --alias  reg_ttrxrst   : std_logic   is buf_reg(16#20#)(30);
  alias  reg_autorst   : std_logic   is buf_reg(16#20#)(30);
  alias  reg_notagerr  : std_logic   is buf_reg(16#20#)(29);
  alias  reg_selreset  : std_logic   is buf_reg(16#20#)(28);
  alias  reg_tluno1st  : std_logic   is buf_reg(16#20#)(27);
  alias  reg_tludelay  : std_logic2  is buf_reg(16#20#)(26 downto 25);
  alias  reg_usetlu    : std_logic   is buf_reg(16#20#)(24);
  alias  reg_ebup      : std_logic   is buf_reg(16#20#)(23);
  alias  reg_paused    : std_logic   is buf_reg(16#20#)(21);
  alias  reg_running   : std_logic   is buf_reg(16#20#)(20);
  alias  reg_busy      : std_logic   is buf_reg(16#20#)(16);
  alias  clr_ictrl     : std_logic   is buf_reg(16#20#)(15); -- 8000 (*)
  alias  set_incdelay  : std_logic   is buf_reg(16#20#)(14); -- 4000 (*)
  alias  set_caldelay  : std_logic   is buf_reg(16#20#)(13); -- 2000 (*)
  alias  set_addr      : std_logic   is buf_reg(16#20#)(12); -- 1000 (*)
  alias  set_stareset  : std_logic   is buf_reg(16#20#)(11); --  800 (*)
  alias  set_gtpreset  : std_logic   is buf_reg(16#20#)(10); --  400 (*)
  alias  set_feereset  : std_logic   is buf_reg(16#20#)(9);  --  200 (*)
  alias  set_b2lreset  : std_logic   is buf_reg(16#20#)(8);  --  100 (*)
  alias  set_errreset  : std_logic   is buf_reg(16#20#)(5);  --   20 (*)
  alias  set_cntreset  : std_logic   is buf_reg(16#20#)(4);  --   10 (*)
  alias  set_trgstop   : std_logic   is buf_reg(16#20#)(3);  --    8 (*)
  alias  reg_genbor    : std_logic   is buf_reg(16#20#)(2);  --    4
  alias  set_trgstart  : std_logic   is buf_reg(16#20#)(1);  --    2 (*)
  alias  set_runreset  : std_logic   is buf_reg(16#20#)(0);  --    1 (*)
  
  alias  sta_rstutim   : long_t      is sta_reg(16#21#);
  alias  sta_rstctim   : std_logic27 is sta_reg(16#22#)(26 downto 0);
  alias  sta_rstsrc    : std_logic3  is sta_reg(16#22#)(30 downto 28);
  alias  sta_errutim   : long_t      is sta_reg(16#23#);
  alias  sta_errctim   : std_logic27 is sta_reg(16#24#)(26 downto 0);
  alias  sta_errport   : std_logic12 is sta_reg(16#25#)(11 downto 0);
  alias  sta_errbit    : std_logic16 is sta_reg(16#25#)(31 downto 16);

  --- registers: trigger (#280 to #2e0)
  alias  set_rateval   : std_logic   is set_reg(16#28#);
  alias  reg_trgopt    : std_logic12 is buf_reg(16#28#)(31 downto 20);
  alias  reg_rateval   : std_logic10 is buf_reg(16#28#)(17 downto 8);
  alias  reg_rateexp   : std_logic4  is buf_reg(16#28#)(7  downto 4);
  alias  reg_notrgclr  : std_logic   is buf_reg(16#28#)(3);
  alias  reg_seltrg    : std_logic3  is buf_reg(16#28#)(2  downto 0);
  alias  reg_trglimit  : long_t      is buf_reg(16#29#);
  alias  cnt_trgin     : long_t      is sta_reg(16#2a#);
  alias  cnt_trgoutl   : long_t      is sta_reg(16#2b#);
  alias  cnt_trglast   : long_t      is sta_reg(16#2c#);
  alias  sta_fifoful   : std_logic   is sta_reg(16#2d#)(31);
  alias  sta_fifoorun  : std_logic   is sta_reg(16#2d#)(30);
  alias  sta_fifoemp   : std_logic   is sta_reg(16#2d#)(28);
  alias  sta_fifoahi   : std_logic2  is sta_reg(16#2d#)(25 downto 24);
  alias  sta_trgen     : std_logic   is sta_reg(16#2d#)(0);
  alias  sig_fiford    : std_logic   is get_reg(16#2e#);
  alias  buf_fifo      : long_t      is sta_reg(16#2e#);

  --- registers: encode (#300 to #350)
  alias  cnt_payload   : std_logic4  is sta_reg(16#30#)(3  downto 0);
  alias  cnt_bit2      : std_logic3  is sta_reg(16#30#)(6  downto 4);
  -----  sta_octet     : byte_t      is sta_reg(16#30#)(15 downto 8);
  -----  sta_isk       : std_logic   is sta_reg(16#30#)(16);
  -----  sta_comma     : std_logic   is sta_reg(16#30#)(17);
  -----  sta_bit2      : std_logic2  is sta_reg(16#30#)(21 downto 20);
  alias  cnt_octet     : std_logic4  is sta_reg(16#30#)(27 downto 24);
  alias  set_revopos   : std_logic   is set_reg(16#31#);
  alias  reg_revopos   : std_logic11 is buf_reg(16#31#)(10 downto 0);
  alias  cnt_revocand  : std_logic16 is sta_reg(16#32#)(31 downto 16);
  alias  sta_revocand  : std_logic11 is sta_reg(16#32#)(10 downto 0);
  alias  cnt_badrevo   : std_logic16 is sta_reg(16#33#)(31 downto 16);
  alias  cnt_norevo    : std_logic16 is sta_reg(16#33#)(15 downto 0);
  alias  reg_cmdaddr   : std_logic20 is buf_reg(16#34#)(31 downto 12);
  alias  reg_cmdhi     : std_logic12 is buf_reg(16#34#)(11 downto 0);
  alias  reg_cmdlo     : long_t      is buf_reg(16#35#);
  alias  set_cmd       : std_logic   is set_reg(16#35#);
  -- 16#36# is not used yet
  alias  sta_lckfreq   : long_t is sta_reg(16#37#);
  
  --- registers: decode (#380 to #4f0)
  alias  sta_fifoerr   : std_logic   is sta_reg(16#38#)(31);
  alias  sta_pipebusy  : std_logic   is sta_reg(16#38#)(30);
  alias  sig_busy      : std_logic   is sta_reg(16#38#)(29);
  alias  sta_busy      : std_logic   is sta_reg(16#38#)(28);
  alias  sta_xbusy     : std_logic4  is sta_reg(16#38#)(23 downto 20);
  alias  sta_obusy     : std_logic8  is sta_reg(16#38#)(19 downto 12);
  alias  sig_xbusy     : std_logic4  is sta_reg(16#38#)(11 downto  8);
  alias  sig_obusy     : std_logic8  is sta_reg(16#38#)(7  downto  0);

  -- no place for sta_xlinkdn yet
  alias  sta_olinkdn   : std_logic8  is sta_reg(16#39#)(31 downto 24);
  alias  sta_xalive    : std_logic4  is sta_reg(16#39#)(23 downto 20);
  alias  sta_oalive    : std_logic8  is sta_reg(16#39#)(19 downto 12);
  alias  sta_xlinkup   : std_logic4  is sta_reg(16#39#)(11 downto  8);
  alias  sta_olinkup   : std_logic8  is sta_reg(16#39#)(7  downto  0);

  alias  sta_b2ldn     : std_logic8  is sta_reg(16#3a#)(31 downto 24);
  alias  sta_plldn     : std_logic8  is sta_reg(16#3a#)(23 downto 16);
  alias  sta_err       : std_logic   is sta_reg(16#3a#)(15);
  alias  sig_errin     : std_logic   is sta_reg(16#3a#)(14);
  alias  sta_clkerr    : std_logic   is sta_reg(16#3a#)(13);
  alias  sta_trigshort : std_logic   is sta_reg(16#3a#)(12);
  alias  sta_xerr      : std_logic4  is sta_reg(16#3a#)(11 downto  8);
  alias  sta_oerr      : std_logic8  is sta_reg(16#3a#)(7  downto  0);
  
  alias  sig_b2lup     : std_logic8  is sta_reg(16#3b#)(31 downto 24);
  alias  sig_plllk     : std_logic8  is sta_reg(16#3b#)(23 downto 16);
  alias  sta_linkerr   : std_logic   is sta_reg(16#3b#)(15);
  alias  sig_b2lor     : std_logic   is sta_reg(16#3b#)(14);
  alias  sta_ictrl     : std_logic2  is sta_reg(16#3b#)(13 downto 12);

  alias  sta_odatab    : long_vector (15 downto 0)
                                     is sta_reg(16#4b# downto 16#3c#);
  alias  sta_xdata     : long_vector (4 downto 1)
                                     is sta_reg(16#4f# downto 16#4c#);

  -- registers: trigger flow control and dead time
  alias  reg_maxtrig   : byte_t      is buf_reg(16#50#)(31 downto 24);
  alias  reg_latency   : std_logic18 is buf_reg(16#50#)(17 downto 0);
  
  -- 16#51# to 16#59# for individual control (not for ft2u)
  -- ft2u uses this range for TLU c ontrol
  --- registers: tlu (#520)
  alias  sta_tlumon    : std_logic4  is sta_reg(16#52#)(31 downto 28);
  alias  sta_tlubsy    : std_logic   is sta_reg(16#52#)(27);
  alias  sta_nontlu    : std_logic   is sta_reg(16#52#)(26);
  alias  sig_tlutrg    : std_logic   is sta_reg(16#52#)(25);
  alias  sig_tlurst    : std_logic   is sta_reg(16#52#)(24);
  alias  cnt_tlurst    : byte_t      is sta_reg(16#52#)(23 downto 16);
  alias  sta_tlutag    : word_t      is sta_reg(16#52#)(15 downto 0);
  alias  sta_tluutim   : long_t      is sta_reg(16#53#);
  alias  sta_tluctim   : std_logic27 is sta_reg(16#54#)(26 downto 0);
  
  alias  sta_udead     : long_t      is sta_reg(16#5a#);
  alias  sta_cdead     : std_logic27 is sta_reg(16#5b#)(26 downto 0);
  alias  sta_pdead     : long_t      is sta_reg(16#5c#); -- pipeline
  alias  sta_edead     : long_t      is sta_reg(16#5d#); -- error
  alias  sta_fdead     : long_t      is sta_reg(16#5e#); -- fifoful
  alias  sta_rdead     : long_t      is sta_reg(16#5f#); -- regbusy
  -- 16#5e# to 16#5f# not used yet
  alias  sta_odead     : long_vector (7 downto 0)
                                     is sta_reg(16#67# downto 16#60#);
  alias  sta_xdead     : long_vector (4 downto 1)
                                     is sta_reg(16#6b# downto 16#68#);
  alias  sig_xbcnt : long_vector (3 downto 0) is sta_reg(16#6f# downto 16#6c#);

  -- registers: line monitoring and control
  alias  sta_odatc : long_vector (7 downto 0) is sta_reg(16#77# downto 16#70#);
  alias  sta_xdatb : long_vector (3 downto 0) is sta_reg(16#7b# downto 16#78#);

  alias  reg_omanual   : byte_t      is buf_reg(16#7c#)(31 downto 24);
  alias  reg_oregslip  : byte_t      is buf_reg(16#7c#)(23 downto 16);
  alias  reg_oclrdelay : byte_t      is buf_reg(16#7c#)(15 downto  8);
  alias  reg_oincdelay : byte_t      is buf_reg(16#7c#)(7  downto  0);
  
  alias  reg_xmanual   : std_logic4  is buf_reg(16#7d#)(15 downto 12);
  alias  reg_xclrdelay : std_logic4  is buf_reg(16#7d#)(7  downto  4);
  alias  reg_xincdelay : std_logic4  is buf_reg(16#7d#)(3  downto  0);

  -- more debug info
  alias  sta_dbg       : long_t      is sta_reg(16#7e#);
  alias  sta_dbg2      : long_t      is sta_reg(16#7f#);
  
  --- registers: dump (#800 to #990)
  alias  buf_dump8 : long_vector (7 downto 0) is sta_reg(16#87# downto 16#80#);
  alias  buf_dumpk     : long_t      is sta_reg(16#88#);
  alias  set_dump      : std_logic   is set_reg(16#89#);
  alias  buf_dumpi     : long_t      is sta_reg(16#89#);

  alias  cnt_packet    : std_logic4  is sta_reg(16#8a#)(31 downto 28);
  alias  sig_bit2      : std_logic2  is sta_reg(16#8a#)(27 downto 26);
  alias  sig_sub2      : std_logic2  is sta_reg(16#8a#)(25 downto 24);
  alias  sta_disp      : std_logic8  is sta_reg(16#8a#)(23 downto 16);
    
  alias  sig_xackq     : std_logic4  is sta_reg(16#8a#)(11 downto  8);
  alias  sig_oackq     : std_logic8  is sta_reg(16#8a#)(7  downto  0);

  alias  buf_dump2 : long_vector (9 downto 0) is sta_reg(16#99# downto 16#90#);

  alias  reg_disp      : std_logic8  is buf_reg(16#9c#)(31 downto 24);
  alias  reg_autodump  : std_logic   is buf_reg(16#9c#)(11);
  alias  reg_dumpwait  : std_logic7  is buf_reg(16#9c#)(10 downto 4);
  alias  reg_idump     : std_logic4  is buf_reg(16#9c#)(3 downto 0);

  alias  buf_crc8      : std_logic24 is sta_reg(16#9d#)(31 downto 8);
  
  alias  sta_busysrc   : std_logic6  is sta_reg(16#9e#)(9 downto 4);
  alias  sta_errsrc    : std_logic4  is sta_reg(16#9e#)(3 downto 0);

  alias  sta_utset     : std_logic   is sta_reg(16#9e#)(12);
  alias  sta_rxrst     : std_logic   is sta_reg(16#9e#)(13);
  alias  sig_trgraw1   : std_logic   is sta_reg(16#9e#)(14);
  --alias  sig_ttrxrst   : std_logic   is sta_reg(16#9e#)(15);
  alias  sig_autorst   : std_logic   is sta_reg(16#9e#)(15);
  alias  cnt_rxrst     : std_logic4  is sta_reg(16#9e#)(19 downto 16);
  alias  cnt_errst     : std_logic4  is sta_reg(16#9e#)(23 downto 20);
  signal seq_rxrst     : std_logic2  := "00";
  signal seq_errst     : std_logic2  := "00";
  
  alias  reg_itrgsel   : std_logic2  is buf_reg(16#9f#)(1  downto  0);
  alias  reg_irsvsel   : std_logic2  is buf_reg(16#9f#)(5  downto  4);
  alias  reg_selila    : std_logic4  is buf_reg(16#9f#)(11 downto  8);
  alias  reg_trgdelay  : word_t      is buf_reg(16#9f#)(31 downto 16);

  signal cnt_pay : std_logic4;
  signal cnt_sub : std_logic4;
begin

  --- map: fixed-output and redirections -------------------------------

  e_rst_b   <= '0';   -- dummy in FTSW2
  e_txen    <= '0';   -- dummy in FTSW2
  f_prsnt_b <= '0';   -- dummy in FTSW2
  f_ftop    <= '0';   -- dummy in FTSW2
  f_irq     <= '0';
  f_xen     <= LCK_ENABLE;
  f_enable  <= (not reg_clkmask) & "11";
  f_entck   <= (others => 'Z') when reg_query    = '1' else
               "1111111100"    when reg_autojtag = '1' else
               reg_enjtag & "00";
  sta_s3    <= f_entck when reg_query = '1' else (others => '0');
  f_query   <= reg_query;

  j_pd_b    <= not (reg_pd or (sig_pd and (not reg_jphase)));

  sta_ckmux <= f_ckmux;
  sta_jpll  <= j_plllock;
  sig_dump2(12) <= sig_bit2;
  --sta_mprsnt <= m_prsnt;

  m_lck     <= sig_lck;

  --sig_runreset <= set_runreset or sig_ttrxrst;
  sig_runreset <= set_runreset or sig_autorst;
  sig_errreset <= sig_runreset or set_errreset;
  
  --- map: clock-buffer ------------------------------------------------

  map_lck: ibufds port map ( o => sig_lck, i => f_lck_p, ib => f_lck_n );
  map_ick: ibufds port map ( o => sig_ick, i => f_ick_p, ib => f_ick_n );
  map_sck: ibufds port map ( o => sig_sck, i => s_jck_p, ib => s_jck_n );
  map_lg:   bufg  port map ( i => sig_lck, o => clk_l );  -- 31MHz
  map_ig:   bufg  port map ( i => sig_ick, o => clk_i );  -- 127MHz
  map_sg:   bufg  port map ( i => sig_sck, o => clk_s );  -- 127MHz

  --- map: utime -------------------------------------------------------

  map_utime: entity work.tt_utime
    port map (
      clock   => clk_s,
      cntclk  => cnt_clk,
      set     => set_utime,
      val     => reg_utime,
      clkfreq => reg_clkfreq,
      utset   => sta_utset,    -- out
      utime   => sta_utime,    -- out
      ctime   => sta_ctime,    -- out
      utimer  => sta_utimer,   -- out
      ctimer  => sta_ctimer ); -- out
  
  --- map: count -------------------------------------------------------

  map_count: entity work.m_count
    port map (
      clock    => clk_s,
      cntreset => set_cntreset,
      runreset => sta_runreset,
      snapshot => sig_snapshot,
      utime    => sta_utime,
      ctime    => sta_ctime,
      clkfreq  => reg_clkfreq,
      trgin    => sig_trgin,
      trgout   => sig_trig,
      busy     => sig_busy,
      pipebusy => sta_pipebusy,
      err      => '0',
      fifoful  => sta_fifoful,
      regbusy  => reg_busy,
      obusy    => sta_obusy,
      xbusy    => sta_xbusy,
      
      frozen   => sta_frozen,  -- out
      cntutime => buf_utime,   -- out (31 downto 0)
      cntctime => buf_ctime,   -- out (26 downto 0)
      cntudead => sta_udead,   -- out (31 downto 0)
      cntcdead => sta_cdead,   -- out (26 downto 0)

      cntpdead => sta_pdead, -- pipeline       -- out (31 downto 0)
      cntedead => sta_edead, -- fatal error    -- out (31 downto 0)
      cntfdead => sta_fdead, -- fifo full      -- out (31 downto 0)
      cntrdead => sta_rdead, -- busy register  -- out (31 downto 0)

      cntodead => sta_odead,    -- out (long 7 downto 0)
      cntxdead => sta_xdead,    -- out (long 4 downto 1)

      cnttrgi  => cnt_trgin,    -- out (31 downto 0)
      cnttrgol => cnt_trgoutl,  -- out (31 downto 0)
      cnttrgo  => cnt_trgout,   -- out (31 downto 0)
      rstutime => sta_rstutim,  -- out (31 downto 0)
      rstctime => sta_rstctim,  -- out (26 downto 0)
      rstsrc   => sta_rstsrc ); -- out (2  downto 0)

  --- map: fifo --------------------------------------------------------

  map_fifo: entity work.m_fifo
    port map (
      clock  => clk_s,
      clr    => sta_runreset,
      wra    => sig_trig,
      trgtyp => sig_trgtyp,
      utime  => sta_utime,
      ctime  => sta_ctime,
      trgcnt => cnt_trgout,
      tlutag => sta_tlutag,
      rdb    => sig_fiford,
      doutb  => buf_fifo,     -- out (31 downto 0)
      nofifo => reg_nofifo,
      err    => sta_fifoerr,  -- out
      empty  => sta_fifoemp,  -- out
      ahib   => sta_fifoahi,  -- out (1  downto 0)
      orun   => sta_fifoorun, -- out
      full   => sta_fifoful,  -- out
      dbg    => open_dbg(0) ); -- out (31 downto 0)
  
  --- map: blink -------------------------------------------------------

  map_blink: entity work.tt_blink
    generic map ( CYCLE => 31804000, NBIT => 25 )
    port map ( clock => clk_s, blink => sig_blink );

  proc_lfreq: process (clk_l)
  begin
    if clk_l'event and clk_l = '1' then
      if buf_utim0 /= sta_utime(0) then
        sta_lckfreq <= cnt_lckfreq;
        cnt_lckfreq <= (others => '0');
      else
        cnt_lckfreq <= cnt_lckfreq + 1;
      end if;
      buf_utim0 <= sta_utime(0);
    end if; -- event
  end process;
  
  --- map: clock-led ---------------------------------------------------

  i_ledy_b <= not sta_busy;
  --i_ledy_b <= not LCK_ENABLE;
  i_ledg_b <= '0'       when (sta_jpll and sta_jdcm) = '1' else
              sig_blink when (sta_jpll xor sta_jdcm) = '1' else
              '1';

  -- ft2u
  f_led1y_b <= sig_blink      when sta_jpll = '0' else
               '0'            when f_ckmux = "00" else  -- 0(in)
               '1';                                     -- 1(xtal)/2(fmc)
  -- ft3u
  f_led1y  <= sig_blink       when sta_jpll = '0' else
              '1'             when f_ckmux = "00"  else  -- 0(in)/1(xtal)
              '0';
  f_led1g  <= (not sig_blink) when j_plllock = '0' else
              '1'             when f_ckmux = "10"  else  -- 2(fmc)/3(pin)
              '0';
  f_led2g  <= '1';   -- n/a in FT2U, GREEN for FT3U
  f_led2y  <= '0';   -- n/a in FT2U

  gen_xled: for i in 1 to 4 generate
    o_ledy_b(i) <= '1'       when sta_xlinkup(i-1) = '0' else
                   sig_blink when sta_xerr(i-1)    = '1' else
                   '0'       when sta_xbusy(i-1)   = '1' else
                   '1';
    o_ledg_b(i) <= '0'       when sta_xlinkup(i-1) = '1' else
                   sig_blink when sta_xalive(i-1)  = '1' else
                   '1';
  end generate;
  gen_oled: for i in 0 to 7 generate
    o_ledy_b(i*2+5) <= '1'       when sta_olinkup(i) = '0' else
                       sig_blink when sta_oerr(i)    = '1' else
                       '0'       when sta_obusy(i)   = '1' else
                       '1';
    o_ledg_b(i*2+5) <= '0'       when sta_olinkup(i) = '1' else
                       sig_blink when sta_oalive(i)  = '1' else
                       '1';
  end generate;

  o_ledy_b(6) <= not sta_trgen;
  --o_ledg_b(6) <= not reg_ttrxrst;
  o_ledg_b(6) <= not reg_autorst;
  o_ledy_b(8) <= not reg_autojtag;
  o_ledg_b(8) <= '1';
  o_ledy_b(10) <= not cnt_trgin(0);
  o_ledg_b(10) <= not cnt_trgin(1);
  o_ledy_b(12) <= not cnt_trgout(0);
  o_ledg_b(12) <= not cnt_trgout(1);

  gen_oled2: for i in 4 to 7 generate
    o_ledy_b(i*2+6) <= '1';
    o_ledg_b(i*2+6) <= '1';
  end generate;
  
  --- map: registers ---------------------------------------------------

  map_regs: entity work.tt_regs
    generic map (
      MIN_REG => MIN_REG, MAX_REG => MAX_REG,
      RW  => RW_REG, CLR => CLR_REG, INI => INI_REG)
    port map (
      clock => clk_l,
      din => sig_din, dout => sig_dout, adr => f_a, ads => f_ads, wr => f_wr,
      reg => buf_reg, sta => sta_reg, set => set_reg, get => get_reg );

  --- map: jtag --------------------------------------------------------

  f_tdo <= sig_tdo;

  map_jtag: entity work.m_jtag
    port map (
    clock    => clk_s,
    seljtag  => reg_seljtag,
    pintck   => f_tck,
    pintms   => f_tms,
    pintdi   => f_tdi,
    settck   => set_tck,
    regtck   => reg_tck,
    regtdi   => reg_tdi,
    regtms   => reg_tms,
    tdiblk   => reg_tdiblk,
    setblk   => set_tdiblk,
    sigtck   => sig_tck,   -- out
    sigtms   => sig_tms,   -- out
    sigtdi   => sig_tdi,   -- out
    err      => sta_jtagerr ); -- out
  
  --- map: ioswitch ----------------------------------------------------

  map_io: entity work.tt_ioswitch
    port map (
      clock => clk_l, d => f_d, a => f_a, ads => f_ads, wr => f_wr,
      regin => sig_din, regout => sig_dout,
      fmca => m_a, fmcd => m_d, fmcads => m_ads, fmcwr => m_wr );

  --- proc: id ---------------------------------------------------------
  
  proc_id: process (clk_l)
  begin
    if clk_l'event and clk_l = '1' then
      seq_id <= c_id1 & seq_id(15 downto 1);
      if c_id2 = '1' then
        sta_id <= seq_id;
      end if;
    end if;
  end process;

  --- map: jitterspi ---------------------------------------------------
  
  map_jc: entity work.tt_jitterspi
    port map (
      clock   => clk_l,
      reg     => reg_jspi,
      set     => set_jspi,
      spimiso => j_spimiso,             -- in
      spimosi => j_spimosi,             -- out
      spiclk  => j_spiclk,              -- out
      spile   => j_spile,               -- out
      status  => sta_jspi );            -- out (31 downto 0)
  
  --- map: clock-phasedet ----------------------------------------------
  -- UPON WRONG PHASE DETECTION, PLL SHOULD BE RESET -------------------
  
  map_phasedet: entity work.tt_phasedet
    port map (
      lclk   => clk_l,
      sclk   => clk_s,
      iclk   => clk_i,
      jpll   => j_plllock,
      reset  => reg_jreset,
      clkset => set_utime,
      clkerr => sta_clkerr,   -- out
      sigpd  => sig_pd,       -- out
      count  => sta_jcount,   -- out (15 downto 0)
      nretry => sta_jretry,   -- out (7  downto 0)
      dcm    => sta_jdcm,     -- out
      phase  => sta_jphase ); -- out (3  downto 0)
  
  --- map: clock-ictrl -------------------------------------------------
  
  map_ictrl: entity work.tt_idelayctrl
    port map (
      clock => clk_s,
      reset => clr_ictrl,
      stat  => sta_ictrl );  -- out

  --- map: oclk (FTSW2 only) -------------------------------------------

  map_oclk: entity work.tt_oclk
    port map (
      clock    => sig_sck,
      clk_p    => o_clk_p,   -- out
      clk_n    => o_clk_n,   -- out
      xmask    => "0000", -- do not stop clock
      omask    => reg_clkmask,
      xorclk   => "00000000",
      autojtag => reg_autojtag,
      enjtag   => reg_enjtag,
      tck      => sig_tck );
  
  --- map: oack --------------------------------------------------------

  map_oack: entity work.tt_oack
    port map (
      ack_p    => o_ack_p,
      ack_n    => o_ack_n,
      autojtag => reg_autojtag,
      enjtag   => reg_enjtag,
      fliptdo  => reg_fliptdo,
      xackp    => sig_xackp,  -- out
      xackn    => sig_xackn,  -- out
      oackp    => sig_oackp,  -- out
      oackn    => sig_oackn,  -- out
      tdo      => sig_tdo ); -- out
  
  --- map: orsv --------------------------------------------------------
  
  map_orsv: entity work.tt_orsv
    port map (
      sigclk   => sig_sck,
      rsv_p    => o_rsv_p,  -- out
      rsv_n    => o_rsv_n,  -- out
      autojtag => reg_autojtag,
      enjtag   => reg_enjtag,
      tms      => sig_tms );
  
  --- map: otrg --------------------------------------------------------

  sta_omask <= reg_omask when reg_oignore = '1' else (others => '0');
  
  map_otrg: entity work.tt_otrg
    port map (
      clock    => clk_s,
      sigframe => sig_frame,
      trgen    => sta_trgen,
      trg2     => sig_bit2,
      sub2     => sig_sub2,
      cprbit2  => sig_xbit2,
      cprsub2  => sig_xsub2,
      cprdum2  => sig_xdum2,
      trg_p    => o_trg_p,   -- out
      trg_n    => o_trg_n,   -- out
      discpr   => reg_xmask,
      selcpr   => reg_selcpr,
      disable  => "00000000",
      omask    => sta_omask,
      autojtag => reg_autojtag,
      enjtag   => reg_enjtag,
      tdi      => sig_tdi );
      
  --- map: x_encode ----------------------------------------------------

  map_xencode: entity work.x_encode
    port map (
      clock    => clk_s,
      runreset => sta_runreset,
      trig     => sig_trig,
      sigframe => sig_frame,
      frame3   => sta_frame3,
      bit2     => sig_xbit2,  -- out (1  downto 0)
      sub2     => sig_xsub2,  -- out (1  downto 0)
      dum2     => sig_xdum2,  -- out (1  downto 0)
      dbg      => open_dbg(1) ); -- out (31 downto 0)
  
  --- map: tt_dump -----------------------------------------------------

  map_ttdump: entity work.tt_dump
    port map (
      clock    => clk_s,
      dump     => set_dump,
      sigdump  => sig_dump,
      autodump => reg_autodump,
      delay    => reg_dumpwait,
      idump    => reg_idump,
      bit2     => sig_dump2,
      cnt2     => cnt_dump2,
      octet    => sig_dumpo,
      isk      => sig_dumpk,
      cnto     => cnt_dumpo,
      regraw   => buf_dump2,   -- out (9 downto 0)
      regoctet => buf_dump8,   -- out (7 downto 0)
      regisk   => buf_dumpk,   -- out
      snapshot => buf_dumpi ); -- out
  
  --- map: encode ------------------------------------------------------

  map_encode: entity work.m_encode
    generic map (
      B2TTVER => B2TTVER )
    port map (
      cntpay => cnt_pay,
      cntsub => cnt_sub,
      
      clock          => clk_s,
      cntreset       => set_cntreset,
      plllock        => sta_jpll,               -- from jitter cleaner
      revoin         => '0',                    -- tbd
      selreset       => reg_selreset,
      runreset       => sig_runreset,
      stareset       => set_stareset,
      trgstart       => set_trgstart,
      feereset       => set_feereset,
      b2lreset       => set_b2lreset,
      gtpreset       => set_gtpreset,
      incdelay       => set_incdelay,
      caldelay       => set_caldelay,
      notagerr       => reg_notagerr,
      cmdaddr        => reg_cmdaddr,
      setaddr        => set_addr,
      cmdhi          => reg_cmdhi,
      cmdlo          => reg_cmdlo,
      setcmd         => set_cmd,
      exprun         => reg_exprun,
      trigin         => sig_trig,
      trigtyp        => sig_trgtyp,             -- tbd
      utime          => sta_utime,
      ctime          => sta_ctime,
      clkfreq        => reg_clkfreq,
      utimer         => sta_utimer,
      ctimer         => sta_ctimer,
      
      starunreset    => sta_runreset,  -- out
      sigstart       => sig_trgstart,  -- out
      bit2           => sig_bit2,      -- out
      sub2           => sig_sub2,      -- out
      bitrd          => sig_bitrd,     -- out
      subrd          => sig_subrd,     -- out
      sigframe       => sig_frame,     -- out
      frame3         => sta_frame3,    -- out
      frame9         => sta_frame9,    -- out
      cntclk         => cnt_clk,       -- out
      cntbit2        => cnt_dump2(12), -- out
      cntoctet       => cnt_dumpo(12)(3 downto 0), -- out
      cntpacket      => cnt_packet,    -- out
      octet          => sig_dumpo(12), -- out
      isk            => sig_dumpk(12), -- out
      subo           => sig_dumpo(13), -- out
      subk           => sig_dumpk(13), -- out
      --iscomma      => sta_comma,     -- out
      revocand       => sta_revocand,  -- out
      cntrevocand    => cnt_revocand,  -- out
      cntbadrevo     => cnt_badrevo,   -- out
      cntnorevo      => cnt_norevo,    -- out
      trigshort      => sta_trigshort, -- out
      revoout        => sig_revo );    -- out

  --- map: collect ------------------------------------------------------

  map_collect: entity work.m_collect
    port map (
      clock     => clk_s,
      reset     => sig_errreset,
      trgen     => sta_trgen,
      oackp     => sig_oackp,
      oackn     => sig_oackn,
      omask     => reg_omask,
      xackp     => sig_xackp,
      xackn     => sig_xackn,
      xmask     => reg_xmask,
      utime     => sta_utime,
      ctime     => sta_ctime,
      tag       => cnt_trgout,
      autorst   => sig_autorst,   -- out
      busy      => sig_busy,      -- out
      errin     => sig_errin,     -- out
      oalive    => sta_oalive,    -- out (7 downto 0)
      olinkdn   => sta_olinkdn,   -- out (7 downto 0)
      olinkup   => sta_olinkup,   -- out (7 downto 0)
      b2lup     => sig_b2lup,     -- out (7 downto 0)
      plllk     => sig_plllk,     -- out (7 downto 0)
      stab2ldn  => sta_b2ldn,     -- out (7 downto 0)
      staplldn  => sta_plldn,     -- out (7 downto 0)
      b2lor     => sig_b2lor,     -- out
      linkerr   => sta_linkerr,   -- out
      odatab    => sta_odatab,    -- out (long 15 downto 0)
      odatc     => sta_odatc,     -- out (long 7 downto 0)
      xalive    => sta_xalive,    -- out (4 downto 1)
      xlinkup   => sta_xlinkup,   -- out (4 downto 1)
      xdata     => sta_xdata,     -- out (long 4 downto 1)
      xdatb     => sta_xdatb,     -- out (long 4 downto 1)
      xbcnt     => sig_xbcnt,     -- out (long 4 downto 1)
      obusy     => sta_obusy,     -- out (7 downto 0)
      xbusy     => sta_xbusy,     -- out (4 downto 1)
      oerrin    => sta_oerr,      -- out (7 downto 0)
      xerrin    => sta_xerr,      -- out (4 downto 1)
      obsyin    => sig_obusy,     -- out (7 downto 0)
      xbsyin    => sig_xbusy,     -- out (4 downto 1)
      oackq     => sig_oackq,     -- out (7 downto 0)
      xackq     => sig_xackq,     -- out (4 downto 1)
      errutim   => sta_errutim,   -- out (31 downto 0)
      errctim   => sta_errctim,   -- out (26 downto 0)
      errport   => sta_errport,   -- out (11 downto 0)
      errbit    => sta_errbit,    -- out (15 downto 0)
      tagdone   => sta_tagdone,   -- out (byte 7 downto 0)
      omanual   => reg_omanual,
      oclrdelay => reg_oclrdelay,
      oincdelay => reg_oincdelay,
      xmanual   => reg_xmanual,
      xclrdelay => reg_xclrdelay,
      xincdelay => reg_xincdelay,
      bit2      => sig_dump2(11 downto 0), -- out
      cntbit2   => cnt_dump2(11 downto 0), -- out
      cntoctet  => cnt_dumpo(11 downto 0), -- out
      octet     => sig_dumpo(11 downto 0), -- out
      isk       => sig_dumpk(11 downto 0), -- out
      sigdump   => sig_dump,
      selila    => "0000",--reg_selila,
      sigila    => sig_ilam );  -- out
  
  --- map: pipeline -----------------------------------------------------

  map_pipeline: entity work.m_pipeline
    port map (
      clock => clk_s,
      runreset => sig_runreset,
      trig     => sig_trig,
      linkup   => sta_olinkup,
      tagdone  => sta_tagdone,
      maxtrig  => reg_maxtrig,
      latency  => reg_latency,
      busy     => sta_pipebusy,  -- out
      dbg      => open_dbg(5),   -- out (31 downto 0)
      dbg2     => open_dbg(6) );    -- out (31 downto 0)
  
  --- map: genbusy ------------------------------------------------------

  map_genbusy: entity work.m_genbusy
    port map (
      clock   => clk_s,
      reset   => sig_errreset,
      trig    => sig_trig,
      clkerr  => sta_clkerr,
      errin   => sig_errin,
      linkerr => sta_linkerr,
      b2lup   => sig_b2lor,
      busyin1 => sig_busy,
      busyin2 => sta_pipebusy,
      fullin  => sta_fifoful,
      usetlu  => reg_usetlu,
      tlubusy => sta_tlubsy,
      regbusy => reg_busy,
      tshort  => sta_trigshort,
      nontlu  => sta_nontlu,     -- out
      errout  => sta_err,        -- out
      errsrc  => sta_errsrc,     -- out
      busyout => sta_busy,       -- out
      busysrc => sta_busysrc );  -- out
  
  --- map: gentrig ------------------------------------------------------

  map_gentrig: entity work.m_gentrig
    port map (
      clock    => clk_s,
      reset    => sig_runreset,
      busy     => sta_busy,
      err      => sta_err,
      start    => sig_trgstart,
      stop     => set_trgstop,
      limit    => reg_trglimit,
      last     => cnt_trglast, -- out
      seltrg   => reg_seltrg,
      genbor   => reg_genbor,
      trgsrc1  => sig_trgsrc1,
      trgsrc2  => sig_trgsrc2,
      trgsrc3  => sig_tlutrg,
      dumtrg   => sig_dumtrg,
      en       => sta_trgen,  -- out
      trgin    => sig_trgin,  -- out
      trig     => sig_trig,   -- out
      trgtyp   => sig_trgtyp, -- out (3 downto 0)
      dbg      => open_dbg(2) ); -- out (31 downto 0)
  
  --- map: dumtrig ------------------------------------------------------

  map_dumtrig: entity work.m_dumtrig
    port map (
      clock   => clk_s,
      revo    => sig_revo,
      setrate => set_rateval,
      seltrg  => reg_seltrg,  -- 3-bit
      rateval => reg_rateval, -- 10-bit
      rateexp => reg_rateexp, -- 4-bit
      trgopt  => reg_trgopt,  -- 12-bit
      trig    => sig_dumtrg,  -- out
      --dbg   => sta_dbg );
      dbg     => open_dbg(3) ); -- out
    
  --- map: trgdelay -----------------------------------------------------

  map_trgdelay: entity work.m_trgdelay
    port map (
      clock => clk_s,
      runreset => sig_runreset,
      delay => reg_trgdelay,
      trgin => sig_trgraw1,
      trgout => sig_trgsrc1 );  -- out

  --- map: tlu ----------------------------------------------------------

  map_tlu: entity work.tt_tlu
    port map (
      clock    => clk_s,
      runreset => sig_runreset,
      utime    => sta_utime,
      ctime    => sta_ctime,
      tludelay => reg_tludelay,
      skip1st  => reg_tluno1st,
      bsyin    => sta_nontlu,
      trgen    => sta_trgen,
      tluout   => sig_tluout,
      tluin    => sig_tluin,     -- out
      tlumon   => sta_tlumon,    -- out
      tlutrg   => sig_tlutrg,    -- out
      tlurst   => sig_tlurst,    -- out
      rstcnt   => cnt_tlurst,    -- out
      tlutag   => sta_tlutag,    -- out
      tlubsy   => sta_tlubsy,    -- out
      tluctim  => sta_tluctim,   -- out
      tluutim  => sta_tluutim,   -- out
      dbg      => open_dbg(4) ); -- out
  
  --- map: extra I/O ----------------------------------------------------
  -- iack is 1-2 pair for async trigger from TT-RX(old)
  -- itrg is 3-6 pair to monitor trigger out
  -- iaux3 is 7-8 pair for async trigger from TT-RX(new)/TT-IO/TLU

  map_iack: ibufds port map ( i => i_ack_p, ib => i_ack_n, o => sig_trgsrc2 );
  map_itrg: entity work.tt_aux
    generic map ( NBIT => 2 )
    port map ( auxp => i_trg_p, auxn => i_trg_n,
               regsel => reg_itrgsel, osig => sig_idbg );
  map_irsv: entity work.tt_aux
    generic map ( NBIT => 2 )
    port map ( auxp => i_rsv_p, auxn => i_rsv_n,
               regsel => reg_irsvsel, osig => sig_idbg );
      
  sig_idbg(1) <= sig_trgin;
  sig_idbg(2) <= sig_dumtrg;
  sig_idbg(3) <= sig_revo;

  map_aux12: obufds port map
    ( i => sig_oaux(0), o => o_aux_p(0), ob => o_aux_n(0) );
  map_aux36: obufds port map
    ( i => sig_oaux(1), o => o_aux_p(1), ob => o_aux_n(1) );
  map_aux54: ibufds port map
    ( o => sig_iaux(2), i => i_aux_p(2), ib => i_aux_n(2) );
  map_aux78: ibufds port map
    ( o => sig_iaux(3), i => i_aux_p(3), ib => i_aux_n(3) );

  sig_trgraw1 <= sig_iaux(3);
  
  sig_oaux(0) <= sig_tluin(0) when reg_usetlu  = '1' else sta_dbg(0);
  sig_oaux(1) <= sig_tluin(1) when reg_usetlu  = '1' else
                 --sig_oackq(0) when reg_ttrxrst = '0' else
                 (not sta_trgen) or sta_busy or sta_err;
  sig_tluout  <= sig_iaux(3 downto 2);
  
  --sig_ttrxrst <= reg_ttrxrst and sig_iaux(2);

  -- debug code
  sta_rxrst   <= sig_iaux(2);
  process (clk_s)
  begin
    if rising_edge(clk_s) then
      seq_rxrst <= seq_rxrst(0) & sta_rxrst;
      seq_errst <= seq_errst(0) & sig_errreset;
      if seq_rxrst = "01" then
        cnt_rxrst <= cnt_rxrst + 1;
      end if;
      if seq_errst = "01" then
        cnt_errst <= cnt_errst + 1;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------
  -- chipscope
  ----------------------------------------------------------------------
  gen_cs: if USE_CHIPSCOPE = '1' generate
    map_icon: entity work.m_icon port map ( control0 => sig_ilacontrol );
    map_ila:  entity work.m_ila
      port map (
        control => sig_ilacontrol,
        clk     => clk_s,
        trig0   => sig_ila );
    sig_ila <= sig_ilau when (not reg_selila) = 0 else sig_ilam;

    process (clk_l)
    begin
      if rising_edge(clk_l) then
        cnt_l <= cnt_l + 1;
      end if;
    end process;
    
    process (clk_s)
    begin
      if rising_edge(clk_s) then
        cnt_s <= cnt_s + 1;
      end if;
    end process;
    process (clk_i)
    begin
      if rising_edge(clk_i) then
        cnt_i <= cnt_i + 1;
      end if;
    end process;
    
    -- m_collect
    sig_ilau(95 downto 88) <= sig_dumpo(12);
    sig_ilau(87)           <= sig_dumpk(12);
    --sig_ilau(95 downto 88) <= sig_dumpo(0);
    --sig_ilau(87)           <= sig_dumpk(0);
    sig_ilau(86)           <= '0';
    sig_ilau(85 downto 84) <= sig_dump2(0);
    sig_ilau(83 downto 81) <= cnt_dump2(0); -- 3 bit
    sig_ilau(80 downto 76) <= cnt_dumpo(0); -- 5 bit
    sig_ilau(75) <= sta_olinkup(0);
    sig_ilau(74) <= sta_xlinkup(0);
    sig_ilau(73 downto 72) <= "00";

    sig_ilau(71 downto 70) <= sta_odatc(0)(31 downto 30); -- cnt_pkterr
    sig_ilau(69 downto 68) <= sta_odatc(0)(29 downto 28); -- cnt_realign
    sig_ilau(67 downto 56) <= sta_odatc(0)(27 downto 16); -- cnt_rdelay
    sig_ilau(55)         <= sta_odatc(0)(15); -- cnt_invalid(cnt_invalid'left)
    sig_ilau(54 downto 52) <= sta_odatc(0)(14 downto 12); -- cnt_invalid[2:0]
    sig_ilau(51 downto 48) <= sta_odatc(0)(3 downto  0); -- cnt_delay
    sig_ilau(47 downto 44) <= cnt_pay;
    sig_ilau(43 downto 40) <= cnt_sub;

    sig_ilau(39 downto 36) <= cnt_packet;
    sig_ilau(35 downto 34) <= sig_bit2;
    --sig_ilau(33 downto 32) <= sig_sub2;
    --sig_ilau(31) <= sig_bitrd;
    --sig_ilau(30) <= sig_subrd;
    --sig_ilau(29 downto 22) <= sig_dumpo(13); -- subo

    sig_ilau(33) <= sig_tck;
    sig_ilau(32) <= sig_tms;
    sig_ilau(31) <= sig_tdi;
    sig_ilau(30)           <= set_tdiblk;
    sig_ilau(29 downto 22) <= reg_tdiblk;
    

    sig_ilau(21) <= sig_iaux(3);
    sig_ilau(20) <= sig_iaux(2);
    
    -- tt_phasedet
    sig_ilau(19) <= sta_jpll;
    sig_ilau(18) <= sta_jdcm;
    sig_ilau(17) <= sig_pd;
    sig_ilau(16) <= sta_clkerr;
    sig_ilau(15 downto 12) <= sta_jcount(3 downto 0);
    sig_ilau(11 downto  8) <= sta_jphase;
    sig_ilau(7  downto  6) <= sta_jretry(1 downto 0);
    sig_ilau(5  downto  4) <= cnt_l;
    sig_ilau(3  downto  2) <= cnt_s;
    sig_ilau(1  downto  0) <= cnt_i;

  end generate;
  
end implementation;
--- (emacs outline mode setup)
-- Local Variables: ***
-- mode:outline-minor ***
-- outline-regexp:"^\\( *--- \\|begin\\|end\\|entity\\|architecture\\)" ***
-- End: ***
