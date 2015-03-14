------------------------------------------------------------------------
-- tt_oclk.vhd (FTSW2 only)
--
-- Mikihiko Nakao, KEK IPNS
-- 
--  20130727 new
--  20130801 en -> disable
--  20130922 autojtag added
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

entity tt_oclk is
  port (
    clock    : in  std_logic;
    clk_p    : out std_logic_vector (20 downto 1);
    clk_n    : out std_logic_vector (20 downto 1);
    xmask    : in  std_logic_vector (4  downto 1);
    omask    : in  std_logic_vector (7  downto 0);
    xorclk   : in  std_logic_vector (7  downto 0);
    autojtag : in  std_logic;
    enjtag   : in  std_logic_vector (7  downto 0);
    tck      : in  std_logic );
end tt_oclk;
------------------------------------------------------------------------
architecture implementation of tt_oclk is

  signal sig_omask : std_logic_vector (7 downto 0) := (others => '0');
  signal sig_tck   : std_logic_vector (7 downto 0) := (others => '0');

begin
  gen_x: for i in 1 to 4 generate
    map_x: obuftds port map
      ( i => clock, o => clk_p(i), ob => clk_n(i), t => xmask(i) );
      
  end generate;

  gen_o: for i in 0 to 7 generate
    sig_omask(i) <= omask(i) xor xorclk(i);
    sig_tck(i)   <= tck and (autojtag or enjtag(i));
    
    map_o: obuftds port map
      ( i => clock, o => clk_p(i*2+5), ob => clk_n(i*2+5), t => sig_omask(i) );
    
    map_j: obufds port map
      ( i => sig_tck(i), o => clk_p(i*2+6), ob => clk_n(i*2+6) );
  end generate;
  
end implementation;
