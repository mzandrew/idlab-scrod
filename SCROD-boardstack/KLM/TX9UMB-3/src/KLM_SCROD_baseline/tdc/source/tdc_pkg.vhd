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
-- Package for Belle-II TDC entity. Modified RPC Front-End source.
--
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
--	use ieee.std_logic_arith.all;
--	use ieee.std_logic_unsigned.all;
--	use ieee.math_real.all;


package tdc_pkg is

    --------------------------------------------------------------------------
	-- Constant declarations.
    --------------------------------------------------------------------------
    constant TDC_NUM_CHAN           : integer   := 10;
	constant TDC_TWIDTH				: integer	:= 9;--timer width
    constant TDC_CWIDTH				: integer	:= 4;--channel width
    constant TDC_FWIDTH				: integer	:= TDC_CWIDTH+TDC_TWIDTH;-- FIFO width (total)	
    constant TDC_INIT_VAL           : std_logic_vector(TDC_TWIDTH-1 downto 0) := (others => '0');
--	constant intc				    : integer 	:= INTEGER(CEIL(LOG2(REAL(SC_NUM_SCR))));
--	constant intc				    : integer 	:= (2**(SC_SCR_BITS+1));

    --------------------------------------------------------------------------
	-- Type declarations.
    --------------------------------------------------------------------------
    type tb_vec_type is array (1 to TDC_NUM_CHAN) of std_logic_vector(5 downto 1);
    type tdc_dout_type is array (1 to TDC_NUM_CHAN) of std_logic_vector(TDC_FWIDTH - 1 downto 0);
    --type tdc_hdout_type is array (1 to TDC_NUM_CHAN/2) of std_logic_vector(TDC_WIDTH - 1 downto 0);

    --------------------------------------------------------------------------
	-- Function declarations.
    --------------------------------------------------------------------------
    function TDC_INIT_FUN(cnt_num : integer; size : integer) return std_logic_vector;
	function BIN_TO_ONEHOT(addr : integer; size : integer) return std_logic_vector;
    function SWAP_BITS(arg : std_logic_vector) return std_logic_vector;

end tdc_pkg;

--------------------------------------------------------------------------
-- Package body
--------------------------------------------------------------------------
package body tdc_pkg is

	---------------------------------------------------------
	-- Calculate counter init values assuming reset is a 
    -- tapped delay line.
	--------------------------------------------------------
	function TDC_INIT_FUN(cnt_num : integer; size : integer) return std_logic_vector is

		variable intval     : integer range 0 to ((2**size)-1);
        variable temp       : unsigned(size-1 downto 0);
		variable outp       : std_logic_vector(size-1 downto 0);

	begin

		intval := ((2**TDC_TWIDTH) - 1) - cnt_num;
        temp := TO_UNSIGNED(intval,size);
        outp := STD_LOGIC_VECTOR(temp);

		return outp;
	end TDC_INIT_FUN;    

	---------------------------------------------------------
	-- Generate a one-hot output from binary input
	--------------------------------------------------------
	function BIN_TO_ONEHOT(addr : integer; size : integer) return std_logic_vector is

		variable temp       : unsigned(size-1 downto 0);
		variable outp       : std_logic_vector(size-1 downto 0);

	begin

		if addr <= 0 then
            outp := (others => '0');
        else
			temp := SHIFT_LEFT(TO_UNSIGNED(1,size),addr-1);
            outp := STD_LOGIC_VECTOR(temp);
        end if;

		return outp;
	end BIN_TO_ONEHOT;
    
	---------------------------------------------------------
	-- Swap bits in a vector
	--------------------------------------------------------
	function SWAP_BITS(arg : std_logic_vector) return std_logic_vector is
		constant arg_l		: integer := arg'length-1;
		variable data		: std_logic_vector(arg_l downto 0)	:= (others => '0');
	begin		
   		
		for I in 0 to arg_l loop
			data(I) := arg(arg_l-I);
		end loop;			
					
		return data;
		
	end SWAP_BITS;    


end tdc_pkg;


