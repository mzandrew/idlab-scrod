------------------------------------------------------------------------
-- m_fifo component
--
-- RAMB18 usage
--
-- RAMB36 usage (ug190 v4.3 p111)
--  port A - 8-bit I/O, auto incrementing address
--  port B - 8 or 16 or 32-bit I/O, read only
--
-- - 21 bit address space (20 downto 0) to cover 2 Mbit space,
--   or up to 64 ramb36 blocks (each ramb36 has 4096 bytes).
--
-- - V5LX30(FTSW) has 32 ramb36
--   V5LX30T(MGTF) has 36 ramb36
--   V5LX50T(HSLB) has 60 ramb36
--
-- - each ramb36 has address space of
--    (14 downto 0) for 32768 bit
--    (14 downto 3) for 4096 byte
--    (14 downto 4) for 2048 word (16-bit)
--    (14 downto 5) for 1024 long (32-bit)
--
--
--  fifo data format
--    word 0: bit 31:28   trig type
--            bit 27      not empty
--            bit 26:0    ctime
--    word 1: bit 31:0    utime
--    word 2: bit 31:0    trig tag
--    word 3: bit 31:16   0
--            bit 15:0    tlu tag
--
--  if empty, read out word is 0xffffffff
--  
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;
library work;
use work.tt_types.all;

entity m_fifo is
  port (
    clock  : in  std_logic;
    clr    : in  std_logic;
    wra    : in  std_logic;
    trgtyp : in  std_logic_vector (3 downto 0);
    utime  : in  std_logic_vector (31 downto 0);
    ctime  : in  std_logic_vector (26 downto 0);
    trgcnt : in  std_logic_vector (31 downto 0);
    tlutag : in  std_logic_vector (15 downto 0);
    rdb    : in  std_logic;
    doutb  : out std_logic_vector (31 downto 0);
    nofifo : in  std_logic;
    err    : out std_logic;
    empty  : out std_logic;
    ahib   : out std_logic_vector (1  downto 0);
    orun   : out std_logic;
    full   : out std_logic;
    dbg    : out std_logic_vector (31 downto 0) );
end m_fifo;

architecture implementation of m_fifo is
  signal sig_dina  : long_vector (3 downto 0) := (others => x"00000000");
  signal sig_doutb : long_vector (3 downto 0) := (others => x"00000000");

  signal buf_addra : std_logic_vector (9  downto 0) := (others => '0');
  signal buf_addrb : std_logic_vector (9  downto 0) := (others => '0');
  signal cnt_ahib  : std_logic_vector (1  downto 0) := "00";
  signal sta_adiff : std_logic_vector (9  downto 0) := (others => '0');

  signal seq_wra   : std_logic_vector (1  downto 0) := (others => '0');
  signal seq_rdb   : std_logic_vector (1  downto 0) := (others => '0');

  signal seq_dina  : std_logic_vector (3  downto 0) := (others => '0');
  signal buf_dina  : std_logic_vector (63 downto 0) := (others => '0');
  signal seq_doutb : std_logic_vector (3  downto 0) := (others => '0');
  signal buf_doutb : std_logic_vector (63 downto 0) := (others => '0');
  
  signal seq_empty : std_logic := '0';
  signal sta_empty : std_logic := '0';
  signal sta_full  : std_logic := '0';
  signal sta_orun  : std_logic := '0';

  signal sig_rdb   : std_logic := '0';
  signal sig_wra   : std_logic_vector (3  downto 0) := (others => '0');
  signal sta_tag   : std_logic_vector (15 downto 0) := (others => '0');

  -- for poor simulator
  signal open_doa  : std_logic_vector (127 downto 0) := (others => '0');
  signal open_dopa : std_logic_vector (15  downto 0) := (others => '0');
  signal open_dopb : std_logic_vector (15  downto 0) := (others => '0');
  signal open_unused : std_logic_vector (15  downto 0) := (others => '0');
begin
  -- in
  sta_empty <= '1' when buf_addra = buf_addrb else '0';
  --sta_tag   <= trgcnt(15 downto 0) + 1;
  sta_tag   <= trgcnt(15 downto 0); -- start from 0
  --sig_dina  <= '0' & ctime & trgtyp & utime(15 downto 0) & sta_tag;
  sig_dina(0) <= '0' & ctime & trgtyp;
  sig_dina(1) <= utime;
  sig_dina(2) <= trgcnt;
  sig_dina(3) <= x"0000" & tlutag(15 downto 0);

  --  addra  addrb  empty wr seqwr doutb
  --  0      0      111   0  00    ffff
  --  0      0      111   1  00    ffff
  --  0      0      111   0  01    ffff
  --  0      0      111   0  10    ffff
  --  1      0      110   0  00    ffff
  --  1      0      100   0  00    dat0
  --  1      0      000   rd seqrd dat0
  --  1      0      0     0  00    dat0
  --  1      0      0     1  00    dat0
  --  1      0      0     1  01
  --  1      0      0     1  11
  --  1      0      0     0  11
  --  1      0      0     0  10    dat0
  --  1      1      1     0  00    dat0
  --  1      1      1     0  00    ffff
  

  
  proca: process (clock)
  begin
    if clock'event and clock = '1' then
      -- sig_wra (one clock delay to write fifo)
      sig_wra   <= wra & wra & wra & wra;

      -- sig_rdb (in clk_s domain)
      sig_rdb   <= rdb;

      -- seq_empty
      --seq_empty <= not ((not sta_empty) and (not sig_rdb));
      seq_empty <= sta_empty or sig_rdb;

      -- buf_addra
      if clr = '1' then
        buf_addra <= (others => '0');
      elsif seq_wra = "10" then
        buf_addra <= buf_addra + 1;  -- turn over to 0
      end if;

      -- buf_addrb
      if clr = '1' then
        buf_addrb <= (others => '0');
      elsif seq_rdb = "10" and cnt_ahib = "11" then
        buf_addrb <= buf_addrb + 1;  -- turns over to 0
      end if;

      -- cnt_ahib
      if clr = '1' then
        cnt_ahib <= "00";
      elsif seq_rdb = "10" then
        cnt_ahib <= cnt_ahib + 1;
      end if;

      -- buf_doutb
      if sig_rdb = '1' then
        -- don't change doutb even if data is filled during read
      elsif sta_empty = '1' then
        doutb <= (others => '1');
      else
        doutb <= sig_doutb(conv_integer(cnt_ahib));
      end if;
      
      -- seq_wra, seq_rdb
      seq_wra <= seq_wra(0) & (wra and not sta_full);
      seq_rdb <= seq_rdb(0) & (sig_rdb and not seq_empty);
      
      -- sta_adiff
      if buf_addrb > buf_addra then
        sta_adiff <= buf_addra + 1024 - buf_addrb;
      else
        sta_adiff <= buf_addra - buf_addrb;
      end if;

      -- sta_orun
      if clr = '1' then
        sta_orun <= '0';
      elsif sta_full = '1' and wra = '1' then
        sta_orun <= '1';
      end if;
      
      -- sta_full
      if clr = '1' then
        sta_full <= '0';
      elsif sta_adiff >= 1020 and nofifo = '0' then
        sta_full <= '1';
      else
        sta_full <= '0';
      end if;
        
    end if;
  end process;

  -- RAMB36
  gen_ramb36: for i in 0 to 3 generate
    map_ram: ramb36
      generic map (
        READ_WIDTH_A => 36, WRITE_WIDTH_A => 36,
        READ_WIDTH_B => 36, WRITE_WIDTH_B => 36 )
    
      port map (
        -- port A
        addra(15)           => '0',
        addra(14 downto 5)  => buf_addra,
        addra(4  downto 0)  => "00000",
        dia                 => sig_dina(i),
        dipa                => "0000",
        doa                 => open_doa(i*32+31 downto i*32),
        dopa                => open_dopa(i*4+3 downto i*4),
        wea                 => sig_wra,
        ena                 => '1',
        ssra                => '0',
        regcea              => '1',
        clka                => clock,
        
        -- port B
        addrb(15)           => '0',
        addrb(14 downto 5)  => buf_addrb,
        addrb(4  downto 0)  => "00000",
        dib                 => x"00000000",
        dipb                => "0000",
        dob                 => sig_doutb(i),
        dopb                => open_dopb(i*4+3 downto i*4),
        web                 => "0000",
        enb                 => '1',
        ssrb                => '0',
        regceb              => '1',
        clkb                => clock,

        -- unused
        cascadeinlata       => '0',
        cascadeinlatb       => '0',
        cascadeinrega       => '0',
        cascadeinregb       => '0',
        cascadeoutlata      => open_unused(i*4+0),
        cascadeoutlatb      => open_unused(i*4+1),
        cascadeoutrega      => open_unused(i*4+2),
        cascadeoutregb      => open_unused(i*4+3) );

    end generate;
  
  -- out
  err    <= sta_full or sta_orun;
  empty  <= sta_empty;
  ahib   <= cnt_ahib;
  orun   <= sta_orun;
  full   <= sta_full;

  dbg <= sta_empty & sta_full & buf_addra & buf_addrb & sta_adiff;
  
end implementation;
