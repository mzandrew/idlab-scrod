--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:18:16 07/04/2011
-- Design Name:   
-- Module Name:   C:/cygwin/home/Dr Kurtis/idlab-scrod/iTOP-BLAB3A-boardstack/branches/pseudo-data_by_fiber/src/Packet_Generator_Testbench.vhd
-- Project Name:  pseudo-data_by_fiber
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Packet_Generator
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
 
ENTITY Packet_Generator_Testbench IS
END Packet_Generator_Testbench;
 
ARCHITECTURE behavior OF Packet_Generator_Testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Packet_Generator
    PORT(
         TX_DST_RDY_N : IN  std_logic;
         USER_CLK : IN  std_logic;
         RESET : IN  std_logic;
         CHANNEL_UP : IN  std_logic;
         ENABLE : IN  std_logic_vector(1 downto 0);
         TX_SRC_RDY_N : OUT  std_logic;
         TX_D : OUT  std_logic_vector(31 downto 0);
         DATA_GENERATOR_STATE : OUT  std_logic_vector(2 downto 0);
			FIFO_EMPTY : OUT std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal TX_DST_RDY_N : std_logic := '0';
   signal USER_CLK : std_logic := '0';
   signal RESET : std_logic := '0';
   signal CHANNEL_UP : std_logic := '1';
   signal ENABLE : std_logic_vector(1 downto 0) := (others => '1');

 	--Outputs
   signal TX_SRC_RDY_N : std_logic;
   signal TX_D : std_logic_vector(31 downto 0);
   signal DATA_GENERATOR_STATE : std_logic_vector(2 downto 0);
	signal FIFO_EMPTY : std_logic;

   -- Clock period definitions
   constant USER_CLK_period : time := 12.8 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Packet_Generator PORT MAP (
          TX_DST_RDY_N => TX_DST_RDY_N,
          USER_CLK => USER_CLK,
          RESET => RESET,
          CHANNEL_UP => CHANNEL_UP,
          ENABLE => ENABLE,
          TX_SRC_RDY_N => TX_SRC_RDY_N,
          TX_D => TX_D,
          DATA_GENERATOR_STATE => DATA_GENERATOR_STATE,
			 FIFO_EMPTY => FIFO_EMPTY
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
      wait for 100 ns;	

      wait for USER_CLK_period*10;

      -- insert stimulus here 


      wait;
   end process;

END;
