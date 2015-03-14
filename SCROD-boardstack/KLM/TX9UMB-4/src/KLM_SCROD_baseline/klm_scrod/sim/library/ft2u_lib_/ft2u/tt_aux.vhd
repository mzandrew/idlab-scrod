------------------------------------------------------------------------
--
-- tt_aux component
--
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity tt_aux is
  generic (
    NBIT   : integer := 6 );
  port (
    auxp   : out std_logic;
    auxn   : out std_logic;
    regsel : in  std_logic_vector (NBIT-1 downto 0);
    osig   : in  std_logic_vector ((2**NBIT)-1 downto 0) );
end tt_aux;

architecture implementation of tt_aux is
  signal sig_t : std_logic := '0';
  signal sig_o : std_logic := '0';
begin
  --map_i: ibufds  port map ( i => auxp, ib => auxn, o => aux );
  map_o: obuftds port map ( o => auxp, ob => auxn, i => sig_o, t => sig_t );

  sig_t <= '1' when regsel = 0 else '0';
  sig_o <= osig(conv_integer(regsel));
end implementation;
