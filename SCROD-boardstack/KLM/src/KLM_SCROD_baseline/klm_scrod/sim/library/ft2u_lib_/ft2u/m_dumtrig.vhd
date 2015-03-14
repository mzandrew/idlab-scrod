------------------------------------------------------------------------
--
-- m_dumtrig component --- dummy trigger generator
--
-- input clock -- 127216000 Hz
--
-- pls trigger
--   127216000 / [ 30 * (14 + val*2^exp) + 1 ]
--    ---> val*2^exp = (127216000/rate - 1)/30 - 14
--   max rate: n=0,    m=0  ---> interval=421 rate=302 kHz
--   example:  n=127,  m=0  ---> interval=4231 rate=30 kHz
--   example:  n=528,  m=3  ---> interval=127141 rate=1 kHz
--   example:  n=517,  m=13 ---> interval=127058341 rate=1 Hz
--   min rate: n=1023, m=15 ---> interval=1005650341 Hz  rate=0.13 Hz
--   
-- rev trigger
--   127216000 / [ 1280 * (1 + val)*2^exp ]
--   max rate: n=0,    m=0  ---> 100 kHz
--   min rate: n=1023, m=15 ---> 0.003 Hz (once in 337 sec)
--
-- rnd trigger
--   clk src:  127216000 / [ (1 + val)*2^exp ]
--   max rate: n=0,    m=0  ---> average-interval=512 rate=248 kHz
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity m_dumtrig is
  port (
    clock   : in  std_logic;
    revo    : in  std_logic;
    setrate : in  std_logic;
    seltrg  : in  std_logic_vector (2  downto 0);
    rateval : in  std_logic_vector (9  downto 0);
    rateexp : in  std_logic_vector (3  downto 0);
    trgopt  : in  std_logic_vector (11 downto 0);
    trig    : out std_logic;
    dbg     : out std_logic_vector (31 downto 0) );
end m_dumtrig;

architecture behavior of m_dumtrig is

  signal tmp_rateval : std_logic_vector (10 downto 0) := (others => '0');
  signal tmp_trgint  : std_logic_vector (41 downto 0) := (others => '0');
  signal reg_trgint  : std_logic_vector (25 downto 0) := (others => '0');

  signal sig_plsclk  : std_logic := '0';
  signal cnt_plsclk  : std_logic_vector (4  downto 0) := (others => '0');
  signal tmp_plsint  : std_logic_vector (41 downto 0) := (others => '0');
  signal reg_plsint  : std_logic_vector (25 downto 0) := (others => '0');
  signal cnt_plsint  : std_logic_vector (25 downto 0) := (others => '0');
  signal sig_plstrg  : std_logic := '0';

  signal cnt_plsint2 : std_logic_vector (6  downto 0) := (others => '0');
  signal cnt_plscnt2 : std_logic_vector (5  downto 0) := (others => '0');
  signal reg_plsint2 : std_logic_vector (6  downto 0) := (others => '0');
  signal reg_plscnt2 : std_logic_vector (5  downto 0) := (others => '0');
  
  signal cnt_revclk  : std_logic_vector (10 downto 0) := "10011111110";
  signal sig_revclk  : std_logic := '0';
  signal cnt_revint  : std_logic_vector (25 downto 0) := (others => '0');

  signal cnt_rndclk  : std_logic_vector (25 downto 0) := (others => '0');
  signal sig_rndclk  : std_logic := '0';
  signal cnt_rndint  : std_logic_vector (9  downto 0) := (others => '0');
  signal buf_rndint  : std_logic_vector (16 downto 0) := "10101010101010101";
  signal sig_rndtrg  : std_logic := '0';

  signal sta_poimem  : std_logic_vector (8  downto 0) := (others => '0');
  signal cnt_poiint  : std_logic_vector (8  downto 0) := (others => '0');
  signal buf_poirnd  : std_logic_vector (16 downto 0) := "10101010101010101";
  signal buf_poiadr  : std_logic_vector (13 downto 0) := (others => '0');
  signal sig_poitrg  : std_logic := '0';

  signal sig_trig    : std_logic := '0';

  signal open_unused : std_logic_vector (26 downto 0) := (others => '0');
begin
  -- in
  -- 30 * (14 + n * 2^m) + 1

  tmp_rateval <= ('0' & rateval) + 1;
  tmp_trgint  <= "000000000000000" & tmp_rateval & x"0000";
  reg_trgint  <= tmp_trgint(41 - conv_integer(rateexp) downto
                            16 - conv_integer(rateexp)) - 1;
  tmp_plsint  <= x"0000" & rateval & x"0000";
  reg_plsint  <= tmp_plsint(41 - conv_integer(rateexp) downto
                            16 - conv_integer(rateexp)) + 14 - 1;

  reg_plscnt2 <= trgopt(5 downto 0);
  reg_plsint2 <= '0' & trgopt(11 downto 6);
  
  buf_poiadr <= buf_poirnd(10 downto 0) & "000";
  
  mem_poitbl: ramb18
    generic map (
      READ_WIDTH_A => 9, WRITE_WIDTH_A => 9,
      READ_WIDTH_B => 0, WRITE_WIDTH_B => 0,
init_00 => x"16181b1d1f2224272a2c2f3236393d4145494e53585e646b737c8693a2b5d0ff",
init_01 => x"e8e9eaebecedeef0f1f2f3f4f6f7f8fafbfcfeff0102040607090b0c0e101214",
init_02 => x"cdcdcecfcfd0d1d2d2d3d4d5d6d6d7d8d9dadbdbdcdddedfe0e1e2e3e4e5e6e7",
init_03 => x"b9bababbbbbcbdbdbebebfbfc0c0c1c2c2c3c3c4c5c5c6c7c7c8c9c9cacbcbcc",
init_04 => x"aaababacacacadadaeaeafafb0b0b0b1b1b2b2b3b3b4b4b5b5b6b6b7b7b8b8b9",
init_05 => x"9e9e9f9fa0a0a0a1a1a1a2a2a2a3a3a4a4a4a5a5a6a6a6a7a7a7a8a8a9a9aaaa",
init_06 => x"949494959595969696979797989898989999999a9a9a9b9b9b9c9c9c9d9d9d9e",
init_07 => x"8b8b8b8c8c8c8c8d8d8d8e8e8e8e8f8f8f8f9090909191919192929293939394",
init_08 => x"8383838484848485858585868686868787878788888888898989898a8a8a8a8b",
init_09 => x"7c7c7c7d7d7d7d7d7e7e7e7e7e7f7f7f7f808080808081818181828282828383",
init_0a => x"7676767676767777777777787878787879797979797a7a7a7a7a7b7b7b7b7b7c",
init_0b => x"7070707070717171717171727272727273737373737374747474747575757575",
init_0c => x"6a6a6b6b6b6b6b6b6c6c6c6c6c6c6d6d6d6d6d6d6e6e6e6e6e6e6f6f6f6f6f70",
init_0d => x"6566666666666666676767676767676868686868686969696969696a6a6a6a6a",
init_0e => x"6161616161616262626262626263636363636363646464646464646565656565",
init_0f => x"5c5d5d5d5d5d5d5d5d5e5e5e5e5e5e5e5f5f5f5f5f5f5f5f6060606060606061",
init_10 => x"585859595959595959595a5a5a5a5a5a5a5a5b5b5b5b5b5b5b5b5c5c5c5c5c5c",
init_11 => x"5555555555555555555656565656565656575757575757575757585858585858",
init_12 => x"5151515151515252525252525252525353535353535353535454545454545454",
init_13 => x"4d4e4e4e4e4e4e4e4e4e4f4f4f4f4f4f4f4f4f4f505050505050505050515151",
init_14 => x"4a4a4a4a4b4b4b4b4b4b4b4b4b4b4c4c4c4c4c4c4c4c4c4d4d4d4d4d4d4d4d4d",
init_15 => x"47474747474848484848484848484849494949494949494949494a4a4a4a4a4a",
init_16 => x"4444444444454545454545454545454546464646464646464646464747474747",
init_17 => x"4141414142424242424242424242424343434343434343434343444444444444",
init_18 => x"3e3f3f3f3f3f3f3f3f3f3f3f4040404040404040404040404141414141414141",
init_19 => x"3c3c3c3c3c3c3c3c3d3d3d3d3d3d3d3d3d3d3d3d3e3e3e3e3e3e3e3e3e3e3e3e",
init_1a => x"3939393a3a3a3a3a3a3a3a3a3a3a3a3b3b3b3b3b3b3b3b3b3b3b3b3b3c3c3c3c",
init_1b => x"3737373737373737383838383838383838383838383839393939393939393939",
init_1c => x"3535353535353535353535353535363636363636363636363636363737373737",
init_1d => x"3232323233333333333333333333333333333434343434343434343434343434",
init_1e => x"3030303030303031313131313131313131313131313232323232323232323232",
init_1f => x"2e2e2e2e2e2e2e2e2e2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f3030303030303030",
init_20 => x"2c2c2c2c2c2c2c2c2c2c2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2e2e2e2e2e",
init_21 => x"2a2a2a2a2a2a2a2a2a2a2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2c2c2c2c2c2c",
init_22 => x"28282828282828282828292929292929292929292929292929292a2a2a2a2a2a",
init_23 => x"2626262626262626272727272727272727272727272727272728282828282828",
init_24 => x"2424242424252525252525252525252525252525252525262626262626262626",
init_25 => x"2222232323232323232323232323232323232323242424242424242424242424",
init_26 => x"2121212121212121212121212121212222222222222222222222222222222222",
init_27 => x"1f1f1f1f1f1f1f1f1f1f20202020202020202020202020202020202020212121",
init_28 => x"1d1d1d1d1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1f1f1f1f1f1f1f1f1f",
init_29 => x"1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d",
init_2a => x"1a1a1a1a1a1a1a1a1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1c1c1c1c",
init_2b => x"191919191919191919191919191919191919191a1a1a1a1a1a1a1a1a1a1a1a1a",
init_2c => x"1717171717171717171818181818181818181818181818181818181818181919",
init_2d => x"1616161616161616161616161616161616161617171717171717171717171717",
init_2e => x"1414141414141415151515151515151515151515151515151515151515151616",
init_2f => x"1313131313131313131313131313131313141414141414141414141414141414",
init_30 => x"1111111212121212121212121212121212121212121212121212131313131313",
init_31 => x"1010101010101010101010111111111111111111111111111111111111111111",
init_32 => x"0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f10101010101010101010101010",
init_33 => x"0d0d0d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0f0f0f0f0f",
init_34 => x"0c0c0c0c0c0c0c0c0c0c0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d",
init_35 => x"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c",
init_36 => x"0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0b0b0b0b0b0b0b0b0b",
init_37 => x"080809090909090909090909090909090909090909090909090909090a0a0a0a",
init_38 => x"0707070707070708080808080808080808080808080808080808080808080808",
init_39 => x"0606060606060606060606060707070707070707070707070707070707070707",
init_3a => x"0505050505050505050505050505050506060606060606060606060606060606",
init_3b => x"0404040404040404040404040404040404040404050505050505050505050505",
init_3c => x"0303030303030303030303030303030303030303030303040404040404040404",
init_3d => x"0202020202020202020202020202020202020202020202020202030303030303",
init_3e => x"0101010101010101010101010101010101010101010101010101010101020202",
init_3f => x"0000000000000000000000000000000000000000000000000000000000000001",
initp_00=>x"00000000000000000000000000000000000000000000000000000fffffffffff",
initp_01=>x"0000000000000000000000000000000000000000000000000000000000000000",
initp_02=>x"0000000000000000000000000000000000000000000000000000000000000000",
initp_03=>x"0000000000000000000000000000000000000000000000000000000000000000",
initp_04=>x"0000000000000000000000000000000000000000000000000000000000000000",
initp_05=>x"0000000000000000000000000000000000000000000000000000000000000000",
initp_06=>x"0000000000000000000000000000000000000000000000000000000000000000",
initp_07=>x"0000000000000000000000000000000000000000000000000000000000000000" )
    port map (
      -- port A
      addra(13 downto 3) => buf_poirnd(10 downto 0),
      addra(2  downto 0) => "000",
      dia(15 downto 0)   => x"0000",
      dipa(1 downto 0)   => "00",
      wea(1  downto 0)   => "00",
      doa(15 downto 8)   => open_unused(25 downto 18),
      doa(7  downto 0)   => sta_poimem(7 downto 0),
      dopa(1)            => open_unused(26),
      dopa(0)            => sta_poimem(8),
      ena                => '1',
      ssra               => '0',
      regcea             => '1',
      clka               => clock,
      -- port B
      addrb(13 downto 3) => "00000000000",
      addrb(2  downto 0) => "000",
      dib(15 downto 0)   => x"0000",
      dipb(1 downto 0)   => "00",
      web(1  downto 0)   => "00",
      dob(15 downto 0)   => open_unused(15 downto 0),
      dopb(1 downto 0)   => open_unused(17 downto 16),
      enb                => '1',
      ssrb               => '0',
      regceb             => '1',
      clkb               => '0' );
  
  proc: process(clock)
  begin
    if clock'event and clock = '1' then

      ------------------------------------------------------------
      -- cnt_plsclk, sig_plsclk
      if sig_plsclk = '1' and cnt_plsint = reg_plsint then
        sig_plsclk <= '0';
        cnt_plsclk <= (others => '0');
      elsif cnt_plsint2 = 0 and cnt_plscnt2 = 1 then
        sig_plsclk <= '0';
        cnt_plsclk <= (others => '0');
      elsif cnt_plsclk = 29 then
        sig_plsclk <= '1';
        cnt_plsclk <= (others => '0');
      else
        sig_plsclk <= '0';
        cnt_plsclk <= cnt_plsclk + 1;
      end if;

      -- cnt_plsint
      if setrate = '1' then
        cnt_plsint <= (others => '0');
      elsif sig_plsclk = '1' then
        if cnt_plsint = reg_plsint then
          cnt_plsint <= (others => '0');
        elsif cnt_plscnt2 /= 0 or cnt_plsint2 /= 0 then
          cnt_plsint <= (others => '0');
        else
          cnt_plsint <= cnt_plsint + 1;
        end if;
      end if;

      -- cnt_plsint2, cnt_plscnt2
      if sig_plsclk = '1' and cnt_plsint = reg_plsint then
        cnt_plsint2 <= reg_plsint2 + 23;
        cnt_plscnt2 <= reg_plscnt2;
      elsif cnt_plsint2 = 0 and cnt_plscnt2 /= 0 then
        cnt_plsint2 <= reg_plsint2 + 23;
        cnt_plscnt2 <= cnt_plscnt2 - 1;
      elsif cnt_plsint2 /= 0 then
        cnt_plsint2 <= cnt_plsint2 - 1;
      end if;

      -- sig_plstrg
      if sig_plsclk = '1' and cnt_plsint = reg_plsint then
        sig_plstrg <= '1';
      elsif cnt_plsint2 = 0 and cnt_plscnt2 /= 0 then
        sig_plstrg <= '1';
      else
        sig_plstrg <= '0';
      end if;

      ------------------------------------------------------------
      -- cnt_revclk
      if revo = '1' then
        cnt_revclk <= "00000000010"; -- 2
      elsif cnt_revclk = 1279 then
        cnt_revclk <= (others => '0');
      else
        cnt_revclk <= cnt_revclk + 1;
      end if;

      -- sig_revclk
      if cnt_revclk = trgopt(10 downto 0) then
        sig_revclk <= '1';
      else
        sig_revclk <= '0';
      end if;

      -- cnt_revint
      if setrate = '1' then
        cnt_revint <= (others => '0');
      elsif sig_revclk = '1' then
        if cnt_revint = reg_trgint then
          cnt_revint <= (others => '0');
        else
          cnt_revint <= cnt_revint + 1;
        end if;
      end if;

      ------------------------------------------------------------
      -- cnt_rndclk, sig_rndclk
      if setrate = '1' or sig_trig = '1' then
        cnt_rndclk <= (others => '0');
        sig_rndclk <= '0';
      elsif cnt_rndclk = reg_trgint then
        cnt_rndclk <= (others => '0');
        sig_rndclk <= '1';
      else
        cnt_rndclk <= cnt_rndclk + 1;
        sig_rndclk <= '0';
      end if;

      -- cnt_rndint, buf_rndint, sig_rndtrg
      if sig_rndclk = '1' then
        if cnt_rndint = buf_rndint(9 downto 0) then
          cnt_rndint <= (others => '0');
          buf_rndint <= buf_rndint(15 downto 0)
                        & (buf_rndint(15) xor buf_rndint(3) xor
                           buf_rndint(2)  xor buf_rndint(1));
          sig_rndtrg <= '1';
        else
          cnt_rndint <= cnt_rndint + 1;
          sig_rndtrg <= '0';
        end if;
      else
        sig_rndtrg <= '0';
      end if;

      ------------------------------------------------------------
      -- cnt_poiint, buf_poirnd, sig_poitrg
      if sig_rndclk = '1' then
        if cnt_poiint = sta_poimem then
          cnt_poiint <= (others => '0');
          buf_poirnd <= buf_poirnd(15 downto 0)
                        & (buf_poirnd(15) xor buf_poirnd(3) xor
                           buf_poirnd(2)  xor buf_poirnd(1));
          sig_poitrg <= '1';
        else
          cnt_poiint <= cnt_poiint + 1;
          sig_poitrg <= '0';
        end if;
      else
        sig_poitrg <= '0';
      end if;

      ------------------------------------------------------------
      -- sig_trig
      if seltrg = 4 and sig_plstrg = '1' then
        sig_trig <= '1';
      elsif seltrg = 5 and sig_revclk = '1' and cnt_revint = reg_trgint then
        sig_trig <= '1';
      elsif seltrg = 6 and sig_rndtrg = '1' then
        sig_trig <= '1';
      elsif seltrg = 7 and sig_poitrg = '1' then
        sig_trig <= '1';
      else
        sig_trig <= '0';
      end if;
    end if;
    
  end process;

  -- out
  trig <= sig_trig;

end behavior;
