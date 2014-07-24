
-- VHDL Instantiation Created from source file klm_aurora.vhd -- 16:51:08 06/06/2014
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
	COMPONENT klm_aurora
	PORT(
		TX_D : IN std_logic_vector(0 to 15);
		TX_REM : IN std_logic;
		TX_SRC_RDY_N : IN std_logic;
		TX_SOF_N : IN std_logic;
		TX_EOF_N : IN std_logic;
		RXP : IN std_logic;
		RXN : IN std_logic;
		GTPD2 : IN std_logic;
		WARN_CC : IN std_logic;
		DO_CC : IN std_logic;
		USER_CLK : IN std_logic;
		SYNC_CLK : IN std_logic;
		RESET : IN std_logic;
		POWER_DOWN : IN std_logic;
		LOOPBACK : IN std_logic_vector(2 downto 0);
		GT_RESET : IN std_logic;
		RXEQMIX_IN : IN std_logic_vector(1 downto 0);
		DADDR_IN : IN std_logic_vector(7 downto 0);
		DCLK_IN : IN std_logic;
		DEN_IN : IN std_logic;
		DI_IN : IN std_logic_vector(15 downto 0);
		DWE_IN : IN std_logic;          
		TX_DST_RDY_N : OUT std_logic;
		RX_D : OUT std_logic_vector(0 to 15);
		RX_REM : OUT std_logic;
		RX_SRC_RDY_N : OUT std_logic;
		RX_SOF_N : OUT std_logic;
		RX_EOF_N : OUT std_logic;
		TXP : OUT std_logic;
		TXN : OUT std_logic;
		HARD_ERR : OUT std_logic;
		SOFT_ERR : OUT std_logic;
		FRAME_ERR : OUT std_logic;
		CHANNEL_UP : OUT std_logic;
		LANE_UP : OUT std_logic;
		GTPCLKOUT : OUT std_logic;
		DRDY_OUT : OUT std_logic;
		DRPDO_OUT : OUT std_logic_vector(15 downto 0);
		TX_LOCK : OUT std_logic
		);
	END COMPONENT;

-- COMP_TAG_END ------ End COMPONENT Declaration ------------
-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.
------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
	Inst_klm_aurora: klm_aurora PORT MAP(
		TX_D => ,
		TX_REM => ,
		TX_SRC_RDY_N => ,
		TX_SOF_N => ,
		TX_EOF_N => ,
		TX_DST_RDY_N => ,
		RX_D => ,
		RX_REM => ,
		RX_SRC_RDY_N => ,
		RX_SOF_N => ,
		RX_EOF_N => ,
		RXP => ,
		RXN => ,
		TXP => ,
		TXN => ,
		GTPD2 => ,
		HARD_ERR => ,
		SOFT_ERR => ,
		FRAME_ERR => ,
		CHANNEL_UP => ,
		LANE_UP => ,
		WARN_CC => ,
		DO_CC => ,
		USER_CLK => ,
		SYNC_CLK => ,
		RESET => ,
		POWER_DOWN => ,
		LOOPBACK => ,
		GT_RESET => ,
		GTPCLKOUT => ,
		RXEQMIX_IN => ,
		DADDR_IN => ,
		DCLK_IN => ,
		DEN_IN => ,
		DI_IN => ,
		DRDY_OUT => ,
		DRPDO_OUT => ,
		DWE_IN => ,
		TX_LOCK => 
	);



-- INST_TAG_END ------ End INSTANTIATION Template ------------

-- You must compile the wrapper file klm_aurora.vhd when simulating
-- the core, klm_aurora. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".
