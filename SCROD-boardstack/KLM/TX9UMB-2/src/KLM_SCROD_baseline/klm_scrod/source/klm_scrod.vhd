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
-- Top level KLM SCROD design for Data Concentrator interface integration.
--
-- There are four data streams:
-- 1) Trigger data stream. The TARGET trigger bits are connected directly to and
--    processed by the conc_intfc.
-- 2) The DAQ data stream. This is an entire triggers worth of DAQ data that will
--    be forwarded to the COPPER. As of creation the DAQ data stream from each
--    TARGET must be combined before transmitting to the conc_intfc. The DAQ data
--    format was not known at time of creation. Connecting all TARGETs to the
--    conc_intfc and combing there would be more consistent. The con_intfc
--    inserts the lowest 16-bits of the trigger tag to be used for combing scint
--    and RPC data.
-- 3) Status data stream. All status registers will be forward to the Data Concentrator
--    every so many DAQ packets (trigger cycles).
-- 4) Control data stream. The Data Concentrator will transmit a single (large) packet
--    containing all run control values as specified in the interface document.
--
-- NOTE:
-- 1) The delay (in clocks) between b2tt runreset and the TDC counter sync must be
--    known (controlled) to keep scint and RPC TDCs in phase.
-- 2) MAXDELAY constraints may need to be placed on the b2tt runreset signal shift
--    register in the timing_ctrl entity to distribute the FFs across the chip.
-- 3) The asynchronous nature of tx_dst_rdy_n may cause issues in the conc_intfc
--    state machine.
-- 4) The Aurora core is modified; the files in the ipore directory are not used
--    during implementation.
-- 5) Search on --? or --! for other important notes.
--
--*********************************************************************************
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_misc.all;
library work;    
    use work.time_order_pkg.all;
    use work.tdc_pkg.all;
    use work.conc_intfc_pkg.all;
    use work.klm_scrod_pkg.all;
-- synthesis translate_off
library unisim;
    use unisim.vcomponents.all;
-- synthesis translate_on

entity klm_scrod is
    generic(
    NUM_GTS                     : integer := 2);
    port(
    -- TTD/FTSW interface
    ttdclkp                     : in std_logic;
    ttdclkn                     : in std_logic;
    ttdtrgp                     : in std_logic;
    ttdtrgn                     : in std_logic;
    ttdrsvp                     : out std_logic;
    ttdrsvn                     : out std_logic;
    ttdackp                     : out std_logic;
    ttdackn                     : out std_logic;
    -- ASIC Interface
    target_tb                   : in tb_vec_type; 
    target_tb16                 : in std_logic_vector(1 to TDC_NUM_CHAN); 
    -- SFP interface
    mgttxfault                  : in std_logic_vector(1 to NUM_GTS);
    mgtmod0                     : in std_logic_vector(1 to NUM_GTS);
    mgtlos                      : in std_logic_vector(1 to NUM_GTS);
    mgttxdis                    : out std_logic_vector(1 to NUM_GTS);
    mgtmod2                     : out std_logic_vector(1 to NUM_GTS);
    mgtmod1                     : out std_logic_vector(1 to NUM_GTS);
    mgtrxp                      : in std_logic;
    mgtrxn                      : in std_logic;
    mgttxp                      : out std_logic;
    mgttxn                      : out std_logic;
    status_fake                 : out std_logic;
    control_fake                : out std_logic);
end klm_scrod;

--- architecture -------------------------------------------------------
architecture behave of klm_scrod is

    component IBUF is
    port(
        O                       : out std_logic;  -- buffer output
        I                       : in std_logic);  -- buffer input (connect directly to top-level port)
    end component;

    component OBUF is
    port(
        O                       : out std_logic;  -- buffer output
        I                       : in std_logic);  -- buffer input (connect directly to top-level port)
    end component;

    component timing_ctrl is
        port(
        clk                     : in std_logic;
        clk2x                   : in std_logic;
        runreset                : in std_logic;
        tdcrst                  : out std_logic_vector(1 to 3);--vector so we can distribute to meet timing
        tdcce_2x                : out std_logic_vector(1 to 5)); -- _Nx is N times clock period
    end component;

    component b2tt is
    generic(
        VERSION                 : integer;
        DEFADDR                 : std_logic_vector(19 downto 0);
        FLIPCLK                 : std_logic;
        FLIPTRG                 : std_logic;
        FLIPACK                 : std_logic;
        USEFIFO                 : std_logic;
        CLKDIV1                 : integer range 1 to 72;
        CLKDIV2                 : integer range 1 to 72;
        USEPLL                  : std_logic;
        USEICTRL                : std_logic;
        NBITTIM                 : integer range 1 to 32;
        NBITTAG                 : integer range 4 to 32;
        NBITID                  : integer range 4 to 32;
        B2LRATE                 : integer);
    port(
    -- RJ-45
        clkp                    : in std_logic;
        clkn                    : in std_logic;
        trgp                    : in std_logic;
        trgn                    : in std_logic;
        rsvp                    : out std_logic;
        rsvn                    : out std_logic;
        ackp                    : out std_logic;
        ackn                    : out std_logic;
    -- board id
        id                      : in std_logic_vector (NBITID-1 downto 0);
    -- link status
        b2clkup                 : out std_logic;
        b2ttup                  : out std_logic;
    -- system clock and time
        sysclk                  : out std_logic;
        sysclk2x                : out std_logic;
        rawclk                  : out std_logic;
        utime                   : out std_logic_vector (NBITTIM-1 downto 0);
        ctime                   : out std_logic_vector (26 downto 0);
    -- divided clock
        divclk1                 : out std_logic_vector (1 downto 0);
        divclk2                 : out std_logic_vector (1 downto 0);
    -- exp- / run-number
        exprun                  : out std_logic_vector (31 downto 0);
    -- run reset
        runreset                : out std_logic;
        feereset                : out std_logic;
        b2lreset                : out std_logic;
        gtpreset                : out std_logic;
    -- trigger
        trgout                  : out std_logic;
        trgtyp                  : out std_logic_vector (3  downto 0);
        trgtag                  : out std_logic_vector (31 downto 0);
    -- revolution
        revo                    : out std_logic;
        revo9                   : out std_logic;
        revoclk                 : out std_logic_vector (10 downto 0);
        revogap                 : out std_logic;                       -- TBI
        injveto                 : out std_logic_vector (1 downto 0);   -- TBI
    -- busy and status return
        busy                    : in std_logic; -- to suspend the trigger
        err                     : in std_logic; -- to stop the run
    -- Belle2link status
        b2plllk                 : in std_logic;
        b2linkup                : in std_logic;
        b2linkwe                : in std_logic;
        b2lclk                  : in std_logic;
    -- SEU status (from virtex5_seu_controller)
        seuinit                 : in std_logic;  -- initialising
        seubusy                 : in std_logic;  -- busy
        seuactiv                : in std_logic;  -- acm_active
        seuscan                 : in std_logic;  -- end_of_scan
        seudet                  : in std_logic;  -- seu_detect
        seucrc                  : in std_logic;  -- crc_error
        seumbe                  : in std_logic;  -- mbe
    -- data for Belle2link header
        fifordy                 : out std_logic;
        fifodata                : out std_logic_vector (95 downto 0);
        fifonext                : in std_logic;
    -- b2tt-link status
        regdbg                  : in  std_logic_vector (7 downto 0);
        octet                   : out std_logic_vector (7 downto 0);  -- decode
        isk                     : out std_logic;                      -- decode
        cntbit2                 : out std_logic_vector (2 downto 0);  -- decode
        sigbit2                 : out std_logic_vector (1 downto 0);  -- decode
        bitddr                  : out std_logic;                      -- encode
    --signal dbg                      : out std_logic_vector (7  downto 0);
        dbg                     : out std_logic_vector (31 downto 0);
        dbg2                    : out std_logic_vector (31 downto 0));
    end component;

    component klm_aurora_intfc is
    generic(
        REFSELDYPLL             : std_logic_vector(2 downto 0);-- if it is gong to be controlled by logic, tie it to signal so it wont be just a generic
        SIM_GTPRESET_SPEEDUP    : integer);
    port(
        user_clk                : in std_logic;
        sync_clk                : in std_logic;
        reset                   : in std_logic;
        gt_reset                : in std_logic;
        plllock                 : in std_logic;
    -- LocalLink TX Interface
        tx_dst_rdy_n            : out std_logic;
        tx_src_rdy_n            : in std_logic;
        tx_sof_n                : in std_logic;
        tx_eof_n                : in std_logic;
        tx_d                    : in std_logic_vector(0 to 15);
        tx_rem                  : in std_logic;
    -- LocalLink RX Interface
        rx_src_rdy_n            : out std_logic;
        rx_sof_n                : out std_logic;
        rx_eof_n                : out std_logic;
        rx_rem                  : out std_logic;
        rx_d                    : out std_logic_vector(0 to 15);
    -- Status
        gtlock                  : out std_logic;
        hard_err                : out std_logic;
        soft_err                : out std_logic;
        frame_err               : out std_logic;
        channel_up              : out std_logic;
        lane_up                 : out std_logic;
        warn_cc                 : out std_logic;
        do_cc                   : out std_logic;
    -- Control
        powerdown               : in std_logic;
        loopback                : in std_logic_vector(2 downto 0);
    -- GT I/O
        rxp                     : in std_logic;
        rxn                     : in std_logic;
        txp                     : out std_logic;
        txn                     : out std_logic);
    end component;

    component conc_intfc is
        port(
        -- inputs ---------------------------------------------
        sys_clk                 : in std_logic;
        tdc_clk                 : in std_logic;
        ce                      : in std_logic_vector(1 to 5);
        --B2TT interface
        b2tt_runreset           : in std_logic;
        b2tt_runreset2x         : in std_logic_vector(1 to 3);        
        b2tt_gtpreset           : in std_logic;
        b2tt_fifordy            : in std_logic;
        b2tt_fifodata           : in std_logic_vector (95 downto 0);
        b2tt_fifonext           : out std_logic;
        --TARGET ASIC trigger interface (trigger bits)
        target_tb               : in tb_vec_type;
        target_tb16             : in std_logic_vector(1 to TDC_NUM_CHAN);
        -- status sent to concentrator
        status_regs             : in stat_reg_type;
        -- Aurora local input local link (from Concentrator)
        rx_dst_rdy_n            : out std_logic;
        rx_sof_n                : in std_logic;
        rx_eof_n                : in std_logic;
        rx_src_rdy_n            : in std_logic;
        rx_data                 : in std_logic_vector(15 downto 0);
        -- DAQ data local link input (TARGET DAQ data when triggered)
        daq_dst_rdy_n           : out std_logic;
        daq_sof_n               : in std_logic;--start of trigger
        daq_eof_n               : in std_logic;--end of trigger
        daq_src_rdy_n           : in std_logic;
        daq_data                : in std_logic_vector(15 downto 0);
        -- outputs --------------------------------------------
        -- Aurora local ouptput local link (to Concentrator)
        tx_dst_rdy_n            : in std_logic;
        tx_sof_n                : out std_logic;
        tx_eof_n                : out std_logic;
        tx_src_rdy_n            : out std_logic;
        tx_data                 : out std_logic_vector(15 downto 0);
        -- Run control local link output
        rcl_dst_rdy_n           : in std_logic;
        rcl_sof_n               : out std_logic;
        rcl_eof_n               : out std_logic;
        rcl_src_rdy_n           : out std_logic;
        rcl_data                : out std_logic_vector(15 downto 0));
    end component;

    component FRAME_GEN is
    port(
        -- User Interface
        TX_D                    : out std_logic_vector(0 to 15);
        TX_REM                  : out std_logic;
        TX_SOF_N                : out std_logic;
        TX_EOF_N                : out std_logic;
        TX_SRC_RDY_N            : out std_logic;
        TX_DST_RDY_N            : in std_logic;
        -- System Interface
        USER_CLK                : in std_logic;
        RESET                   : in std_logic;
        CHANNEL_UP              : in std_logic);
    end component;
    
    component run_ctrl is
        port(
        clk					    : in std_logic;
        rx_dst_rdy_n            : out std_logic;
        rx_sof_n                : in std_logic;
        rx_eof_n                : in std_logic;
        rx_src_rdy_n            : in std_logic;
        rx_data                 : in std_logic_vector(15 downto 0);
        ctrl_regs               : out ctrl_reg_type);
    end component;    

    component sfp_stat_ctrl is
    generic(
        NUM_GTS                 : integer);
    port(
        clk                     : in std_logic;
        txfault                 : in std_logic_vector(1 to NUM_GTS);
        txdis                   : out std_logic_vector(1 to NUM_GTS);
        mod2                    : out std_logic_vector(1 to NUM_GTS);
        mod1                    : out std_logic_vector(1 to NUM_GTS);
        mod0                    : in std_logic_vector(1 to NUM_GTS);
        los                     : in std_logic_vector(1 to NUM_GTS);
        fault_flag              : out std_logic;
        mod_flag                : out std_logic;
        los_flag                : out std_logic);
    end component;    
    
    alias NUM_ASICS is TDC_NUM_CHAN;
    
    constant NUM_ATBS           : integer := 5; --ASIC trigger bits

    signal mgttxfault_i         : std_logic_vector(1 to NUM_GTS);
    signal mgtmod0_i            : std_logic_vector(1 to NUM_GTS);
    signal mgtlos_i             : std_logic_vector(1 to NUM_GTS);

    signal mgttxdis_i           : std_logic_vector(1 to NUM_GTS);
    signal mgtmod2_i            : std_logic_vector(1 to NUM_GTS);
    signal mgtmod1_i            : std_logic_vector(1 to NUM_GTS);
    
    signal target_tb_i          : tb_vec_type;
    signal target_tb16_i        : std_logic_vector(1 to TDC_NUM_CHAN);    

    signal b2tt_ctime_i         : std_logic;
    signal status_vec_i         : std_logic_vector(1 to NUM_STAT_REGS);
    signal ctrl_vec_i           : std_logic_vector(1 to NUM_CTRL_REGS);
    signal status_fake_i        : std_logic;
    signal control_fake_i       : std_logic;

    signal sys_clk_ib           : std_logic;
    signal sys_clk2x_ib         : std_logic;    

    signal mgttxfault_qi        : std_logic_vector(1 to NUM_GTS);
    signal mgtmod0_qi           : std_logic_vector(1 to NUM_GTS);
    signal mgtlos_qi            : std_logic_vector(1 to NUM_GTS);

    signal mgttxdis_iq          : std_logic_vector(1 to NUM_GTS);
    signal mgtmod2_iq           : std_logic_vector(1 to NUM_GTS);
    signal mgtmod1_iq           : std_logic_vector(1 to NUM_GTS);

    signal b2tt_ctime_iq        : std_logic;
    signal status_fake_iq       : std_logic;
    signal control_fake_iq      : std_logic;

    signal b2tt_clkup           : std_logic;
    signal b2tt_b2ttup          : std_logic;
    signal b2tt_trg             : std_logic;
    signal b2tt_b2plllk         : std_logic;
    signal b2tt_utime           : std_logic_vector(NBITTIM-1 downto 0);    
    signal b2tt_ctime           : std_logic_vector(26 downto 0);
    signal b2tt_divclk1         : std_logic_vector(1 downto 0);
    signal b2tt_divclk2         : std_logic_vector(1 downto 0);    
    signal b2tt_runreset        : std_logic                             := '1';
    signal b2tt_runreset2x      : std_logic_vector(1 to 3)              := (others => '1');
    signal b2tt_feereset        : std_logic                             := '1';
    signal b2tt_gtpreset        : std_logic                             := '1';
    signal b2tt_b2linkup        : std_logic                             := '1';
    signal b2tt_b2linkwe        : std_logic                             := '0';
    signal b2tt_b2lreset        : std_logic                             := '1';
    signal b2tt_fifonext        : std_logic                             := '0';
    signal b2tt_fifodata        : std_logic_vector(95 downto 0)         := (others => '0');
    signal b2tt_fifordy         : std_logic;    
    signal b2tt_exprun          : std_logic_vector(31 downto 0);

    signal rx_dst_rdy_n         : std_logic;
    signal rx_sof_n             : std_logic;
    signal rx_eof_n             : std_logic;
    signal rx_src_rdy_n         : std_logic;
    signal rx_data              : std_logic_vector(15 downto 0);

    signal tx_dst_rdy_n         : std_logic;
    signal tx_sof_n             : std_logic;
    signal tx_eof_n             : std_logic;
    signal tx_src_rdy_n         : std_logic;
    signal tx_data              : std_logic_vector(15 downto 0);

    signal gtlock               : std_logic;
    signal hard_err             : std_logic;
    signal soft_err             : std_logic;
    signal frame_err            : std_logic;
    signal channel_up           : std_logic;
    signal lane_up              : std_logic;
    signal warn_cc              : std_logic;
    signal do_cc                : std_logic;
    signal tdc_ce               : std_logic_vector(1 to 5);
    
    signal status_regs          : stat_reg_type;
    signal ctrl_regs            : ctrl_reg_type;
    signal daq_dst_rdy_n        : std_logic;
    signal daq_sof_n            : std_logic;
    signal daq_eof_n            : std_logic;
    signal daq_src_rdy_n        : std_logic;
    signal daq_data             : std_logic_vector(15 downto 0);
    signal rcl_dst_rdy_n        : std_logic;
    signal rcl_sof_n            : std_logic;
    signal rcl_eof_n            : std_logic;
    signal rcl_src_rdy_n        : std_logic;
    signal rcl_data             : std_logic_vector(15 downto 0);
    
    signal fault_flag           : std_logic;
    signal los_flag             : std_logic;
    signal mod_flag             : std_logic;

begin

    -------------------------------------------------
    -- Input Buffers
    -------------------------------------------------    
    asic_IBUF_GEN : 
    for I in 1 to 10 generate
        atb_IBUF_GEN : 
        for J in 5 downto 1 generate
		  target_tb_i(I)(J)<=target_tb(I)(J);
--		  
--            atb_IBUF : IBUF
--            port map(
--                O               => target_tb_i(I)(J),
--                I               => target_tb(I)(J)
--            );
        end generate;
		 target_tb16_i(I)<=target_tb16(I);	  
--        atb16_IBUF : IBUF
--        port map(
--                O               => target_tb16_i(I),
--                I               => target_tb16(I)
--        );    
		  
    end generate;   
    
    mgttxfault_IBUF_GEN :
    for I in 1 to NUM_GTS generate
        mgttxfault_IBUF : IBUF
        port map(
            O                   => mgttxfault_i(I),
            I                   => mgttxfault(I)
        );
    end generate;

    mgtmod0_IBUF_GEN :
    for I in 1 to NUM_GTS generate
        mgtmod0_IBUF : IBUF
        port map(
            O                   => mgtmod0_i(I),
            I                   => mgtmod0(I)
        );
    end generate;

    mgtlos_IBUF_GEN :
    for I in 1 to NUM_GTS generate
        mgtlos_IBUF : IBUF
        port map(
            O                   => mgtlos_i(I),
            I                   => mgtlos(I)
        );
    end generate;

    -------------------------------------------------
    -- Output Buffers
    -------------------------------------------------    
    mgttxdis_OBUF_GEN :
    for I in 1 to NUM_GTS generate
        mgttxdis_OBUF : OBUF
        port map(
            O                   => mgttxdis(I),
            I                   => mgttxdis_iq(I)
        );
    end generate;

    mgtmod2_OBUF_GEN :
    for I in 1 to NUM_GTS generate
        mgtmod2_OBUF : OBUF
        port map(
            O                   => mgtmod2(I),
            I                   => mgtmod2_iq(I)
        );
    end generate;

    mgtmod1_OBUF_GEN :
    for I in 1 to NUM_GTS generate
        mgtmod1_OBUF : OBUF
        port map(
            O                   => mgtmod1(I),
            I                   => mgtmod1_iq(I)
        );
    end generate;

    status_OBUF : OBUF
    port map(
        O                       => status_fake,
        I                       => status_fake_iq
    );
    
    control_OBUF : OBUF
    port map(
        O                       => control_fake,
        I                       => control_fake_iq
    );    

    ----------------------------------------------------------------
    -- Clock enables, resets, strobes, etc.
    ----------------------------------------------------------------    
    tmg_ctrl_ins : timing_ctrl
    port map(
        clk                     => sys_clk_ib,
        clk2x                   => sys_clk2x_ib,
        runreset                => b2tt_runreset,
        tdcrst                  => b2tt_runreset2x,
        tdcce_2x                => tdc_ce
    );


    ----------------------------------------------------------------
    -- Timing and trigger distribution interface.
    ----------------------------------------------------------------
    b2tt_ins : b2tt
    generic map(
        VERSION                 => VERSION,
        DEFADDR                 => DEFADDR,
        FLIPCLK                 => FLIPCLK,
        FLIPTRG                 => FLIPTRG,
        FLIPACK                 => FLIPACK,
        USEFIFO                 => USEFIFO,
        CLKDIV1                 => CLKDIV1,
        CLKDIV2                 => CLKDIV2,
        USEPLL                  => USEPLL,
        USEICTRL                => USEICTRL,
        NBITTIM                 => NBITTIM,
        NBITTAG                 => NBITTAG,
        NBITID                  => NBITID,
        B2LRATE                 => B2LRATE)
    port map(
    -- RJ-45
        clkp                    => ttdclkp,
        clkn                    => ttdclkn,
        trgp                    => ttdtrgp,
        trgn                    => ttdtrgn,
        rsvp                    => ttdrsvp,
        rsvn                    => ttdrsvn,
        ackp                    => ttdackp,
        ackn                    => ttdackn,
    -- board id
        id                      => X"BEAD",
    -- link status
        b2clkup                 => b2tt_clkup,
        b2ttup                  => b2tt_b2ttup,
    -- system clock and time
        sysclk                  => sys_clk_ib,
        sysclk2x                => sys_clk2x_ib,
        rawclk                  => open,
        utime                   => b2tt_utime,
        ctime                   => b2tt_ctime,
    -- divided clock
        divclk1                 => b2tt_divclk1,
        divclk2                 => b2tt_divclk2,
    -- exp- / run-number
        exprun                  => open,
    -- run reset
        runreset                => b2tt_runreset,
        feereset                => b2tt_feereset,
        b2lreset                => b2tt_b2lreset,
        gtpreset                => b2tt_gtpreset,
    -- trigger
        trgout                  => b2tt_trg,
        trgtyp                  => open,
        trgtag                  => open,
    -- revolution
        revo                    => open,
        revo9                   => open,
        revoclk                 => open,
        revogap                 => open,
        injveto                 => open,
    -- busy and status return
        busy                    => '0',
        err                     => '0',
    -- Belle2link status
        b2plllk                 => b2tt_b2plllk,
        b2linkup                => b2tt_b2linkup,
        b2linkwe                => b2tt_b2linkwe,
        b2lclk                  => sys_clk_ib,
    -- SEU status (from virtex5_seu_controller)
        seuinit                 => '0',
        seubusy                 => '0',
        seuactiv                => '0',
        seuscan                 => '0',
        seudet                  => '0',
        seucrc                  => '0',
        seumbe                  => '0',
    -- data for Belle2link header
        fifordy                 => b2tt_fifordy,
        fifodata                => b2tt_fifodata,
        fifonext                => b2tt_fifonext,
    -- b2tt-link status (for debug only)
        regdbg                  => X"00",
        octet                   => open,
        isk                     => open,
        cntbit2                 => open,
        sigbit2                 => open,
        bitddr                  => open,
    -- debug signals
        dbg                     => open,
        dbg2                    => open
    );

    ----------------------------------------------------------------
    -- Aurora Core.
    ----------------------------------------------------------------
    aurora_ins : klm_aurora_intfc
    generic map(
        REFSELDYPLL             => "010",--PLLCLK (bad idea), -- not one of the MGT clocks
        SIM_GTPRESET_SPEEDUP    => 1)
    port map(
        user_clk                => sys_clk_ib,
        sync_clk                => sys_clk2x_ib,
        reset                   => b2tt_b2lreset,
        gt_reset                => b2tt_gtpreset,
        plllock                 => b2tt_clkup,--b2tt_b2plllk,
    -- LocalLink TX Interface
        tx_dst_rdy_n            => tx_dst_rdy_n,
        tx_src_rdy_n            => tx_src_rdy_n,
        tx_sof_n                => tx_sof_n,
        tx_eof_n                => tx_eof_n,
        tx_d                    => tx_data,
        tx_rem                  => '1',--?
    -- LocalLink RX Interface
        rx_src_rdy_n            => rx_src_rdy_n,
        rx_sof_n                => rx_sof_n,
        rx_eof_n                => rx_eof_n,
        rx_rem                  => open,--?
        rx_d                    => rx_data,
    -- Status
        gtlock                  => gtlock,
        hard_err                => hard_err,
        soft_err                => soft_err,
        frame_err               => frame_err,
        channel_up              => channel_up,
        lane_up                 => lane_up,
        warn_cc                 => warn_cc, -- the may help in conc interface
        do_cc                   => do_cc,
    -- Control
        powerdown               => '0',
        loopback                => "000",
    -- GT I/O
        rxp                     => mgtrxp,
        rxn                     => mgtrxn,
        txp                     => mgttxp,
        txn                     => mgttxn
    );

    ----------------------------------------------------------------
    -- Data Concentrator interface. Generate and time-order TDC.
    -- Combine trigger, DAQ, and status data. Receive control data.
    ----------------------------------------------------------------    
    conc_intfc_ins : conc_intfc
    port map(
        -- inputs ---------------------------------------------
        sys_clk                 => sys_clk_ib,
        tdc_clk                 => sys_clk2x_ib,
        ce                      => tdc_ce,
        --B2TT interface
        b2tt_runreset           => b2tt_runreset,
        b2tt_runreset2x         => b2tt_runreset2x,
        b2tt_gtpreset           => b2tt_gtpreset,
        b2tt_fifordy            => b2tt_fifordy ,
        b2tt_fifodata           => b2tt_fifodata,
        b2tt_fifonext           => b2tt_fifonext,
        --TARGET ASIC trigger interface (trigger bits)
        target_tb               => target_tb_i,
        target_tb16             => target_tb16_i,
        -- status sent to concentrator
        status_regs             => status_regs,
        -- Aurora local input local link (from Concentrator)
        rx_dst_rdy_n            => rx_dst_rdy_n,
        rx_sof_n                => rx_sof_n,
        rx_eof_n                => rx_eof_n,
        rx_src_rdy_n            => rx_src_rdy_n,
        rx_data                 => rx_data,
        -- DAQ data local link input (TARGET DAQ data when triggered)
        daq_dst_rdy_n           => daq_dst_rdy_n,
        daq_sof_n               => daq_sof_n,--start of trigger
        daq_eof_n               => daq_eof_n,--end of trigger
        daq_src_rdy_n           => daq_src_rdy_n,
        daq_data                => daq_data,
        -- outputs --------------------------------------------
        -- Aurora local ouptput local link (to Concentrator)
        tx_dst_rdy_n            => tx_dst_rdy_n,
        tx_sof_n                => tx_sof_n,
        tx_eof_n                => tx_eof_n,
        tx_src_rdy_n            => tx_src_rdy_n,
        tx_data                 => tx_data,
        -- Run control local link output
        rcl_dst_rdy_n           => rcl_dst_rdy_n,
        rcl_sof_n               => rcl_sof_n,
        rcl_eof_n               => rcl_eof_n,
        rcl_src_rdy_n           => rcl_src_rdy_n,
        rcl_data                => rcl_data
    );

    ----------------------------------------------------------------
    -- Create a single DAQ data stream from alll Asics.
    --!A packet is an entire trigger.
    --!Must be synced with b2tt trigger/fifo read.
    ----------------------------------------------------------------    
    daq_gen_ins : FRAME_GEN
    port map(
        -- User Interface
        TX_D                    => daq_data,
        TX_REM                  => open,
        TX_SOF_N                => daq_sof_n,
        TX_EOF_N                => daq_eof_n,
        TX_SRC_RDY_N            => daq_src_rdy_n,
        TX_DST_RDY_N            => daq_dst_rdy_n,
        -- System Interface
        USER_CLK                => sys_clk_ib,
        RESET                   => b2tt_b2lreset,
        CHANNEL_UP              => b2tt_b2linkup
    );
    
    ----------------------------------------------------------------
    -- Receive and distribute run control registers.
    ----------------------------------------------------------------    
    run_ctrl_ins : run_ctrl
        port map(
        clk					    => sys_clk_ib,
        rx_dst_rdy_n            => rcl_dst_rdy_n,
        rx_sof_n                => rcl_sof_n,
        rx_eof_n                => rcl_eof_n,
        rx_src_rdy_n            => rcl_src_rdy_n,
        rx_data                 => rcl_data,
        ctrl_regs               => ctrl_regs
    );
    
    ----------------------------------------------------------------
    -- Deal with the SFP connections.
    ----------------------------------------------------------------    
    sfp_stat_ctrl_ins : sfp_stat_ctrl
    generic map(
        NUM_GTS                 => NUM_GTS)
    port map(
        clk                     => sys_clk_ib,
        txfault                 => mgttxfault_qi,
        txdis                   => mgttxdis_i,
        mod2                    => mgtmod2_i,
        mod1                    => mgtmod1_i,
        mod0                    => mgtmod0_qi,
        los                     => mgtlos_qi,
        fault_flag              => fault_flag,
        mod_flag                => mod_flag,
        los_flag                => los_flag
    );    
    
---------------------------------------------------------------------
-- Concurrent statements
---------------------------------------------------------------------    
    
    --------------------------------------
    -- Map the status registers
    --------------------------------------    
    --! just keep signals from being synthesized away for now
    --! SFP/link signals are useless if link is down
    status_regs(0) <= '0' & fault_flag & mod_flag & los_flag & hard_err & soft_err & frame_err & lane_up;    
    status_regs(1) <= "0000" & warn_cc & do_cc & b2tt_feereset & b2tt_ctime_iq;   
    
    b2tt_b2linkup <= channel_up;
    b2tt_b2plllk <= gtlock;
    b2tt_b2linkwe <= tx_src_rdy_n;
    
---------------------------------------------------------------------
-- Synchronous processes
---------------------------------------------------------------------
----------------------------------------------------------------
-- Input registers to be placed in the I/O ring
----------------------------------------------------------------

    --------------------------------------
    -- System clock domain input registers
    --------------------------------------
    sysin_regs : process(sys_clk_ib)
    begin
        if (sys_clk_ib'event and sys_clk_ib = '1') then
            mgttxfault_qi <= mgttxfault_i;
            mgtmod0_qi <= mgtmod0_i;
            mgtlos_qi <= mgtlos_i;
        end if;
    end process;

----------------------------------------------------------------
-- Output registers to be placed in the I/O ring
----------------------------------------------------------------

    --------------------------------------
    -- System clock domain output registers
    --------------------------------------
    sout_regs : process(sys_clk_ib)
    begin
        if (sys_clk_ib'event and sys_clk_ib = '1') then
            mgttxdis_iq <= mgttxdis_i;
            mgtmod2_iq <= mgtmod2_i;
            mgtmod1_iq <= mgtmod1_i;
            b2tt_ctime_i <= OR_REDUCE(b2tt_ctime);
            b2tt_ctime_iq <= b2tt_ctime_i;
            status_fake_iq <= status_fake_i;
            control_fake_iq <= control_fake_i;
            -- keep signals from being synthesized away
            status_vec_i <= OR_REDUCE(status_regs(0)) & OR_REDUCE(status_regs(1));
            status_fake_i <= OR_REDUCE(status_vec_i);            
            ctrl_vec_i <= OR_REDUCE(ctrl_regs(0)) & OR_REDUCE(ctrl_regs(1));
            control_fake_i <= OR_REDUCE(ctrl_vec_i);                        
        end if;
    end process;

end behave;
