" Line 1240: <internal_dig_sr_busy> is not declared.
" Line 1245: <srasicx> is not declared.
d" Line 1245: Actual of formal out port srax cannot be an expression
" Line 1246: <srasicy> is not declared.
d" Line 1246: Actual of formal out port sray cannot be an expression
" Line 1247: <ro_win_start_i> is not declared.
d" Line 1247: Actual of formal out port ro_win_start cannot be an expression
" Line 1249: <readout_busy_i> is not declared.
d" Line 1249: Actual of formal out port ro_busy cannot be an expression
" Line 1250: <dig_sr_start_i> is not declared.
d" Line 1250: Actual of formal out port dig_sr_start cannot be an expression
" Line 1260: <clk> is not declared.
" Line 1261: <dig_sr_start_i> is not declared.
" Line 1262: <ro_win_start_i> is not declared.
" Line 1264: <srasicy> is not declared.
" Line 1265: <internal_dig_sr_busy> is not declared.
d" Line 1265: Actual of formal out port busy cannot be an expression
" Line 1267: <busb_dig_rd_ena_i> is not declared.
d" Line 1267: Actual of formal out port dig_rd_ena cannot be an expression


signal asicy_dig_sr_busy_i:std_logic:='0';
signal asicx_dig_sr_busy_i:std_logic:='0';
signal srasicx_i:std_logic_vector(2 downto 0):="000";
signal srasicy_i:std_logic_vector(2 downto 0):="000";

signal ro_win_start_i:std_logic_vector(8 downto 0);
signal READOUT_BUSY_i:std_logic;
signal dig_sr_start_i:std_logic;
signal busb_dig_rd_ena_i:std_logic;




	signal BUSA_DIG_RD_ENA_i:std_logic;
	signal BUSA_cur_ro_win_i:std_logic_vector(8 downto 0);	
	signal BUSA_DIG_CLR_i:std_logic;
	signal BUSA_DIG_RAMP_i:std_logic;

	signal BUSB_DIG_RD_ENA_i:std_logic;
	signal BUSB_cur_ro_win_i:std_logic_vector(8 downto 0);	
	signal BUSB_DIG_CLR_i:std_logic;
	signal BUSB_DIG_RAMP_i:std_logic;

	
	--make serial readout bus signals identical
	signal BUSA_SAMPLESEL_i:std_logic_vector(4 downto 0);
	signal BUSA_SR_SEL_i:std_logic;
	signal BUSA_SR_CLR_i:std_logic;
	signal BUSB_SAMPLESEL_i:std_logic_vector(4 downto 0);
	signal BUSB_SR_SEL_i:std_logic;
	signal BUSB_SR_CLR_i:std_logic;
	
	
	--Serial readout DO signal switches between buses based on internal_READCTRL_ASIC_NUM signal
	signal BUSA_dout_i:std_logic_vector(15 downto 0);
	signal BUSB_dout_i:std_logic_vector(15 downto 0);
	
	
	
	
	
	
		internal_TRIGDEC_asic_enable_bits(4 downto 0)<= "00000" when (internal_TRIGDEC_ax="000") else
														"00001" when (internal_TRIGDEC_ax="001") else
														"00010" when (internal_TRIGDEC_ax="010") else
														"00100" when (internal_TRIGDEC_ax="011") else
														"01000" when (internal_TRIGDEC_ax="100") else
														"01000" when (internal_TRIGDEC_ax="101") else
														"00000";
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	