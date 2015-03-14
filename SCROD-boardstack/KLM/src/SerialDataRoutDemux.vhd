-- Description:
--	Function: 
--	Modifications:
--

Library work;
use work.all;

Library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use work.readout_definitions.all;
use IEEE.NUMERIC_STD.ALL;


entity SerialDataRoutDemux is
   port (
        clk		 			 : in   std_logic;
        start	    		 : in   std_logic;  -- start serial readout
		  restart			 : in		std_logic;-- reset the dmx_win counter
		  calc_peds_en		 :	in std_logic;-- enable pedestal calculation mode- will start averaging sampels to create pedestals and write to BRAM- edge sensitive restart for averaging window counter.
		  navg				 : in std_logic_vector(3 downto 0);-- 2**navg= number of reads to average.
		  
		  EVENT_NUM			 : in   std_logic_vector(31 downto 0);
		  WIN_ADDR			 : in   std_logic_vector(8 downto 0);
		  ASIC_NUM 		    : in   std_logic_vector(3 downto 0);
		  force_test_pattern : in   std_logic;
		  
		  IDLE_status		: out  std_logic;
		  busy				 : out  std_logic;
        samp_done	       : out  std_logic;  -- indicate that all sampled processed

        dout             : in   std_logic_vector(15 downto 0);
        sr_clr           : out  std_logic;     -- Unused set to 0
        sr_clk           : out  std_logic;     -- start slow at 125/2	=62.5MHz
        sr_sel           : out  std_logic;     -- 1 -latch data, 0 - shift
		  samplesel 	    : out  std_logic_vector(4 downto 0);
        smplsi_any       : out  std_logic;     -- off during conversion
		  
		  dmx_allwin_done	 : out std_logic;
		  
			srout_bram_dout: out STD_LOGIC_VECTOR(19 DOWNTO 0);--:=x"000";
			srout_bram_addr: in std_logic_vector(10 downto 0);--:="00000000000";		  
		  
		  fifo_wr_en		 : out  std_logic;
		  fifo_wr_clk		 : out  std_logic;
		  fifo_wr_din		 : out  std_logic_vector(31 downto 0)
       );
end SerialDataRoutDemux;

architecture Behavioral of SerialDataRoutDemux is
	
	COMPONENT srout_bram_blkmem
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(19 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(19 DOWNTO 0)
  );
END COMPONENT;


	--time samplesel_any is held high
	constant ADDR_TIME : integer:=6;
	constant LOAD_TIME :  integer:=6;
	constant LOAD_TIME1 : integer:=6;
	constant LOAD_TIME2 :  integer:=6;
	constant CLK_CNT_MAX : integer:=12; -- (11+1)->12 clk -> 12 bits

   type sr_overall_type is
	(
	Idle,				  -- Idling until command start bit and store size	
	CheckBusy,
	CheckSampleSel,	    
	StartSROutProcess,	   
	WaitSROutProcess
	);
	signal next_overall					: sr_overall_type := Idle;

	type sr_state_type is
	(
	Idle,				  -- Idling until command start bit and store size	
	WaitStart,
	LoadHeader,
	LoadHeader2,
	WaitAddr,	    -- Wait for address to settle, need docs to finilize
	WaitLoad,	    -- Wait for load cmd to settle, need docs to finilize
	WaitLoad1,	    -- Wait for load cmd to settle relatively to clk, need docs to finilize
	WaitLoad1a,
	WaitLoad2,	    -- Wait for load cmd to settle relatively to clk, need docs to finilize
	clkHigh,	    -- Clock high, now at 62.5 MHz ,can investigate later at higher speed
	clkHighHold,
	clkLow,	      -- Clock low, now at 62.5 MHz ,can investigate later at higher speed
	clkLowHold,	      -- Clock low, now at 62.5 MHz ,can investigate later at higher speed
	StoreDataSt,	  -- Store shifted in data
	StoreDataStWait,
	StoreDataEnd,
	CheckWindowEnd,
	WaitCheckDone,
	WaitCheckDone2,
	WaitCheckDone3
	);
	
	signal next_state						: sr_state_type := Idle;
	signal internal_start 				: std_logic := '0';
	signal internal_start_reg 			: std_logic_vector(1 downto 0) := (others=>'0');
   signal internal_start_srout 		: std_logic := '0';
	signal internal_busy 				: std_logic := '0';
	signal internal_srout_busy 		: std_logic := '0';
	signal sr_clk_i  	     				: std_logic := '0';
	signal Ev_CNT     	  				: integer:=0;
	signal BIT_CNT     	 			  	: integer:=0;
	signal sr_clk_d        				: std_logic := '0';
	signal start_fifo						:	STD_LOGIC := '0';
	signal FifoDone						:	STD_LOGIC := '0';
	signal FifoCount						:	STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');
	signal SAMP_DONE_out 				: STD_LOGIC := '0';
	--signal rd_cs_s     					: STD_LOGIC_VECTOR(5 downto 0) := (others=>'0');
	--signal rd_rs_s     					: STD_LOGIC_VECTOR(2 downto 0) := (others=>'0');
	signal dout_i							: std_logic_vector(15 downto 0):="1100110000110011";
	signal internal_samplesel : std_logic_vector(5 downto 0) := (others=>'0');
	signal internal_idle : STD_LOGIC := '0';
	
	signal chan_data : STD_LOGIC_VECTOR(3 downto 0) := (others=>'0');
	signal internal_fifo_wr_din : STD_LOGIC_VECTOR(31 downto 0) := (others=>'0');
signal dmx_win					:std_logic_vector(1 downto 0):="00";
--signal dmx_allwin_done		: std_logic:='0';
signal dmx_wav					: WaveTempArray:=(x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");

signal bram_we			: std_logic_vector(0 downto 0):="0";
signal bram_din			: STD_LOGIC_VECTOR(19 DOWNTO 0):="00000000000000000000";
signal bram_dout		: STD_LOGIC_VECTOR(19 DOWNTO 0);
signal bram_addr	: std_logic_vector(10 downto 0):="00000000000";
signal start_tmp2bram_xfer: std_logic:='0';
signal start_bram2tmp_xfer: std_logic:='0';

signal tmp2bram_ctr	: std_logic_vector(7 downto 0):=x"00";
signal bram2tmp_ctr	: std_logic_vector(7 downto 0):=x"00";
signal jdx0						: std_logic_vector(6 downto 0);
signal restart_i: std_logic_vector(1 downto 0):="00";
signal restart_peds_i: std_logic_vector(1 downto 0):="00";
signal calc_peds_en_i:std_logic:='0';
signal jdx_bram2tmp			:std_logic_vector(6 downto 0);
signal jdx_tmp2bram			:std_logic_vector(6 downto 0);
signal navg_i					:std_logic_vector(3 downto 0):="0000";
signal pedarray_tmp			: WaveWideTempArray;
signal pedarray_tmp2		: WaveWideTempArray;-- added for pipelining
signal navgcnt			: integer:=0;
signal ncnt				: integer:=0;


type bram2tmp_state is
(
st_bram2tmp_waitstart,
st_bram2tmp_check_ctr,
st_bram2tmp_fetch1,
st_bram2tmp_fetch2,
st_bram2tmp_fetch3
);
signal st_bram2tmp				: bram2tmp_state:=st_bram2tmp_waitstart;


type tmp_to_bram_state is
(
st_tmp2bram_waitstart,
st_tmp2bram_check_ctr,
st_tmp2bram_store1,
st_tmp2bram_store2
);
 
signal st_tmp2bram				: tmp_to_bram_state:=st_tmp2bram_waitstart;

----------------------------------------
begin

sr_clk <= sr_clk_i;
SAMP_DONE <= SAMP_DONE_out;
samplesel <= internal_samplesel(4 downto 0);
fifo_wr_clk <= clk;
fifo_wr_din <= internal_fifo_wr_din;
busy <= internal_busy;
IDLE_status <= internal_idle;


ncnt	<= 1   when navg_i=x"0" else
			2   when navg_i=x"1" else
			4   when navg_i=x"2" else
			8   when navg_i=x"3" else
			16  when navg_i=x"4" else
			32  when navg_i=x"5" else
			64  when navg_i=x"6" else
			128 when navg_i=x"7" else
			0 ;

u_srout_bram : srout_bram_blkmem
  PORT MAP (
    clka 	=> clk,
    wea 		=> bram_we,
    addra 	=> bram_addr,
    dina 	=> bram_din,
    douta 	=> bram_dout,
    clkb 	=> clk,
    web 		=> "0",
    addrb 	=> srout_bram_addr,
    dinb 	=>x"00000" ,
    doutb 	=> srout_bram_dout
  );

--delay by one clock for proper latch
process (clk) is
begin
if (clk'event and clk = '1') then
  sr_clk_d <= sr_clk_i;  
  internal_start <= start;  
  dout_i<=dout;
end if;
end process;

--detect start rising edge
process (clk) is
begin
	if (clk'event and clk = '1') then
		internal_start_reg(1) <= internal_start_reg(0);  
		internal_start_reg(0) <= internal_start;  
		
		navg_i<=navg;
		calc_peds_en_i<=calc_peds_en;
	end if;
end process;

--process iterates 32 times after start_srout goes HIGH, incrementing samplesel and starting signal process
process(Clk)
begin
if (Clk'event and Clk = '1') then
  Case next_overall is
  
  When Idle =>
	
	 internal_busy <= '0';
    internal_samplesel <= (others=>'0');
	 internal_start_srout <= '0';
	 internal_idle <= '1';
    if( internal_start_reg(1 downto 0) = "01" ) then   -- start (readout initiated)
      next_overall 		  <= CheckBusy;
    else
      next_overall 		<= Idle;
    end if;

	--wait here in case SRout process still active, shouldn't happen ever
   When CheckBusy =>
	internal_busy <= '1';
	internal_idle <= '0';
	if( internal_srout_busy = '1' ) then
		next_overall 		  <= CheckBusy;
	else
		next_overall 		<= CheckSampleSel;
   end if;
	
	--check to see if all 32 samles read out
	When CheckSampleSel =>
    if( internal_samplesel >= "100000" ) then
		next_overall 		  <= Idle;
	 else
		next_overall	  <= StartSROutProcess;
	 end if;
	
	--start SRout process and wait for busy to go high
	When StartSROutProcess =>
	 internal_start_srout <= '1';
    if( internal_srout_busy = '1' ) then
		next_overall 		  <= WaitSROutProcess;
	 else
		next_overall	  <= StartSROutProcess;
	 end if;
	 
	--wait for busy to go low, then increment samplesel
	When WaitSROutProcess =>
	 internal_start_srout <= '0';
	 if( internal_srout_busy = '1' ) then
		next_overall 		  <= WaitSROutProcess;
	 else
		internal_samplesel <= std_logic_vector(to_unsigned(to_integer(unsigned(internal_samplesel)) + 1,6));
		next_overall	<= CheckSampleSel;
    end if;
	 
   When Others =>
    internal_samplesel <= (others=>'0');
	 internal_start_srout <= '0';
	 next_overall	  <= Idle;
	 
	end case;
end if;
end process;

--process asserts actual signals needed for serial readout
process(Clk)
begin
if (Clk'event and Clk = '1') then
  --sr_clr            <= '0'; --doesn't do anything
  	start_tmp2bram_xfer<='0';
	start_bram2tmp_xfer<='0';

 restart_i<=restart_i(0) & restart;
 restart_peds_i<=restart_peds_i(0) & calc_peds_en;

 if(restart_i="01") then
	dmx_allwin_done<='0';
	dmx_win<="00";
 end if;
 
 if(restart_peds_i="01") then
	dmx_allwin_done<='0';
	navgcnt<=0;
 end if;

		
  Case next_state is
  
  When Idle =>
--  	bram_addr<="00000000000";
--	bram_din<="00000000000000000000";

    sr_clr            <= '1'; --doesn't do anything
  sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    SAMP_DONE_out    <= '0';
    Ev_CNT           <= 0;
	 BIT_CNT				<= 0;
	 smplsi_any       <= '0';
	 --start_fifo 		<= '0';
	 fifo_wr_en			<= '0';
	 internal_srout_busy <= '0';
	 internal_fifo_wr_din <= (others=>'0');
    if( internal_start_srout = '1') then   -- start (readout initiated)
      next_state 		  <= WaitStart;
    else
      next_state 		<= Idle;
    end if;
	 
   --delay some number of clock cycles
   When WaitStart =>
	  sr_clr            <= '0'; --doesn't do anything

    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    SAMP_DONE_out    <= '0';
	 BIT_CNT				<= 0;
	 smplsi_any       <= '0';
	 internal_srout_busy <= '1';
    if (Ev_CNT < ADDR_TIME) then   -- start (trigger was detected)
      Ev_CNT <= Ev_CNT + 1;
      next_state 	<= WaitStart;
    else
      Ev_CNT           <= 0;
      --next_state 	<= WaitAddr;
		next_state 	<= LoadHeader;
    end if;
	
	--load initial sample packet header
	When LoadHeader =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    SAMP_DONE_out    <= '0';
	 BIT_CNT				<= 0;
	 smplsi_any       <= '0';
	 fifo_wr_en			<= '1';
	 internal_fifo_wr_din <= x"ABC" & '0' & WIN_ADDR & ASIC_NUM & '0' & internal_samplesel(4 downto 0);
    jdx0<=dmx_win & internal_samplesel(4 downto 0);
	 internal_srout_busy <= '1';
      next_state 	<= LoadHeader2;

	
	--so dumb, temporaroily add second header word to deal with dumb FIFO buffer process
	When LoadHeader2 =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    SAMP_DONE_out    <= '0';
	 BIT_CNT				<= 0;
	 smplsi_any       <= '0';
	 fifo_wr_en			<= '1';
	 internal_fifo_wr_din <= x"ABC" & '0' & WIN_ADDR & ASIC_NUM & '0' & internal_samplesel(4 downto 0);
	 internal_srout_busy <= '1';
	
      next_state 	<= WaitAddr;
		
	--turn smplsi_any on, wait to settle
   When WaitAddr =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= not force_test_pattern; -- <='0' inorder to force test pattern;
    SAMP_DONE_out        <= '0';
	 --start_fifo 		<= '0';
	 fifo_wr_en			<= '0';
    if (Ev_CNT < ADDR_TIME) then   -- start (trigger was detected)
      Ev_CNT <= Ev_CNT + 1;
      next_state 	<= WaitAddr;
    else
      Ev_CNT           <= 0;
      next_state 	<= WaitLoad;
    end if;

	--turn sr_sel on, wait to settle
   When WaitLoad =>
	 sr_sel  	       <= '1';
    smplsi_any       <= not force_test_pattern; -- <='0' inorder to force test pattern;
    SAMP_DONE_out        <= '0';
    if (Ev_CNT < LOAD_TIME) then
      Ev_CNT <= Ev_CNT + 1;
		sr_clk_i  	       <= '0';
      next_state 	<= WaitLoad;
    else
      Ev_CNT           <= 0;
		sr_clk_i  	       <= '1';
      next_state 	<= WaitLoad1;
    end if;

	--turn sr_clk_i on, wait to settle
	--turn off sr_sel and sr_clk_i on transition
   When WaitLoad1 =>
    smplsi_any       <= not force_test_pattern; -- <='0' inorder to force test pattern;
    SAMP_DONE_out        <= '0';
    if (Ev_CNT < LOAD_TIME1) then
      Ev_CNT <= Ev_CNT + 1;
      sr_sel  	       <= '1';
		sr_clk_i  	       <= '1';
      next_state 	<= WaitLoad1;
    else
      Ev_CNT           <= 0;
      sr_sel  	       <= '0';
--      sr_sel  	       <= '1'; this line commented out on 12/4/2014 to make the code resemble the original
		sr_clk_i  	       <= '0';
      next_state 	<= WaitLoad2;
    end if;

	 
	--turn off sr_sel and sr_clk_i on transition
   When WaitLoad2 =>
    smplsi_any       <= not force_test_pattern; -- <='0' inorder to force test pattern;
    SAMP_DONE_out        <= '0';
	 sr_sel  	       <= '0';
	 sr_clk_i  	       <= '0';
    if (Ev_CNT < LOAD_TIME1) then
      Ev_CNT <= Ev_CNT + 1;
      next_state 	<= WaitLoad2;
    else
      Ev_CNT           <= 0;
      --next_state 	<= ClkHigh;
		next_state 	<= StoreDataStWait;
    end if; 
	
	--hold sr_clk_i high
   When ClkHigh =>
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
    SAMP_DONE_out        <= '0';
	 Ev_CNT           <= 0;
	 if (BIT_CNT=3) then
	 jdx_bram2tmp<=jdx0;
		if (calc_peds_en_i='1') then --we are in pedestal calculation mode- start fetching from bram to temp array for averaging.
			start_bram2tmp_xfer<='1';
		end if;
	 end if;
	 
    if (BIT_CNT < CLK_CNT_MAX) then
      sr_clk_i  	       <= '1';
      next_state 	<= ClkHighHold;
    else
      sr_clk_i  	       <= '0';
      --next_state 	<= StoreDataSt;
	  --done w the bits, save the samples into temp. 
	  if (navgcnt=0) then
			pedarray_tmp2((0 ))<=x"00" & dmx_wav(0  );
			pedarray_tmp2((1 ))<=x"00" & dmx_wav(1  );
			pedarray_tmp2((2 ))<=x"00" & dmx_wav(2  );
			pedarray_tmp2((3 ))<=x"00" & dmx_wav(3  );
			pedarray_tmp2((4 ))<=x"00" & dmx_wav(4  );
			pedarray_tmp2((5 ))<=x"00" & dmx_wav(5  );
			pedarray_tmp2((6 ))<=x"00" & dmx_wav(6  );
			pedarray_tmp2((7 ))<=x"00" & dmx_wav(7  );
			pedarray_tmp2((8 ))<=x"00" & dmx_wav(8  );
			pedarray_tmp2((9 ))<=x"00" & dmx_wav(9  );
			pedarray_tmp2((10))<=x"00" & dmx_wav(10 );
			pedarray_tmp2((11))<=x"00" & dmx_wav(11 );
			pedarray_tmp2((12))<=x"00" & dmx_wav(12 );
			pedarray_tmp2((13))<=x"00" & dmx_wav(13 );
			pedarray_tmp2((14))<=x"00" & dmx_wav(14 );
			pedarray_tmp2((15))<=x"00" & dmx_wav(15 );	 


			
		else 
			pedarray_tmp2((0 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(0  ))+unsigned(pedarray_tmp(0 )));
			pedarray_tmp2((1 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(1  ))+unsigned(pedarray_tmp(1 )));
			pedarray_tmp2((2 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(2  ))+unsigned(pedarray_tmp(2 )));
			pedarray_tmp2((3 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(3  ))+unsigned(pedarray_tmp(3 )));
			pedarray_tmp2((4 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(4  ))+unsigned(pedarray_tmp(4 )));
			pedarray_tmp2((5 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(5  ))+unsigned(pedarray_tmp(5 )));
			pedarray_tmp2((6 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(6  ))+unsigned(pedarray_tmp(6 )));
			pedarray_tmp2((7 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(7  ))+unsigned(pedarray_tmp(7 )));
			pedarray_tmp2((8 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(8  ))+unsigned(pedarray_tmp(8 )));
			pedarray_tmp2((9 ))<=std_logic_vector(x"00" & unsigned(dmx_wav(9  ))+unsigned(pedarray_tmp(9 )));
			pedarray_tmp2((10))<=std_logic_vector(x"00" & unsigned(dmx_wav(10 ))+unsigned(pedarray_tmp(10)));
			pedarray_tmp2((11))<=std_logic_vector(x"00" & unsigned(dmx_wav(11 ))+unsigned(pedarray_tmp(11)));
			pedarray_tmp2((12))<=std_logic_vector(x"00" & unsigned(dmx_wav(12 ))+unsigned(pedarray_tmp(12)));
			pedarray_tmp2((13))<=std_logic_vector(x"00" & unsigned(dmx_wav(13 ))+unsigned(pedarray_tmp(13)));
			pedarray_tmp2((14))<=std_logic_vector(x"00" & unsigned(dmx_wav(14 ))+unsigned(pedarray_tmp(14)));
			pedarray_tmp2((15))<=std_logic_vector(x"00" & unsigned(dmx_wav(15 ))+unsigned(pedarray_tmp(15)));
		
		end if;
		jdx_tmp2bram<=jdx0;
		start_tmp2bram_xfer<='1';
		
		next_state 	<= CheckWindowEnd;
    end if;
	
	When ClkHighHold =>
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
	 SAMP_DONE_out        <= '0';
	 sr_clk_i  	       <= '1';
	if (Ev_CNT < LOAD_TIME2) then   -- start (trigger was detected)
      Ev_CNT <= Ev_CNT + 1;
		next_state 	<= ClkHighHold;
	else
		Ev_CNT           <= 0;
		next_state 	<= ClkLow;
    end if;
	 
	--hold sr_clk_i low
   When ClkLow =>
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
	 Ev_CNT           <= 0;
    BIT_CNT <= BIT_CNT;
    sr_clk_i  	       <= '0';
    SAMP_DONE_out        <= '0';
	 next_state 	<= ClkLowHold;
	 
   When ClkLowHold =>
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
    BIT_CNT <= BIT_CNT;
    sr_clk_i  	       <= '0';
    SAMP_DONE_out        <= '0';
	 if (Ev_CNT < LOAD_TIME2) then   -- start (trigger was detected)
      Ev_CNT <= Ev_CNT + 1;
		next_state 	<= ClkLowHold;
	else
		Ev_CNT           <= 0;
		next_state 	<= StoreDataStWait;
    end if;
	 
	when StoreDataStWait =>
		next_state 	<= StoreDataSt;
	
	--Start FIFO write process
   When StoreDataSt =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
    SAMP_DONE_out        <= '0';
	--start_fifo		<= '1';
	fifo_wr_en			<= '1';
	internal_fifo_wr_din <= x"DEF" & std_logic_vector(to_unsigned(BIT_CNT,4)) & dout_i;
	dmx_wav(0 )<=dmx_wav(0 )(10 downto 0) & dout_i(0 );
	dmx_wav(1 )<=dmx_wav(1 )(10 downto 0) & dout_i(1 );
	dmx_wav(2 )<=dmx_wav(2 )(10 downto 0) & dout_i(2 );
	dmx_wav(3 )<=dmx_wav(3 )(10 downto 0) & dout_i(3 );
	dmx_wav(4 )<=dmx_wav(4 )(10 downto 0) & dout_i(4 );
	dmx_wav(5 )<=dmx_wav(5 )(10 downto 0) & dout_i(5 );
	dmx_wav(6 )<=dmx_wav(6 )(10 downto 0) & dout_i(6 );
	dmx_wav(7 )<=dmx_wav(7 )(10 downto 0) & dout_i(7 );
	dmx_wav(8 )<=dmx_wav(8 )(10 downto 0) & dout_i(8 );
	dmx_wav(9 )<=dmx_wav(9 )(10 downto 0) & dout_i(9 );
	dmx_wav(10)<=dmx_wav(10)(10 downto 0) & dout_i(10);
	dmx_wav(11)<=dmx_wav(11)(10 downto 0) & dout_i(11);
	dmx_wav(12)<=dmx_wav(12)(10 downto 0) & dout_i(12);
	dmx_wav(13)<=dmx_wav(13)(10 downto 0) & dout_i(13);
	dmx_wav(14)<=dmx_wav(14)(10 downto 0) & dout_i(14);
	dmx_wav(15)<=dmx_wav(15)(10 downto 0) & dout_i(15);
--	dmx_wav((15))<=dmx_win & WIN_ADDR(4 downto 0) & internal_samplesel(4 downto 0);	 
--	dmx_wav((15))<=dmx_win & internal_samplesel(4 downto 0) & "00000";	 
--	dmx_wav(12) <='0' & dmx_win & WIN_ADDR;
--	dmx_wav(13) <="000" & WIN_ADDR;
--	dmx_wav(14) <=dmx_win & internal_samplesel(4 downto 0) & "00000";	 
  
    next_state 	<= StoreDataEnd;
	 
	When StoreDataEnd =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
    SAMP_DONE_out        <= '0';
	 BIT_CNT <= BIT_CNT + 1;
	 --start_fifo 	<= '0';
	 fifo_wr_en			<= '0';
	 next_state 	<= ClkHigh;

	--wait for start signal to go low
   When CheckWindowEnd =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '0';
	 next_state 		<= Idle;
	 --add a footer to end of window
	 internal_fifo_wr_din <= x"FACEFACE";
	 if( internal_samplesel = "011111" ) then
      fifo_wr_en			<= '1';
	  dmx_win<=std_logic_vector(to_unsigned(to_integer(unsigned(dmx_win)) + 1,2));
		if (dmx_win="11") then
			if (calc_peds_en_i='1') then
				if (navgcnt>=(ncnt-1)) then
						next_state<=WaitCheckDone;
				else
					navgcnt<=navgcnt+1;	
				end if;
			else
					navgcnt<=0;
--					dmx_allwin_done<='1';
					next_state<=WaitCheckDone;
			end if;
			
		end if;
	 else
	 	fifo_wr_en			<= '0';
	 end if;
	 
  When WaitCheckDone=>
		if (bram2tmp_ctr/=x"00" or tmp2bram_ctr/=x"00") then
				next_state<=WaitCheckDone;
			else
				next_state <= WaitCheckDone2;			
		end if;
  
    When WaitCheckDone2=>
	 		next_state <= WaitCheckDone3;			

    When WaitCheckDone3=>
			dmx_allwin_done<='1';
			navgcnt<=0;
	 		next_state <= Idle;			


	 
  When Others =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '0';
    Ev_CNT           <= 0;
	 BIT_CNT           <= 0;
    SAMP_DONE_out        <= '0';
	 internal_srout_busy <= '0';
	 fifo_wr_en			<= '0';
	 next_state 		<= Idle;
	end case;
end if;
end process;


tmp2bram_xfre_proc:process(clk) -- pedestal fetch
begin

if (rising_edge(clk)) then

case st_bram2tmp is-- this is a side working FSM just to fetch and fill the temp sample in the BRAM array

when st_bram2tmp_waitstart =>
	if (start_bram2tmp_xfer='0') then
		bram2tmp_ctr<=x"00";
		st_bram2tmp<=st_bram2tmp_waitstart;
	else
		bram2tmp_ctr<=x"10";
		st_bram2tmp<=st_bram2tmp_check_ctr;
	end if;

when st_bram2tmp_check_ctr =>
	if (bram2tmp_ctr=x"00") then
		st_bram2tmp<= st_bram2tmp_waitstart;
		bram_addr<="00000000000";
	else
		bram2tmp_ctr<=std_logic_vector(to_unsigned(to_integer(unsigned(bram2tmp_ctr))-1,8));
		st_bram2tmp<= st_bram2tmp_fetch1;
	end if;
	
when 	st_bram2tmp_fetch1 =>
	if (to_integer(unsigned(bram2tmp_ctr))<16) then
		bram_addr<=bram2tmp_ctr(3 downto 0) & jdx_bram2tmp;--(to_integer(unsigned(tmp2bram_ctr)));
		st_bram2tmp<= st_bram2tmp_fetch2;
		else
		bram_addr<="00000000000";			
		st_bram2tmp<= st_bram2tmp_waitstart;
	end if;

when st_bram2tmp_fetch2 =>
		st_bram2tmp<= st_bram2tmp_fetch3;

when st_bram2tmp_fetch3 =>
	pedarray_tmp(to_integer(unsigned(bram2tmp_ctr)))<=bram_dout;
--	bram_addr<="00000000000";
	st_bram2tmp<=st_bram2tmp_check_ctr;
	
end case;


case st_tmp2bram is-- this is a side working FSM just to store and fill the temp sample in the BRAM array

when st_tmp2bram_waitstart =>
		bram_addr<="00000000000";
		bram_din<=x"00000";

	if (start_tmp2bram_xfer='0') then
		tmp2bram_ctr<=x"00";
		st_tmp2bram<=st_tmp2bram_waitstart;
	else
		tmp2bram_ctr<=x"10";
		st_tmp2bram<=st_tmp2bram_check_ctr;
	end if;

when st_tmp2bram_check_ctr =>
	if (tmp2bram_ctr=x"00") then
		st_tmp2bram<= st_tmp2bram_waitstart;
		bram_addr<="00000000000";
		bram_din<=x"00000";
		bram_we<="0";
	else
			-- make sure BRAM is connected to this then read from temp array and fill BRAM
		tmp2bram_ctr<=std_logic_vector(to_unsigned(to_integer(unsigned(tmp2bram_ctr))-1,8));
		st_tmp2bram<= st_tmp2bram_store1;
	end if;

when 	st_tmp2bram_store1 =>
	if (to_integer(unsigned(tmp2bram_ctr))<16) then
		bram_addr<=tmp2bram_ctr(3 downto 0) & jdx_tmp2bram;--(to_integer(unsigned(tmp2bram_ctr)));
		bram_din<=pedarray_tmp2(to_integer(unsigned(tmp2bram_ctr)));
		bram_we<="1";
	else
		bram_addr<="00000000000";
		bram_din<=x"00000";
		bram_we<="0";
	end if;
	st_tmp2bram<= st_tmp2bram_store2;


when st_tmp2bram_store2 =>
	bram_addr<="00000000000";
	bram_din<=x"00000";
	bram_we<="0";
	st_tmp2bram<=st_tmp2bram_check_ctr;

-- put in different processes
end case;

end if;



end process;










--delay by one clock for proper latch
--process (clk) is
--begin
--if (clk'event and clk = '0') then
--  if( start_fifo = '1') then
--	fifo_wr_en <= '1';
--  else
--   fifo_wr_en <= '0';
--  end if;
--end if;
--end process;

end Behavioral;
