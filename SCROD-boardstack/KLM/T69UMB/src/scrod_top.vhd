----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:20:38 10/25/2012 
-- Design Name: 
-- Module Name:    scrod_top - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;
--use work.asic_definitions_irs2_carrier_revA.all;
--use work.CarrierRevA_DAC_definitions.all;

entity scrod_top is
	Port(
		BOARD_CLOCKP                : in  STD_LOGIC;
		BOARD_CLOCKN                : in  STD_LOGIC;
		--LEDS                        : out STD_LOGIC_VECTOR(15 downto 0);
		------------------FTSW pins------------------
		RJ45_ACK_P                  : out std_logic;
		RJ45_ACK_N                  : out std_logic;			  
		RJ45_TRG_P                  : in std_logic;
		RJ45_TRG_N                  : in std_logic;			  			  
		RJ45_RSV_P                  : in std_logic;
		RJ45_RSV_N                  : in std_logic;
		RJ45_CLK_P                  : in std_logic;
		RJ45_CLK_N                  : in std_logic;
		---------Jumper for choosing FTSW clock------
		MONITOR_INPUT               : in  std_logic_vector(0 downto 0);
		
		----------------------------------------------
		------------Fiberoptic Pins-------------------
		----------------------------------------------
		FIBER_0_RXP                 : in  STD_LOGIC;
		FIBER_0_RXN                 : in  STD_LOGIC;
		FIBER_1_RXP                 : in  STD_LOGIC;
		FIBER_1_RXN                 : in  STD_LOGIC;
		FIBER_0_TXP                 : out STD_LOGIC;
		FIBER_0_TXN                 : out STD_LOGIC;
		FIBER_1_TXP                 : out STD_LOGIC;
		FIBER_1_TXN                 : out STD_LOGIC;
		FIBER_REFCLKP               : in  STD_LOGIC;
		FIBER_REFCLKN               : in  STD_LOGIC;
		FIBER_0_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_1_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_0_LINK_UP             : out STD_LOGIC;
		FIBER_1_LINK_UP             : out STD_LOGIC;
		FIBER_0_LINK_ERR            : out STD_LOGIC;
		FIBER_1_LINK_ERR            : out STD_LOGIC;
		---------------------------------------------
		------------------USB pins-------------------
		---------------------------------------------
		USB_IFCLK                   : in  STD_LOGIC;
		USB_CTL0                    : in  STD_LOGIC;
		USB_CTL1                    : in  STD_LOGIC;
		USB_CTL2                    : in  STD_LOGIC;
		USB_FDD                     : inout STD_LOGIC_VECTOR(15 downto 0);
		USB_PA0                     : out STD_LOGIC;
		USB_PA1                     : out STD_LOGIC;
		USB_PA2                     : out STD_LOGIC;
		USB_PA3                     : out STD_LOGIC;
		USB_PA4                     : out STD_LOGIC;
		USB_PA5                     : out STD_LOGIC;
		USB_PA6                     : out STD_LOGIC;
		USB_PA7                     : in  STD_LOGIC;
		USB_RDY0                    : out STD_LOGIC;
		USB_RDY1                    : out STD_LOGIC;
		USB_WAKEUP                  : in  STD_LOGIC;
		USB_CLKOUT		             : in  STD_LOGIC;
		
		--Global Bus Signals
		
		--ASIC related
		
		SIN								 : out STD_LOGIC_VECTOR(9 downto 0);
		SCLK								 : out STD_LOGIC_VECTOR(9 downto 0);
		PCLK								 : out STD_LOGIC_VECTOR(9 downto 0);
		BUSA_REGCLR						 : out STD_LOGIC;
		BUSB_REGCLR						 : out STD_LOGIC;
		SHOUT						 	    : in STD_LOGIC_VECTOR(9 downto 0)
		
		--TRG_16							 : in STD_LOGIC;
		--TRG								 : in STD_LOGIC_VECTOR(3 downto 0)
	);
end scrod_top;

architecture Behavioral of scrod_top is
	signal internal_BOARD_CLOCK      : std_logic;
	signal internal_CLOCK_50MHz_BUFG : std_logic;
	signal internal_CLOCK_4MHz_BUFG  : std_logic;
	signal internal_CLOCK_ENABLE_I2C : std_logic;
	signal internal_CLOCK_SST_BUFG   : std_logic;
	signal internal_CLOCK_4xSST_BUFG : std_logic;
	
	signal internal_OUTPUT_REGISTERS : GPR;
	signal internal_INPUT_REGISTERS  : RR;
	
	--Trigger readout
	signal internal_SOFTWARE_TRIGGER : std_logic;
	signal internal_HARDWARE_TRIGGER : std_logic;
	signal internal_TRIGGER : std_logic;
	signal internal_TRIGGER_OUT : std_logic;
	--Vetoes for the triggers
	signal internal_SOFTWARE_TRIGGER_VETO : std_logic;
	signal internal_HARDWARE_TRIGGER_VETO : std_logic;
	--SCROD ID and REVISION Number
	signal internal_SCROD_REV_AND_ID_WORD        : STD_LOGIC_VECTOR(31 downto 0);
   signal internal_EVENT_NUMBER_TO_SET          : STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); --This is what event number will be set to when set event number is enabled
   signal internal_SET_EVENT_NUMBER             : STD_LOGIC;
   signal internal_EVENT_NUMBER                 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

	--SciFi- event builder related
	signal internal_WAVEFORM_FIFO_DATA_OUT       : std_logic_vector(31 downto 0);
	signal internal_WAVEFORM_FIFO_EMPTY          : std_logic;
	signal internal_WAVEFORM_FIFO_DATA_VALID     : std_logic;
	signal internal_WAVEFORM_FIFO_READ_CLOCK     : std_logic;
	signal internal_WAVEFORM_FIFO_READ_ENABLE    : std_logic;
	signal internal_WAVEFORM_PACKET_BUILDER_BUSY	: std_logic := '0';
	signal internal_WAVEFORM_PACKET_BUILDER_VETO : std_logic;
	
	signal internal_TRIGGER_ALL : std_logic := '0';
	signal INTERNAL_COUNTER : UNSIGNED(27 downto 0) :=  x"0000000";
	signal internal_triggerCounter : UNSIGNED(15 downto 0) :=  x"0000";
	signal internal_numTriggers : UNSIGNED(15 downto 0) :=  x"0000";
	
	signal internal_SMP_STOP : std_logic := '0';
	signal internal_START_DIG : std_logic := '0';
	signal internal_STARTRAMP_out : std_logic := '0';
	signal internal_TARGET6_DAC_CONTROL_UPDATE : std_logic := '0';
	signal internal_TARGET6_DAC_CONTROL_REG_DATA : std_logic_vector(17 downto 0) :=  "00" & x"0000" ;
	
	signal internal_DAC_CONTROL_UPDATE : std_logic_vector(9 downto 0) := "0000000000";
	type array_KLMTDCS is array (0 to 9) of std_logic_vector(17 downto 0); 
   signal internal_KLMTDCS_DAC_CONTROL_REG_DATA : array_KLMTDCS;
	
begin

   --internal_TRIGGER_ALL <= TRG_16 OR TRG(0) OR TRG(1) OR TRG(2) OR TRG(3);
	
	--Clock generation
	map_clock_generation : entity work.clock_generation
	port map ( 
		--Raw boad clock input
		BOARD_CLOCKP      => BOARD_CLOCKP,
		BOARD_CLOCKN      => BOARD_CLOCKN,
		--FTSW inputs
		RJ45_ACK_P        => RJ45_ACK_P,
		RJ45_ACK_N        => RJ45_ACK_N,			  
		RJ45_TRG_P        => RJ45_TRG_P,
		RJ45_TRG_N        => RJ45_TRG_N,			  			  
		RJ45_RSV_P        => RJ45_RSV_P,
		RJ45_RSV_N        => RJ45_RSV_N,
		RJ45_CLK_P        => RJ45_CLK_P,
		RJ45_CLK_N        => RJ45_CLK_N,
		--Trigger outputs from FTSW
		FTSW_TRIGGER      => open,
		--Select signal between the two
		USE_LOCAL_CLOCK   => MONITOR_INPUT(0),
		--General output clocks
		CLOCK_50MHz_BUFG  => internal_CLOCK_50MHz_BUFG,
		CLOCK_4MHz_BUFG   => internal_CLOCK_4MHz_BUFG,
		--ASIC control clocks
		CLOCK_SSTx4_BUFG  => internal_CLOCK_4xSST_BUFG,
		CLOCK_SST_BUFG    => internal_CLOCK_SST_BUFG,
		--ASIC output clocks
		ASIC_SST          => open,
		ASIC_SSP          => open,
		ASIC_WR_STRB      => open,
		ASIC_WR_ADDR_LSB  => open,
		ASIC_WR_ADDR_LSB_RAW => open,
		--Output clock enable for I2C things
		I2C_CLOCK_ENABLE  => internal_CLOCK_ENABLE_I2C
	);	

	--Interface to the DAQ devices
	map_readout_interfaces : entity work.readout_interface
	port map ( 
		CLOCK                        => internal_CLOCK_50MHz_BUFG,

		OUTPUT_REGISTERS             => internal_OUTPUT_REGISTERS,
		INPUT_REGISTERS              => internal_INPUT_REGISTERS,
	
		--NOT original implementation - SciFi specific
		--WAVEFORM_FIFO_DATA_IN        => internal_WAVEFORM_FIFO_DATA_OUT,
		--WAVEFORM_FIFO_EMPTY          => internal_WAVEFORM_FIFO_EMPTY,
		--WAVEFORM_FIFO_DATA_VALID     => internal_WAVEFORM_FIFO_DATA_VALID,
		--WAVEFORM_FIFO_READ_CLOCK     => internal_WAVEFORM_FIFO_READ_CLOCK,
		--WAVEFORM_FIFO_READ_ENABLE    => internal_WAVEFORM_FIFO_READ_ENABLE,
		--WAVEFORM_PACKET_BUILDER_BUSY => internal_WAVEFORM_PACKET_BUILDER_BUSY,
		--WAVEFORM_PACKET_BUILDER_VETO => internal_WAVEFORM_PACKET_BUILDER_VETO,
		
		--WAVEFORM ROI readout disable for now (SciFi implementation)
		WAVEFORM_FIFO_DATA_IN        => (others=>'0'),
		WAVEFORM_FIFO_EMPTY          => '1',
		WAVEFORM_FIFO_DATA_VALID     => '0',
		WAVEFORM_FIFO_READ_CLOCK     => open,
		WAVEFORM_FIFO_READ_ENABLE    => open,
		WAVEFORM_PACKET_BUILDER_BUSY => '0',
		WAVEFORM_PACKET_BUILDER_VETO => open,

		FIBER_0_RXP                  => FIBER_0_RXP,
		FIBER_0_RXN                  => FIBER_0_RXN,
		FIBER_1_RXP                  => FIBER_1_RXP,
		FIBER_1_RXN                  => FIBER_1_RXN,
		FIBER_0_TXP                  => FIBER_0_TXP,
		FIBER_0_TXN                  => FIBER_0_TXN,
		FIBER_1_TXP                  => FIBER_1_TXP,
		FIBER_1_TXN                  => FIBER_1_TXN,
		FIBER_REFCLKP                => FIBER_REFCLKP,
		FIBER_REFCLKN                => FIBER_REFCLKN,
		FIBER_0_DISABLE_TRANSCEIVER  => FIBER_0_DISABLE_TRANSCEIVER,
		FIBER_1_DISABLE_TRANSCEIVER  => FIBER_1_DISABLE_TRANSCEIVER,
		FIBER_0_LINK_UP              => FIBER_0_LINK_UP,
		FIBER_1_LINK_UP              => FIBER_1_LINK_UP,
		FIBER_0_LINK_ERR             => FIBER_0_LINK_ERR,
		FIBER_1_LINK_ERR             => FIBER_1_LINK_ERR,

		USB_IFCLK                    => USB_IFCLK,
		USB_CTL0                     => USB_CTL0,
		USB_CTL1                     => USB_CTL1,
		USB_CTL2                     => USB_CTL2,
		USB_FDD                      => USB_FDD,
		USB_PA0                      => USB_PA0,
		USB_PA1                      => USB_PA1,
		USB_PA2                      => USB_PA2,
		USB_PA3                      => USB_PA3,
		USB_PA4                      => USB_PA4,
		USB_PA5                      => USB_PA5,
		USB_PA6                      => USB_PA6,
		USB_PA7                      => USB_PA7,
		USB_RDY0                     => USB_RDY0,
		USB_RDY1                     => USB_RDY1,
		USB_WAKEUP                   => USB_WAKEUP,
		USB_CLKOUT		              => USB_CLKOUT
	);

	--------------------------------------------------
	-------General registers interfaced to DAQ -------
	--------------------------------------------------
	
	--DAC CONTROL SIGNALS
	internal_DAC_CONTROL_UPDATE(9 downto 0) <= internal_OUTPUT_REGISTERS(1)(9 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(0) <= internal_OUTPUT_REGISTERS(2)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(3)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(1) <= internal_OUTPUT_REGISTERS(4)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(5)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(2) <= internal_OUTPUT_REGISTERS(6)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(7)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(3) <= internal_OUTPUT_REGISTERS(8)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(9)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(4) <= internal_OUTPUT_REGISTERS(10)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(11)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(5) <= internal_OUTPUT_REGISTERS(12)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(13)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(6) <= internal_OUTPUT_REGISTERS(14)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(15)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(7) <= internal_OUTPUT_REGISTERS(16)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(17)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(8) <= internal_OUTPUT_REGISTERS(18)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(19)(11 downto 0);
	internal_KLMTDCS_DAC_CONTROL_REG_DATA(9) <= internal_OUTPUT_REGISTERS(20)(5 downto 0) 
															& internal_OUTPUT_REGISTERS(21)(11 downto 0);															

	--------Input register mapping--------------------
	--Map the first N_GPR output registers to the first set of read registers
	gen_OUTREG_to_INREG: for i in 0 to N_GPR-1 generate
		gen_BIT: for j in 0 to 15 generate
			map_BUF_RR : BUF 
			port map( 
				I => internal_OUTPUT_REGISTERS(i)(j), 
				O => internal_INPUT_REGISTERS(i)(j) 
			);
		end generate;
	end generate;
	--- The register numbers must be updated for the following if N_GPR is changed.
	--internal_INPUT_REGISTERS(N_GPR + 10 ) <= std_logic_vector(INTERNAL_COUNTER(15 downto 0));
	--internal_INPUT_REGISTERS(N_GPR + 11) <= std_logic_vector(internal_numTriggers);

   --ASIC control processes
	
	--Disable TARGET6 DAC Control
	--SIN <= (others => '0');
	--SCLK <= (others => '0');
	--PCLK <= (others => '0');
	--BUSA_REGCLR <= '0';
	--BUSB_REGCLR <= '0';
	
	--TARGET6 DAC Control (10 ASICs)
	gen_DAC_CONTROL: for i in 0 to 9 generate
		u_TARGET6_DAC_CONTROL: entity work.TARGET6_DAC_CONTROL PORT MAP(
			CLK => internal_CLOCK_50MHz_BUFG,
			UPDATE => internal_DAC_CONTROL_UPDATE(i),
			REG_DATA => internal_KLMTDCS_DAC_CONTROL_REG_DATA(i),
			SIN => SIN(i),
			SCLK => SCLK(i),
			PCLK => PCLK(i)
		);
	end generate;
	BUSA_REGCLR <= '0';
	BUSB_REGCLR <= '0';
	
	--sampling logic - specifically SSPIN/SSTIN + write address control
	u_SamplingLgc : entity work.SamplingLgc
   Port map (
		clk => internal_CLOCK_150MHz_BUFG,
		stop => internal_SMP_STOP,
		MAIN_CNT_out => open,
		sspin_out => SSPIN,
		sstin_out => SSTIN,
		wr_advclk_out => WR_ADVCLK,
		wr_addrclr_out => WR_ADDRCLR,
		wr_strb_out => WR_STRB,
		wr_ena_out => WR_ENA,
		samp_delay => x"000"
	);
	
	--digitizing logic
	u_DigitizingLgc: entity work.DigitizingLgc PORT MAP(
		clk => internal_CLOCK_50MHz_BUFG,
		StartDig => internal_DIG_START,
		ramp_length => X"400",
		rd_ena => RD_ENA,
		clr => CLR,
		startramp => internal_DIG_STARTRAMP_OUT
	);
	
	u_SerialDataRout: entity work.SerialDataRout PORT MAP(
		clk => internal_CLOCK_50MHz_BUFG,
		start_srout => internal_SROUT_START,
		samp_done => internal_SROUT_SAMP_DONE,
		dout => DOUT,
		sr_clr => SR_CLR,
		sr_clk => SR_CLK,
		sr_sel => SR_SEL,
		samplesel => internal_SROUT_SAMPLESEL,
		smplsi_any => internal_SROUT_SAMPLESEL_ANY,
		fifo_wr_en => internal_FIFO_WR_EN,
		fifo_wr_clk => internal_FIFO_WR_CLK,
		fifo_wr_din => internal_FIFO_WR_DIN
	);
	
	--RAMP <= internal_STARTRAMP_out;
	--START <= internal_STARTRAMP_out;
	--RD_RS_S <= "000";
	--RD_CS_S <= "000000";
	
   --counter process
   --process (internal_CLOCK_50MHz_BUFG) begin
	--	if (rising_edge(internal_CLOCK_50MHz_BUFG)) then
	--		INTERNAL_COUNTER <= INTERNAL_COUNTER + 1;
   --   end if;
   --end process;
	
	--trigger counter
	--process (INTERNAL_COUNTER, internal_TRIGGER_ALL) begin
	--	if (INTERNAL_COUNTER = 0) then
	--		--if (INTERNAL_COUNTER = x"0000000") then
	--		--	internal_numTriggers = internal_triggerCounter;
	--		--end if;
	--		internal_numTriggers <= internal_triggerCounter;
	--		internal_triggerCounter <= x"0000";
	--	else
	--		if( rising_edge(internal_TRIGGER_ALL) ) then
	--			internal_triggerCounter <= internal_triggerCounter  + 1;
	--		end if;
   --   end if;
   --end process;

end Behavioral;
