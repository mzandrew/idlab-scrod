----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:16:54 02/15/2013 
-- Design Name: 
-- Module Name:    update_SMPSELANY_GPIO - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity update_SMPSELANY_GPIO is
		port(
		CLOCK											: in std_logic;
		DO_RESET_SMPSEL							:  in std_logic; --LM: start GPIO to reset SMPSEL_ANY
		DO_SET_SMPSEL								:  in std_logic; --LM: start GPIO to set SMPSEL_ANY
--		DO_READ_TEMP								: in std_logic; -- LM: read temperature sensor #1
		ENABLE_SET 									: in std_logic;
		SELECT_CARRIER 							: in std_logic;
		FORCE_ADDRESS_ASIC_LOW				: in std_logic_vector(2 downto 0);
		FORCE_ADDRESS_CHANNEL				: in std_logic_vector(2 downto 0);
		smpsel_done									:  out std_logic; 
		GPIO_CAL_SCL									:  out std_logic; 
--		GPIO_CAL_SDA									:  inout std_logic; -- externally controlling the SDA interface
		GPIO_CAL_SDA									:  out std_logic;
--		GPIO_CAL_SDA_force_out						:  out std_logic;
--		SDA_in											: in std_logic;
		TEMPERATURE										: out std_logic_vector(15 downto 0)
			);
end update_SMPSELANY_GPIO;

architecture Behavioral of update_SMPSELANY_GPIO is
signal counter : std_logic_vector(7 downto 0) := (others=>'0');
--constant ADDRESS : std_logic_vector(31 downto 0) := X"0FFFFF00";
--constant ALL_ZEROS : std_logic_vector(31 downto 0) := X"00000000";
--constant INITIAL_OUTPUTS : std_logic_vector(31 downto 0) := X"0000F000"; -- writes 1 only in CAL_EN to decouple channel 1 from amps
--constant COMM_CONF : std_logic_vector(31 downto 0) := X"000000FF";
--constant COMM_WRITE : std_logic_vector(31 downto 0) := X"0000000F";
--constant POS_SEL_ANY : std_logic_vector(31 downto 0) := X"0F000000";
--constant POS_CALS : std_logic_vector(31 downto 0) := X"0000FFFF";
--constant SCL_COMPLETE : std_logic_vector(115 downto 0) := X"CCCCCCCCCCCCCCCCCCCCCCCCCCCCF";
--signal POS_OUTPUTS : std_logic_vector(31 downto 0) := X"F0FF0000" ;

constant ADDRESS_0 : std_logic_vector(15 downto 0) := X"3FF0";
constant ADDRESS_1 : std_logic_vector(15 downto 0) := X"3F30";




constant ALL_ZEROS : std_logic_vector(15 downto 0) := X"0000";
constant INITIAL_OUTPUTS : std_logic_vector(15 downto 0) := X"0FC0"; -- writes 1 only in CAL_EN to decouple channel 1 from amps
constant COMM_CONF : std_logic_vector(15 downto 0) := X"000F";
constant COMM_WRITE : std_logic_vector(15 downto 0) := X"0003";
constant POS_SEL_ANY : std_logic_vector(15 downto 0) := X"3000";
constant POS_CALS : std_logic_vector(15 downto 0) := X"0FFF";
constant SCL_COMPLETE : std_logic_vector(59 downto 0) := X"EAAAAAAAAAAAAAB";
constant POS_OUTPUTS : std_logic_vector(15 downto 0) := X"C000" ;


constant ADDRESS_TEMP : std_logic_vector(15 downto 0) := X"C330";
constant ADDRESS_TEMP_R : std_logic_vector(15 downto 0) := X"C333";
constant TEMP_REG_HIGH : std_logic_vector(15 downto 0) := X"0000";
constant TEMP_REG_LOW : std_logic_vector(15 downto 0) := X"000C";



signal SCL :  std_logic_vector(59 downto 0) := (others =>'1');
signal SDA :  std_logic_vector(59 downto 0) := (others =>'1');

signal period_counter :  std_logic_vector(7 downto 0) := (others =>'0'); -- counts 250 for 1/2 period

signal ADDRESS : std_logic_vector(15 downto 0);
 

signal set_preamble : std_logic := '0';
signal configured_0 : std_logic := '0';
signal configured_1 : std_logic := '0';
signal initial_reset_0 : std_logic := '0';
signal initial_reset_1 : std_logic := '0';
signal LEVEL_RESET_SEMPSEL : std_logic := '0';
signal LEVEL_SET_SEMPSEL : std_logic := '0';
signal LEVEL_READ_TEMP : std_logic := '0';

signal OUTPUTS : std_logic_vector(15 downto 0) := X"0FC0"; -- writes 1 only in CAL_EN to decouple channel 1 from amps


begin
--GPIO_CAL_SCL <= SCL(115);
--GPIO_CAL_SDA <= SDA(113);
GPIO_CAL_SCL <= SCL(59);
GPIO_CAL_SDA <= SDA(59);

ADDRESS <= ADDRESS_0 when SELECT_CARRIER = '0' else
           ADDRESS_1 ;
 
OUTPUTS <= X"0" & not FORCE_ADDRESS_ASIC_LOW(1) & not FORCE_ADDRESS_ASIC_LOW(1) & 
					not FORCE_ADDRESS_ASIC_LOW(0) & not FORCE_ADDRESS_ASIC_LOW(0) &
						"11" & FORCE_ADDRESS_CHANNEL(2) & FORCE_ADDRESS_CHANNEL(2) & FORCE_ADDRESS_CHANNEL(1) & FORCE_ADDRESS_CHANNEL(1) &
						FORCE_ADDRESS_CHANNEL(0) & FORCE_ADDRESS_CHANNEL(0);
process(CLOCK)
begin
if rising_edge(CLOCK) then
smpsel_done<='0';
	if configured_0 = '0' then
		if set_preamble = '0' then
--			SDA<= "100" & ADDRESS & "ZZZZ" & (POS_SEL_ANY or POS_CALS) & "ZZZZ" & POS_OUTPUTS & "ZZZZ" & "001";
			SDA<= "110" & ADDRESS_0 & "ZZ" & COMM_CONF & "ZZ" & POS_OUTPUTS & "ZZ" & "001";
			SCL<= SCL_COMPLETE;
			set_preamble <= '1';
		elsif(counter < 59 ) then
			if period_counter < 250 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others =>'0');
				counter<= counter +1;
--				SDA<=SDA(112 downto 0) & '1';
--				SCL<=SCL(114 downto 0) & '1';
				SDA<=SDA(58 downto 0) & '1';
				SCL<=SCL(58 downto 0) & '1';
			end if;
		else
			configured_0 <='1';
			set_preamble <= '0';
			counter <= (others =>'0');
			period_counter <= (others =>'0');
		end if;
	elsif configured_1 = '0' then
		if set_preamble = '0' then
--			SDA<= "100" & ADDRESS & "ZZZZ" & (POS_SEL_ANY or POS_CALS) & "ZZZZ" & POS_OUTPUTS & "ZZZZ" & "001";
			SDA<= "110" & ADDRESS_1 & "ZZ" & COMM_CONF & "ZZ" & POS_OUTPUTS & "ZZ" & "001";
			SCL<= SCL_COMPLETE;
			set_preamble <= '1';
		elsif(counter < 59 ) then
			if period_counter < 250 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others =>'0');
				counter<= counter +1;
--				SDA<=SDA(112 downto 0) & '1';
--				SCL<=SCL(114 downto 0) & '1';
				SDA<=SDA(58 downto 0) & '1';
				SCL<=SCL(58 downto 0) & '1';
			end if;
		else
			configured_1 <='1';
			set_preamble <= '0';
			counter <= (others =>'0');
			period_counter <= (others =>'0');
		end if;
	elsif initial_reset_0 = '0' then
		if set_preamble = '0' then
--			SDA<= "100" & ADDRESS & "ZZZZ" & COMM_WRITE & "ZZZZ" & INITIAL_OUTPUTS & "ZZZZ" & "001"; -- writing all zeros forces all outputs to be 0 
																																  -- but CAL_EN = reset SMPSELANY, SELECT CAL to CH0 to
																																  -- decouple from the output of the amp

			SDA<= "110" & ADDRESS_0 & "ZZ" & COMM_WRITE & "ZZ" & OUTPUTS & "ZZ" & "001"; -- writing all zeros forces all outputs to be 0 
																																  -- but CAL_EN = reset SMPSELANY, SELECT CAL to CH0 to
																																  -- decouple from the output of the amp
			SCL<= SCL_COMPLETE;
			set_preamble <= '1';
		elsif(counter < 59 ) then
			if period_counter < 250 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others =>'0');
				counter<= counter +1;
--				SDA<=SDA(112 downto 0) & '1';
--				SCL<=SCL(114 downto 0) & '1';
				SDA<=SDA(58 downto 0) & '1';
				SCL<=SCL(58 downto 0) & '1';
			end if;
		else
			initial_reset_0 <='1';
			set_preamble <= '0';
			counter <= (others =>'0');
			period_counter <= (others =>'0');
		end if;
	elsif initial_reset_1 = '0' then
		if set_preamble = '0' then
--			SDA<= "100" & ADDRESS & "ZZZZ" & COMM_WRITE & "ZZZZ" & INITIAL_OUTPUTS & "ZZZZ" & "001"; -- writing all zeros forces all outputs to be 0 
																																  -- but CAL_EN = reset SMPSELANY, SELECT CAL to CH0 to
																																  -- decouple from the output of the amp

			SDA<= "110" & ADDRESS_0 & "ZZ" & COMM_WRITE & "ZZ" & OUTPUTS & "ZZ" & "001"; -- writing all zeros forces all outputs to be 0 
																																  -- but CAL_EN = reset SMPSELANY, SELECT CAL to CH0 to
																																  -- decouple from the output of the amp
			SCL<= SCL_COMPLETE;
			set_preamble <= '1';
		elsif(counter < 59 ) then
			if period_counter < 250 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others =>'0');
				counter<= counter +1;
--				SDA<=SDA(112 downto 0) & '1';
--				SCL<=SCL(114 downto 0) & '1';
				SDA<=SDA(58 downto 0) & '1';
				SCL<=SCL(58 downto 0) & '1';
			end if;
		else
			initial_reset_1 <='1';
			set_preamble <= '0';
			counter <= (others =>'0');
			period_counter <= (others =>'0');
		end if;	
	elsif DO_RESET_SMPSEL = '1' then
		LEVEL_RESET_SEMPSEL <= '1';
	elsif LEVEL_RESET_SEMPSEL = '1' then
		if set_preamble = '0' then
--			SDA<= "100" & ADDRESS & "ZZZZ" & COMM_WRITE & "ZZZZ" & INITIAL_OUTPUTS & "ZZZZ" & "001"; -- writing all zeros forces all outputs to be 0 = reset
			SDA<= "110" & ADDRESS & "ZZ" & COMM_WRITE & "ZZ" & OUTPUTS & "ZZ" & "001"; -- writing all zeros forces all outputs to be 0 = reset
			SCL<= SCL_COMPLETE;
			set_preamble <= '1';
		elsif(counter < 59 ) then
			if period_counter < 250 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others =>'0');			
				counter<= counter +1;
--				SDA<=SDA(112 downto 0) & '1';
--				SCL<=SCL(114 downto 0) & '1';
				SDA<=SDA(58 downto 0) & '1';
				SCL<=SCL(58 downto 0) & '1';
			end if;
		else
			initial_reset_0 <='1';
			initial_reset_1 <='1';
			set_preamble <= '0';
			counter <= (others =>'0');
			period_counter <= (others =>'0');
			smpsel_done<='1';
			LEVEL_RESET_SEMPSEL <= '0';
		end if;	
	elsif DO_SET_SMPSEL = '1' and ENABLE_SET = '1' then
		LEVEL_SET_SEMPSEL <= '1';
	elsif LEVEL_SET_SEMPSEL = '1' then
		if set_preamble = '0' then
--			SDA<= "100" & ADDRESS & "ZZZZ" & COMM_WRITE & "ZZZZ" & (POS_SEL_ANY or INITIAL_OUTPUTS) & "ZZZZ" & "001"; -- writing all zeros but in SMPSEL forces 1 on SMPSEL = set
			SDA<= "110" & ADDRESS & "ZZ" & COMM_WRITE & "ZZ" & (POS_SEL_ANY or OUTPUTS) & "ZZ" & "001"; -- writing all zeros but in SMPSEL forces 1 on SMPSEL = set
			SCL<= SCL_COMPLETE;
			set_preamble <= '1';
		elsif(counter < 59 ) then
			if period_counter < 250 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others =>'0');		counter<= counter +1;
--				SDA<=SDA(112 downto 0) & '1';
--				SCL<=SCL(114 downto 0) & '1';
				SDA<=SDA(58 downto 0) & '1';
				SCL<=SCL(58 downto 0) & '1';
			end if;
		else
			initial_reset_0 <='1';
			initial_reset_1 <='1';
			set_preamble <= '0';
			counter <= (others =>'0');
			period_counter <= (others =>'0');
			smpsel_done<='1';
			LEVEL_SET_SEMPSEL <= '0';
		end if;		
--	elsif DO_READ_TEMP = '1' then
--		LEVEL_READ_TEMP <= '1';
--	elsif LEVEL_READ_TEMP = '1' then
--		if set_preamble = '0' then
--			SDA<= "110" & ADDRESS_TEMP & "ZZ" & TEMP_REG_HIGH & "ZZ" & ADDRESS_TEMP_R & "11111";
--		
--			SCL<= SCL_COMPLETE;
--			set_preamble <= '1';
--		elsif(counter < 59 ) then
--			if period_counter < 250 then
--				period_counter <= period_counter + 1;
--			else
--				period_counter <= (others =>'0');		counter<= counter +1;
----				SDA<=SDA(112 downto 0) & '1';
----				SCL<=SCL(114 downto 0) & '1';
--				SDA<=SDA(58 downto 0) & '1';
--				SCL<=SCL(58 downto 0) & '1';
--			end if;
--		elsif(counter = 59) then
--			SDA<=	"ZZ" & "ZZZZZZZZZZZZZZZZ"  & "11" & "0011" & X"FFFFFFFFF"; 
--			SCL<= SCL_COMPLETE;
--			counter<= counter +1; 
--		elsif(counter < 59+23+1 ) then
--			if period_counter < 250 then
--				period_counter <= period_counter + 1;
--				if  period_counter = 120 then TEMPERATURE<= TEMPERATURE(14 downto 0) & SDA_in; end if;
--			else
--				period_counter <= (others =>'0');		counter<= counter +1;
----				SDA<=SDA(112 downto 0) & '1';
----				SCL<=SCL(114 downto 0) & '1';
--				
--				SDA<=SDA(58 downto 0) & '1';
--				SCL<=SCL(58 downto 0) & '1';
--			end if;
--		else
--			initial_reset <='1';
--			set_preamble <= '0';
--			counter <= (others =>'0');
--			period_counter <= (others =>'0');
--			smpsel_done<='1';
--			LEVEL_SET_SEMPSEL <= '0';
--		end if;	
	end if;
end if;
end process;


end Behavioral;

