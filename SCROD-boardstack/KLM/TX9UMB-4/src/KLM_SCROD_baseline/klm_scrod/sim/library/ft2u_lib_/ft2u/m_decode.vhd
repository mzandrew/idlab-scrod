------------------------------------------------------------------------
--
--  m_decode.vhd -- decoder for TTD master
--
--  Mikihiko Nakao, KEK IPNS
--
--  20130603 new
--  20130801 en -> disable
--  20140101 need 18-bit buffer for K28.5 intercepting
--  20140811 proper crc8 and obusy handling
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- - m_decomma
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_decomma is
  port ( 
    bit2     : in  std_logic_vector (1 downto 0);
    prev18   : in  std_logic_vector (17 downto 0);
    cntbit2  : in  std_logic_vector (2 downto 0);  -- 0 to 4
    busyup   : out std_logic;
    busydn   : out std_logic;
    comma    : out std_logic;
    newcomma : out std_logic );
end m_decomma;
------------------------------------------------------------------------
architecture implementation of m_decomma is
  signal sig_bit10 : std_logic_vector (9 downto 0) := "0000000000";
  signal sig_chk10 : std_logic_vector (9 downto 0) := "0000000000";
  signal sig_comma : std_logic := '0';
begin

  -- in
  sig_bit10 <= prev18(17 downto 8);
  sig_chk10 <= prev18(7 downto 0) & bit2;

  -- comma detection (before clock cycle)
  sig_comma <= '1' when sig_bit10 = K28_1P or sig_bit10 = K28_1N else '0';

  -- async-out
  -- busy-up detection (before clock cycle)
  busyup <= '1' when sig_chk10 = K28_5P else '0';
  busydn <= '1' when sig_chk10 = K28_5N else '0';

  -- misaligned comma detection (before clock cycle)
  newcomma <= '1' when sig_comma = '1' and
		       cntbit2 /= 0 and cntbit2 /= 5 else '0';

  comma <= sig_comma;
  
end implementation;
------------------------------------------------------------------------
-- - m_debit2
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_debit2 is
  port ( 
    clock    : in  std_logic;
    incdelay : in  std_logic;
    newcomma : in  std_logic;
    comma    : in  std_logic;
    bit2     : in  std_logic_vector (1 downto 0);
    busyup   : in  std_logic;
    busydn   : in  std_logic;
    bit18    : out std_logic_vector (17 downto 0);
    cntbit2  : out std_logic_vector (2 downto 0) ); -- 0 to 4
end m_debit2;
------------------------------------------------------------------------
architecture implementation of m_debit2 is

  signal buf_bit18  : std_logic_vector (17 downto 0) := (others => '0');
  signal buf_bit10  : std_logic_vector (9  downto 0) := (others => '0');
  signal cnt_bit2   : std_logic_vector (2 downto 0) := "101";
begin
  -- in
  buf_bit10  <= buf_bit18(17 downto 8);
  
  -- process
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- decode counter to align octet boundary (=5 when not aligned)
      if newcomma = '1' then
        cnt_bit2 <= "101"; -- 5
      elsif comma = '1' then
        cnt_bit2 <= "001"; -- 1
      elsif cnt_bit2 = 4 then
        cnt_bit2 <= "000"; -- 0
      elsif cnt_bit2 /= 5 then
        cnt_bit2 <= cnt_bit2 + 1;
      end if;
  
      -- standard buffer
      if busyup = '1' or busydn = '1' then
        buf_bit18 <= "00000000" & buf_bit18(17 downto 8);
      else
        buf_bit18 <= buf_bit18(15 downto 0) & bit2;
      end if;
    end if;
  end process;
  
  -- out
  bit18   <= buf_bit18;
  cntbit2 <= cnt_bit2;
  
end implementation;
------------------------------------------------------------------------
-- - m_debit10
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_debit10 is
  port ( 
    clock      : in  std_logic;
    cntbit2    : in  std_logic_vector (2 downto 0);
    bit2       : in  std_logic_vector (1 downto 0);
    bit18      : in  std_logic_vector (17 downto 0);
    obusy      : in  std_logic;
    octet      : out std_logic_vector (7 downto 0);  -- out/async
    isk        : out std_logic );                    -- out/async

end m_debit10;
------------------------------------------------------------------------
architecture implementation of m_debit10 is

  signal sig_10b : std_logic_vector (9 downto 0) := "0000000000";
  signal sig_en  : std_logic := '0';
  signal sig_isk : std_logic := '0';
  signal buf_isk : std_logic := '0';
  signal sig_8b  : std_logic_vector (7 downto 0) := x"00";
  signal buf_8b  : std_logic_vector (7 downto 0) := x"00";
  signal open_err : std_logic_vector (4 downto 0) := (others => '0');
  signal open_rdp : std_logic := '0';
begin

  -- in
  sig_10b <= bit18(17 downto 8);
  sig_en  <= '1' when cntbit2 = 4 else '0';

  -- almost async (except for rdp)
  map_de8b10b: entity work.b2tt_de8b10b
    port map (
      reset => '0',
      clock => clock,
      en    => sig_en,
      ein   => sig_10b,
      dout  => sig_8b,
      isk   => sig_isk,
      err   => open_err,
      rdp   => open_rdp );

  -- async-out
  octet   <= sig_8b  when (cntbit2 = 0 or cntbit2 = 5) and obusy = '0' else
             buf_8b;
  isk     <= sig_isk when (cntbit2 = 0 or cntbit2 = 5) and obusy = '0' else
             buf_isk;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if (cntbit2 = 0 or cntbit2 = 5) and obusy = '0' then
        buf_8b  <= sig_8b;
        buf_isk <= sig_isk;
      end if;
    end if;
  end process;

end implementation;
------------------------------------------------------------------------
-- - m_debusy
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_debusy is
  port ( 
    clock    : in  std_logic;
    reset    : in  std_logic;
    linkup   : in  std_logic;
    busyup   : in  std_logic;
    busydn   : in  std_logic;
    busy     : out std_logic;
    obusy    : out std_logic );
end m_debusy;
------------------------------------------------------------------------
architecture implementation of m_debusy is
  signal buf_busy  : std_logic := '0';
  signal buf_obusy : std_logic := '0';
  signal cnt_obusy : std_logic_vector (2 downto 0) := (others => '0');
begin

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if linkup = '0' or reset = '1' then
        buf_busy <= '0';
      elsif busyup = '1' then
        buf_busy <= '1';
      elsif busydn = '1' then
        buf_busy <= '0';
      end if;
      if linkup = '0' or reset = '1' then
        buf_obusy <= '0';
      elsif busyup = '1' or busydn = '1' then
        cnt_obusy <= "100";
        buf_obusy <= '1';
      elsif cnt_obusy /= 0 then
        cnt_obusy <= cnt_obusy - 1;
      elsif buf_obusy = '1' then
        buf_obusy <= '0';
      end if;
    end if;
  end process;

  -- out
  busy  <= busyup or (buf_busy and not busydn);
  obusy <= buf_obusy;
      
end implementation;
------------------------------------------------------------------------
-- - m_deoctet
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_deoctet is
  port ( 
    clock      : in  std_logic;
    cntbit2    : in  std_logic_vector (2 downto 0);
    octet      : in  std_logic_vector (7 downto 0);
    isk        : in  std_logic;
    obusy      : in  std_logic;
    staoctet   : out std_logic;
    cntoctet   : out std_logic_vector (4 downto 0);
    cntdato    : out std_logic_vector (3 downto 0);
    stadefer   : out std_logic;
    sigpayload : out std_logic;
    nopayload  : out std_logic;
    incdelay   : out std_logic;
    payload    : out std_logic_vector (111 downto 0);
    errbit     : out std_logic_vector (3  downto 0);
    cntinvalid : out std_logic_vector (11 downto 0);
    cntrealign : out std_logic_vector (1  downto 0);
    crc8ok     : out std_logic );
end m_deoctet;
------------------------------------------------------------------------
architecture implementation of m_deoctet is

  signal cnt_datoctet : std_logic_vector (3 downto 0) := "0000";
  signal cnt_octet    : std_logic_vector (4 downto 0) := "00000";
  signal sta_octet    : std_logic := '0';
  signal cnt_invalid  : std_logic_vector (11 downto 0) := x"000";

  signal buf_payload  : std_logic_vector (111 downto 0) := (others => '0');

  signal seq_staoctet : std_logic := '0';
  signal cnt_realign  : std_logic_vector (1 downto 0) := (others => '0');

  signal sta_crc8     : std_logic_vector (7 downto 0) := x"00";
  signal buf_crc8     : std_logic_vector (7 downto 0) := x"00";
  signal sig_crc8     : std_logic_vector (7 downto 0) := x"00";
  signal cnt_crc8ok   : std_logic_vector (6 downto 0) := (others => '0');
  signal sta_crc8ok   : std_logic := '0';
  signal sta_defer    : std_logic := '0';

  -- from crc8.vhd and comlib.vhd of
  -- http://opencores.org/project,w11
  -- 0x4d (x8 + x6 + x3 + x2 + 1)   [ shr 1 makes 0xa6 ]
  subtype byte_t is  std_logic_vector (7 downto 0);
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

  -- in
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- check invalid packet
      -- - cnt_invalid: number of invalid octet
      -- - sig_indelay: signal to increment delay
      if cnt_invalid(cnt_invalid'left) = '1' then
        cnt_invalid <= (others => '0');
        incdelay <= '1';  -- out
      else
        if sta_octet = '0' then
          cnt_invalid <= cnt_invalid + 1;
        end if;
        incdelay <= '0';  -- out
      end if;

      -- crc8 calculation
      if cntbit2 = 1 then
        if isk = '1' and octet = K28_1 then
          sta_crc8 <= (others => '0');
          sta_crc8ok <= '1';
        elsif cnt_datoctet = 14 and isk = '0' and obusy = '0' then
          buf_crc8 <= sta_crc8;
          sig_crc8 <= octet;
          if sta_crc8 /= octet then
            sta_crc8ok <= '0';
          elsif sta_crc8ok = '0' then
            cnt_crc8ok <= cnt_crc8ok + 1;
          end if;
        elsif isk = '0' and obusy = '0' then
          sta_crc8 <= crc8_update(sta_crc8, octet);
        end if;
      end if;

      -- cnt_realign
      seq_staoctet <= sta_octet;
      if seq_staoctet = '0' and sta_octet = '1' then
        cnt_realign <= cnt_realign + 1;
      end if;
      
      -- search for a packet boundary
      -- - cnt_octet: to align octet to packet boundary
      -- - sta_octet: octet is aligned to packet boundary
      if cntbit2 = 5 then
        if sta_octet = '1' then
          errbit(0) <= '1';
        end if;
        sta_octet <= '0';
        cnt_octet <= "11111";
        
      elsif cntbit2 = 1 then
        -- and all the octets are checked only at cntbit2 = 1 (2?)
        
        if isk = '1' and octet = K28_1 then
          -- valid comma if cnt_octet = 15
          if cnt_octet = 31 then
            sta_octet <= '1';
            cnt_octet <= "00000";
          elsif cnt_octet = 15 then
            sta_octet <= sta_crc8ok;
            cnt_octet <= "00000";
          elsif (cnt_octet = 0 or cnt_octet = 16) and sta_octet = '1' then
            cnt_octet <= "00001";
          else 
            sta_octet <= '0';
            cnt_octet <= "00000";
            errbit(1) <= '1';
          end if;
        elsif (cnt_datoctet = 0 or cnt_datoctet = 14) and
          isk = '1' and octet = K28_3 then
          --20140414: 14th octet is for idle until b2tt014
          -- valid idle
          cnt_octet <= cnt_octet + 1;
        elsif isk = '1' and obusy = '0' then
          -- invalid K character
          sta_octet <= '0';
          cnt_octet <= "11111";
          errbit(2) <= '1';
          --20140414: 14th octet is for crc8 from b2tt015
          --elsif cnt_datoctet = 14 and obusy = '0' then
          --  -- invalid (too long) data payload
          --  sta_octet <= '0';
          --  cnt_octet <= "11111";
          --  cnt_err4  <= cnt_err4 + 1;
        elsif cnt_octet < 15 or sta_defer = '1' then
          -- valid data octet
          cnt_octet <= cnt_octet + 1;
        else
          -- invalid data payload
          sta_octet <= '0';
          cnt_octet <= "00000";
          errbit(3) <= '1';
        end if;
      else
        errbit <= (others => '0');
      end if;

      if cnt_octet = 0 or cnt_octet = 1 then
        sta_defer <= '0';
      elsif obusy = '1' and (cnt_octet = 14 or cnt_octet = 15) then
        sta_defer <= '1';
      end if;
      
      -- payload reconstruction
      if cntbit2 = 5 then
        buf_payload  <= (others => '0');
        cnt_datoctet <= (others => '0');
      elsif cntbit2 = 2 then
        if cnt_octet = 0 and obusy = '1' then
          buf_payload  <= (others => '0');
          cnt_datoctet <= "1111"; -- 15
        elsif cnt_octet = 0 or cnt_datoctet = 15 then
          buf_payload  <= (others => '0');
          cnt_datoctet <= (others => '0');
        elsif cnt_octet = 16 then
          buf_payload  <= (others => '0');
          cnt_datoctet <= "1111"; -- 15
        elsif cnt_datoctet < 14 and obusy = '0' then
          buf_payload  <= buf_payload(8*13-1 downto 0) & octet;
          cnt_datoctet <= cnt_datoctet + 1;
        end if;
      end if;
      
      -- sig_payload
      if cntbit2 = 3 and cnt_octet = 15 then
        if cnt_datoctet = 14 then
          sigpayload <= '1';  -- out
          payload    <= buf_payload;
        else
          nopayload  <= '1';  -- out
        end if;
      else
        sigpayload   <= '0';  -- out
        nopayload    <= '0';  -- out
      end if;
    end if;
  end process;

  -- out
  staoctet   <= sta_octet;
  cntoctet   <= cnt_octet;
  cntdato    <= cnt_datoctet;
  cntinvalid <= cnt_invalid;
  cntrealign <= cnt_realign;
  crc8ok     <= sta_crc8ok;
  stadefer   <= sta_defer;
  
end implementation;
------------------------------------------------------------------------
-- - m_depacket
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.b2tt_symbols.all;

entity m_depacket is
  port ( 
    clock      : in  std_logic;
    mask       : in  std_logic;
    reset      : in  std_logic;
    staoctet   : in  std_logic;
    sigpayload : in  std_logic;
    nopayload  : in  std_logic;
    payload    : in  std_logic_vector (111 downto 0);
    tag        : in  std_logic_vector (31 downto 0);
    seladdr    : in  std_logic_vector (19 downto 0);
    incdelay   : out std_logic;
    linkup     : out std_logic;
    linkdn     : out std_logic;
    data       : out std_logic_vector (31 downto 0);
    datb       : out std_logic_vector (31 downto 0);
    tagdone    : out std_logic_vector (7  downto 0);
    cntpkterr  : out std_logic_vector (1  downto 0);
    cntrdelay  : out std_logic_vector (11 downto 0);
    sigdump    : out std_logic );
end m_depacket;
------------------------------------------------------------------------
architecture implementation of m_depacket is
  signal cnt_valid   : std_logic_vector (7  downto 0) := (others => '0');
  signal sta_next    : std_logic_vector (7  downto 0) := (others => '0');
  signal sig_cntp    : std_logic_vector (7  downto 0) := (others => '0');
  signal seq_alive   : std_logic := '0';
  signal sig_valid   : std_logic := '0';
  signal sta_seuscan : std_logic := '0';
  signal sta_tagdiff : std_logic_vector (9  downto 0) := (others => '0');
  signal buf_tagdiff : std_logic_vector (1  downto 0) := (others => '0');

  signal sta_linkup  : std_logic := '0';
  
  signal seq_ttup    : std_logic := '0';
  signal sig_ttup    : std_logic := '0';
  signal sta_diff12  : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_pkterr  : std_logic_vector (7  downto 0) := (others => '0');
  signal cnt_nopay   : std_logic_vector (3  downto 0) := (others => '0');

  signal buf_data    : std_logic_vector (31 downto 0) := (others => '0');
  signal seq_linkup  : std_logic_vector (1  downto 0) := (others => '0');

  signal sta_addr    : std_logic_vector (19 downto 0) := (others => '0');
  signal sta_feeerr  : std_logic := '0';
  signal sta_ttlost  : std_logic := '0';
  signal sta_b2llost : std_logic := '0';
  signal sta_tagerr  : std_logic := '0';
  signal sta_fifoerr : std_logic := '0';
  signal sta_fifoful : std_logic := '0';
  signal sta_seuerr  : std_logic_vector (1  downto 0) := (others => '0');
  signal sta_b2lup   : std_logic := '0';
  signal sta_plllk   : std_logic := '0';
  signal sta_ttup    : std_logic := '0';
  signal sta_alive   : std_logic := '0';
  signal sta_busy    : std_logic := '0';
  signal cnt_b2ltag  : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_b2lwe   : std_logic_vector (15 downto 0) := (others => '0');
begin
  -- in
  sig_cntp <= payload(89 downto 82); -- => sig_valid
  sig_valid <= '1' when sig_cntp = sta_next else '0';
  sig_ttup  <= payload(91);
  sta_diff12  <= (tag(11 downto 0) - payload(63 downto 52));
               
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- sta_alive
      if staoctet = '0' then
        sta_alive  <= '0';
      elsif sigpayload = '1' then
        if sig_valid = '0' then
          sta_alive <= '0';
        elsif cnt_valid = x"ff" then
          sta_alive <= '1';
        end if;
      end if;

      -- seq_alive
      seq_alive <= sta_alive;

      -- sta_ttup, sta_b2lup, sta_plllk
      if reset = '1' or (seq_alive = '0' and sta_alive = '1') then
        sta_ttup  <= sta_alive and payload(91);
        sta_b2lup <= sta_alive and payload(90);
        sta_plllk <= sta_alive and payload(17);
      elsif sta_alive = '1' then
        sta_ttup  <= sta_ttup  and payload(91);
        sta_b2lup <= sta_b2lup and payload(90);
        sta_plllk <= sta_plllk and payload(17);
      end if;
      
      -- stata error bits
      if sta_alive = '1' and
         (reset = '1' or seq_alive = '0') and
          mask = '0' then
        sta_feeerr  <= payload(80);
        sta_ttlost  <= payload(79);
        sta_b2llost <= payload(78);
        sta_tagerr  <= payload(77);
        sta_fifoerr <= payload(76);
        sta_fifoful <= payload(75);
      elsif reset = '1' or mask = '1' then
        sta_feeerr  <= '0';
        sta_ttlost  <= '0';
        sta_b2llost <= '0';
        sta_tagerr  <= '0';
        sta_fifoerr <= '0';
        sta_fifoful <= '0';
      elsif sta_alive = '1' then
        sta_feeerr  <= sta_feeerr  or payload(80);
        sta_ttlost  <= sta_ttlost  or payload(79);
        sta_b2llost <= sta_b2llost or payload(78);
        sta_tagerr  <= sta_tagerr  or payload(77);
        sta_fifoerr <= sta_fifoerr or payload(76);
        sta_fifoful <= sta_fifoful or payload(75);
      end if;

      -- seu error bits
      if sta_alive = '1' and (reset = '1' or sta_seuerr /= 0) then
        sta_seuerr <= payload(69 downto 68);
      elsif reset = '1' then
        sta_seuerr <= (others => '0');
      end if;
      
      -- linkup
      seq_linkup <= seq_linkup(0) & (sta_alive and payload(91));
      if seq_linkup = "10" then
        sigdump <= '1';
      else
        sigdump <= '0';
      end if;
      sta_linkup <= sta_alive and payload(91); -- ttup
      if reset = '1' and mask = '0' then
        linkdn <= '0';
      elsif sta_linkup = '1' and (sta_alive = '0' or payload(91) = '0') then
        linkdn <= '1';
      end if;
      
      -- adrs and statb
      if sta_alive = '1' then
        sta_addr <= payload(111 downto 92);
        sta_busy <= payload(81);
        cnt_b2ltag <= payload(63 downto 52);
        cnt_b2lwe  <= payload(51 downto 36);
      else
        sta_busy   <= '0';
        cnt_b2ltag <= (others => '0');
        cnt_b2lwe  <= (others => '0');
      end if;

      if sta_alive = '1' and payload(16 downto 12) = "10000" then
        cntrdelay <= payload(11 downto 0);
      end if;

      -- sta_tagdiff, buf_tagdiff
      -- (take only lowest 10 bit)
      sta_tagdiff <= sta_diff12(9 downto 0);
      tagdone     <= payload(59 downto 52);
      if sta_tagdiff(sta_tagdiff'left downto 4) /= 0 then
        buf_tagdiff <= sta_tagdiff(sta_tagdiff'left) & '1';
      else
        buf_tagdiff <= "00";
      end if;

      -- sta_seuscan
      if payload(25 downto 18) = 0 then
        sta_seuscan <= '0';
      else
        sta_seuscan <= '1';
      end if;
                 
      -- cnt_valid
      --
      -- 20140407: could not figure out the reason of using seq_ttup,
      --           more comments are needed here if it is really used
      if sigpayload = '1' then
        if (seq_ttup = '0' and sig_ttup = '1') or sig_valid = '1' then
          if cnt_valid /= x"ff" then
            cnt_valid <= cnt_valid + 1;
          end if;
        else
          cnt_valid <= x"00";
        end if;
      end if;

      -- seq_ttup
      seq_ttup <= payload(91);

      -- cnt_pkterr
      if reset = '1' then
        cnt_pkterr <= (others => '0');
      elsif sigpayload = '1' and sig_valid = '0' then
        cnt_pkterr <= cnt_pkterr + 1;
      end if;
      if reset = '1' then
        cnt_nopay  <= (others => '0');
      elsif nopayload = '1' then
        cnt_nopay <= cnt_nopay + 1;
      end if;

      -- sta_next
      if sigpayload = '1' then
        sta_next <= sig_cntp + 1;
      elsif nopayload = '1' then
        sta_next <= sta_next + 1;
      end if;
      
    end if; -- event
  end process;

  -- out
  cntpkterr <= cnt_pkterr(1 downto 0); -- statc
  linkup <= sta_linkup;
  
  data(31 downto 12) <= sta_addr; -- payload(111 downto 92)
  data(11) <= sta_feeerr;  -- payload(80)
  data(10) <= sta_ttlost;  -- payload(79)
  data(9)  <= sta_b2llost; -- payload(78)
  data(8)  <= sta_tagerr;  -- payload(77)
  data(7)  <= sta_fifoerr; -- payload(76)
  data(6)  <= sta_fifoful; -- payload(75)
  data(5 downto 4) <= sta_seuerr; -- payload(69 downto 68)
  data(3)  <= sta_b2lup;   -- payload(90)
  data(2)  <= sta_plllk;   -- payload(17)
  data(1)  <= sta_ttup;    -- payload(91)
  data(0)  <= sta_alive;

  datb(31) <= sta_busy;
  datb(30) <= '0';
  datb(29 downto 28) <= buf_tagdiff(1 downto 0);
  datb(27 downto 16) <= cnt_b2ltag;
  datb(15 downto  0) <= cnt_b2lwe;
  
end implementation;
------------------------------------------------------------------------
-- - m_decode
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity m_decode is
  port ( 
    clock      : in  std_logic;
    mask       : in  std_logic;
    reset      : in  std_logic;
    ackp       : in  std_logic;
    ackn       : in  std_logic;
    manual     : in  std_logic;
    clrdelay   : in  std_logic;
    incdelay   : in  std_logic;
    tag        : in  std_logic_vector (31 downto 0);

    linkup     : out std_logic;
    linkdn     : out std_logic;
    bitddr     : out std_logic;
    bsyout     : out std_logic;
    stata      : out std_logic_vector (31 downto 0);
    statb      : out std_logic_vector (31 downto 0);
    statc      : out std_logic_vector (31 downto 0);
    
    tagdone    : out std_logic_vector (7 downto 0);
    octet      : out std_logic_vector (7 downto 0);
    isk        : out std_logic;
    bit2       : out std_logic_vector (1 downto 0);
    cntbit2    : out std_logic_vector (2 downto 0);
    cntoctet   : out std_logic_vector (4 downto 0);

    sigdump    : out std_logic;
    sigila     : out std_logic_vector (95 downto 0) );
end m_decode;
------------------------------------------------------------------------
architecture implementation of m_decode is

  -- cnt_bit2:  (3-bit) 0..4 if in sync, 5 if out of sync

  signal cnt_bit2      : std_logic_vector (2  downto 0) := "101";
  signal cnt_octet     : std_logic_vector (4  downto 0) := (others => '0');
  signal cnt_turn      : std_logic_vector (60 downto 0) := (others => '0');

  signal buf_octet     : std_logic_vector (7  downto 0) := (others => '0');
  signal buf_isk       : std_logic := '0';
  signal sig_comma     : std_logic := '0';
  signal sta_octet     : std_logic := '0';

  signal sig_bit2      : std_logic_vector (1  downto 0) := (others => '0');
  signal sig_bit18     : std_logic_vector (17 downto 0) := (others => '0');

  signal sig_newcomma  : std_logic := '0';

  signal sig_incdelay  : std_logic := '0';
  signal sig_incdelay1 : std_logic := '0';
  signal sig_incdelay2 : std_logic := '0';
  signal sig_payload   : std_logic := '0';
  signal sig_nopayload : std_logic := '0';

  signal cnt_width     : std_logic_vector (5  downto 0) := (others => '0');
  signal cnt_delay     : std_logic_vector (6  downto 0) := (others => '0');

  signal buf_payload   : std_logic_vector (111 downto 0) := (others => '0');

  signal sig_obusy     : std_logic := '0';
  signal sig_busyup    : std_logic := '0';
  signal sig_busydn    : std_logic := '0';

  signal sta_linkup    : std_logic := '0';
  signal sta_linkdn    : std_logic := '0';
  signal sta_crc8ok    : std_logic := '0';
  signal cnt_dato      : std_logic_vector (3  downto 0) := (others => '0');
  signal sta_defer     : std_logic := '0';
  
  signal sta_iddr      : std_logic_vector (1  downto 0) := (others => '0');
  signal sta_iddrdbg   : std_logic_vector (9  downto 0) := (others => '0');

  signal cnt_invalid   : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_err       : std_logic_vector (31 downto 0) := (others => '0');

  signal cnt_rdelay    : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_pkterr    : std_logic_vector (1  downto 0) := (others => '0');
  signal cnt_realign   : std_logic_vector (1  downto 0) := (others => '0');

  signal sta_errbit    : std_logic_vector (3  downto 0) := (others => '0');
  signal buf_stata     : std_logic_vector (31 downto 0) := (others => '0');
  signal buf_statb     : std_logic_vector (31 downto 0) := (others => '0');
  signal open_dbg      : std_logic_vector (31 downto 0) := (others => '0');
begin

  map_id: entity work.b2tt_iddr
    port map (
      clock      => clock,
      invclock   => '0', -- spartan6 only
      dblclock   => '0', -- virtex6 only
      dblclockb  => '1', -- virtex6 only
      inp        => ackp,
      inn        => ackn,
      staoctet   => sta_octet,
      stacrc8ok  => sta_crc8ok,
      manual     => manual,
      incdelay   => incdelay,
      clrdelay   => clrdelay,
      caldelay   => '0', -- spartan6 only
      staiddr    => sta_iddr,      -- out
      bitddr     => bitddr,        -- out
      bit2       => sig_bit2,      -- out
      cntdelay   => cnt_delay,     -- out
      cntwidth   => cnt_width,     -- out
      iddrdbg    => sta_iddrdbg ); -- out

  map_co: entity work.m_decomma
    port map (
      bit2      => sig_bit2,
      prev18    => sig_bit18,
      cntbit2   => cnt_bit2,
      busyup    => sig_busyup,      -- out/async for debusy/debit2
      busydn    => sig_busydn,      -- out/async for debusy/debit2
      comma     => sig_comma,       -- out/async for debit2
      newcomma  => sig_newcomma );  -- out/async for debit2
  
  map_b2: entity work.m_debit2
    port map (
      clock      => clock,
      incdelay   => sig_incdelay,
      newcomma   => sig_newcomma,
      comma      => sig_comma,
      bit2       => sig_bit2,
      busyup     => sig_busyup,
      busydn     => sig_busydn,
      bit18      => sig_bit18,     -- out
      cntbit2    => cnt_bit2 );    -- out

  map_10: entity work.m_debit10
    port map (
      clock      => clock,
      cntbit2    => cnt_bit2,
      bit2       => sig_bit2,  -- to skip one clock wait for 10b
      bit18      => sig_bit18,
      obusy      => sig_obusy,
      octet      => buf_octet, -- out/async for detrig/deoctet
      isk        => buf_isk ); -- out/async for detrig/deoctet
  
  map_bs: entity work.m_debusy
    port map (
      clock      => clock,
      reset      => reset,
      linkup     => sta_linkup,
      busyup     => sig_busyup,
      busydn     => sig_busydn,
      busy       => bsyout,      -- out/async
      obusy      => sig_obusy ); -- out
  
  map_oc: entity work.m_deoctet
    port map (
      clock      => clock,
      cntbit2    => cnt_bit2,
      octet      => buf_octet,
      isk        => buf_isk,
      obusy      => sig_obusy,
      staoctet   => sta_octet,     -- out
      cntoctet   => cnt_octet,     -- out
      cntdato    => cnt_dato,      -- out
      stadefer   => sta_defer,     -- out
      sigpayload => sig_payload,   -- out
      nopayload  => sig_nopayload, -- out
      incdelay   => sig_incdelay1, -- out
      payload    => buf_payload,   -- out
      errbit     => sta_errbit,    -- out
      cntinvalid => cnt_invalid,   -- out
      cntrealign => cnt_realign,   -- out
      crc8ok     => sta_crc8ok );  -- out

  map_pa: entity work.m_depacket
    port map (
      clock      => clock,
      mask       => mask,
      reset      => reset,
      staoctet   => sta_octet,
      sigpayload => sig_payload,
      nopayload  => sig_nopayload,
      payload    => buf_payload,
      tag        => tag,
      seladdr    => x"00000",
      incdelay   => sig_incdelay2, -- out
      linkup     => sta_linkup,    -- out
      linkdn     => sta_linkdn,    -- out
      data       => buf_stata,     -- out
      datb       => buf_statb,     -- out
      tagdone    => tagdone,    -- out
      cntpkterr  => cnt_pkterr, -- out
      cntrdelay  => cnt_rdelay, -- out
      sigdump    => sigdump ); -- out
  
  -- out-async
  linkup     <= sta_linkup;
  linkdn     <= sta_linkdn;
  cntbit2    <= cnt_bit2;
  cntoctet   <= cnt_octet;
  isk        <= buf_isk;
  octet      <= buf_octet;
  bit2       <= sig_bit2;
  stata      <= buf_stata;
  statb      <= buf_statb;

  statc(31 downto 30) <= cnt_pkterr;
  statc(29 downto 28) <= cnt_realign;
  statc(27 downto 16) <= cnt_rdelay;
  statc(15)           <= cnt_invalid(cnt_invalid'left);
  statc(14 downto 13) <= sta_iddr;
  statc(12 downto  7) <= cnt_width;
  statc(6  downto  0) <= cnt_delay;
  
  sigila(95) <= sta_linkup;
  sigila(94) <= sta_octet;
  sigila(93) <= sta_crc8ok;
  sigila(92) <= sig_payload;

  
  sigila(91) <= reset;
  sigila(90) <= buf_isk;
  sigila(89 downto 82) <= buf_octet;
  sigila(81 downto 80) <= sig_bit2;
  sigila(79 downto 77) <= cnt_bit2;
  sigila(76 downto 72) <= cnt_octet;
  sigila(71 downto 70) <= sta_iddr;
  sigila(69 downto 64) <= cnt_width;
  sigila(63 downto 57) <= cnt_delay;
  sigila(56 downto 47) <= sta_iddrdbg;

  sigila(21)           <= sta_defer;
  sigila(20)           <= sig_obusy;
  sigila(19 downto 16) <= cnt_dato;
  sigila(15 downto 12) <= sta_errbit;
  sigila(11 downto  0) <= buf_stata(11 downto 0);

  --stata(11) <= sta_feeerr;  -- payload(80)
  --stata(10) <= sta_ttlost;  -- payload(79)
  --stata(9)  <= sta_b2llost; -- payload(78)
  --stata(8)  <= sta_tagerr;  -- payload(77)
  --stata(7)  <= sta_fifoerr; -- payload(76)
  --stata(6)  <= sta_fifoful; -- payload(75)
  --stata(5 downto 4) <= sta_seuerr; -- payload(69 downto 68)
  --stata(3)  <= sta_b2lup;   -- payload(90)
  --stata(2)  <= sta_plllk;   -- payload(17)
  --stata(1)  <= sta_ttup;    -- payload(91)
  --stata(0)  <= sta_alive;
  
end implementation;
