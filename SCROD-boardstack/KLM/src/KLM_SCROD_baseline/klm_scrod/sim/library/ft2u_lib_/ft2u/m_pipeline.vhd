------------------------------------------------------------------------
--
-- m_pipeline component --- trigger pipeline
--
-- time - 18-bit  (262,144 clocks or 2ms, long enough for longest latency)
-- depth - 8-bit  (256 triggers, deep enough for multiple triggers)
--
-- 20140403: fix latency comparison: ">=" instead of ">"
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

entity m_pipeline is
  port (
    clock    : in  std_logic;
    runreset : in  std_logic;
    trig     : in  std_logic;
    linkup   : in  std_logic_vector (7 downto 0); -- TBI
    tagdone  : in  byte_vector      (7 downto 0); -- TBI
    maxtrig  : in  byte_t;      -- 12 for the moment
    latency  : in  std_logic18; -- 4240 for 33 us (for avg 30 kHz rate)
    busy     : out std_logic;
    dbg      : out std_logic_vector (31 downto 0);
    dbg2     : out std_logic_vector (31 downto 0) );
end m_pipeline;

architecture implementation of m_pipeline is
  signal sig_trig    : std_logic := '0';
  signal seq_trig    : std_logic := '0';
  signal sig_wra     : std_logic2 := "00";
  signal cnt_in      : byte_t := x"00";
  signal cnt_out     : byte_t := x"00";
  signal sta_adiff   : byte_t := x"00";
  signal cnt_tim     : std_logic18 := (others => '0');
  signal sta_tim     : std_logic18 := (others => '0');
  signal sta_tdiff   : std_logic18 := (others => '0');
  signal cnt_pipe    : byte_t := x"00";
  signal cnt_trig    : std_logic2 := "00";
  signal open_unused : std_logic18 := (others => '0'); -- for poor simulator
begin
  sig_wra <= sig_trig & sig_trig;
  sta_adiff <= cnt_in - cnt_out;
  sta_tdiff <= cnt_tim - sta_tim;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then

      -- sig_trig (one clock delay)
      -- seq_trig (one more clock delay before address increment)
      sig_trig <= trig;
      seq_trig <= sig_trig;

      -- cnt_trig
      if sig_trig = '1' then
        cnt_trig <= cnt_trig + 1;
      end if;
      
      -- cnt_tim
      cnt_tim <= cnt_tim + 1;
      
      -- cnt_in
      if runreset = '1' then
        cnt_in <= (others => '0');
      elsif seq_trig = '1' then
        cnt_in <= cnt_in + 1;
      end if;

      -- cnt_out
      if runreset = '1' then
        cnt_out <= (others => '0');
      elsif sta_adiff /= 0 and sta_tdiff >= latency then
        -- 33.3usec for 30kHz avg rate
        cnt_out <= cnt_out + 1;
      end if;

      -- busy
      if sta_adiff < maxtrig then
        busy <= '0';
      else
        busy <= '1';
        cnt_pipe <= cnt_pipe + 1;
      end if;
      
    end if; -- event
  end process;
  
  -- RAMB36
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
  dbg <= cnt_tim(15 downto 0) & sta_tim(15 downto 0);
  dbg2 <= cnt_trig & cnt_tim(17 downto 16) & "00" & sta_tim(17 downto 16) &
         x"00" & cnt_in & cnt_out;
  
end implementation;

