----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:35:00 08/27/2011 
-- Design Name: 
-- Module Name:    test_top - Behavioral 
-- Project Name: 	
-- Target Devices: Spartan-6; 
-- Tool versions: 
-- Description: 	Using Chipscope to write and read 16 bytes to EEPROM at any given address.
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity test_top is
	generic(
		STRING_SIZE			: integer := 16	--# of bytes write and read at one time from chipscope.
		);
		
	port(
		bclk_250MHz_p		: IN		STD_LOGIC;
		bclk_250MHz_n		: IN		STD_LOGIC;
		SCL					: INOUT	STD_LOGIC;
		SDA					: INOUT	STD_LOGIC
		);
		
end test_top;

architecture Behavioral of test_top is
--========================================================================================
	--------------------CHIPSCOPE-----------------------------------------
	component ICON
		PORT (
			CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
			);

	end component;
	component VIO
		PORT (
			CONTROL 	: INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
			CLK 		: IN STD_LOGIC;
			SYNC_IN 	: IN STD_LOGIC_VECTOR(255 DOWNTO 0);
			SYNC_OUT : OUT STD_LOGIC_VECTOR(255 DOWNTO 0)
			);

	end component;

	---------------------------------------------------------------------------
	SIGNAL CLK_COUNTER					: UNSIGNED(21 DOWNTO 0) := x"00000"&"00";
		
	SIGNAL INTERNAL_CHIPSCOPE_CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	SIGNAL INTERNAL_CHIPSCOPE_VIO_IN : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL INTERNAL_CHIPSCOPE_VIO_OUT : STD_LOGIC_VECTOR(255 DOWNTO 0);
	
	SIGNAL CLK	: STD_LOGIC;
	--===============================SIGNAL END=================================================================	

begin
	--=================================================================================

	IBUFGDS_inst : IBUFGDS
	generic map (
		DIFF_TERM => TRUE, -- Differential Termination
		IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
		IOSTANDARD => "DEFAULT"
	)
	port map (
		O => CLK, -- Clock buffer output
		I => bclk_250MHz_p, -- Diff_p clock buffer input (connect directly to top-level port)
		IB => bclk_250MHz_n -- Diff_n clock buffer input (connect directly to top-level port)
	);

	--=========================================================================
	reduce_requency: PROCESS(CLK)
	BEGIN
		IF RISING_EDGE(CLK) THEN
			
			CLK_COUNTER <= CLK_COUNTER + 1;
			
		end if;
	END PROCESS reduce_requency;
	--=========================================================================
	
	---------------------------------------------------------
	CHIPSCOPE_ICON : ICON
	PORT MAP (
		CONTROL0 => INTERNAL_CHIPSCOPE_CONTROL
	 );

	CHIPSCOPE_VIO : VIO
	PORT MAP(
		CONTROL => INTERNAL_CHIPSCOPE_CONTROL,
		CLK => CLK_COUNTER(10),
		SYNC_IN => INTERNAL_CHIPSCOPE_VIO_IN,
		SYNC_OUT => INTERNAL_CHIPSCOPE_VIO_OUT
	 );
	---------------------------------------------------------

	eeprom : entity work.SCROD_EEPROM
	generic map(
		STRING_SIZE => STRING_SIZE	--# of bytes write and read at one time from chipscope.
	)
	port map(
		CLK => CLK_COUNTER(10),
		SCL => SCL,
		SDA => SDA,
		ADDR => INTERNAL_CHIPSCOPE_VIO_OUT(140 downto 128),
		RD_EN	=> INTERNAL_CHIPSCOPE_VIO_OUT(141),
		WR_EN	=> INTERNAL_CHIPSCOPE_VIO_OUT(142),
		WR_DATA => INTERNAL_CHIPSCOPE_VIO_OUT(127 downto 0),
		RD_DATA => INTERNAL_CHIPSCOPE_VIO_IN(127 downto 0),
		DONE => INTERNAL_CHIPSCOPE_VIO_IN(128)
	);
--		INTERNAL_CHIPSCOPE_VIO_IN(128) <= '1';
--=================================================================================
end Behavioral;

