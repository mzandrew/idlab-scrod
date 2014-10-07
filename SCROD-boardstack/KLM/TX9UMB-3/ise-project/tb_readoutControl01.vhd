--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:41:30 09/05/2014
-- Design Name:   
-- Module Name:   C:/Users/isar/Documents/code4/TX9UMB-2/ise-project/tb_readoutControl01.vhd
-- Project Name:  scrod-boardstack-new-daq-interface
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ReadoutControl
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_readoutControl01 IS
END tb_readoutControl01;
 
ARCHITECTURE behavior OF tb_readoutControl01 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ReadoutControl
    PORT(
         clk : IN  std_logic;
         smp_clk : IN  std_logic;
         trigger : IN  std_logic;
         trig_delay : IN  std_logic_vector(11 downto 0);
         dig_offset : IN  std_logic_vector(8 downto 0);
         win_num_to_read : IN  std_logic_vector(8 downto 0);
         asic_enable_bits : IN  std_logic_vector(9 downto 0);
         SMP_MAIN_CNT : IN  std_logic_vector(8 downto 0);
         SMP_IDLE_status : IN  std_logic;
         DIG_IDLE_status : IN  std_logic;
         SROUT_IDLE_status : IN  std_logic;
         fifo_empty : IN  std_logic;
         EVTBUILD_DONE_SENDING_EVENT : IN  std_logic;
         READOUT_RESET : IN  std_logic;
         READOUT_CONTINUE : IN  std_logic;
         RESET_EVENT_NUM : IN  std_logic;
         LATCH_SMP_MAIN_CNT : OUT  std_logic_vector(8 downto 0);
			dig_win_start : OUT  std_logic_vector(8 downto 0);
         LATCH_DONE : OUT  std_logic;
         ASIC_NUM : OUT  std_logic_vector(3 downto 0);
         busy_status : OUT  std_logic;
         smp_stop : OUT  std_logic;
         dig_start : OUT  std_logic;
         DIG_RD_ROWSEL_S : OUT  std_logic_vector(2 downto 0);
         DIG_RD_COLSEL_S : OUT  std_logic_vector(5 downto 0);
         srout_start : OUT  std_logic;
         EVTBUILD_start : OUT  std_logic;
         EVTBUILD_MAKE_READY : OUT  std_logic;
         EVENT_NUM : OUT  std_logic_vector(31 downto 0);
         READOUT_DONE : OUT  std_logic
        );
    END COMPONENT;
    
	
    COMPONENT DigitizingLgcTX
    PORT(
         clk : IN  std_logic;
         IDLE_status : OUT  std_logic;
         StartDig : IN  std_logic;
         ramp_length : IN  std_logic_vector(12 downto 0);
         rd_ena : OUT  std_logic;
         clr : OUT  std_logic;
         startramp : OUT  std_logic
        );
    END COMPONENT;
    
	 COMPONENT SerialDataRout
    PORT(
         clk : IN  std_logic;
         start : IN  std_logic;
         EVENT_NUM : IN  std_logic_vector(31 downto 0);
         WIN_ADDR : IN  std_logic_vector(8 downto 0);
         ASIC_NUM : IN  std_logic_vector(3 downto 0);
         IDLE_status : OUT  std_logic;
			force_test_pattern : in   std_logic;

         busy : OUT  std_logic;
         samp_done : OUT  std_logic;
         dout : IN  std_logic_vector(15 downto 0);
         sr_clr : OUT  std_logic;
         sr_clk : OUT  std_logic;
         sr_sel : OUT  std_logic;
         samplesel : OUT  std_logic_vector(4 downto 0);
         smplsi_any : OUT  std_logic;
         fifo_wr_en : OUT  std_logic;
         fifo_wr_clk : OUT  std_logic;
         fifo_wr_din : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    
	 COMPONENT SamplingLgc
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         dig_win_start : IN  std_logic_vector(8 downto 0);
         dig_win_n : IN  std_logic_vector(8 downto 0);
         dig_win_ena : IN  std_logic;
         MAIN_CNT_out : OUT  std_logic_vector(8 downto 0);
         sstin_out : OUT  std_logic;
         wr_addrclr_out : OUT  std_logic;
         wr1_ena : OUT  std_logic;
         wr2_ena : OUT  std_logic
        );
    END COMPONENT;


   --Inputs
   signal clk : std_logic := '0';
   signal smp_clk : std_logic := '0';
   signal trigger : std_logic := '0';
   signal trig_delay : std_logic_vector(11 downto 0) := (others => '0');
   signal dig_offset : std_logic_vector(8 downto 0) := "000110100";--(others => '0');
   signal win_num_to_read : std_logic_vector(8 downto 0) := "000001000";
   signal asic_enable_bits : std_logic_vector(9 downto 0) := "1000000000";
   signal SMP_MAIN_CNT : std_logic_vector(8 downto 0) := "001000000";
   signal SMP_IDLE_status : std_logic := '0';
   signal DIG_IDLE_status : std_logic := '1';
   signal SROUT_IDLE_status : std_logic := '1';
   signal fifo_empty : std_logic := '1';
   signal EVTBUILD_DONE_SENDING_EVENT : std_logic := '0';
   signal READOUT_RESET : std_logic := '0';
   signal READOUT_CONTINUE : std_logic := '0';
   signal RESET_EVENT_NUM : std_logic := '0';
	signal ramp_length : std_logic_vector(12 downto 0) := "0110100000000"; -- x"D00"
 --Inputs
  -- signal clk : std_logic := '0';
   signal start : std_logic := '0';
   signal EVENT_NUM : std_logic_vector(31 downto 0) := (others => '0');
   signal WIN_ADDR : std_logic_vector(8 downto 0) := (others => '0');
 --  signal ASIC_NUM : std_logic_vector(3 downto 0) := (others => '0');
   signal dout : std_logic_vector(15 downto 0) := (others => '0');

 	--Outputs
--   signal IDLE_status : std_logic;
   signal busy : std_logic;
   signal samp_done : std_logic;
   signal sr_clr : std_logic;
   signal sr_clk : std_logic;
   signal sr_sel : std_logic;
   signal samplesel : std_logic_vector(4 downto 0);
   signal smplsi_any : std_logic;
   signal fifo_wr_en : std_logic;
   signal fifo_wr_clk : std_logic;
   signal fifo_wr_din : std_logic_vector(31 downto 0);

 	--Outputs
   signal IDLE_status : std_logic;
   signal dig_rd_ena : std_logic;
   signal dig_clr : std_logic;
   signal dig_startramp : std_logic;
 	--Outputs
   signal LATCH_SMP_MAIN_CNT : std_logic_vector(8 downto 0);
	signal internal_READCTRL_dig_win_start : std_logic_vector(8 downto 0);
   signal LATCH_DONE : std_logic;
   signal ASIC_NUM : std_logic_vector(3 downto 0);
   signal busy_status : std_logic;
   signal smp_stop : std_logic;
   signal dig_start : std_logic;
   signal DIG_RD_ROWSEL_S : std_logic_vector(2 downto 0);
   signal DIG_RD_COLSEL_S : std_logic_vector(5 downto 0);
   signal srout_start : std_logic;
   signal EVTBUILD_start : std_logic;
   signal EVTBUILD_MAKE_READY : std_logic;
   --signal EVENT_NUM : std_logic_vector(31 downto 0);
   signal READOUT_DONE : std_logic;

  signal wr_addrclr_out : std_logic;
   signal wr1_ena : std_logic;
   signal wr2_ena : std_logic;
	signal smp_reset : std_logic;

   -- Clock period definitions
   constant clk_period : time := 16 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	 uut_samp: SamplingLgc PORT MAP (
          clk => clk,
          reset => smp_reset,
          dig_win_start => internal_READCTRL_dig_win_start,
          dig_win_n => win_num_to_read,
          dig_win_ena => not DIG_IDLE_status,--busy_status,
          MAIN_CNT_out => SMP_MAIN_CNT,
          sstin_out => smp_clk,
          wr_addrclr_out => wr_addrclr_out,
          wr1_ena => wr1_ena,
          wr2_ena => wr2_ena
        );
		  
   uut: ReadoutControl PORT MAP (
          clk => clk,
          smp_clk => smp_clk,
          trigger => trigger,
          trig_delay => trig_delay,
          dig_offset => dig_offset,
          win_num_to_read => win_num_to_read,
          asic_enable_bits => asic_enable_bits,
          SMP_MAIN_CNT => SMP_MAIN_CNT,
          SMP_IDLE_status => SMP_IDLE_status,
          DIG_IDLE_status => DIG_IDLE_status,
          SROUT_IDLE_status => SROUT_IDLE_status,
          fifo_empty => fifo_empty,
          EVTBUILD_DONE_SENDING_EVENT => EVTBUILD_DONE_SENDING_EVENT,
          READOUT_RESET => READOUT_RESET,
          READOUT_CONTINUE => READOUT_CONTINUE,
          RESET_EVENT_NUM => RESET_EVENT_NUM,
          LATCH_SMP_MAIN_CNT => LATCH_SMP_MAIN_CNT,
			 dig_win_start => internal_READCTRL_dig_win_start,
          LATCH_DONE => LATCH_DONE,
          ASIC_NUM => ASIC_NUM,
          busy_status => busy_status,
          smp_stop => smp_stop,
          dig_start => dig_start,
          DIG_RD_ROWSEL_S => DIG_RD_ROWSEL_S,
          DIG_RD_COLSEL_S => DIG_RD_COLSEL_S,
          srout_start => srout_start,
          EVTBUILD_start => EVTBUILD_start,
          EVTBUILD_MAKE_READY => EVTBUILD_MAKE_READY,
          EVENT_NUM => EVENT_NUM,
          READOUT_DONE => READOUT_DONE
        );
-- Instantiate the Unit Under Test (UUT)
   uut_dig: DigitizingLgcTX PORT MAP (
          clk => clk,
          IDLE_status => DIG_IDLE_status,
          StartDig => dig_start,
          ramp_length => ramp_length,
          rd_ena => dig_rd_ena,
          clr => dig_clr,
          startramp => dig_startramp
        );
		  
		   uut_serread: SerialDataRout PORT MAP (
          clk => clk,
          start => srout_start,
          EVENT_NUM => EVENT_NUM,
          WIN_ADDR => WIN_ADDR,
          ASIC_NUM => ASIC_NUM,
          IDLE_status => SROUT_IDLE_status,
			 force_test_pattern=>'0',
          busy => busy,
          samp_done => open,
          dout => dout,
          sr_clr => sr_clr,
          sr_clk => sr_clk,
          sr_sel => sr_sel,
          samplesel => samplesel,
          smplsi_any => smplsi_any,
          fifo_wr_en => fifo_wr_en,
          fifo_wr_clk => fifo_wr_clk,
          fifo_wr_din => fifo_wr_din
        );
		  
		  WIN_ADDR<=DIG_RD_COLSEL_S & DIG_RD_ROWSEL_S;
		  
   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		smp_reset<='1';
     wait for 100 ns;	
		smp_reset<='0';
    wait for 200 ns;	
		

      wait for clk_period*10;
	

	trigger<='1';
      -- insert stimulus here 
      wait for clk_period*20;
		--SROUT_IDLE_status<='1';
      wait for clk_period*20;
--		SROUT_IDLE_status<='0';
      wait for clk_period*20;
	--	SROUT_IDLE_status<='1';
		

      wait;
   end process;

END;
