----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:59:48 11/08/2014 
-- Design Name: 
-- Module Name:    TrigDecisionLogic - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
 use work.tdc_pkg.all;


entity TrigDecisionLogic is
    Port ( 
			  tb : in  tb_vec_type;
			  tm : in std_logic_vector(10 downto 1);-- mask
           TrigOut : out  STD_LOGIC;
           asicX : out  STD_LOGIC_VECTOR (2 downto 0):="000";
           asicY : out  STD_LOGIC_VECTOR (2 downto 0):="000"
			  );
			  
end TrigDecisionLogic;

architecture Behavioral of TrigDecisionLogic is
signal Xtb : std_logic_vector(5 downto 1):="00000";
signal Ytb : std_logic_vector(5 downto 1):="00000";
signal trg:std_logic:='0';
signal asicX_i :  STD_LOGIC_VECTOR (2 downto 0):="000";
signal asicY_i :  STD_LOGIC_VECTOR (2 downto 0):="000";


begin

Xtb(1)<=(tb(1)(1) or tb(1)(2) or tb(1)(3) or tb(1)(4) or tb(1)(5)) and tm(1);
Xtb(2)<=(tb(2)(1) or tb(2)(2) or tb(2)(3) or tb(2)(4) or tb(2)(5)) and tm(2);
Xtb(3)<=(tb(3)(1) or tb(3)(2) or tb(3)(3) or tb(3)(4) or tb(3)(5)) and tm(3);
Xtb(4)<=(tb(4)(1) or tb(4)(2) or tb(4)(3) or tb(4)(4) or tb(4)(5)) and tm(4);
Xtb(5)<=(tb(5)(1) or tb(5)(2) or tb(5)(3) or tb(5)(4) or tb(5)(5)) and tm(5);

Ytb(1)<=(tb(6 )(1) or tb(6 )(2) or tb(6 )(3) or tb(6 )(4) or tb(6 )(5)) and tm(6);
Ytb(2)<=(tb(7 )(1) or tb(7 )(2) or tb(7 )(3) or tb(7 )(4) or tb(7 )(5)) and tm(7);
Ytb(3)<=(tb(8 )(1) or tb(8 )(2) or tb(8 )(3) or tb(8 )(4) or tb(8 )(5)) and tm(8);
Ytb(4)<=(tb(9 )(1) or tb(9 )(2) or tb(9 )(3) or tb(9 )(4) or tb(9 )(5)) and tm(9);
Ytb(5)<=(tb(10)(1) or tb(10)(2) or tb(10)(3) or tb(10)(4) or tb(10)(5)) and tm(10);

trg<= (Xtb(1) or Xtb(2) or Xtb(3) or Xtb(4) or Xtb(5) )  and (Ytb(1) or Ytb(2) or Ytb(3) or Ytb(4) or Ytb(5) );

asicX_i<="001" when (Xtb(1 downto 1)="1"    )	   else
			"010" when (Xtb(2 downto 1)="10"   ) 		else 
			"011" when (Xtb(3 downto 1)="100"  )     else 
			"100" when (Xtb(4 downto 1)="1000" )     else 
			"101" when (Xtb(5 downto 1)="10000")     else
			"000";
asicY_i<="001" when (Ytb(1 downto 1)="1"    )	   else
			"010" when (Ytb(2 downto 1)="10"   ) 		else 
			"011" when (Ytb(3 downto 1)="100"  )     else 
			"100" when (Ytb(4 downto 1)="1000" )     else 
			"101" when (Ytb(5 downto 1)="10000") 		else
			"000";

TrigOut<=trg;

process( trg)
begin
if (rising_edge(trg)) then

asicX<=asicX_i;
asicY<=asicY_i;



end if;

   
end process;


end Behavioral;

