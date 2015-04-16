------------------------------------------------------------------------
--
--- tt_types.vhd --- short names for long type names
---
--
-- Mikihiko Nakao, KEK IPNS
--
-- 20120313  first version for FTSW
-- 20130403  renamed to tt_types
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package tt_types is
subtype byte_t      is std_logic_vector (7 downto 0);
subtype word_t      is std_logic_vector (15 downto 0);
subtype long_t      is std_logic_vector (31 downto 0);
type    byte_vector is array (natural range <>) of byte_t;
type    word_vector is array (natural range <>) of word_t;
type    long_vector is array (natural range <>) of long_t;

subtype std_logic2  is std_logic_vector (1 downto 0);
subtype std_logic3  is std_logic_vector (2 downto 0);
subtype std_logic4  is std_logic_vector (3 downto 0);
subtype std_logic5  is std_logic_vector (4 downto 0);
subtype std_logic6  is std_logic_vector (5 downto 0);
subtype std_logic7  is std_logic_vector (6 downto 0);
subtype std_logic8  is std_logic_vector (7 downto 0);
subtype std_logic9  is std_logic_vector (8 downto 0);
subtype std_logic10 is std_logic_vector (9 downto 0);
subtype std_logic11 is std_logic_vector (10 downto 0);
subtype std_logic12 is std_logic_vector (11 downto 0);
subtype std_logic13 is std_logic_vector (12 downto 0);
subtype std_logic14 is std_logic_vector (13 downto 0);
subtype std_logic15 is std_logic_vector (14 downto 0);
subtype std_logic16 is std_logic_vector (15 downto 0);
subtype std_logic17 is std_logic_vector (16 downto 0);
subtype std_logic18 is std_logic_vector (17 downto 0);
subtype std_logic19 is std_logic_vector (18 downto 0);
subtype std_logic20 is std_logic_vector (19 downto 0);
subtype std_logic21 is std_logic_vector (20 downto 0);
subtype std_logic24 is std_logic_vector (23 downto 0);
subtype std_logic25 is std_logic_vector (24 downto 0);
subtype std_logic27 is std_logic_vector (26 downto 0);
subtype std_logic28 is std_logic_vector (27 downto 0);
subtype std_logic29 is std_logic_vector (28 downto 0);
subtype std_logic30 is std_logic_vector (29 downto 0);
subtype std_logic31 is std_logic_vector (30 downto 0);
subtype std_logic40 is std_logic_vector (39 downto 0);
subtype std_logic48 is std_logic_vector (47 downto 0);
subtype std_logic64 is std_logic_vector (63 downto 0);

type std_logic2_vector  is array (natural range <>) of std_logic2;
type std_logic3_vector  is array (natural range <>) of std_logic3;
type std_logic4_vector  is array (natural range <>) of std_logic4;
type std_logic5_vector  is array (natural range <>) of std_logic5;
type std_logic6_vector  is array (natural range <>) of std_logic6;
type std_logic9_vector  is array (natural range <>) of std_logic9;
type std_logic12_vector is array (natural range <>) of std_logic12;
type std_logic16_vector is array (natural range <>) of std_logic16;
type std_logic17_vector is array (natural range <>) of std_logic17;
type std_logic18_vector is array (natural range <>) of std_logic18;
type std_logic24_vector is array (natural range <>) of std_logic24;
type std_logic27_vector is array (natural range <>) of std_logic27;
type std_logic40_vector is array (natural range <>) of std_logic40;
type std_logic48_vector is array (natural range <>) of std_logic48;

constant ZEROx27 : std_logic27 := "000000000000000000000000000";

end package tt_types;
