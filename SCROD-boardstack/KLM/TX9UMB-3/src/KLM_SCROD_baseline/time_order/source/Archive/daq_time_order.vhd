--*********************************************************************************
-- Indiana University
-- Center for Exploration of Energy and Matter (CEEM)
--
-- Project: Belle-II
--
-- Author:  Brandon Kunkler
--
-- Date:    04/04/2014
--
--*********************************************************************************
-- Description:
-- Time order and merge (TOM) NUM_LANES DAQ data inputs into a single output. The 
-- empty flags from the previous entity's FIFOs is used as a valid data flag. The
-- minimum output is found and then that FIFO is read - there is a feedback loop.
-- The output is only written when new data appears.
--
-- Output pseudocode: 
-- 1) Wait for valid data flag.
-- 2) Write minimum value to output.
-- 3) Read input that contains minimum value.
-- 4) Find new minimum value.
--
-- The NUM_LANES constant must be calculated for the trigger time order case so that
-- the RPC format for trigger and DAQ is the same.
--
-- Deficiencies/Issues
-- 1) The use of constant is conflicting and lacking. The number of input lanes
-- cannot actually be changed and must be known in the package to generate
-- TO_CWIDTH. The NUM_LANES constant should just be moved to the package where
-- TO_CWIDTH can be calculated.
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.math_real.all;
library work;    
	use work.time_order_pkg.all;
    use work.fpga_common_pkg.all;

entity daq_time_order is
    generic(
    NUM_LANES                   : integer);
	port(
	clk						    : in std_logic;
    ce                          : in std_logic;
	reset						: in std_logic;
    dst_full                    : in std_logic;
    src_epty                    : in std_logic_vector(1 to NUM_LANES);
    din    	                    : in daq_data_type(1 to NUM_LANES);
    src_re                      : out std_logic_vector(1 to NUM_LANES);
    dst_we                      : out std_logic;
    dout                        : out std_logic_vector(TO_WIDTH-1 downto 0));
end daq_time_order;


architecture behave of daq_time_order is
    
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
    
    --constant LANE_BITS          : integer := INTEGER(CEIL(LOG2(REAL(NUM_LANES))));
    
    signal ein_t                : to_mape_type(1 to NUM_LANES);
    signal cin_t                : to_mapc_type(1 to NUM_LANES);
    signal din_t                : to_mapd_type(1 to NUM_LANES);    

    signal emin                 : std_logic;
    signal cmin                 : std_logic_vector(TO_CWIDTH-1 downto 0);    
    signal dmin                 : std_logic_vector(TO_DWIDTH-1 downto 0);    

    signal one_hot_ch_t         : std_logic_vector(1 to NUM_LANES);
    signal src_re_d0            : std_logic_vector(1 to NUM_LANES);
    signal src_re_q0            : std_logic_vector(1 to NUM_LANES)          := (others => '0');
    signal out_cmp_d0           : std_logic;
    signal out_cmp_q0           : std_logic                                 := '0';
    signal out_cmp_d1           : std_logic;
    signal out_cmp_q1           : std_logic                                 := '0';
    signal out_cmp_q2           : std_logic                                 := '0';
    signal out_cmp_vec          : std_logic_vector(1 to NUM_LANES);
    signal dout_q0              : std_logic_vector(TO_WIDTH-1 downto 0)     := (others => '0');
    signal dout_q1              : std_logic_vector(TO_WIDTH-1 downto 0)     := (others => '0');
    
    signal temp                 : std_logic_vector(3 downto 0);

begin

---------------------------------------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------------------------------------
    
    -----------------------------------------------------------
    -- Time order RPC data
    -----------------------------------------------------------    
    rpc_tom_ins : tom_13_to_1
    port map(
        clk                 => clk,
        ce                  => ce,
        ein                 => to_13e_type(ein_t),
        cin                 => to_13c_type(cin_t),
        din                 => to_13d_type(din_t),
        emin                => emin,
        cmin                => cmin,
        dmin                => dmin
    );    
    
---------------------------------------------------------------------------------------------------------
-- Concurrent statments
---------------------------------------------------------------------------------------------------------

	-- Assertions ----------------------------------------------

	-----------------------------------------------------------
    
    -- Map the static signals to/from the port
    INPUT_GEN :
    for N in 1 to NUM_LANES generate
        ein_t(N) <= src_epty(N);
        cin_t(N) <= TO_CH_FUN(N,TO_LANE_BITS) & din(N)(23 downto 16);
        din_t(N) <= din(N)(TO_DWIDTH-1 downto 0);
    end generate;

    src_re <= src_re_q0;
    --dst_we <= out_cmp_q1;
    dst_we <= out_cmp_q2;
    --dout <= dout_q0;
    dout <= dout_q1;

    -- Asynchronous logic -------------------------------------
    dout_q0 <= cmin & dmin;

    -- exclude the bootstrap bit (MSb) from conversion
    one_hot_ch_t <= TO_CH2ONEHOT(cmin(cmin'length-1 downto cmin'length-TO_LANE_BITS),NUM_LANES);

    -- assert when the output data changes
    out_cmp_d0 <= '0' when dout_q0 = dout_q1 else '1';
    out_cmp_d1 <= out_cmp_q0 and (not emin);
    --out_cmp_vec <= (others => out_cmp_q0);--!this could be an error in RPC and trigger time order
    out_cmp_vec <= (others => out_cmp_q1);--!this could be the fix

    src_re_d0 <= out_cmp_vec and (not src_epty) and one_hot_ch_t;
    -----------------------------------------------------------

    temp <= cmin(cmin'length-1 downto cmin'length-4);
    
---------------------------------------------------------------------------------------------------------
-- Synchronous processes
---------------------------------------------------------------------------------------------------------

	
    --------------------------------------------------------------------------
	-- Register the inputs and outputs to improve timing or adjust delays.
	--------------------------------------------------------------------------
    io_regs_pcs : process(clk)
    begin
        if (clk'event and clk = '1') then
    	end if;
    end process;

    --------------------------------------------------------------------------
	-- Register valid data output signals to improve timing or adjust delays.
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

