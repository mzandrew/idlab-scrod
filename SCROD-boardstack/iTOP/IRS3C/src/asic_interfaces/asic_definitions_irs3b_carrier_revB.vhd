--
--	Definitions for how the ASIC signals are distributed on 
-- the SCROD boardstack 
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

package asic_definitions_irs3b_carrier_revB is
	-------------General definitions-------------------------
	--Number of rows and columns, each site corresponding to one ASIC
	constant ASICS_PER_ROW      : integer := 4;
	constant ROW_SELECT_BITS    : integer := 2;
	constant ROWS_PER_COL       : integer := 4;
	constant COL_SELECT_BITS    : integer := 2;
	constant CH_SELECT_BITS     : integer := 3;
	constant CHANNELS_PER_ASIC  : integer := 8;
	constant SAMPLE_SELECT_BITS : integer := 6;
	constant ANALOG_MEMORY_ADDRESS_BITS : integer := 9;
	-------------Trigger related-----------------------------
	--Number of trigger channels per ASIC
	constant TRIGGER_CHANNELS_PER_ASIC : integer := 8;
	constant TOTAL_TRIGGER_BITS        : integer := ASICS_PER_ROW*ROWS_PER_COL*TRIGGER_CHANNELS_PER_ASIC;
	constant TOTAL_TRIGGER_BIT_WIDTH   : integer := 7;
	--Memory space for the trigger bits
	--Right now divided into half-windows, so one extra bit beyond the analog memory space
	constant TRIGGER_MEMORY_ADDRESS_BITS : integer := ANALOG_MEMORY_ADDRESS_BITS+1;
	--Data types for trigger bits
	subtype  TRIGGER_BITS is std_logic_vector(TRIGGER_CHANNELS_PER_ASIC-1 downto 0);
	type ROW_TRIGGER_BITS is array(ROWS_PER_COL-1 downto 0) of TRIGGER_BITS;
	type COL_ROW_TRIGGER_BITS is array(ASICS_PER_ROW-1 downto 0) of ROW_TRIGGER_BITS;
	-------------Trigger scalers-----------------------------
	--Clock rate that runs the trigger blocks
	constant TRIGGER_CLOCK_RATE            : real := 50000000.0;
	--Clock rate for the clock that defines the integration period (in Hz?)
	constant TRIGGER_INTEGRATION_FREQUENCY : real := 10.0;
	--Bit width for the scalers
	constant TRIGGER_SCALER_BIT_WIDTH      : integer := 16;
	--Data type for one asic's worth of trigger scalers
	type ASIC_TRIGGER_SCALERS is array(TRIGGER_CHANNELS_PER_ASIC-1 downto 0) of std_logic_vector(TRIGGER_SCALER_BIT_WIDTH-1 downto 0);	
	-------------Feedback/monitoring related-----------------
	--Generic 16-bit counter types
	subtype Counter is std_logic_vector(15 downto 0);
	type Row_Counters is array(ROWS_PER_COL-1 downto 0) of Counter;
	type Column_Row_Counters is array(ASICS_PER_ROW-1 downto 0) of Row_Counters;
--	--Wilkinson monitor counter count values
--	subtype Wilkinson_Counter is Column_Row_Counters;
--	--Sampling rate (RCO) monitor counter values
--	subtype Sampling_Rate_Counter is Column_Row_Counters;
	constant WILKINSON_INTEGRATION_FREQUENCY : real := 10.0;
	constant RCO_INTEGRATION_FREQUENCY       : real := 600.0;

	--Enables for the various feedbacks (1 bit per asic)
	type Row_Enables is array(ROWS_PER_COL-1 downto 0) of std_logic;
	type Column_Row_Enables is array(ASICS_PER_ROW-1 downto 0) of Row_Enables;
	-------------Sampling and analog storage related---------
	subtype ASIC_SST_C is std_logic_vector(ASICS_PER_ROW-1 downto 0);
	-------------Digitization related------------------------
	subtype ASIC_START_C is std_logic_vector(ASICS_PER_ROW-1 downto 0);
	constant SAMPLES_PER_WINDOW : integer := 64;
	constant WAVEFORMS_PER_PACKET : integer := 1;
	-------------Readout related-----------------------------
	type ASIC_DATA_C is array(ASICS_PER_ROW-1 downto 0) of std_logic_vector(11 downto 0);
	--Maximum number of waveform windows allowed per event
	constant MAXIMUM_SEGMENTS_PER_EVENT : integer := 512;
	constant SEGMENT_COUNTER_BITS       : integer := integer(ceil(log2(real(MAXIMUM_SEGMENTS_PER_EVENT+1))));

end asic_definitions_irs3b_carrier_revB;

package body asic_definitions_irs3b_carrier_revB is
--Nothing in the body (yet) 
end asic_definitions_irs3b_carrier_revB;
