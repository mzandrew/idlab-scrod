------------------------------------------------------------------------
-- tt_oack.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
--  20130514 new
--  20130922 autojtag added
--  20131027 differential output to use b2tt_ddr.vhd
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

entity tt_oack is
  port (
    ack_p    : in  std_logic_vector (20 downto 1);
    ack_n    : in  std_logic_vector (20 downto 1);
    autojtag : in  std_logic;
    enjtag   : in  std_logic_vector (7  downto 0);
    fliptdo  : in  std_logic_vector (7  downto 0);
    xackp    : out std_logic_vector (4  downto 1);
    xackn    : out std_logic_vector (4  downto 1);
    oackp    : out std_logic_vector (7  downto 0);
    oackn    : out std_logic_vector (7  downto 0);
    tdo      : out std_logic );

end tt_oack;
------------------------------------------------------------------------
architecture implementation of tt_oack is

  signal sig_xack  : std_logic_vector (4 downto 1) := (others => '0');
  signal sig_ack   : std_logic_vector (7 downto 0) := (others => '0');
  signal sig_tdoin : std_logic_vector (7 downto 0) := (others => '0');
  signal sig_tdo   : std_logic_vector (7 downto 0) := (others => '0');
  
begin
  gen_xport: for i in 1 to 4 generate
    xackp(i) <= ack_p(i);
    xackn(i) <= ack_n(i);
  end generate;
  
  gen_oport: for i in 0 to 7 generate

    oackp(i) <= ack_p(i*2+5);
    oackn(i) <= ack_n(i*2+5);

    map_tdo: ibufds port map
      ( o => sig_tdoin(i), i => ack_p(i*2+6), ib => ack_n(i*2+6) );

    sig_tdo(i) <= sig_tdoin(i) xor fliptdo(i);

  end generate;

  -- out
  tdo  <= '1' when autojtag = '0' and (sig_tdo and enjtag) /= 0   else
          '1' when autojtag = '1' and sig_tdo(0)           =  '1' else
          '0';
  
end implementation;
