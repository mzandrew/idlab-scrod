------------------------------------------------------------------------
--
--  b2tt_encode.vhd -- TT-link encoder for Belle2link frontend
--
--  Mikihiko Nakao, KEK IPNS
--
--  20130528 first version
--  20131002 oddr is separated out
--  20131101 no more std_logic_arith
--  20131126 hold "err" until runreset
--  20140406 ttup error study
--
--  eout bit 9 is first transmitted, bit 0 is last transmitted
--  ein  bit 9 is first received,    bit 0 is last received
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- b2tt_encounter
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity b2tt_encounter is
  port (
    clock      : in  std_logic;
    frame      : in  std_logic;
    staframe   : out std_logic;
    cntbit2    : out std_logic_vector (2 downto 0);
    cntoctet   : out std_logic_vector (3 downto 0);
    cntpacket  : out std_logic_vector (7 downto 0) );
end b2tt_encounter;
------------------------------------------------------------------------
architecture implementation of b2tt_encounter is
  signal sta_frame  : std_logic := '0';
  signal cnt_bit2   : std_logic_vector (2 downto 0) := "101";
  signal cnt_octet  : std_logic_vector (3 downto 0) := "0000";
  signal cnt_packet : std_logic_vector (7 downto 0) := x"00";
begin
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- sta_frame
      if frame = '1' then
        if cnt_bit2 = 4 and cnt_octet = 15 and cnt_packet = 255 then
          sta_frame <= '1';
        else
          sta_frame <= '0';
        end if;
      end if;

      -- cnt_bit2
      if frame = '1' or cnt_bit2 = 4 then
        cnt_bit2 <= "000";
      else
        cnt_bit2 <= cnt_bit2 + 1;
      end if;

      -- cnt_octet
      if frame = '1' then
        cnt_octet <= x"0";
      elsif cnt_bit2 = 4 then
        cnt_octet <= cnt_octet + 1;
      end if;

      -- cnt_packet
      if frame = '1' then
        cnt_packet <= x"00";
      elsif cnt_bit2 = 4 and cnt_octet = 15 then
        cnt_packet <= cnt_packet + 1;
      end if;
      
    end if;
  end process;

  -- out
  staframe  <= sta_frame;
  cntbit2   <= cnt_bit2;
  cntoctet  <= cnt_octet;
  cntpacket <= cnt_packet;

end implementation;
------------------------------------------------------------------------
-- b2tt_enpacket
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity b2tt_enpacket is
  port (
    clock     : in  std_logic;
    id        : in  std_logic_vector (15 downto 0);
    myaddr    : in  std_logic_vector (19 downto 0);
    b2clkup   : in  std_logic;
    b2ttup    : in  std_logic;
    b2plllk   : in  std_logic;
    b2linkup  : in  std_logic;
    b2linkwe  : in  std_logic;
    b2lnext   : in  std_logic;
    b2lclk    : in  std_logic;
    runreset  : in  std_logic;
    busy      : in  std_logic;
    err       : in  std_logic;
    moreerrs  : in  std_logic_vector (1  downto 0);
    timerr    : in  std_logic;
    tag       : in  std_logic_vector (31 downto 0);
    tagerr    : in  std_logic;
    fifoerr   : in  std_logic;
    fifoful   : in  std_logic;
    seu       : in  std_logic_vector (6  downto 0);
    cntbit2   : in  std_logic_vector (2  downto 0);
    cntoctet  : in  std_logic_vector (3  downto 0);
    cntpacket : in  std_logic_vector (7  downto 0);
    cntdelay  : in  std_logic_vector (11 downto 0);
    regdbg    : in  std_logic_vector (7  downto 0);
    payload   : out std_logic_vector (111 downto 0) );
end b2tt_enpacket;
------------------------------------------------------------------------
architecture implementation of b2tt_enpacket is
  signal seq_b2we    : std_logic := '0';
  signal cnt_b2we    : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_b2ltag  : std_logic_vector (15 downto 0) := (others => '0');
  signal seq_seudet  : std_logic_vector (1  downto 0) := (others => '0');
  signal cnt_seudet  : std_logic_vector (9  downto 0) := (others => '0');
  signal seq_seuscan : std_logic_vector (1  downto 0) := (others => '0');
  signal cnt_seuscan : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_payload : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_err     : std_logic := '0';
  signal sta_ttdown  : std_logic := '0';
begin
  proc_b2l: process (b2lclk)
  begin
    if b2lclk'event and b2lclk = '1' then
      --MN (debug code enabled to debug cdcv3b2l)
      if b2clkup = '0' or b2linkup = '0' or runreset = '1' then
        cnt_b2we   <= (others => '0');
        cnt_b2ltag <= (others => '0');
      else
        if b2linkwe = '1' then
          cnt_b2we <= cnt_b2we + 1;
        end if;
        if b2lnext = '1' then
          cnt_b2ltag <= cnt_b2ltag + 1;
        end if;
      end if;
    end if; -- event
  end process;
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      --MN (nominal code is disabled to debug cdcv3b2l)
      --MN -- cnt_b2we
      --MN if b2clkup = '0' or b2linkup = '0' or runreset = '1' then
      --MN  cnt_b2we <= (others => '0');
      --MN elsif seq_b2we = '0' and b2linkwe = '1' then
      --MN  cnt_b2we <= cnt_b2we + 1;
      --MN end if;

      -- seq_b2we
      seq_b2we <= b2linkwe;

      -- seq_seudet, cnt_seudet
      if seq_seudet = "01" then
        cnt_seudet <= cnt_seudet + 1;
      end if;
      seq_seudet <= seq_seudet(0) & seu(2);
      
      -- seq_seuscan, cnt_seuscan
      if seq_seuscan = "01" then
        cnt_seuscan <= cnt_seuscan + 1;
      end if;
      seq_seuscan <= seq_seuscan(0) & seu(3);

      -- sta_err
      if runreset = '1' or err = '1' then
        sta_err <= err;
      end if;

      -- sta_ttdown
      if runreset = '1' or b2ttup = '0' then
        sta_ttdown <= not b2ttup;
      end if;

      --payload <= x"123456789abcdef0132435465768";
      --payload <= x"21436587a9cbed0f314253647586";
      -- payload
      if b2clkup = '0' then
        payload(91 downto 77) <= (others => '0');
        payload(76 downto 75) <= (others => '1'); -- impossible combination
        payload(74 downto  0) <= (others => '0');
      elsif cntbit2 = 4 and cntoctet = 15 then
        payload(111 downto 92) <= myaddr;
        payload(91)            <= b2ttup;
        payload(90)            <= b2linkup;
        payload(89  downto 82) <= cnt_payload;
        payload(81)            <= busy;
        payload(80)            <= err or sta_err;
        payload(79  downto 78) <= moreerrs;
        payload(77)            <= tagerr;
        payload(76)            <= fifoerr;
        payload(75)            <= fifoful;
        payload(74  downto 68) <= seu;
        payload(67  downto 52) <= cnt_b2ltag(15 downto 0);
        payload(51  downto 36) <= cnt_b2we;
        payload(35  downto 26) <= cnt_seudet;
        payload(25  downto 18) <= cnt_seuscan;
        -- b2plllk should be placed somewhere else, maybe by rearranging
        -- seu bits
        payload(17)            <= b2plllk;
        --payload(17  downto 16) <= "00"; -- 0 for id
        if cnt_payload(0) = '0' then
          payload(16) <= '0'; -- 0 for id
          payload(15  downto  0) <= id;
        else
          payload(16) <= '1'; -- 0 for id
          payload(15 downto 14) <= "00";
          payload(13)           <= sta_ttdown;
          payload(12)           <= timerr;
          payload(11 downto  0) <= cntdelay;
        end if;
        cnt_payload <= cnt_payload + 1;
      end if;
    end if;
  end process;
end implementation;
------------------------------------------------------------------------
-- b2tt_enoctet
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity b2tt_enoctet is
  port (
    clock      : in  std_logic;
    obusy      : in  std_logic;
    cntbit2    : in  std_logic_vector (2 downto 0);
    cntoctet   : in  std_logic_vector (3 downto 0);
    payload    : in  std_logic_vector (111 downto 0); -- 14 bytes
    octet      : out std_logic_vector (7 downto 0);
    isk        : out std_logic );
end b2tt_enoctet;
------------------------------------------------------------------------
architecture implementation of b2tt_enoctet is
  signal sta_defer   : std_logic := '0';
  signal buf_payload : std_logic_vector (111 downto 0) := (others => '0');

  signal sta_crc8  : std_logic_vector (7 downto 0) := x"00";
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
      -- busy transition found in the packet
      if obusy = '1' then
        sta_defer <= '1';
      elsif cntoctet = 0 then
        sta_defer <= '0';
      end if;

      -- crc8 trial
      --   this code doesn't care about sta_defer, but it will not be
      --   sent anyway if sta_defer occurs
      if cntoctet = 0 and obusy = '0' then
        sta_crc8 <= (others => '0');
      elsif cntbit2 = 0 and cntoctet /= 15 then
        sta_crc8 <= crc8_update(sta_crc8, buf_payload(111 downto 104));
      end if;
      
      -- data to encode
      if (cntoctet = 0 and obusy = '0') or
         (cntoctet = 1 and sta_defer = '1') then
        octet <= K28_1; -- comma
        isk   <= '1';
      elsif cntoctet = 15 and sta_defer = '0' then
        --octet <= K28_3; -- idle
        --isk   <= '1';
        octet <= sta_crc8;
        isk   <= '0';
      else
        octet <= buf_payload(111 downto 104);
        isk <= '0';
      end if;
      
      -- fetch payload
      if cntoctet = 0 then
        buf_payload <= payload;
      elsif obusy = '1' then
        -- skip
      elsif cntoctet = 1 and sta_defer = '1' then
        -- skip
      elsif cntbit2 = 4 then
        buf_payload <= buf_payload(103 downto 0) & x"00";
      end if;
    end if;
  end process;
end implementation;
------------------------------------------------------------------------
-- b2tt_enbit2
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity b2tt_enbit2 is
  port (
    clock    : in  std_logic;
    runreset : in  std_logic;
    cntbit2  : in  std_logic_vector (2 downto 0);
    octet    : in  std_logic_vector (7 downto 0);
    isk      : in  std_logic;
    busy     : in  std_logic;
    err      : in  std_logic;
    obusy    : out std_logic;
    bit2     : out std_logic_vector (1 downto 0);
    validk   : out std_logic;
    rdnext   : out std_logic;
    rd6p     : out std_logic;
    rd4p     : out std_logic );
end b2tt_enbit2;
------------------------------------------------------------------------
architecture implementation of b2tt_enbit2 is
  signal sig_en     : std_logic := '0';
  signal buf_10b    : std_logic_vector (9 downto 0) := "0000000000";
  signal seq_10b    : std_logic_vector (7 downto 0) := "00000000";
  signal buf_reset  : std_logic := '0';
  signal sig_reset  : std_logic := '0';
  signal buf_validk : std_logic := '0';
  signal seq_busy   : std_logic_vector (1 downto 0) := "00";
  signal seq_err    : std_logic_vector (1 downto 0) := "00";
  signal sta_err    : std_logic := '0';
  signal sig_busyup : std_logic := '0';
  signal sig_busydn : std_logic := '0';
  signal cnt_k285   : std_logic_vector (2 downto 0) := "000";
  signal seq_k285   : std_logic_vector (7 downto 0) := "00000000";
  signal sig_orerr  : std_logic := '0';
  signal sig_orbusy : std_logic := '0';
  signal seq_orbusy : std_logic := '0';
begin

  -- in
  sig_en     <= '1' when cntbit2  = 3    else '0';
  sig_busyup <= '1' when seq_busy = "01" and cnt_k285 = 0 else '0';
  sig_busydn <= '1' when seq_busy = "10" and cnt_k285 = 0 and sta_err = '0' else
                '0';
  sig_orerr  <= err;
  sig_orbusy <= busy or sig_orerr or seq_orbusy or sta_err;
  
  map_en8b10b: entity work.b2tt_en8b10b
    port map (
      reset  => '0',
      clock  => clock,
      en     => sig_en,
      isk    => isk,
      din    => octet,
      eout   => buf_10b, -- out/async
      validk => validk,  -- out
      rdnext => rdnext,  -- out
      rd6psav => rd6p,   -- out
      rd4psav => rd4p ); -- out

  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- seq_orbusy (to enlong sig_orbusy until cnt_k285 != 0)
      seq_orbusy <= busy or sig_orerr;

      -- sta_err (to stay up until runreset)
      if runreset = '1' then
        sta_err <= sig_orerr;
      elsif seq_err = "01" then
        sta_err <= '1';
      end if;

      -- seq_busy, seq_err (to detect up and down)
      if runreset = '1' then
        seq_busy <= '0' & sig_orbusy;
        seq_err  <= '0' & sig_orerr;
      elsif cnt_k285 = 0 then
        seq_busy <= seq_busy(0) & sig_orbusy;
        seq_err  <= seq_err(0)  & sig_orerr;
      end if;

      -- seq_k285, cnt_k285 (to intercept the bit stream with K28.5)
      -- obusy (to suspend other tasks for 5 clocks of K28.5 sending)
      -- seq_10b (bit 7..0 of 8b10b data, bit 9..8 directly goes to bit2)
      if sig_busyup = '1' then
        seq_k285 <= "00000101";
        cnt_k285 <= "100";
        obusy    <= '1';
      elsif sig_busydn = '1' then
        seq_k285 <= "11111010";
        cnt_k285 <= "100";
        obusy    <= '1';
      elsif cnt_k285 /= 0 then
        cnt_k285 <= cnt_k285 - 1;
        seq_k285 <= seq_k285(5 downto 0) & "00";
        obusy    <= '1';
      elsif cntbit2 = 3 then
        seq_10b <= buf_10b(7 downto 0);
        obusy    <= '0';
      else
        seq_10b <= seq_10b(5 downto 0) & "00";
        obusy    <= '0';
      end if;

    end if;
  end process;

  -- out (partially async)
  -- busy-begin: K28.5+ 1100000101
  -- busy-end:   K28.5- 0011111010
  bit2   <= "11" when seq_busy = "01" else
            "00" when seq_busy = "10" else
            seq_k285(7 downto 6) when cnt_k285 /= 0 else
            buf_10b(9 downto 8) when cntbit2 = 3 else -- async
            seq_10b(7 downto 6);

end implementation;
------------------------------------------------------------------------
-- b2tt_encode
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity b2tt_encode is
  generic (
    constant FLIPACK : std_logic := '0' );
  port (
    clock    : in  std_logic;
    invclock : in  std_logic;
    frame    : in  std_logic;
    id       : in  std_logic_vector (15 downto 0);
    myaddr   : in  std_logic_vector (19 downto 0);
    b2clkup  : in  std_logic;
    b2ttup   : in  std_logic;
    b2plllk  : in  std_logic;
    b2linkup : in  std_logic;
    b2linkwe : in  std_logic;
    b2lnext  : in  std_logic;
    b2lclk   : in  std_logic;
    runreset : in  std_logic;
    busy     : in  std_logic;
    err      : in  std_logic;
    moreerrs : in  std_logic_vector (1  downto 0);
    tag      : in  std_logic_vector (31 downto 0);
    tagerr   : in  std_logic;
    fifoerr  : in  std_logic;
    fifoful  : in  std_logic;
    seu      : in  std_logic_vector (6  downto 0);
    cntdelay : in  std_logic_vector (11 downto 0);
    timerr   : in  std_logic;
    regdbg   : in  std_logic_vector (7  downto 0);
    ackp     : out std_logic;
    ackn     : out std_logic;
    cntbit2  : out std_logic_vector (2  downto 0);
    cntoctet : out std_logic_vector (3  downto 0);
    isk      : out std_logic;
    octet    : out std_logic_vector (7  downto 0);
    bit2     : out std_logic_vector (1  downto 0);
    bitddr   : out std_logic );
end b2tt_encode;
------------------------------------------------------------------------
architecture implementation of b2tt_encode is
  signal sta_frame   : std_logic := '0';
  signal sig_obusy   : std_logic := '0';
  signal cnt_bit2    : std_logic_vector (2 downto 0) := "101";
  signal cnt_octet   : std_logic_vector (3 downto 0) := "0000";
  signal cnt_packet  : std_logic_vector (7 downto 0) := x"00";
  signal sig_bit2    : std_logic_vector (1 downto 0) := "00";
  signal buf_isk     : std_logic := '0';
  signal buf_octet   : std_logic_vector (7 downto 0) := x"00";
  signal buf_payload : std_logic_vector (111 downto 0) := (others => '0');
  signal buf_rdnext  : std_logic := '0';
  signal buf_rd6p    : std_logic := '0';
  signal buf_rd4p    : std_logic := '0';
  signal sig_validk  : std_logic := '0';
begin

  map_co: entity work.b2tt_encounter
    port map (
      clock     => clock,
      frame     => frame,
      staframe  => sta_frame,    -- out
      cntbit2   => cnt_bit2,     -- out
      cntoctet  => cnt_octet,    -- out
      cntpacket => cnt_packet ); -- out

  map_pa: entity work.b2tt_enpacket
    port map (
      clock     => clock,
      id        => id,
      myaddr    => myaddr,
      b2clkup   => b2clkup,
      b2ttup    => b2ttup,
      b2plllk   => b2plllk,
      b2linkup  => b2linkup,
      b2linkwe  => b2linkwe,
      b2lnext   => b2lnext,
      b2lclk    => b2lclk,
      runreset  => runreset,
      busy      => busy,
      err       => err,
      moreerrs  => moreerrs,
      timerr    => timerr,
      tag       => tag,
      tagerr    => tagerr,
      fifoerr   => fifoerr,
      fifoful   => fifoful,
      seu       => seu,
      cntbit2   => cnt_bit2,
      cntoctet  => cnt_octet,
      cntpacket => cnt_packet,
      cntdelay  => cntdelay,
      regdbg    => regdbg,
      payload   => buf_payload ); -- out

  map_oc: entity work.b2tt_enoctet
    port map (
      clock     => clock,
      obusy     => sig_obusy,
      cntbit2   => cnt_bit2,
      cntoctet  => cnt_octet,
      payload   => buf_payload,
      octet     => buf_octet, -- out
      isk       => buf_isk ); -- out

  map_b2: entity work.b2tt_enbit2
    port map (
      clock     => clock,
      runreset  => runreset,
      cntbit2   => cnt_bit2,
      octet     => buf_octet,
      isk       => buf_isk,
      busy      => busy,
      err       => err,
      obusy     => sig_obusy,  -- out
      bit2      => sig_bit2,   -- out/async
      validk    => sig_validk, -- out/async
      rdnext    => buf_rdnext, -- out
      rd6p      => buf_rd6p,   -- out
      rd4p      => buf_rd4p ); -- out

  map_od: entity work.b2tt_oddr
    generic map (
      FLIPOUT   => FLIPACK )
    port map (
      clock     => clock,
      invclock  => invclock,
      mask      => '0',  -- for ftsw only
      bit2      => sig_bit2,
      bitddr    => bitddr,  -- out
      outp      => ackp,    -- out
      outn      => ackn );  -- out
  
  -- out
  bit2     <= sig_bit2;
  octet    <= buf_octet;
  isk      <= buf_isk;
  cntbit2  <= cnt_bit2;
  cntoctet <= cnt_octet;
  
end implementation;
