-------------------------------------------------------------------------------
-- Copyright (c) 2015 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : s6_vio.vhd
-- /___/   /\     Timestamp  : Fri Mar 27 14:51:33 Hawaiian Standard Time 2015
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY s6_vio IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    SYNC_IN: in std_logic_vector(63 downto 0);
    SYNC_OUT: out std_logic_vector(15 downto 0));
END s6_vio;

ARCHITECTURE s6_vio_a OF s6_vio IS
BEGIN

END s6_vio_a;
