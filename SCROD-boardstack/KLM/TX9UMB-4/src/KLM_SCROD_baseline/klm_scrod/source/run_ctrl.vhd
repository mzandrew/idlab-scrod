--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    06/09/2014
--
--*********************************************************************************
-- Description:
-- Run control interface.
--
-- Deficiencies/Issues
--
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_misc.all;
library work;
    use work.conc_intfc_pkg.all;

entity run_ctrl is
	port(
	clk					    : in std_logic;
    rx_dst_rdy_n            : out std_logic;
    rx_sof_n                : in std_logic;
    rx_eof_n                : in std_logic;
    rx_src_rdy_n            : in std_logic;
    rx_data                 : in std_logic_vector(15 downto 0);
    ctrl_regs               : out ctrl_reg_type);
end run_ctrl;


architecture behave of run_ctrl is

    signal intfc_bit        : std_logic;
    signal data_q0          : std_logic_vector(15 downto 0);
    signal data_q1          : std_logic_vector(15 downto 0);
	signal data_q2          : std_logic_vector(15 downto 0);

begin

---------------------------------------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------
-- Concurrent statements
---------------------------------------------------------------------------------------------------------


	-- Assertions ----------------------------------------------

	-----------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- Synchronous processes
---------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------
	-- Register the inputs and outputs to improve timing or adjust delays.
	--------------------------------------------------------------------------
    ctrl_pcs : process(clk)
    begin
        if (clk'event and clk = '1') then
            intfc_bit <= rx_sof_n xor rx_eof_n xor rx_src_rdy_n;
            data_q0 <= rx_data;
            data_q1 <= data_q0;
			data_q2 <= data_q1;
            rx_dst_rdy_n <= intfc_bit;
            ctrl_regs(0) <= data_q1;
            ctrl_regs(1) <= not data_q2;
    	end if;
    end process;

end behave;

