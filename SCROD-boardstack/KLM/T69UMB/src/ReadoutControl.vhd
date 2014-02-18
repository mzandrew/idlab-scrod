----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:19:35 10/20/2012 
-- Design Name: 
-- Module Name:    ReadoutControl - Behavioral 
-- Project Name: 
-- Target Devices: 
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

Library work;
use work.all;
--use work.Target2Package.all;

Library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
--Library synplify;
--use synplify.attributes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ReadoutControl is
    Port ( clk : in  STD_LOGIC;
           trigger : in  STD_LOGIC;
			  trig_delay : in  STD_LOGIC_VECTOR(11 downto 0);
			  dig_offset : in  STD_LOGIC_VECTOR(8 downto 0);
			  SMP_MAIN_CNT : in STD_LOGIC_VECTOR(8 downto 0);
			  SMP_IDLE_status : in  STD_LOGIC;
			  DIG_IDLE_status : in  STD_LOGIC;
			  SROUT_IDLE_status : in  STD_LOGIC;
			  fifo_empty : in  STD_LOGIC;
			  EVTBUILD_DONE_SENDING_EVENT : in  STD_LOGIC;
			  READOUT_RESET  : in  STD_LOGIC;
			  busy_status : out STD_LOGIC;
           smp_stop : out  STD_LOGIC;
           dig_start : out  STD_LOGIC;
			  DIG_RD_ROWSEL_S : out STD_LOGIC_VECTOR(2 downto 0);
			  DIG_RD_COLSEL_S : out STD_LOGIC_VECTOR(5 downto 0);
           srout_start : out  STD_LOGIC;
			  EVTBUILD_start : out  STD_LOGIC;
			  EVTBUILD_MAKE_READY : out  STD_LOGIC
	  );
end ReadoutControl;

architecture Behavioral of ReadoutControl is

type trig_state_type is
	(
	Idle,
	WAIT_TRIG_DELAY,
	STOP_SAMPLING,
	WAIT_SAMPLING_IDLE,
	START_DIG,
	WAIT_DIGITIZATION_IDLE_LOW,
	WAIT_DIGITIZATION_IDLE_HIGH,
	WAIT_READOUT_RESET,
	START_SROUT,
	WAIT_SROUT_IDLE_LOW,
	WAIT_SROUT_IDLE_HIGH,
	START_EVTBUILD,
	WAIT_EVTBUILD_DONE,
	SET_EVTBUILD_MAKE_READY
	);
signal next_trig_state	: trig_state_type;

signal internal_trigger : std_logic := '0';
signal internal_trigger_reg : std_logic_vector(1 downto 0) := "00";
signal interal_start_readout : std_logic := '0';

signal INTERNAL_COUNTER : UNSIGNED(15 downto 0) :=  x"0000";

signal internal_SMP_MAIN_CNT : UNSIGNED(8 downto 0) := '0' & x"00";
signal internal_SMP_IDLE_status : std_logic := '0';
signal internal_DIG_IDLE_status : std_logic := '0';
signal internal_SROUT_IDLE_status : std_logic := '0';
signal internal_fifo_empty : std_logic := '0';
signal internal_EVTBUILD_DONE_SENDING_EVENT : std_logic := '0';
signal internal_READOUT_RESET : std_logic := '0';

signal internal_busy_status : std_logic := '0';
signal internal_smp_stop : std_logic := '0';
signal internal_dig_start : std_logic := '0';
signal internal_srout_start : std_logic := '0';
signal internal_EVTBUILD_start : std_logic := '0';
signal internal_EVTBUILD_MAKE_READY : std_logic := '0';

begin

busy_status <= internal_busy_status;
smp_stop <= internal_smp_stop;
dig_start <= internal_dig_start;
srout_start <= internal_srout_start;
EVTBUILD_start <= internal_EVTBUILD_start;
EVTBUILD_MAKE_READY <= internal_EVTBUILD_MAKE_READY;
DIG_RD_ROWSEL_S(2 downto 0) <= std_logic_vector(internal_SMP_MAIN_CNT(8 downto 6));
DIG_RD_COLSEL_S(5 downto 0) <= std_logic_vector(internal_SMP_MAIN_CNT(5 downto 0));

--latch trigger to local clock domain
process(clk)
begin
if (clk'event and clk = '1') then
	internal_trigger <= trigger;
	internal_SMP_IDLE_status <= SMP_IDLE_status;
	internal_DIG_IDLE_status <= DIG_IDLE_status;
	internal_SROUT_IDLE_status <= SROUT_IDLE_status;
	internal_fifo_empty <= fifo_empty;
	internal_EVTBUILD_DONE_SENDING_EVENT <= EVTBUILD_DONE_SENDING_EVENT;
	internal_READOUT_RESET <= READOUT_RESET;
end if;
end process;

--detect trigger rising edge
process(clk)
begin
if (clk'event and clk = '1') then
	internal_trigger_reg(1) <= internal_trigger_reg(0);
	internal_trigger_reg(0) <= internal_trigger;
end if;
end process;

--process governing trigger + sampling, stop_smp signal
process(clk)
begin
if (clk'event and clk = '1') then
	Case next_trig_state is
	
	--detect trigger word
	When Idle =>
		internal_busy_status <= '0';
		internal_smp_stop <= '0';
		internal_dig_start <= '0';
		internal_srout_start <= '0';
		internal_EVTBUILD_start <= '0';
		internal_EVTBUILD_MAKE_READY <= '0';
	--make sure readout isn't active when accepting a new trigger
	if( internal_trigger_reg = "01" AND internal_SMP_IDLE_status = '0' AND internal_DIG_IDLE_status = '1' 
		AND internal_SROUT_IDLE_status = '1' AND internal_fifo_empty = '1' AND internal_EVTBUILD_DONE_SENDING_EVENT = '0' ) then 
		next_trig_state <= WAIT_TRIG_DELAY;
		--latch the SMP_MAIN_CNT at time of trigger, include a configurable digitzation window offset
		internal_SMP_MAIN_CNT <= UNSIGNED(SMP_MAIN_CNT) + 10 - UNSIGNED(dig_offset);
		--internal_SMP_MAIN_CNT <= SMP_MAIN_CNT;
	else
		next_trig_state <= Idle;
	end if;
	
	--optionally delay sampling stop
	When WAIT_TRIG_DELAY =>
		internal_busy_status <= '1';
		if( UNSIGNED(trig_delay) > INTERNAL_COUNTER ) then 
			INTERNAL_COUNTER <= INTERNAL_COUNTER + 1;
			next_trig_state <= WAIT_TRIG_DELAY;
		else
			INTERNAL_COUNTER <= (Others => '0');
			next_trig_state <=STOP_SAMPLING;
		end if;
	
	--stop sampling
	When STOP_SAMPLING =>
		internal_smp_stop <= '1';
		internal_dig_start <= '0';
		internal_srout_start <= '0';
		internal_EVTBUILD_start <= '0';
		internal_EVTBUILD_MAKE_READY <= '0';
			next_trig_state <= WAIT_SAMPLING_IDLE;	

	--wait for sampling idle signal
	When WAIT_SAMPLING_IDLE =>
	if( internal_SMP_IDLE_status = '0' ) then 
		next_trig_state <= WAIT_SAMPLING_IDLE;
	else
		next_trig_state <= START_DIG;
	end if;	
	
	--wait until sampling unsuspended
	When START_DIG =>
		internal_smp_stop <= '1';
		internal_dig_start <= '1';
		internal_srout_start <= '0';
		internal_EVTBUILD_start <= '0';
		internal_EVTBUILD_MAKE_READY <= '0';
			next_trig_state <= WAIT_DIGITIZATION_IDLE_LOW;	
	
	--wait for digitization IDLE_status to go low, ie. digitization starts
	When WAIT_DIGITIZATION_IDLE_LOW =>
	if( internal_DIG_IDLE_status = '1' ) then 
		next_trig_state <= WAIT_DIGITIZATION_IDLE_LOW;
	else
		next_trig_state <= WAIT_DIGITIZATION_IDLE_HIGH;
	end if;
	
	--wait for digitization IDLE_status to go high, ie. digitization ends
	When WAIT_DIGITIZATION_IDLE_HIGH =>
	if( internal_DIG_IDLE_status = '0' ) then 
		next_trig_state <= WAIT_DIGITIZATION_IDLE_HIGH;
	else
		next_trig_state <= START_SROUT;
		--next_trig_state <= WAIT_READOUT_RESET;
	end if;
	
	--LOOP OVER ASIC SERIAL READOUT GOES HERE
	
	When START_SROUT =>
		internal_smp_stop <= '1';
		internal_dig_start <= '1'; --leave dig start signal high until end of process
		internal_srout_start <= '1';
		internal_EVTBUILD_start <= '0';
		internal_EVTBUILD_MAKE_READY <= '0';
			next_trig_state <= WAIT_SROUT_IDLE_LOW;
	
	--wait for serial readout IDLE_status to go low, ie. digitization starts
	When WAIT_SROUT_IDLE_LOW =>
	if( internal_SROUT_IDLE_status = '1' ) then 
		next_trig_state <= WAIT_SROUT_IDLE_LOW;
	else
		next_trig_state <= WAIT_SROUT_IDLE_HIGH;
	end if;
	
	--wait for digitization IDLE_status to go high, ie. digitization ends
	When WAIT_SROUT_IDLE_HIGH =>
	if( internal_SROUT_IDLE_status = '0' ) then 
		next_trig_state <= WAIT_SROUT_IDLE_HIGH;
	else
		next_trig_state <= START_EVTBUILD;
	end if;
	
	When START_EVTBUILD =>
		internal_smp_stop <= '1';
		internal_dig_start <= '1';
		internal_srout_start <= '1';
		internal_EVTBUILD_start <= '1';
		internal_EVTBUILD_MAKE_READY <= '0';
			next_trig_state <= WAIT_EVTBUILD_DONE;
			
	--wait for event builder to finish
	When WAIT_EVTBUILD_DONE =>
	if( internal_EVTBUILD_DONE_SENDING_EVENT = '0' ) then 
		next_trig_state <= WAIT_EVTBUILD_DONE;
	else
		next_trig_state <= SET_EVTBUILD_MAKE_READY;
	end if;
	
	--send MAKE_READY signal, hand shake for event builder finishing
	When SET_EVTBUILD_MAKE_READY =>
		internal_smp_stop <= '1';
		internal_dig_start <= '1';
		internal_srout_start <= '1';
		internal_EVTBUILD_start <= '1';
		internal_EVTBUILD_MAKE_READY <= '1';
			next_trig_state <= WAIT_READOUT_RESET;
			
	--wait for readout to be reset via command interpreter (prevents triggers while USB read out)
	When WAIT_READOUT_RESET =>
		internal_smp_stop <= '1'; --hold sampling, in principle allow testing different write addresses
		internal_dig_start <= '0';
		internal_srout_start <= '0';
		internal_EVTBUILD_start <= '0';
		internal_EVTBUILD_MAKE_READY <= '0';
	if( internal_READOUT_RESET = '0' ) then 
		next_trig_state <= WAIT_READOUT_RESET;
	else
		next_trig_state <= Idle;
	end if;
	
	When Others =>
		INTERNAL_COUNTER <= (Others => '0');
		internal_smp_stop <= '0';
		internal_dig_start <= '0';
		internal_srout_start <= '0';
		internal_EVTBUILD_start <= '0';
		internal_EVTBUILD_MAKE_READY <= '0';
		next_trig_state <= Idle;
	end Case;
	
end if;
end process;

end Behavioral;

