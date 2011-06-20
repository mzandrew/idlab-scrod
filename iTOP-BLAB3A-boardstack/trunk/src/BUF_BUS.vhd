--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--								University of Hawaii at Manoa						         --
--						Instrumentation Development Lab / GARY S. VARNER				--
--   								Watanabe Hall Room 214								      --
--  								  2505 Correa Road										   --
--  								 Honolulu, HI 96822											--
--  								Lab: (808) 956-2920											--
--	 								Fax: (808) 956-2930										   --
--  						E-mail: idlab@phys.hawaii.edu									   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------	
-- Design by: Larry L. Ruckman Jr.															--
-- DATE : 23 JUNE 2009																			--
-- Project name: ICRR firmware																--
--	Module name: Aurora_TOP				  														--
--	Description : 																					--
-- 	Aurora Top Level																			--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity BUF_BUS is
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
end BUF_BUS; 

architecture Behavioral of BUF_BUS is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	BUFFER_GEN : for a in (bus_width-1) downto 0 generate
		xBUF : BUF 
		port map (
			I	=> I(a),
         O	=> O(a));		
	end generate BUFFER_GEN;	
--------------------------------------------------------------------------------	
end Behavioral;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity OBUF_BUS is
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
end OBUF_BUS; 

architecture Behavioral of OBUF_BUS is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component OBUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of OBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	BUFFER_GEN : for a in (bus_width-1) downto 0 generate
		xOBUF : OBUF 
		port map(
			I	=> I(a),
         O	=> O(a));		
	end generate BUFFER_GEN;	
--------------------------------------------------------------------------------	
end Behavioral;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IBUF_BUS is
	generic(bus_width : integer := 16);
	PORT( 
		I : IN  STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O : OUT STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0));
end IBUF_BUS; 

architecture Behavioral of IBUF_BUS is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xWIRE : STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component IBUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	BUFFER_GEN : for a in (bus_width-1) downto 0 generate
		xIBUF : IBUF 
		port map(
			I	=> I(a),
         O	=> xWIRE(a));	
		xBUF : BUF 
		port map(
			I	=> xWIRE(a),
         O	=> O(a));				
	end generate BUFFER_GEN;	
--------------------------------------------------------------------------------	
end Behavioral;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IOBUF_BUS is
	generic(bus_width : integer := 16);
	PORT( 
		I  : in    STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
		IO : inout STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O  : out   STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      T  : in    std_logic);
end IOBUF_BUS; 

architecture Behavioral of IOBUF_BUS is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xWIRE : STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------	
	component IOBUF
   port( 
		I  : in    std_logic; 
		IO : inout std_logic; 
      O  : out   std_logic; 
      T  : in    std_logic);
	end component;
   attribute BOX_TYPE of IOBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	BUFFER_GEN : for a in (bus_width-1) downto 0 generate
		xIOBUF : IOBUF 
		port map(
			I	=> I(a),
         T	=> T,
         O	=> xWIRE(a),
         IO	=> IO(a));
		xBUF : BUF 
		port map(
			I	=> xWIRE(a),
         O	=> O(a));				
	end generate BUFFER_GEN;	
--------------------------------------------------------------------------------	
end Behavioral;