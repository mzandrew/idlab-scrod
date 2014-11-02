--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    09/26/2011
--
--*********************************************************************************
-- Description:
-- Generates free running counter that is written to a FIFO when discrimitor is
-- asserted.
--
--?? Must adjust TDC FIFO/Schedule FIFO prog empty/full flags because a pipeline register
-- was added to tdc_fifo_dout.
--*********************************************************************************

library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
library work;
   	use work.tdc_pkg.all;

entity tdc_out_regs is
port(
-- Inputs -----------------------------
    clk                   		    : in std_logic;
    ce                              : in std_logic_vector(1 to 2);
    fifo_ept_d              	    : in std_logic_vector(1 to TDC_NUM_CHAN/2);
    tdc_dout_d           	        : in tdc_hdout_type;
-- Outputs -----------------------------
    fifo_ept_q              	    : out std_logic_vector(1 to TDC_NUM_CHAN/2);
	tdc_dout_q           	        : out tdc_hdout_type);
end tdc_out_regs;


architecture behave of tdc_out_regs is


begin

----------------------------------------------------------------
-- Concurrent Statements
----------------------------------------------------------------

	-- Map signals to port -----------------------------------

    ----------------------------------------------------------

----------------------------------------------------------------
-- Synchronous processes
----------------------------------------------------------------

	-------------------------------------
	-- Clock enabled flip-flops
	-------------------------------------
    regs_pcs : process(clk)
    begin
        if (clk'event and clk = '1') then
            if ce(1) = '1' then
                fifo_ept_q(1 to 12) <= fifo_ept_d(1 to 12);
                tdc_dout_q(1 to 12) <= tdc_dout_d(1 to 12);
            end if;
            if ce(2) = '1' then
                fifo_ept_q(13 to 24) <= fifo_ept_d(13 to 24);
                tdc_dout_q(13 to 24) <= tdc_dout_d(13 to 24);
            end if;
        end if;
    end process;

end behave;
