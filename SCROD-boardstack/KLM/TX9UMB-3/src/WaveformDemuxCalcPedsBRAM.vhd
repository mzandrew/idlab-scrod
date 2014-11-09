----------------------------------------------------------------------------------
-- Company: UH Manoa - ID LAB
-- Engineer: Isar Mostafanezhad
-- 
-- Create Date:    13:06:51 10/16/2014 
-- Design Name:  WaveformDemuxCalcPedsBRAM
-- Module Name:    WaveformDemuxCalcPedsBRAM - Behavioral 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;
 
-- this will creat pedestals for 4 consequetive windows starting with win_addr_start
entity WaveformDemuxCalcPedsBRAM is
port(
			clk		 			 : in   std_logic;
			reset					 : in std_logic; -- resets the waveform buffer in memory and the counter 
			enable				 : in std_logic; -- '0'= disable, '1'= enable
			navg					 : in std_logic_vector(3 downto 0);-- 2**navg= number of reads to average.
			--these 3 signals com form the ReadoutControl module and as soon as they are set and the SR Readout start is asserted, it goes and finds the proper pedestals from SRAM and populates buffer
			asic_no				 : in std_logic_vector(3 downto 0);
			win_addr_start		 : in std_logic_vector (8 downto 0);-- start of a 4 window sequence of samples
			trigin				 : in std_logic; -- comes from the readout control module- hooked to the trigger
			busy					 : out std_logic;
			
			--waveform : 
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

end WaveformDemuxCalcPedsBRAM;

architecture Behavioral of WaveformDemuxCalcPedsBRAM is
------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT blk_mem_gen_v7_3
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------


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
signal trigin_i			: std_logic_vector(4 downto 0);
--signal ped_sa_num_i		: std_logic_vector(21 downto 0);
signal ped_sa_wval0		: std_logic_vector(11 downto 0);
signal ped_sa_wval1		: std_logic_vector(11 downto 0);
signal ped_sa_wval0_tmp		: std_logic_vector(11 downto 0);
signal ped_sa_wval1_tmp		: std_logic_vector(11 downto 0);
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
signal fifo_din_i				: std_logic_vector(31 downto 0);
signal start_ped_sub			: std_logic :='0';
signal sa_cnt					: integer 	:=0;
signal busy_i 		: std_logic:='0';
signal ped_sub_wr_busy 	: std_logic:='1';
signal navg_i					: std_logic_vector(3 downto 0):="0000";
signal reset_i					:std_logic_vector(1 downto 0):="00";
signal ncnt						:std_logic_vector(15 downto 0):=x"0000";
signal ncnt_i					:integer :=0;-- decrement counter
signal ncnt_int				:integer :=0;-- fixed
signal clr_idx					:integer:=0;
signal jdx						: JDXTempArray;
signal jdx2						: JDXTempArray;


--signal wea			: std_logic;
signal wea_0			: std_logic_vector(0 downto 0):="0";

signal dina			: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal doutb		: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal bram_addra	: std_logic_vector(10 downto 0);
signal bram_addrb	: std_logic_vector(10 downto 0);

signal bram2tmp_ctr	: integer:=0;
signal tmp2bram_ctr	: integer:=0;

signal pedarray_tmp				: WaveTempArray;
signal pedarray_tmp2				: WaveTempArray;-- added for pipelining
signal dmx_wav					: WaveTempArray:=(x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000",x"0000");

type dmx_state is -- demux state
(
dmx_reset2,
dmx_reset3,
idle, -- waits for a trigger signal- basically idles. if this is the first trigger then automatically resets internal buffer 
demuxing,
dmx_wait_tmp2bram,
peds_write,
pedswrpedaddr1,
pedswrpedaddr2,
pedswrpedaddr3,
PedsWRPedVal_RDtmp1,
PedsWRPedVal_RDtmp2,
PedsWRPedVal_RDtmp3,
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

type bram2tmp_state is
(
st_bram2tmp_check_ctr,
--st_bram2tmp_fetch1,
st_bram2tmp_fetch2
);

signal st_bram2tmp				: bram2tmp_state:=st_bram2tmp_check_ctr;

type tmp_to_bram_state is
(
st_tmp2bram_check_ctr,
--st_tmp2bram_fetch1,
st_tmp2bram_fetch2
);

signal st_tmp2bram				: tmp_to_bram_state:=st_tmp2bram_check_ctr;

begin


  -- The following code must appear in the VHDL architecture header:


-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
u_pedarr : blk_mem_gen_v7_3
  PORT MAP (
    clka => clk,
    wea => wea_0,
    addra => bram_addra,
    dina => dina,
    clkb => clk,
    addrb => bram_addrb,
    doutb => doutb
  );
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


latch_inputs: process(clk)
begin
--wea_0<=wea;
busy<=busy_i;

	if (rising_edge(clk)) then
	reset_i(1)<=reset_i(0);
	reset_i(0)<=reset;
	
	
	trigin_i(4)<=trigin_i(3);
	trigin_i(3)<=trigin_i(2);
	trigin_i(2)<=trigin_i(1);
	trigin_i(1)<=trigin_i(0);
	trigin_i(0)<=trigin;
	-- give it enough time till the win addr and other information become available
	
--	if (trigin_i="00001") then
--			ncnt<=x"0000";
--			navg_i<=navg;
--	end if;
--	
--	if (trigin_i="00111") then
--		ncnt(conv_integer(unsigned(navg_i)))<='1';
--	end if;

	
	if (trigin_i="01111") then
		asic_no_i<=conv_integer(unsigned(asic_no));
		win_addr_start_i<=conv_integer(unsigned(win_addr_start));
--		navg_i<=navg;
--		ncnt(conv_integer(unsigned(navg)))<='1';
		
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
	
	
case st_bram2tmp is-- this is a side working FSM just to fetch and fill the temp sample in the BRAM array

when st_bram2tmp_check_ctr =>
if (bram2tmp_ctr=0) then
st_bram2tmp<= st_bram2tmp_check_ctr;
else
-- make sure BRAM is connected to this then read from BRAM and fill temp array
bram2tmp_ctr<=bram2tmp_ctr-1;
bram_addrb<=jdx(bram2tmp_ctr-1);
wea_0<="0";
st_bram2tmp<= st_bram2tmp_fetch2;
end if;

when st_bram2tmp_fetch2 =>
pedarray_tmp(bram2tmp_ctr)<=doutb;
st_bram2tmp<=st_bram2tmp_check_ctr;
end case;


case st_tmp2bram is-- this is a side working FSM just to fetch and fill the temp sample in the BRAM array

when st_tmp2bram_check_ctr =>
if (tmp2bram_ctr=0) then
st_tmp2bram<= st_tmp2bram_check_ctr;
else
-- make sure BRAM is connected to this then read from temp array and fill BRAM
tmp2bram_ctr<=tmp2bram_ctr-1;
bram_addra<=jdx2(tmp2bram_ctr-1);
dina<=pedarray_tmp2(tmp2bram_ctr-1);
wea_0<="1";
st_tmp2bram<= st_tmp2bram_fetch2;
end if;


when st_tmp2bram_fetch2 =>
wea_0<="0";
st_tmp2bram<=st_tmp2bram_check_ctr;

-- put in different processes
end case;


	
case dmx_st is

when dmx_reset2 =>
		ncnt(conv_integer(unsigned(navg_i)))<='1';
		dmx_st<=dmx_reset3;
		
when dmx_reset3 =>
		ncnt_i<=conv_integer(unsigned(ncnt));
		ncnt_int<=conv_integer(unsigned(ncnt));
		dmx_st<=idle;	


when idle =>
-- this reset needs more work
busy_i<='0';
if(reset_i="01") then -- force reset and then got to idle and wait for trigger
			ncnt<=x"0000";
			navg_i<=navg;
			st_tmp2bram<=st_tmp2bram_check_ctr;
			st_bram2tmp<=st_bram2tmp_check_ctr;
			bram2tmp_ctr<=0;
			tmp2bram_ctr<=0;
			dmx_st<=dmx_reset2;	
			else
		if (trigin_i="01111" and enable='1') then-- we only care about the first trigger to get started
	dmx_st<=demuxing;
	else
	dmx_st<=idle;
	end if;	
			
	end if;
	
	
	
	

when demuxing =>
busy_i<='1';

	if (fifo_en='1' and enable='1') then-- data is coming, push into waveform memory
		fifo_din_i<=fifo_din;
	
	if (dmx_win=NWWIN-1 and fifo_din=x"FACEFACE") then-- this is the last window- set the flag
			ncnt_i<=ncnt_i-1;
		end if;
			
			
		if    (fifo_din(31 downto 20)=x"ABC") then
	
			dmx_asic<=conv_integer(unsigned(fifo_din(9 downto 6)));
			dmx_win <=conv_integer(unsigned(fifo_din(18 downto 10)))-win_addr_start_i;
			dmx_sa  <=conv_integer(unsigned(fifo_din(4 downto 0)));
			dmx2_sa<=fifo_din(4 downto 0);
			dmx2_win<=conv_std_logic_vector(conv_integer(unsigned(fifo_din(18 downto 10)))-win_addr_start_i,2);

		elsif (fifo_din(31 downto 20)=x"DEF") then-- reconstruct the sampels and demux
			
--			if (fifo_din(19 downto 16)="0000") then
--				dmx2_win<=conv_std_logic_vector(dmx_win,2);
--			end if;
			
			if (fifo_din(19 downto 16)="0000") then -- this is the first bit in the sequence, so prep the address and stuff
				jdx(0 )<=x"0" & dmx2_win & dmx2_sa;
				jdx(1 )<=x"1" & dmx2_win & dmx2_sa;
				jdx(2 )<=x"2" & dmx2_win & dmx2_sa;
				jdx(3 )<=x"3" & dmx2_win & dmx2_sa;
				jdx(4 )<=x"4" & dmx2_win & dmx2_sa;
				jdx(5 )<=x"5" & dmx2_win & dmx2_sa;
				jdx(6 )<=x"6" & dmx2_win & dmx2_sa;
				jdx(7 )<=x"7" & dmx2_win & dmx2_sa;
				jdx(8 )<=x"8" & dmx2_win & dmx2_sa;
				jdx(9 )<=x"9" & dmx2_win & dmx2_sa;
				jdx(10)<=x"A" & dmx2_win & dmx2_sa;
				jdx(11)<=x"B" & dmx2_win & dmx2_sa;
				jdx(12)<=x"C" & dmx2_win & dmx2_sa;
				jdx(13)<=x"D" & dmx2_win & dmx2_sa;
				jdx(14)<=x"E" & dmx2_win & dmx2_sa;
				jdx(15)<=x"F" & dmx2_win & dmx2_sa;
			end if;
			
			if (fifo_din(19 downto 16)="0011") then -- this is the first bit in the sequence, so prep the address and stuff
						bram2tmp_ctr<=16;-- this will fill the tmp2;
						jdx2<=jdx;
			end if;
					
			
			--dmx_bit<=conv_integer(unsigned(fifo_din(19 downto 16)));
			dmx_wav(0 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(0 );
			dmx_wav(1 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(1 );
			dmx_wav(2 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(2 );
			dmx_wav(3 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(3 );
			dmx_wav(4 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(4 );
			dmx_wav(5 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(5 );
			dmx_wav(6 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(6 );
			dmx_wav(7 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(7 );
			dmx_wav(8 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(8 );
			dmx_wav(9 )(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(9 );
			dmx_wav(10)(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(10);
			dmx_wav(11)(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(11);
			dmx_wav(12)(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(12);
			dmx_wav(13)(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(13);
			dmx_wav(14)(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(14);
			dmx_wav(15)(conv_integer(unsigned(fifo_din_i(19 downto 16))))<=fifo_din(15);

		
		elsif (fifo_din(31 downto 0) = x"FACEFACE") then --end of window.
		
		else 
			--unknown package!
		
		end if;
	
		if (fifo_din_i(19 downto 16)="1011") then  -- this is the last bit of the sample, add to averaging buffer		
			--however since last bit will not get through we have to manual stick it in- we are out of clock cycles here and data
			if (ncnt_i=ncnt_int) then 
			pedarray_tmp2((0 ))<=dmx_wav(0  );--+pedarray_tmp((0 ));
			pedarray_tmp2((1 ))<=dmx_wav(1  );--+pedarray_tmp((1 ));
			pedarray_tmp2((2 ))<=dmx_wav(2  );--+pedarray_tmp((2 ));
			pedarray_tmp2((3 ))<=dmx_wav(3  );--+pedarray_tmp((3 ));
			pedarray_tmp2((4 ))<=dmx_wav(4  );--+pedarray_tmp((4 ));
			pedarray_tmp2((5 ))<=dmx_wav(5  );--+pedarray_tmp((5 ));
			pedarray_tmp2((6 ))<=dmx_wav(6  );--+pedarray_tmp((6 ));
			pedarray_tmp2((7 ))<=dmx_wav(7  );--+pedarray_tmp((7 ));
			pedarray_tmp2((8 ))<=dmx_wav(8  );--+pedarray_tmp((8 ));
			pedarray_tmp2((9 ))<=dmx_wav(9  );--+pedarray_tmp((9 ));
			pedarray_tmp2((10))<=dmx_wav(10 );--+pedarray_tmp((10));
			pedarray_tmp2((11))<=dmx_wav(11 );--+pedarray_tmp((11));
			pedarray_tmp2((12))<=dmx_wav(12 );--+pedarray_tmp((12));
			pedarray_tmp2((13))<=dmx_wav(13 );--+pedarray_tmp((13));
			pedarray_tmp2((14))<=dmx_wav(14 );--+pedarray_tmp((14));
			pedarray_tmp2((15))<=dmx_wav(15 );--+pedarray_tmp((15));
			
			else 
			
			pedarray_tmp2((0 ))<=dmx_wav(0  )+pedarray_tmp((0 ));
			pedarray_tmp2((1 ))<=dmx_wav(1  )+pedarray_tmp((1 ));
			pedarray_tmp2((2 ))<=dmx_wav(2  )+pedarray_tmp((2 ));
			pedarray_tmp2((3 ))<=dmx_wav(3  )+pedarray_tmp((3 ));
			pedarray_tmp2((4 ))<=dmx_wav(4  )+pedarray_tmp((4 ));
			pedarray_tmp2((5 ))<=dmx_wav(5  )+pedarray_tmp((5 ));
			pedarray_tmp2((6 ))<=dmx_wav(6  )+pedarray_tmp((6 ));
			pedarray_tmp2((7 ))<=dmx_wav(7  )+pedarray_tmp((7 ));
			pedarray_tmp2((8 ))<=dmx_wav(8  )+pedarray_tmp((8 ));
			pedarray_tmp2((9 ))<=dmx_wav(9  )+pedarray_tmp((9 ));
			pedarray_tmp2((10))<=dmx_wav(10 )+pedarray_tmp((10));
			pedarray_tmp2((11))<=dmx_wav(11 )+pedarray_tmp((11));
			pedarray_tmp2((12))<=dmx_wav(12 )+pedarray_tmp((12));
			pedarray_tmp2((13))<=dmx_wav(13 )+pedarray_tmp((13));
			pedarray_tmp2((14))<=dmx_wav(14 )+pedarray_tmp((14));
			pedarray_tmp2((15))<=dmx_wav(15 )+pedarray_tmp((15));
		end if;
			tmp2bram_ctr<=16;
			end if;
		
	end if;
	
			if (ncnt_i=0) then-- this is the last window to be averaged, so start writing to ped ram
			dmx_st<=dmx_wait_tmp2bram;
			else 
				dmx_st<=demuxing;
			end if;	
		
		
--		if(reset_i="01") then 
--		clr_idx<=0;
--		dmx_st<=clear_array;
--		else
--			if (ncnt_i=0) then-- this is the last window to be averaged, so start writing to ped ram
--			dmx_st<=dmx_wait_tmp2bram;
--			--dmx_st<=peds_write;
--			else 
--				dmx_st<=demuxing;
--			end if;
--		end if;


   when 	dmx_wait_tmp2bram=>
		if (tmp2bram_ctr/=0) then 
			dmx_st<=dmx_wait_tmp2bram;
		else
			dmx_st<=peds_write;
		end if;
	


		
	When peds_write =>
	if (enable='1') then
		ped_asic<=dmx_asic-1;--asic_no_i;--conv_integer(unsigned(asic_no_i));
		ped_ch  <=0;
		ped_win <=0;
		ped_sa  <=0;
		dmx_st<=PedsWRPedAddr1;
		else 
		dmx_st<=idle;

	end if ;

	When PedsWRPedAddr1 =>
		ped_sub_wr_busy<='1';
		ped_sa_num(21 downto 18)<=conv_std_logic_vector(dmx_asic-1,4);--		: std_logic_vector(21 downto 0);
		ped_sa_num(17 downto 14)<=conv_std_logic_vector(ped_ch,4);--		: std_logic_vector(21 downto 0);
		ped_sa_num(13 downto 5) <=conv_std_logic_vector(ped_win+win_addr_start_i,9);
		ped_sa_num(4  downto 0) <=conv_std_logic_vector(ped_sa,5);
		dmx_st<=PedsWRPedAddr2;	
		
	
	When PedsWRPedAddr2 =>
		ped_arr_addr<=ped_sa_num(17 downto 14) & conv_std_logic_vector(ped_win,2) & ped_sa_num(4 downto 0);
		dmx_st<=PedsWRPedAddr3;	

	When PedsWRPedAddr3 =>
		ped_arr_addr0_int<=  conv_integer(unsigned(ped_arr_addr));
		ped_arr_addr1_int<=1+conv_integer(unsigned(ped_arr_addr));
		dmx_st<=PedsWRPedVal_RDtmp1;
		
	when PedsWRPedVal_RDtmp1=>
		bram_addrb<=ped_arr_addr;
		dmx_st<=PedsWRPedVal_RDtmp2;
	
	when PedsWRPedVal_RDtmp2=>
		ped_sa_wval0_tmp<=doutb(11+conv_integer(unsigned(navg_i)) downto 0+conv_integer(unsigned(navg_i)));
		dmx_st<=PedsWRPedVal_RDtmp3;

	when PedsWRPedVal_RDtmp3=>
		bram_addrb<=ped_arr_addr+1;
		dmx_st<=PedsWRPedVal_RDtmp4;
	
	when PedsWRPedVal_RDtmp4=>
		ped_sa_wval1_tmp<=doutb(11+conv_integer(unsigned(navg_i)) downto 0+conv_integer(unsigned(navg_i)));
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
		ncnt_i<=conv_integer(unsigned(ncnt));
		ncnt_int<=conv_integer(unsigned(ncnt));
		dmx_st<=idle;--wait for trigger
	--done wring pedestals
	

	When others =>
		dmx_st<=demuxing;

	end case;
	
	end if;-- rising_edge of clk
	



end process;


end Behavioral;

