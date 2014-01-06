--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:47:43 03/28/2013
-- Design Name:   
-- Module Name:   C:/cygwin/home/Dr Kurtis/idlab-scrod/SCROD-boardstack/iTOP/IRS3B_CRT/src/asic_interfaces/simulation/ch_smpl_sel_test.vhd
-- Project Name:  scrod-boardstack-new-daq-interface
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: irs_readout_control_v4
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
 
ENTITY ch_smpl_sel_test IS
END ch_smpl_sel_test;
 
ARCHITECTURE behavior OF ch_smpl_sel_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT irs_readout_control_v4
    PORT(
         clk_i : IN  std_logic;
         clk_en : IN  std_logic;
         rst_i : IN  std_logic;
         start_i : IN  std_logic;
         increment : IN  std_logic;
         new_sample_address_reached : OUT  std_logic;
         sel_channel : IN  std_logic_vector(2 downto 0);
         DO_DIR : OUT  std_logic;
         DO_SIN : OUT  std_logic;
         DO_SCLK : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal clk_en : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal start_i : std_logic := '0';
   signal increment : std_logic := '0';
   signal sel_channel : std_logic_vector(2 downto 0) := (others => '0');

 	--Outputs
   signal new_sample_address_reached : std_logic;
   signal DO_DIR : std_logic;
   signal DO_SIN : std_logic;
   signal DO_SCLK : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: irs_readout_control_v4 PORT MAP (
          clk_i => clk_i,
          clk_en => clk_en,
          rst_i => rst_i,
          start_i => start_i,
          increment => increment,
          new_sample_address_reached => new_sample_address_reached,
          sel_channel => sel_channel,
          DO_DIR => DO_DIR,
          DO_SIN => DO_SIN,
          DO_SCLK => DO_SCLK
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 
	clk_en <= '1';
	sel_channel <= "110";
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_i_period*10;

		rst_i <= '1';
		wait for clk_i_period*2;
		rst_i <= '0';
		increment <= '1';
		wait for clk_i_period*2;
		start_i <= '1';

      -- insert stimulus here 

      wait;
   end process;

END;
