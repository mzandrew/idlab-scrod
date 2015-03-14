------------------------------------------------------------------------
--
--  m_encode.vhd -- encoder for TTD master
--
--  Mikihiko Nakao, KEK IPNS
--
--
--  20120121 rewritten
--           based on http://en.wikipedia.org/wiki/8b/10b_encoding
--  20130513 utime is taken out
--  20130528 fixes based on c-model
--  20130626 revoout
--  20140108 rename: runstart -> trgstart
--  20140403 no iscomma out
--
--  eout bit 9 is first transmitted, bit 0 is last transmitted
--  ein  bit 9 is first received,    bit 0 is last received
--
--
--  cnt_encode (0 to 4)  incremented every clock to make an octet to 8b10b
--  cnt_octet  (0 to 15) incremented every 5 clocks to make a packet (16 octet)
--  cnt_packet (0 to 15) incremented every 80 clocks to make a turn (16 packet)
--  
--  trigger octet <= '1' & tim(3-bit) & typ(4-bit)
--    [1 octet <= 5 clock(3-bit), sub-timing to get 2ns is part of typ]
--  data octet    <= '0' & info(7-bit)
--
--  address <= dist1(5-bit) & dist2(5-bit) & dist3(5-bit) & dist4(5-bit)
--
--  data packet <= comma & payload & (filler) & (trigger)
--  comma:   either at the first (K28.1) or second octet (K28.5)
--  payload: 11 data octets, 77 bits
--  trigger: up to 4 octets, each separated by more than 4 octets
--  filler:  up to 4 octets, to make the data packet 16 octets (K28.3)
--
--  payload <= broadcast & command & (sub-command) & (address) & data
--  broadcast: 1 bit, '1' for broadcast, '0' for point-to-point
--  command:   12 bit
--  address:   20 bit
--  data:      64 bit for broadcast, 44 bit for point-to-point
--
--  address <= dist1 & dist2 & dist3 & dist4
--  each dist is
--    0:      to this
--    1..20:  to one of 20 RJ-45 ports
--    21..28: to one of 8 optical ports
--    29,30:  reserved
--    31:     to all ports
--  (examples:
--     [01][00][00][00] 2nd level node at RJ-45 port 1
--     [01][02][31][00] all 4th level nodes under port 1-port 2 chain
--     [01][31][31][31] all 5th leval nodes under port 1)
--
--  idle command
--    broadcast, command = 0x000
--    
--  trigger tag command
--    broadcast, command = 0x001, data
--    exp 8-bit run 12-bit subrun 12-bit event 32-bit
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- - m_en2bit
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_en2bit is
  port ( 
    clock   : in  std_logic;
    counter : in  std_logic_vector (2 downto 0);  -- 0 to 4
    octet   : in  std_logic_vector (7 downto 0);
    isk     : in  std_logic;
    bit2    : out std_logic_vector (1 downto 0);
    validk  : out std_logic;
    rdnext  : out std_logic );
end m_en2bit;
------------------------------------------------------------------------
architecture implementation of m_en2bit is
  signal sig_en     : std_logic := '0';
  signal buf_10b    : std_logic_vector (9 downto 0) := "0000000000";
  signal seq_10b    : std_logic_vector (7 downto 0) := "00000000";
  signal buf_reset  : std_logic := '0';
  signal sig_reset  : std_logic := '0';
  signal buf_validk : std_logic := '0';
  signal open_rd6p  : std_logic := '0';
  signal open_rd4p  : std_logic := '0';
begin

  -- in
  sig_en <= '1' when counter = 3 else '0';
  
  map_en8b10b: entity work.b2tt_en8b10b
    port map (
      reset   => '0',
      clock   => clock,
      en      => sig_en,
      isk     => isk,
      din     => octet,
      eout    => buf_10b,
      validk  => validk, -- out
      rdnext  => rdnext, -- out
      rd6psav => open_rd6p,   -- out
      rd4psav => open_rd4p ); -- out

  -- out (async)
  bit2 <= buf_10b(9 downto 8) when counter = 3 else seq_10b(7 downto 6);

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if counter = 3 then
        seq_10b <= buf_10b(7 downto 0);
      else
        seq_10b <= seq_10b(5 downto 0) & "00";
      end if;
    end if;
  end process;
  
end implementation;
------------------------------------------------------------------------
-- - m_enoctet
--   build a trigger- and data-octet from trigger and payload
--   trigtyp: 4 bit trigger type including 2-bit fine timing (2 ns unit)
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_enoctet is
  port (
    cntpay : out std_logic_vector (3 downto 0);
    cntsub : out std_logic_vector (3 downto 0);
    clock      : in  std_logic;
    runreset   : in  std_logic;
    cntencode  : in  std_logic_vector (2 downto 0);
    cntoctet   : in  std_logic_vector (3 downto 0);
    trigin     : in  std_logic;
    trigtyp    : in  std_logic_vector (3 downto 0);
    setdata    : in  std_logic;
    setsub     : in  std_logic;
    payload    : in  payload_t;
    octet      : out octet_t;
    isk        : out std_logic;
    subo       : out octet_t;
    subk       : out std_logic;
    trigout    : out std_logic;
    trigshort  : out std_logic );
end m_enoctet;
------------------------------------------------------------------------
architecture implementation of m_enoctet is
  signal seq_trigin  : std_logic_vector (1 downto 0) := "00";
  signal buf_trigtyp : trigtyp_t                     := TTYP_NONE;
  signal buf_trigtim : std_logic_vector (2 downto 0) := "000";
  signal cnt_trigspc : std_logic_vector (4 downto 0) := "10111";  -- (=23)
  signal buf_isk     : std_logic := '0';
  signal buf_octet   : octet_t := x"00";
  signal cnt_payload : std_logic_vector (3 downto 0) := "0000";
  signal buf_subk    : std_logic := '0';
  signal buf_subo    : octet_t := x"00";
  signal cnt_subload : std_logic_vector (3 downto 0) := "0000";
  signal buf_payload : payload_t := (others => '0');

  signal sta_crc8  : std_logic_vector (7 downto 0) := x"00";
  signal sta_sub8  : std_logic_vector (7 downto 0) := x"00";
  subtype byte_t is  std_logic_vector (7 downto 0);

  -- from crc8.vhd and comlib.vhd of
  -- http://opencores.org/project,w11
  -- 0x4d (x8 + x6 + x3 + x2 + 1)   [ shr 1 makes 0xa6 ]
  function crc8_update
    ( crc:  in byte_t; data: in byte_t ) return byte_t is
    variable t : byte_t := (others => '0');
    variable n : byte_t := (others => '0');
  begin
    t := data xor crc;
    n(0) := t(5) xor t(4) xor t(2) xor t(0);
    n(1) := t(6) xor t(5) xor t(3) xor t(1);
    n(2) := t(7) xor t(6) xor t(5) xor t(0);
    n(3) := t(7) xor t(6) xor t(5) xor t(4) xor t(2) xor t(1) xor t(0);
    n(4) := t(7) xor t(6) xor t(5) xor t(3) xor t(2) xor t(1);
    n(5) := t(7) xor t(6) xor t(4) xor t(3) xor t(2);
    n(6) := t(7) xor t(3) xor t(2) xor t(0);
    n(7) := t(4) xor t(3) xor t(1);
    return n;
  end function crc8_update;
  
begin
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- fill payload
      if cnt_payload = 0 and setdata = '1' then
        buf_payload <= payload;
        cnt_payload <= "1011"; -- (=11)
      elsif cnt_payload /= 0 and cntencode = 1 and
            buf_isk = '0' and buf_octet(7) = '0' then
        buf_payload <= buf_payload(69 downto 0) & "0000000";
        cnt_payload <= cnt_payload - 1;
      end if;

      -- sub payload counter
      if cnt_subload = 0 and setsub = '1' then
        cnt_subload <= "1011"; -- (=11)
      elsif cnt_subload /= 0 and cntencode = 2 and
            buf_isk = '0' and buf_octet(7) = '0' then
        cnt_subload <= cnt_subload - 1;
      end if;

      -- data to encode
      if cntencode = 0 then
        if seq_trigin = "01" and cnt_trigspc = 23 then
          buf_isk   <= '0';
          buf_octet <= '1' & "101" & trigtyp;  -- buf_trigtim = 5
        elsif buf_trigtim /= 0 then
          buf_isk   <= '0';
          buf_octet <= '1' & buf_trigtim & buf_trigtyp;
        elsif cntoctet = 0 then
          buf_isk   <= '1';
          buf_octet <= K28_1;           -- comma
        elsif buf_isk = '0' and buf_octet(7) = '1' and cntoctet = 1 then
          -- octet 0 was trig
          buf_isk   <= '1';
          buf_octet <= K28_5;           -- alternative comma
        elsif cnt_payload = 0 and cntoctet = 15 then
          buf_isk   <= '0';
          buf_octet <= '0' & sta_crc8(6 downto 0);
        elsif cnt_payload = 0 then
          buf_isk   <= '1';
          buf_octet <= K28_3;           -- idle
        else
          buf_isk   <= '0';
          buf_octet <= '0' & buf_payload(76 downto 70);
        end if;
      end if;

      -- sub data to encode
      if cntencode = 1 then
        if buf_isk = '0' and buf_octet(7) = '1' then
          buf_subk <= '0';
          buf_subo <= buf_octet;
        elsif buf_isk = '1' then
          buf_subk <= '1';
          buf_subo <= buf_octet; -- K28_1, K28_5, K28_3
        elsif cnt_subload = 0 and cntoctet = 15 then
          buf_subk <= '0';
          buf_subo <= '0' & sta_sub8(6 downto 0);
        elsif cnt_subload = 0 then
          buf_subk <= '1';
          buf_subo <= K28_3;
        else
          buf_subk <= buf_isk;
          buf_subo <= buf_octet;
        end if;
      end if;

      -- crc8
      if cntencode = 1 then
        if cntoctet = 0 then
          sta_crc8 <= crc8_update(x"00", buf_octet);
        else
          sta_crc8 <= crc8_update(sta_crc8, buf_octet);
        end if;
      end if;
      
      -- sub crc8
      if cntencode = 2 then
        if cntoctet = 0 then
          sta_sub8 <= crc8_update(x"00", buf_subo);
        else
          sta_sub8 <= crc8_update(sta_sub8, buf_subo);
        end if;
      end if;
      
      -- trigger signal generation
      if seq_trigin = "01" and cnt_trigspc = 23 then
        trigout <= '1';
      else
        trigout <= '0';
      end if;

      -- trigger type generation
      if seq_trigin = "01" and cnt_trigspc = 23 then
        buf_trigtyp <= trigtyp;
      elsif cntencode = 0 then
        buf_trigtyp <= TTYP_NONE;
      end if;
      
      -- trigger timing detection
      if seq_trigin = "01" and cnt_trigspc = 23 then
        buf_trigtim <= cntencode;
      elsif cntencode = 0 then
        buf_trigtim <= (others => '0');
      end if;
      
      -- trigger space counting
      if seq_trigin = "01" and cnt_trigspc = 23 then
        cnt_trigspc <= (others => '0');
      elsif cnt_trigspc /= 23 then
        cnt_trigspc <= cnt_trigspc + 1;
      end if;
      
      -- short trigger space detection
      --   should have been checked in m_gentrig and should not happen here
      --   so can be cleared only by runreset
      if runreset = '1' then
        trigshort <= '0';
      elsif seq_trigin = "01" and cnt_trigspc /= 23 then
        trigshort <= '1';
      end if;

      -- trigger edge detection
      seq_trigin <= seq_trigin(0) & trigin;
      
    end if;
  end process;

  -- out
  octet <= buf_octet;
  isk   <= buf_isk;
  subo  <= buf_subo;
  subk  <= buf_subk;
  cntpay <= cnt_payload;
  cntsub <= cnt_subload;

end implementation;
------------------------------------------------------------------------
-- - m_enreset
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_enreset is
  generic ( PACKET : integer := 15 );
  port ( clock : in  std_logic;
         i     : in  std_logic;
         seq   : out std_logic_vector (1 downto 0);
         cnt2  : in  std_logic_vector (2 downto 0);
         cnto  : in  std_logic_vector (3 downto 0);
         cntp  : in  std_logic_vector (3 downto 0) );
end m_enreset;
architecture implementation of m_enreset is
  signal sig_seq : std_logic_vector (1 downto 0) := "00";
begin
  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      --   Reset signal stays for one frame cycle
      --   There is 80 clock difference between here and remote
      --   
      if i = '1' then
        sig_seq <= "01";
      elsif cnt2 = 0 and cnto = 0 then
        if cntp = PACKET then
          sig_seq <= sig_seq(0) & sig_seq(0);
        elsif cntp = 0 and sig_seq(1) = '1' then
          sig_seq <= "10";
        end if;
      end if;
    end if; -- event
  end process;

  -- out
  seq <= sig_seq;
  
end implementation;
------------------------------------------------------------------------
-- - m_enpacket
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_enpacket is
  generic (
    B2TTVER     : integer := 0 );
  port (
    clock       : in  std_logic;
    locked      : in  std_logic;
    cntbit2     : in  std_logic_vector (2 downto 0);
    cntoctet    : in  std_logic_vector (3 downto 0);
    cntpacket   : in  std_logic_vector (3 downto 0);
    frame3      : in  std_logic;
    frame9      : in  std_logic;
    disparity   : in  std_logic;
    subparity   : in  std_logic;
    selreset    : in  std_logic;
    runreset    : in  std_logic;
    stareset    : in  std_logic;
    trgstart    : in  std_logic;
    feereset    : in  std_logic;
    b2lreset    : in  std_logic;
    gtpreset    : in  std_logic;
    incdelay    : in  std_logic;
    caldelay    : in  std_logic;
    notagerr    : in  std_logic;
    cmdaddr     : in  std_logic_vector (19 downto 0);
    setaddr     : in  std_logic;
    cmdhi       : in  std_logic_vector (11 downto 0);
    cmdlo       : in  std_logic_vector (31 downto 0);
    setcmd      : in  std_logic;
    trigout     : in  std_logic;
    utime       : in  std_logic_vector (31 downto 0);

    ctime       : in  std_logic_vector (26 downto 0);
    clkfreq     : in  std_logic_vector (23 downto 0);
    utimer      : in  std_logic_vector (31 downto 0);
    ctimer      : in  std_logic_vector (26 downto 0);
    exprun      : in  std_logic_vector (31 downto 0);
    starunreset : out std_logic;
    sigstart    : out std_logic;
    payload     : out payload_t;
    setdata     : out std_logic;
    setsub      : out std_logic );
end m_enpacket;
------------------------------------------------------------------------
architecture implementation of m_enpacket is
  signal cnt_trig     : std_logic_vector (31 downto 0) := x"00000000";
  signal buf_cmd      : ttcmd_t   := TTCMD_IDLE;
  signal buf_bcast    : std_logic := '0';
  signal buf_data     : std_logic_vector (63 downto 0) := x"0000000000000000";
  signal buf_ttag     : std_logic_vector (31 downto 0) := x"00000000";
  signal seq_runreset : std_logic_vector (1  downto 0) := "00";
  signal seq_stareset : std_logic_vector (1  downto 0) := "00";
  signal seq_trgstart : std_logic_vector (1  downto 0) := "00";
  signal seq_sigstart : std_logic_vector (1  downto 0) := "00";
  signal seq_feereset : std_logic_vector (1  downto 0) := "00";
  signal seq_b2lreset : std_logic_vector (1  downto 0) := "00";
  signal seq_gtpreset : std_logic_vector (1  downto 0) := "00";
  signal seq_incdelay : std_logic_vector (1  downto 0) := "00";
  signal seq_caldelay : std_logic_vector (1  downto 0) := "00";
  signal seq_setaddr  : std_logic_vector (1  downto 0) := "00";
  signal seq_setcmd   : std_logic_vector (1  downto 0) := "00";
begin

  map_runreset: entity work.m_enreset
    generic map ( PACKET => 15 )
    port map ( clock => clock, i => runreset, seq => seq_runreset,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_trgstart: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => trgstart, seq => seq_trgstart,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_b2lreset: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => b2lreset, seq => seq_b2lreset,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_gtpreset: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => gtpreset, seq => seq_gtpreset,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_incdelay: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => incdelay, seq => seq_incdelay,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_caldelay: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => caldelay, seq => seq_caldelay,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_setaddr: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => setaddr, seq => seq_setaddr,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_stareset: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => stareset, seq => seq_stareset,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  map_setcmd: entity work.m_enreset
    generic map ( PACKET => 1 )
    port map ( clock => clock, i => setcmd, seq => seq_setcmd,
               cnt2 => cntbit2, cnto => cntoctet, cntp => cntpacket );
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- buf_ttag
      if locked = '0' or runreset = '1' then
        buf_ttag <= (others => '1');
      elsif cntbit2 = 0 and cntoctet = 0 and cntpacket = 0 then
        buf_ttag <= cnt_trig - 1;
      end if;

      -- cnt_trig
      if seq_runreset(0) = '1' then
        cnt_trig <= (others => '0');
      elsif trigout = '1' then
        cnt_trig <= cnt_trig + 1;
      end if;

      -- trgstart
      seq_sigstart <= seq_sigstart(0) & seq_trgstart(1);
      if seq_sigstart = "10" then
        sigstart <= '1';
      else
        sigstart <= '0';
      end if;

      -- setdata, buf_bcast, buf_cmd, buf_data
      if cntbit2 = 1 then
        if cntoctet = 0 then
          if cntpacket = 15 then
            setdata   <= '1';
            setsub    <= '1';
            buf_bcast <= '1';
            buf_cmd   <= TTCMD_SYNC;
            buf_data  <= seq_runreset(1) & frame3 & frame9 & "11" &
                         utimer & ctimer;
          elsif cntpacket = 7 then
            setdata   <= '1';
            setsub    <= '0';
            buf_bcast <= '1';
            buf_cmd   <= TTCMD_DISP;

            -- bit 62 is an arbitrary bit to align the disparity
            -- between bit2 and sub2 when they are different.
            -- found by manual scan (see commented-out code below)
            buf_data(63 downto 63)  <= (others => '0');
            buf_data(62) <= not (disparity xor subparity);
            buf_data(61 downto 0)  <= (others => '0');
            --buf_data(63) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(7);
            --buf_data(62) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(6);
            --buf_data(61) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(5);
            --buf_data(60) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(4);
            --buf_data(59) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(3);
            --buf_data(58) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(2);
            --buf_data(57) <= (disparity xor subparity xor regdisp(0))
            --                and regdisp(1);
            --buf_data(56 downto 0)  <= (others => '0');
          elsif cntpacket = 3 then
            setdata   <= seq_setcmd(1);
            setsub    <= '0';
            buf_bcast <= '0';
            buf_cmd   <= TTCMD_CMD;
            buf_data  <= cmdaddr & cmdhi & cmdlo;
          elsif cntpacket = 2 then
            setdata   <= '1';
            setsub    <= '0';
            buf_bcast <= not selreset;
            buf_cmd   <= TTCMD_RST;
            buf_data(63 downto 44) <= cmdaddr;
            buf_data(43) <= seq_feereset(1);
            buf_data(42) <= seq_b2lreset(1);
            buf_data(41) <= seq_gtpreset(1);
            buf_data(40) <= seq_incdelay(1);
            buf_data(39) <= seq_caldelay(1);
            buf_data(38) <= seq_setaddr(1);
            buf_data(37) <= not notagerr;
            buf_data(36) <= seq_stareset(1);
            buf_data(35 downto 0) <= (others => '0');
          elsif cntpacket = 1 then
            setdata   <= '1';
            setsub    <= '1';
            buf_bcast <= '1';
            buf_cmd   <= TTCMD_FREQ;
            buf_data(63 downto 34) <= (others => '0');
            buf_data(33 downto 24)
              <= std_logic_vector(to_unsigned(B2TTVER, 10));
            buf_data(23 downto  0) <= clkfreq;
          elsif cntpacket = 0 then
            setdata   <= '1';
            setsub    <= '1';
            buf_bcast <= '1';
            buf_cmd   <= TTCMD_TTAG;
            buf_data  <= exprun & buf_ttag;
          end if;
        else
          setdata <= '0';
          setsub  <= '0';
        end if;
      end if;
    end if;
      
  end process;

  -- out
  -- payload(76)           <= buf_bcast;
  -- payload(75 downto 64) <= buf_cmd;
  -- payload(63 downto  0) <= buf_data;
  payload <= buf_bcast & buf_cmd & buf_data;
  starunreset <= seq_runreset(1) or seq_runreset(0);
  
end implementation;
------------------------------------------------------------------------
-- - m_encounter
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_encounter is
  port (
    clock          : in  std_logic;
    plllock        : in  std_logic;
    revoin         : in  std_logic;
    setrevoref     : in  std_logic;
    revoref        : in  std_logic_vector (10 downto 0);
    cntclk         : out std_logic_vector (10 downto 0);
    cntbit2        : out std_logic_vector (2  downto 0);
    cntoctet       : out std_logic_vector (3  downto 0);
    cntpacket      : out std_logic_vector (3  downto 0);
    sigframe       : out std_logic;
    frame3         : out std_logic;
    frame9         : out std_logic;
    revoout        : out std_logic;
    cntnorevo      : out std_logic_vector (15 downto 0);
    revocand       : out std_logic_vector (10 downto 0);
    cntrevocand    : out std_logic_vector (15 downto 0);
    cntbadrevo     : out std_logic_vector (15 downto 0);
    locked         : out std_logic );
end m_encounter;

architecture implementation of m_encounter is
  -- cnt_plllock for first 1 msec / cnt_refclk up to 1279
  signal cnt_plllock  : std_logic_vector (17 downto 0) := (others => '0');
  signal cnt_refclk   : std_logic_vector (10 downto 0) := (others => '0');
  signal sta_plllock  : std_logic := '0';
  signal sta_reflock  : std_logic := '0';
  signal cnt_frame3   : std_logic_vector (1  downto 0) := "11";
  signal cnt_frame9   : std_logic_vector (3  downto 0) := "1111";
  signal cnt_bit2     : std_logic_vector (2  downto 0) := "111";
  signal cnt_octet    : std_logic_vector (3  downto 0) := "1111";
  signal cnt_packet   : std_logic_vector (3  downto 0) := "1111";

  signal cnt_norevo   : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_badrevo  : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_revocand : std_logic_vector (15 downto 0) := (others => '0');
  signal buf_revocand : std_logic_vector (10 downto 0) := "10100000000"; --1280
  
  signal reg_revoref1 : std_logic_vector (10 downto 0) := (others => '0');
begin
  -- in
  sta_plllock  <= cnt_plllock(cnt_plllock'left);
  reg_revoref1 <= revoref - 1 when revoref /= 0 else
                  std_logic_vector(to_unsigned(1279, 11));

  -- proc
  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      
      -- cnt_plllock
      if plllock = '0' then
        cnt_plllock <= (others => '0');
      elsif sta_plllock = '0' then
        cnt_plllock <= cnt_plllock + 1;
      end if;

      -- sta_reflock, cnt_refclk
      --   cnt_refclk loops over 0..1279, and phase is adjusted to
      --   revo if it is found in the first 1280 clocks.
      if sta_plllock = '0' then
        sta_reflock <= '0';
        cnt_refclk  <= std_logic_vector(to_unsigned(0, 11));
      elsif cnt_refclk = 1279 then
        sta_reflock <= '1';
        cnt_refclk  <= (others => '0');
      elsif sta_reflock = '0' and revoin = '1' then
        --sta_reflock <= '1';
        cnt_refclk  <= std_logic_vector(to_unsigned(1, 11));
      else
        cnt_refclk  <= cnt_refclk + 1;
      end if;

      -- locked, sigframe, frame9, cnt_frame9
      if sta_reflock = '0' then
        locked       <= '0';
        sigframe     <= '0';
        frame9       <= '0';
        frame3       <= '0';
        cnt_frame9   <= "1111";
        cnt_frame3   <= "11";
      elsif cnt_refclk = 1279 then
        locked       <= '1';
        sigframe     <= '1';
        if cnt_frame9(3) = '1' or cnt_frame3(1) = '1' then
          cnt_frame3 <= "00";
          frame3     <= '1';
        else
          cnt_frame3 <= cnt_frame3 + 1;
          frame3     <= '0';
        end if;
        if cnt_frame9(3) = '1' then
          cnt_frame9 <= "0000";
          frame9     <= '1';
        else
          cnt_frame9 <= cnt_frame9 + 1;
          frame9     <= '0';
        end if;
      else
        sigframe     <= '0';
      end if;
      
      -- cnt_bit2
      if sta_reflock = '0' and cnt_refclk /= 1279 then
        cnt_bit2 <= (others => '1');
      elsif cnt_bit2(2) = '1' then
        cnt_bit2 <= (others => '0');
      else
        cnt_bit2 <= cnt_bit2 + 1;
      end if;

      -- cnt_octet, cnt_packet
      if sta_reflock = '0' and cnt_refclk /= 1279 then
        cnt_packet <= (others => '1');
        cnt_octet  <= (others => '1');
      elsif cnt_bit2(2) = '1' then
        if cnt_octet = 15 then
          cnt_packet <= cnt_packet + 1;
        end if;
        cnt_octet <= cnt_octet + 1;
      end if;

      -- cnt_norevo, cnt_revocand, buf_revocand, buf_badrevo
      --   "revocand" is the new revolution position candidate,
      --   whereas "badrevo" is neither revoref nor revocand
      if sta_reflock = '0' or setrevoref = '1' then
        cnt_norevo   <= (others => '0');
        cnt_revocand <= (others => '0');
        cnt_badrevo  <= (others => '0');
        buf_revocand <= "10100000000"; -- 1280 (not set yet)
      elsif revoin = '0' then
        if cnt_refclk = revoref and cnt_norevo(cnt_norevo'left) = '0' then
          cnt_norevo <= cnt_norevo + 1;
        end if;
      elsif cnt_refclk = buf_revocand then
        if cnt_revocand(cnt_revocand'left) = '0' then
          cnt_revocand <= cnt_revocand + 1;
        end if;
      elsif cnt_refclk /= revoref then
        if buf_revocand = 1280 then
          buf_revocand <= cnt_refclk;
        elsif cnt_badrevo(cnt_badrevo'left) = '1' then
          cnt_badrevo <= cnt_badrevo + 1;
        end if;
      end if;

      -- revoout
      if sta_reflock = '1' and cnt_refclk = revoref then
        revoout <= '1';
      else
        revoout <= '0';
      end if;
      
    end if; -- event
  end process;

  -- out
  cntclk      <= cnt_refclk;
  cntbit2     <= cnt_bit2;
  cntoctet    <= cnt_octet;
  cntpacket   <= cnt_packet;
  cntnorevo   <= cnt_norevo;
  cntbadrevo  <= cnt_badrevo;
  cntrevocand <= cnt_revocand;
  revocand    <= buf_revocand;
  
end implementation;

------------------------------------------------------------------------
-- - m_encode
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_encode is
  generic (
    B2TTVER : integer := 0 );
  port (
    cntpay : out std_logic_vector (3 downto 0);
    cntsub : out std_logic_vector (3 downto 0);

    clock          : in  std_logic;
    cntreset       : in  std_logic;
    plllock        : in  std_logic;
    revoin         : in  std_logic;
    selreset       : in  std_logic;
    runreset       : in  std_logic;
    stareset       : in  std_logic;
    trgstart       : in  std_logic;
    feereset       : in  std_logic;
    b2lreset       : in  std_logic;
    gtpreset       : in  std_logic;
    incdelay       : in  std_logic;
    caldelay       : in  std_logic;
    notagerr       : in  std_logic;
    cmdaddr        : in  std_logic_vector (19 downto 0);
    setaddr        : in  std_logic;
    cmdhi          : in  std_logic_vector (11 downto 0);
    cmdlo          : in  std_logic_vector (31 downto 0);
    setcmd         : in  std_logic;
    exprun         : in  std_logic_vector (31 downto 0);
    trigin         : in  std_logic;
    trigtyp        : in  std_logic_vector (3  downto 0);
    utime          : in  std_logic_vector (31 downto 0);
    ctime          : in  std_logic_vector (26 downto 0);
    clkfreq        : in  std_logic_vector (23 downto 0);
    utimer         : in  std_logic_vector (31 downto 0);
    ctimer         : in  std_logic_vector (26 downto 0);

    starunreset    : out std_logic;
    sigstart       : out std_logic;
    bit2           : out std_logic_vector (1  downto 0);
    sub2           : out std_logic_vector (1  downto 0);
    bitrd          : out std_logic;
    subrd          : out std_logic;
    sigframe       : out std_logic;
    frame3         : out std_logic;
    frame9         : out std_logic;
    cntclk         : out std_logic_vector (10 downto 0);
    cntbit2        : out std_logic_vector (2  downto 0);
    cntoctet       : out std_logic_vector (3  downto 0);
    cntpacket      : out std_logic_vector (3  downto 0);
    octet          : out std_logic_vector (7  downto 0);
    isk            : out std_logic;
    subo           : out std_logic_vector (7  downto 0);
    subk           : out std_logic;
    revocand       : out std_logic_vector (10 downto 0);
    cntrevocand    : out std_logic_vector (15 downto 0);
    cntbadrevo     : out std_logic_vector (15 downto 0);
    cntnorevo      : out std_logic_vector (15 downto 0);
    trigshort      : out std_logic;
    revoout        : out std_logic );

end m_encode;
------------------------------------------------------------------------
architecture implementation of m_encode is
  signal cnt_clk       : std_logic_vector (10 downto 0) := (others => '0');
  signal cnt_bit2      : std_logic_vector (2  downto 0) := "000";
  signal cnt_octet     : std_logic_vector (3  downto 0) := "0000";
  signal cnt_packet    : std_logic_vector (3  downto 0) := "0000";
  signal cnt_turn      : std_logic_vector (59 downto 0) := (others => '0');

  signal buf_payload   : payload_t := (others => '0');
  signal sig_octet     : octet_t := x"00";
  signal sig_isk       : std_logic := '0';
  signal sig_subo      : octet_t := x"00";
  signal sig_subk      : std_logic := '0';
  signal sig_trigout   : std_logic := '0';
  signal sig_frame3    : std_logic := '0';
  signal sig_frame9    : std_logic := '0';
  signal sig_setdata   : std_logic := '0';
  signal sig_setsub    : std_logic := '0';
  signal sta_runreset  : std_logic := '0';
  signal sta_locked    : std_logic := '0';
  signal sig_frame     : std_logic := '0';

  -- for debug
  signal sig_validk    : std_logic := '0';
  signal sig_rdnext    : std_logic := '0';
  signal sig_validsub  : std_logic := '0';
  signal sig_subrd     : std_logic := '0';
begin

  map_2b: entity work.m_en2bit
    port map ( clock   => clock,
               counter => cnt_bit2,
               octet   => sig_octet,
               isk     => sig_isk,
               bit2    => bit2,          -- out
               validk  => sig_validk,    -- out
               rdnext  => sig_rdnext );  -- out

  map_2s: entity work.m_en2bit
    port map ( clock   => clock,
               counter => cnt_bit2,
               octet   => sig_subo,
               isk     => sig_subk,
               bit2    => sub2,          -- out
               validk  => sig_validsub,  -- out
               rdnext  => sig_subrd );   -- out

  map_oc: entity work.m_enoctet
    port map ( cntpay => cntpay,
               cntsub => cntsub,
               clock      => clock,
               runreset   => runreset,
               cntencode  => cnt_bit2,
               cntoctet   => cnt_octet,
               trigin     => trigin,
               trigtyp    => trigtyp,
               setdata    => sig_setdata,
               setsub     => sig_setsub,
               payload    => buf_payload,
               octet      => sig_octet,    -- out
               isk        => sig_isk,      -- out
               subo       => sig_subo,     -- out
               subk       => sig_subk,     -- out
               trigout    => sig_trigout,  -- out
               trigshort  => trigshort );  -- out

  map_pa: entity work.m_enpacket
    generic map ( B2TTVER  => B2TTVER )
    port map ( clock       => clock,
               locked      => sta_locked,
               cntbit2     => cnt_bit2,
               cntoctet    => cnt_octet,
               cntpacket   => cnt_packet,
               frame3      => sig_frame3,
               frame9      => sig_frame9,
               disparity   => sig_rdnext,
               subparity   => sig_subrd,
               selreset    => selreset,
               runreset    => runreset,
               stareset    => stareset,
               trgstart    => trgstart,
               feereset    => feereset,
               b2lreset    => b2lreset,
               gtpreset    => gtpreset,
               incdelay    => incdelay,
               caldelay    => caldelay,
               notagerr    => notagerr,
               cmdaddr     => cmdaddr,
               setaddr     => setaddr,
               cmdhi       => cmdhi,
               cmdlo       => cmdlo,
               setcmd      => setcmd,
               trigout     => sig_trigout,
               utime       => utime,
               ctime       => ctime,
               clkfreq     => clkfreq,
               utimer      => utimer,
               ctimer      => ctimer,
               exprun      => exprun,
               starunreset => sta_runreset,   -- out
               sigstart    => sigstart,       -- out
               payload     => buf_payload,    -- out
               setdata     => sig_setdata,    -- out
               setsub      => sig_setsub );   -- out


  map_co: entity work.m_encounter
    port map ( clock          => clock,
               plllock        => plllock,
               revoin         => revoin,
               setrevoref     => '0',
               revoref        => "00000000000",
               cntclk         => cnt_clk,        -- out
               cntbit2        => cnt_bit2,       -- out
               cntoctet       => cnt_octet,      -- out
               cntpacket      => cnt_packet,     -- out
               sigframe       => sig_frame,      -- out
               frame3         => sig_frame3,     -- out
               frame9         => sig_frame9,     -- out
               revoout        => revoout,        -- out
               cntnorevo      => cntnorevo,      -- out
               revocand       => revocand,       -- out
               cntrevocand    => cntrevocand,    -- out
               cntbadrevo     => cntbadrevo,     -- out
               locked         => sta_locked );   -- out
    
  -- out
  starunreset <= sta_runreset;
  octet       <= sig_octet;
  isk         <= sig_isk;
  subo        <= sig_subo;
  subk        <= sig_subk;
  sigframe    <= sig_frame;
  frame3      <= sig_frame3;
  frame9      <= sig_frame9;
  cntclk      <= cnt_clk;
  cntbit2     <= cnt_bit2;
  cntoctet    <= cnt_octet;
  cntpacket   <= cnt_packet;
  bitrd       <= sig_rdnext;
  subrd       <= sig_subrd;
  
end implementation;

-- - emacs outline mode setup
-- Local Variables: ***
-- mode:outline-minor ***
-- outline-regexp:"-- -+" ***
-- End: ***
