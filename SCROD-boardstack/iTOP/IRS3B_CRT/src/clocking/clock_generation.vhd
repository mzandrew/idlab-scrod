----------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.asic_definitions_irs3b_carrier_revB.all;

entity clock_generation is
	Port ( 
		--Raw board clock input
		BOARD_CLOCKP     : in  STD_LOGIC;
		BOARD_CLOCKN     : in  STD_LOGIC;
		--FTSW inputs
		RJ45_ACK_P       : out std_logic;
		RJ45_ACK_N       : out std_logic;			  
		RJ45_TRG_P       : in  std_logic;
		RJ45_TRG_N       : in  std_logic;			  			  
		RJ45_RSV_P       : in  std_logic;
		RJ45_RSV_N       : in  std_logic;
		RJ45_CLK_P       : in  std_logic;
		RJ45_CLK_N       : in  std_logic;
		--Trigger outputs from distributed system
		EXT_TRIGGER      : out std_logic;
		--Select local or remote clocking
		USE_LOCAL_CLOCK  : in  std_logic;
		--General output clocks
		CLOCK_50MHz_BUFG : out STD_LOGIC;
		--ASIC control clocks
		CLOCK_SSTx4_BUFG : out STD_LOGIC;
		CLOCK_SSTx2_CE   : out STD_LOGIC;
		CLOCK_SST_BUFG   : out STD_LOGIC;
		--ASIC output clocks (sent through ODDR2)
		ASIC_SST         : out STD_LOGIC_VECTOR(ASICS_PER_ROW-1 downto 0);
		--Output clock enable for I2C things
		I2C_CLOCK_ENABLE : out STD_LOGIC;
		--Output clock enable for ASIC DAC interface
		ASIC_SERIAL_CLOCK_ENABLE : out STD_LOGIC
	);
end clock_generation;

architecture Behavioral of clock_generation is
	signal internal_BOARD_CLOCK         : std_logic;
	signal internal_BOARD_CLOCK_FB      : std_logic;
	signal internal_BOARD_CLOCK_FB_BUFG : std_logic;
	signal internal_BOARD_DERIVED_SST   : std_logic;
	signal internal_BOARD_DERIVED_SST_GBUF : std_logic;
	signal internal_FTSW_DERIVED_SST    : std_logic;
	signal internal_CLK_FIN_SST         : std_logic;
	signal internal_CLOCK_SST           : std_logic;
	signal internal_CLOCK_SSTx4_BUFG    : std_logic;
	--
	signal internal_FTSW_INTERFACE_READY  : std_logic;
	signal internal_FTSW_INTERFACE_STABLE : std_logic;
	signal internal_FTSW_STABLE_COUNTER   : unsigned(15 downto 0);
	signal internal_FTSW_TRIGGER          : std_logic;
	signal internal_CLK_FIN_TRIGGER       : std_logic;
	--
	signal internal_CLOCK_50MHz_BUFG    : std_logic;
	
begin
	--Simple mappings from internals to output ports
	CLOCK_SSTx4_BUFG <= internal_CLOCK_SSTx4_BUFG;


	------------------------------------------------------
	--            Board derived clocking                --
	------------------------------------------------------
	map_board_clock : ibufds
	port map(
		I  => BOARD_CLOCKP,
		IB => BOARD_CLOCKN,
		O  => internal_BOARD_CLOCK
	);	
	map_board_clock_feedback : bufg
	port map(
		I  => internal_BOARD_CLOCK_FB,
		O  => internal_BOARD_CLOCK_FB_BUFG
	);
	map_board_derived_clockgen : entity work.clockgen
	port map (
		-- Clock in ports
		BOARD_CLK     => internal_BOARD_CLOCK,
		-- Feedback ports
		CLKFB_IN      => internal_BOARD_CLOCK_FB_BUFG,
		CLKFB_OUT     => internal_BOARD_CLOCK_FB,		
		-- clock out ports
		BOARD_CLK_SST => internal_BOARD_DERIVED_SST,
		LOCKED        => open
	);
	------------------------------------------------------
	--            FTSW derived clocking                 --
	------------------------------------------------------
	map_FTSW_interface: entity work.bpid
	port map (
		ack_p  => RJ45_ACK_P,
		ack_n  => RJ45_ACK_N,
		trg_p  => RJ45_TRG_P,
		trg_n  => RJ45_TRG_N,
		rsv_p  => RJ45_RSV_P,
		rsv_n  => RJ45_RSV_N,
		clk_p  => RJ45_CLK_P,
		clk_n  => RJ45_CLK_N,
		clk127 => open,
		clk21  => internal_FTSW_DERIVED_SST,
		trg127 => open,
		trg21  => internal_FTSW_TRIGGER,
		ready  => internal_FTSW_INTERFACE_READY,
		monitor => open
	);
	--Quick stability check for FTSW interface
	process(internal_BOARD_DERIVED_SST) begin
		if (rising_edge(internal_BOARD_DERIVED_SST)) then
			if (internal_FTSW_INTERFACE_READY = '0') then
				internal_FTSW_STABLE_COUNTER <= (others => '0');
			elsif (internal_FTSW_STABLE_COUNTER(15) = '0') then
				internal_FTSW_STABLE_COUNTER <= internal_FTSW_STABLE_COUNTER + 1;
			end if;
		end if;
	end process;
	--Don't issue FTSW triggers unless the FTSW interface is stable.
	internal_FTSW_INTERFACE_STABLE <= internal_FTSW_STABLE_COUNTER(15);
	EXT_TRIGGER <= internal_FTSW_TRIGGER and internal_FTSW_INTERFACE_STABLE;
	
--	------------------------------------------------------
--	--            CLK_FIN derived clocking              --
--	------------------------------------------------------
--	-- N.B. This is primarily for FDIRC!                --
--	--      DO NOT USE THIS FOR ITOP UNLESS YOU         --
--	--      UNDERSTAND WHY THIS MESSAGE WAS WRITTEN     --
--	------------------------------------------------------
--	map_CLK_FIN_interface: entity work.clk_fin_receiver
--	port map (
--		RJ45_ACK_N  => RJ45_ACK_N,
--		RJ45_ACK_P  => RJ45_ACK_P,
--		RJ45_TRG_N  => RJ45_TRG_N,
--		RJ45_TRG_P  => RJ45_TRG_P,
--		RJ45_RSV_N  => RJ45_RSV_N,
--		RJ45_RSV_P  => RJ45_RSV_P,
--		RJ45_CLK_N  => RJ45_CLK_N,
--		RJ45_CLK_P  => RJ45_CLK_P,
--		SST_NOBUF   => internal_CLK_FIN_SST,
--		SST_GBUF    => open,
--		TRIG21      => internal_CLK_FIN_TRIGGER
--	);
--	EXT_TRIGGER <= internal_CLK_FIN_TRIGGER;

	------------------------------------------------------
	--            MUX between board/distributed         --
	------------------------------------------------------
	-- Nominal version with multiplexing
	map_bufgmux_sst : bufgmux
	port map (
--		I0 => internal_CLK_FIN_SST,
		I0 => internal_FTSW_DERIVED_SST,
		I1 => internal_BOARD_DERIVED_SST,
		O  => internal_CLOCK_SST,
		S  => USE_LOCAL_CLOCK		
	);
--	-- Force using board clock only
--	map_sst_bufg : bufg port map(
--		I => internal_BOARD_DERIVED_SST,
--		O => internal_CLOCK_SST
--	);
-- Force using distributed clock only
--	internal_CLOCK_SST <= internal_CLK_FIN_SST;
	------------------------------------------------------
	--        PLLs to generate all other clocks         --
	------------------------------------------------------
	--this takes in 21.2027 MHz in
	--     generates General use clock @ 50.0000 MHz @  0 degrees
	--               SSTx4             @ 84.8108 MHz @ 90 degrees
	map_clockgen_ASIC : entity work.clockgen_asic_A
	port map (
		-- Clock in ports
		CLK_SST          => internal_CLOCK_SST,
		-- Clock out ports
		CLK_50MHz_BUFG   => internal_CLOCK_50MHz_BUFG,
		CLK_SSTx4_BUFG   => internal_CLOCK_SSTx4_BUFG,
		-- Status and control signals
		LOCKED           => open
	);
	CLOCK_50MHz_BUFG <= internal_CLOCK_50MHz_BUFG;
   CLOCK_SST_BUFG   <= internal_CLOCK_SST;
	
	-------------------------------------------------------
	--Logic to generate slow clock enables(e.g., for I2C)--
	-------------------------------------------------------
	process(internal_CLOCK_SSTx4_BUFG) 
		variable toggle_bit : std_logic := '0';
	begin
		if (rising_edge(internal_CLOCK_SSTx4_BUFG)) then
			CLOCK_SSTx2_CE <= toggle_bit;
			toggle_bit := not(toggle_bit);
		end if;
	end process;

	map_i2c_clock_enable : entity work.clock_enable_generator
	generic map (
--		DIVIDE_RATIO => 20 --This is suitable for a 4 MHz clock divided by 20 ==> 200 kHz
		DIVIDE_RATIO => 250 --This is for a 50 MHz clock divided by 250 ==> 200 kHz
	)
	port map (
--		CLOCK_IN         => internal_CLOCK_4MHz_BUFG,
		CLOCK_IN         => internal_CLOCK_50MHz_BUFG,
		CLOCK_ENABLE_OUT => I2C_CLOCK_ENABLE
	);
	
	------------------------------------------------------------
	--Map out the ASIC control signals that are on clock nets --
	------------------------------------------------------------
	gen_sst_to_asic : for i in 0 to ASICS_PER_ROW-1 generate
		map_sst_to_col : ODDR2
			generic map(
				DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
				INIT => '0', -- Sets initial state of the Q output to '0' or '1'
				SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
			port map (
				Q  => ASIC_SST(i),        -- 1-bit output data
				C0 => internal_CLOCK_SST,      -- 1-bit clock input
				C1 => not(internal_CLOCK_SST), -- 1-bit clock input
				CE => '1',                     -- 1-bit clock enable input
				D0 => '1',                     -- 1-bit data input (associated with C0)
				D1 => '0',                     -- 1-bit data input (associated with C1)
				R  => '0',                     -- 1-bit reset input
				S  => '0'                      -- 1-bit set input
		);
	end generate;

end Behavioral;

