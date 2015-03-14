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
    --constant TO_NUM_CHAN        : integer   := 2; -- tom_2_to_1_tb
    --constant TO_NUM_CHAN        : integer   := 12;-- tom_12_to_1_tb
    constant TO_NUM_CHAN        : integer   := 48;-- normal use
    constant TO_DWIDTH          : integer   := 9;
    constant TO_CWIDTH          : integer   := INTEGER(CEIL(LOG2(REAL(TO_NUM_CHAN))));
    constant TO_WIDTH           : integer   := TO_CWIDTH + TO_DWIDTH; -- add one for bootstrap
    constant TO_WRAP_BIT        : integer   := TO_DWIDTH-1;
    constant TO_RED_FAC         : integer   := 12;                                      -- reduction factor
    constant TO_RED_OUT         : integer   := TO_NUM_CHAN/TO_RED_FAC;                  -- number of outputs after reduced

    --------------------------------------------------------------------------
	-- Type declarations.
    --------------------------------------------------------------------------
    type to_2c_type is array (1 to 2) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_2d_type is array (1 to 2) of std_logic_vector(TO_DWIDTH-1 downto 0);
    type to_3c_type is array (1 to 3) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_3d_type is array (1 to 3) of std_logic_vector(TO_DWIDTH-1 downto 0);
    type to_4e_type is array (1 to 2) of std_logic_vector(1 to 2);
    type to_4c_type is array (1 to 2) of to_2c_type;
    type to_4d_type is array (1 to 2) of to_2d_type;
    type to_8e_type is array (1 to 4) of std_logic_vector(1 to 2);
    type to_8c_type is array (1 to 4) of to_2c_type;
    type to_8d_type is array (1 to 4) of to_2d_type;
    type to_12e_type is array (1 to 6) of std_logic_vector(1 to 2);
    type to_12c_type is array (1 to 6) of to_2c_type;
    type to_12d_type is array (1 to 6) of to_2d_type;

    type to_ein_type is array (1 to 4) of to_12e_type;
    type to_cin_type is array (1 to 4) of to_12c_type;
    type to_din_type is array (1 to 4) of to_12d_type;

    type to_onehot_type is array (1 to 4) of std_logic_vector(1 to TO_NUM_CHAN);
    type to_48to4e_type is array (1 to 4) of std_logic;
    type to_48to4c_type is array (1 to 4) of std_logic_vector(TO_CWIDTH-1 downto 0);
    type to_48to4d_type is array (1 to 4) of std_logic_vector(TO_DWIDTH-1 downto 0);
    type to_outreg_type is array (1 to 4) of std_logic_vector(TO_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
	-- Function declarations.
    --------------------------------------------------------------------------
	-- Calculates the index for mapping signals to input ports
    function TO_IN_IDX2(i : integer) return integer;
    function TO_IN_IDX1(i : integer) return integer;
	function TO_IN_IDX0(i : integer) return integer;
    function TO_CH_FUN(ch_offset : integer; size : integer) return std_logic_vector;
    function TO_CH2ONEHOT(addr : std_logic_vector; size : integer) return std_logic_vector;

end time_order_pkg;

--------------------------------------------------------------------------
-- Package body
--------------------------------------------------------------------------
package body time_order_pkg is


    ----------------------------------------------------------
	-- Calculates the index for mapping signals to input ports
    ----------------------------------------------------------
    function TO_IN_IDX2(i : integer) return integer is
        variable z          : integer range 0 to TO_RED_OUT;
    begin

        z := INTEGER(CEIL(REAL(i)/REAL(TO_RED_FAC)));

    return z;

    end TO_IN_IDX2;


    ----------------------------------------------------------
	-- Calculates the index for mapping signals to input ports
    ----------------------------------------------------------
    function TO_IN_IDX1(i : integer) return integer is
        variable k          : integer range 0 to TO_RED_OUT;
        variable y          : integer range 0 to TO_NUM_CHAN;
        variable z          : integer range 0 to TO_RED_FAC/2;
    begin

        k := TO_IN_IDX2(i)-1;
        y := i - (k * 12);
        z := INTEGER(CEIL(REAL(y) / 2.0));

    return z;

    end TO_IN_IDX1;

    ----------------------------------------------------------
	-- Calculates the index for mapping signals to input ports
    ----------------------------------------------------------
    function TO_IN_IDX0(i : integer) return integer is
        variable temp       : unsigned(TO_CWIDTH-1 downto 0);
        variable z          : integer range 0 to TO_NUM_CHAN;
    begin

        temp := TO_UNSIGNED(i,TO_CWIDTH);
        if temp(0) = '1' then
            z := 1;
        else
            z := 2;
        end if;

    return z;

    end TO_IN_IDX0;

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


