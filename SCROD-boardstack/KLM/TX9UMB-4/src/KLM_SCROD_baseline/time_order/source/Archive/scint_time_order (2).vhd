--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    01/28/2014
--
--*********************************************************************************
-- Description:
-- Orders time stamps from two inputs and writes them to an output - expects the
-- the output to be the same entity in a tree structure.
--
-- Deficiencies/Issues
--
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.math_real.all;
library work;    
	use work.time_order_pkg.all;

entity time_order is
    generic(
    NUM_LANES                   : integer);
	port(
	clk						    : in std_logic;
    ce                          : in std_logic;
	reset						: in std_logic;
    dst_full                    : in std_logic;
    src_epty                    : in std_logic_vector(1 to NUM_LANES);
    din    	                    : in trigger_data_type(1 to NUM_LANES);
    src_re                      : out std_logic_vector(1 to NUM_LANES);
    dst_we                      : out std_logic;
    dout                        : out std_logic_vector(TO_WIDTH-1 downto 0));
end time_order;


architecture behave of time_order is

    component tom_7_to_1 is
        port(
        clk                     : in std_logic;
        ce                      : in std_logic;
        ein                     : in to_7e_type;
        cin                     : in to_7c_type;
        din                     : in to_7d_type;
        emin                    : out std_logic;
        cmin                    : out std_logic_vector(TO_CWIDTH-1 downto 0);
        dmin                    : out std_logic_vector(TO_DWIDTH-1 downto 0));
    end component;
    
    component tom_13_to_1 is
        port(
        clk                     : in std_logic;
        ce                      : in std_logic;
        ein                     : in to_13e_type;
        cin                     : in to_13c_type;
        din                     : in to_13d_type;
        emin                    : out std_logic;
        cmin                    : out std_logic_vector(TO_CWIDTH-1 downto 0);
        dmin                    : out std_logic_vector(TO_DWIDTH-1 downto 0));
    end component;    
    
    constant LANE_BITS          : integer := INTEGER(CEIL(LOG2(REAL(TO_MAX_LANE))));
    
    signal ein1_t               : to_mape_type(1 to NUM_LANES);
    signal cin1_t               : to_mapc_type(1 to NUM_LANES);
    signal din1_t               : to_mapd_type(1 to NUM_LANES);    
    
    signal emin1_t              : std_logic;
    signal cmin1_t              : std_logic_vector(TO_CWIDTH-1 downto 0);
    signal dmin1_t              : std_logic_vector(TO_DWIDTH-1 downto 0);

    signal one_hot_ch_t         : std_logic_vector(1 to NUM_LANES);
    signal src_re_d0            : std_logic_vector(1 to NUM_LANES);
    signal src_re_q0            : std_logic_vector(1 to NUM_LANES);
    signal out_cmp_d0           : std_logic;
    signal out_cmp_q0           : std_logic;
    signal out_cmp_d1           : std_logic;
    signal out_cmp_q1           : std_logic;
    signal out_cmp_q2           : std_logic;
    signal out_cmp_vec          : std_logic_vector(1 to NUM_LANES);
    signal dout_q0              : std_logic_vector(TO_WIDTH-1 downto 0)     := (others => '0');
    signal dout_q1              : std_logic_vector(TO_WIDTH-1 downto 0)     := (others => '0');
    
    signal temp                 : std_logic_vector(3 downto 0);

begin

---------------------------------------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------------------------------------
    
    -----------------------------------------------------------
    -- Time order scintillator data
    -----------------------------------------------------------
    SCINT_TOM_GEN : if NUM_LANES = 7 generate
        tom_ins : tom_7_to_1
        port map(
            clk                 => clk,
            ce                  => ce,
            ein                 => to_7e_type(ein1_t),
            cin                 => to_7c_type(cin1_t),
            din                 => to_7d_type(din1_t),
            emin                => emin1_t,
            cmin                => cmin1_t,
            dmin                => dmin1_t
        );
    end generate;
    
    -----------------------------------------------------------
    -- Time order RPC data
    -----------------------------------------------------------    
    RPC_TOM_GEN : if NUM_LANES = 13 generate
        tom_ins : tom_13_to_1
        port map(
            clk                 => clk,
            ce                  => ce,
            ein                 => to_13e_type(ein1_t),
            cin                 => to_13c_type(cin1_t),
            din                 => to_13d_type(din1_t),
            emin                => emin1_t,
            cmin                => cmin1_t,
            dmin                => dmin1_t
        );
    end generate;    

---------------------------------------------------------------------------------------------------------
-- Concurrent statments
---------------------------------------------------------------------------------------------------------

	-- Assertions ----------------------------------------------

	-----------------------------------------------------------
    
    -- Map the static signals to/from the port
    INPUT_GEN :
    for N in 1 to NUM_LANES generate
        ein1_t(N) <= src_epty(N);
        cin1_t(N) <= TO_CH_FUN(N,LANE_BITS) & din(N)(23 downto 16);
        din1_t(N) <= din(N)(TO_DWIDTH-1 downto 0);
    end generate;

    src_re <= src_re_q0;
    --dst_we <= out_cmp_q1;
    dst_we <= out_cmp_q2;
    --dout <= dout_q0;
    dout <= dout_q1;

    -- Asynchronous logic -------------------------------------
    dout_q0 <= cmin1_t & dmin1_t;

    -- exclude the bootstrap bit (MSb) from conversion
    one_hot_ch_t <= TO_CH2ONEHOT(cmin1_t(cmin1_t'length-1 downto cmin1_t'length-4),NUM_LANES);

    -- assert when the output data changes
    out_cmp_d0 <= '0' when dout_q0 = dout_q1 else '1';
    out_cmp_d1 <= out_cmp_q0 and (not emin1_t);
    out_cmp_vec <= (others => out_cmp_q0);

    src_re_d0 <= out_cmp_vec and (not src_epty) and one_hot_ch_t;
    -----------------------------------------------------------

    temp <= cmin1_t(cmin1_t'length-1 downto cmin1_t'length-4);
    
---------------------------------------------------------------------------------------------------------
-- Synchronous processes
---------------------------------------------------------------------------------------------------------

	-- Generate adder tree to sum the DALUTs


    --------------------------------------------------------------------------
	-- Register the inputs and outputs to improve timing or adjust delays.
	--------------------------------------------------------------------------
    io_regs_pcs : process(clk)
    begin
        if (clk'event and clk = '1') then
    	end if;
    end process;

    --------------------------------------------------------------------------
	-- Register the inputs and outputs to improve timing or adjust delays.
	--------------------------------------------------------------------------
    valid_pcs : process(clk)
    begin
        if (clk'event and clk = '1') then
            src_re_q0 <= src_re_d0;
            dout_q1 <= dout_q0;
            out_cmp_q0 <= out_cmp_d0;
            out_cmp_q1 <= out_cmp_d1;
            out_cmp_q2 <= out_cmp_q1;
    	end if;
    end process;

end behave;

