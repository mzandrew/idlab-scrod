------------------------------------------------------------------------
-- tt_phasedet.vhd
--
-- Mikihiko Nakao, KEK IPNS
-- 
-- 20120313  first version for FTSW
-- 20131206  clkerr
-- 
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.ALL;

entity tt_phasedet is
  generic (
    EXPECTED : std_logic_vector := "1100" );
  
  port (
    lclk     : in  std_logic;
    iclk     : in  std_logic;
    sclk     : in  std_logic;
    jpll     : in  std_logic;
    reset    : in  std_logic;
    clkset   : in  std_logic;
    clkerr   : out std_logic;
    sigpd    : out std_logic;
    dcm      : out std_logic;
    count    : out std_logic_vector (15 downto 0);
    nretry   : out std_logic_vector (7 downto 0);
    phase    : out std_logic_vector (3 downto 0) );
end tt_phasedet;

architecture implementation of tt_phasedet is
  signal sig_fbin   : std_logic := '0';
  signal sig_oclk   : std_logic_vector (3 downto 0) := "0000";
  signal sig_gclk   : std_logic_vector (3 downto 0) := "0000";
  signal buf_phase  : std_logic_vector (3 downto 0) := "0000";
  signal seq_phased : std_logic := '0';
  signal cnt_phased : std_logic_vector (15 downto 0) := x"0010";
  signal sig_pd     : std_logic := '0';
  signal cnt_retry  : std_logic_vector (7 downto 0) := x"00";
  signal sta_dcm    : std_logic := '0';
  signal sta_clkset : std_logic := '0';
  signal seq_jpll   : std_logic_vector (1 downto 0) := "00";
  signal sig_reset  : std_logic := '0';
begin
  count  <= cnt_phased;
  phase  <= buf_phase;
  nretry <= cnt_retry;
  dcm    <= sta_dcm;
  sigpd  <= sig_pd;
  sig_reset <= reset or (seq_jpll(1) and not seq_jpll(0));
  
  mapg0:  bufg port map ( i => sig_oclk(0), o => sig_gclk(0) );
  mapg1:  bufg port map ( i => sig_oclk(1), o => sig_gclk(1) );
  mapg2:  bufg port map ( i => sig_oclk(2), o => sig_gclk(2) );
  mapg3:  bufg port map ( i => sig_oclk(3), o => sig_gclk(3) );

  proc_check: process (lclk)
  begin
    if lclk'event and lclk = '1' then
      if sig_reset = '1' then -- external synchronous reset
        cnt_phased <= (others => '0');
        cnt_retry  <= (others => '0');
      elsif cnt_phased < 16 then
        sig_pd <= '1';
        cnt_phased <= cnt_phased + 1;
      elsif cnt_phased < 1024 then
        sig_pd <= '0';
        cnt_phased <= cnt_phased + 1;
      elsif buf_phase /= EXPECTED and seq_jpll(1) = '1' and sta_dcm = '1' then
        -- found to be failed before getting stable
        cnt_phased <= (others => '0');
        cnt_retry <= cnt_retry + 1;
      elsif cnt_phased(cnt_phased'left) = '0' then
        cnt_phased <= cnt_phased + 1;
      elsif buf_phase /= EXPECTED or jpll = '0' or sta_dcm = '0' then
        -- failed after getting stable
        cnt_phased <= (others => '0');
        cnt_retry <= cnt_retry + 1;
      end if;

      -- clock error detection
      --   standalone mode: clkerr is cleared upon valid jpll
      --   usual mode: clkerr is not cleared until utime is set
      sta_clkset <= sta_clkset or clkset;
      seq_jpll <= seq_jpll(0) & jpll;
      if seq_jpll = "10" then
        clkerr <= '1';
      elsif seq_jpll(0) = '1' and (sta_clkset = '0' or clkset = '1') then
        clkerr <= '0';
      end if;
      
    end if;
  end process;
  
  proc_phase: process (sclk)
  begin
    if sclk'event and sclk = '1' then
      -- clk0/clk90/clk180/clk270 have to go through bufg
      buf_phase <= sig_gclk;
    end if;
  end process;
  
  mapdcm: dcm_base
    generic map (
      CLKFX_MULTIPLY => 2,
      CLKFX_DIVIDE   => 2,
      DFS_FREQUENCY_MODE => "HIGH",
      DLL_FREQUENCY_MODE => "HIGH",
      DCM_PERFORMANCE_MODE => "MAX_SPEED" )
    port map (
      rst    => sig_reset,
      locked => sta_dcm,
      clkin  => iclk,
      clk0   => sig_oclk(0),
      clk90  => sig_oclk(1),
      clk180 => sig_oclk(2),
      clk270 => sig_oclk(3),
      clkfb  => sig_gclk(0) );
      
end implementation;
