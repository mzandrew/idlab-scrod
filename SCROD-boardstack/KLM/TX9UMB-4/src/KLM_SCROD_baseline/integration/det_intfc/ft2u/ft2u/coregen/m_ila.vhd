--------------------------------------------------------------------------------
-- Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: M.81d
--  \   \         Application: netgen
--  /   /         Filename: m_ila.vhd
-- /___/   /\     Timestamp: Fri Jun 27 14:25:32 2014
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -w -sim -ofmt vhdl /home/usr/nakao/ise/ftsw3/ft2u/coregen/tmp/_cg/m_ila.ngc /home/usr/nakao/ise/ftsw3/ft2u/coregen/tmp/_cg/m_ila.vhd 
-- Device	: xc5vlx30-ff676-1
-- Input file	: /home/usr/nakao/ise/ftsw3/ft2u/coregen/tmp/_cg/m_ila.ngc
-- Output file	: /home/usr/nakao/ise/ftsw3/ft2u/coregen/tmp/_cg/m_ila.vhd
-- # of Entities	: 1
-- Design Name	: m_ila
-- Xilinx	: /home/xilinx/ise12.4/ISE/
--             
-- Purpose:    
--     This VHDL netlist is a verification model and uses simulation 
--     primitives which may not represent the true implementation of the 
--     device, however the netlist is functionally correct and should not 
--     be modified. This file cannot be synthesized and should only be used 
--     with supported simulation tools.
--             
-- Reference:  
--     Command Line Tools User Guide, Chapter 23
--     Synthesis and Simulation Design Guide, Chapter 6
--             
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity m_ila is
  port (
    CLK : in STD_LOGIC := 'X'; 
    CONTROL : inout STD_LOGIC_VECTOR ( 35 downto 0 ); 
    TRIG0 : in STD_LOGIC_VECTOR ( 95 downto 0 ) 
  );
end m_ila;

architecture STRUCTURE of m_ila is
begin
end STRUCTURE;
