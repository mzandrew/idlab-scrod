--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Board_Stack_Definitions is
	-- A single LTC2637 has 8 DAC channels, each 12 bits
	type LTC2637_Voltages is array(7 downto 0) of std_logic_vector(11 downto 0);
	-- There are 2 LTC2637 DACs per daughter card.
	type Daughter_Card_Voltages is array(1 downto 0) of LTC2637_Voltages;

	-- Add addresses for different DC's at different locations?

	-------------ASIC related items from here on down----------------------------------
	type R_C_signal is array(3 downto 0) of std_logic_vector(3 downto 0);
	type R_or_C_bus12 is array(3 downto 0) of std_logic_vector(11 downto 0);
	type R_or_C_bus8 is array(3 downto 0) of std_logic_vector(7 downto 0);
	type R_C_bus8 is array(3 downto 0) of R_or_C_bus8;
  
   type AsicInputs_for_Digitizing is record
		data_bus_channel_address 	: std_logic_vector(2 downto 0);
		data_bus_sample_address		: std_logic_vector(5 downto 0);
		data_bus_output_enable		: std_logic;
		data_bus_output_disable_R_C: R_C_signal;
		storage_to_wilk_address		: std_logic_vector(8 downto 0);
		storage_to_wilk_address_enable : std_logic;
		storage_to_wilk_enable		: std_logic;
		wilk_counter_reset			: std_logic;
		wilk_counter_start_C			: std_logic_vector(3 downto 0);
		wilk_ramp_active				: std_logic;
	end record;

	type AsicInputs_for_Sampling is record
		sampling_track_C				: std_logic_vector(3 downto 0);
		sampling_hold_C				: std_logic_vector(3 downto 0);
		sampling_to_storage_address: std_logic_vector(8 downto 0);
		sampling_to_storage_address_enable : std_logic;
		sampling_to_storage_transfer_C : std_logic_vector(3 downto 0);	
	end record;

	type AsicInputs_for_Monitoring is record
		monitor_trig					: std_logic;
		monitor_wilk_counter_reset : std_logic;
		monitor_wilk_counter_start : std_logic;
	end record;
	
	type AsicInputs_for_Triggering is record
		trig_on_rising_edge			: std_logic;
	end record;

	type AsicOutputs_for_Triggering is record
		trigger_bits_R_C				: R_C_bus8;
	end record;	
	
	type AsicOutputs_for_Monitoring is record
		monitor_trig_R_C				: R_C_signal;
		monitor_wilk_counter_R_C	: R_C_signal;
		monitor_sampling_track_R_C	: R_C_signal;
	end record;
	
	type AsicOutputs_for_Digitizing is record
		data_bus_C						: R_or_C_bus12;
	end record;
  
end Board_Stack_Definitions;

--package body Board_Stack_Definitions is
--
--end package body;