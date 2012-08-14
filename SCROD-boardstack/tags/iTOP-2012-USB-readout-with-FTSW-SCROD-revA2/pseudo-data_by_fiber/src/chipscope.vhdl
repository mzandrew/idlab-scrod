-- 2011-09 mza
-----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity chipscope is
	port (
		CLOCK       : in    std_logic;
		ILA_DATA    : in    std_logic_vector(255 downto 0);
		ILA_TRIGGER : in    std_logic_vector(255 downto 0);
		VIO_DISPLAY : in    std_logic_vector(255 downto 0);
		VIO_BUTTONS :   out std_logic_vector(255 downto 0)
	);
end chipscope;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

architecture behavioral of chipscope is
	component s6_vio
	port (
		control     : inout std_logic_vector(35 downto 0);
		clk         : in    std_logic;
		sync_in     : in    std_logic_vector(255 downto 0);
		sync_out    :   out std_logic_vector(255 downto 0)
	);
	end component;
	signal icon_to_vio           : std_logic_vector(35 downto 0);
	signal icon_to_ila           : std_logic_vector(35 downto 0);
	signal internal_CLOCK        : std_logic;
begin
--	chipscope1 : if USE_CHIPSCOPE = 1 generate
	internal_CLOCK <= CLOCK;
		chipscope_icon : entity work.s6_icon
		port map (
			control0 => icon_to_vio,
			control1 => icon_to_ila
		);

		chipscope_vio : s6_vio
		port map (
			control   => icon_to_vio,
			clk       => internal_CLOCK,
			sync_in   => VIO_DISPLAY,
			sync_out  => VIO_BUTTONS
		);

		chipscope_ila : entity work.s6_ila
		port map (
			control  => icon_to_ila,
			clk      => internal_CLOCK,
			data     => ILA_DATA,
			trig0    => ILA_TRIGGER,
			trig_out => open
		);
--	end generate chipscope1;

--	no_chipscope1 : if USE_CHIPSCOPE = 0 generate
--	end generate no_chipscope1;

end behavioral;
