------------------------------------------------------------------------
--
-- tt_jitterspi.vhd --- Virtex5 jitter cleaner setup with SPI
--
-- Mikihiko Nakao, KEK IPNS
--
-- 20120201 0.01  new
-- 20120208 0.02  renamed
-- 20130408 0.02  renamed to tt_jitterspi
------------------------------------------------------------------------

------------------------------------------------------------------------
-- jitter cleaner setup
------------------------------------------------------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;

entity tt_jitterspi is
  port (
    clock:   in  std_logic;
    set:     in  std_logic;
    reg:     in  std_logic_vector (31 downto 0);
    spimiso: in  std_logic;
    spimosi: out std_logic;
    spiclk:  out std_logic;
    spile:   out std_logic;
    status:  out std_logic_vector (31 downto 0);
    debug:   out std_logic_vector (31 downto 0) );

end tt_jitterspi;

architecture implementation of tt_jitterspi is
  signal sta_jwr:     std_logic := '0';
  signal sta_jrd:     std_logic := '0';
  signal cnt_jspi:    std_logic_vector (7  downto 0) := (others => '0');
  signal sig_spimosi: std_logic := '0';
  signal sig_spile:   std_logic := '1'; -- 0 only when reading out spimiso
  signal sig_spiclk:  std_logic := '0';
  signal buf_jspi:    std_logic_vector (31 downto 0) := (others => '0');
  signal buf_jspi2:   std_logic_vector (31 downto 0) := (others => '0');
begin
  status  <= buf_jspi;
  debug   <= buf_jspi2;
  spimosi <= sig_spimosi;
  spiclk  <= sig_spiclk;
  spile   <= sig_spile;

  proc: process (clock)
  begin
    if clock'event and clock = '1' then
      if sta_jwr = '1' then

        if cnt_jspi = 64*2+1 or (sta_jrd = '0' and cnt_jspi = 64+1) then
          sta_jwr <= '0';
        end if;
        
        if cnt_jspi(0) = '0' then       -- (cnt_jspi mod 2) = 0
          if cnt_jspi = 0 or cnt_jspi = 64+2 then
            sig_spile <= '0';
          elsif cnt_jspi = 64 then
            sig_spile <= '1';
          end if;
          
          if cnt_jspi < 64 then
            sig_spimosi <= buf_jspi(0);
            buf_jspi <= '0' & buf_jspi(buf_jspi'high downto 1);
          else
            sig_spimosi <= '1';
          end if;
          sig_spiclk <= '0';
        else
          if cnt_jspi >= 64 and sta_jrd = '1' then
            buf_jspi <= spimiso & buf_jspi(buf_jspi'high downto 1);
          else
            buf_jspi2 <= spimiso & buf_jspi2(buf_jspi2'high downto 1);
          end if;
          sig_spiclk <= '1';
        end if;
        cnt_jspi <= cnt_jspi + 1;

      else
        sig_spiclk  <= '0';
        sig_spile   <= '1';
        sig_spimosi <= '1';
        cnt_jspi    <= (others => '0');
        
        if set = '1' then
          if reg = 16#0e# or reg = 16#1e# or reg = 16#2e# or
             reg = 16#4e# or reg = 16#8e# then
            buf_jspi <= reg;
            sta_jrd  <= '1';
            sta_jwr  <= '1';
            
          elsif (reg(3 downto 2) = "00" and
                 reg(1 downto 0) /= "11") or reg = 16#1f# then
            buf_jspi <= reg;
            sta_jwr  <= '1';
            sta_jrd  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
    
end implementation;
