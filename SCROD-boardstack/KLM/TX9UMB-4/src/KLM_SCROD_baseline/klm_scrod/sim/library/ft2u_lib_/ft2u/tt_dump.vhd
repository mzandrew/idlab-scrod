------------------------------------------------------------------------
-- tt_dump.vhd
--
-- 20120427 dump TT link bit stream
-- 20130411 renamed from b2tt_dump to tt_dump
-- 20140403 
--
-- 1. every clock, store 2 bit into sta_320
-- 2. every 5 clock, store octet + k into sta_256 and sta_32
-- 3. then by asserting dump, these buffers are copied into
--    regraw, regoctet, regisk after 2 clocks
-- 4. at the same time, a few more info can be saved in snapshot
-- 5. 20x (32-bit-)word address space is needed
--
-- Mikihiko Nakao, KEK IPNS
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;
library work;
use work.tt_types.all;

entity tt_dump is
  generic (
    CNTOCTET : integer := 2;
    NDUMP    : integer := 16 );
  port (
    clock     : in std_logic;
    dump      : in std_logic;
    sigdump   : in std_logic;
    autodump  : in std_logic;
    delay     : in std_logic7;
    idump     : in std_logic4;
    bit2      : in std_logic2_vector (NDUMP-1 downto 0);
    cnt2      : in std_logic3_vector (NDUMP-1 downto 0);
    cnto      : in std_logic5_vector (NDUMP-1 downto 0);
    octet     : in byte_vector       (NDUMP-1 downto 0);
    isk       : in std_logic_vector  (NDUMP-1 downto 0);
    regraw    : out long_vector (9 downto 0);
    regoctet  : out long_vector (7 downto 0);
    regisk    : out long_t;
    snapshot  : out long_t );
  
end tt_dump;
------------------------------------------------------------------------
architecture implementation of tt_dump is
  signal buf_256     : std_logic_vector (255 downto 0) := (others => '0');
  signal sta_256     : std_logic_vector (255 downto 0) := (others => '0');
  signal sta_32      : std_logic_vector (31  downto 0) := (others => '0');
  
  signal buf_320     : std_logic_vector (319 downto 0) := (others => '0');
  signal sta_320     : std_logic_vector (319 downto 0) := (others => '0');

  signal seq_dump    : std_logic_vector (2   downto 0) := (others => '0');
  
  signal seq_counter : std_logic_vector (2   downto 0) := (others => '0');
  signal cnt_counter : std_logic_vector (15  downto 0) := (others => '0');

  signal cnt_wait : std_logic7;
  
begin
  gen_256i: for i in 0 to 7 generate
    regoctet(i) <= buf_256(32*i+31 downto 32*i);
  end generate;
  gen_320i: for i in 0 to 9 generate
    regraw(i) <= buf_320(32*i+31 downto 32*i);
  end generate;
  
  proc: process (clock)
    variable i : integer;
  begin
    i := conv_integer(idump);
    
    if clock'event and clock = '1' then
      sta_320 <= sta_320(317 downto 0) & bit2(i);
      if autodump = '0' then
        seq_dump(1 downto 0) <= seq_dump(0) & dump;
      elsif cnt_wait = 0 then
        seq_dump(1 downto 0) <= seq_dump(0) & sigdump;
      elsif cnt_wait = 1 then
        seq_dump(1 downto 0) <= seq_dump(0) & '1';
      end if;

      if sigdump = '1' then
        cnt_wait <= delay;
      elsif cnt_wait /= 0 then
        cnt_wait <= cnt_wait - 1;
      end if;

      if cnt2(i) = CNTOCTET then
        sta_256 <= sta_256(247 downto 0) & octet(i);
        sta_32  <= sta_32(30  downto 0)  & isk(i);
      end if;
      
      if cnt2(i) = 4 then
        seq_counter <= "000";
      else
        seq_counter <= cnt2(i) + 1;
      end if;
      
      if seq_counter /= cnt2(i) then
        cnt_counter <= x"0001";
      elsif cnt_counter(15) = '0' then
        cnt_counter <= cnt_counter + 1;
      end if;
      
      if seq_dump(1 downto 0) = "01" then
        seq_dump(2) <= '1';
        
      elsif seq_dump(2) = '1' then
        seq_dump(2) <= '0';
        
        snapshot(31 downto 16) <= cnt_counter;
        snapshot(2 downto 0)   <= cnt2(i);
        snapshot(8 downto 4)   <= cnto(i);

        buf_320 <= sta_320;
        buf_256 <= sta_256;
        regisk  <= sta_32;
      end if;
    end if;
  end process;
  
end implementation;
------------------------------------------------------------------------
