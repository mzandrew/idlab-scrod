--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:38:18 08/16/2011
-- Design Name:   
-- Module Name:   C:/cygwin/home/Dr Kurtis/idlab-scrod/iTOP-BLAB3A-boardstack/branches/common_stop_with_FTSW_clocks/src/BLAB3_IRS2_Control/ASIC_control_testbench.vhd
-- Project Name:  SCROD_common_stop_with_FTSW_clocks
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: BLAB3_IRS2_MAIN
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
 
ENTITY ASIC_control_testbench IS
END ASIC_control_testbench;
 
ARCHITECTURE behavior OF ASIC_control_testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT BLAB3_IRS2_MAIN
    PORT(
         ASIC_CH_SEL : OUT  std_logic_vector(2 downto 0);
         ASIC_RD_ADDR : OUT  std_logic_vector(9 downto 0);
         ASIC_SMPL_SEL : OUT  std_logic_vector(5 downto 0);
         ASIC_SMPL_SEL_ALL : OUT  std_logic;
         ASIC_RD_ENA : OUT  std_logic;
         ASIC_RAMP : OUT  std_logic;
         ASIC_DAT : IN  std_logic_vector(11 downto 0);
         ASIC_TDC_START : OUT  std_logic;
         ASIC_TDC_CLR : OUT  std_logic;
         ASIC_WR_STRB : OUT  std_logic;
         ASIC_WR_ADDR : OUT  std_logic_vector(9 downto 0);
         ASIC_SSP_IN : OUT  std_logic;
         ASIC_SST_IN : OUT  std_logic;
         ASIC_SSP_OUT : IN  std_logic;
         ASIC_TRIGGER_BITS : IN  std_logic_vector(7 downto 0);
         SOFT_WRITE_ADDR : IN  std_logic_vector(8 downto 0);
         SOFT_READ_ADDR : IN  std_logic_vector(8 downto 0);
         USE_SOFT_READ_ADDR : IN  std_logic;
         CLK_SSP : IN  std_logic;
         CLK_SST : IN  std_logic;
         CLK_WRITE_STROBE : IN  std_logic;
         START_USB_XFER : OUT  std_logic;
         DONE_USB_XFER : IN  std_logic;
         MONITOR : OUT  std_logic_vector(15 downto 0);
         CLR_ALL : IN  std_logic;
         TRIGGER : IN  std_logic;
         RAM_READ_ADDRESS : IN  std_logic_vector(12 downto 0);
         RAM_READ_CLOCK : IN  std_logic;
         DATA_TO_USB : OUT  std_logic_vector(15 downto 0);
			USB_WRITE_BUSY: IN std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal ASIC_DAT : std_logic_vector(11 downto 0) := (others => '0');
   signal ASIC_SSP_OUT : std_logic := '0';
   signal ASIC_TRIGGER_BITS : std_logic_vector(7 downto 0) := (others => '0');
   signal SOFT_WRITE_ADDR : std_logic_vector(8 downto 0) := (others => '0');
   signal SOFT_READ_ADDR : std_logic_vector(8 downto 0) := (others => '0');
   signal USE_SOFT_READ_ADDR : std_logic := '0';
   signal CLK_SSP : std_logic := '0';
   signal CLK_SST : std_logic := '0';
   signal CLK_WRITE_STROBE : std_logic := '0';
   signal DONE_USB_XFER : std_logic := '0';
   signal CLR_ALL : std_logic := '0';
   signal TRIGGER : std_logic := '0';
   signal RAM_READ_ADDRESS : std_logic_vector(12 downto 0) := (others => '0');
   signal RAM_READ_CLOCK : std_logic := '0';
	signal USB_WRITE_BUSY : std_logic := '0';

 	--Outputs
   signal ASIC_CH_SEL : std_logic_vector(2 downto 0);
   signal ASIC_RD_ADDR : std_logic_vector(9 downto 0);
   signal ASIC_SMPL_SEL : std_logic_vector(5 downto 0);
   signal ASIC_SMPL_SEL_ALL : std_logic;
   signal ASIC_RD_ENA : std_logic;
   signal ASIC_RAMP : std_logic;
   signal ASIC_TDC_START : std_logic;
   signal ASIC_TDC_CLR : std_logic;
   signal ASIC_WR_STRB : std_logic;
   signal ASIC_WR_ADDR : std_logic_vector(9 downto 0);
   signal ASIC_SSP_IN : std_logic;
   signal ASIC_SST_IN : std_logic;
   signal START_USB_XFER : std_logic;
   signal MONITOR : std_logic_vector(15 downto 0);
   signal DATA_TO_USB : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant CLK_SSP_period : time := 10 ns;
   constant CLK_SST_period : time := 10 ns;
   constant CLK_WRITE_STROBE_period : time := 10 ns;
   constant RAM_READ_CLOCK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: BLAB3_IRS2_MAIN PORT MAP (
          ASIC_CH_SEL => ASIC_CH_SEL,
          ASIC_RD_ADDR => ASIC_RD_ADDR,
          ASIC_SMPL_SEL => ASIC_SMPL_SEL,
          ASIC_SMPL_SEL_ALL => ASIC_SMPL_SEL_ALL,
          ASIC_RD_ENA => ASIC_RD_ENA,
          ASIC_RAMP => ASIC_RAMP,
          ASIC_DAT => ASIC_DAT,
          ASIC_TDC_START => ASIC_TDC_START,
          ASIC_TDC_CLR => ASIC_TDC_CLR,
          ASIC_WR_STRB => ASIC_WR_STRB,
          ASIC_WR_ADDR => ASIC_WR_ADDR,
          ASIC_SSP_IN => ASIC_SSP_IN,
          ASIC_SST_IN => ASIC_SST_IN,
          ASIC_SSP_OUT => ASIC_SSP_OUT,
          ASIC_TRIGGER_BITS => ASIC_TRIGGER_BITS,
          SOFT_WRITE_ADDR => SOFT_WRITE_ADDR,
          SOFT_READ_ADDR => SOFT_READ_ADDR,
          USE_SOFT_READ_ADDR => USE_SOFT_READ_ADDR,
          CLK_SSP => CLK_SSP,
          CLK_SST => CLK_SST,
          CLK_WRITE_STROBE => CLK_WRITE_STROBE,
          START_USB_XFER => START_USB_XFER,
          DONE_USB_XFER => DONE_USB_XFER,
          MONITOR => MONITOR,
          CLR_ALL => CLR_ALL,
          TRIGGER => TRIGGER,
          RAM_READ_ADDRESS => RAM_READ_ADDRESS,
          RAM_READ_CLOCK => RAM_READ_CLOCK,
          DATA_TO_USB => DATA_TO_USB,
			 USB_WRITE_BUSY => USB_WRITE_BUSY
        );

   -- Clock process definitions
   CLK_SSP_process :process
   begin
		CLK_SSP <= '0';
		wait for CLK_SSP_period/2;
		CLK_SSP <= '1';
		wait for CLK_SSP_period/2;
   end process;
 
   CLK_SST_process :process
   begin
		CLK_SST <= '0';
		wait for CLK_SST_period/2;
		CLK_SST <= '1';
		wait for CLK_SST_period/2;
   end process;
 
   CLK_WRITE_STROBE_process :process
   begin
		CLK_WRITE_STROBE <= '0';
		wait for CLK_WRITE_STROBE_period/2;
		CLK_WRITE_STROBE <= '1';
		wait for CLK_WRITE_STROBE_period/2;
   end process;
 
   RAM_READ_CLOCK_process :process
   begin
		RAM_READ_CLOCK <= '0';
		wait for RAM_READ_CLOCK_period/2;
		RAM_READ_CLOCK <= '1';
		wait for RAM_READ_CLOCK_period/2;
   end process;
 
 USE_SOFT_READ_ADDR <= '0';
 TRIGGER <= '1';

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_SSP_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
