------------------------------------------------------------------------
--
--  m_collect.vhd -- collector of decoded info for TTD master
--
--  Mikihiko Nakao, KEK IPNS
--
--  20120607 new
--  20130801 enotrg/encpr -> omask/xmask
--  20131027 differential oack/xack to use b2tt_ddr.vhd
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- - m_collect
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.tt_types.all;
use work.b2tt_symbols.all;

entity m_collect is
  port ( 
    clock     : in  std_logic;
    reset     : in  std_logic;
    trgen     : in  std_logic;
    oackp     : in  std_logic_vector  (7  downto 0);
    oackn     : in  std_logic_vector  (7  downto 0);
    omask     : in  std_logic_vector  (7  downto 0);
    xackp     : in  std_logic_vector  (4  downto 1);
    xackn     : in  std_logic_vector  (4  downto 1);
    xmask     : in  std_logic_vector  (4  downto 1);
    utime     : in  std_logic_vector  (31 downto 0);
    ctime     : in  std_logic_vector  (26 downto 0);
    tag       : in  std_logic_vector  (31 downto 0);
    autorst   : out std_logic;
    busy      : out std_logic;
    errin     : out std_logic;
    oalive    : out std_logic_vector  (7  downto 0);
    olinkdn   : out std_logic_vector  (7  downto 0);
    olinkup   : out std_logic_vector  (7  downto 0);
    b2lup     : out std_logic_vector  (7  downto 0);
    plllk     : out std_logic_vector  (7  downto 0);
    stab2ldn  : out std_logic_vector  (7  downto 0);
    staplldn  : out std_logic_vector  (7  downto 0);
    b2lor     : out std_logic;
    linkerr   : out std_logic;
    odatab    : out long_vector       (15 downto 0);
    odatc     : out long_vector       (7  downto 0);
    xalive    : out std_logic_vector  (4  downto 1);
    xlinkup   : out std_logic_vector  (4  downto 1);
    xdata     : out long_vector       (4  downto 1);
    xdatb     : out long_vector       (4  downto 1);
    xdatc     : out long_vector       (4  downto 1);
    obusy     : out std_logic_vector  (7  downto 0);
    xbusy     : out std_logic_vector  (4  downto 1);
    oerrin    : out std_logic_vector  (7  downto 0);
    xerrin    : out std_logic_vector  (4  downto 1);
    obsyin    : out std_logic_vector  (7  downto 0);
    xbsyin    : out std_logic_vector  (4  downto 1);
    oackq     : out std_logic_vector  (7  downto 0);
    xackq     : out std_logic_vector  (4  downto 1);
    errutim   : out std_logic_vector  (31 downto 0);
    errctim   : out std_logic_vector  (26 downto 0);
    errport   : out std_logic_vector  (11 downto 0);
    errbit    : out std_logic_vector  (15 downto 0);
    tagdone   : out byte_vector       (7 downto 0);
    xmanual   : in  std_logic_vector  (4  downto 1);
    xclrdelay : in  std_logic_vector  (4  downto 1);
    xincdelay : in  std_logic_vector  (4  downto 1);
    omanual   : in  std_logic_vector  (7  downto 0);
    oclrdelay : in  std_logic_vector  (7  downto 0);
    oincdelay : in  std_logic_vector  (7  downto 0);
    xbcnt     : out long_vector       (4  downto 1);
    bit2      : out std_logic2_vector (11 downto 0);
    cntbit2   : out std_logic3_vector (11 downto 0);
    cntoctet  : out std_logic5_vector (11 downto 0);
    octet     : out byte_vector       (11 downto 0);
    isk       : out std_logic_vector  (11 downto 0);
    sigdump   : out std_logic;
    selila    : in  std_logic_vector  (3  downto 0);
    sigila    : out std_logic_vector  (95 downto 0) );
end m_collect;
------------------------------------------------------------------------
architecture implementation of m_collect is
  signal sig_obusy   : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_obusy   : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_oerrin  : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_oalive  : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_olinkup : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_olinkdn : std_logic_vector (7  downto 0) := (others => '0');
  signal seq_olinkup : std_logic_vector (7  downto 0) := (others => '0');
  signal buf_olinkup : std_logic_vector (7  downto 0) := (others => '0');
  signal sig_b2lup   : std_logic_vector (7  downto 0) := (others => '0');
  signal sig_plllk   : std_logic_vector (7  downto 0) := (others => '0');
  signal seq_b2lup   : std_logic_vector (7  downto 0) := (others => '0');
  signal seq_plllk   : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_b2ldn   : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_plldn   : std_logic_vector (7  downto 0) := (others => '0');

  signal sta_xlinkup : std_logic_vector (4  downto 1) := (others => '0');
  signal sta_xlinkdn : std_logic_vector (4  downto 1) := (others => '0');
  signal seq_xlinkup : std_logic_vector (4  downto 1) := (others => '0');
  signal buf_xlinkup : std_logic_vector (4  downto 1) := (others => '0');
  signal sig_xbusy   : std_logic_vector (4  downto 1) := (others => '0');
  signal sta_xbusy   : std_logic_vector (4  downto 1) := (others => '0');
  signal sta_xerrin  : std_logic_vector (4  downto 1) := (others => '0');

  signal sta_xdata   : long_vector (4  downto 1) := (others => x"00000000");
  signal sta_xdatb   : long_vector (4  downto 1) := (others => x"00000000");

  signal sta_o       : long_vector (15 downto 0) := (others => x"00000000");
  signal sta_odata   : long_vector (7  downto 0) := (others => x"00000000");
  signal sta_odatb   : long_vector (7  downto 0) := (others => x"00000000");
  signal sta_odatc   : long_vector (7  downto 0) := (others => x"00000000");

  signal sta_feeerr  : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_ttlost  : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_b2llost : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_tagerr  : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_fifoerr : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_fifoful : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_seuerr1 : std_logic_vector (7 downto 0) := (others => '0');
  signal sta_seuerr0 : std_logic_vector (7 downto 0) := (others => '0');
  
  signal sta_ehslbd  : std_logic_vector (4 downto 1) := (others => '0');
  signal sta_ehslbc  : std_logic_vector (4 downto 1) := (others => '0');
  signal sta_ehslbb  : std_logic_vector (4 downto 1) := (others => '0');
  signal sta_ehslba  : std_logic_vector (4 downto 1) := (others => '0');
  
  signal sig_feeerr  : std_logic := '0';
  signal sig_ttlost  : std_logic := '0';
  signal sig_b2llost : std_logic := '0';
  signal sig_tagerr  : std_logic := '0';
  signal sig_fifoerr : std_logic := '0';
  signal sig_fifoful : std_logic := '0';
  signal sig_seuerr1 : std_logic := '0';
  signal sig_seuerr0 : std_logic := '0';
  
  signal sig_ehslbd  : std_logic := '0';
  signal sig_ehslbc  : std_logic := '0';
  signal sig_ehslbb  : std_logic := '0';
  signal sig_ehslba  : std_logic := '0';
  
  signal sig_odump : std_logic_vector (7 downto 0) := (others => '0');
  
  signal sta_errport : std_logic_vector (11 downto 0) := (others => '0');
  type sigila_vector is array (natural range <>) of
                       std_logic_vector (95 downto 0);
  signal sig_ila   : sigila_vector (11 downto 0);
begin

  gen_xdecode: for i in 1 to 4 generate
    map_xdecode: entity work.x_decode
      port map (
        clock    => clock,
        reset    => reset,
        disable  => xmask(i),
        ackp     => xackp(i),
        ackn     => xackn(i),
        manual   => xmanual(i),
        clrdelay => xclrdelay(i),
        incdelay => xincdelay(i),
        bitddr   => xackq(i),               -- out
        bsyout   => sig_xbusy(i),           -- out
        cntfbsy  => xbcnt(i)(15 downto 0),  -- out
        cntsbsy  => xbcnt(i)(31 downto 16), -- out
        xdata(63 downto 32) => sta_xdata(i), -- out
        xdata(31 downto  0) => sta_xdatb(i), -- out
        sigila   => sig_ila(i+7) ); -- out

    xalive(i)      <= sta_xdatb(i)(0);
    sta_xlinkup(i) <= sta_xdatb(i)(1);
    sta_xlinkdn(i) <= sta_xdatb(i)(11);

    -- xdatb(3 downto 2) is staiddr which should be 3
    -- to be an established link
    buf_xlinkup(i) <= sta_xdatb(i)(1) and sta_xdatb(i)(2) and sta_xdatb(i)(3);
    
    bit2(i+7) <= "00";
    cntbit2(i+7) <= "000";
    cntoctet(i+7) <= "00000";
    octet(i+7) <= x"00";
    isk(i+7) <= '0';
  end generate;
  
  gen_decode: for i in 0 to 7 generate
    map_decode: entity work.o_decode
      port map (
        clock      => clock,
        mask       => omask(i),
        reset      => reset,
        ackp       => oackp(i),
        ackn       => oackn(i),
        manual     => omanual(i),
        clrdelay   => oclrdelay(i),
        incdelay   => oincdelay(i),
        bitddr     => oackq(i), -- out / debug
        bsyout     => sig_obusy(i),  -- out
        tag        => tag,
        linkup     => sta_olinkup(i),
        stata      => sta_odata(i),
        statb      => sta_odatb(i),
        statc      => sta_odatc(i), -- out / debug
        tagdone    => tagdone(i),
        octet      => octet(i),   -- out
        isk        => isk(i),     -- out
        bit2       => bit2(i),    -- out
        cntbit2    => cntbit2(i), -- out
        cntoctet   => cntoctet(i), -- out
        sigdump    => sig_odump(i),
        sigila     => sig_ila(i) ); -- out
    
    sta_o(i*2 + 0) <= sta_odata(i);
    sta_o(i*2 + 1) <= sta_odatb(i);
    
    -- odatc(14 downto 13) is staiddr which should be 3
    -- to be an established link
    buf_olinkup(i) <= sta_olinkup(i) and sta_odatc(i)(13) and sta_odatc(i)(14);
    
  end generate;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- errutim, errctim, errport
      if reset = '1' then
        errutim <= (others => '0');
        errctim <= (others => '0');
        sta_errport <= (others => '0');
        errbit  <= (others => '0');
      elsif sta_errport = 0 and (sta_oerrin /= 0 or sta_xerrin /= 0) then
        errutim <= utime;
        errctim <= ctime;
        sta_errport <= sta_xerrin & sta_oerrin;
        errbit <= "0000" &
                  sig_ehslbd & sig_ehslbc & sig_ehslbb & sig_ehslba &
                  sig_feeerr & sig_ttlost & sig_b2llost & sig_tagerr &
                  sig_fifoerr & sig_fifoful & sig_seuerr1 & sig_seuerr0;
      end if;

      -- autorst
      if buf_olinkup = seq_olinkup and buf_xlinkup = seq_xlinkup then
        autorst <= '0';
      else
        autorst <= '1';
      end if;
      seq_olinkup <= buf_olinkup;
      seq_xlinkup <= buf_xlinkup;
      
    end if; -- event
  end process;

  -- out
  -- 11  feeerr;  -- payload(80)
  -- 10  ttlost;  -- payload(79)
  -- 9   b2llost; -- payload(78)
  -- 8   tagerr;  -- payload(77)
  -- 7   fifoerr; -- payload(76)
  -- 6   fifoful; -- payload(75)
  -- 5:4 seuerr; -- payload(69 downto 68)
  -- 3   b2lup;   -- payload(90)
  -- 2   plllk;   -- payload(17)
  -- 1   ttup;    -- payload(91)
  -- 0   alive;

  gen_obusy: for i in 0 to 7 generate
    sta_obusy(i)  <= '1' when sta_olinkdn(i) = '1' else
                     '0' when sta_olinkup(i) = '0' else
                     '0' when sta_odata(i)(11 downto 4) = 0 and
                              sta_odatb(i)(31) = '0' else
                     '1';
    sta_oerrin(i) <= '1' when sta_olinkdn(i) = '1' else
                     '0' when sta_olinkup(i) = '0' else
                     '1' when sta_odata(i)(11 downto 4) /= 0 else
                     '0';
    sta_feeerr(i)  <= sta_olinkup(i) and sta_odata(i)(11);
    sta_ttlost(i)  <= sta_olinkup(i) and sta_odata(i)(10);
    sta_b2llost(i) <= sta_olinkup(i) and sta_odata(i)(9);
    sta_tagerr(i)  <= sta_olinkup(i) and sta_odata(i)(8);
    sta_fifoerr(i) <= sta_olinkup(i) and sta_odata(i)(7);
    sta_fifoful(i) <= sta_olinkup(i) and sta_odata(i)(6);
    sta_seuerr1(i) <= sta_olinkup(i) and sta_odata(i)(5);
    sta_seuerr0(i) <= sta_olinkup(i) and sta_odata(i)(4);
  end generate;
  sig_feeerr  <= '1' when sta_feeerr  /= 0 else '0';
  sig_ttlost  <= '1' when sta_ttlost  /= 0 else '0';
  sig_b2llost <= '1' when sta_b2llost /= 0 else '0';
  sig_tagerr  <= '1' when sta_tagerr  /= 0 else '0';
  sig_fifoerr <= '1' when sta_fifoerr /= 0 else '0';
  sig_fifoful <= '1' when sta_fifoful /= 0 else '0';
  sig_seuerr1 <= '1' when sta_seuerr1 /= 0 else '0';
  sig_seuerr0 <= '1' when sta_seuerr0 /= 0 else '0';

  -- 0: linkup
  -- 1: nwff
  -- 2-5: emp
  -- 6-9: ful (copper ful)
  -- 13-10: bsy (hslb error)
  -- 17-14: en
  gen_xbusy: for i in 1 to 4 generate
    sta_xbusy(i)  <= '1' when sta_xlinkdn(i) = '1' else
                     '0' when sta_xlinkup(i) = '0' else
                     '0' when sta_xdata(i)(27 downto 20) = 0 and
                              sta_xdata(i)(15) = '0' else
                     '1';
    sta_xerrin(i) <= '1' when sta_xlinkdn(i) = '1' else
                     '0' when sta_xlinkup(i) = '0' else
                     '1' when sta_xdata(i)(27 downto 24) /= 0 else
                     '0';
    sta_ehslbd(i) <= sta_xlinkup(i) and sta_xdata(i)(27);
    sta_ehslbc(i) <= sta_xlinkup(i) and sta_xdata(i)(26);
    sta_ehslbb(i) <= sta_xlinkup(i) and sta_xdata(i)(25);
    sta_ehslba(i) <= sta_xlinkup(i) and sta_xdata(i)(24);
  end generate;
  sig_ehslbd <= '1' when sta_ehslbd /= 0 else '0';
  sig_ehslbc <= '1' when sta_ehslbc /= 0 else '0';
  sig_ehslbb <= '1' when sta_ehslbb /= 0 else '0';
  sig_ehslba <= '1' when sta_ehslba /= 0 else '0';

  linkerr <= '1' when sta_olinkdn /= 0 else
             '1' when sta_xlinkdn /= 0 else
             '0';
  busy    <= '1' when sta_obusy /= 0 else
             '1' when sta_xbusy /= "0000" else
             '0';
  errin   <= '1' when sta_oerrin /= 0 else
             '1' when sta_xerrin /= "0000" else
             '0';

  stab2ldn <= sta_b2ldn;
  staplldn <= sta_plldn;
  b2lup    <= sig_b2lup or (not sta_olinkup);
  plllk    <= sig_plllk or (not sta_olinkup);
  b2lor    <= '1' when ((not sig_b2lup) and sta_olinkup) = 0 else '0';
  xlinkup  <= sta_xlinkup;
  olinkup  <= sta_olinkup;
  obsyin   <= sig_obusy and sta_olinkup;
  xbsyin   <= sig_xbusy and sta_xlinkup;
  
  odatab  <= sta_o;
  obusy   <= sta_obusy;
  oerrin  <= sta_oerrin;
  xbusy   <= sta_xbusy;
  xerrin  <= sta_xerrin;
  xdata   <= sta_xdata;
  xdatb   <= sta_xdatb;

  errport <= sta_errport;
  sigdump  <= '1' when sig_odump /= 0 else '0';
  
  sigila  <= sig_ila(conv_integer(selila));
  
end implementation;
