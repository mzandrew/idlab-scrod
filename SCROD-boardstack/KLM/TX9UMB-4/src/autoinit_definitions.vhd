--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package autoinit_definitions is

 constant scrodpre_len : integer :=3;
 type scrodpre is array (0 to scrodpre_len-1) of std_logic_vector(23 downto 0);
 constant init_scrodpre : scrodpre:= (x"050080",x"060140",x"000000");
 
 	constant INIT_CNT1_MAX: integer:=1000000;
	constant WAIT_CNT1_MAX: integer:=1000000;-- wait between regs this long 

  constant scrodpost_len : integer :=35;
  type scrodpost is array (0 to scrodpost_len-1) of std_logic_vector(23 downto 0);
 constant init_scrodpost : scrodpost:= (
 x"140000",
 x"1E0000",
 x"1F0000",
 x"320000",
 x"2C0000",
 x"2D0001",
 x"2D0000",
 x"3303FF",
 x"340000",
 x"350000",
 x"360004",
 x"370001",
 x"370000",
 x"380000",
 x"390004",
 x"3A0000",
 x"4803FF",
 x"3D0F00",
 x"260000",
 x"260800",
 x"260000",
 x"2630A0",
 x"270000",
 x"0B8001",
 x"0A0000",
 x"0A0001",
 x"0A0000",
 x"3E0000",
 x"460000",
 x"470000",
 x"470001",
 x"470000",
 x"460001",
 x"27C1FF",
 x"007FFF"
 );


 constant asic_trig_threshold:std_logic_vector(15 downto 0):=x"0BB8"; --is 3000 decimal

 constant asicregs_len : integer :=63;
	type asicregs is array (0 to asicregs_len-1) of std_logic_vector(23 downto 0);
 constant init_asicregs : asicregs:=(
 x"00" & asic_trig_threshold,
 x"02" & asic_trig_threshold,
 x"04" & asic_trig_threshold,
 x"06" & asic_trig_threshold,
 x"08" & asic_trig_threshold,
 x"0A" & asic_trig_threshold,
 x"0C" & asic_trig_threshold,
 x"0E" & asic_trig_threshold,
 x"10" & asic_trig_threshold,
 x"12" & asic_trig_threshold,
 x"14" & asic_trig_threshold,
 x"16" & asic_trig_threshold,
 x"18" & asic_trig_threshold,
 x"1A" & asic_trig_threshold,
 x"1C" & asic_trig_threshold,
 x"1E" & asic_trig_threshold,
 x"01" & x"03D9",
 x"03" & x"03D9",
 x"05" & x"03D9",
 x"07" & x"03D9",
 x"09" & x"03D9",
 x"0B" & x"03D9",
 x"0D" & x"03D9",
 x"0F" & x"03D9",
 x"11" & x"03D9",
 x"13" & x"03D9",
 x"15" & x"03D9",
 x"17" & x"03D9",
 x"19" & x"03D9",
 x"1B" & x"03D9",
 x"1D" & x"03D9",
 x"1F" & x"03D9",

 x"30" & x"0514",
 x"31" & x"0000",
 x"32" & x"0A5A",
 x"33" & x"044C",
 x"34" & x"05DC",
 x"35" & x"0426",
 x"36" & x"0DAC",
 x"37" & x"0000",
 x"38" & x"0480",
 x"39" & x"0000",
 x"3A" & x"08BB",
 x"3B" & x"0000",
 x"3D" & x"04A6",
 x"3E" & x"044C",
 x"3F" & x"044C",
 x"40" & x"008F",
 x"41" & x"00A3",
 x"42" & x"000D",
 x"43" & x"0021",
 x"44" & x"0014",
 x"45" & x"0028",
 x"46" & x"0021",
 x"47" & x"0035",
 x"48" & x"0038",
 x"49" & x"000C",
 x"4A" & x"0028",
 x"4B" & x"003A",
 x"4C" & x"02E1",
 x"4D" & x"0C28",
 x"4E" & x"0480",
 x"4F" & x"0AAA"

 );
 
 
 


-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end autoinit_definitions;

package body autoinit_definitions is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end autoinit_definitions;
