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

entity USB_IO is
   PORT( IFCLK	:	IN	STD_LOGIC; 
          PA2	:	OUT	STD_LOGIC; 
          xSLOE	:	IN	STD_LOGIC; 
          PA4	:	OUT	STD_LOGIC; 
          PA5	:	OUT	STD_LOGIC; 
          PA6	:	OUT	STD_LOGIC; 
          xFIFOADR0	:	IN	STD_LOGIC; 
          xFIFOADR1	:	IN	STD_LOGIC; 
          xPKTEND	:	IN	STD_LOGIC; 
          RDY1	:	OUT	STD_LOGIC; 
          xSLWR	:	IN	STD_LOGIC; 
          RDY0	:	OUT	STD_LOGIC; 
          xSLRD	:	IN	STD_LOGIC; 
          WAKEUP	:	IN	STD_LOGIC; 
          CTL2	:	IN	STD_LOGIC; 
          CTL1	:	IN	STD_LOGIC; 
          CTL0	:	IN	STD_LOGIC; 
          PA7	:	IN	STD_LOGIC; 
          PA3	:	IN	STD_LOGIC; 
          PA1	:	IN	STD_LOGIC; 
          PA0	:	IN	STD_LOGIC; 
          CLKOUT	:	IN	STD_LOGIC; 
          xTOGGLE	:	IN	STD_LOGIC; 
          xDATA_OUT	:	IN	STD_LOGIC_VECTOR (15 DOWNTO 0); 
          FD	:	INOUT	STD_LOGIC_VECTOR (15 DOWNTO 0); 
          xUSB_DATA	:	OUT	STD_LOGIC_VECTOR (15 DOWNTO 0); 
          xIFCLK	:	OUT	STD_LOGIC; 
          xFLAGA	:	OUT	STD_LOGIC; 
          xFLAGB	:	OUT	STD_LOGIC; 
          xFLAGC	:	OUT	STD_LOGIC; 
          xWAKEUP	:	OUT	STD_LOGIC);
end USB_IO; 

architecture Behavioral of USB_IO is
   attribute BOX_TYPE   : string ;
--------------------------------------------------------------------------------
--   								signals		     		   						         --
--------------------------------------------------------------------------------
	signal xCTL0	: std_logic;
	signal xCTL1	: std_logic;
	signal xCTL2	: std_logic;
	signal IFCLK_BUFF		: std_logic;
	signal WAKEUP_BUFF		: std_logic;
--------------------------------------------------------------------------------
--   								components     		   						         --
--------------------------------------------------------------------------------
   component IBUFG
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUFG : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component IBUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of IBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUFG
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUFG : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component BUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of BUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------
   component OBUF
      port ( I : in    std_logic; 
             O : out   std_logic);
   end component;
   attribute BOX_TYPE of OBUF : component is "BLACK_BOX";
--------------------------------------------------------------------------------	
	component IOBUF_BUS
	generic(bus_width : integer := 16);
	PORT( 
		I  : in    STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
		IO : inout STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      O  : out   STD_LOGIC_VECTOR((bus_width-1) DOWNTO 0); 
      T  : in    std_logic);
	end component;
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	xIOBUF_BUS : IOBUF_BUS
	generic map(bus_width => 16)
	port map(
		I	=> xDATA_OUT,
      IO	=> FD,
      O	=> xUSB_DATA,
      T	=> xTOGGLE);	
--------------------------------------------------------------------------------
	xIBUF_PA0 : IBUF 
	port map (
		I  => PA0,
		O  => open);
--------------------------------------------------------------------------------		
	xIBUF_PA1 : IBUF 
	port map (
		I  => PA1,
		O  => open);
--------------------------------------------------------------------------------		
	xOBUF_PA2 : OBUF 
	port map (
		I  => xSLOE,
		O  => PA2);
--------------------------------------------------------------------------------		
	xIBUF_PA3 : IBUF 
	port map (
		I  => PA3,
		O  => open);		
--------------------------------------------------------------------------------		
	xOBUF_PA4 : OBUF 
	port map (
		I  => xFIFOADR0,
		O  => PA4);		
--------------------------------------------------------------------------------		
	xOBUF_PA5 : OBUF 
	port map (
		I  => xFIFOADR1,
		O  => PA5);	
--------------------------------------------------------------------------------		
	xOBUF_PA6 : OBUF 
	port map (
		I  => xPKTEND,
		O  => PA6);	
--------------------------------------------------------------------------------		
	xIBUF_PA7 : IBUF 
	port map (
		I  => PA7,
		O  => open);	
--------------------------------------------------------------------------------		
	xIBUF_CTL0 : IBUF 
	port map (
		I  => CTL0,
		O  => xCTL0);	
--------------------------------------------------------------------------------		
	xIBUF_CTL1 : IBUF 
	port map (
		I  => CTL1,
		O  => xCTL1);	
--------------------------------------------------------------------------------		
	xIBUF_CTL2 : IBUF 
	port map (
		I  => CTL2,
		O  => xCTL2);	
--------------------------------------------------------------------------------		
	xBUF_CTL0 : BUF 
	port map (
		I  => xCTL0,
		O  => xFLAGA);	
--------------------------------------------------------------------------------		
	xBUF_CTL1 : BUF 
	port map (
		I  => xCTL1,
		O  => xFLAGB);	
--------------------------------------------------------------------------------		
	xBUF_CTL2 : BUF 
	port map (
		I  => xCTL2,
		O  => xFLAGC);	
--------------------------------------------------------------------------------		
	xIBUF_IFCLK : IBUF
	port map (
		I  => IFCLK,
		O  => IFCLK_BUFF);	
--------------------------------------------------------------------------------		
	xBUFG_IFCLK : BUFG 
	port map (
		I  => IFCLK_BUFF,
		O  => xIFCLK);	
--------------------------------------------------------------------------------		
	xIBUF_WAKEUP : IBUF
	port map (
		I  => WAKEUP,
		O  => WAKEUP_BUFF);	
--------------------------------------------------------------------------------		
	xBUF_WAKEUP : BUF 
	port map (
		I  => WAKEUP_BUFF,
		O  => xWAKEUP);	
--------------------------------------------------------------------------------		
	xIBUF_CLKOUT : IBUF 
	port map (
		I  => CLKOUT,
		O  => open);	
--------------------------------------------------------------------------------		
	xOBUF_RDY0 : OBUF 
	port map (
		I  => xSLRD,
		O  => RDY0);	
--------------------------------------------------------------------------------		
	xOBUF_RDY1 : OBUF 
	port map (
		I  => xSLWR,
		O  => RDY1);		
--------------------------------------------------------------------------------	
end Behavioral;