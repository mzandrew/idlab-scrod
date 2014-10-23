----------------------------------------------------------------------------------
-- Company: UH Manoa - ID LAB
-- Engineer: Isar Mostafanezhad
-- 
-- Create Date:    13:06:51 10/16/2014 
-- Design Name:  WaveformDemuxPedsubDSP
-- Module Name:    WaveformDemuxPedsubDSP - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;


entity WaveformDemuxPedsubDSP is
port(
			clk		 			 : in   std_logic;
			--these two signals com form the ReadoutControl module and as soon as they are set and the SR Readout start is asserted, it goes and finds the proper pedestals from SRAM and populates buffer
			asic_no				 : in std_logic_vector(3 downto 0);
			win_addr_start		 : in std_logic_vector (8 downto 0);
			sr_start				 : in std_logic; -- comes from the readout control module
			
			--ped subtracted waveform FIFO:
			pswfifo_en 			:	out std_logic;
			pswfifo_clk 		: 	out std_logic;
			pswfifo_d 			: 	out std_logic_vector(31 downto 0);
			
			
			
			--waveform : 
			-- steal fifo signal from the srreadout module and demux 
		  fifo_en		 : in  std_logic;
		  fifo_clk		 : in  std_logic;
		  fifo_din		 : in  std_logic_vector(31 downto 0);
		  
		  -- Pedestal RAM Access: only for reading pedestals
		  ram_addr			: out std_logic_vector(21 downto 0);
		  ram_data			: in std_logic_vector(7 downto 0);
		  ram_update		: out std_logic;
		  ram_busy			: in std_logic


);

end WaveformDemuxPedsubDSP;

architecture Behavioral of WaveformDemuxPedsubDSP is

--Latch to clock or sr_start
signal asic_no_i			: integer;--std_logic_vector (3 downto 0);-- latched to sr_start
signal win_addr_start_i	: integer;--std_logic_vector (9 downto 0);
signal sr_start_i			: std_logic_vector(4 downto 0);
signal ped_fetch_start	: std_logic:='0';
signal ped_asic			: integer:=0;
signal ped_ch				: integer:=0;
signal ped_win				: integer:=0;
signal ped_sa				: integer:=0;
signal ped_hbyte			:std_logic_vector(7 downto 0);
signal ped_hbword			:integer:=0;
signal ped_word			:std_logic_vector(16 downto 0);
signal dmx_asic			:integer:=0;
signal dmx_win			:integer:=0;
signal dmx_ch			:integer:=0;
signal dmx_sa			:integer:=0;
signal dmx_bit			:integer:=0;
signal dmx_wav		: WaveTempArray;
signal fifo_din_i	: std_logic_vector(31 downto 0);
signal start_ped_sub	: std_logic :='0';
signal sa_cnt	: integer :=0;


signal waveform					: WaveformArray;--temp waveform array
signal pedarray					: WaveformArray;--temp pedestal array
signal wavepedsubarray			: WaveformArray;--temp pedestal array


type ped_state is --pedstals fetch state
(
PedsIdle,				  -- Idling until command start bit and store asic no and win addr no	
PedsFetchPedHiVal,
PedsFetchPedHiValWaitSRAM1,
PedsFetchPedHiValWaitSRAM2,
PedsFetchPedHiValWaitSRAM3,
PedsFetchPedLoVal,
PedsFetchPedLoValWaitSRAM1,
PedsFetchPedLoValWaitSRAM2,
PedsFetchPedLoValWaitSRAM3,
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
pedsub_sub
);
signal pedsub_st : pedsub_state:=pedsub_idle;

begin

pswfifo_clk<=clk;


process(clk)
begin

	if (rising_edge(clk)) then
	sr_start_i(4)<=sr_start_i(3);
	sr_start_i(3)<=sr_start_i(2);
	sr_start_i(2)<=sr_start_i(1);
	sr_start_i(1)<=sr_start_i(0);
	sr_start_i(0)<=sr_start;
	-- give it enough time till the win addr and other information become available
	
	if (sr_start_i="01111") then
		asic_no_i<=to_integer(unsigned(asic_no));
		win_addr_start_i<=to_integer(unsigned(win_addr_start));
		ped_fetch_start<='1';
	end if;
	

	end if;

end process;


process(clk) -- pedestal fetch
begin

if (rising_edge(clk)) then

	case next_ped_st is 

	When PedsIdle =>
	if (sr_start_i="01111") then
		ped_asic<=to_integer(unsigned(asic_no));
		ped_ch  <=0;
		ped_win <=0;
		ped_sa  <=0;
		next_ped_st<=PedsFetchPedHiVal;
	end if ;

	When PedsFetchPedHiVal =>
		--ram_addr<=std_logic_vector(to_unsigned((ped_win+to_integer(unsigned(win_addr_start_i))),22));--*(NSamplesPerWin+1)+ped_ch*(512*(NSamplesPerWin+1))+ped_asic*10*(512*(NSamplesPerWin+1));
		ram_addr<=std_logic_vector(to_unsigned((ped_win+win_addr_start_i)*(NSamplesPerWin+1)+ped_ch*(512*(NSamplesPerWin+1))+ped_asic*10*(512*(NSamplesPerWin+1)),22));
		--ram_addr<=std_logic_vector(to_unsigned(10,22));--*(NSamplesPerWin+1)+ped_ch*(512*(NSamplesPerWin+1))+ped_asic*10*(512*(NSamplesPerWin+1));
		ram_update<='1';
		next_ped_st<=PedsFetchPedHiValWaitSRAM1;
	
	When PedsFetchPedHiValWaitSRAM1 =>
		--wait for ram_busy to come up
		next_ped_st<=PedsFetchPedHiValWaitSRAM2;
	
	When PedsFetchPedHiValWaitSRAM2 =>
		next_ped_st<=PedsFetchPedHiValWaitSRAM3;
	
	When PedsFetchPedHiValWaitSRAM3 =>
		ram_update<='0';
		if (ram_busy='1') then
				next_ped_st<=PedsFetchPedHiValWaitSRAM3;
		else
				--keep the hi value
				ped_hbyte<=ram_data;
				ped_hbword<=to_integer(unsigned(ram_data))*256;
				next_ped_st<=PedsFetchPedLoVal;
		end if;

	When PedsFetchPedLoVal =>
		ram_addr<=std_logic_vector(to_unsigned(ped_sa+1+(ped_win+win_addr_start_i)*(NSamplesPerWin+1)+ped_ch*(512*(NSamplesPerWin+1))+ped_asic*10*(512*(NSamplesPerWin+1)),22));
		--ram_addr<=ped_sa+1+(ped_win+win_addr_start_i)*(NSamplesPerWin+1)+ped_ch*(512*(NSamplesPerWin+1))+ped_asic*NCHPerTX*(512*(NSamplesPerWin+1));
		ram_update<='1';
	next_ped_st<=PedsFetchPedLoValWaitSRAM1;
	
	When PedsFetchPedLoValWaitSRAM1 =>
		--wait for ram_busy to come up
		next_ped_st<=PedsFetchPedLoValWaitSRAM2;
	
	When PedsFetchPedLoValWaitSRAM2 =>
		next_ped_st<=PedsFetchPedLoValWaitSRAM3;
			
	When PedsFetchPedLoValWaitSRAM3 =>
		ram_update<='0';
		if (ram_busy='1') then
				next_ped_st<=PedsFetchPedLoValWaitSRAM3;
		else
				--Assemble the complete ped value and write to array 
				--pedarray(ped_sa+ped_win*NSamplesPerWin+ped_ch*NSamplesPerWin*NCHPerTX)<=to_integer(unsigned((ped_hbyte & ram_data)));
				pedarray(ped_sa+ped_win*NSamplesPerWin+ped_ch*NSamplesPerWin*NWWIN)<=ped_hbword+to_integer(signed((ram_data)));
				ped_sa<=ped_sa+1;
				next_ped_st<=PedsFetchCheckSample;
		end if;	
		
	When PedsFetchCheckSample=>
			if (ped_sa<NSamplesPerWin) then
				next_ped_st<=PedsFetchPedLoVal;
			else
				ped_sa<=0;
				ped_win<=ped_win+1;
				next_ped_st<=PedsFetchCheckWin;
			end if;

	When PedsFetchCheckWin=>
			if (ped_win<NWWin) then
				next_ped_st<=PedsFetchPedHiVal;
			else
				ped_win<=0;
				ped_ch<=ped_ch+1;
				next_ped_st<=PedsFetchCheckCH;
			end if;
	
	When PedsFetchCheckCH=>
			if (ped_ch<NCHPerTX) then
				next_ped_st<=PedsFetchPedHiVal;
			else
				next_ped_st<=PedsFetchDone;
			end if;
					
	When PedsFetchDone =>
		next_ped_st<=PedsIdle;
	--done Fetching pedestals
	

	When others =>
		next_ped_st<=PedsIdle;

	end case;


end if;


if (rising_edge(clk)) then

	start_ped_sub<='0';

	if (fifo_en='1') then-- data is coming, push into waveform memory
		fifo_din_i<=fifo_din;
					--dmx_win <=to_integer(unsigned(fifo_din(18 downto 10)))-win_addr_start_i;

		if    (fifo_din(31 downto 20)=x"ABC") then
			--(to_integer(unsigned(din(18 downto 10)))-win_addr_start_i)*NSamplesPerWin
			dmx_asic<=to_integer(unsigned(fifo_din(9 downto 6)));
			dmx_win <=to_integer(unsigned(fifo_din(18 downto 10)))-win_addr_start_i;
			dmx_sa  <=to_integer(unsigned(fifo_din(4 downto 0)));
			if (dmx_win=3) then -- this is the last window- start the ped subtraction
				start_ped_sub<='1';
			end if;
			
		elsif (fifo_din(31 downto 20)=x"DEF") then
			dmx_bit<=to_integer(unsigned(fifo_din(19 downto 16)));
			dmx_wav(0)(to_integer(unsigned(fifo_din(19 downto 16))))<=fifo_din(0);
			dmx_wav(1)(to_integer(unsigned(fifo_din(19 downto 16))))<=fifo_din(1);
			dmx_wav(2)(to_integer(unsigned(fifo_din(19 downto 16))))<=fifo_din(2);
			dmx_wav(3)(to_integer(unsigned(fifo_din(19 downto 16))))<=fifo_din(3);
			--add all 16 chnannels
		elsif (fifo_din(31 downto 0) = x"FACEFACE") then --end of window.
		
		else 
			--unknown package!
		
		end if;
	
		if (fifo_din_i(19 downto 16)="1011") then  -- this is the last sample
			waveform(dmx_sa+dmx_win*NSamplesPerWin+0*NSamplesPerWin*NWWIN)<=to_integer(unsigned(dmx_wav(0)));
			waveform(dmx_sa+dmx_win*NSamplesPerWin+1*NSamplesPerWin*NWWIN)<=to_integer(unsigned(dmx_wav(1)));
			waveform(dmx_sa+dmx_win*NSamplesPerWin+2*NSamplesPerWin*NWWIN)<=to_integer(unsigned(dmx_wav(2)));
			waveform(dmx_sa+dmx_win*NSamplesPerWin+3*NSamplesPerWin*NWWIN)<=to_integer(unsigned(dmx_wav(3)));
			--add all 16 chnannels
		
		end if;
	
	
	
	end if;
	
case pedsub_st is

When pedsub_idle =>
	if (start_ped_sub='1') then 
		sa_cnt<=0;
		pswfifo_en<='1';
		pedsub_st<=pedsub_sub;
	else 
	   pswfifo_en<='0';

		pedsub_st<=pedsub_idle;
	end if;

When pedsub_sub=>
		wavepedsubarray(sa_cnt)<=waveform(sa_cnt)-pedarray(sa_cnt);
--		wavepedsubarray(sa_cnt+1)<=waveformarray(sa_cnt+1)-pedarray(sa_cnt+1);
--		wavepedsubarray(sa_cnt+2)<=waveformarray(sa_cnt+2)-pedarray(sa_cnt+2);
--		wavepedsubarray(sa_cnt+3)<=waveformarray(sa_cnt+3)-pedarray(sa_cnt+3);
		pswfifo_d<=std_logic_vector(to_unsigned(sa_cnt,16)) & std_logic_vector(to_signed(wavepedsubarray(sa_cnt+0),16));
		sa_cnt<=sa_cnt+1;
		if (sa_cnt>NSamplesPerWin*NWWIN*16-2) then
				pedsub_st<=pedsub_idle;
				
		end if;

when others=>
		pedsub_st<=pedsub_idle;


end case;




--	case next_dmx_st is 
--
--	When DmxIdle =>
--	if (sr_start_i="01") then
--		dmx_asic<=to_integer(unsigned(asic_no));
--		dmx_ch  <=0;
--		dmx_win <=0;
--		dmx_sa  <=0;
--		dmx_bit <=0;
--		next_ped_st<=PedsFetchPedHiVal;
--	end if ;
--
--	When others =>
--
--	end case;


end if;

end process;






end Behavioral;

