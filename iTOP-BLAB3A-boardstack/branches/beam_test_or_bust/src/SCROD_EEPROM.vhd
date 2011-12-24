----------------------------------------------------------------------------------
-- Create Date:    17:35:00 08/27/2011 
-- Module Name:    EEPROM_CHIPSCOPE_MODULE - Behavioral 
-- Target Devices: Tested with Spartan-3 eval board and Spartan-6 on SCROD
-- Description: 	Using Chipscope to write and read 16 bytes to EEPROM at any given address.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SCROD_EEPROM is
	generic(
		STRING_SIZE			: integer := 16	--# of bytes write and read at one time from chipscope.
		);
		
	port(
		CLK					: IN		STD_LOGIC;
		RESET					: IN		STD_LOGIC;
		SCL					: INOUT	STD_LOGIC;
		SDA					: INOUT	STD_LOGIC;
		ADDR					: IN		STD_LOGIC_VECTOR(12 downto 0); --13 bit Address (
		RD_EN					: IN		STD_LOGIC;
		WR_EN					: IN		STD_LOGIC;
		WR_DATA				: IN		STD_LOGIC_VECTOR(STRING_SIZE*8-1 downto 0);
		RD_DATA				: OUT		STD_LOGIC_VECTOR(STRING_SIZE*8-1 downto 0);
		DONE					: OUT		STD_LOGIC
		);
		
end SCROD_EEPROM;

architecture Behavioral of SCROD_EEPROM is
--=========================================================================================
	----------------------------------------------------------------------------------------
	COMPONENT EEPROM_I2C_INTERFACE is
	generic(
		CONSTANT PAGE_SIZE			: integer := 32
		);
	port(
		CLK			: IN	STD_LOGIC;
		ADDRESS		: IN	STD_LOGIC_VECTOR(12 DOWNTO 0);
		
		COMMAND							: IN		STD_LOGIC_VECTOR(2 DOWNTO 0);
	
		----------------------------------------------
		--total # of bytes to read from EEPROM
		--it will be the index of bytes when transfer out the data 
		NUM_OF_BYTES		: IN	STD_LOGIC_VECTOR(5 DOWNTO 0);	
		----------------------------------------------
		EXECUTE				: IN	STD_LOGIC;
		
		COMMAND_RUNNING	: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
		
		INDEX_OF_BYTES		: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);	--showing which byte is transferred out. MAX # OF BYTES => 2^5=32 BYTES
		DATA_OUT_BYTE		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		DATA_IN_BYTE		: IN		STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		SCL					: INOUT STD_LOGIC;
		SDA					: INOUT STD_LOGIC

			);
	end COMPONENT;

--===============================SIGNAL BEGIN=================================================================
	SIGNAL COMMAND_EEPROM					: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL ADDRESS_EEPROM					: STD_LOGIC_VECTOR(12 DOWNTO 0);
	SIGNAL NUM_OF_BYTES_EEPROM				: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL COMMAND_RUNNING_EEPROM			: STD_LOGIC_vector(2 downto 0);
	SIGNAL INDEX_OF_BYTES_EEPROM			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL EXECUTE_EEPROM					: STD_LOGIC := '0'; 
	SIGNAL SCL_EEPROM							: STD_LOGIC;
	SIGNAL SDA_EEPROM							: STD_LOGIC;
	signal DATA_OUT_BYTE_EEPROM			: std_logic_vector(7 downto 0);
	signal DATA_IN_BYTE_EEPROM				: STD_LOGIC_VECTOR(7 DOWNTO 0);

	---------------------------------------------------------------------------
	SIGNAL AUTO_READ	:	STD_LOGIC := '0';
	SIGNAL RD_EN_r		:	STD_LOGIC;
	SIGNAL WR_EN_r		:	STD_LOGIC;
	SIGNAL ADDR_r		: 	STD_LOGIC_VECTOR(12 downto 0);
	SIGNAL WR_DATA_r	:	STD_LOGIC_VECTOR(STRING_SIZE*8-1 downto 0);
	SIGNAL RD_DATA_r	:	STD_LOGIC_VECTOR(STRING_SIZE*8-1 downto 0);
	SIGNAL DONE_r		:	STD_LOGIC;
--===============================SIGNAL END=================================================================	

begin
--=================================================================================

	RD_EN_r <= RD_EN;
	WR_EN_r <= WR_EN;
	ADDR_r <= ADDR;
	WR_DATA_r <= WR_DATA;
	RD_DATA <= RD_DATA_r;
	DONE <= DONE_r;
	SCL <= SCL_EEPROM;
	SDA <= SDA_EEPROM;
	
	---------------------------------------------------------	
	EEPROMI2C		: EEPROM_I2C_INTERFACE
	port map (
		CLK			=> CLK,
		ADDRESS		=> ADDRESS_EEPROM,
		COMMAND		=> COMMAND_EEPROM,
		NUM_OF_BYTES		=>	NUM_OF_BYTES_EEPROM,
		
		EXECUTE				=> EXECUTE_EEPROM,
		
		COMMAND_RUNNING	=> COMMAND_RUNNING_EEPROM,
		INDEX_OF_BYTES		=> INDEX_OF_BYTES_EEPROM,
		DATA_OUT_BYTE		=> DATA_OUT_BYTE_EEPROM,
		DATA_IN_BYTE		=> DATA_IN_BYTE_EEPROM,
		
		SCL	=> SCL_EEPROM,
		SDA	=> SDA_EEPROM

		);
		

	process (CLK, RESET)
		--======================================================================
		-----------COMMAND FOR EEPROM_I2C_INTERFACE MODULE----------------
		CONSTANT CMD_CHECK_COMMAND			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
		CONSTANT CMD_SET_ADDRESS			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
		CONSTANT CMD_READ_EEPROM			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
		CONSTANT CMD_TRANSFER_READ_OUT	: STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		
		CONSTANT CMD_SAVE_DATA_BYTE				: STD_LOGIC_VECTOR(2 DOWNTO 0) := "001"; 
		CONSTANT CMD_WRITE_TO_EEPROM_BYTES		: STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
		CONSTANT CMD_RESET_BYTES_SAVED			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
	-----------------------------------------------------------------
	type DATA_BYTES_TYPE is array(0 TO STRING_SIZE - 1) of std_logic_vector(7 downto 0);
	
	variable bytes_to_write					: DATA_BYTES_TYPE := (OTHERS => x"20"); --default: "space"

	variable bytes_to_write_counter				: integer range 0 to STRING_SIZE := 0;
	
	variable bytes_after_read						: DATA_BYTES_TYPE;
	variable bytes_after_read_counter, i		: integer range 0 to STRING_SIZE := 0;
	
	variable counter, step_counter				:	integer range 0 to 15 := 0;
	variable  sub_step_counter						: integer range 0 to 7 := 0;
		--======================================================================
	BEGIN

		if RESET = '1' then
			AUTO_READ <= '1';
			DONE_r <= '0';
			step_counter := 0;
			sub_step_counter := 0;
			counter := 0;
		
		ELSIF RISING_EDGE(CLK) THEN

			--#############################
			IF EXECUTE_EEPROM = '1' THEN
				EXECUTE_EEPROM <= '0';			--RESET SIGNAL 'EXECUTE' TO '0'!
			END IF;
			--#############################

--			if RESET = '1' then
--				AUTO_READ <= '1';
--				DONE_r <= '0';
--				step_counter := 0;
--				sub_step_counter := 0;
--				counter := 0;
--			elsif AUTO_READ = '1' then
			if AUTO_READ = '1' then
			--------------Read after reset---------------
					if step_counter = 0 then
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
							ADDRESS_EEPROM <= x"000"&"0";
							COMMAND_EEPROM <= CMD_SET_ADDRESS;
							EXECUTE_EEPROM <= '1';
							step_counter := step_counter + 1;
						end if; 
					elsif step_counter = 1 then
						if COMMAND_RUNNING_EEPROM = CMD_SET_ADDRESS then
							step_counter := step_counter + 1;
						end if;
					elsif step_counter = 2 then
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
							NUM_OF_BYTES_EEPROM <= std_logic_vector(to_unsigned(STRING_SIZE, 6));		--READ 'STRING_SIZE' of BYTES
							COMMAND_EEPROM <= CMD_READ_EEPROM;
							EXECUTE_EEPROM <= '1';
							step_counter := step_counter + 1;
						end if; 
					elsif step_counter = 3 then
						if COMMAND_RUNNING_EEPROM = CMD_READ_EEPROM then
							step_counter := step_counter + 1;
						end if;
					
					elsif step_counter = 4 then
						if bytes_after_read_counter < STRING_SIZE then
							if sub_step_counter = 0  then
								if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
									NUM_OF_BYTES_EEPROM <= std_logic_vector(to_unsigned(bytes_after_read_counter, 6));
									COMMAND_EEPROM <= CMD_TRANSFER_READ_OUT;
									EXECUTE_EEPROM <= '1';
									sub_step_counter := sub_step_counter + 1;
								end if;
							elsif sub_step_counter = 1 then
								if COMMAND_RUNNING_EEPROM = CMD_TRANSFER_READ_OUT then
									sub_step_counter := sub_step_counter + 1;
								end if;
							
							else
								if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
									bytes_after_read(bytes_after_read_counter) := DATA_OUT_BYTE_EEPROM;
									bytes_after_read_counter := bytes_after_read_counter + 1;
									sub_step_counter := 0;
								end if;
							end if;
						else --after all bytes are transfered out
							bytes_after_read_counter := 0;
							step_counter := step_counter + 1;
						end if;
					else	--show the read-out on Chipscope
						for i in 0 to STRING_SIZE-1 loop
							RD_DATA_r(7+8*i downto 0+8*i) <= bytes_after_read(i);
						end loop;
						DONE_r <= '1';
						AUTO_READ <= '0';
					end if;
			else
				-------------------------Read---------------------------------------------------------	
				if RD_EN_r = '1' and WR_EN_r /= '1' then	--'Read' signal from Chipscope
					if step_counter = 0 then
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
							ADDRESS_EEPROM <= ADDR_r;
							COMMAND_EEPROM <= CMD_SET_ADDRESS;
							EXECUTE_EEPROM <= '1';
							step_counter := step_counter + 1;
						end if; 
					elsif step_counter = 1 then
						if COMMAND_RUNNING_EEPROM = CMD_SET_ADDRESS then
							step_counter := step_counter + 1;
						end if;
					elsif step_counter = 2 then
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
							NUM_OF_BYTES_EEPROM <= std_logic_vector(to_unsigned(STRING_SIZE, 6));		--READ 'STRING_SIZE' of BYTES
							COMMAND_EEPROM <= CMD_READ_EEPROM;
							EXECUTE_EEPROM <= '1';
							step_counter := step_counter + 1;
						end if; 
					elsif step_counter = 3 then
						if COMMAND_RUNNING_EEPROM = CMD_READ_EEPROM then
							step_counter := step_counter + 1;
						end if;
					
					elsif step_counter = 4 then
						if bytes_after_read_counter < STRING_SIZE then
							if sub_step_counter = 0  then
								if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
									NUM_OF_BYTES_EEPROM <= std_logic_vector(to_unsigned(bytes_after_read_counter, 6));
									COMMAND_EEPROM <= CMD_TRANSFER_READ_OUT;
									EXECUTE_EEPROM <= '1';
									sub_step_counter := sub_step_counter + 1;
								end if;
							elsif sub_step_counter = 1 then
								if COMMAND_RUNNING_EEPROM = CMD_TRANSFER_READ_OUT then
									sub_step_counter := sub_step_counter + 1;
								end if;
							
							else
								if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
									bytes_after_read(bytes_after_read_counter) := DATA_OUT_BYTE_EEPROM;
									bytes_after_read_counter := bytes_after_read_counter + 1;
									sub_step_counter := 0;
								end if;
							end if;
						else --after all bytes are transfered out
							bytes_after_read_counter := 0;
							step_counter := step_counter + 1;
						end if;
					else	--show the read-out on Chipscope
						for i in 0 to STRING_SIZE-1 loop
							RD_DATA_r(7+8*i downto 0+8*i) <= bytes_after_read(i);
						end loop;
						DONE_r <= '1';
					end if;
				
					
				------------------------Write Part---------------------------------------------------------		
				elsif RD_EN_r /= '1' and WR_EN_r = '1' then	--when 'Write' signal from Chipscope is 'on'
					for i in 0 to STRING_SIZE-1 loop
						bytes_to_write(i) := WR_DATA_r(7+8*i downto 0+8*i);
					end loop;	
					if counter = 0 then
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
							COMMAND_EEPROM <= CMD_RESET_BYTES_SAVED;	--clear bytes saved
							EXECUTE_EEPROM <= '1';
							counter := counter + 1;
						end if;
					elsif counter = 1 then
						if COMMAND_RUNNING_EEPROM = CMD_RESET_BYTES_SAVED then	
							counter := counter + 1;
						end if;
					elsif counter = 2 then	--transfer all the data in the array.
						if bytes_to_write_counter < STRING_SIZE then
							if step_counter = 0 then
								if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then	
									DATA_IN_BYTE_EEPROM <= bytes_to_write(bytes_to_write_counter);
									COMMAND_EEPROM <= CMD_SAVE_DATA_BYTE;	--SAVE THE BYTE
									EXECUTE_EEPROM <= '1';
									step_counter := step_counter + 1;
								end if;
							elsif step_counter = 1 then
								if COMMAND_RUNNING_EEPROM = CMD_SAVE_DATA_BYTE then
									bytes_to_write_counter := bytes_to_write_counter + 1;
									step_counter := 0;
								end if;
							end if;
						else	--all bytes are sent to EEPROM_I2C_INTERFACE module
							bytes_to_write_counter := 0;
							counter := counter + 1;
						end if;
					elsif counter = 3 then
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then		
							ADDRESS_EEPROM <= ADDR_r;
							COMMAND_EEPROM <= CMD_WRITE_TO_EEPROM_BYTES;	--WRITE DATA TO EEPROM
							EXECUTE_EEPROM <= '1';
							counter := counter + 1;
						end if;
					elsif counter = 4 then					
						if COMMAND_RUNNING_EEPROM = CMD_WRITE_TO_EEPROM_BYTES then		
							counter := counter + 1;
						end if;
					else 
						if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then	
							DONE_r <= '1';
						end if;
					end if;
				else --clear all the counters, and ready for the next operation.			
					counter := 0;
					step_counter := 0;
					sub_step_counter := 0;
					DONE_r <= '0';
				end if;
			end if;	--if RESET
		END IF;
	END PROCESS;
--=================================================================================
end Behavioral;

