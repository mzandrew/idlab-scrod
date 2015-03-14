------------------------------------------------------------------------
-- tt_orsv.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
--  20130514 new
--  20130922 autojtag added
--  20140505 clock to ttrx
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

entity tt_orsv is
  port (
    sigclk   : in  std_logic;
    rsv_p    : out std_logic_vector (20 downto 1);
    rsv_n    : out std_logic_vector (20 downto 1);
    autojtag : in  std_logic;
    enjtag   : in  std_logic_vector (7  downto 0);
    tms      : in  std_logic );
end tt_orsv;
------------------------------------------------------------------------
architecture implementation of tt_orsv is

  signal sig_tms : std_logic_vector (7 downto 0) := (others => '0');
  
begin
  gen_xport: for i in 1 to 4 generate
    --rsv_p(i) <= '0';
    --rsv_n(i) <= '0';
    map_clk: obufds port map
      ( i => sigclk, o => rsv_p(i), ob => rsv_n(i) );
  end generate;
  
  gen_oport: for i in 0 to 7 generate

    sig_tms(i)   <= tms and (autojtag or enjtag(i));

    rsv_p(i*2+5) <= '0';
    rsv_n(i*2+5) <= '0';
  
    map_tms: obufds port map
      ( i => sig_tms(i), o => rsv_p(i*2+6), ob => rsv_n(i*2+6) );

  end generate;
    
end implementation;
