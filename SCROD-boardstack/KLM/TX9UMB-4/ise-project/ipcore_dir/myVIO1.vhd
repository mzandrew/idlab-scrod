-------------------------------------------------------------------------------
-- Copyright (c) 2015 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : myVIO1.vhd
-- /___/   /\     Timestamp  : Tue Jun 16 12:31:35 Eastern Daylight Time 2015
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY myVIO1 IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    ASYNC_IN: in std_logic_vector(47 downto 0);
    ASYNC_OUT: out std_logic_vector(47 downto 0));
END myVIO1;

ARCHITECTURE myVIO1_a OF myVIO1 IS
BEGIN

END myVIO1_a;
