----------------------------------------------------------------------------------
-- Company: UH Manoa - ID LAB
-- Engineer: Isar Mostafanezhad
-- 
-- Create Date:    13:06:51 10/16/2014 
-- Design Name:  WaveformPedcalcDSP
-- Module Name:    WaveformPedcalcDSP - Behavioral 
-- Project Name: 
-- Target Devices: SP6-SCROD rev A4, IDL_KLM_MB RevA (w SRAM)+BRAM
-- Tool versions: 
-- Description: 
--	Creates pedestals and stores in SRAM
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
use work.readout_definitions.all;
 
-- this will creat pedestals for 4 consequetive windows starting with win_addr_start
entity WaveformPedcalcDSP is
port(
			clk		 			 : in   std_logic;
			reset					 : in std_logic; -- resets the waveform buffer in memory and the counter 
			enable				 : in std_logic; -- '0'= disable, '1'= enable
			navg					 : in std_logic_vector(3 downto 0);-- 2**navg= number of reads to average.
			--these 3 signals com form the ReadoutControl module and as soon as they are set and the SR Readout start is asserted, it goes and finds the proper pedestals from SRAM and populates buffer
			SMP_MAIN_CNT		: in std_logic_vector(8 downto 0);-- just to keep track of the sampling window number being written to at the time of trigger
			asic_no				 : in std_logic_vector(3 downto 0);
			win_addr_start		 : in std_logic_vector (8 downto 0);-- start of a 4 window sequence of samples
			trigin				 : in std_logic; -- comes from the readout control module- hooked to the trigger
			busy					 : out std_logic;
			
			dmx_allwin_done	:in std_logic;

			niter					 : out std_logic_vector(15 downto 0); -- route debug info out to top and then a SCROD reg 
			
			--waveform : 
			bram_doutb		: in STD_LOGIC_VECTOR(19 DOWNTO 0);--:=x"000";
			bram_addrb	: out std_logic_vector(10 downto 0);--:="00000000000";		  

			-- steal fifo signal from the srreadout module and demux 
		  fifo_en		 : in  std_logic;
		  fifo_clk		 : in  std_logic;
		  fifo_din		 : in  std_logic_vector(31 downto 0);
		  
		  -- 12 bit Pedestal RAM Access: only for writing pedestals
		   ram_addr 	: OUT  std_logic_vector(21 downto 0);
         ram_data 	: OUT  std_logic_vector(7 downto 0);
         ram_update 	: OUT  std_logic;
         ram_busy 	: IN  std_logic
			
			
);

end WaveformPedcalcDSP;

architecture Behavioral of WaveformPedcalcDSP is
--------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
--COMPONENT blkmem_pedcalc_tmp
--  PORT (
--    clka : IN STD_LOGIC;
--    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
--    dina : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
--    clkb : IN STD_LOGIC;
--    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
--    doutb : OUT STD_LOGIC_VECTOR(19 DOWNTO 0)
--  );
--END COMPONENT;
---- COMP_TAG_END ------ End COMPONENT Declaration ------------
--

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
	
--Latch to clock or trigin
signal asic_no_i			: integer;--std_logic_vector (3 downto 0);-- latched to trigin
signal win_addr_start_i	: integer;--std_logic_vector (9 downto 0);
signal trigin_i			: std_logic_vector(1 downto 0);
--signal ped_sa_num_i		: std_logic_vector(21 downto 0);
signal ped_sa_wval0		: std_logic_vector(11 downto 0);
signal ped_sa_wval1		: std_logic_vector(11 downto 0);
--signal ped_sa_wval0_tmp		: std_logic_vector(11 downto 0);
--signal ped_sa_wval1_tmp		: std_logic_vector(11 downto 0);
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
signal dmx_asic				:integer:=0;
signal dmx_win					:integer:=0;
signal dmx2_win				:std_logic_vector(1 downto 0):="00";
signal dmx_ch					:integer:=0;
signal dmx_sa					:integer:=0;
signal dmx2_sa					:std_logic_vector(4 downto 0):="00000";
signal dmx_bit					:integer:=0;
signal fifo_din_i				:std_logic_vector(31 downto 0);
signal fifo_din_i2			:std_logic_vector(31 downto 0);
signal fifo_en_i				:std_logic:='0';
signal fifo_en_i2				:std_logic:='0';
signal enable_i				:std_logic:='0';
--signal start_ped_sub			:std_logic :='0';
signal sa_cnt					:integer 	:=0;
signal busy_i 					:std_logic:='0';
signal ped_sub_wr_busy 		:std_logic:='1';
signal navg_i					:std_logic_vector(3 downto 0):="0000";
signal reset_i					:std_logic_vector(1 downto 0):="00";
signal ncnt						:unsigned(7 downto 0):=x"00";
signal ncnt_i					:unsigned(7 downto 0):=x"00";-- decrement counter
signal ncnt_int				:unsigned(7 downto 0):=x"00";-- fixed
signal jdx_bram2tmp			:std_logic_vector(6 downto 0);
signal jdx_tmp2bram			:std_logic_vector(6 downto 0);
signal SMP_MAIN_CNT_i:std_logic_vector(8 downto 0);

signal ped_wr_start				:std_logic_vector(1 downto 0):="00";

--signal wea			: std_logic;
--signal wea_0			: std_logic_vector(0 downto 0):="0";

--signal dina			: STD_LOGIC_VECTOR(19 DOWNTO 0);
--signal doutb		: STD_LOGIC_VECTOR(19 DOWNTO 0);
--signal bram_addra	: std_logic_vector(10 downto 0);
--signal bram_addrb	: std_logic_vector(10 downto 0);
signal start_tmp2bram_xfer: std_logic:='0';
signal start_bram2tmp_xfer: std_logic:='0';

signal tmp2bram_ctr	: std_logic_vector(7 downto 0):=x"00";
signal bram2tmp_ctr	: std_logic_vector(7 downto 0):=x"00";

signal pedarray_tmp			: WaveWideTempArray;
signal pedarray_tmp2		: WaveWideTempArray;-- added for pipelining
signal dmx_wav				: WaveTempArray:=(x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");

signal dbg_tmp2:std_logic:='0';


type dmx_state is -- demux state
(
idle, -- waits for a trigger signal- basically idles. if this is the first trigger then automatically resets internal buffer 
peds_wait_allwin_done,
peds_write,
pedswrpedaddr1,
pedswrpedaddr2,
pedswrpedaddr3,
PedsWRPedVal_RDtmp1,
PedsWRPedVal_RDtmp1wait,
PedsWRPedVal_RDtmp2,
PedsWRPedVal_RDtmp3,
PedsWRPedVal_RDtmp3wait,
PedsWRPedVal_RDtmp4,
PedsWRPedVal,
PedsWRPedVal2,
PedsWRPedValWaitSRAM1,
PedsWRPedValWaitSRAM2,
PedsWRPedValWaitSRAM3,
PedsWRCheckSample,
PedsWRCheckWin,
PedsWRCheckCH,
PedsWRDone
);
signal dmx_st					: dmx_state := idle;



begin



  -- The following code must appear in the VHDL architecture header:


-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
--u_pedarr : blkmem_pedcalc_tmp
--  PORT MAP (
--    clka => clk,
--    wea => wea_0,
--    addra => bram_addra,
--    dina => dina(19 DOWNTO 0),
--    clkb => clk,
--    addrb => bram_addrb,
--    doutb => doutb(19 DOWNTO 0)
--  );
-- INST_TAG_END ------ End INSTANTIATION Template ------------

-- You must compile the wrapper file blk_mem_gen_v7_3.vhd when simulating
-- the core, blk_mem_gen_v7_3. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

	Inst_PedRAMaccess: PedRAMaccess PORT MAP(
		clk => clk,
		addr => ped_sa_num,
		rval0 => open,
		rval1 => open,
		wval0 => ped_sa_wval0,
		wval1 => ped_sa_wval1,
		rw => '1',-- write only
		update => ped_sa_update,
		busy => ped_sa_busy,
		ram_addr => ram_addr,
		ram_datar =>"00000000",
		ram_dataw => ram_data,--"00000000",
		ram_rw => open,--'0',
		ram_update => ram_update,
		ram_busy => ram_busy
	);


ncnt	<= x"01" when navg_i=x"0" else
			x"02" when navg_i=x"1" else
			x"04" when navg_i=x"2" else
			x"08" when navg_i=x"3" else
			x"10" when navg_i=x"4" else
			x"20" when navg_i=x"5" else
			x"40" when navg_i=x"6" else
			x"80" when navg_i=x"7" else
			x"00";

latch_inputs: process(clk)
begin
--wea_0<=wea;
busy<=busy_i;


	if (rising_edge(clk)) then

niter(7 downto 0)<=std_logic_vector(ncnt_i);
niter(14 downto 8)<=std_logic_vector(ncnt_int(6 downto 0));
niter(15)<=dbg_tmp2;

	navg_i<=navg;

	reset_i(1)<=reset_i(0);
	reset_i(0)<=reset;

	fifo_en_i<=fifo_en;
	fifo_din_i<=fifo_din;
	enable_i<=enable;
	
	trigin_i(1)<=trigin_i(0);
	trigin_i(0)<=trigin;

	-- give it enough time till the win addr and other information become available

	if (trigin_i(1 downto 0) = "01") then
		SMP_MAIN_CNT_i<=SMP_MAIN_CNT;
	end if;

	
	if (trigin_i="01") then
		asic_no_i<=to_integer(unsigned(asic_no));
		win_addr_start_i<=to_integer(unsigned(win_addr_start));
--		ncnt(conv_integer(unsigned(navg)))<='1';
		dmx_asic<=to_integer(unsigned(asic_no));
	end if;
	

	end if;-- rising_edge

end process;


parse_inpur_packet: process (clk)
begin
if (rising_edge(clk)) then


end if;

end process;






process(clk) -- pedestal wr
begin

if (rising_edge(clk)) then

	--start_ped_sub<='0';
	


	ped_wr_start(1)<=ped_wr_start(0);
	ped_wr_start(0)<=dmx_allwin_done;
	


	
case dmx_st is

	when idle =>
	-- this reset needs more work
	bram_addrb<="00000000000";
	busy_i<='0';
--	if(reset_i="01") then -- force reset and then got to idle and wait for trigger
--		dmx_st<=idle;	
--	end if;
	if (trigin_i="01" and enable_i='1') then
		dmx_st<=peds_wait_allwin_done;
		busy_i<='1';

		else 
		dmx_st<=idle;	
	end if;

	When peds_wait_allwin_done =>

	if (reset_i="01") then
		dmx_st<=idle;
	else 	
		if (ped_wr_start="01" ) then
			dmx_st<=peds_write;
			else 
			dmx_st<=peds_wait_allwin_done;
		end if;
	end if;

		
	When peds_write =>
	if (enable_i='1') then
		ped_asic<=dmx_asic-1;
		ped_ch  <=0;
		ped_win <=0;
		ped_sa  <=0;
		dmx_st<=PedsWRPedAddr1;
	else 
		dmx_st<=idle;
	end if ;

	When PedsWRPedAddr1 =>
		ped_sub_wr_busy<='1';
		ped_sa_num(21 downto 18)<=std_logic_vector(to_unsigned(dmx_asic-1,4));--		: std_logic_vector(21 downto 0);
		ped_sa_num(17 downto 14)<=std_logic_vector(to_unsigned(ped_ch,4));--		: std_logic_vector(21 downto 0);
		ped_sa_num(13 downto 5) <=std_logic_vector(to_unsigned(ped_win+win_addr_start_i,9));
		ped_sa_num(4  downto 0) <=std_logic_vector(to_unsigned(ped_sa,5));
		dmx_st<=PedsWRPedAddr2;	
	
	When PedsWRPedAddr2 =>
		ped_arr_addr<=ped_sa_num(17 downto 14) & std_logic_vector(to_unsigned(ped_win,2)) & ped_sa_num(4 downto 0);
		dmx_st<=PedsWRPedAddr3;	

	When PedsWRPedAddr3 =>
		ped_arr_addr0_int<=  to_integer(unsigned(ped_arr_addr));
		ped_arr_addr1_int<=1+to_integer(unsigned(ped_arr_addr));
		dmx_st<=PedsWRPedVal_RDtmp1;
		
	when PedsWRPedVal_RDtmp1=>
		bram_addrb<=ped_arr_addr;
		dmx_st<=PedsWRPedVal_RDtmp1wait;

	when PedsWRPedVal_RDtmp1wait=>
		dmx_st<=PedsWRPedVal_RDtmp2;
	
	when PedsWRPedVal_RDtmp2=>
		ped_sa_wval0<=bram_doutb((11+to_integer(unsigned(navg_i))) downto (0+to_integer(unsigned(navg_i))));
		dmx_st<=PedsWRPedVal_RDtmp3;

	when PedsWRPedVal_RDtmp3=>
		bram_addrb<=std_logic_vector(to_unsigned(ped_arr_addr1_int,11));
		dmx_st<=PedsWRPedVal_RDtmp3wait;
	
	when PedsWRPedVal_RDtmp3wait=>
		dmx_st<=PedsWRPedVal_RDtmp4;
	
	when PedsWRPedVal_RDtmp4=>
		ped_sa_wval1<=bram_doutb((11+to_integer(unsigned(navg_i))) downto (0+to_integer(unsigned(navg_i))));
		dmx_st<=PedsWRPedVal2;
				
	When PedsWRPedVal2 =>
		ped_sa_update<='1';
		dmx_st<=PedsWRPedValWaitSRAM1;

	When PedsWRPedValWaitSRAM1 =>
		--wait for ram_busy to come up
		dmx_st<=PedsWRPedValWaitSRAM2;

	When PedsWRPedValWaitSRAM2 =>
		--wait for ram_busy to come up
		dmx_st<=PedsWRPedValWaitSRAM3;

	When PedsWRPedValWaitSRAM3 =>
		ped_sa_update<='0';
		if (ped_sa_busy='1') then
				dmx_st<=PedsWRPedValWaitSRAM3;
		else
				ped_sa<=ped_sa+2;
				dmx_st<=PedsWRCheckSample;
		end if;

	When PedsWRCheckSample=>
			if (ped_sa<NSamplesPerWin) then
				dmx_st<=PedsWRPedAddr1;
			else
				ped_sa<=0;
				ped_win<=ped_win+1;
				dmx_st<=PedsWRCheckWin;
			end if;

	When PedsWRCheckWin=>
			if (ped_win<NWWin) then
				dmx_st<=PedsWRPedAddr1;
			else
				ped_win<=0;
				ped_ch<=ped_ch+1;
				dmx_st<=PedsWRCheckCH;
			end if;
	
	When PedsWRCheckCH=>
			if (ped_ch=NCHPerTX) then
				dmx_st<=PedsWRDone;
			else
				dmx_st<=PedsWRPedAddr1;
			end if;
					
	When PedsWRDone =>
		ped_sub_wr_busy<='0';
		--get ready for next round and go to idle- this will help avoiding having to push reset everytime
		ncnt_i	<=ncnt;
		ncnt_int	<=ncnt;
		dmx_st<=idle;--wait for trigger
	--done wring pedestals
	

	When others =>
		dmx_st<=idle;

	end case;
	
	end if;-- rising_edge of clk
	



end process;


end Behavioral;

