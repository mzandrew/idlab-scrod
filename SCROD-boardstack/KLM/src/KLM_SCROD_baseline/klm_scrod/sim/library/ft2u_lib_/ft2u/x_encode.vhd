------------------------------------------------------------------------
--
--- x_encode.vhd
---
--  Mikihiko Nakao, KEK IPNS
--  20130613 0.01  new
--  20130617 0.04  fixed
--  20130719 0.05  reverse the order of output
--  20131020 0.06  run reset is added (data is not much used yet)
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

entity x_encode is
  port (
    clock    : in  std_logic;
    runreset : in  std_logic;
    trig     : in  std_logic;
    sigframe : in  std_logic;
    frame3   : in  std_logic;
    bit2     : out std_logic_vector (1  downto 0);
    sub2     : out std_logic_vector (1  downto 0);
    dum2     : out std_logic_vector (1  downto 0);
    dbg      : out std_logic_vector (31 downto 0) );
end x_encode;

architecture implementation of x_encode is
  constant ZERO     : std_logic_vector (5  downto 0) := "010001";
  constant TRG0     : std_logic_vector (5  downto 0) := "011001";
  constant TRG1     : std_logic_vector (5  downto 0) := "011011";
  constant TRG2     : std_logic_vector (5  downto 0) := "011101";
  constant SYNC     : std_logic_vector (5  downto 0) := "000111";
  constant REVO     : std_logic_vector (5  downto 0) := "000011";
  constant COMM     : std_logic_vector (5  downto 0) := "000101";
  constant ZEROx3   : std_logic_vector (17 downto 0) := "010001010001010001";

  signal sig_frame3 : std_logic := '0';
  signal sig_sync   : std_logic := '0';
  signal sig_sync2  : std_logic := '0';
  signal cnt_ttim   : std_logic_vector (1  downto 0) := (others => '0');
  signal cnt_bit2   : std_logic_vector (3  downto 0) := (others => '0');
  signal cnt_packet : std_logic_vector (7  downto 0) := (others => '0');
  signal seq_bit2   : std_logic_vector (29 downto 0) := (others => '0');
  signal seq_sub2   : std_logic_vector (29 downto 0) := (others => '0');
  signal seq_dum2   : std_logic_vector (5  downto 0) := (others => '0');
  signal buf_nib4x3 : std_logic_vector (17 downto 0) := ZEROx3;

  signal buf_trig   : std_logic_vector (1  downto 0) := "11";

  signal cnt_frame  : std_logic_vector (3  downto 0) := (others => '0');
  signal cnt_frame3 : std_logic_vector (3  downto 0) := (others => '0');
  signal cnt_sig3   : std_logic_vector (3  downto 0) := (others => '0');

  signal buf_data   : std_logic_vector (8  downto 0) := (others => '0');
  signal buf_data0  : std_logic_vector (3  downto 0) := "1000";
  signal buf_data1  : std_logic_vector (3  downto 0) := "1000";
  signal buf_data2  : std_logic_vector (3  downto 0) := "1000";
begin
  
  -- in (async)
  -- lower bit sent first, but higher nibble sent first
  sig_frame3 <= sigframe and frame3;
  sig_sync2 <= '1' when cnt_packet = 255 and sig_frame3 = '1' else sig_sync;

  buf_nib4x3 <= '0' & buf_data0 & "10" & buf_data1 & "10" & buf_data2 & '1';
  
  buf_data0 <= not buf_data(2) & buf_data(2 downto 0);
  buf_data1 <= not buf_data(5) & buf_data(5 downto 3);
  buf_data2 <= not buf_data(8) & buf_data(8 downto 6);

  -- proc
  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      -- cnt_frame(3)
      if sigframe = '1' then
        cnt_frame <= cnt_frame + 1;
      end if;
      if frame3 = '1' then
        cnt_frame3 <= cnt_frame3 + 1;
      end if;
      if sig_frame3 = '1' then
        cnt_sig3 <= cnt_sig3 + 1;
      end if;

      -- buf_data
      if runreset = '1' then
        buf_data <= "000000001";
      elsif cnt_bit2 = 14 then
        buf_data <= "000000000";
      end if;      

      -- cnt_ttim, cnt_bit2, cnt_packet, sig_sync
      if sig_frame3 = '1' then
        if cnt_bit2 = 14 and cnt_packet = 255 then
          sig_sync <= '1';
        else
          sig_sync <= '0';
        end if;
        cnt_ttim   <= "00";
        cnt_bit2   <= (others => '0');
        cnt_packet <= (others => '0');
      elsif cnt_bit2 = 14 then
        if cnt_packet = 255 then
          sig_sync <= '0';
        end if;
        cnt_packet <= cnt_packet + 1;
        cnt_bit2   <= (others => '0');
        cnt_ttim   <= "00";
      else
        if cnt_ttim = 2 then
          cnt_ttim <= "00";
        else
          cnt_ttim <= cnt_ttim + 1;
        end if;
        cnt_bit2   <= cnt_bit2 + 1;
      end if;

      -- seq_dum2
      if cnt_bit2 = 14 then
        seq_dum2 <= SYNC;
      else
        seq_dum2 <= seq_dum2(1 downto 0) & seq_dum2(5 downto 2);
      end if;

      -- seq_bit2, seq_sub2
      if cnt_bit2 = 14 then
        
        if trig = '1' and sig_sync2 = '1' then
          seq_bit2 <= SYNC & buf_nib4x3 & TRG2;
          seq_sub2 <= SYNC &     ZEROx3 & TRG2;
        elsif buf_trig /= "11" and sig_sync2 = '1' then
          seq_bit2 <= SYNC & buf_nib4x3 & "011" & buf_trig & "1";
          seq_sub2 <= SYNC &     ZEROx3 & "011" & buf_trig & "1";
        elsif cnt_packet = 255 and sig_frame3 = '1' then
          seq_bit2 <= SYNC & buf_nib4x3 & REVO;
          seq_sub2 <= SYNC &     ZEROx3 & REVO;
        elsif sig_sync = '0' then
          seq_bit2 <= SYNC & SYNC & SYNC & SYNC & SYNC;
          seq_sub2 <= SYNC & SYNC & SYNC & SYNC & SYNC;
        else
          seq_bit2 <= SYNC & buf_nib4x3 & COMM;
          seq_sub2 <= SYNC &     ZEROx3 & COMM;
        end if;
        
      elsif trig = '1' and cnt_ttim = 2 then
        seq_bit2 <= "00" & seq_bit2(23 downto 2) & TRG2;
        seq_sub2 <= "00" & seq_sub2(23 downto 2) & TRG2;
      elsif trig = '1' and cnt_ttim = 1 then
        seq_bit2 <= "00" & seq_bit2(23 downto 4) & TRG1 & seq_bit2(3 downto 2);
        seq_sub2 <= "00" & seq_sub2(23 downto 4) & TRG1 & seq_sub2(3 downto 2);
      elsif trig = '1' and cnt_ttim = 0 then
        seq_bit2 <= "00" & seq_bit2(23 downto 6) & TRG0 & seq_bit2(5 downto 2);
        seq_sub2 <= "00" & seq_sub2(23 downto 6) & TRG0 & seq_sub2(5 downto 2);
      else
        seq_bit2 <= "00" & seq_bit2(29 downto 2);
        seq_sub2 <= "00" & seq_sub2(29 downto 2);
      end if;

      -- buf_trig
      if trig = '1' then
        buf_trig <= cnt_ttim;
      elsif cnt_ttim = 2 then
        buf_trig <= "11";
      end if;
    
    end if; -- event

  end process;

  -- out
  bit2 <= seq_bit2(0) & seq_bit2(1);
  sub2 <= seq_sub2(0) & seq_sub2(1);
  dum2 <= seq_dum2(0) & seq_dum2(1);

  dbg(31 downto 16) <= cnt_sig3 & cnt_frame3 & cnt_frame & x"0";
  dbg(15 downto 12) <= sig_sync & '0' & cnt_ttim;
  dbg(11 downto  0) <= cnt_bit2 & cnt_packet;
  
end implementation;
