--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:24:27 07/04/2011
-- Design Name:   
-- Module Name:   C:/cygwin/home/Dr Kurtis/idlab-scrod/iTOP-BLAB3A-boardstack/branches/pseudo-data_by_fiber/src/Data_Generator_Testbench.vhd
-- Project Name:  pseudo-data_by_fiber
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: data_generator
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
 
ENTITY Data_Generator_Testbench IS
END Data_Generator_Testbench;
 
ARCHITECTURE behavior OF Data_Generator_Testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT data_generator
    PORT(
         ENABLE : IN  std_logic;
         TX_DST_RDY_N : IN  std_logic;
         FIFO_DATA_COUNT : IN  std_logic_vector(9 downto 0);
         FIFO_EMPTY : IN  std_logic;
         USER_CLK : IN  std_logic;
         DATA_TO_FIFO : OUT  std_logic_vector(31 downto 0);
         WRITE_DATA_TO_FIFO : OUT  std_logic;
         TX_SRC_RDY_N : OUT  std_logic;
         READ_FROM_FIFO_ENABLE : OUT  std_logic;
         DATA_GENERATOR_STATE : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal ENABLE : std_logic := '1';
   signal TX_DST_RDY_N : std_logic := '0';
   signal FIFO_DATA_COUNT : std_logic_vector(9 downto 0) := (others => '0');
   signal FIFO_EMPTY : std_logic := '1';
   signal USER_CLK : std_logic := '0';

 	--Outputs
   signal DATA_TO_FIFO : std_logic_vector(31 downto 0);
   signal WRITE_DATA_TO_FIFO : std_logic;
   signal TX_SRC_RDY_N : std_logic;
   signal READ_FROM_FIFO_ENABLE : std_logic;
   signal DATA_GENERATOR_STATE : std_logic_vector(2 downto 0);

   -- Clock period definitions
   constant USER_CLK_period : time := 10 ns;
--   constant WRITE_DATA_TO_FIFO_CLK_period : time := 10 ns;
 
BEGIN
  
	-- Instantiate the Unit Under Test (UUT)
   uut: data_generator PORT MAP (
          ENABLE => ENABLE,
          TX_DST_RDY_N => TX_DST_RDY_N,
          FIFO_DATA_COUNT => FIFO_DATA_COUNT,
          FIFO_EMPTY => FIFO_EMPTY,
          USER_CLK => USER_CLK,
          DATA_TO_FIFO => DATA_TO_FIFO,
          WRITE_DATA_TO_FIFO => WRITE_DATA_TO_FIFO,
          TX_SRC_RDY_N => TX_SRC_RDY_N,
          READ_FROM_FIFO_ENABLE => READ_FROM_FIFO_ENABLE,
          DATA_GENERATOR_STATE => DATA_GENERATOR_STATE
        );

   -- Clock process definitions
   USER_CLK_process :process
   begin
		USER_CLK <= '0';
		wait for USER_CLK_period/2;
		USER_CLK <= '1';
		wait for USER_CLK_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		ENABLE <= '0';
      TX_DST_RDY_N <= '1';
      FIFO_DATA_COUNT <= (others => '0');
		FIFO_EMPTY <= '0';
      wait for 100 ns;	
		TX_DST_RDY_N <= '0';
		FIFO_DATA_COUNT <= (others => '0');
		FIFO_EMPTY <= '1';

      wait for USER_CLK_period*10;

			-- insert stimulus here 
			ENABLE <= '1';

      wait;
   end process;

END;
