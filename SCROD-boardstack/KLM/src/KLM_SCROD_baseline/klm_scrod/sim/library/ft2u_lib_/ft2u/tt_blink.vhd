------------------------------------------------------------------------
--
-- tt_blink.vhd --- fast clock (127MHz) to slow blink (1Hz)
--
-- Mikihiko Nakao, KEK IPNS
--
-- 20130514 0.01  renamed from mnclockled
------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tt_blink is
  generic (
    CYCLE : integer := 127216000;
    NBIT  : integer := 26 ); -- 2^(26+1)-1 = 134217727 > 127216000
  port (
    clock:  in  std_logic;
    blink:  out std_logic );

end tt_blink;

architecture implementation of tt_blink is
  signal count     : std_logic_vector (NBIT-2 downto 0) := (others => '0');
  signal sig_blink : std_logic := '0';
begin
  blink <= sig_blink;
  
  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if count = CYCLE/2 - 1 then
        count <= (others => '0');
        sig_blink <= not sig_blink;
      else
        count <= count + 1;
      end if;
    end if;
  end process;

end implementation;
