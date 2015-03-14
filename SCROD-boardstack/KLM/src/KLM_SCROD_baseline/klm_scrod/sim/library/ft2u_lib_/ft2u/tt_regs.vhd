------------------------------------------------------------------------
-- tt_regs.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
-- 20101027  first version for FTSW
-- 20101028  debug timing (v5022)
-- 20110420  debug for ftsw2
-- 20120207  renamed to mnregs
-- 20130404  renamed to tt_regs
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

entity tt_regs is
  generic (
    MIN_REG : integer := 16#3f#;
    MAX_REG : integer := 16#10#;
    RW      : std_logic_vector (255 downto 0) := ( others => '0');
    CLR     : long_vector (255 downto 0) := ( others => x"00000000" );
    INI     : long_vector (255 downto 0) := ( others => x"00000000" ) );
  
  port (
    -- from/to outside of the FPGA
    clock  : in    std_logic;
    ads    : in    std_logic;
    wr     : in    std_logic;
    adr    : in    std_logic_vector (11 downto 0);
    din    : in    std_logic_vector (31 downto 0);
    dout   : out   std_logic_vector (31 downto 0);

    -- from/to other part of FPGA
    reg    : out   long_vector      (MAX_REG downto MIN_REG);
    sta    : in    long_vector      (MAX_REG downto MIN_REG);
    set    : out   std_logic_vector (MAX_REG downto MIN_REG);
    get    : out   std_logic_vector (MAX_REG downto MIN_REG) );
end tt_regs;
------------------------------------------------------------------------
architecture implementation of tt_regs is

  signal seq_ads : std_logic_vector (3 downto 0) := (others => '0');
  signal seq_set : std_logic_vector (MAX_REG downto MIN_REG) :=
                                       (others => '0');
  signal seq_get : std_logic_vector (MAX_REG downto MIN_REG) :=
                                       (others => '0');
  signal first   : std_logic := '1';
  signal rw_reg  : std_logic_vector (MAX_REG downto MIN_REG) :=
                                       RW(MAX_REG downto MIN_REG);
  signal buf_reg : long_vector      (MAX_REG downto MIN_REG) :=
                                       INI(MAX_REG downto MIN_REG);
  signal buf_clr : long_vector      (MAX_REG downto MIN_REG) :=
                                       (others => x"00000000");

begin

  bufclr: for i in MIN_REG to MAX_REG generate
    buf_clr(i) <= buf_reg(i) and (not CLR(i));
  end generate;
  
  readwrite_proc: process(clock)
    variable iadr   : integer;
  begin
    iadr   := conv_integer(adr(7 downto 0));
    reg <= buf_reg;

    if clock'event and clock = '1' then

      seq_ads <= seq_ads(2 downto 0) & ads;

      if seq_ads(1 downto 0) = "10" then
        set     <= seq_set;
        get     <= seq_get;
        seq_get <= (others => '0');
        seq_set <= (others => '0');
      else
        set <= (others => '0');
        get <= (others => '0');
      end if;

      if seq_ads(1 downto 0) = "10" then    -- at the falling edge of ads
        dout <= (others => 'Z');
        
      elsif seq_ads(1 downto 0) /= "01" then
        -- do nothing unless rising edge of ads
        if seq_ads(2 downto 1) = "10" then
          buf_reg <= buf_clr;
        end if;

      elsif iadr < MIN_REG  or iadr >= MIN_REG + MAX_REG then
        -- do nothing for if out of range

      else
        if rw_reg(iadr) = '0' then
          dout <= sta(iadr);
        elsif wr = '0' then
          dout <= buf_reg(iadr);
        else
          buf_reg(iadr) <= din;
        end if;
        
        if wr = '0' then
          seq_get(iadr) <= '1';
        else
          seq_set(iadr) <= '1';
        end if;
        
      end if; ------------------------------- end of read/write cases --
    end if;
  end process;
end implementation;
