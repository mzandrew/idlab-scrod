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
-- DATE : 25 JUNE 2007																			--
-- Project name: ROBUSTv3 firmware															--
--	Module name: DAC_SERIALIZER  																--
--	Description : 																					--
-- 	DAC serialization module																--
--		  											    												--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DAC_SERIALIZER is
   port ( 
		xCLK_10MHz	: in  std_logic;
		xUPDATE   	: in    std_logic;
		xDAC_A 		: in    std_logic_vector (15 downto 0);
		xDAC_B 		: in    std_logic_vector (15 downto 0);
		xDAC_C 		: in    std_logic_vector (15 downto 0);
		xDAC_D 		: in    std_logic_vector (15 downto 0);
		xNSYNC		: out   std_logic;
		xD_OUT	 	: out   std_logic);	
end DAC_SERIALIZER;

architecture Behavioral of DAC_SERIALIZER is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	type STATE_TYPE is ( IDLE,DATA_XFER,WAIT_XFER);
	signal STATE 		   : STATE_TYPE;
	signal D_OUT			: std_logic := '1';
	signal NSYNC			: std_logic := '1';
	signal DATA				: std_logic_vector(15 downto 0);	
	signal CH_CNT			: std_logic_vector(1 downto 0);	
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component BUF
      port ( I  : in    std_logic;  
             O  : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	xBUF_D_OUT : BUF
	port map (
		I  	=> D_OUT,
		O		=> xD_OUT);	
--------------------------------------------------------------------------------	
	xBUF_NSYNC : BUF
	port map (
		I  	=> NSYNC,
		O		=> xNSYNC);	
--------------------------------------------------------------------------------	
	process(CH_CNT,xDAC_A,xDAC_B,xDAC_C,xDAC_D)
	begin
		if CH_CNT = 0 then
			DATA <= xDAC_A;
		elsif CH_CNT = 1 then
			DATA <= xDAC_B;
		elsif CH_CNT = 2 then
			DATA <= xDAC_C;
		elsif CH_CNT = 3 then
			DATA <= xDAC_D;
		end if;
	end process;
--------------------------------------------------------------------------------	
	process(xCLK_10MHz)
	variable i : integer range 15 downto 0;
	begin
		if rising_edge(xCLK_10MHz) then
--------------------------------------------------------------------------------			
			case STATE is
--------------------------------------------------------------------------------	
				when IDLE =>			
					NSYNC <= '1';
					D_OUT <= '1';
					i := 15;
					CH_CNT <= "00";
					if xUPDATE = '0' then
						STATE <= DATA_XFER;
					end if;
--------------------------------------------------------------------------------	
				when DATA_XFER =>			
					D_OUT <= DATA(i);
					NSYNC <= '0';
					i := i - 1;
					if i = 0 then
						i := 4;
						CH_CNT <= CH_CNT + 1;
						STATE <= WAIT_XFER;
					end if;
--------------------------------------------------------------------------------	
				when WAIT_XFER =>			
					D_OUT <= '1';
					NSYNC <= '1';
					i := i - 1;
					if CH_CNT = 0 then
						if xUPDATE = '1' then
							STATE <= IDLE;
						end if;	
					elsif i = 0 then
						i := 15;
						STATE <= DATA_XFER;
					end if;					
--------------------------------------------------------------------------------	
				when others =>	STATE<=IDLE;																
			end case;
		end if;
	end process;	
--------------------------------------------------------------------------------
end Behavioral;