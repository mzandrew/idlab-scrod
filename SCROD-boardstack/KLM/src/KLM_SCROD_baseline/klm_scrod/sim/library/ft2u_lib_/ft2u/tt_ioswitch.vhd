------------------------------------------------------------------------
-- tt_ioswitch.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
-- 20120207  first version for FTSW
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

entity tt_ioswitch is
  port (
    clock  : in    std_logic;
    --
    ads    : in    std_logic;
    wr     : in    std_logic;
    a      : in    std_logic_vector (11 downto 0);
    d      : inout std_logic_vector (31 downto 0);
    --
    regin  : out   std_logic_vector (31 downto 0);
    regout : in    std_logic_vector (31 downto 0);
    --
    fmcads : out   std_logic;
    fmcwr  : out   std_logic;
    fmca   : out   std_logic_vector (6  downto 0);
    fmcd   : inout std_logic_vector (7  downto 0) );
    
end tt_ioswitch;
------------------------------------------------------------------------
architecture implementation of tt_ioswitch is
  signal afmc : std_logic := '0';
  signal avif : std_logic := '0';
  signal wrd  : std_logic := '0';
begin
  -- fmcads when a is 070..07f
  avif   <= '1' when a(11 downto 4) = x"00" else '0';
  afmc   <= '1' when a(11 downto 4) = x"0f" else '0';

  d    <= (others => 'Z')  when wrd  = '1' else
          x"000000" & fmcd when afmc = '1' else
          regout           when avif = '0' else
          (others => 'Z');

  regin  <= d;
  fmcads <= ads and afmc;
  fmcwr  <= wr  and afmc;
  fmcd   <= d(7 downto 0) when (wr and afmc) = '1' else (others => 'Z');
  fmca   <= "000" & a(3 downto 0);

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      wrd <= wr;
    end if;
  end process;
  
end implementation;
