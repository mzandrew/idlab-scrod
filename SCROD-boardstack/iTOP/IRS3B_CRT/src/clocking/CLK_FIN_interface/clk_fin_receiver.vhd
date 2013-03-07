library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity clk_fin_receiver is
Port ( 
    signal RJ45_ACK_N      : out std_logic;
    signal RJ45_ACK_P      : out std_logic;
    signal RJ45_TRG_N      : in  std_logic;
    signal RJ45_TRG_P      : in  std_logic;
    signal RJ45_RSV_N      : out std_logic;
    signal RJ45_RSV_P      : out std_logic;
    signal RJ45_CLK_N      : in  std_logic;
    signal RJ45_CLK_P      : in  std_logic;
	 signal SST_NOBUF       : out std_logic;
	 signal SST_GBUF        : out	std_logic;
	 signal TRIG21          : out	std_logic
	);
end clk_fin_receiver;

architecture Behavioral of clk_fin_receiver is
	signal internal_RSV : std_logic;
	signal internal_ACK : std_logic;
	signal internal_CLOCK_SST_UNBUFFERED : std_logic;
	signal internal_CLOCK_SST_GBUF       : std_logic;
	signal internal_TRIGGER21            : std_logic;
begin
	----Connect internal signals to top level ports------------------
	SST_GBUF  <= internal_CLOCK_SST_GBUF;
	SST_NOBUF <= internal_CLOCK_SST_UNBUFFERED;
	TRIG21    <= internal_TRIGGER21;
   ----Map out the interface signals--------------------------------
	internal_RSV <= '0';
	internal_ACK <= '0';
	map_ibufds_SST_UNBUFFERED : IBUFDS
      port map (O  => internal_CLOCK_SST_UNBUFFERED,
                I  => RJ45_CLK_P,
                IB => RJ45_CLK_N);
--	map_bufg_SST : BUFG
--		port map (I => internal_CLOCK_SST_UNBUFFERED,
--		          O => internal_CLOCK_SST_GBUF);
	map_ibufds_trigger_SST : IBUFDS
      port map (O  => internal_TRIGGER21,
                I  => RJ45_TRG_P,
                IB => RJ45_TRG_N);
	map_obufds_ack : OBUFDS
      port map (I  => internal_ACK,
                O  => RJ45_ACK_P,
                OB => RJ45_ACK_N);
	map_obufds_rsv : OBUFDS
      port map (I  => internal_RSV, 
                O  => RJ45_RSV_P,
                OB => RJ45_RSV_N);

end Behavioral;

