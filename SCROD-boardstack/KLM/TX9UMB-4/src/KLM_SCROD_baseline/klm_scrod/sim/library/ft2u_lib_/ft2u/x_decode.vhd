------------------------------------------------------------------------
--
--- x_decode.vhd
---
--  Mikihiko Nakao, KEK IPNS
--  20130613 0.01  new
--  20130619 0.05  fixed, still with debug code
--  20130801 en -> disable
--  20131027 b2tt_ddr
--  20140114 sig_inc at linkdown
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

entity x_decode is
  port (
    clock    : in  std_logic;
    reset    : in  std_logic;
    disable  : in  std_logic;
    ackp     : in  std_logic;
    ackn     : in  std_logic;
    manual   : in  std_logic;
    clrdelay : in  std_logic;
    incdelay : in  std_logic;
    bsyout   : out std_logic;
    cntfbsy  : out std_logic_vector (15 downto 0);
    cntsbsy  : out std_logic_vector (15 downto 0);
    bitddr   : out std_logic;
    xdata    : out std_logic_vector (63 downto 0);
    sigila   : out std_logic_vector (95 downto 0) );
end x_decode;

architecture implementation of x_decode is

  constant ZERO    : std_logic_vector (5  downto 0) := "000011";
  constant BUSY    : std_logic_vector (5  downto 0) := "011001";
  constant FREE    : std_logic_vector (5  downto 0) := "000111";
  constant SYNC    : std_logic_vector (5  downto 0) := "000001";
  constant COMM    : std_logic_vector (5  downto 0) := "011111";

  signal sig_q     : std_logic := '0';
  signal sig_inc   : std_logic := '0';
  signal sig_ddr   : std_logic := '0';
  signal sig_bit2  : std_logic_vector (1  downto 0) := (others => '1');
  
  signal cnt_bit2  : std_logic_vector (1  downto 0) := (others => '0');
  signal cnt_nib   : std_logic_vector (2  downto 0) := (others => '0');
  signal buf_nib6  : std_logic_vector (5  downto 0) := (others => '0');
  signal cnt_data  : std_logic_vector (2  downto 0) := (others => '0');
  signal seq_data  : std_logic_vector (17 downto 0) := (others => '0');
  signal buf_data  : std_logic_vector (17 downto 0) := (others => '0');
  signal sta_busy  : std_logic := '0';
  signal cnt_sync  : std_logic_vector (11 downto 0) := (others => '0');
  signal cnt_async : std_logic_vector (15 downto 0) := (others => '0');
  signal sta_cntb2 : std_logic_vector (1  downto 0) := (others => '0');

  signal seq_inc   : std_logic_vector (1  downto 0) := (others => '0');
  
  signal cnt_fbsy  : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_sbsy  : std_logic_vector (15 downto 0) := (others => '0');
  signal seq_fbsy  : std_logic := '0';
  signal sta_sbsy  : std_logic := '0';
  signal sig_sbsy  : std_logic := '0';

  signal cnt_delay : std_logic_vector (6  downto 0) := (others => '0');
  signal cnt_width : std_logic_vector (5  downto 0) := (others => '0');
  
  signal sta_alive  : std_logic := '0';
  signal sta_linkup : std_logic := '0';
  signal seq_linkup : std_logic := '0';
  signal sta_linkdn : std_logic := '0';

  signal sta_iddr    : std_logic_vector (1  downto 0) := (others => '0');
  signal sta_iddrdbg : std_logic_vector (9  downto 0) := (others => '0');
begin
  -- in
  sta_alive <= cnt_sync(cnt_sync'left);
  
  --          (enabled      and (bsy          or full))
  sta_sbsy <= (seq_data(17) and (seq_data(13) or seq_data(9))) or
              (seq_data(16) and (seq_data(12) or seq_data(8))) or
              (seq_data(15) and (seq_data(11) or seq_data(7))) or
              (seq_data(14) and (seq_data(10) or seq_data(6))) or
              seq_data(1); -- NWFF

  map_ddr: entity work.b2tt_iddr
    port map (
      clock      => clock,
      invclock   => '0', -- spartan6 only
      dblclock   => '0', -- virtex6 only
      dblclockb  => '1', -- virtex6 only
      inp        => ackp,
      inn        => ackn,
      staoctet   => cnt_sync(cnt_sync'left) ,
      stacrc8ok  => '1',
      manual     => manual,
      incdelay   => incdelay,
      clrdelay   => clrdelay,
      caldelay   => '0', -- spartan6 only
      staiddr    => sta_iddr,      -- out
      bitddr     => sig_ddr,       -- out
      bit2       => sig_bit2,      -- out
      cntdelay   => cnt_delay,     -- out
      cntwidth   => cnt_width,     -- out
      iddrdbg    => sta_iddrdbg ); -- out
  
  -- proc
  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- buf_nib6 is valid when cnt_bit2 = 2
      -- seq_data is valid when cnt_bit2 = 0 and cnt_data = 6
      -- from cnt_bit2 = 1 and cnt_data = 0, use buf_data

      -- bsyout count
      if reset = '1' then
        cnt_fbsy <= (others => '0');
      elsif cnt_sync(cnt_sync'left) = '1' and
            cnt_bit2 = 1 and buf_nib6(5 downto 2) = "1001" then
        cnt_fbsy <= cnt_fbsy + 1;
      end if;
      if reset = '1' then
        cnt_sbsy <= (others => '0');
      elsif sig_sbsy = '1' then
        cnt_sbsy <= cnt_sbsy + 1;
      end if;

      -- bsyout
      -- at cnt_bit2 = 2, BUSY means buf_nib6 = 0 1100 1
      -- at cnt_bit2 = 2, FREE means buf_nib6 = 0 0011 1
      -- so, at a clock earlier (i.e. cnt_bit = 1,)
      -- at cnt_bit2 = 1, BUSY means buf_nib6 = 100 1 0x
      -- at cnt_bit2 = 1, FREE means buf_nib6 = 011 1 0x
      if sta_alive = '0' then
        -- nothing
      elsif cnt_bit2 = 1 and buf_nib6(5 downto 2) = "1001" then
        sta_busy <= '1';
        seq_fbsy <= '1';
      elsif cnt_bit2 = 1 and buf_nib6(5 downto 2) = "0111" then
        sta_busy <= '0';
        seq_fbsy <= '1';
      elsif cnt_bit2 = 0 and cnt_data = 6 then
        if seq_fbsy = '0' then
          sta_busy <= sta_sbsy;
        end if;
        seq_fbsy <= '0';
      end if;
      
      if cnt_bit2 = 0 and cnt_data = 6 and seq_fbsy = '0' then
        sig_sbsy <= sta_sbsy and (not sta_busy);
      else
        sig_sbsy <= '0';
      end if;

      -- cnt_bit2
      if cnt_bit2 = 3 and buf_nib6 = COMM then
        cnt_bit2 <= "00"; -- newly found COMM
      elsif cnt_bit2 = 3 then
        -- nothing
      elsif cnt_bit2 = 2 and cnt_nib = 7 and buf_nib6 = COMM then
        cnt_bit2 <= "00"; -- COMM at right place
      elsif cnt_bit2 = 2 and cnt_nib = 6 and buf_nib6 = SYNC then
        cnt_bit2 <= "00"; -- SYNC at right place
      elsif buf_nib6 = COMM or buf_nib6 = SYNC then
        cnt_bit2 <= "11";  -- COMM or SYNC at wrong place
        sta_cntb2 <= "10";
      elsif cnt_bit2 = 2 then
        if cnt_nib = 7 and (not (buf_nib6 = BUSY or buf_nib6 = FREE)) then
          cnt_bit2 <= "11";  -- no COMM/BUSY/FREE at the first nibble
          sta_cntb2 <= "10";
        elsif buf_nib6(5) = '1' or buf_nib6(0) = '0' then
          cnt_bit2 <= "11";  -- invalid start or stop bit
          sta_cntb2 <= "11";
        else
          cnt_bit2 <= "00";
        end if;
      else
        cnt_bit2 <= cnt_bit2 + 1;
        if sta_alive = '1' then
          sta_cntb2 <= "00";
        end if;
      end if;
      
      -- cnt_nib
      if cnt_bit2 = 3 and buf_nib6 = COMM then
        cnt_nib <= (others => '0');
      elsif cnt_bit2 = 2 then
        if cnt_nib = 7 then
          cnt_nib <= (others => '0');
        else
          cnt_nib <= cnt_nib + 1;
        end if;
      end if;

      -- cnt_data / seq_data / data
      if cnt_bit2 = 3 then
        cnt_data <= "000";
        seq_data <= (others => '0');
      elsif cnt_bit2 = 2 then
        if buf_nib6(2) /= buf_nib6(1) then
          seq_data <= seq_data(seq_data'left - 3 downto 0) &
                      buf_nib6(4 downto 2);
          cnt_data <= cnt_data + 1;
        end if;
      elsif cnt_bit2 = 0 then
        if cnt_data = 6 then
          if disable = '1' then
            buf_data(17 downto 14) <= seq_data(17 downto 14);
            buf_data(13 downto 1) <= (others => '0');
            buf_data(0) <= seq_data(0);
          else
            buf_data <= seq_data;
          end if;
        end if;
        if cnt_data = 6 or cnt_nib = 0 then
          cnt_data <= "000";
        end if;
      end if;

      -- cnt_sync
      if cnt_bit2 = "11" then
        cnt_sync <= (others => '0');
      elsif buf_nib6 = SYNC and sta_alive = '0' then
        cnt_sync <= cnt_sync + 1;
      end if;

      -- cnt_async
      if sta_alive = '1' then
        cnt_async <= (others => '0');
      elsif cnt_async(cnt_async'left) = '1' then
        cnt_async <= (others => '0');
      else
        cnt_async <= cnt_async + 1;
      end if;
      
      -- buf_nib6 (sig_bit2 order is flipped)
      buf_nib6 <= sig_bit2(0) & sig_bit2(1) & buf_nib6(5 downto 2);

      if reset = '1' or disable = '1' then
        seq_linkup <= sta_linkup;
        sta_linkdn <= '0';
      else
        seq_linkup <= seq_linkup and sta_linkup;
        sta_linkdn <= sta_linkdn or (seq_linkup and (not sta_linkup));
      end if;
      sta_linkup <= sta_alive and buf_data(0);
    end if; -- event

  end process;

  -- out
  bitddr   <= sig_ddr;
  bsyout   <= sta_busy when disable = '0' else '0';
  cntfbsy  <= cnt_fbsy;
  cntsbsy  <= cnt_sbsy;
  
  xdata(63 downto 46) <= buf_data;
  xdata(45 downto 25) <= (others => '0'); -- future buf_data extension
  xdata(24 downto 24) <= (others => '0'); -- future x_decode extension
  xdata(23 downto 22) <= sig_bit2;
  xdata(21 downto 20) <= cnt_bit2;
  xdata(19 downto 18) <= sta_cntb2;
  xdata(17 downto 12) <= cnt_width;
  xdata(11)           <= sta_linkdn;
  xdata(10 downto  4) <= cnt_delay;
  xdata(3  downto  2) <= sta_iddr;
  xdata(1)            <= sta_linkup;
  xdata(0)            <= sta_alive;

  sigila(95) <= sta_linkup;
  sigila(94) <= sta_alive;
  sigila(93) <= reset;
  sigila(92 downto 75) <= buf_data;
  sigila(74 downto 65) <= sta_iddrdbg;
  sigila(64 downto 59) <= cnt_width;
  sigila(58 downto 52) <= cnt_delay;
  sigila(51 downto 50) <= sig_bit2;
  sigila(49) <= sig_inc;
  sigila(48 downto 46) <= cnt_data;
  sigila(45 downto 44) <= cnt_bit2;
  sigila(43 downto 42) <= sta_iddr;
  sigila(41 downto 36) <= buf_nib6;
  sigila(35 downto 28) <= seq_data(17 downto 10);
  sigila(27 downto 16) <= cnt_sync;
  sigila(15 downto  0) <= cnt_async;
  
end implementation;
