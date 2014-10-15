----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:21:17 10/10/2014 
-- Design Name: 	Scheduler/ logical access channel for the CY62177EV30 SRAM chip
-- Module Name:    SRAMscheduler - Behavioral 
-- Project Name: KLM- 
-- Target Devices: SP6-SCROD rev A4, IDL_KLM_MB RevB (w SRAM on SCROD)
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

--package ram_scheduler_pkg is
--  type AddrArray is array (NRAMCH-1 downto 0) of std_logic_vector(21 downto 0);
--  type DataArray is array (NRAMCH-1 downto 0) of std_logic_vector(7 downto 0);
--  type QArray is array (NRAMCH-1 downto 0) of integer;
-- 
---- type AddrArray is array (NRAMCH-1 downto 0) of std_logic_vector(21 downto 0);
--end package;

entity SRAMscheduler is


Port ( 
			  
			  clk  : in std_logic;
						
			  Ain 	: in AddrArray;
			  DWin 	: in DataArray;
			  DRout 	 	: out DataArray;
			  rw   	: in std_logic_vector(NRAMCH-1 downto 0); --'0' = read, '1' = write
			  update_req : in std_logic_vector(NRAMCH-1 downto 0); --'0'= do nothing, edge to '1' means start either a read or write opertion
			  busy 	: out std_logic_vector(NRAMCH-1 downto 0);
						  
			--Controls to the SRAM, the scheduler will control who has access to the RAM using a multiplexer  
			  A : out  STD_LOGIC_VECTOR (21 downto 0);
           IO : inout  STD_LOGIC_VECTOR (7 downto 0);
           WEb : out  STD_LOGIC;
           CE2 : out  STD_LOGIC;
           CE1b : out  STD_LOGIC;
           OEb : out  STD_LOGIC
			  
			  );
			  
end SRAMscheduler;

architecture Behavioral of SRAMscheduler is

signal busy_i: std_logic_vector(NRAMCH-1 downto 0);
signal update_req_i1: std_logic_vector(NRAMCH-1 downto 0);
signal update_req_i0: std_logic_vector(NRAMCH-1 downto 0);
signal ram_wait_i: std_logic_vector(NRAMCH-1 downto 0);
signal queue_i		: QArray;
signal nap : integer :=0; 
signal curr_ch : integer :=0;
signal update_req_edg : std_logic_vector(NRAMCH-1 downto 0);
signal update_req_edg_new : std_logic;

signal A_i :  AddrArray;
signal IO_i : DataArray;
signal WEb_i	: STD_LOGIC_vector(NRAMCH-1 downto 0);
signal CE2_i	: std_logic_vector(NRAMCH-1 downto 0);
signal CE1b_i	: std_logic_vector(NRAMCH-1 downto 0);
signal OEb_i	: std_logic_vector(NRAMCH-1 downto 0);


type state_type is
	(
	SrvQ,			-- Idling until there is a '1' edge in any update_req bit, during idle, monitor previous requests and service as needed
	CheckUpdate,	--Check the diff in update request bits and find the requesting channels and add to queue 
   QReq		  -- Queue the request if possible( the specific channel is not busy) and go to the Idle 
	);
	
signal sched_st	 : state_type:=SrvQ;


begin

u_ram_iface : for i in 0 to NRAMCH-1 generate
u_ri: entity work.SRAMiface2 port map
(
		clk => clk,
		addr => Ain(i),
		dw => DWin(i),
		dr => DRout(i),
		rw => rw(i),
		update => update_req_i0(i),
		busy => open,--busy_i(i),
		ram_busy => ram_wait_i(i),
		A => A_i(i),
		IO => IO_i(i),
		WEb => WEb_i(i),
		CE2 => CE2_i(i),
		CE1b => CE1b_i(i),
		OEb => OEb_i(i)
);

A<=A_i(i) when (curr_ch=i) else (others=>'0');--?
IO<=IO_i(i) when (curr_ch=i) else (others=>'0');--?
WEb<=WEb_i(i) when (curr_ch=i) else '0';--?
CE2<=CE2_i(i) when (curr_ch=i) else '0';--?
CE1b<=CE1b_i(i) when (curr_ch=i) else '1';--?
OEb<=OEb_i(i) when (curr_ch=i) else '0';--?
--update_req_edg_new <= update_req_edg_new or update_req_edg(i);

end generate;
update_req_edg_new <= update_req_edg(0) or update_req_edg(1) or update_req_edg(2) or update_req_edg(3) ;


process (clk)
begin
if (rising_edge(clk)) then
--latch signals
update_req_i1<=update_req_i0;
update_req_i0<=update_req;

for i in 0 to NRAMCH-1 loop
	if (update_req_i1(i)='0' and update_req_i0(i)='1') then
	update_req_edg(i)<='1';
	else 
	update_req_edg(i)<='0';
	end if;
 

end loop;

end if;

end process;

process (clk)
begin
if (rising_edge(clk)) then
--
--basic idea: check the updat bits from all logical channels, which reflects the update requests. If there is a change in the update bit pattern
--then add that to the access queue for servicing
--
--
Case sched_st is
   
	When SrvQ =>
	-- code to service exiting queue
	
	if (update_req_edg_new='1') then 
		sched_st<=CheckUpdate;-- there are new update requests, so go and check them and add to queue
		else 
		sched_st<=SrvQ;  -- otherwise just service the queue
	end if;

	When CheckUpdate =>
	-- find the all the update requests and queue RAM access accordingly
	for i in 0 to NRAMCH-1 loop
	if (update_req_edg(i)='1' ) then
	-- add the ch of the requester to the 
	else 
	end if;
 

end loop;


	when others =>
			busy_i<=(others=>'0');
			sched_st<=SrvQ;
	end case;

end if;

end process;



end Behavioral;

