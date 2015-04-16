------------------------------------------------------------------------
--
-- m_trgdelay component --- trigger delay
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;
library work;
use work.tt_types.all;

entity m_trgdelay is
  port (
    clock    : in  std_logic;
    runreset : in  std_logic;
    delay    : in  std_logic_vector (15 downto 0);
    trgin    : in  std_logic;
    trgout   : out std_logic );
end m_trgdelay;

architecture implementation of m_trgdelay is
  signal sig_trig    : std_logic := '0';
  signal seq_trig    : std_logic := '0';
  signal seq_trig2   : std_logic := '0';
  signal sig_wra     : std_logic2 := "00";
  signal cnt_in      : byte_t := x"00";
  signal cnt_out     : byte_t := x"00";
  signal sta_adiff   : byte_t := x"00";
  signal cnt_tim     : std_logic18 := (others => '0');
  signal sta_tim     : std_logic18 := (others => '0');
  signal sta_tdiff   : std_logic18 := (others => '0');
  signal sig_delayed : std_logic := '0';
  signal open_unused : std_logic18 := (others => '0'); -- for poor simulator
begin
  sig_wra <= sig_trig & sig_trig when delay > 3 else "00";
  sta_adiff <= cnt_in - cnt_out;
  sta_tdiff <= cnt_tim - sta_tim;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- sig_trig (one clock delay)
      -- seq_trig (one more clock delay before address increment)
      sig_trig <= trgin;
      seq_trig <= sig_trig;
      seq_trig2 <= seq_trig;

      -- cnt_tim
      cnt_tim <= cnt_tim + 1;
      
      -- cnt_in
      if runreset = '1' then
        cnt_in <= (others => '0');
      elsif seq_trig = '1' and delay > 3 then
        cnt_in <= cnt_in + 1;
      end if;

      -- cnt_out
      if runreset = '1' then
        cnt_out <= (others => '0');
        sig_delayed <= '0';
      elsif sta_adiff /= 0 and sta_tdiff(15 downto 0) = delay then
        cnt_out <= cnt_out + 1;
        sig_delayed <= '1';
      else
        sig_delayed <= '0';
      end if;

    end if; -- event
  end process;
  
  -- RAMB18
  map_ram: ramb18
    generic map (
      READ_WIDTH_A => 18, WRITE_WIDTH_A => 18,
      READ_WIDTH_B => 18, WRITE_WIDTH_B => 18 )
    
    port map (
      -- port A
      addra(13 downto 12) => "00",
      addra(11 downto 4)  => cnt_in,
      addra(3  downto 0)  => "0000",
      dia                 => cnt_tim(15 downto 0),
      dipa                => cnt_tim(17 downto 16),
      doa                 => open_unused(15 downto 0),
      dopa                => open_unused(17 downto 16),
      wea                 => sig_wra,
      ena                 => '1',
      ssra                => '0',
      regcea              => '1',
      clka                => clock,
        
      -- port B
      addrb(13 downto 12) => "00",
      addrb(11 downto 4)  => cnt_out,
      addrb(3  downto 0)  => "0000",
      dib                 => x"0000",
      dipb                => "00",
      dob                 => sta_tim(15 downto 0),
      dopb                => sta_tim(17 downto 16),
      web                 => "00",
      enb                 => '1',
      ssrb                => '0',
      regceb              => '1',
      clkb                => clock );

  -- out
  trgout <= trgin when delay = 0 else 
            sig_trig when delay = 1 else
            seq_trig when delay = 2 else
            seq_trig2 when delay = 3 else
            sig_delayed;
  
end implementation;

