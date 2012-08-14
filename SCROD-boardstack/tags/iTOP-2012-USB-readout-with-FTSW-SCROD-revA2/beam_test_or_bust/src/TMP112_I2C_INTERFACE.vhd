----------------------------------------------------------------------------------
-- Company:
-- Engineer: 
-- 
-- Create Date:    09:42:22 07/07/2011 
-- Design Name: 
-- Module Name:    TMP112_I2C_INTERFACE - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 	Read 12-bit temperature data from TMP112. 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--		2011-09-29: This code was written by Xiaowen earlier this year and tested
--                on the Spartan-3 eval.  It has not been tested yet on our board
--                stack.  Attempting integration for the first time now.  -KN
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--===============================================================
entity TMP112_I2C_INTERFACE is
	port (
			CLK						: IN			STD_LOGIC;
			READ_NOW					: IN			STD_LOGIC;
			ADDRESS					: IN			STD_LOGIC_VECTOR(1 downto 0);
			
			SCL						: OUT			STD_LOGIC;
			SDA						: INOUT		STD_LOGIC;
			
			LAST_TEMP_READ			: OUT			STD_LOGIC_VECTOR(11 DOWNTO 0)
			);
end TMP112_I2C_INTERFACE;
--================================================================


architecture Behavioral of TMP112_I2C_INTERFACE is

--------------------------------------SIGNAL DECLEARATION-------------------------------------------------------
	type IIC_TMP112_STATE_TYPE is 
		(	st_start,			st_check_state,		st_send_data_byte,		
			st_wait_for_ack,	st_read_data_byte,
			st_send_ack,		st_stop,							st_idle
		);

	signal state      						: IIC_TMP112_STATE_TYPE := st_idle;

	
	signal bit_counter,  toggle_counter	: integer := 0;
	signal send_data_step_counter, read_data_step_counter : integer := 0;
	
	signal to_send_data_byte				: std_logic_vector(7 downto 0) := x"00";
	signal to_read_data_byte				: std_logic_vector(7 downto 0) := x"00";
	signal temp_reading						: std_logic_vector(15 downto 0):= x"0000";
	
	signal is_register_address_sent 		: std_logic := '0';
	
	signal step_counter						: unsigned(1 downto 0) 	:= "00";
	
	
----------------------------------------------------------------------------------------------------------------

begin
	
	process(CLK)
	BEGIN
		IF rising_edge(CLK) THEN

			-------------------------CASE START-----------------------------------------------------
			CASE state IS
				--------------------------------------------------------------------------------
				when st_start =>
					if (step_counter = 0) then
						SCL <= '0';
						step_counter <= step_counter + 1;
					elsif (step_counter = 1) then
						SDA <= '1';
						step_counter <= step_counter + 1;
					elsif (step_counter = 2) then
						SCL <= '1';
						step_counter <= step_counter + 1;
					else
						SDA <= '0';
						step_counter <= "00";
						state <= st_check_state;
					end if;	
					
				--------------------------------------------------------------------------------
				when st_check_state =>
					if (is_register_address_sent = '0') then     --write data to sensor register
						if (send_data_step_counter = 0) then		--need to locate the given address sensor
							to_send_data_byte(7 downto 0) <= "10010"&ADDRESS(1 downto 0)&"0";  --R/^W (1/0)  write to TMP112 at the 'ADDRESS'
							state <= st_send_data_byte;
						elsif (send_data_step_counter = 1) then	--sensor address was sent. 
							to_send_data_byte(7 downto 0) <= x"00";  --sent the register address --"00" which is the temp. register
							state <= st_send_data_byte;
						elsif (send_data_step_counter >= 2) then
							is_register_address_sent <= '1';
							send_data_step_counter <= 0;
							state <= st_stop;
						end if;
					else	--is_register_address_sent = '1'			--read data from sensor
						if (send_data_step_counter = 0) then
							to_send_data_byte(7 downto 0) <= "10010"&ADDRESS(1 downto 0)&"1";  --R/^W (1/0)  read from TMP112 at the 'ADDRESS'
							state <= st_send_data_byte;
						elsif (send_data_step_counter = 1) then			--after the sensor is located
							if (read_data_step_counter = 0) then
								state <= st_read_data_byte;
							elsif (read_data_step_counter = 1) then		--1st byte was read
								temp_reading(15 downto 8) <= to_read_data_byte(7 downto 0);
								state <= st_read_data_byte;
							elsif (read_data_step_counter = 2) then		--2nd byte was read
								temp_reading(7 downto 0) <= to_read_data_byte(7 downto 0);
								read_data_step_counter <= read_data_step_counter + 1;
							else
								LAST_TEMP_READ(11 downto 0) <= temp_reading(15 downto 4);  --update the output after 2 bytes are read successfully.
								state <= st_stop;
								read_data_step_counter <= 0;
								send_data_step_counter <= 0;		--after 2 bytes are read, need to relocate the sensor for the next reading.
							end if;
							
							
						end if;
					end if;
				--------------------------------------------------------------------------------

				--------------------------------------------------------------------------------
				when st_send_data_byte =>   
					if bit_counter <= 7 then   
						if step_counter = 0 then 
							SCL <= '0';
							step_counter <= step_counter + 1;
						elsif step_counter = 1 then
							SDA <= to_send_data_byte(7 - bit_counter);
							step_counter <= step_counter + 1;
						elsif step_counter = 2 then
							SCL <= '1';
							bit_counter <= bit_counter + 1;
							step_counter <= "00";
						end if;
					else   --after all data are sent
						state <= st_wait_for_ack;
						bit_counter <= 0;
					end if;
					
				--------------------------------------------------------------------------------
				when st_wait_for_ack =>
					if step_counter = 0 then
						SCL <= '0';
						step_counter <= step_counter + 1;
					elsif step_counter = 1 then
						SDA <= 'Z';
						step_counter <= step_counter + 1;
					elsif step_counter = 2 then
						SCL <= '1';
						step_counter <= step_counter + 1;
					elsif step_counter = 3 then
						if SDA = '0' then
							state <= st_check_state;
							step_counter <= "00";
							send_data_step_counter <= send_data_step_counter + 1;
						else --SDA = '1';  -- if not receiving ack then wait
							state <= st_wait_for_ack;
							toggle_counter <= toggle_counter + 1;

							if toggle_counter >= 10 then
								state <= st_idle;
								toggle_counter <= 0;
								step_counter <= "00";
								send_data_step_counter <= 0;
							end if;
						 end if;
					 end if;
					
					
				-----------------------------------------------------------------------------
				when st_read_data_byte =>
					if bit_counter <= 7 then   
						if step_counter = 0 then 
							SCL <= '0';
							step_counter <= step_counter + 1;
						elsif step_counter = 1 then
							step_counter <= step_counter + 1;
						elsif step_counter = 2 then
							SCL <= '1';
							step_counter <= step_counter + 1;
						elsif step_counter = 3 then
							to_read_data_byte(7 - bit_counter) <= SDA;  
							bit_counter <= bit_counter + 1;
							step_counter <= "00";
						end if;
					else   --after 1 byte is read
						state <= st_send_ack;
						bit_counter <= 0;
					end if;
				
				
				-----------------------------------------------------------------
				when st_send_ack =>
					if (step_counter = 0) then
						SCL <= '0';
						step_counter <= step_counter + 1;
					elsif (step_counter = 1) then
						SDA <= '0';  			 --sending the ack to the sensor
						step_counter <= step_counter + 1;
					elsif (step_counter = 2) then
						SCL <= '1';
						step_counter <= step_counter + 1;
					elsif (step_counter = 3) then
						SCL <= '0';
						SDA <= 'Z';				 --release the SDA wire for the sensor
						step_counter <= "00";
						read_data_step_counter <= read_data_step_counter + 1;
						state <= st_check_state;
					end if;
					
				-----------------------------------------------------------------
				when st_stop =>
					if 	step_counter = 0 then
						SCL <= '0';
						step_counter <= step_counter + 1;
					elsif step_counter = 1 then
						SDA <= '0';
						step_counter <= step_counter + 1;
					elsif step_counter = 2 then
						SCL <= '1';
						step_counter <= step_counter + 1;
					else
						SDA <= '1';
						step_counter <= "00";
						
						if (is_register_address_sent = '0') then
							state <= st_start;
						else
							state <= st_idle;
						end if;
						
						
					end if;

				-----------------------------------------------------------------
				when st_idle =>
					SCL <= '1';
               SDA <= '1';
 
               bit_counter <= 0;
					send_data_step_counter <= 0;
					read_data_step_counter <= 0;
					---------------------------------------------------------------------------------------------
					--is_register_address_sent <= '0';  -- uncomment it if needed to repeat the whole process automatically. 
																	--Otherwise it needs 'READ_NOW' to be '1' to run. 
																	--Register address is stored in the sensor. 
																	--It will directly read from the register addressed earlier next time.
					---------------------------------------------------------------------------------------------
               if (READ_NOW = '1') then						                                      
                  state <= st_start;
               end if;
					
				-----------------------------------------------------------------
				when others =>
					state <= st_idle;
	
			END CASE;
			-------------------------------------------------------------------------

			
			
		END IF;
	END PROCESS;

end Behavioral;
--================================================================
