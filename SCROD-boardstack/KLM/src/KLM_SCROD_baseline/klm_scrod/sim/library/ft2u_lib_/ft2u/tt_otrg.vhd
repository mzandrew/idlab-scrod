------------------------------------------------------------------------
-- tt_otrg.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
--  20130409 new
--  20130514 no more odelay: variable delay doesn't work for output
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

entity tt_otrg is
  port (
    clock    : in  std_logic;
    sigframe : in  std_logic;
    trgen    : in  std_logic;
    trg2     : in  std_logic_vector (1  downto 0);
    sub2     : in  std_logic_vector (1  downto 0);
    cprbit2  : in  std_logic_vector (1  downto 0);
    cprsub2  : in  std_logic_vector (1  downto 0);
    cprdum2  : in  std_logic_vector (1  downto 0);
    trg_p    : out std_logic_vector (20 downto 1);
    trg_n    : out std_logic_vector (20 downto 1);
    discpr   : in  std_logic_vector (4  downto 1);
    selcpr   : in  std_logic_vector (2  downto 0);
    disable  : in  std_logic_vector (7  downto 0);
    omask    : in  std_logic_vector (7  downto 0);
    autojtag : in  std_logic;
    enjtag   : in  std_logic_vector (7  downto 0);
    tdi      : in  std_logic );
end tt_otrg;
------------------------------------------------------------------------
architecture implementation of tt_otrg is

  signal sig_tdi   : std_logic_vector  (7  downto 0) := (others => '0');
  signal sig_cprd  : std_logic2_vector (4  downto 1) := (others => "00");
  signal sig_otrg  : std_logic2_vector (7  downto 0) := (others => "00");
  signal open_ddr  : std_logic_vector  (11 downto 0) := (others => '0');
  signal buf_omask : std_logic_vector  (7  downto 0) := (others => '0');
begin
  gen_copper: for i in 1 to 4 generate
    sig_cprd(i) <= cprdum2 when discpr(i) = '1'          else
                   cprbit2 when selcpr = i or selcpr = 0 else
                   cprsub2;
    
    map_trg: entity work.b2tt_oddr
      port map (
        clock    => clock,
        invclock => '0', -- only for s6
        slip     => '0',
        mask     => discpr(i),
        bit2     => sig_cprd(i),
        bitddr   => open_ddr(7+i),
        outp     => trg_p(i),
        outn     => trg_n(i) );
    
  end generate;
  
  gen_oport: for i in 0 to 7 generate

    sig_tdi(i)  <= tdi and (autojtag or enjtag(i));

    sig_otrg(i) <= trg2 when buf_omask(i) = '0' else
                   sub2;
    
    map_trg: entity work.b2tt_oddr
      port map (
        clock    => clock,
        invclock => '0',
        slip     => '0',
        mask     => disable(i),
        bit2     => sig_otrg(i),
        bitddr   => open_ddr(i),
        outp     => trg_p(i*2+5),
        outn     => trg_n(i*2+5) );

    map_tdi: obufds port map
      ( i => sig_tdi(i), o => trg_p(i*2+6), ob => trg_n(i*2+6) );

  end generate;

  process(clock)
  begin
    if rising_edge(clock) then
      if sigframe = '1' and trgen = '0' then
        buf_omask <= omask;
      end if;
    end if;
  end process;
    
end implementation;
