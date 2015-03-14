--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    09/20/2011
--
--*********************************************************************************
-- Description:
-- Package for Belle-II TDC entity.
--
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
--	use ieee.std_logic_unsigned.all;
    use ieee.math_real.all;


package time_order_pkg is

    --------------------------------------------------------------------------
	-- Constant declarations.
    --------------------------------------------------------------------------
    constant TO_MAX_CHAN        : integer   := 150; -- scint channels
    constant TO_MAX_LANE        : integer   := 13; -- RPC lanes
    constant TO_DWIDTH          : integer   := 9;
    constant TO_CWIDTH          : integer   := 4+8; -- number of lanes + number of front-end channels
    constant TO_WIDTH           : integer   := TO_CWIDTH + TO_DWIDTH;
    constant TO_WRAP_BIT        : integer   := TO_DWIDTH-1;

    --------------------------------------------------------------------------
	-- Type declarations.
    --------------------------------------------------------------------------
    type aurora_data_type is array (natural range <>) of std_logic_vector(15 downto 0);    
    type trigger_data_type is array (natural range <>) of std_logic_vector(31 downto 0);    
    type to_mape_type is array (natural range <>) of std_logic;
    type to_mapc_type is array (natural range <>) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_mapd_type is array (natural range <>) of std_logic_vector(TO_DWIDTH-1 downto 0);        
    
    type to_2e_type is array (1 to 2) of std_logic;
    type to_2c_type is array (1 to 2) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_2d_type is array (1 to 2) of std_logic_vector(TO_DWIDTH-1 downto 0);
    type to_3e_type is array (1 to 3) of std_logic;
    type to_3c_type is array (1 to 3) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_3d_type is array (1 to 3) of std_logic_vector(TO_DWIDTH-1 downto 0);
    type to_4e_type is array (1 to 2) of to_2e_type;
    type to_4c_type is array (1 to 2) of to_2c_type;
    type to_4d_type is array (1 to 2) of to_2d_type;    
    type to_7e_type is array (1 to 7) of std_logic;
    type to_7c_type is array (1 to 7) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_7d_type is array (1 to 7) of std_logic_vector(TO_DWIDTH-1 downto 0);   
    type to_13e_type is array (1 to 13) of std_logic;
    type to_13c_type is array (1 to 13) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_13d_type is array (1 to 13) of std_logic_vector(TO_DWIDTH-1 downto 0);    

    --------------------------------------------------------------------------
	-- Function declarations.
    --------------------------------------------------------------------------
	-- Calculates the index for mapping signals to input ports
    function TO_CH_FUN(ch_offset : integer; size : integer) return std_logic_vector;
    function TO_CH2ONEHOT(addr : std_logic_vector; size : integer) return std_logic_vector;

end time_order_pkg;

--------------------------------------------------------------------------
-- Package body
--------------------------------------------------------------------------
package body time_order_pkg is

	---------------------------------------------------------
	-- Calculate TDC channel from entity offsets.
	--------------------------------------------------------
	function TO_CH_FUN(ch_offset : integer; size : integer) return std_logic_vector is
        variable temp       : unsigned(size-1 downto 0);
		variable outp       : std_logic_vector(size-1 downto 0);
	begin

        temp := TO_UNSIGNED(ch_offset,size);
        outp := STD_LOGIC_VECTOR(temp);

		return outp;
	end TO_CH_FUN;

	---------------------------------------------------------
	-- Generate a one-hot output from binary input
	--------------------------------------------------------
	function TO_CH2ONEHOT(addr : std_logic_vector; size : integer) return std_logic_vector is

		variable addr_i     : integer range 0 to size;
		variable outp       : std_logic_vector(1 to size);

	begin

        addr_i := TO_INTEGER(UNSIGNED(addr));
        outp := (others => '0');
        if addr_i > 0 then
            outp(addr_i) := '1';
        end if;

		return outp;
	end TO_CH2ONEHOT;

end time_order_pkg;


