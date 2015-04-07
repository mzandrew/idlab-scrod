----------------------------------------------------------------------------------
-- Company: UH Manoa - ID LAB
-- Engineer: Isar Mostafanezhad
-- 
-- Create Date:    13:06:51 10/16/2014 
-- Design Name:  WaveformPedsubDSP
-- Module Name:    WaveformPedsubDSP - Behavioral 
-- Project Name: 
-- Target Devices: SP6-SCROD rev A4, IDL_KLM_MB RevA (w SRAM)
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
Library work;
use work.readout_definitions.all;
use work.all;

entity WaveformPedsubDSP is
port(
			clk		 			 : in   std_logic;
			enable 				: in std_logic;  -- '0'= disable, '1'= enable
			--these two signals com form the ReadoutControl module and as soon as they are set and the SR Readout start is asserted, it goes and finds the proper pedestals from SRAM and populates buffer
			SMP_MAIN_CNT		: in std_logic_vector(8 downto 0);-- just to keep track of the sampling window number being written to at the time of trigger
			asic_no				 : in std_logic_vector(3 downto 0);
			win_addr_start		 : in std_logic_vector (8 downto 0);
			trigin				 : in std_logic; -- comes from the readout control module: starts fetching pedestals
			
			asic_en_bits		: in std_logic_vector(9 downto 0);
			busy					 : out std_logic; -- stays '1' until all pedsub samples have been sent out to the FIFO
			mode	: in std_logic_vector(1 downto 0);

			calc_mode : in std_logic_vector(3 downto 0);
			
			--ped subtracted waveform FIFO:
			pswfifo_en 			:	out std_logic;
			pswfifo_clk 		: 	out std_logic;
			pswfifo_d 			: 	out std_logic_vector(31 downto 0);
			
			--waveform : 
			-- steal fifo signal from the srreadout module and demux -- this has to go no more needed
		  fifo_en		 : in  std_logic;
		  fifo_clk		 : in  std_logic;
		  fifo_din		 : in  std_logic_vector(31 downto 0);
		  
		  qt_fifo_rd_clk	:in std_logic;
		  qt_fifo_rd_en	:in std_logic;
		  qt_fifo_dout		:out STD_LOGIC_VECTOR(17 DOWNTO 0);
		  qt_fifo_empty	:out std_logic;
		  qt_fifo_almost_empty	:out std_logic;
		  qt_fifo_evt_rdy	: out std_logic;
		  
   		trig_ctime		:in std_logic_vector(15 downto 0);

			bram_doutb		: in STD_LOGIC_VECTOR(11 DOWNTO 0);--:=x"000";
			bram_addrb	: out std_logic_vector(10 downto 0);--:="00000000000";		  
			dmx_allwin_done	:in std_logic;-- signals that all windows have been readout using the serial readout module and are in the BRAM ready for pedsub and sending to FIFO
		  
		  --trig bram access
		  trig_bram_addr	: out std_logic_vector(8 downto 0);
		  trig_bram_data	: in  std_logic_vector(49 downto 0);
		  trig_bram_sel	: out std_logic;
		  -- 12 bit Pedestal RAM Access: only for reading pedestals
		   ram_addr 	: OUT  std_logic_vector(21 downto 0);
         ram_data 	: IN  std_logic_vector(7 downto 0);
         ram_update 	: OUT  std_logic;
         ram_busy 	: IN  std_logic

);

end WaveformPedsubDSP;

architecture Behavioral of WaveformPedsubDSP is
COMPONENT PedRAMaccess
	PORT(
		clk : IN std_logic;
		addr : IN std_logic_vector(21 downto 0);
		wval0 : IN std_logic_vector(11 downto 0);
		wval1 : IN std_logic_vector(11 downto 0);
		rw : IN std_logic;
		update : IN std_logic;
		ram_datar : IN std_logic_vector(7 downto 0);
		ram_busy : IN std_logic;          
		rval0 : OUT std_logic_vector(11 downto 0);
		rval1 : OUT std_logic_vector(11 downto 0);
		busy : OUT std_logic;
		ram_addr : OUT std_logic_vector(21 downto 0);
		ram_dataw : OUT std_logic_vector(7 downto 0);
		ram_rw : OUT std_logic;
		ram_update : OUT std_logic
		);
	END COMPONENT;
	
COMPONENT blk_mem_gen_v7_3
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END COMPONENT;

COMPONENT qt_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC
  );
END COMPONENT;





--Latch to clock or trigin
signal asic_no_i			: integer;--std_logic_vector (3 downto 0);-- latched to trigin
signal win_addr_start_i	: integer;--std_logic_vector (9 downto 0);
signal trigin_i			: std_logic_vector(1 downto 0);
--signal ped_sa_num_i		: std_logic_vector(21 downto 0);
signal ped_sa_rval0		: std_logic_vector(11 downto 0);
signal ped_sa_rval1		: std_logic_vector(11 downto 0);
--signal ped_rval0_i		: std_logic_vector(11 downto 0);
signal ped_arr_addr:std_logic_vector(10 downto 0);
signal ped_arr_addr0_int : integer:=0;
signal ped_arr_addr1_int : integer:=0;
signal ped_sa_update		: std_logic:='0';
signal ped_sa_busy		: std_logic:='0';

signal ped_sa_num:std_logic_vector(21 downto 0);

signal ped_asic				: integer:=0;
signal ped_ch					: integer:=0;
signal ped_win					: integer:=0;
signal ped_sa					: integer:=0;
signal ped_hbyte				:std_logic_vector(7 downto 0);
signal ped_hbword				:integer:=0;
signal ped_word				:std_logic_vector(16 downto 0);
--signal dmx2_win				:std_logic_vector(1 downto 0):="00";
signal dmx2_sa					:std_logic_vector(4 downto 0):="00000";
signal dmx_asic				:integer:=0;
signal dmx_win					:std_logic_vector(1 downto 0):="00";
signal dmx_ch					:integer:=0;
signal dmx_sa					:integer:=0;
signal dmx_bit					:integer:=0;
signal fifo_din_i				: std_logic_vector(31 downto 0);
signal fifo_din_i2				: std_logic_vector(31 downto 0);
signal fifo_en_i				: std_logic:='0';
signal enable_i				: std_logic:='0';
signal start_ped_sub			: std_logic :='0';
signal sa_cnt					: integer 	:=0;
signal dmx_allwin_busy 		: std_logic:='1';
signal ped_sub_fetch_busy 	: std_logic:='1';
signal ped_sub_start			:std_logic_vector(1 downto 0):="00";
--signal jdx						: JDXTempArray;
--signal jdx2						: JDXTempArray;
signal jdx1						: std_logic_vector(6 downto 0);
signal ped_sub_fetch_done	: std_logic:='0'; 
--signal dmx_allwin_done		: std_logic:='0';
signal lastbit					: std_logic:='0';
		
signal dmx_wav					: WaveTempArray:=(x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
signal ped_wea					: std_logic_vector(0 downto 0):="0";
signal ped_dina				: STD_LOGIC_VECTOR(11 DOWNTO 0);
signal ped_doutb				: STD_LOGIC_VECTOR(11 DOWNTO 0);
signal ped_bram_addra		: std_logic_vector(10 downto 0);
signal ped_bram_addrb		: std_logic_vector(10 downto 0);
signal wav_doutb				: STD_LOGIC_VECTOR(11 DOWNTO 0):=x"000";
signal wav_bram_addrb		: std_logic_vector(10 downto 0):="00000000000";
signal ped_sub_send_data_busy : std_logic:='0';
signal busy_i					:std_logic:='0';
signal trig_ctime_i				:std_logic_vector(15 downto 0);

signal trgrec	: std_logic_vector(19 downto 0):=(others=>'0');--a snapshot of the trigger bits for the ASIC of interest: 19 downto 15 is DigWin, 14 downto 10 is DigWin+1, 9 downto 5 is DigWin+2, 4 downto 0 is DigWin+3

signal trig_bram_cnt: integer :=0;
signal trig_bram_start_addr_i :integer:=0;--(8 downto 0):=(others=>'0');
signal trig_asic_no_i : integer :=0;


signal sapedsub	:unsigned(12 downto 0):=(others=> '0');
signal samem		: WaveUnsignedTempArray:=(others=> x"000");
signal ct_lpv		: WaveUnsignedTempArray:=(others=> x"000");
signal ct_lpt		: WaveUnsignedTempArray:=(x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
signal ct_sa		: std_logic_vector(6 downto 0):="0000000";
signal ct_ch		: integer:=0;
signal ct_cnt		: integer:=0;
signal start_tmp2bram_xfer: std_logic:='0';
signal SMP_MAIN_CNT_i:std_logic_vector(8 downto 0);
signal calc_mode_i:std_logic_vector(3 downto 0);
signal tmp_cnt	:integer:=0;
signal wavarray_tmp				: WaveTempArray;-- added for pipelining


signal qt_rst		:std_logic:='0';
signal qt_rd_clk	:std_logic;
signal qt_din		:STD_LOGIC_VECTOR(17 DOWNTO 0);	--tx_eof_n & tx_sof_n & rest of data
signal qt_wr_en	:std_logic:='0';
signal qt_rd_en	:std_logic:='0';
signal qt_dout		:STD_LOGIC_VECTOR(17 DOWNTO 0);	--tx_eof_n & tx_sof_n & rest of data
signal qt_full		:std_logic:='0';
signal qt_empty	:std_logic:='0';
signal qt_almost_empty:std_logic:='0';

signal first_asic_no: std_logic_vector(3 downto 0):=x"0";
signal last_asic_no : std_logic_vector(3 downto 0):=x"0";
signal asic_en_bits_i			: std_logic_vector(9 downto 0):="0000000000";
signal send_empty_packet	: std_logic:='0';
signal qt_chno:	integer:=0;
signal qt_axis: std_logic:='0';


type ped_state is --pedstals fetch state
(
PedsIdle,				  -- Idling until command start bit and store asic no and win addr no	
PedsFetchPedVal,
PedsFetchPedValWaitSRAM1,
PedsFetchPedValWaitSRAM2,
PedsFetchPedValWaitSRAM3,
PedsFetchRedValWR1,
PedsFetchRedValWR2,
PedsFetchCheckSample,
PedsFetchCheckWin,
PedsFetchCheckCH,
PedsFetchDone
);
signal next_ped_st					: ped_state := PedsIdle;

type dmx_state is -- demux state
(
dmxIdle,				 
dmxAction,
dmxDone
);
signal next_dmx_st					: dmx_state := dmxIdle;

type pedsub_state is
(
pedsub_idle,
pedsub_sub_pre,
pedsub_sub_pre2,
pedsub_sub,
pedsub_sub0wait,
pedsub_sub0,
pedsub_sub1,
pedsub_sub2,
pedsub_inc_sa_cnt,
pedsub_dumpct,
pedsub_dumpct2,
pedsub_dump_trigrec,
pedsub_dumpfooter,
pedsub_dumpfooter2,
pedsub_dump_qt1,
pedsub_dump_qt2,
pedsub_dump_qt3,
pedsub_dump_qt4,
pedsub_dump_qt_chk,
pedsub_dump_qt_footer,
pedsub_dump_qt_evt_rdy,
pedsub_dump_qt_evt_rdy2,
pedsub_dump_qt_evt_rdy3
);
signal pedsub_st : pedsub_state:=pedsub_idle;


type trig_rec_state is
(
trg_rec_idle,
trg_rec_win00,
trg_rec_win0,
trg_rec_win1,
trg_rec_win2,
trg_rec_win3
);

signal st_trgrec		: trig_rec_state:=trg_rec_idle;


begin

qt_chno<=(dmx_asic-1)*15+ct_cnt+1 when dmx_asic<=5 	and dmx_asic>=1 	else
			(dmx_asic-6)*15+ct_cnt+1 when dmx_asic<=10 	and dmx_asic>=6 	else
			0;
			
qt_axis<='0' when dmx_asic<=5 	and dmx_asic>=1 	else
			'1' when dmx_asic<=10 	and dmx_asic>=6 	else
			'0';



pswfifo_clk<=clk;
bram_addrb<=wav_bram_addrb;
wav_doutb<=bram_doutb;

qt_rd_clk		<=qt_fifo_rd_clk;
qt_rd_en			<=qt_fifo_rd_en;
qt_fifo_dout 	<=qt_dout;
qt_fifo_empty	<=qt_empty;
qt_fifo_almost_empty<=qt_almost_empty;

	Inst_PedRAMaccess: PedRAMaccess PORT MAP(
		clk => clk,
		addr => ped_sa_num,
		rval0 => ped_sa_rval0,
		rval1 => ped_sa_rval1,
		wval0 => "000000000000",
		wval1 => "000000000000",
		rw => '0',-- read only
		update => ped_sa_update,
		busy => ped_sa_busy,
		ram_addr => ram_addr,
		ram_datar => ram_data,
		ram_dataw => open,--"00000000",
		ram_rw => open,--'0',
		ram_update => ram_update,
		ram_busy => ram_busy
	);

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
u_pedarr : blk_mem_gen_v7_3
  PORT MAP (
    clka => clk,
    wea => ped_wea,
    addra => ped_bram_addra,
    dina => ped_dina(11 DOWNTO 0),
    clkb => clk,
    addrb => ped_bram_addrb,
    doutb => ped_doutb(11 DOWNTO 0)
  );

u_qtfifo : qt_fifo
  PORT MAP (
    rst => qt_rst,
    wr_clk => clk,
    rd_clk => qt_rd_clk,
    din => qt_din,
    wr_en => qt_wr_en,
    rd_en => qt_rd_en,
    dout => qt_dout,
    full => qt_full,
    empty => qt_empty,
    almost_empty => qt_almost_empty

  );
  
--u_wavarr : blk_mem_gen_v7_3
--  PORT MAP (
--    clka => clk,
--    wea => wav_wea,
--    addra => wav_bram_addra,
--    dina => wav_dina(11 DOWNTO 0),
--    clkb => clk,
--    addrb => wav_bram_addrb,
--    doutb => wav_doutb(11 DOWNTO 0)
--  );


-- INST_TAG_END ------ End INSTANTIATION Template ------------
--busy<=ped_sub_send_data_busy or ped_sub_fetch_busy;
busy<=busy_i;

first_asic_no<= 
			x"1" when asic_en_bits_i(0)='1' else
			x"2" when asic_en_bits_i(1)='1' else
			x"3" when asic_en_bits_i(2)='1' else
			x"4" when asic_en_bits_i(3)='1' else
			x"5" when asic_en_bits_i(4)='1' else
			x"6" when asic_en_bits_i(5)='1' else
			x"7" when asic_en_bits_i(6)='1' else
			x"8" when asic_en_bits_i(7)='1' else
			x"9" when asic_en_bits_i(8)='1' else
			x"A" when asic_en_bits_i(9)='1' else
			x"0";

last_asic_no<= 
			x"A" when asic_en_bits_i(9)='1' else
			x"9" when asic_en_bits_i(8)='1' else
			x"8" when asic_en_bits_i(7)='1' else
			x"7" when asic_en_bits_i(6)='1' else
			x"6" when asic_en_bits_i(5)='1' else
			x"5" when asic_en_bits_i(4)='1' else
			x"4" when asic_en_bits_i(3)='1' else
			x"3" when asic_en_bits_i(2)='1' else
			x"2" when asic_en_bits_i(1)='1' else
			x"1" when asic_en_bits_i(0)='1' else
			x"0";


process(clk)
begin

	if (rising_edge(clk)) then
	fifo_en_i<=fifo_en;
	fifo_din_i<=fifo_din;
	enable_i<=enable;
	calc_mode_i<=calc_mode;
	trig_ctime_i<=trig_ctime;
	
	
	if (trigin_i(1 downto 0) = "01") then
		SMP_MAIN_CNT_i<=SMP_MAIN_CNT;
		asic_en_bits_i<=asic_en_bits;
	end if;

	end if;

end process;


process(clk) -- pedestal fetch
begin

if (rising_edge(clk)) then
-- take care of trigger 
case st_trgrec is

	when trg_rec_idle =>
		trgrec<=trgrec;
		trig_bram_cnt<=0;
		if (trigin_i="01"  and enable_i='1' and asic_no/=x"0") then
			st_trgrec<=trg_rec_win00;
			trig_bram_sel<='1';
		else
			trig_bram_sel<='0';
			st_trgrec<=trg_rec_idle;
		end if;
		
	when trg_rec_win00 =>
			trig_bram_start_addr_i<=win_addr_start_i;
			trig_asic_no_i<=asic_no_i;
			st_trgrec<=trg_rec_win0;

	when trg_rec_win0 =>	
		trgrec<=trgrec;
		trig_bram_addr<=std_logic_vector(to_unsigned(trig_bram_start_addr_i+trig_bram_cnt,9));
		st_trgrec<=trg_rec_win1;
		
	when trg_rec_win1 =>
		trgrec<=trgrec;
		st_trgrec<=trg_rec_win2;

	when trg_rec_win2 =>
		trgrec((trig_bram_cnt*5+4) downto (trig_bram_cnt*5))<=trig_bram_data((trig_asic_no_i*5-1) downto (trig_asic_no_i*5-5));
		trig_bram_cnt<=trig_bram_cnt+1;
		st_trgrec<=trg_rec_win3;

	when trg_rec_win3 =>
		trgrec<=trgrec;
		if (trig_bram_cnt = 5) then
			st_trgrec<=trg_rec_idle;
		else
			st_trgrec<=trg_rec_win0;
		end if;
			
		

end case;


end if;






if (rising_edge(clk)) then

	case next_ped_st is 

	When PedsIdle =>
	if (trigin_i="01"  and enable_i='1' and asic_no/=x"0") then
		ped_asic<=to_integer(unsigned(asic_no));
		ped_ch  <=0;
		ped_win <=0;
		ped_sa  <=0;
		ped_sub_fetch_busy<='0';
		next_ped_st<=PedsFetchPedVal;
	end if ;

	When PedsFetchPedVal =>
		ped_sub_fetch_busy<='1';
		ped_sa_num(21 downto 18)<=std_logic_vector(to_unsigned(asic_no_i-1,4));--		: std_logic_vector(21 downto 0);
		ped_sa_num(17 downto 14)<=std_logic_vector(to_unsigned(ped_ch,4));--		: std_logic_vector(21 downto 0);
		ped_sa_num(13 downto 5) <=std_logic_vector(to_unsigned(ped_win+win_addr_start_i,9));
		ped_sa_num(4  downto 0) <=std_logic_vector(to_unsigned(ped_sa,5));
		ped_sa_update<='1';
		ped_wea<="0";
		next_ped_st<=PedsFetchPedValWaitSRAM1;
	
	When PedsFetchPedValWaitSRAM1 =>
		--wait for ram_busy to come up
		ped_arr_addr<=ped_sa_num(17 downto 14) & std_logic_vector(to_unsigned(ped_win,2)) & ped_sa_num(4 downto 0);
		next_ped_st<=PedsFetchPedValWaitSRAM2;
	
	When PedsFetchPedValWaitSRAM2 =>
		ped_sa_update<='0';
		if (ped_sa_busy='1') then
				next_ped_st<=PedsFetchPedValWaitSRAM2;
		else
				next_ped_st<=PedsFetchPedValWaitSRAM3;
		end if;

	When PedsFetchPedValWaitSRAM3=>
			ped_bram_addra<=ped_arr_addr;
			ped_dina<=ped_sa_rval0;
			ped_wea<="1";
			ped_sa<=ped_sa+2;
			next_ped_st<=PedsFetchRedValWR1;

	When PedsFetchRedValWR1=>
			ped_bram_addra<=std_logic_vector(to_unsigned(to_integer(unsigned(ped_arr_addr))+1,11));
			ped_dina<=ped_sa_rval1;
			ped_wea<="1";
			next_ped_st<=PedsFetchCheckSample;
				
	When PedsFetchCheckSample=>
			ped_wea<="0";
			if (ped_sa<NSamplesPerWin) then
				next_ped_st<=PedsFetchPedVal;
			else
				ped_sa<=0;
				ped_win<=ped_win+1;
				next_ped_st<=PedsFetchCheckWin;
			end if;

	When PedsFetchCheckWin=>
			if (ped_win<NWWin) then
				next_ped_st<=PedsFetchPedVal;
			else
				ped_win<=0;
				ped_ch<=ped_ch+1;
				next_ped_st<=PedsFetchCheckCH;
			end if;
	
	When PedsFetchCheckCH=>
			if (ped_ch<NCHPerTX) then
				next_ped_st<=PedsFetchPedVal;
			else
				next_ped_st<=PedsFetchDone;
			end if;
					
	When PedsFetchDone =>
		ped_sub_fetch_busy<='0';
		ped_sub_fetch_done<='1';
		next_ped_st<=PedsIdle;
	--done Fetching pedestals
	

	When others =>
		next_ped_st<=PedsIdle;

	end case;


end if;
 

if (rising_edge(clk)) then
	
	trigin_i(1)<=trigin_i(0);
	trigin_i(0)<=trigin;
	
	-- give it enough time till the win addr and other information become available
	
	if (trigin_i="01" and enable_i='1') then
			busy_i<='1';
			asic_no_i<=to_integer(unsigned(asic_no));
			win_addr_start_i<=to_integer(unsigned(win_addr_start));
			ped_sub_fetch_done<='0';
			dmx_asic<=to_integer(unsigned(asic_no));

--		if (asic_no=x"0") then
--			send_empty_packet<='1';
--		else
--			send_empty_packet<='0';
--		end if;
		
	end if;

	ped_sub_start(1)<=ped_sub_start(0);
	ped_sub_start(0)<=dmx_allwin_done and ped_sub_fetch_done;

	
case pedsub_st is

When pedsub_idle =>
--	qt_wr_en	<='1';
	wav_bram_addrb<="00000000000";
	ped_bram_addrb<="00000000000";
	qt_wr_en	<='0';
	qt_fifo_evt_rdy<='0';
	if (asic_no/=x"0") then 
		if (ped_sub_start="01" and enable_i='1') then 
			sa_cnt<=0;
			pswfifo_en<='0';
			ped_sub_send_data_busy<='1';
			pedsub_st<=pedsub_sub_pre;
		else 
			pswfifo_en<='0';
			ped_sub_send_data_busy<='0';
			pedsub_st<=pedsub_idle;
		end if;
	else
		if (trigin_i="01" and enable_i='1') then
			ped_sub_send_data_busy<='1';
			ct_cnt<=0;
			pedsub_st<=pedsub_dump_qt1;
		end if;
		
	end if;
	
		
When pedsub_sub_pre =>
		pswfifo_d<=x"FE" & std_logic_vector(to_unsigned(dmx_asic,4)) & "00" & SMP_MAIN_CNT_i & std_logic_vector(to_unsigned(win_addr_start_i,9)) ;
		pswfifo_en<='1';
		if (calc_mode_i=x"0") then --peak search mode
			ct_lpv<=(others=> x"000");
		elsif (calc_mode_i=x"1") then --trough search mode
			ct_lpv<=(others=> x"FFF");
		end if;
		samem(0)<=(others=>'0');
		samem(1)<=(others=>'0');
		samem(2)<=(others=>'0');
		pedsub_st<=pedsub_sub_pre2;

When pedsub_sub_pre2 =>
		pedsub_st<=pedsub_sub;



When pedsub_sub=>--read from bram and send out to FIFO
	   pswfifo_en<='0';
		wav_bram_addrb<=std_logic_vector(to_unsigned(sa_cnt,11));
		ped_bram_addrb<=std_logic_vector(to_unsigned(sa_cnt,11));
 		pedsub_st<=pedsub_sub0wait;
		
When pedsub_sub0wait=>
 		pedsub_st<=pedsub_sub0;

When pedsub_sub0=>
	   pswfifo_en<='0';
		ct_ch<=to_integer(unsigned(wav_bram_addrb(10 downto 7)));
		ct_sa<=wav_bram_addrb(6 downto 0);
		if (mode="01") then 
--			sapedsub<=(to_signed(to_integer(unsigned(wav_doutb))-to_integer(unsigned(ped_doutb)),12 ));
			sapedsub<=(unsigned('0' & wav_doutb)+('0' & x"D48")-unsigned('0' & ped_doutb));
		end if;
		if (mode="10") then 
			sapedsub<=unsigned('0' & ped_doutb);
		end if;
		if (mode="11") then 
			sapedsub<=unsigned('0' & wav_doutb);
		end if;
 		pedsub_st<=pedsub_sub1;

When pedsub_sub1=>
	   pswfifo_en<='0';
		samem(2)<=samem(1);
		samem(1)<=samem(0);
		samem(0)<=sapedsub(11 downto 0);
		pedsub_st<=pedsub_sub2;

when pedsub_sub2=>
		if (calc_mode_i=x"0") then --calc peak
			if (samem(1)>samem(2) and samem(1)>=samem(0)) then --we have a peak! add to peak memory if larger than previous peak
				if (samem(1)>ct_lpv(ct_ch)) then 
					ct_lpv(ct_ch)<=samem(1);
					ct_lpt(ct_ch)<="00000" & unsigned(ct_sa);-- sample offset from the beginning of the 4 windows
				end if;			
			end if;
		elsif (calc_mode_i=x"1") then  --calc trough
			if (samem(1)<samem(2) and samem(1)<=samem(0)) then --we have a peak! add to peak memory if larger than previous peak
				if (samem(1)<ct_lpv(ct_ch)) then 
					ct_lpv(ct_ch)<=samem(1);
					ct_lpt(ct_ch)<="00000" & unsigned(ct_sa);-- sample offset from the beginning of the 4 windows
				end if;			
			end if;
		end if;
		
		pswfifo_d<=x"BD" & '0' & std_logic_vector(to_unsigned(sa_cnt,11)) & std_logic_vector(sapedsub(11 downto 0));
		pswfifo_en<='1';
		if (ct_sa="1111111") then -- reset buffer at the end of a channel
			samem(0)<=(others=>'0');
			samem(1)<=(others=>'0');
			samem(2)<=(others=>'0');
		end if;
		
		pedsub_st<=pedsub_inc_sa_cnt;
		
when pedsub_inc_sa_cnt=>
		pswfifo_en<='0';
		sa_cnt<=sa_cnt+1;
		if (sa_cnt>NSamplesPerWin*NWWIN*16-2) then
				--start_calc_CT<='1';-- start calculating charge and time
				--now dump the C&T buffer into FIFO
				ct_cnt<=0;
				pedsub_st<=pedsub_dumpct;
		else 
				pedsub_st<=pedsub_sub;
		end if;
		
when pedsub_dumpct=>
		pswfifo_en<='0';
		if (ct_cnt<16) then
			pedsub_st<=pedsub_dumpct2;
		else
			pedsub_st<=pedsub_dump_trigrec;
		end if;
		
when pedsub_dumpct2=>
		pswfifo_d<=x"CB" & std_logic_vector(to_unsigned(ct_cnt,4))  & '0' & std_logic_vector(ct_lpt(ct_cnt)(6 downto 0)) & std_logic_vector(ct_lpv(ct_cnt)(11 downto 0));-- charge and time
		ct_cnt<=ct_cnt+1;
		pswfifo_en<='1';
		pedsub_st<=pedsub_dumpct;

when pedsub_dump_trigrec =>
		pswfifo_d<=x"CF" & std_logic_vector(to_unsigned(dmx_asic,4)) & trgrec;
		pswfifo_en<='1';
		pedsub_st<=pedsub_dumpfooter;

when pedsub_dumpfooter=>
		pswfifo_en<='1';
		pswfifo_d<=x"E0F1E0F1";
		pedsub_st<=pedsub_dumpfooter2;
		
when pedsub_dumpfooter2=>
		pswfifo_en<='1';
		pswfifo_d<=x"FACEFACE";
		ct_cnt<=0;
		pedsub_st<=pedsub_dump_qt1;


when pedsub_dump_qt1=>
		pswfifo_en<='0';
		qt_wr_en	<='1';
		if ct_cnt=0 and std_logic_vector(to_unsigned(dmx_asic,4))=first_asic_no then
--			qt_din	<="10" & x"FE" & std_logic_vector(to_unsigned(dmx_asic,4)) & std_logic_vector(to_unsigned(ct_cnt,4));
			qt_din	<="10" & x"80" & qt_axis & std_logic_vector(to_unsigned(qt_chno,7));
		else
			qt_din	<="11" & x"80" & qt_axis & std_logic_vector(to_unsigned(qt_chno,7));
		end if;
		pedsub_st<=pedsub_dump_qt2;

when pedsub_dump_qt2=>
		qt_wr_en	<='1';
--		if (asic_no/=x"0") then 
			qt_din	<="11" & trig_ctime_i;
--		else 
--			qt_din	<="11" & x"ABC0";
--		end if;
		
		pedsub_st<=pedsub_dump_qt3;

when pedsub_dump_qt3=>
		qt_wr_en	<='1';
		if (asic_no/=x"0") then 
			qt_din	<="11" & std_logic_vector(to_unsigned(win_addr_start_i,9)) & std_logic_vector(ct_lpt(ct_cnt)(6 downto 0));
		else 
			qt_din	<="11" & x"DEF1";
		end if;
		
		pedsub_st<=pedsub_dump_qt4;

when pedsub_dump_qt4=>
		qt_wr_en	<='1';
--		qt_din	<="0000" & std_logic_vector(ct_lpv(ct_cnt)(11 downto 0));
		if ct_cnt=15 and std_logic_vector(to_unsigned(dmx_asic,4))=last_asic_no then
			qt_din	<="01" & x"0E0A";-- end of asic
		else
			if (asic_no/=x"0") then 
				qt_din	<=	"11" & x"D" & std_logic_vector(ct_lpv(ct_cnt)(11 downto 0));
			else
				qt_din	<=	"11" & x"BAC2";
			end if;
		end if;
			
		ct_cnt<=ct_cnt+1;
		pedsub_st<=pedsub_dump_qt_chk;

when pedsub_dump_qt_chk=>
		qt_wr_en	<='0';
		qt_fifo_evt_rdy<='0';
		if (ct_cnt/=16) then 
			pedsub_st<=pedsub_dump_qt1;
		else
			pedsub_st<=pedsub_dump_qt_footer;
		end if;

when pedsub_dump_qt_footer=>
		qt_wr_en	<='0';
--		qt_din	<=x"0E0A";-- end of asic
		qt_fifo_evt_rdy<='0';
		pedsub_st<=pedsub_dump_qt_evt_rdy;

when pedsub_dump_qt_evt_rdy=>
		if std_logic_vector(to_unsigned(dmx_asic,4))=last_asic_no then
			qt_fifo_evt_rdy<='1';
		else 
			qt_fifo_evt_rdy<='0';
		end if;
		qt_wr_en	<='0';
		pedsub_st<=pedsub_dump_qt_evt_rdy2;

when pedsub_dump_qt_evt_rdy2=>
		pedsub_st<=pedsub_dump_qt_evt_rdy3;

when pedsub_dump_qt_evt_rdy3=>
		busy_i<='0';
		pedsub_st<=pedsub_idle;
		


when others=>
		pedsub_st<=pedsub_idle;
		
end case;





end if;

end process;



end Behavioral;

