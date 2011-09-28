-- 2011-09 mza
-----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity trigger is
	port (
		RESET                                    : in    std_logic;
		CLOCK_1MHz                               : in    std_logic;
		CLOCK_1kHz                               : in    std_logic;
		external_trigger_from_monitor_header     : in    std_logic;
		external_simple_trigger_from_LVDS        : in    std_logic;
		external_encoded_trigger_from_LVDS       : in    std_logic;
		transmit_always                          : in    std_logic;
		fake_spill_structure_enable              : in    std_logic;
		external_trigger_disable                 : in    std_logic;
		FAKE_SPILL_ACTIVE                        :   out std_logic;
		raw_fake_trigger                         :   out std_logic;
		TRIGGER                                  :   out std_logic;
		TRIGGER_ACKNOWLEDGE                      : in    std_logic
	);
end trigger;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

architecture behavioral of trigger is
	signal raw_500Hz_fake_trigger                   : std_logic := '0';
	signal raw_100Hz_fake_trigger                   : std_logic := '0';
	signal raw_5Hz_fake_trigger                     : std_logic := '0';
	signal internal_raw_fake_trigger                : std_logic;
	signal external_triggers_ORed_together          : std_logic;
	signal gated_trigger                            : std_logic;
	signal gated_fill_inactive                      : std_logic;
	signal pulsed_trigger                           : std_logic;
	signal trigger_a_digitization_and_readout_event : std_logic;
	signal trigger_accepted                         : std_logic;
	signal spill_active                             : std_logic;
	signal fill_active                              : std_logic;
-----------------------------------------------------------------------------
begin
-----------------------------------------------------------------------------
	process (CLOCK_1MHz, RESET)
		variable trigger_acknowledge_counter : integer range 0 to 100 := 0;
	begin
		if (RESET = '1') then
			trigger_accepted <= '0';
			trigger_acknowledge_counter := 0;
		elsif rising_edge(CLOCK_1MHz) then
			if (TRIGGER_ACKNOWLEDGE = '1') then
				if (trigger_acknowledge_counter < 30) then
					trigger_accepted <= '1';
					trigger_acknowledge_counter := trigger_acknowledge_counter + 1;
				else
					trigger_accepted <= '0';
				end if;
			else
				trigger_accepted <= '0';
				trigger_acknowledge_counter := 0;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
	process(CLOCK_1kHz, RESET)
		variable counter_1_kHz    : integer range 0 to 10 := 0;
		variable counter_200_Hz   : integer range 0 to 10 := 0;
		variable counter_100_Hz   : integer range 0 to 10 := 0;
		variable counter_10_Hz    : integer range 0 to 10 := 0;
		variable counter_1_Hz     : integer range 0 to 3600 := 0;
		variable spill_counter         : integer range 0 to 60 := 1;
		constant spill_counter_maximum : integer range 0 to 60 := 2;
		variable fill_counter          : integer range 0 to 60 := 1;
		constant fill_counter_maximum  : integer range 0 to 60 := 4;
	begin
		if (RESET = '1') then
			spill_active <= '1';
			fill_active  <= '0';
			counter_1_kHz   := 0;
			counter_200_Hz  := 0;
			counter_100_Hz  := 0;
			counter_10_Hz   := 0;
			counter_1_Hz    := 0;
			spill_counter   := 1;
			fill_counter    := 1;
			raw_5Hz_fake_trigger   <= '0';
			raw_100Hz_fake_trigger <= '0';
			raw_500Hz_fake_trigger <= '0';
		elsif rising_edge(CLOCK_1kHz) then
			-- evaluated once per millisecond
			counter_1_kHz := counter_1_kHz + 1;
			if (counter_1_kHz > 4) then
				-- evaluated 200 times per second
				counter_1_kHz := 0;
				counter_200_Hz := counter_200_Hz + 1;
				raw_100Hz_fake_trigger <= not raw_100Hz_fake_trigger;
			end if;
			if (counter_200_Hz > 1) then
				-- evaluated 100 times per second
				counter_200_Hz := 0;
				counter_100_Hz := counter_100_Hz + 1;
			end if;
			if (counter_100_Hz > 9) then
				-- evaluated 10 times per second
				counter_100_Hz := 0;
				counter_10_Hz := counter_10_Hz + 1;
				raw_5Hz_fake_trigger <= not raw_5Hz_fake_trigger;
			end if;
--				raw_25Hz_fake_trigger <= not raw_25Hz_fake_trigger;
			if (counter_10_Hz > 9) then
				-- evaluated once per second
--				if (fiber_link_is_up = '0') then
--					pulsed_fiber_link_is_down = '1';
--					request_an_aurora_reset = '1';
--				end if;
				counter_10_Hz := 0;
				counter_1_Hz := counter_1_Hz + 1;
--				stupid_counter <= std_logic_vector(unsigned(stupid_counter) + 1);
				if (spill_counter < spill_counter_maximum) then
					spill_counter := spill_counter + 1;
				else
					spill_active <= '0';
					fill_active  <= '1';
					if (fill_counter < fill_counter_maximum) then
						fill_counter := fill_counter + 1;
					else
						spill_active <= '1';
						fill_active  <= '0';
						spill_counter := 1;
						fill_counter  := 1;
					end if;
				end if;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------
	process(external_trigger_disable)
	begin
		if (external_trigger_disable = '0') then
			gated_trigger <= external_triggers_ORed_together;
		else
			gated_trigger <= internal_raw_fake_trigger;
		end if;
	end process;
-----------------------------------------------------------------------------
	process (trigger_a_digitization_and_readout_event, transmit_always, trigger_accepted)
	begin
		if (trigger_accepted = '1') then
			pulsed_trigger <= '0';
		elsif (transmit_always = '1') then
			pulsed_trigger <= '1';
		elsif rising_edge(trigger_a_digitization_and_readout_event) then
			pulsed_trigger <= '1';
		end if;
	end process;
-----------------------------------------------------------------------------
	TRIGGER           <= pulsed_trigger;
	FAKE_SPILL_ACTIVE <= spill_active;
	raw_fake_trigger  <= internal_raw_fake_trigger;
	internal_raw_fake_trigger <= raw_5Hz_fake_trigger;
--	internal_trigger <= raw_5Hz_fake_trigger;
--	external_triggers_ORed_together <= external_trigger_1_from_monitor_header or external_trigger_2_from_LVDS;
	external_triggers_ORed_together <= external_simple_trigger_from_LVDS;
--	external_triggers_ORed_together <= external_trigger_from_monitor_header;
	gated_fill_inactive <= fake_spill_structure_enable nand fill_active;
	trigger_a_digitization_and_readout_event <= gated_fill_inactive and gated_trigger;
--	internal_PACKET_GENERATOR_ENABLE(1) <= '1';--trigger_a_digitization_and_readout_event or transmit_always;
--	internal_PACKET_GENERATOR_ENABLE(0) <= not transmit_disable;
--	trigger_a_digitization_and_readout_event
--	pulsed_trigger <= trigger_a_digitization_and_readout_event or transmit_always;
-----------------------------------------------------------------------------
end behavioral;
