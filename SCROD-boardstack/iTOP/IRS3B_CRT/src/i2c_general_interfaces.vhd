----------------------------------------------------------------------------------
-- Simple block to add some hierarchy and instantiate all general I2C interfaces
-- in a single place.  
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
package i2c_types is
	constant N_I2C_BUSES : integer := 8;
	type i2c_rw_registers is array(7 downto 0) of std_logic_vector(15 downto 0);
	type i2c_bytes        is array(7 downto 0) of std_logic_vector( 7 downto 0);
end i2c_types;
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.i2c_types.all;

entity i2c_general_interfaces is
	Port ( 
		CLOCK           : in    STD_LOGIC;
		CLOCK_ENABLE    : in    STD_LOGIC;
		I2C_SCL_LINES   : inout STD_LOGIC_VECTOR (N_I2C_BUSES-1 downto 0);
		I2C_SDA_LINES   : inout STD_LOGIC_VECTOR (N_I2C_BUSES-1 downto 0);
		WRITE_REGISTERS : in    i2c_rw_registers;
		READ_REGISTERS  : out   i2c_rw_registers
	);
end i2c_general_interfaces;

architecture Behavioral of i2c_general_interfaces is
	signal internal_I2C_BYTE_TO_SEND     : i2c_bytes;
	signal internal_I2C_SEND_START       : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_SEND_BYTE        : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_READ_BYTE        : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_SEND_ACKNOWLEDGE : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_SEND_STOP        : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_ACKNOWLEDGED     : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_BUSY             : std_logic_vector(N_I2C_BUSES-1 downto 0);
	signal internal_I2C_BYTE_RECEIVED    : i2c_bytes;
begin
	i2c_interface_n : for i in 0 to N_I2C_BUSES-1 generate
		--This defines the mapping of bits for write registers connected to I2C general interfaces
		internal_I2C_BYTE_TO_SEND(i)     <= WRITE_REGISTERS(i)(7 downto 0);
		internal_I2C_SEND_START(i)       <= WRITE_REGISTERS(i)(8);
		internal_I2C_SEND_BYTE(i)        <= WRITE_REGISTERS(i)(9);
		internal_I2C_READ_BYTE(i)        <= WRITE_REGISTERS(i)(10);
		internal_I2C_SEND_ACKNOWLEDGE(i) <= WRITE_REGISTERS(i)(11);
		internal_I2C_SEND_STOP(i)        <= WRITE_REGISTERS(i)(12);
		--This defines the mapping of bits for read registers connected to I2C general interfaces
		READ_REGISTERS(i) <= internal_I2C_ACKNOWLEDGED(i) & internal_I2C_BUSY(i) & "000000" & internal_I2C_BYTE_RECEIVED(i);
		--Instantiate the actual I2C interface block
		i2c_interface_bus : entity work.i2c_master
		port map(
			I2C_BYTE_TO_SEND  => internal_I2C_BYTE_TO_SEND(i),
			I2C_BYTE_RECEIVED => internal_I2C_BYTE_RECEIVED(i),
			ACKNOWLEDGED      => internal_I2C_ACKNOWLEDGED(i),
			SEND_START        => internal_I2C_SEND_START(i),
			SEND_BYTE         => internal_I2C_SEND_BYTE(i),
			READ_BYTE         => internal_I2C_READ_BYTE(i),
			SEND_ACKNOWLEDGE  => internal_I2C_SEND_ACKNOWLEDGE(i),
			SEND_STOP         => internal_I2C_SEND_STOP(i),
			BUSY              => internal_I2C_BUSY(i),
			CLOCK             => CLOCK,
			CLOCK_ENABLE      => CLOCK_ENABLE,
			SCL               => I2C_SCL_LINES(i),
			SDA               => I2C_SDA_LINES(i)
		);
	end generate;

end Behavioral;

