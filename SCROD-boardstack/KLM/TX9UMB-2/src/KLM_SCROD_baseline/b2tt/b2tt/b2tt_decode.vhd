------------------------------------------------------------------------
--
--  b2tt_decode.vhd -- TT-link decoder for Belle2link frontend
--
--  Mikihiko Nakao, KEK IPNS
--
--  20120325 first version
--  20120528 fixes based on c-model
--  20120603 restructured
--  20131002 many changes, b2tt_iddr separated out
--  20131012 unifying with v6 code
--  20131101 no more std_logic_arith
--  20131126 tagerr fix (debug with c-model)
--  20140102 ini.value of detag:buf_cnttrg / detrig:cnt_trig to -1
--
--  eout bit 9 is first transmitted, bit 0 is last transmitted
--  ein  bit 9 is first received,    bit 0 is last received
--
--  data structure
--     bit2       2-bit input at every clock
--     bit10      10-bit input before 8b10b
--     octet/isk  8-bit decoded data and flag for K-character
--     packet     16-octet container starting with a comma
--     payload    77-bit data inserted in a packet
--     frame      16-packet container synchronized to beam revolution
--
--  counters
--    cntbit2
--      0 to 4  incremented every clock to make an octet to 8b10b
--      5       octet boundary is not found or found at wrong place
--              When a comma is found at a wrong place, "newcomma" is
--              asserted.  When another comma is found when cntbit2 is 5,
--              cntbit2 cycle immediately goes into 0 to 4 cycle.
--    cntoctet
--      0  to 15 incremented every 5 clocks to make a packet (16 octet)
--      16      packet boundary is found with alternative comma
--      17      packet boundary is not found or found at wrong place
--              When a packet boundary is found at a wrong place,
--              "newframe" is asserted.  When another comma is found
--              when cntbit2 is 5, cntbit2 cycle immediately goes into
--              0 to 4 cycle.
--
--    cnt_packet
--      0  to 15 incremented every 16 octet to make a frame
--      16       reset because of incorrect octet/packet
--      17 to 255  link yet to be established, incremented until round
--                 up to 0
--  
------------------------------------------------------------------------

------------------------------------------------------------------------
-- - b2tt_decomma
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_decomma is
  port (
    en        : in std_logic;
    bit2      : in std_logic_vector (1 downto 0);
    prev8     : in std_logic_vector (7 downto 0);
    cntbit2   : in std_logic_vector (2 downto 0);
    comma     : out std_logic;
    newcomma  : out std_logic );
end b2tt_decomma;
------------------------------------------------------------------------
architecture implementation of b2tt_decomma is
  signal sig_bit10 : std_logic_vector (9 downto 0) := "0000000000";
  signal sig_comma : std_logic := '0';
begin
  -- in
  sig_bit10 <= prev8 & bit2 when en = '1' else (others => '0');

  -- comma detection (before clock cycle)
  sig_comma <= '1' when
    sig_bit10 = K28_5P or sig_bit10 = K28_5N or
    sig_bit10 = K28_1P or sig_bit10 = K28_1N else '0';

  -- misaligned comma detection (before clock cycle)
  -- out (async)
  newcomma <= '1' when sig_comma = '1' and
                       cntbit2 /= 0 and cntbit2 /= 5 else '0';
  comma <= sig_comma;
  
end implementation;
------------------------------------------------------------------------
-- - b2tt_debit2
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_debit2 is
  port (
    clock     : in  std_logic;
    en        : in  std_logic;
    newcomma  : in  std_logic;
    comma     : in  std_logic;
    bit2      : in  std_logic_vector (1 downto 0);
    bit10     : out std_logic_vector (9 downto 0);
    cntbit2   : out std_logic_vector (2 downto 0); -- 0 to 4
    sigslip   : out std_logic );
end b2tt_debit2;
------------------------------------------------------------------------
architecture implementation of b2tt_debit2 is

  signal buf_slip10 : std_logic_vector (9 downto 0) := "0000000000";
  signal buf_bit10  : std_logic_vector (9 downto 0) := "0000000000";
  signal buf_slip   : std_logic := '0';

  signal cnt_bit2   : std_logic_vector (2 downto 0) := "101";
begin
  -- process
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- search for a shifted comma charactor for bit slip
      if en = '0' or
         buf_slip10 = K28_5P or buf_slip10 = K28_5N or
         buf_slip10 = K28_1P or buf_slip10 = K28_1N then
        buf_slip10 <= (others => '0');
        buf_slip   <= '0';
        sigslip    <= en;
      else
        buf_slip10 <= buf_slip10(7 downto 0) & buf_slip & bit2(1);
        buf_slip   <= bit2(0);
        sigslip    <= '0';
      end if;

      -- decode counter to align octet boundary (==5 when not aligned)
      if en = '0' then
        cnt_bit2 <= "101"; -- 5
      elsif newcomma = '1' then
        cnt_bit2 <= "101"; -- 5
      elsif comma = '1' then
        cnt_bit2 <= "001"; -- 1
      elsif cnt_bit2 = 4 then
        cnt_bit2 <= "000"; -- 0
      elsif cnt_bit2 /= 5 then
        cnt_bit2 <= cnt_bit2 + 1;
      end if;

      -- standard buffer
      if en = '1' then
        buf_bit10 <= buf_bit10(7 downto 0) & bit2;
      else
        buf_bit10 <= (others => '0');
      end if;
    end if;
  end process;

  -- out
  bit10     <= buf_bit10;
  cntbit2   <= cnt_bit2;

end implementation;
------------------------------------------------------------------------
-- - b2tt_debit10
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_debit10 is
  port (
    clock     : in  std_logic;
    cntbit2   : in  std_logic_vector (2 downto 0);
    bit2      : in  std_logic_vector (1 downto 0);
    bit10     : in  std_logic_vector (9 downto 0);
    octet     : out std_logic_vector (7 downto 0);  -- out/async
    isk       : out std_logic );                    -- out/async
end b2tt_debit10;
------------------------------------------------------------------------
architecture implementation of b2tt_debit10 is

  signal sig_10b  : std_logic_vector (9 downto 0) := "0000000000";
  signal sig_en   : std_logic := '0';
  signal sig_isk  : std_logic := '0';
  signal buf_isk  : std_logic := '0';
  signal sig_8b   : std_logic_vector (7 downto 0) := x"00";
  signal buf_8b   : std_logic_vector (7 downto 0) := x"00";

  signal open_err : std_logic_vector (4 downto 0) := (others => '0');
  signal open_rdp : std_logic := '0';
begin

  -- in
  sig_10b <= bit10(7 downto 0) & bit2;
  sig_en  <= '1' when cntbit2 = 4 else '0';

  -- almost async (except for rdp)
  map_de: entity work.b2tt_de8b10b
    port map ( reset => '0',
               clock => clock,
               en    => sig_en,
               ein   => sig_10b,
               dout  => sig_8b,
               isk   => sig_isk,
               err   => open_err,  -- out
               rdp   => open_rdp); -- out
  
  -- out (async)
  octet   <= sig_8b  when cntbit2 = 0 or cntbit2 = 5 else buf_8b;
  isk     <= sig_isk when cntbit2 = 0 or cntbit2 = 5 else buf_isk;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if cntbit2 = 0 or cntbit2 = 5 then
        buf_8b  <= sig_8b;
        buf_isk <= sig_isk;
      end if;
    end if;
  end process;

end implementation;
------------------------------------------------------------------------
-- - b2tt_detrig
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_detrig is
  port (
    clock      : in  std_logic;
    en         : in  std_logic;
    runreset   : in  std_logic;
    cntbit2    : in  std_logic_vector (2  downto 0);
    octet      : in  std_logic_vector (7  downto 0);
    isk        : in  std_logic;
    trgout     : out std_logic;
    trgtyp     : out std_logic_vector (3  downto 0);
    trgtag     : out std_logic_vector (31 downto 0);
    trgshort   : out std_logic;
    dbg : out std_logic_vector (31 downto 0) );
end b2tt_detrig;
------------------------------------------------------------------------
architecture implementation of b2tt_detrig is
  signal sig_trgoctet    : std_logic := '0';
  signal sig_trgout      : std_logic := '0';
  signal sig_trgtim      : std_logic_vector (2  downto 0) := "111";
  signal buf_trgtim      : std_logic_vector (2  downto 0) := "111";
  signal cnt_trginterval : std_logic_vector (4  downto 0) := "11000";  -- 24
  signal cnt_trig        : std_logic_vector (31 downto 0) := (others => '1');

  signal cnt_dbg1 : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_dbg2 : std_logic_vector (15 downto 0) := (others => '0');
begin

  -- in
  sig_trgtim   <= octet(6 downto 4);
  sig_trgoctet <= octet(7) and (not isk) when cntbit2 = 1 else '0';

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if sig_trgout = '1' then
        cnt_trginterval <= "00001";
      elsif cnt_trginterval < 23 then
        cnt_trginterval <= cnt_trginterval + 1;
      end if;
      
      -- search for trigger octet
      -- sig_trgout: time-recovered trigger signal
      -- buf_trgtim: for delayed trigger generation
      -- trgshort:   trigger comes in a too short interval (held until reset)

      -- trgshort
      if en = '0' or runreset = '1' then
        trgshort <= '0';
      elsif sig_trgoctet = '1' and cnt_trginterval + sig_trgtim < 24 then
        trgshort <= '1';
      end if;

      -- trgout
      if en = '0' or runreset = '1' then
        sig_trgout <= '0';
      elsif sig_trgoctet = '1' and sig_trgtim = 1 then
        if cnt_trginterval + 1 >= 24 then
          sig_trgout <= '1';
        else
          sig_trgout <= '0';
        end if;
      elsif cntbit2 = buf_trgtim then
        sig_trgout <= '1';
      else
        sig_trgout <= '0';
      end if;

      -- cnt_trig
      if en = '0' or runreset = '1' then
        cnt_trig <= (others => '1');
        if en = '0' then
          cnt_dbg1 <= cnt_dbg1 + 1;
        end if;
        if runreset = '1' then
          cnt_dbg2 <= cnt_dbg2 + 1;
        end if;
      elsif sig_trgoctet = '1' and sig_trgtim = 1 then
        if cnt_trginterval + 1 >= 24 then
          cnt_trig <= cnt_trig + 1;
        end if;
      elsif cntbit2 = buf_trgtim then
        cnt_trig <= cnt_trig + 1;
      end if;
      
      -- buf_trgtyp
      if en = '0' or runreset = '1' then
        trgtyp <= TTYP_NONE;
      elsif cntbit2 = 1 and sig_trgoctet = '1' then
        trgtyp <= octet(3 downto 0);
      end if;

      -- buf_trgtim
      if en = '0' or runreset = '1' then
        buf_trgtim <= "111";
      elsif sig_trgoctet = '1' then
        if sig_trgtim <= 1 or sig_trgtim > 5 then
          buf_trgtim <= "111"; -- 1: immediate trgout, 0,6,7: invalid
        elsif sig_trgtim = 5 then
          buf_trgtim <= "000"; -- 5: wrap-around to 0
        else
          buf_trgtim <= sig_trgtim; -- 2,3,4: as it is
        end if;
      elsif cntbit2 = 0 then
        buf_trgtim <= "111";
      end if;

    end if; -- event
  end process;

  -- out
  trgout <= sig_trgout;
  trgtag <= cnt_trig;

  dbg <= cnt_dbg1 & cnt_dbg2;
  
end implementation;
------------------------------------------------------------------------
-- - b2tt_deoctet
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_deoctet is
  port (
    clock      : in  std_logic;
    cntbit2    : in  std_logic_vector (2 downto 0);
    octet      : in  std_logic_vector (7 downto 0);
    isk        : in  std_logic;
    staoctet   : out std_logic;
    sigpayload : out std_logic;
    sigidle    : out std_logic;
    incdelay   : out std_logic;
    cntlinkrst : out std_logic_vector (7  downto 0);
    payload    : out std_logic_vector (76 downto 0);
    cnterr     : out std_logic_vector (31 downto 0) );
end b2tt_deoctet;
------------------------------------------------------------------------
architecture implementation of b2tt_deoctet is
  signal cnt_octet    : std_logic_vector (4  downto 0) := "00000";
  signal sta_octet    : std_logic := '0';
  signal cnt_invalid  : std_logic_vector (11 downto 0) := x"000";
  signal cnt_incdelay : std_logic_vector (7  downto 0) := x"00";

  signal sig_datoctet : std_logic := '0';
  signal cnt_datoctet : std_logic_vector (3  downto 0) := (others => '0');
  signal buf_payload  : std_logic_vector (76 downto 0) := (others => '0');

  signal cnt_err0 : std_logic_vector (3 downto 0) := x"0";
  signal cnt_err1 : std_logic_vector (3 downto 0) := x"0";
  signal cnt_err2 : std_logic_vector (3 downto 0) := x"0";
  signal cnt_err3 : std_logic_vector (3 downto 0) := x"0";
  signal cnt_err4 : std_logic_vector (3 downto 0) := x"0";
  signal cnt_err5 : std_logic_vector (3 downto 0) := x"0";
  signal buf_dat6 : std_logic_vector (7 downto 0) := x"00";
begin
  -- in
  sig_datoctet <= (not octet(7)) and (not isk);
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- check invalid packet
      -- - cnt_invalid: number of invalid octet
      -- - sig_indelay: signal to increment delay
      if cnt_invalid(cnt_invalid'left) = '1' then
        cnt_invalid  <= (others => '0');
        incdelay <= '1';  -- out
        cnt_incdelay <= cnt_incdelay + 1;
      else
        if sta_octet = '0' then
          cnt_invalid  <= cnt_invalid + 1;
        end if;
        incdelay <= '0';  -- out
      end if;

      -- search for a packet boundary
      -- - cnt_octet: to align octet to packet boundary
      -- - sta_octet: octet is aligned to packet boundary
      if cntbit2 = 5 then
        if sta_octet = '1' then
          cnt_err0 <= cnt_err0 + 1;
        end if;
        sta_octet <= '0';
        cnt_octet <= "11111";
          
      elsif cntbit2 = 1 then
        -- and all the octets are checked only at cntbit2 = 1 (2?)

        if isk = '1' and octet = K28_1 then
          -- valid comma if cnt_octet = 15
          if cnt_octet = 15 or cnt_octet = 31 then
            sta_octet <= '1';
            cnt_octet <= "00000";
          else
            sta_octet <= '0';
            cnt_octet <= "11111";
            cnt_err1 <= cnt_err1 + 1;
          end if;
        elsif isk = '1' and octet = K28_5 then
          -- valid alternative comma if cnt_octet = 16
          if cnt_octet = 16 then
            sta_octet <= '1';
            cnt_octet <= "00001";
          else
            sta_octet <= '0';
            cnt_octet <= "11111";
            cnt_err2 <= cnt_err2 + 1;
          end if;
        elsif (cnt_datoctet = 0 or cnt_datoctet = 11) and
               isk = '1' and octet = K28_3 then
          -- valid idle
          cnt_octet <= cnt_octet + 1;
        elsif isk = '1' then
          -- invalid K character
          sta_octet <= '0';
          cnt_octet <= "11111";
          cnt_err3 <= cnt_err3 + 1;
          buf_dat6 <= octet;
        elsif cnt_datoctet = 11 and octet(7) = '0' then
          -- invalid (too long) data payload
          sta_octet <= '0';
          cnt_octet <= "11111";
          cnt_err4 <= cnt_err4 + 1;
        elsif cnt_octet = 15 and octet(7) = '1' then
          -- valid trigger octet at the beginning of packet
          cnt_octet <= "10000";
        elsif cnt_octet < 15 then
          -- valid data or trigger octet
          cnt_octet <= cnt_octet + 1;
        else
          -- invalid data payload
          sta_octet <= '0';
          cnt_octet <= "00000";
          cnt_err5 <= cnt_err5 + 1;
        end if;
      end if;
      
      -- payload reconstruction
      if cntbit2 = 5 then
        buf_payload  <= (others => '0');
        cnt_datoctet <= (others => '0');
      elsif cntbit2 = 2 then
        if cnt_octet = 0 or cnt_octet = 16 then
          buf_payload  <= (others => '0');
          cnt_datoctet <= (others => '0');
        elsif cnt_datoctet < 11 and sig_datoctet = '1' then
          buf_payload  <= buf_payload(7*10-1 downto 0) & octet(6 downto 0);
          cnt_datoctet <= cnt_datoctet + 1;
        end if;
      end if;

      -- sig_payload and sig_idle
      if cntbit2 = 3 and cnt_octet = 15 then
        if cnt_datoctet = 11 then
          sigpayload <= '1';  -- out
          payload    <= buf_payload;
        end if;
        if cnt_datoctet = 0 then
          sigidle    <= '1';  -- out
        end if;
      else
        sigpayload   <= '0';  -- out
        sigidle      <= '0';  -- out
      end if;

    end if;
  end process;

  -- out
  cnterr <= buf_dat6 & cnt_err5 & cnt_err4 &
            cnt_err3 & cnt_err2 & cnt_err1 & cnt_err0;
  staoctet   <= sta_octet;
  cntlinkrst <= cnt_incdelay;

end implementation;
------------------------------------------------------------------------
-- - b2tt_depacket
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_depacket is
  generic (
    constant CLKDIV1 : integer range 0 to 72;
    constant CLKDIV2 : integer range 0 to 72;
    constant DEFADDR : std_logic_vector (19 downto 0) := x"00000" );
  port (
    clock      : in  std_logic;
    staoctet   : in  std_logic;
    sigpayload : in  std_logic;
    sigidle    : in  std_logic;
    payload    : in  std_logic_vector (76 downto 0);
    myaddr     : out std_logic_vector (19 downto 0);
    frame      : out std_logic;
    frame9     : out std_logic;
    divclk1    : out std_logic_vector (1  downto 0);
    divclk2    : out std_logic_vector (1  downto 0);
    cntpacket  : out std_logic_vector (7  downto 0);
    utime      : out std_logic_vector (31 downto 0);
    ctime      : out std_logic_vector (26 downto 0);
    cntrevoclk : out std_logic_vector (10 downto 0);
    runreset   : out std_logic;
    feereset   : out std_logic;
    b2lreset   : out std_logic;
    gtpreset   : out std_logic;
    incdelay   : out std_logic;
    caldelay   : out std_logic;
    entagerr   : out std_logic;
    stalink    : out std_logic;
    timerr     : out std_logic;
    dbg : out std_logic_vector (31 downto 0) );
end b2tt_depacket;
------------------------------------------------------------------------
architecture implementation of b2tt_depacket is
  signal sta_link     : std_logic := '0';
  signal cnt_packet   : std_logic_vector (7  downto 0) := (others => '0');
  signal buf_bcast    : std_logic := '0';
  signal buf_ttcmd    : std_logic_vector (11 downto 0) := (others => '0');
  signal buf_bdata    : std_logic_vector (63 downto 0) := (others => '0');
  signal buf_adata    : std_logic_vector (43 downto 0) := (others => '0');
  signal buf_addr     : std_logic_vector (19 downto 0) := (others => '0');
  signal sig_frame    : std_logic := '0';
  signal sig_frame3   : std_logic := '0';
  signal sig_frame9   : std_logic := '0';
  signal buf_utime    : std_logic_vector (31 downto 0) := (others => '0');
  signal buf_ctime    : std_logic_vector (26 downto 0) := (others => '0');
  signal buf_clkfreq  : std_logic_vector (23 downto 0) := x"952980";
  signal cnt_utime    : std_logic_vector (31 downto 0) := (others => '0');
  signal cnt_ctime    : std_logic_vector (26 downto 0) := (others => '0');
  signal cnt_timer    : std_logic_vector (3  downto 0) := "0000";
  signal cnt_revoclk  : std_logic_vector (10 downto 0) := "10100000000";
  signal sig_reset    : std_logic := '0';
  signal cnt_divseq1  : std_logic_vector (6  downto 0) := (others => '0');
  signal cnt_divseq2  : std_logic_vector (6  downto 0) := (others => '0');
  signal cnt_dbg1     : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_dbg2     : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_dbg3     : std_logic_vector (7  downto 0) := (others => '0');
  signal buf_dbg4     : std_logic_vector (7  downto 0) := (others => '0');
  signal buf_myaddr   : std_logic_vector (19 downto 0) := DEFADDR;
  signal reg_clkfreq  : std_logic_vector (26 downto 0) := "111" & x"95297f";
  signal seq_entagerr : std_logic := '0';
  signal seq_reset    : std_logic := '0';
begin
  -- in
  buf_bcast <= payload(76);
  buf_ttcmd <= payload(75 downto 64);
  buf_bdata <= payload(63 downto 0);
  buf_adata <= payload(43 downto 0);
  buf_addr  <= payload(63 downto 44);
  reg_clkfreq <= ("111" & buf_clkfreq) - 1;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- check valid payload
      if staoctet = '0' then
        cnt_packet <= "00010000";
        sta_link   <= '0';
        cnt_dbg1 <= cnt_dbg1 + 1;
      elsif sigidle = '1' and cnt_packet /= 255 then
        cnt_packet <= cnt_packet + 1;
      elsif sigpayload = '1' then
        if buf_bcast = '1' and buf_ttcmd = TTCMD_SYNC then
          if cnt_packet = 15 or cnt_packet = 255 then
            cnt_packet <= (others => '0');
            sta_link   <= '1';
          elsif cnt_packet(3 downto 0) = 15 then
            cnt_packet <= cnt_packet + 1;
            sta_link   <= '0';
            cnt_dbg2 <= cnt_dbg2 + 1;
          else
            cnt_packet <= "00010000";
            sta_link   <= '0';
            cnt_dbg3 <= cnt_dbg3 + 1;
          end if;
        elsif cnt_packet /= 255 then
          cnt_packet <= cnt_packet + 1;
        end if;
      end if;

      -- buf_myaddr
      if sigpayload = '1' and buf_ttcmd = TTCMD_RST and
         buf_adata(38) = '1' then
        buf_myaddr <= buf_addr;
      end if;

      -- buf_clkfreq
      if sigpayload = '1' and buf_ttcmd = TTCMD_RST then
        buf_clkfreq <= buf_adata(23 downto 0);
      end if;
      
      -- feereset, gtpreset
      if sigpayload = '1' and buf_ttcmd = TTCMD_RST and
         (buf_bcast = '1' or buf_addr = buf_myaddr) then
        feereset <= buf_adata(43);
        b2lreset <= buf_adata(42);
        gtpreset <= buf_adata(41);
        incdelay <= buf_adata(40);
        caldelay <= buf_adata(39);
      else
        feereset <= '0';
        b2lreset <= '0';
        gtpreset <= '0';
        incdelay <= '0';
        caldelay <= '0';
      end if;

      -- entagerr (don't care bcast or myaddr)
      if seq_reset = '1' and sig_reset = '0' then
        entagerr <= seq_entagerr;
      elsif sigpayload = '1' and buf_ttcmd = TTCMD_RST then
        seq_entagerr <= buf_adata(37);
      end if;
      seq_reset <= sig_reset;

      -- sig_reset, sig_frame, sig_frame3, sig_frame9
      if sigpayload = '1' and buf_bcast = '1' and buf_ttcmd = TTCMD_SYNC and
        (cnt_packet = 15 or cnt_packet = 255) then
        sig_reset  <= buf_bdata(63);
        sig_frame  <= '1';
        sig_frame3 <= buf_bdata(62);
        sig_frame9 <= buf_bdata(61);
      else
        sig_reset  <= '0';
        sig_frame  <= '0';
        sig_frame3 <= '0';
        sig_frame9 <= '0';
      end if;

      -- divclk1
      if (sigpayload = '1' and buf_bcast = '1' and buf_ttcmd = TTCMD_SYNC and
          buf_bdata(61) = '1' and cnt_packet(3 downto 0) = 15) or
         cnt_divseq1 = 0 then
        cnt_divseq1 <= std_logic_vector(to_unsigned(CLKDIV1 - 1, 7));
        if CLKDIV1 = 0 then
          divclk1 <= "00";
        elsif CLKDIV1 = 1 then
          divclk1 <= "10";
        else
          divclk1 <= "11";
        end if;
      else
        if cnt_divseq1 < (CLKDIV1 + 0) / 2 then
          divclk1(1) <= '0';
        end if;
        if cnt_divseq1 < (CLKDIV1 + 1) / 2 then
          divclk1(0) <= '0';
        end if;
        
        cnt_divseq1 <= cnt_divseq1 - 1;
      end if;
          
      -- divclk2
      if (sigpayload = '1' and buf_bcast = '1' and buf_ttcmd = TTCMD_SYNC and
          buf_bdata(61) = '1' and cnt_packet(3 downto 0) = 15) or
         cnt_divseq2 = 0 then
        cnt_divseq2 <= std_logic_vector(to_unsigned(CLKDIV2 - 1, 7));
        if CLKDIV2 = 0 then
          divclk2 <= "00";
        elsif CLKDIV2 = 1 then
          divclk2 <= "10";
        else
          divclk2 <= "11";
        end if;
      else
        if cnt_divseq2 < (CLKDIV2 + 0) / 2 then
          divclk2(1) <= '0';
        end if;
        if cnt_divseq2 < (CLKDIV2 + 1) / 2 then
          divclk2(0) <= '0';
        end if;
        
        cnt_divseq2 <= cnt_divseq2 - 1;
      end if;
          
      -- buf_utime, buf_ctime, cnt_timer
      if sigpayload = '1' and buf_bcast = '1' and buf_ttcmd = TTCMD_SYNC and
        (cnt_packet = 15 or cnt_packet = 255) then
        buf_utime <= buf_bdata(58 downto 27);
        buf_ctime <= buf_bdata(26 downto  0);
        cnt_timer <= "0110";
      elsif cnt_timer /= 0 then
        cnt_timer <= cnt_timer - 1;
      end if;

      -- cnt_utime, cnt_ctime
      if cnt_timer = 1 then
        cnt_utime <= buf_utime;
        cnt_ctime <= buf_ctime;
      elsif cnt_ctime = reg_clkfreq then
        cnt_utime <= cnt_utime + 1;
        cnt_ctime <= (others => '0');
      else
        cnt_ctime <= cnt_ctime + 1;
      end if;

      -- sta_timerr
      if sig_reset = '1' then
        timerr <= '0';
      elsif cnt_timer = 1 and 
        (cnt_utime /= buf_utime or cnt_ctime /= buf_ctime + 1) then
        timerr <= '1';
      end if;
      
      -- cnt_revoclk
      if cnt_timer = 1 then
        cnt_revoclk <= (others => '0');
      elsif cnt_revoclk /= 1280 then
        cnt_revoclk <= cnt_revoclk + 1;
      end if;
    end if; -- event
  end process;

  -- out
  stalink    <= sta_link;
  cntpacket  <= cnt_packet;
  utime      <= cnt_utime;
  ctime      <= cnt_ctime;
  cntrevoclk <= cnt_revoclk;
  runreset   <= sig_reset;
  frame      <= sig_frame;
  frame9     <= sig_frame9;
  myaddr     <= buf_myaddr;
  dbg <= cnt_dbg1 & x"0" & cnt_dbg2 & x"0" & cnt_dbg3;
  
end implementation;
------------------------------------------------------------------------
-- - b2tt_detag
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_detag is
  port (
    -- input
    clock      : in  std_logic;
    cntrevoclk : in  std_logic_vector (10 downto 0);
    en         : in  std_logic;
    runreset   : in  std_logic;
    entagerr   : in  std_logic;
    trgtag     : in  std_logic_vector (31 downto 0);
    sigpayload : in  std_logic;
    payload    : in  std_logic_vector (76 downto 0);
    exprun     : out std_logic_vector (31 downto 0);
    dbg        : out std_logic_vector (31 downto 0);
    tagerr     : out std_logic );
end b2tt_detag;

architecture implementation of b2tt_detag is
  signal sig_reset    : std_logic := '0';
  signal sig_bcast    : std_logic := '0';
  signal buf_ttcmd    : std_logic_vector (11 downto 0) := (others => '0');
  signal buf_bdata    : std_logic_vector (63 downto 0) := (others => '0');
  signal sig_runreset : std_logic := '0';
  signal buf_cnttrig  : std_logic_vector (31 downto 0) := (others => '1');
  signal cnt_revoclk  : std_logic_vector (10 downto 0) := "11111111111";
  signal buf_exprun   : std_logic_vector (31 downto 0) := x"87654321"; --dbg

  signal cnt_dbg : std_logic_vector (7 downto 0) := (others => '0');
begin
  
  -- in
  sig_bcast <= payload(76) and en and sigpayload;
  buf_ttcmd <= payload(75 downto 64);
  buf_bdata <= payload(63 downto 0);

  -- proc
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- buf_cnttrig
      if runreset = '1' then
        buf_cnttrig <= (others => '1');
      elsif cntrevoclk = 1278 then
        buf_cnttrig <= trgtag;
      end if;

      -- tagerr / exprun
      -- [buf_data: (8-bit expno) (12-bit runno) (12-bit subno) (32-bit tag)]
      if runreset = '1' then
        buf_exprun <= (others => '0');
        tagerr <= '0';
        dbg <= (others => '0');
      elsif sig_bcast = '1' and buf_ttcmd = TTCMD_TTAG then
        buf_exprun <= buf_bdata(63 downto 32);
        --f_exprun <= cnt_dbg & buf_bdata(63-8 downto 32);
        cnt_dbg <= cnt_dbg + 1;
        if buf_bdata(31 downto 0) /= buf_cnttrig then
          tagerr <= entagerr;
          dbg <= buf_bdata(15 downto 0) & buf_cnttrig(15 downto 0);
        end if;
      end if;
      
    end if; -- event
  end process;

  -- out
  exprun <= buf_exprun;

end implementation;

------------------------------------------------------------------------
-- - b2tt_decode
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_decode is
  generic (
    FLIPTRG : std_logic := '0';
    DEFADDR : std_logic_vector (19 downto 0) := x"00000";
    CLKDIV1 : integer range 0 to 72;
    CLKDIV2 : integer range 0 to 72 );
  port (
    -- input
    clock      : in  std_logic; -- 127 MHz
    invclock   : in  std_logic; -- 127 MHz inverted
    en         : in  std_logic; -- clock is locked
    trgp       : in  std_logic; -- directly from RJ-45 or SFP
    trgn       : in  std_logic;
    
    -- system time
    utime      : out std_logic_vector (31 downto 0); -- unit: second
    ctime      : out std_logic_vector (26 downto 0); -- unit: clock
    timerr     : out std_logic;
    
    -- exp- / run-number, my address
    exprun     : out std_logic_vector (31 downto 0);
    myaddr     : out std_logic_vector (19 downto 0);
    
    -- reset out
    runreset   : out std_logic; -- one clock long
    feereset   : out std_logic; -- one clock long
    b2lreset   : out std_logic; -- one clock long
    gtpreset   : out std_logic; -- one clock long
    
    -- trigger out
    trgout     : out std_logic; -- one clock long
    trgtyp     : out std_logic_vector (3  downto 0); -- available at trgout
    trgtag     : out std_logic_vector (31 downto 0); -- available at trgout
    tagerr     : out std_logic; -- error, held until runreset
    trgshort   : out std_logic; -- error, held until runreset
    
    -- status out
    staoctet   : out std_logic; -- H: valid K-symbols found for 80 clocks
    stalink    : out std_logic; -- H: valid packet found for 256*1280 clocks
    cntlinkrst : out std_logic_vector (7  downto 0); -- number of link reset
    
    -- revolution signal and reduced clock output
    frame      : out std_logic;
    frame9     : out std_logic;
    cntrevoclk : out std_logic_vector (10 downto 0);
    divclk1    : out std_logic_vector (1  downto 0);
    divclk2    : out std_logic_vector (1  downto 0);
    
    -- data out (may be or may not be useful)
    octet      : out std_logic_vector (7  downto 0);
    isk        : out std_logic;
    payload    : out std_logic_vector (76 downto 0);
    sigpayload : out std_logic;
    sigidle    : out std_logic;
    cntbit2    : out std_logic_vector (2  downto 0);
    cntpacket  : out std_logic_vector (7  downto 0);
    
    -- debug input to investigate link condition
    manual     : in  std_logic;
    clrdelay   : in  std_logic;
    sigdelay   : in  std_logic;
    regslip    : in  std_logic;
    decdelay   : in  std_logic;
    caldelay   : in  std_logic;
    
    -- debug output to investigate link condition
    staslip    : out std_logic;
    bitddr     : out std_logic;
    bit2       : out std_logic_vector (1  downto 0);
    bit10      : out std_logic_vector (9  downto 0);
    cntslip    : out std_logic_vector (1  downto 0);
    cntdelay   : out std_logic_vector (11 downto 0);
    comma      : out std_logic;
    dbg        : out std_logic_vector (31 downto 0);
    dbg2       : out std_logic_vector (31 downto 0) );
  
end b2tt_decode;
------------------------------------------------------------------------
architecture implementation of b2tt_decode is
  -- cnt_bit2:  (3-bit) 0..4 if in sync, 5 if out of sync
  -- cnt_octet:  (5-bit) 0..16 to count any octet in a packet (=16 alt.comma)
  -- cnt_packet: (8-bit) 0..15 to count packet in a revo frame (>15 not sync)
  -- cnt_revoclk: (11-bit) 0..1279 to locate position in a frame
  signal cnt_bit2      : std_logic_vector (2  downto 0) := "101";
  signal cnt_packet    : std_logic_vector (7  downto 0) := "00010000";
  signal cnt_revoclk   : std_logic_vector (10 downto 0) := "10100000000";

  signal buf_octet     : std_logic_vector (7  downto 0) := x"00";
  signal buf_isk       : std_logic := '0';
  signal sig_comma     : std_logic := '0';
  signal sta_link      : std_logic := '0';
  signal sta_octet     : std_logic := '0';

  signal sig_bitddr    : std_logic := '0';
  signal sig_bit2      : std_logic_vector (1  downto 0) := "00";
  signal sig_bit10     : std_logic_vector (9  downto 0) := (others => '0');
  signal sig_slip      : std_logic := '0';

  signal reg_autoslip  : std_logic := '0';
  signal reg_incdelay  : std_logic := '0';
  signal sig_incdelay  : std_logic := '0';
  signal sig_inccmd    : std_logic := '0';
  signal sig_calcmd    : std_logic := '0';  -- spartan6 only
  signal sig_caldelay  : std_logic := '0';  -- spartan6 only
  
  signal sig_newcomma  : std_logic := '0';

  signal sig_payload   : std_logic := '0';
  signal sig_idle      : std_logic := '0';
  signal cnt_delay     : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_slip      : std_logic_vector (1  downto 0) := "00";
  signal buf_payload   : std_logic_vector (76 downto 0) := (others => '0');
  
  signal sig_trig      : std_logic := '0';
  signal sta_trgtag    : std_logic_vector (31 downto 0) := (others => '0');
  signal sig_utime     : std_logic_vector (31 downto 0) := (others => '0');
  signal sig_ctime     : std_logic_vector (26 downto 0) := (others => '0');

  signal sig_runreset  : std_logic := '0';
  
  signal sta_entagerr  : std_logic := '0';

  signal open_trdbg    : std_logic_vector (31 downto 0) := (others => '0');
  signal open_padbg    : std_logic_vector (31 downto 0) := (others => '0');
begin

  -- in
  reg_autoslip <= not manual;
  reg_incdelay <= sigdelay when manual = '1' else
                  (sigdelay or sig_incdelay or sig_inccmd);
  sig_caldelay <= caldelay or sig_calcmd;

  proc_cntslip: process (clock)
  begin
    if clock'event and clock = '1' then
      if sig_slip = '1' then
        cnt_slip <= cnt_slip + 1;
      end if;
    end if;
  end process;
  
  map_is: entity work.b2tt_iddr
    generic map ( FLIPIN  => FLIPTRG )
    port map ( clock      => clock,
               invclock   => invclock,
               inp        => trgp,
               inn        => trgn,
               incdelay   => reg_incdelay,
               clrdelay   => clrdelay,
               sigslip    => sig_slip,
               enslip     => regslip,
               autoslip   => reg_autoslip,
               decdelay   => decdelay,      -- debug only
               caldelay   => sig_caldelay,  -- spartan6 only
               staslip    => staslip,       -- out
               bitddr     => sig_bitddr,    -- out
               bit2       => sig_bit2,      -- out
               cntdelay   => cnt_delay );   -- out

  map_nd: entity work.b2tt_decomma
    port map ( en        => en,
               bit2      => sig_bit2,
               prev8     => sig_bit10(7 downto 0),
               cntbit2   => cnt_bit2,
               comma     => sig_comma,      -- out/async for debit2
               newcomma  => sig_newcomma ); -- out/async for debit2
  
  map_2b: entity work.b2tt_debit2
    port map ( clock      => clock,
               en         => en,
               newcomma   => sig_newcomma,
               comma      => sig_comma,
               bit2       => sig_bit2,
               bit10      => sig_bit10,    -- out
               cntbit2    => cnt_bit2,     -- out
               sigslip    => sig_slip );   -- out

  map_10: entity work.b2tt_debit10
    port map ( clock      => clock,
               cntbit2    => cnt_bit2,
               bit2       => sig_bit2,     -- to skip one clock wait for 10b
               bit10      => sig_bit10,
               octet      => buf_octet,    -- out/async for detrig/deoctet
               isk        => buf_isk );    -- out/async for detrig/deoctet

  map_tr: entity work.b2tt_detrig
    port map ( clock      => clock,
               en         => sta_link,
               runreset   => sig_runreset,
               cntbit2    => cnt_bit2,
               octet      => buf_octet,
               isk        => buf_isk,
               trgout     => sig_trig,     -- out
               trgtyp     => trgtyp,       -- out
               trgtag     => sta_trgtag,   -- out
               trgshort   => trgshort,     -- out
               dbg        => open_trdbg ); -- out

  map_oc: entity work.b2tt_deoctet
    port map ( clock      => clock,
               cntbit2    => cnt_bit2,
               octet      => buf_octet,
               isk        => buf_isk,
               staoctet   => sta_octet,    -- out
               sigpayload => sig_payload,  -- out
               sigidle    => sig_idle,     -- out
               incdelay   => sig_incdelay, -- out
               cntlinkrst => cntlinkrst,   -- out
               payload    => buf_payload,  -- out
               cnterr     => dbg2 );       -- out

  map_pa: entity work.b2tt_depacket
    generic map ( CLKDIV1 => CLKDIV1,
                  CLKDIV2 => CLKDIV2,
                  DEFADDR => DEFADDR )
    port map ( clock      => clock,
               staoctet   => sta_octet,
               sigpayload => sig_payload,
               sigidle    => sig_idle,
               payload    => buf_payload,
               myaddr     => myaddr,       -- out
               frame      => frame,        -- out
               frame9     => frame9,       -- out
               divclk1    => divclk1,      -- out
               divclk2    => divclk2,      -- out
               cntpacket  => cnt_packet,   -- out
               utime      => sig_utime,    -- out
               ctime      => sig_ctime,    -- out
               cntrevoclk => cnt_revoclk,  -- out
               runreset   => sig_runreset, -- out
               feereset   => feereset,     -- out
               b2lreset   => b2lreset,     -- out
               gtpreset   => gtpreset,     -- out
               incdelay   => sig_inccmd,   -- out
               caldelay   => sig_calcmd,   -- out
               entagerr   => sta_entagerr, -- out
               stalink    => sta_link,     -- out
               timerr     => timerr,       -- out
               dbg        => open_padbg ); -- out
  
  map_tt: entity work.b2tt_detag
    port map ( clock      => clock,
               cntrevoclk => cnt_revoclk,
               en         => sta_link,
               entagerr   => sta_entagerr,
               runreset   => sig_runreset,
               trgtag     => sta_trgtag,
               sigpayload => sig_payload,
               payload    => buf_payload,
               exprun     => exprun,       -- out
               dbg        => dbg,          -- out
               tagerr     => tagerr );     -- out

  -- out (async)
  isk        <= buf_isk;
  octet      <= buf_octet;
  
  -- out

  -- staoctet='1' when a valid comma is found
  -- stalink='1'  when >255 continuously valid packets are found
  staoctet   <= sta_octet;
  stalink    <= sta_link;
  runreset   <= sig_runreset;
  
  cntdelay   <= cnt_delay;
  cntbit2    <= cnt_bit2;
  cntpacket  <= cnt_packet;
  comma      <= sig_comma;
  bitddr     <= sig_bitddr;
  bit2       <= sig_bit2;
  bit10      <= sig_bit10;
  cntslip    <= cnt_slip;
  payload    <= buf_payload;
  sigpayload <= sig_payload;
  sigidle    <= sig_idle;

  trgout     <= sig_trig;
  trgtag     <= sta_trgtag;
  utime      <= sig_utime;
  ctime      <= sig_ctime;
  cntrevoclk <= cnt_revoclk;

  --dbg <= sta_link & sta_octet & cnt_bit2(1 downto 0) & sig_payload & cnt_slip(0);
  --dbg <= sta_link & sta_octet & sig_comma & reg_incdelay & sig_slip & sig_bitddr;
  
end implementation;

-- - emacs outline mode setup
-- Local Variables: ***
-- mode:outline-minor ***
-- outline-regexp:"-- -+" ***
-- End: ***
