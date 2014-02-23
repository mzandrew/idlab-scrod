-------------------------------------------------------------------------------
Library work;
use work.all;

Library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity SamplingLgc is
   port (
			clk		 			   : in    std_logic;  --expect input clock to be 8xSST
			start	 			      : in    std_logic;  -- start sampling, asserted once
			stop	 			      : in    std_logic;  -- hold operation
			IDLE_status				: out   std_logic := '1'; --sampling idle
			MAIN_CNT_out			: out   std_logic_vector(8 downto 0); --COL & ROW write address
			sspin_out            : out   std_logic; --SCA control signals
			sstin_out            : out   std_logic; --SCA control signals
			wr_advclk_out        : out   std_logic; --Write Address Increment Clock 
			wr_addrclr_out       : out   std_logic; --Clear Write Address Counter
			wr_strb_out          : out   std_logic; --Pulse to transfer samples to store
			wr_ena_out           : out   std_logic --Enable Write procedure
	);
end SamplingLgc;

architecture Behavioral of SamplingLgc is

--state machine drives sampling logic signals directly, loops between Sampling0-7 unless stopped
type state_type is
	(
	Idle,					--Initial State
	SamplingIdle,		-- Idling until command stop deasserted
	SamplingStart0,	--Sampling cycle start
	SamplingStart1,	
	SamplingStart2,	
	SamplingStart3,	
	SamplingStart4,	
	SamplingStart5,	
	SamplingStart6,	
	SamplingStart7,	
   Sampling0,			--start of normal sampling
   Sampling1,		
   Sampling2,		
	Sampling3,	  
	Sampling4,	  
	Sampling5,	  
	Sampling6,
	Sampling7,			--loops back to Sampling0 unless stop is high
	SamplingGoToIdle --Intermediate state between Sampling7 and SamplingIdle if stop
	);

	signal next_state		: state_type := Idle;
	
	--vector stores current write address
	signal MAIN_CNT		: UNSIGNED(8 downto 0) := "000000000";
	
	--output connecting signals
	signal sspin     : std_logic := '0'; --SCA control signals
	signal sstin     : std_logic := '0'; --SCA control signals
	signal wr_advclk : std_logic := '0'; --Write Address Increment Clock 
	signal wr_addrclr : std_logic := '1'; --Clear Write Address Counter
	signal wr_strb   : std_logic := '0'; --Pulse to transfer samples to store
	signal wr_ena    : std_logic := '0'; --Enable Write procedure

   --sampling module control signals
	signal start_in : std_logic := '0';
	signal stop_in : std_logic := '0';
--------------------------------------------------------------------------------
begin

--usual sampling signals
--MAIN_CNT_out <= MAIN_CNT; --output full counter
MAIN_CNT_out <= std_logic_vector(MAIN_CNT(8 downto 0)); --output only row + colum sections
sspin_out <= sspin;
sstin_out <= sstin;
wr_advclk_out <= wr_advclk;
wr_addrclr_out <= wr_addrclr;
wr_strb_out <= wr_strb;
wr_ena_out <= wr_ena;

--latch stop to local clock domain
process(clk)
begin
if (clk'event and clk = '1') then
	stop_in <= stop;
	start_in <= start;
end if;
end process;

--process(Clk,rst)
process(Clk)
begin
if (Clk'event and Clk = '1') then
  Case next_state is
  
  --stay Idle until start goes high, only needs to happen once
  When Idle =>
    MAIN_CNT <= (Others => '0');
    sspin          <= '0';
    sstin          <= '0';
    wr_advclk      <= '0';
	 wr_addrclr     <= '1';    
    wr_strb        <= '0';
	 wr_ena         <= '0';
	 IDLE_status 	 <= '1';
    if ( start_in = '1') then  --begin sampling
		next_state <= SamplingIdle;
    else								 --stay Idle
      next_state <= Idle;
    end if;

  --Sampling Idle state, stay here as long as stop signal is held high
  When SamplingIdle =>
    sspin          <= '0';
    sstin          <= '0';
    wr_advclk      <= '0';
	 wr_addrclr     <= '1';
    wr_strb        <= '0';
	 wr_ena         <= '0';
	 IDLE_status    <= '1';
    if ( stop_in = '0') then   --start normal sampling, reset MAIN_CNT
		MAIN_CNT     <= (Others => '0');
		next_state <= SamplingStart0;
    else								 --stay Idle until STOP goes low, keep MAIN_CNT constant
		MAIN_CNT     <= MAIN_CNT;
      next_state <= SamplingIdle;
    end if;
  
  --Beging preliminary sampling sequence
  When SamplingStart0 =>
    MAIN_CNT <= MAIN_CNT;
    sspin          <= '1';
    sstin          <= '0';
    wr_advclk      <= '0';    
	 wr_addrclr     <= '0';
	 wr_strb        <= '0';
	 wr_ena         <= '1';
	 IDLE_status    <= '0';
		next_state <= SamplingStart1;

  When SamplingStart1 =>
    MAIN_CNT <= MAIN_CNT;
    sspin          <= '1';
    sstin          <= '1';
    wr_advclk      <= '0';
    wr_addrclr     <= '0';
    wr_strb        <= '0';
    wr_ena         <= '1';
		next_state <= SamplingStart2;

  When SamplingStart2 =>   
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= SamplingStart3;	

  When SamplingStart3 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
		next_state 	<= SamplingStart4;	

  When SamplingStart4 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= SamplingStart5;

  When SamplingStart5 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= SamplingStart6;	
  
  When SamplingStart6 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= SamplingStart7;
  
  --end of preliminary sampling sequence, go to Sampling0 (start of normal sampling)
  When SamplingStart7 =>
    MAIN_CNT <= MAIN_CNT + 1;
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
		next_state <= Sampling0;

  --start of normal sampling, Sampling7 loops back here	 
  When Sampling0 =>
    MAIN_CNT <= MAIN_CNT;
    sspin          <= '1';
    sstin          <= '0';
    wr_advclk      <= '1';
	 wr_addrclr     <= '0';
	 wr_strb        <= '0';
    wr_ena         <= '1';
	 IDLE_status    <= '0';
		next_state <= Sampling1;

  When Sampling1 =>
    MAIN_CNT <= MAIN_CNT;
    sspin          <= '1';
    sstin          <= '1';
    wr_advclk      <= '0';
    wr_addrclr     <= '0';
    wr_strb        <= '0';
    wr_ena         <= '1';
		next_state <= Sampling2;

  When Sampling2 =>   
    MAIN_CNT <= MAIN_CNT ;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= Sampling3;	

  When Sampling3 =>
    MAIN_CNT <= MAIN_CNT + 1;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
		next_state 	<= Sampling4;	

  When Sampling4 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '1';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= Sampling5;

  When Sampling5 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= Sampling6;	
  
  When Sampling6 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
		next_state 	<= Sampling7;
  
  --loop back to Sampling0, allow stop signal to interrupt sampling
  When Sampling7 =>
    MAIN_CNT <= MAIN_CNT + 1;
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
	 if ( stop_in = '0') then  --normal sampling
		next_state <= Sampling0;
    else								--stop sampling and go to Idle state
      next_state <= SamplingGoToIdle;
    end if;
	 
  --If going to SamplingIdle, can hold signal high one additional clock cycle
  When SamplingGoToIdle =>
    MAIN_CNT <= MAIN_CNT;
    sspin          <= '0';
    sstin          <= '0';
    wr_advclk      <= '1';    
	 wr_addrclr     <= '0';
	 wr_strb        <= '0';
	 wr_ena         <= '1';
	 IDLE_status    <= '0';
      next_state <= SamplingIdle;
	 
  When Others =>
  MAIN_CNT <= (Others => '0');
  sspin             <= '0';
  sstin             <= '0';
  wr_advclk         <= '0';
  wr_addrclr        <= '1';
  wr_strb           <= '0';
  wr_ena            <= '0';
	next_state <= SamplingIdle;
  end Case;
end if;
end process;

end Behavioral;