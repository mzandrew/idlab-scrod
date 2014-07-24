--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    06/04/2014
--
--*********************************************************************************
-- Description:
--
-- Package for KLM SCROD high level constants and functions.
--
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;

package klm_scrod_pkg is
    --------------------------------------------------------------------------
    -- Constant declarations.
    --------------------------------------------------------------------------
    constant VERSION        : integer                           := 15;
    constant DEFADDR        : std_logic_vector(19 downto 0)     := x"00000";
    constant FLIPCLK        : std_logic                         := '0';
    constant FLIPTRG        : std_logic                         := '0';
    constant FLIPACK        : std_logic                         := '0';
    constant USEFIFO        : std_logic                         := '1';
    constant CLKDIV1        : integer range 1 to 72             := 3;
    constant CLKDIV2        : integer range 1 to 72             := 2;
    constant USEPLL         : std_logic                         := '1';
    constant USEICTRL       : std_logic                         := '1';
    constant NBITTIM        : integer range 1 to 32             := 32;
    constant NBITTAG        : integer range 4 to 32             := 32;
    constant NBITID         : integer range 4 to 32             := 16;
    constant B2LRATE        : integer                           := 4;  -- 127 Mbyte / s

end klm_scrod_pkg;

package body klm_scrod_pkg is

end klm_scrod_pkg;