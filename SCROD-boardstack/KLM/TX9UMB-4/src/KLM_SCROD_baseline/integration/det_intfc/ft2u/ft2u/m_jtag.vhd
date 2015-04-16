------------------------------------------------------------------------
-- m_jtag.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
--  20140804 new
-- 
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;
library work;
use work.tt_types.all;

entity m_jtag is
  port (
    clock    : in  std_logic;
    seljtag  : in  std_logic;
    pintck   : in  std_logic;
    pintms   : in  std_logic;
    pintdi   : in  std_logic;
    settck   : in  std_logic;
    regtck   : in  std_logic;
    regtdi   : in  std_logic;
    regtms   : in  std_logic;
    tdiblk   : in  std_logic_vector (7  downto 0);
    setblk   : in  std_logic;
    sigtck   : out std_logic;
    sigtms   : out std_logic;
    sigtdi   : out std_logic;
    err      : out std_logic_vector (4 downto 0) );
    
end m_jtag;
------------------------------------------------------------------------
architecture implementation of m_jtag is

  signal seq_tck  : std_logic_vector (1 downto 0) := "00";
  signal seq_blk  : std_logic_vector (1 downto 0) := "00";
  -- 8-bit cnt_tck* => 2us cycle
  signal cnt_tck1 : std_logic_vector (6  downto 0) := (others => '0');
  signal cnt_tck2 : std_logic_vector (8  downto 0) := (others => '0');
  signal buf_tdi  : std_logic_vector (7  downto 0) := (others => '0');

  signal sta_err  : std_logic_vector (4  downto 0) := (others => '0');
  
begin

  process (clock)
  begin
    if rising_edge(clock) then
      -- falling edge of settck and setblk
      seq_tck(1 downto 0) <= seq_tck(0) & settck;
      seq_blk(1 downto 0) <= seq_blk(0) & setblk;

      -- timing error (no way to reset)
      if cnt_tck1 /= 0 then
        sta_err(1) <= sta_err(1) or settck;
        sta_err(2) <= sta_err(2) or setblk;
      end if;
      if cnt_tck2 /= 0 then
        sta_err(0) <= '1';
        sta_err(3) <= sta_err(3) or settck;
        sta_err(4) <= sta_err(4) or setblk;
      else
        sta_err(0) <= '0';
      end if;

      -- block tdi cycle
      if seq_blk = "10" then
        buf_tdi <= tdiblk;
      elsif cnt_tck2(cnt_tck2'left-3 downto 0) = 1 then
        buf_tdi <= buf_tdi(6 downto 0) & '0';
      elsif cnt_tck2 = 0 then
        buf_tdi <= regtdi & "0000000";
      end if;
        
      -- single tck pulse generation
      if seq_tck = "10" then
        cnt_tck1(cnt_tck1'left downto 2) <= (others => '0');
        cnt_tck1(1             downto 0) <= "10";
      elsif cnt_tck1 /= 0 then
        cnt_tck1 <= cnt_tck1 + 1;
      end if;

      -- tck pulse generation
      if seq_blk = "10" then
        cnt_tck2(cnt_tck2'left downto 2) <= (others => '0');
        cnt_tck2(1             downto 0) <= "10";
      elsif cnt_tck2 /= 0 then
        cnt_tck2 <= cnt_tck2 + 1;
      end if;
    end if;
  end process;

  -- out
  sigtck <= pintck when seljtag = '0' else
            (cnt_tck1(cnt_tck1'left) or
             cnt_tck2(cnt_tck2'left-3) or
             regtck);
  sigtms <= pintms when seljtag = '0' else regtms;
  sigtdi <= pintdi when seljtag = '0' else buf_tdi(7);
  err    <= sta_err;
  
end implementation;
