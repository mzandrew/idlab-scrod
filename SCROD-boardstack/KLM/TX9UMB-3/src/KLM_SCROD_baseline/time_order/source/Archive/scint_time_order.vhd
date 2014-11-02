--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    12/11/2012
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
library work;
    use work.tdc_pkg.all;
	use work.time_order_pkg.all;

entity time_order is
	port(
	clk						    : in std_logic;
    ce                          : in std_logic_vector(1 to 5);
	reset						: in std_logic;
    pbstrap                     : in std_logic;
    dst_full                    : in std_logic;
    src_ept                     : in std_logic_vector(1 to TO_NUM_CHAN);
    din    	                    : in tdc_dout_type;
    src_re                      : out std_logic_vector(1 to TO_NUM_CHAN);
    dst_we                      : out std_logic;
    dout                        : out std_logic_vector(TO_WIDTH-1 downto 0));
end time_order;


architecture behave of time_order is

    component tom_12_to_1 is
        port(
        clk                     : in std_logic;
        ce                      : in std_logic;
        ein                     : in to_12e_type;
        cin                     : in to_12c_type;
        din                     : in to_12d_type;
        emin                    : out std_logic;
        cmin                    : out std_logic_vector(TO_CWIDTH-1 downto 0);
        dmin                    : out std_logic_vector(TO_DWIDTH-1 downto 0));
    end component;

    component tom_4_to_1 is
        port(
        clk                     : in std_logic;
        ce                      : in std_logic;
        ein                     : in to_4e_type;
        cin                     : in to_4c_type;
        din                     : in to_4d_type;
        emin                    : out std_logic;
        cmin                    : out std_logic_vector(TO_CWIDTH-1 downto 0);
        dmin                    : out std_logic_vector(TO_DWIDTH-1 downto 0));
    end component;

    signal ein1_t               : to_ein_type;
    signal cin1_t               : to_cin_type;
    signal din1_t               : to_din_type;
    signal emin1_t              : to_48to4e_type;
    signal cmin1_t              : to_48to4c_type;
    signal dmin1_t              : to_48to4d_type;

    signal ein2_t               : to_4e_type;
    signal cin2_t               : to_4c_type;
    signal din2_t               : to_4d_type;
    signal emin2_t              : std_logic;
    signal cmin2_t              : std_logic_vector(TO_CWIDTH-1 downto 0);
    signal dmin2_t              : std_logic_vector(TO_DWIDTH-1 downto 0);
    signal one_hot_ch_t         : std_logic_vector(1 to TO_NUM_CHAN);
    signal src_re_d0            : std_logic_vector(1 to TO_NUM_CHAN);
    signal src_re_q0            : std_logic_vector(1 to TO_NUM_CHAN);
    signal out_cmp_d0           : std_logic;
    signal out_cmp_q0           : std_logic;
    signal out_cmp_d1           : std_logic;
    signal out_cmp_q1           : std_logic;
    signal out_cmp_q2           : std_logic;
    signal out_cmp_vec          : std_logic_vector(1 to TO_NUM_CHAN);
    signal dout_q0              : std_logic_vector(TO_WIDTH-1 downto 0)     := (others => '0');
    signal dout_q1              : std_logic_vector(TO_WIDTH-1 downto 0)     := (others => '0');

begin

---------------------------------------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------------------------------------
    --------------------------------------------------
    -- Generate a 48 to 4 time orderer out of 12 to 1
    -- time-order-merge components
    --------------------------------------------------
    TOM48_TO_4_GEN:
    for I in 1 to 4 generate
        tom_12_to_1_ins : tom_12_to_1
            port map(
            clk                 => clk,
            ce                  => ce(I),
            ein                 => ein1_t(I),
            cin                 => cin1_t(I),
            din                 => din1_t(I),
            emin                => emin1_t(I),
            cmin                => cmin1_t(I),
            dmin                => dmin1_t(I)
        );
    end generate;

    --------------------------------------------------
    -- Four input even-odd-merge sorter
    --------------------------------------------------
    tom_4_to_1_ins : tom_4_to_1
        port map(
        clk                     => clk,
        ce                      => ce(5),
        ein                     => ein2_t,
        cin                     => cin2_t,
        din                     => din2_t,
        emin                    => emin2_t,
        cmin                    => cmin2_t,
        dmin                    => dmin2_t
    );

---------------------------------------------------------------------------------------------------------
-- Concurrent statments
---------------------------------------------------------------------------------------------------------

	-- Assertions ----------------------------------------------

	-----------------------------------------------------------

    -- Map the static signals to/from the port
    INPUT_GEN :
    for N in 1 to TO_NUM_CHAN generate
        ein1_t(TO_IN_IDX2(N))(TO_IN_IDX1(N))(TO_IN_IDX0(N)) <= src_ept(N);
        cin1_t(TO_IN_IDX2(N))(TO_IN_IDX1(N))(TO_IN_IDX0(N)) <= TO_CH_FUN(N,TO_CWIDTH);
        din1_t(TO_IN_IDX2(N))(TO_IN_IDX1(N))(TO_IN_IDX0(N)) <= din(N);
    end generate;

    ein2_t(1) <= emin1_t(1) & emin1_t(2);
    cin2_t(1) <= cmin1_t(1) & cmin1_t(2);
    din2_t(1) <= dmin1_t(1) & dmin1_t(2);

    ein2_t(2) <= emin1_t(3) & emin1_t(4);
    cin2_t(2) <= cmin1_t(3) & cmin1_t(4);
    din2_t(2) <= dmin1_t(3) & dmin1_t(4);

    src_re <= src_re_q0;
    --dst_we <= out_cmp_q1;
    dst_we <= out_cmp_q2;
    --dout <= dout_q0;
    dout <= dout_q1;

    -- Asynchronous logic -------------------------------------
    dout_q0 <= cmin2_t & dmin2_t;

    -- exclude the bootstrap bit (MSb) from conversion
    one_hot_ch_t <= TO_CH2ONEHOT(cmin2_t(cmin2_t'length-1 downto 0),TO_NUM_CHAN);

    -- assert when the output data changes
    out_cmp_d0 <= '0' when dout_q0 = dout_q1 else '1';
    out_cmp_d1 <= out_cmp_q0 and (not emin2_t);
    out_cmp_vec <= (others => out_cmp_q0);

    src_re_d0 <= out_cmp_vec and (not src_ept) and one_hot_ch_t;
    -----------------------------------------------------------

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

