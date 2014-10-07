--------------------------------------------------------------------------------
--     (c) Copyright 1995 - 2010 Xilinx, Inc. All rights reserved.            --
--                                                                            --
--     This file contains confidential and proprietary information            --
--     of Xilinx, Inc. and is protected under U.S. and                        --
--     international copyright and other intellectual property                --
--     laws.                                                                  --
--                                                                            --
--     DISCLAIMER                                                             --
--     This disclaimer is not a license and does not grant any                --
--     rights to the materials distributed herewith. Except as                --
--     otherwise provided in a valid license issued to you by                 --
--     Xilinx, and to the maximum extent permitted by applicable              --
--     law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND                --
--     WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES            --
--     AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING              --
--     BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-                 --
--     INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and               --
--     (2) Xilinx shall not be liable (whether in contract or tort,           --
--     including negligence, or under any other theory of                     --
--     liability) for any loss or damage of any kind or nature                --
--     related to, arising under or in connection with these                  --
--     materials, including for any direct, or any indirect,                  --
--     special, incidental, or consequential loss or damage                   --
--     (including loss of data, profits, goodwill, or any type of             --
--     loss or damage suffered as a result of any action brought              --
--     by a third party) even if such damage or loss was                      --
--     reasonably foreseeable or Xilinx had been advised of the               --
--     possibility of the same.                                               --
--                                                                            --
--     CRITICAL APPLICATIONS                                                  --
--     Xilinx products are not designed or intended to be fail-               --
--     safe, or for use in any application requiring fail-safe                --
--     performance, such as life-support or safety devices or                 --
--     systems, Class III medical devices, nuclear facilities,                --
--     applications related to the deployment of airbags, or any              --
--     other applications that could lead to death, personal                  --
--     injury, or severe property or environmental damage                     --
--     (individually and collectively, "Critical                              --
--     Applications"). Customer assumes the sole risk and                     --
--     liability of any use of Xilinx products in Critical                    --
--     Applications, subject only to applicable laws and                      --
--     regulations governing limitations on product liability.                --
--                                                                            --
--     THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS               --
--     PART OF THIS FILE AT ALL TIMES.                                        --
--------------------------------------------------------------------------------

--  Generated from component ID: xilinx.com:ip:gig_eth_pcs_pma:11.1


-- The following code must appear in the VHDL architecture header:

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
component ethercon
	port (
	reset: in std_logic;
	signal_detect: in std_logic;
	link_timer_value: in std_logic_vector(8 downto 0);
	mgt_rx_reset: out std_logic;
	mgt_tx_reset: out std_logic;
	userclk: in std_logic;
	userclk2: in std_logic;
	dcm_locked: in std_logic;
	rxbufstatus: in std_logic_vector(1 downto 0);
	rxchariscomma: in std_logic;
	rxcharisk: in std_logic;
	rxclkcorcnt: in std_logic_vector(2 downto 0);
	rxdata: in std_logic_vector(7 downto 0);
	rxdisperr: in std_logic;
	rxnotintable: in std_logic;
	rxrundisp: in std_logic;
	txbuferr: in std_logic;
	powerdown: out std_logic;
	txchardispmode: out std_logic;
	txchardispval: out std_logic;
	txcharisk: out std_logic;
	txdata: out std_logic_vector(7 downto 0);
	enablealign: out std_logic;
	gmii_txd: in std_logic_vector(7 downto 0);
	gmii_tx_en: in std_logic;
	gmii_tx_er: in std_logic;
	gmii_rxd: out std_logic_vector(7 downto 0);
	gmii_rx_dv: out std_logic;
	gmii_rx_er: out std_logic;
	gmii_isolate: out std_logic;
	an_interrupt: out std_logic;
	phyad: in std_logic_vector(4 downto 0);
	mdc: in std_logic;
	mdio_in: in std_logic;
	mdio_out: out std_logic;
	mdio_tri: out std_logic;
	status_vector: out std_logic_vector(15 downto 0));
end component;

-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : ethercon
		port map (
			reset => reset,
			signal_detect => signal_detect,
			link_timer_value => link_timer_value,
			mgt_rx_reset => mgt_rx_reset,
			mgt_tx_reset => mgt_tx_reset,
			userclk => userclk,
			userclk2 => userclk2,
			dcm_locked => dcm_locked,
			rxbufstatus => rxbufstatus,
			rxchariscomma => rxchariscomma,
			rxcharisk => rxcharisk,
			rxclkcorcnt => rxclkcorcnt,
			rxdata => rxdata,
			rxdisperr => rxdisperr,
			rxnotintable => rxnotintable,
			rxrundisp => rxrundisp,
			txbuferr => txbuferr,
			powerdown => powerdown,
			txchardispmode => txchardispmode,
			txchardispval => txchardispval,
			txcharisk => txcharisk,
			txdata => txdata,
			enablealign => enablealign,
			gmii_txd => gmii_txd,
			gmii_tx_en => gmii_tx_en,
			gmii_tx_er => gmii_tx_er,
			gmii_rxd => gmii_rxd,
			gmii_rx_dv => gmii_rx_dv,
			gmii_rx_er => gmii_rx_er,
			gmii_isolate => gmii_isolate,
			an_interrupt => an_interrupt,
			phyad => phyad,
			mdc => mdc,
			mdio_in => mdio_in,
			mdio_out => mdio_out,
			mdio_tri => mdio_tri,
			status_vector => status_vector);
-- INST_TAG_END ------ End INSTANTIATION Template ------------

