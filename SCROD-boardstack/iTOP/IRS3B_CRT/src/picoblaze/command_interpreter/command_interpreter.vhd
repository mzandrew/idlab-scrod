--
-------------------------------------------------------------------------------------------
-- Copyright © 2010-2011, Xilinx, Inc.
-- This file contains confidential and proprietary information of Xilinx, Inc. and is
-- protected under U.S. and international copyright and other intellectual property laws.
-------------------------------------------------------------------------------------------
--
-- Disclaimer:
-- This disclaimer is not a license and does not grant any rights to the materials
-- distributed herewith. Except as otherwise provided in a valid license issued to
-- you by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE
-- MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY
-- DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY,
-- INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
-- OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable
-- (whether in contract or tort, including negligence, or under any other theory
-- of liability) for any loss or damage of any kind or nature related to, arising
-- under or in connection with these materials, including for any direct, or any
-- indirect, special, incidental, or consequential loss or damage (including loss
-- of data, profits, goodwill, or any type of loss or damage suffered as a result
-- of any action brought by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-safe, or for use in any
-- application requiring fail-safe performance, such as life-support or safety
-- devices or systems, Class III medical devices, nuclear facilities, applications
-- related to the deployment of airbags, or any other applications that could lead
-- to death, personal injury, or severe property or environmental damage
-- (individually and collectively, "Critical Applications"). Customer assumes the
-- sole risk and liability of any use of Xilinx products in Critical Applications,
-- subject only to applicable laws and regulations governing limitations on product
-- liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------------------
--
--
-- Definition of a program memory for KCPSM6 including generic parameters for the 
-- convenient selection of device family, program memory size and the ability to include 
-- the JTAG Loader hardware for rapid software development.
--
-- This file is primarily for use during code development and it is recommended that the 
-- appropriate simplified program memory definition be used in a final production design. 
--
--    Generic                  Values             Comments
--    Parameter                Supported
--  
--    C_FAMILY                 "S6"               Spartan-6 device
--                             "V6"               Virtex-6 device
--                             "7S"               7-Series device 
--                                                   (Artix-7, Kintex-7 or Virtex-7)
--
--    C_RAM_SIZE_KWORDS        1, 2 or 4          Size of program memory in K-instructions
--                                                 '4' is not supported for 'S6'.
--
--    C_JTAG_LOADER_ENABLE     0 or 1             Set to '1' to include JTAG Loader
--
-- Notes
--
-- If your design contains MULTIPLE KCPSM6 instances then only one should have the 
-- JTAG Loader enabled at a time (i.e. make sure that C_JTAG_LOADER_ENABLE is only set to 
-- '1' on one instance of the program memory). Advanced users may be interested to know 
-- that it is possible to connect JTAG Loader to multiple memories and then to use the 
-- JTAG Loader utility to specify which memory contents are to be modified. However, 
-- this scheme does require some effort to set up and the additional connectivity of the 
-- multiple BRAMs can impact the placement, routing and performance of the complete 
-- design. Please contact the author at Xilinx for more detailed information. 
--
-- Regardless of the size of program memory specified by C_RAM_SIZE_KWORDS, the complete 
-- 12-bit address bus is connected to KCPSM6. This enables the generic to be modified 
-- without requiring changes to the fundamental hardware definition. However, when the 
-- program memory is 1K then only the lower 10-bits of the address are actually used and 
-- the valid address range is 000 to 3FF hex. Likewise, for a 2K program only the lower 
-- 11-bits of the address are actually used and the valid address range is 000 to 7FF hex.
--
-- Programs are stored in Block Memory (BRAM) and the number of BRAM used depends on the 
-- size of the program and the device family. 
--
-- In a Spartan-6 device a BRAM is capable of holding 1K instructions. Hence a 2K program 
-- will require 2 BRAMs to be used. Whilst it is possible to implement a 4K program in a 
-- Spartan-6 device this is a less natural fit within the architecture and either requires 
-- 4 BRAMs and a small amount of logic resulting in a lower performance or 5 BRAMs when 
-- performance is a critical factor. Due to these additional considerations this file 
-- does not support the selection of 4K when using Spartan-6. If one of these special 
-- cases is required then please contact the author at Xilinx to discuss and request a 
-- specific 'ROM_form' template that will meet your requirements. Note that whilst it 
-- it is possible to divide a Spartan-6 BRAM into 2 smaller memories which would each hold
-- a program up to only 512 instructions there is a silicon errata which makes unsuitable. 
--
-- In a Virtex-6 or any 7-Series device a BRAM is capable of holding 2K instructions so 
-- obviously a 2K program requires only a single BRAM. Each BRAM can also be divided into 
-- 2 smaller memories supporting programs of 1K in half of a 36k-bit BRAM (generally reported 
-- as being an 18k-bit BRAM). For a program of 4K instructions 2 BRAMs are required.
--
--
-- Program defined by 'C:\cygwin\home\Dr Kurtis\idlab-scrod\SCROD-boardstack\iTOP\IRS3B_CRT\src\picoblaze\command_interpreter\command_interpreter.psm'.
--
-- Generated by KCPSM6 Assembler: 12 Mar 2013 - 23:29:01. 
--
-- Assembler used ROM_form template: 16th August 2011
--
-- Standard IEEE libraries
--
--
package jtag_loader_pkg is
 function addr_width_calc (size_in_k: integer) return integer;
end jtag_loader_pkg;
--
package body jtag_loader_pkg is
  function addr_width_calc (size_in_k: integer) return integer is
   begin
    if (size_in_k = 1) then return 10;
      elsif (size_in_k = 2) then return 11;
      elsif (size_in_k = 4) then return 12;
      else report "Invalid BlockRAM size. Please set to 1, 2 or 4 K words." severity FAILURE;
    end if;
    return 0;
  end function addr_width_calc;
end package body;
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.jtag_loader_pkg.ALL;
--
-- The Unisim Library is used to define Xilinx primitives. It is also used during
-- simulation. The source can be viewed at %XILINX%\vhdl\src\unisims\unisim_VCOMP.vhd
--  
library unisim;
use unisim.vcomponents.all;
--
--
entity command_interpreter is
  generic(             C_FAMILY : string := "S6"; 
              C_RAM_SIZE_KWORDS : integer := 1;
           C_JTAG_LOADER_ENABLE : integer := 0);
  Port (      address : in std_logic_vector(11 downto 0);
          instruction : out std_logic_vector(17 downto 0);
               enable : in std_logic;
                  rdl : out std_logic;                    
                  clk : in std_logic);
  end command_interpreter;
--
architecture low_level_definition of command_interpreter is
--
signal       address_a : std_logic_vector(15 downto 0);
signal       data_in_a : std_logic_vector(35 downto 0);
signal      data_out_a : std_logic_vector(35 downto 0);
signal    data_out_a_l : std_logic_vector(35 downto 0);
signal    data_out_a_h : std_logic_vector(35 downto 0);
signal       address_b : std_logic_vector(15 downto 0);
signal       data_in_b : std_logic_vector(35 downto 0);
signal     data_in_b_l : std_logic_vector(35 downto 0);
signal      data_out_b : std_logic_vector(35 downto 0);
signal    data_out_b_l : std_logic_vector(35 downto 0);
signal     data_in_b_h : std_logic_vector(35 downto 0);
signal    data_out_b_h : std_logic_vector(35 downto 0);
signal        enable_b : std_logic;
signal           clk_b : std_logic;
signal            we_b : std_logic_vector(7 downto 0);
-- 
signal       jtag_addr : std_logic_vector(11 downto 0);
signal         jtag_we : std_logic;
signal        jtag_clk : std_logic;
signal        jtag_din : std_logic_vector(17 downto 0);
signal       jtag_dout : std_logic_vector(17 downto 0);
signal     jtag_dout_1 : std_logic_vector(17 downto 0);
signal         jtag_en : std_logic_vector(0 downto 0);
-- 
signal picoblaze_reset : std_logic_vector(0 downto 0);
signal         rdl_bus : std_logic_vector(0 downto 0);
--
constant BRAM_ADDRESS_WIDTH  : integer := addr_width_calc(C_RAM_SIZE_KWORDS);
--
--
component jtag_loader_6
generic(                C_JTAG_LOADER_ENABLE : integer := 1;
                                    C_FAMILY : string  := "V6";
                             C_NUM_PICOBLAZE : integer := 1;
                       C_BRAM_MAX_ADDR_WIDTH : integer := 10;
          C_PICOBLAZE_INSTRUCTION_DATA_WIDTH : integer := 18;
                                C_JTAG_CHAIN : integer := 2;
                              C_ADDR_WIDTH_0 : integer := 10;
                              C_ADDR_WIDTH_1 : integer := 10;
                              C_ADDR_WIDTH_2 : integer := 10;
                              C_ADDR_WIDTH_3 : integer := 10;
                              C_ADDR_WIDTH_4 : integer := 10;
                              C_ADDR_WIDTH_5 : integer := 10;
                              C_ADDR_WIDTH_6 : integer := 10;
                              C_ADDR_WIDTH_7 : integer := 10);
port(              picoblaze_reset : out std_logic_vector(C_NUM_PICOBLAZE-1 downto 0);
                           jtag_en : out std_logic_vector(C_NUM_PICOBLAZE-1 downto 0);
                          jtag_din : out STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                         jtag_addr : out STD_LOGIC_VECTOR(C_BRAM_MAX_ADDR_WIDTH-1 downto 0);
                          jtag_clk : out std_logic;
                           jtag_we : out std_logic;
                       jtag_dout_0 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_1 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_2 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_3 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_4 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_5 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_6 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
                       jtag_dout_7 : in STD_LOGIC_VECTOR(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0));
end component;
--
begin
  --
  --  
  ram_1k_generate : if (C_RAM_SIZE_KWORDS = 1) generate
 
    s6: if (C_FAMILY = "S6") generate 
      --
      address_a(13 downto 0) <= address(9 downto 0) & "0000";
      instruction <= data_out_a(33 downto 32) & data_out_a(15 downto 0);
      data_in_a <= "0000000000000000000000000000000000" & address(11 downto 10);
      jtag_dout <= data_out_b(33 downto 32) & data_out_b(15 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b <= "00" & data_out_b(33 downto 32) & "0000000000000000" & data_out_b(15 downto 0);
        address_b(13 downto 0) <= "00000000000000";
        we_b(3 downto 0) <= "0000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b <= "00" & jtag_din(17 downto 16) & "0000000000000000" & jtag_din(15 downto 0);
        address_b(13 downto 0) <= jtag_addr(9 downto 0) & "0000";
        we_b(3 downto 0) <= jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      --
      kcpsm6_rom: RAMB16BWER
      generic map ( DATA_WIDTH_A => 18,
                    DOA_REG => 0,
                    EN_RSTRAM_A => FALSE,
                    INIT_A => X"000000000",
                    RST_PRIORITY_A => "CE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    DATA_WIDTH_B => 18,
                    DOB_REG => 0,
                    EN_RSTRAM_B => FALSE,
                    INIT_B => X"000000000",
                    RST_PRIORITY_B => "CE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    RSTTYPE => "SYNC",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    SIM_DEVICE => "SPARTAN6",
                    INIT_00 => X"D108D007110010000328110010C8D109D108D0071104100003281100100C0335",
                    INIT_01 => X"D00A10011F0002E402B603390245D109D108D0071100101503281101107BD109",
                    INIT_02 => X"DF031000006CDF0210000058DF0110000050DF0001B750003001900020200022",
                    INIT_03 => X"00EBDF08100000C7DF07100000BFDF061000009EDF0510000096DF041000007B",
                    INIT_04 => X"5000D00A1001500060489004300690005000D00A10020048D00A100350001000",
                    INIT_05 => X"1001A065B400B300B20091FF01950170500001B400420240016E1001D00101C7",
                    INIT_06 => X"D00201D10170016B500001B4016E100209200810019A500001B4016E10000152",
                    INIT_07 => X"B200910001950170016B500001B4016E1003500001B4016E1000015210022077",
                    INIT_08 => X"500001B4016E1000015210042090A360A2508140B602B501B400019A2090B300",
                    INIT_09 => X"0170016B500001B4016E10050A4001A90170016B500001B4023B019F016E1004",
                    INIT_0A => X"100716001700500001B4016E10000152100820B7D00520B2D00420ADD00301DB",
                    INIT_0B => X"016B500001B4151A20BC016E10061601170220BC016E10061601170120BC016E",
                    INIT_0C => X"10000152101020D3A4E0A3D0A2C081B0016B500001B4016E10079601018C0170",
                    INIT_0D => X"008020DF01390100D70220DF012000F7D70120DF010AD700017A500001B4016E",
                    INIT_0E => X"A4E0A3D0A2C081B001A4500001B4016E1004023B20E9016E1008B10090010190",
                    INIT_0F => X"5000F11DF01C91079006D106D005B11BB01A500001B4016E10000152102020F3",
                    INIT_10 => X"10050175021F023B611E01C35000D309D308D207D106D005B31DB21CB11BB01A",
                    INIT_11 => X"5000004D0235017501FB017501AE0175032F0175022901750219130012001100",
                    INIT_12 => X"01AE0175032F017502290175021913001200110010060175021F023B613701C3",
                    INIT_13 => X"110010060175021F023B615001C35000004D02350175020F020D017502010175",
                    INIT_14 => X"02350175020F020D01750207017501AE0175032F017502290175021913001200",
                    INIT_15 => X"0175032F0175022F0175021913001200110010050175021F023BF0105000004D",
                    INIT_16 => X"50000F005000B90098015000004D023501750219130012001100B010017501AE",
                    INIT_17 => X"4C004B06B307B206B105B00450002E302D202C100B0050002E402D302C200B10",
                    INIT_18 => X"1501E2501501E1505000023BF307F206F105F00423E022D021C000B04E004D00",
                    INIT_19 => X"FB045000B413B312B211B1105000F413F312F211F11050001501E4501501E350",
                    INIT_1A => X"B109B0085000F40BF30AF209F1085000BE07BD06BC05BB045000FE07FD06FC05",
                    INIT_1B => X"D302D201D1005000940593049203910290015000D000100050000219B30BB20A",
                    INIT_1C => X"100161D1D40061D1D3BE61D1D21161D1D1E2500020A0001011805000D404D403",
                    INIT_1D => X"D36961E5D26E61E5D1675000100261DBD46461DBD36F61DBD26961DBD1745000",
                    INIT_1E => X"D1655000100461EFD47261EFD36561EFD26161EFD1645000100361E5D47061E5",
                    INIT_1F => X"021913701269116E1067500010005000100561F9D47261F9D36961F9D27461F9",
                    INIT_20 => X"A0505000151A5000021913721269117410655000021913721265116110645000",
                    INIT_21 => X"10E25000D304D303D202D101D000500002191501A3501501A2501501A1501501",
                    INIT_22 => X"103F50000219136F126B116110795000D304D3031300D20212BED1011111D000",
                    INIT_23 => X"50001E001D001C001B005000DE04DE03DD02DC01DB0050000219137712681161",
                    INIT_24 => X"0339032B10A011000339032B1000110103281001110050001E001DBE1C111BE2",
                    INIT_25 => X"0339032B100011000339032B100011020339032B100011000339032B10A01102",
                    INIT_26 => X"0339032B10A111020339032B10A111000339032B100011010339032B10001102",
                    INIT_27 => X"110C032B10001100032810011100F00090060328100011020339032B1000110C",
                    INIT_28 => X"10001104032B10001100032810011100F00190060328110210000339032B1000",
                    INIT_29 => X"0328110010A6032B10001110032811001001F00290060328110210000339032B",
                    INIT_2A => X"032811001000D109D108D0071100B0020328110010A7D109D108D007B101B000",
                    INIT_2B => X"032810F4110103071494132212000328100111005000D109D108D007B101B000",
                    INIT_2C => X"0307147603071474030714960307149403071472030714700307149203071490",
                    INIT_2D => X"1474030714960307149403071472030714700307149203071490032810F51101",
                    INIT_2E => X"13031474030712401301030712001303147C032810F411015000030714760307",
                    INIT_2F => X"1474030712401301030712001303147C032810F5110103071240130103071200",
                    INIT_30 => X"11020339032B004011000339032B100011015000030712401301030712001303",
                    INIT_31 => X"11020339032B002011000339032B003011020339032B003011000339032B0040",
                    INIT_32 => X"B0005000D009D007D1085000D005D10650000339032B100011100339032B0020",
                    INIT_33 => X"B200B1009001233D10E211041200233D1038119C121C500002191300B202B101",
                    INIT_34 => X"000000000000000000000000000000000000000000000000000000005000633D",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"5AAA2A236AA80AA2355AAFC6A2D0A28BDF7DF7DF7DF7DB0A82AAA082A082A082",
                   INITP_01 => X"A8282A2355AA2F143F7F7DAA2355AB1AA8A0280A02A23776AA82AAA8A88D502D",
                   INITP_02 => X"50095655896AA00AAAA00AAAAAAAAAA00ABAAAAAAAA802AEAAAAAA802AEAAA00",
                   INITP_03 => X"8022377763777637776377763777602AAA0024A00AAA00AAA00AAA6666AAA555",
                   INITP_04 => X"208220A0A0A0A0A0A0A0A0A0A0A08200802AAA802802A2222AAA911122802802",
                   INITP_05 => X"20808208082020A2222222208888888882020AA082A082A08208220A08208828",
                   INITP_06 => X"0000000000000000000000000000000B560202802AAAA8282828282828282820",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(  ADDRA => address_a(13 downto 0),
                   ENA => enable,
                  CLKA => clk,
                   DOA => data_out_a(31 downto 0),
                  DOPA => data_out_a(35 downto 32), 
                   DIA => data_in_a(31 downto 0),
                  DIPA => data_in_a(35 downto 32), 
                   WEA => "0000",
                REGCEA => '0',
                  RSTA => '0',
                 ADDRB => address_b(13 downto 0),
                   ENB => enable_b,
                  CLKB => clk_b,
                   DOB => data_out_b(31 downto 0),
                  DOPB => data_out_b(35 downto 32), 
                   DIB => data_in_b(31 downto 0),
                  DIPB => data_in_b(35 downto 32), 
                   WEB => we_b(3 downto 0),
                REGCEB => '0',
                  RSTB => '0');
    --               
    end generate s6;
    --
    --
    v6 : if (C_FAMILY = "V6") generate
      --
      address_a(13 downto 0) <= address(9 downto 0) & "0000";
      instruction <= data_out_a(17 downto 0);
      data_in_a(17 downto 0) <= "0000000000000000" & address(11 downto 10);
      jtag_dout <= data_out_b(17 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b(17 downto 0) <= data_out_b(17 downto 0);
        address_b(13 downto 0) <= "00000000000000";
        we_b(3 downto 0) <= "0000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b(17 downto 0) <= jtag_din(17 downto 0);
        address_b(13 downto 0) <= jtag_addr(9 downto 0) & "0000";
        we_b(3 downto 0) <= jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      -- 
      kcpsm6_rom: RAMB18E1
      generic map ( READ_WIDTH_A => 18,
                    WRITE_WIDTH_A => 18,
                    DOA_REG => 0,
                    INIT_A => "000000000000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 18,
                    WRITE_WIDTH_B => 18,
                    DOB_REG => 0,
                    INIT_B => X"000000000000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    SIM_DEVICE => "VIRTEX6",
                    INIT_00 => X"D108D007110010000328110010C8D109D108D0071104100003281100100C0335",
                    INIT_01 => X"D00A10011F0002E402B603390245D109D108D0071100101503281101107BD109",
                    INIT_02 => X"DF031000006CDF0210000058DF0110000050DF0001B750003001900020200022",
                    INIT_03 => X"00EBDF08100000C7DF07100000BFDF061000009EDF0510000096DF041000007B",
                    INIT_04 => X"5000D00A1001500060489004300690005000D00A10020048D00A100350001000",
                    INIT_05 => X"1001A065B400B300B20091FF01950170500001B400420240016E1001D00101C7",
                    INIT_06 => X"D00201D10170016B500001B4016E100209200810019A500001B4016E10000152",
                    INIT_07 => X"B200910001950170016B500001B4016E1003500001B4016E1000015210022077",
                    INIT_08 => X"500001B4016E1000015210042090A360A2508140B602B501B400019A2090B300",
                    INIT_09 => X"0170016B500001B4016E10050A4001A90170016B500001B4023B019F016E1004",
                    INIT_0A => X"100716001700500001B4016E10000152100820B7D00520B2D00420ADD00301DB",
                    INIT_0B => X"016B500001B4151A20BC016E10061601170220BC016E10061601170120BC016E",
                    INIT_0C => X"10000152101020D3A4E0A3D0A2C081B0016B500001B4016E10079601018C0170",
                    INIT_0D => X"008020DF01390100D70220DF012000F7D70120DF010AD700017A500001B4016E",
                    INIT_0E => X"A4E0A3D0A2C081B001A4500001B4016E1004023B20E9016E1008B10090010190",
                    INIT_0F => X"5000F11DF01C91079006D106D005B11BB01A500001B4016E10000152102020F3",
                    INIT_10 => X"10050175021F023B611E01C35000D309D308D207D106D005B31DB21CB11BB01A",
                    INIT_11 => X"5000004D0235017501FB017501AE0175032F0175022901750219130012001100",
                    INIT_12 => X"01AE0175032F017502290175021913001200110010060175021F023B613701C3",
                    INIT_13 => X"110010060175021F023B615001C35000004D02350175020F020D017502010175",
                    INIT_14 => X"02350175020F020D01750207017501AE0175032F017502290175021913001200",
                    INIT_15 => X"0175032F0175022F0175021913001200110010050175021F023BF0105000004D",
                    INIT_16 => X"50000F005000B90098015000004D023501750219130012001100B010017501AE",
                    INIT_17 => X"4C004B06B307B206B105B00450002E302D202C100B0050002E402D302C200B10",
                    INIT_18 => X"1501E2501501E1505000023BF307F206F105F00423E022D021C000B04E004D00",
                    INIT_19 => X"FB045000B413B312B211B1105000F413F312F211F11050001501E4501501E350",
                    INIT_1A => X"B109B0085000F40BF30AF209F1085000BE07BD06BC05BB045000FE07FD06FC05",
                    INIT_1B => X"D302D201D1005000940593049203910290015000D000100050000219B30BB20A",
                    INIT_1C => X"100161D1D40061D1D3BE61D1D21161D1D1E2500020A0001011805000D404D403",
                    INIT_1D => X"D36961E5D26E61E5D1675000100261DBD46461DBD36F61DBD26961DBD1745000",
                    INIT_1E => X"D1655000100461EFD47261EFD36561EFD26161EFD1645000100361E5D47061E5",
                    INIT_1F => X"021913701269116E1067500010005000100561F9D47261F9D36961F9D27461F9",
                    INIT_20 => X"A0505000151A5000021913721269117410655000021913721265116110645000",
                    INIT_21 => X"10E25000D304D303D202D101D000500002191501A3501501A2501501A1501501",
                    INIT_22 => X"103F50000219136F126B116110795000D304D3031300D20212BED1011111D000",
                    INIT_23 => X"50001E001D001C001B005000DE04DE03DD02DC01DB0050000219137712681161",
                    INIT_24 => X"0339032B10A011000339032B1000110103281001110050001E001DBE1C111BE2",
                    INIT_25 => X"0339032B100011000339032B100011020339032B100011000339032B10A01102",
                    INIT_26 => X"0339032B10A111020339032B10A111000339032B100011010339032B10001102",
                    INIT_27 => X"110C032B10001100032810011100F00090060328100011020339032B1000110C",
                    INIT_28 => X"10001104032B10001100032810011100F00190060328110210000339032B1000",
                    INIT_29 => X"0328110010A6032B10001110032811001001F00290060328110210000339032B",
                    INIT_2A => X"032811001000D109D108D0071100B0020328110010A7D109D108D007B101B000",
                    INIT_2B => X"032810F4110103071494132212000328100111005000D109D108D007B101B000",
                    INIT_2C => X"0307147603071474030714960307149403071472030714700307149203071490",
                    INIT_2D => X"1474030714960307149403071472030714700307149203071490032810F51101",
                    INIT_2E => X"13031474030712401301030712001303147C032810F411015000030714760307",
                    INIT_2F => X"1474030712401301030712001303147C032810F5110103071240130103071200",
                    INIT_30 => X"11020339032B004011000339032B100011015000030712401301030712001303",
                    INIT_31 => X"11020339032B002011000339032B003011020339032B003011000339032B0040",
                    INIT_32 => X"B0005000D009D007D1085000D005D10650000339032B100011100339032B0020",
                    INIT_33 => X"B200B1009001233D10E211041200233D1038119C121C500002191300B202B101",
                    INIT_34 => X"000000000000000000000000000000000000000000000000000000005000633D",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"5AAA2A236AA80AA2355AAFC6A2D0A28BDF7DF7DF7DF7DB0A82AAA082A082A082",
                   INITP_01 => X"A8282A2355AA2F143F7F7DAA2355AB1AA8A0280A02A23776AA82AAA8A88D502D",
                   INITP_02 => X"50095655896AA00AAAA00AAAAAAAAAA00ABAAAAAAAA802AEAAAAAA802AEAAA00",
                   INITP_03 => X"8022377763777637776377763777602AAA0024A00AAA00AAA00AAA6666AAA555",
                   INITP_04 => X"208220A0A0A0A0A0A0A0A0A0A0A08200802AAA802802A2222AAA911122802802",
                   INITP_05 => X"20808208082020A2222222208888888882020AA082A082A08208220A08208828",
                   INITP_06 => X"0000000000000000000000000000000B560202802AAAA8282828282828282820",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a(13 downto 0),
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a(15 downto 0),
                      DOPADOP => data_out_a(17 downto 16), 
                        DIADI => data_in_a(15 downto 0),
                      DIPADIP => data_in_a(17 downto 16), 
                          WEA => "00",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b(13 downto 0),
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b(15 downto 0),
                      DOPBDOP => data_out_b(17 downto 16), 
                        DIBDI => data_in_b(15 downto 0),
                      DIPBDIP => data_in_b(17 downto 16), 
                        WEBWE => we_b(3 downto 0),
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0');
      --
    end generate v6;
    --
    --
    akv7 : if (C_FAMILY = "7S") generate
      --
      address_a(13 downto 0) <= address(9 downto 0) & "0000";
      instruction <= data_out_a(17 downto 0);
      data_in_a(17 downto 0) <= "0000000000000000" & address(11 downto 10);
      jtag_dout <= data_out_b(17 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b(17 downto 0) <= data_out_b(17 downto 0);
        address_b(13 downto 0) <= "00000000000000";
        we_b(3 downto 0) <= "0000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b(17 downto 0) <= jtag_din(17 downto 0);
        address_b(13 downto 0) <= jtag_addr(9 downto 0) & "0000";
        we_b(3 downto 0) <= jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      -- 
      kcpsm6_rom: RAMB18E1
      generic map ( READ_WIDTH_A => 18,
                    WRITE_WIDTH_A => 18,
                    DOA_REG => 0,
                    INIT_A => "000000000000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 18,
                    WRITE_WIDTH_B => 18,
                    DOB_REG => 0,
                    INIT_B => X"000000000000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    SIM_DEVICE => "7SERIES",
                    INIT_00 => X"D108D007110010000328110010C8D109D108D0071104100003281100100C0335",
                    INIT_01 => X"D00A10011F0002E402B603390245D109D108D0071100101503281101107BD109",
                    INIT_02 => X"DF031000006CDF0210000058DF0110000050DF0001B750003001900020200022",
                    INIT_03 => X"00EBDF08100000C7DF07100000BFDF061000009EDF0510000096DF041000007B",
                    INIT_04 => X"5000D00A1001500060489004300690005000D00A10020048D00A100350001000",
                    INIT_05 => X"1001A065B400B300B20091FF01950170500001B400420240016E1001D00101C7",
                    INIT_06 => X"D00201D10170016B500001B4016E100209200810019A500001B4016E10000152",
                    INIT_07 => X"B200910001950170016B500001B4016E1003500001B4016E1000015210022077",
                    INIT_08 => X"500001B4016E1000015210042090A360A2508140B602B501B400019A2090B300",
                    INIT_09 => X"0170016B500001B4016E10050A4001A90170016B500001B4023B019F016E1004",
                    INIT_0A => X"100716001700500001B4016E10000152100820B7D00520B2D00420ADD00301DB",
                    INIT_0B => X"016B500001B4151A20BC016E10061601170220BC016E10061601170120BC016E",
                    INIT_0C => X"10000152101020D3A4E0A3D0A2C081B0016B500001B4016E10079601018C0170",
                    INIT_0D => X"008020DF01390100D70220DF012000F7D70120DF010AD700017A500001B4016E",
                    INIT_0E => X"A4E0A3D0A2C081B001A4500001B4016E1004023B20E9016E1008B10090010190",
                    INIT_0F => X"5000F11DF01C91079006D106D005B11BB01A500001B4016E10000152102020F3",
                    INIT_10 => X"10050175021F023B611E01C35000D309D308D207D106D005B31DB21CB11BB01A",
                    INIT_11 => X"5000004D0235017501FB017501AE0175032F0175022901750219130012001100",
                    INIT_12 => X"01AE0175032F017502290175021913001200110010060175021F023B613701C3",
                    INIT_13 => X"110010060175021F023B615001C35000004D02350175020F020D017502010175",
                    INIT_14 => X"02350175020F020D01750207017501AE0175032F017502290175021913001200",
                    INIT_15 => X"0175032F0175022F0175021913001200110010050175021F023BF0105000004D",
                    INIT_16 => X"50000F005000B90098015000004D023501750219130012001100B010017501AE",
                    INIT_17 => X"4C004B06B307B206B105B00450002E302D202C100B0050002E402D302C200B10",
                    INIT_18 => X"1501E2501501E1505000023BF307F206F105F00423E022D021C000B04E004D00",
                    INIT_19 => X"FB045000B413B312B211B1105000F413F312F211F11050001501E4501501E350",
                    INIT_1A => X"B109B0085000F40BF30AF209F1085000BE07BD06BC05BB045000FE07FD06FC05",
                    INIT_1B => X"D302D201D1005000940593049203910290015000D000100050000219B30BB20A",
                    INIT_1C => X"100161D1D40061D1D3BE61D1D21161D1D1E2500020A0001011805000D404D403",
                    INIT_1D => X"D36961E5D26E61E5D1675000100261DBD46461DBD36F61DBD26961DBD1745000",
                    INIT_1E => X"D1655000100461EFD47261EFD36561EFD26161EFD1645000100361E5D47061E5",
                    INIT_1F => X"021913701269116E1067500010005000100561F9D47261F9D36961F9D27461F9",
                    INIT_20 => X"A0505000151A5000021913721269117410655000021913721265116110645000",
                    INIT_21 => X"10E25000D304D303D202D101D000500002191501A3501501A2501501A1501501",
                    INIT_22 => X"103F50000219136F126B116110795000D304D3031300D20212BED1011111D000",
                    INIT_23 => X"50001E001D001C001B005000DE04DE03DD02DC01DB0050000219137712681161",
                    INIT_24 => X"0339032B10A011000339032B1000110103281001110050001E001DBE1C111BE2",
                    INIT_25 => X"0339032B100011000339032B100011020339032B100011000339032B10A01102",
                    INIT_26 => X"0339032B10A111020339032B10A111000339032B100011010339032B10001102",
                    INIT_27 => X"110C032B10001100032810011100F00090060328100011020339032B1000110C",
                    INIT_28 => X"10001104032B10001100032810011100F00190060328110210000339032B1000",
                    INIT_29 => X"0328110010A6032B10001110032811001001F00290060328110210000339032B",
                    INIT_2A => X"032811001000D109D108D0071100B0020328110010A7D109D108D007B101B000",
                    INIT_2B => X"032810F4110103071494132212000328100111005000D109D108D007B101B000",
                    INIT_2C => X"0307147603071474030714960307149403071472030714700307149203071490",
                    INIT_2D => X"1474030714960307149403071472030714700307149203071490032810F51101",
                    INIT_2E => X"13031474030712401301030712001303147C032810F411015000030714760307",
                    INIT_2F => X"1474030712401301030712001303147C032810F5110103071240130103071200",
                    INIT_30 => X"11020339032B004011000339032B100011015000030712401301030712001303",
                    INIT_31 => X"11020339032B002011000339032B003011020339032B003011000339032B0040",
                    INIT_32 => X"B0005000D009D007D1085000D005D10650000339032B100011100339032B0020",
                    INIT_33 => X"B200B1009001233D10E211041200233D1038119C121C500002191300B202B101",
                    INIT_34 => X"000000000000000000000000000000000000000000000000000000005000633D",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"5AAA2A236AA80AA2355AAFC6A2D0A28BDF7DF7DF7DF7DB0A82AAA082A082A082",
                   INITP_01 => X"A8282A2355AA2F143F7F7DAA2355AB1AA8A0280A02A23776AA82AAA8A88D502D",
                   INITP_02 => X"50095655896AA00AAAA00AAAAAAAAAA00ABAAAAAAAA802AEAAAAAA802AEAAA00",
                   INITP_03 => X"8022377763777637776377763777602AAA0024A00AAA00AAA00AAA6666AAA555",
                   INITP_04 => X"208220A0A0A0A0A0A0A0A0A0A0A08200802AAA802802A2222AAA911122802802",
                   INITP_05 => X"20808208082020A2222222208888888882020AA082A082A08208220A08208828",
                   INITP_06 => X"0000000000000000000000000000000B560202802AAAA8282828282828282820",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a(13 downto 0),
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a(15 downto 0),
                      DOPADOP => data_out_a(17 downto 16), 
                        DIADI => data_in_a(15 downto 0),
                      DIPADIP => data_in_a(17 downto 16), 
                          WEA => "00",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b(13 downto 0),
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b(15 downto 0),
                      DOPBDOP => data_out_b(17 downto 16), 
                        DIBDI => data_in_b(15 downto 0),
                      DIPBDIP => data_in_b(17 downto 16), 
                        WEBWE => we_b(3 downto 0),
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0');
      --
    end generate akv7;
    --
  end generate ram_1k_generate;
  --
  --
  --
  ram_2k_generate : if (C_RAM_SIZE_KWORDS = 2) generate
    --
    --
    s6: if (C_FAMILY = "S6") generate
      --
      address_a(13 downto 0) <= address(10 downto 0) & "000";
      instruction <= data_out_a_h(32) & data_out_a_h(7 downto 0) & data_out_a_l(32) & data_out_a_l(7 downto 0);
      data_in_a <= "00000000000000000000000000000000000" & address(11);
      jtag_dout <= data_out_b_h(32) & data_out_b_h(7 downto 0) & data_out_b_l(32) & data_out_b_l(7 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b_l <= "000" & data_out_b_l(32) & "000000000000000000000000" & data_out_b_l(7 downto 0);
        data_in_b_h <= "000" & data_out_b_h(32) & "000000000000000000000000" & data_out_b_h(7 downto 0);
        address_b(13 downto 0) <= "00000000000000";
        we_b(3 downto 0) <= "0000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b_h <= "000" & jtag_din(17) & "000000000000000000000000" & jtag_din(16 downto 9);
        data_in_b_l <= "000" & jtag_din(8) & "000000000000000000000000" & jtag_din(7 downto 0);
        address_b(13 downto 0) <= jtag_addr(10 downto 0) & "000";
        we_b(3 downto 0) <= jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      --
      kcpsm6_rom_l: RAMB16BWER
      generic map ( DATA_WIDTH_A => 9,
                    DOA_REG => 0,
                    EN_RSTRAM_A => FALSE,
                    INIT_A => X"000000000",
                    RST_PRIORITY_A => "CE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    DATA_WIDTH_B => 9,
                    DOB_REG => 0,
                    EN_RSTRAM_B => FALSE,
                    INIT_B => X"000000000",
                    RST_PRIORITY_B => "CE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    RSTTYPE => "SYNC",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    SIM_DEVICE => "SPARTAN6",
                    INIT_00 => X"0A0100E4B63945090807001528017B09080700002800C8090807040028000C35",
                    INIT_01 => X"EB0800C70700BF06009E05009604007B03006C02005801005000B70001002022",
                    INIT_02 => X"0165000000FF957000B442406E0101C7000A010048040600000A02480A030000",
                    INIT_03 => X"000095706B00B46E0300B46E0052027702D1706B00B46E0220109A00B46E0052",
                    INIT_04 => X"706B00B46E0540A9706B00B43B9F6E0400B46E005204906050400201009A9000",
                    INIT_05 => X"6B00B41ABC6E060102BC6E060101BC6E07000000B46E005208B705B204AD03DB",
                    INIT_06 => X"80DF390002DF20F701DF0A007A00B46E005210D3E0D0C0B06B00B46E07018C70",
                    INIT_07 => X"001D1C070606051B1A00B46E005220F3E0D0C0B0A400B46E043BE96E08000190",
                    INIT_08 => X"004D3575FB75AE752F7529751900000005751F3B1EC30009080706051D1C1B1A",
                    INIT_09 => X"0006751F3B50C3004D35750F0D750175AE752F7529751900000006751F3B37C3",
                    INIT_0A => X"752F752F751900000005751F3B10004D35750F0D750775AE752F752975190000",
                    INIT_0B => X"000607060504003020100000403020100000000001004D3575190000001075AE",
                    INIT_0C => X"0400131211100013121110000150015001500150003B07060504E0D0C0B00000",
                    INIT_0D => X"02010000050403020100000000190B0A0908000B0A0908000706050400070605",
                    INIT_0E => X"69E56EE5670002DB64DB6FDB69DB740001D100D1BED111D1E200A01080000403",
                    INIT_0F => X"1970696E6700000005F972F969F974F9650004EF72EF65EF61EF640003E570E5",
                    INIT_10 => X"E200040302010000190150015001500150001A00197269746500197265616400",
                    INIT_11 => X"000000000000040302010000197768613F00196F6B61790004030002BE011100",
                    INIT_12 => X"392B0000392B0002392B0000392BA002392BA000392B00012801000000BE11E2",
                    INIT_13 => X"0C2B00002801000006280002392B000C392BA102392BA100392B0001392B0002",
                    INIT_14 => X"2800A62B00102800010206280200392B00042B00002801000106280200392B00",
                    INIT_15 => X"28F4010794220028010000090807010028000009080700022800A70908070100",
                    INIT_16 => X"7407960794077207700792079028F50107760774079607940772077007920790",
                    INIT_17 => X"740740010700037C28F501074001070003740740010700037C28F40100077607",
                    INIT_18 => X"02392B2000392B3002392B3000392B4002392B4000392B000100074001070003",
                    INIT_19 => X"0000013DE204003D389C1C0019000201000009070800050600392B0010392B20",
                    INIT_1A => X"000000000000000000000000000000000000000000000000000000000000003D",
                    INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"55345B153ABB45B3B4A52D01D9D669557B3476AD174900004924926025ADADAD",
                   INITP_01 => X"505D9765D9765D88A5028A5294ABB2A968A550ABEAA04BEAA625F5531FD54DAA",
                   INITP_02 => X"5AB6AD555555AAAAB55ADADAD71B6D36DA5DDDDDDDDDDDA528A514E634772514",
                   INITP_03 => X"0000000000000000000000000000000000000000000000015545096EEEEEEEAD",
                   INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(  ADDRA => address_a(13 downto 0),
                   ENA => enable,
                  CLKA => clk,
                   DOA => data_out_a_l(31 downto 0),
                  DOPA => data_out_a_l(35 downto 32), 
                   DIA => data_in_a(31 downto 0),
                  DIPA => data_in_a(35 downto 32), 
                   WEA => "0000",
                REGCEA => '0',
                  RSTA => '0',
                 ADDRB => address_b(13 downto 0),
                   ENB => enable_b,
                  CLKB => clk_b,
                   DOB => data_out_b_l(31 downto 0),
                  DOPB => data_out_b_l(35 downto 32), 
                   DIB => data_in_b_l(31 downto 0),
                  DIPB => data_in_b_l(35 downto 32), 
                   WEB => we_b(3 downto 0),
                REGCEB => '0',
                  RSTB => '0');
      -- 
      kcpsm6_rom_h: RAMB16BWER
      generic map ( DATA_WIDTH_A => 9,
                    DOA_REG => 0,
                    EN_RSTRAM_A => FALSE,
                    INIT_A => X"000000000",
                    RST_PRIORITY_A => "CE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    DATA_WIDTH_B => 9,
                    DOB_REG => 0,
                    EN_RSTRAM_B => FALSE,
                    INIT_B => X"000000000",
                    RST_PRIORITY_B => "CE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    RSTTYPE => "SYNC",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    SIM_DEVICE => "SPARTAN6",
                    INIT_00 => X"68080F0101010168686808080108086868680808010808686868080801080801",
                    INIT_01 => X"80EF8880EF8880EF8880EF8880EF8880EF8880EF8880EF8880EF00A818481000",
                    INIT_02 => X"08D0DAD9D9C80000280080818008E80028680828B0C818482868080068082888",
                    INIT_03 => X"D9C80000002800000828000008000890E8000000280000080404002800000800",
                    INIT_04 => X"0000280000080500000028000100000828000008000890D1D1C05B5A5A0090D9",
                    INIT_05 => X"0028000A1000080B0B1000080B0B1000080B0B28000008000890E890E890E800",
                    INIT_06 => X"00908080EB908080EB9080EB0028000008000890D2D1D1C00028008008CB0000",
                    INIT_07 => X"28787848486868585828000008000890D2D1D1C0002800000801908008D8C800",
                    INIT_08 => X"2800010000000000010001000109090808000101B00028696969686859595858",
                    INIT_09 => X"0808000101B0002800010001010001000000010001000109090808000101B000",
                    INIT_0A => X"0001000100010909080800010178280001000101000100000001000100010909",
                    INIT_0B => X"A6A55959585828979696852897969685280728DCCC2800010001090908580000",
                    INIT_0C => X"7D285A595958287A797978288A728A718A718A7028017979787891919080A7A6",
                    INIT_0D => X"696968284A4949484828E808280159595858287A797978285F5E5E5D287F7E7E",
                    INIT_0E => X"E9B0E9B0E82808B0EAB0E9B0E9B0E82808B0EAB0E9B0E9B0E828100008286A6A",
                    INIT_0F => X"010909080828082808B0EAB0E9B0E9B0E82808B0EAB0E9B0E9B0E82808B0EAB0",
                    INIT_10 => X"0828696969686828018A518A518A508A50280A28010909080828010909080828",
                    INIT_11 => X"280F0E0E0D286F6F6E6E6D280109090808280109090808286969096909680868",
                    INIT_12 => X"010108080101080801010808010108080101080801010808010808280F0E0E0D",
                    INIT_13 => X"0801080801080878480108080101080801010808010108080101080801010808",
                    INIT_14 => X"0108080108080108087848010808010108080108080108087848010808010108",
                    INIT_15 => X"010808010A090901080828686868585801080868686808580108086868685858",
                    INIT_16 => X"0A010A010A010A010A010A010A010808010A010A010A010A010A010A010A010A",
                    INIT_17 => X"0A0109090109090A0108080109090109090A0109090109090A01080828010A01",
                    INIT_18 => X"0801010008010100080101000801010008010100080101080828010909010909",
                    INIT_19 => X"D9D8C81108080911080809280109595858286868682868682801010808010100",
                    INIT_1A => X"00000000000000000000000000000000000000000000000000000000000028B1",
                    INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"E6750F70776F50F3EC631D55F9FEEA063F757E3D43F9D8DBB6DB6DB39FC9C9C9",
                   INITP_01 => X"8555555555555547F04C3F0FC3F55FC00210A7C3FC3FFFFC3FFFFE1FFFF87FF0",
                   INITP_02 => X"4892244D5554AAAA913C9C9C925324A6494CCCCCCCCCCC9087F861D57F805861",
                   INITP_03 => X"00000000000000000000000000000000000000000000000311187FE666666664",
                   INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(  ADDRA => address_a(13 downto 0),
                   ENA => enable,
                  CLKA => clk,
                   DOA => data_out_a_h(31 downto 0),
                  DOPA => data_out_a_h(35 downto 32), 
                   DIA => data_in_a(31 downto 0),
                  DIPA => data_in_a(35 downto 32), 
                   WEA => "0000",
                REGCEA => '0',
                  RSTA => '0',
                 ADDRB => address_b(13 downto 0),
                   ENB => enable_b,
                  CLKB => clk_b,
                   DOB => data_out_b_h(31 downto 0),
                  DOPB => data_out_b_h(35 downto 32), 
                   DIB => data_in_b_h(31 downto 0),
                  DIPB => data_in_b_h(35 downto 32), 
                   WEB => we_b(3 downto 0),
                REGCEB => '0',
                  RSTB => '0');
    --
    end generate s6;
    --
    --
    v6 : if (C_FAMILY = "V6") generate
      --
      address_a <= '0' & address(10 downto 0) & "0000";
      instruction <= data_out_a(33 downto 32) & data_out_a(15 downto 0);
      data_in_a <= "00000000000000000000000000000000000" & address(11);
      jtag_dout <= data_out_b(33 downto 32) & data_out_b(15 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b <= "00" & data_out_b(33 downto 32) & "0000000000000000" & data_out_b(15 downto 0);
        address_b <= "0000000000000000";
        we_b <= "00000000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b <= "00" & jtag_din(17 downto 16) & "0000000000000000" & jtag_din(15 downto 0);
        address_b <= '0' & jtag_addr(10 downto 0) & "0000";
        we_b <= jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      --
      kcpsm6_rom: RAMB36E1
      generic map ( READ_WIDTH_A => 18,
                    WRITE_WIDTH_A => 18,
                    DOA_REG => 0,
                    INIT_A => X"000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 18,
                    WRITE_WIDTH_B => 18,
                    DOB_REG => 0,
                    INIT_B => X"000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    EN_ECC_READ => FALSE,
                    EN_ECC_WRITE => FALSE,
                    RAM_EXTENSION_A => "NONE",
                    RAM_EXTENSION_B => "NONE",
                    SIM_DEVICE => "VIRTEX6",
                    INIT_00 => X"D108D007110010000328110010C8D109D108D0071104100003281100100C0335",
                    INIT_01 => X"D00A10011F0002E402B603390245D109D108D0071100101503281101107BD109",
                    INIT_02 => X"DF031000006CDF0210000058DF0110000050DF0001B750003001900020200022",
                    INIT_03 => X"00EBDF08100000C7DF07100000BFDF061000009EDF0510000096DF041000007B",
                    INIT_04 => X"5000D00A1001500060489004300690005000D00A10020048D00A100350001000",
                    INIT_05 => X"1001A065B400B300B20091FF01950170500001B400420240016E1001D00101C7",
                    INIT_06 => X"D00201D10170016B500001B4016E100209200810019A500001B4016E10000152",
                    INIT_07 => X"B200910001950170016B500001B4016E1003500001B4016E1000015210022077",
                    INIT_08 => X"500001B4016E1000015210042090A360A2508140B602B501B400019A2090B300",
                    INIT_09 => X"0170016B500001B4016E10050A4001A90170016B500001B4023B019F016E1004",
                    INIT_0A => X"100716001700500001B4016E10000152100820B7D00520B2D00420ADD00301DB",
                    INIT_0B => X"016B500001B4151A20BC016E10061601170220BC016E10061601170120BC016E",
                    INIT_0C => X"10000152101020D3A4E0A3D0A2C081B0016B500001B4016E10079601018C0170",
                    INIT_0D => X"008020DF01390100D70220DF012000F7D70120DF010AD700017A500001B4016E",
                    INIT_0E => X"A4E0A3D0A2C081B001A4500001B4016E1004023B20E9016E1008B10090010190",
                    INIT_0F => X"5000F11DF01C91079006D106D005B11BB01A500001B4016E10000152102020F3",
                    INIT_10 => X"10050175021F023B611E01C35000D309D308D207D106D005B31DB21CB11BB01A",
                    INIT_11 => X"5000004D0235017501FB017501AE0175032F0175022901750219130012001100",
                    INIT_12 => X"01AE0175032F017502290175021913001200110010060175021F023B613701C3",
                    INIT_13 => X"110010060175021F023B615001C35000004D02350175020F020D017502010175",
                    INIT_14 => X"02350175020F020D01750207017501AE0175032F017502290175021913001200",
                    INIT_15 => X"0175032F0175022F0175021913001200110010050175021F023BF0105000004D",
                    INIT_16 => X"50000F005000B90098015000004D023501750219130012001100B010017501AE",
                    INIT_17 => X"4C004B06B307B206B105B00450002E302D202C100B0050002E402D302C200B10",
                    INIT_18 => X"1501E2501501E1505000023BF307F206F105F00423E022D021C000B04E004D00",
                    INIT_19 => X"FB045000B413B312B211B1105000F413F312F211F11050001501E4501501E350",
                    INIT_1A => X"B109B0085000F40BF30AF209F1085000BE07BD06BC05BB045000FE07FD06FC05",
                    INIT_1B => X"D302D201D1005000940593049203910290015000D000100050000219B30BB20A",
                    INIT_1C => X"100161D1D40061D1D3BE61D1D21161D1D1E2500020A0001011805000D404D403",
                    INIT_1D => X"D36961E5D26E61E5D1675000100261DBD46461DBD36F61DBD26961DBD1745000",
                    INIT_1E => X"D1655000100461EFD47261EFD36561EFD26161EFD1645000100361E5D47061E5",
                    INIT_1F => X"021913701269116E1067500010005000100561F9D47261F9D36961F9D27461F9",
                    INIT_20 => X"A0505000151A5000021913721269117410655000021913721265116110645000",
                    INIT_21 => X"10E25000D304D303D202D101D000500002191501A3501501A2501501A1501501",
                    INIT_22 => X"103F50000219136F126B116110795000D304D3031300D20212BED1011111D000",
                    INIT_23 => X"50001E001D001C001B005000DE04DE03DD02DC01DB0050000219137712681161",
                    INIT_24 => X"0339032B10A011000339032B1000110103281001110050001E001DBE1C111BE2",
                    INIT_25 => X"0339032B100011000339032B100011020339032B100011000339032B10A01102",
                    INIT_26 => X"0339032B10A111020339032B10A111000339032B100011010339032B10001102",
                    INIT_27 => X"110C032B10001100032810011100F00090060328100011020339032B1000110C",
                    INIT_28 => X"10001104032B10001100032810011100F00190060328110210000339032B1000",
                    INIT_29 => X"0328110010A6032B10001110032811001001F00290060328110210000339032B",
                    INIT_2A => X"032811001000D109D108D0071100B0020328110010A7D109D108D007B101B000",
                    INIT_2B => X"032810F4110103071494132212000328100111005000D109D108D007B101B000",
                    INIT_2C => X"0307147603071474030714960307149403071472030714700307149203071490",
                    INIT_2D => X"1474030714960307149403071472030714700307149203071490032810F51101",
                    INIT_2E => X"13031474030712401301030712001303147C032810F411015000030714760307",
                    INIT_2F => X"1474030712401301030712001303147C032810F5110103071240130103071200",
                    INIT_30 => X"11020339032B004011000339032B100011015000030712401301030712001303",
                    INIT_31 => X"11020339032B002011000339032B003011020339032B003011000339032B0040",
                    INIT_32 => X"B0005000D009D007D1085000D005D10650000339032B100011100339032B0020",
                    INIT_33 => X"B200B1009001233D10E211041200233D1038119C121C500002191300B202B101",
                    INIT_34 => X"000000000000000000000000000000000000000000000000000000005000633D",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"5AAA2A236AA80AA2355AAFC6A2D0A28BDF7DF7DF7DF7DB0A82AAA082A082A082",
                   INITP_01 => X"A8282A2355AA2F143F7F7DAA2355AB1AA8A0280A02A23776AA82AAA8A88D502D",
                   INITP_02 => X"50095655896AA00AAAA00AAAAAAAAAA00ABAAAAAAAA802AEAAAAAA802AEAAA00",
                   INITP_03 => X"8022377763777637776377763777602AAA0024A00AAA00AAA00AAA6666AAA555",
                   INITP_04 => X"208220A0A0A0A0A0A0A0A0A0A0A08200802AAA802802A2222AAA911122802802",
                   INITP_05 => X"20808208082020A2222222208888888882020AA082A082A08208220A08208828",
                   INITP_06 => X"0000000000000000000000000000000B560202802AAAA8282828282828282820",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a,
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a(31 downto 0),
                      DOPADOP => data_out_a(35 downto 32), 
                        DIADI => data_in_a(31 downto 0),
                      DIPADIP => data_in_a(35 downto 32), 
                          WEA => "0000",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b,
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b(31 downto 0),
                      DOPBDOP => data_out_b(35 downto 32), 
                        DIBDI => data_in_b(31 downto 0),
                      DIPBDIP => data_in_b(35 downto 32), 
                        WEBWE => we_b,
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0',
                   CASCADEINA => '0',
                   CASCADEINB => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0');
      --
    end generate v6;
    --
    --
    akv7 : if (C_FAMILY = "7S") generate
      --
      address_a <= '0' & address(10 downto 0) & "0000";
      instruction <= data_out_a(33 downto 32) & data_out_a(15 downto 0);
      data_in_a <= "00000000000000000000000000000000000" & address(11);
      jtag_dout <= data_out_b(33 downto 32) & data_out_b(15 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b <= "00" & data_out_b(33 downto 32) & "0000000000000000" & data_out_b(15 downto 0);
        address_b <= "0000000000000000";
        we_b <= "00000000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b <= "00" & jtag_din(17 downto 16) & "0000000000000000" & jtag_din(15 downto 0);
        address_b <= '0' & jtag_addr(10 downto 0) & "0000";
        we_b <= jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      --
      kcpsm6_rom: RAMB36E1
      generic map ( READ_WIDTH_A => 18,
                    WRITE_WIDTH_A => 18,
                    DOA_REG => 0,
                    INIT_A => X"000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 18,
                    WRITE_WIDTH_B => 18,
                    DOB_REG => 0,
                    INIT_B => X"000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    EN_ECC_READ => FALSE,
                    EN_ECC_WRITE => FALSE,
                    RAM_EXTENSION_A => "NONE",
                    RAM_EXTENSION_B => "NONE",
                    SIM_DEVICE => "7SERIES",
                    INIT_00 => X"D108D007110010000328110010C8D109D108D0071104100003281100100C0335",
                    INIT_01 => X"D00A10011F0002E402B603390245D109D108D0071100101503281101107BD109",
                    INIT_02 => X"DF031000006CDF0210000058DF0110000050DF0001B750003001900020200022",
                    INIT_03 => X"00EBDF08100000C7DF07100000BFDF061000009EDF0510000096DF041000007B",
                    INIT_04 => X"5000D00A1001500060489004300690005000D00A10020048D00A100350001000",
                    INIT_05 => X"1001A065B400B300B20091FF01950170500001B400420240016E1001D00101C7",
                    INIT_06 => X"D00201D10170016B500001B4016E100209200810019A500001B4016E10000152",
                    INIT_07 => X"B200910001950170016B500001B4016E1003500001B4016E1000015210022077",
                    INIT_08 => X"500001B4016E1000015210042090A360A2508140B602B501B400019A2090B300",
                    INIT_09 => X"0170016B500001B4016E10050A4001A90170016B500001B4023B019F016E1004",
                    INIT_0A => X"100716001700500001B4016E10000152100820B7D00520B2D00420ADD00301DB",
                    INIT_0B => X"016B500001B4151A20BC016E10061601170220BC016E10061601170120BC016E",
                    INIT_0C => X"10000152101020D3A4E0A3D0A2C081B0016B500001B4016E10079601018C0170",
                    INIT_0D => X"008020DF01390100D70220DF012000F7D70120DF010AD700017A500001B4016E",
                    INIT_0E => X"A4E0A3D0A2C081B001A4500001B4016E1004023B20E9016E1008B10090010190",
                    INIT_0F => X"5000F11DF01C91079006D106D005B11BB01A500001B4016E10000152102020F3",
                    INIT_10 => X"10050175021F023B611E01C35000D309D308D207D106D005B31DB21CB11BB01A",
                    INIT_11 => X"5000004D0235017501FB017501AE0175032F0175022901750219130012001100",
                    INIT_12 => X"01AE0175032F017502290175021913001200110010060175021F023B613701C3",
                    INIT_13 => X"110010060175021F023B615001C35000004D02350175020F020D017502010175",
                    INIT_14 => X"02350175020F020D01750207017501AE0175032F017502290175021913001200",
                    INIT_15 => X"0175032F0175022F0175021913001200110010050175021F023BF0105000004D",
                    INIT_16 => X"50000F005000B90098015000004D023501750219130012001100B010017501AE",
                    INIT_17 => X"4C004B06B307B206B105B00450002E302D202C100B0050002E402D302C200B10",
                    INIT_18 => X"1501E2501501E1505000023BF307F206F105F00423E022D021C000B04E004D00",
                    INIT_19 => X"FB045000B413B312B211B1105000F413F312F211F11050001501E4501501E350",
                    INIT_1A => X"B109B0085000F40BF30AF209F1085000BE07BD06BC05BB045000FE07FD06FC05",
                    INIT_1B => X"D302D201D1005000940593049203910290015000D000100050000219B30BB20A",
                    INIT_1C => X"100161D1D40061D1D3BE61D1D21161D1D1E2500020A0001011805000D404D403",
                    INIT_1D => X"D36961E5D26E61E5D1675000100261DBD46461DBD36F61DBD26961DBD1745000",
                    INIT_1E => X"D1655000100461EFD47261EFD36561EFD26161EFD1645000100361E5D47061E5",
                    INIT_1F => X"021913701269116E1067500010005000100561F9D47261F9D36961F9D27461F9",
                    INIT_20 => X"A0505000151A5000021913721269117410655000021913721265116110645000",
                    INIT_21 => X"10E25000D304D303D202D101D000500002191501A3501501A2501501A1501501",
                    INIT_22 => X"103F50000219136F126B116110795000D304D3031300D20212BED1011111D000",
                    INIT_23 => X"50001E001D001C001B005000DE04DE03DD02DC01DB0050000219137712681161",
                    INIT_24 => X"0339032B10A011000339032B1000110103281001110050001E001DBE1C111BE2",
                    INIT_25 => X"0339032B100011000339032B100011020339032B100011000339032B10A01102",
                    INIT_26 => X"0339032B10A111020339032B10A111000339032B100011010339032B10001102",
                    INIT_27 => X"110C032B10001100032810011100F00090060328100011020339032B1000110C",
                    INIT_28 => X"10001104032B10001100032810011100F00190060328110210000339032B1000",
                    INIT_29 => X"0328110010A6032B10001110032811001001F00290060328110210000339032B",
                    INIT_2A => X"032811001000D109D108D0071100B0020328110010A7D109D108D007B101B000",
                    INIT_2B => X"032810F4110103071494132212000328100111005000D109D108D007B101B000",
                    INIT_2C => X"0307147603071474030714960307149403071472030714700307149203071490",
                    INIT_2D => X"1474030714960307149403071472030714700307149203071490032810F51101",
                    INIT_2E => X"13031474030712401301030712001303147C032810F411015000030714760307",
                    INIT_2F => X"1474030712401301030712001303147C032810F5110103071240130103071200",
                    INIT_30 => X"11020339032B004011000339032B100011015000030712401301030712001303",
                    INIT_31 => X"11020339032B002011000339032B003011020339032B003011000339032B0040",
                    INIT_32 => X"B0005000D009D007D1085000D005D10650000339032B100011100339032B0020",
                    INIT_33 => X"B200B1009001233D10E211041200233D1038119C121C500002191300B202B101",
                    INIT_34 => X"000000000000000000000000000000000000000000000000000000005000633D",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"5AAA2A236AA80AA2355AAFC6A2D0A28BDF7DF7DF7DF7DB0A82AAA082A082A082",
                   INITP_01 => X"A8282A2355AA2F143F7F7DAA2355AB1AA8A0280A02A23776AA82AAA8A88D502D",
                   INITP_02 => X"50095655896AA00AAAA00AAAAAAAAAA00ABAAAAAAAA802AEAAAAAA802AEAAA00",
                   INITP_03 => X"8022377763777637776377763777602AAA0024A00AAA00AAA00AAA6666AAA555",
                   INITP_04 => X"208220A0A0A0A0A0A0A0A0A0A0A08200802AAA802802A2222AAA911122802802",
                   INITP_05 => X"20808208082020A2222222208888888882020AA082A082A08208220A08208828",
                   INITP_06 => X"0000000000000000000000000000000B560202802AAAA8282828282828282820",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a,
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a(31 downto 0),
                      DOPADOP => data_out_a(35 downto 32), 
                        DIADI => data_in_a(31 downto 0),
                      DIPADIP => data_in_a(35 downto 32), 
                          WEA => "0000",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b,
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b(31 downto 0),
                      DOPBDOP => data_out_b(35 downto 32), 
                        DIBDI => data_in_b(31 downto 0),
                      DIPBDIP => data_in_b(35 downto 32), 
                        WEBWE => we_b,
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0',
                   CASCADEINA => '0',
                   CASCADEINB => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0');
      --
    end generate akv7;
    --
  end generate ram_2k_generate;
  --
  --	
  ram_4k_generate : if (C_RAM_SIZE_KWORDS = 4) generate
    s6: if (C_FAMILY = "S6") generate
      assert(1=0) report "4K BRAM in Spartan-6 is a special case not supported by this template." severity FAILURE;
    end generate s6;
    --
    --
    v6 : if (C_FAMILY = "V6") generate
      --
      address_a <= '0' & address(11 downto 0) & "000";
      instruction <= data_out_a_h(32) & data_out_a_h(7 downto 0) & data_out_a_l(32) & data_out_a_l(7 downto 0);
      data_in_a <= "000000000000000000000000000000000000";
      jtag_dout <= data_out_b_h(32) & data_out_b_h(7 downto 0) & data_out_b_l(32) & data_out_b_l(7 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b_l <= "000" & data_out_b_l(32) & "000000000000000000000000" & data_out_b_l(7 downto 0);
        data_in_b_h <= "000" & data_out_b_h(32) & "000000000000000000000000" & data_out_b_h(7 downto 0);
        address_b <= "0000000000000000";
        we_b <= "00000000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b_h <= "000" & jtag_din(17) & "000000000000000000000000" & jtag_din(16 downto 9);
        data_in_b_l <= "000" & jtag_din(8) & "000000000000000000000000" & jtag_din(7 downto 0);
        address_b <= '0' & jtag_addr(11 downto 0) & "000";
        we_b <= jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      --
      kcpsm6_rom_l: RAMB36E1
      generic map ( READ_WIDTH_A => 9,
                    WRITE_WIDTH_A => 9,
                    DOA_REG => 0,
                    INIT_A => X"000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 9,
                    WRITE_WIDTH_B => 9,
                    DOB_REG => 0,
                    INIT_B => X"000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    EN_ECC_READ => FALSE,
                    EN_ECC_WRITE => FALSE,
                    RAM_EXTENSION_A => "NONE",
                    RAM_EXTENSION_B => "NONE",
                    SIM_DEVICE => "VIRTEX6",
                    INIT_00 => X"0A0100E4B63945090807001528017B09080700002800C8090807040028000C35",
                    INIT_01 => X"EB0800C70700BF06009E05009604007B03006C02005801005000B70001002022",
                    INIT_02 => X"0165000000FF957000B442406E0101C7000A010048040600000A02480A030000",
                    INIT_03 => X"000095706B00B46E0300B46E0052027702D1706B00B46E0220109A00B46E0052",
                    INIT_04 => X"706B00B46E0540A9706B00B43B9F6E0400B46E005204906050400201009A9000",
                    INIT_05 => X"6B00B41ABC6E060102BC6E060101BC6E07000000B46E005208B705B204AD03DB",
                    INIT_06 => X"80DF390002DF20F701DF0A007A00B46E005210D3E0D0C0B06B00B46E07018C70",
                    INIT_07 => X"001D1C070606051B1A00B46E005220F3E0D0C0B0A400B46E043BE96E08000190",
                    INIT_08 => X"004D3575FB75AE752F7529751900000005751F3B1EC30009080706051D1C1B1A",
                    INIT_09 => X"0006751F3B50C3004D35750F0D750175AE752F7529751900000006751F3B37C3",
                    INIT_0A => X"752F752F751900000005751F3B10004D35750F0D750775AE752F752975190000",
                    INIT_0B => X"000607060504003020100000403020100000000001004D3575190000001075AE",
                    INIT_0C => X"0400131211100013121110000150015001500150003B07060504E0D0C0B00000",
                    INIT_0D => X"02010000050403020100000000190B0A0908000B0A0908000706050400070605",
                    INIT_0E => X"69E56EE5670002DB64DB6FDB69DB740001D100D1BED111D1E200A01080000403",
                    INIT_0F => X"1970696E6700000005F972F969F974F9650004EF72EF65EF61EF640003E570E5",
                    INIT_10 => X"E200040302010000190150015001500150001A00197269746500197265616400",
                    INIT_11 => X"000000000000040302010000197768613F00196F6B61790004030002BE011100",
                    INIT_12 => X"392B0000392B0002392B0000392BA002392BA000392B00012801000000BE11E2",
                    INIT_13 => X"0C2B00002801000006280002392B000C392BA102392BA100392B0001392B0002",
                    INIT_14 => X"2800A62B00102800010206280200392B00042B00002801000106280200392B00",
                    INIT_15 => X"28F4010794220028010000090807010028000009080700022800A70908070100",
                    INIT_16 => X"7407960794077207700792079028F50107760774079607940772077007920790",
                    INIT_17 => X"740740010700037C28F501074001070003740740010700037C28F40100077607",
                    INIT_18 => X"02392B2000392B3002392B3000392B4002392B4000392B000100074001070003",
                    INIT_19 => X"0000013DE204003D389C1C0019000201000009070800050600392B0010392B20",
                    INIT_1A => X"000000000000000000000000000000000000000000000000000000000000003D",
                    INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"55345B153ABB45B3B4A52D01D9D669557B3476AD174900004924926025ADADAD",
                   INITP_01 => X"505D9765D9765D88A5028A5294ABB2A968A550ABEAA04BEAA625F5531FD54DAA",
                   INITP_02 => X"5AB6AD555555AAAAB55ADADAD71B6D36DA5DDDDDDDDDDDA528A514E634772514",
                   INITP_03 => X"0000000000000000000000000000000000000000000000015545096EEEEEEEAD",
                   INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a,
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a_l(31 downto 0),
                      DOPADOP => data_out_a_l(35 downto 32), 
                        DIADI => data_in_a(31 downto 0),
                      DIPADIP => data_in_a(35 downto 32), 
                          WEA => "0000",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b,
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b_l(31 downto 0),
                      DOPBDOP => data_out_b_l(35 downto 32), 
                        DIBDI => data_in_b_l(31 downto 0),
                      DIPBDIP => data_in_b_l(35 downto 32), 
                        WEBWE => we_b,
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0',
                   CASCADEINA => '0',
                   CASCADEINB => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0');
      --
      kcpsm6_rom_h: RAMB36E1
      generic map ( READ_WIDTH_A => 9,
                    WRITE_WIDTH_A => 9,
                    DOA_REG => 0,
                    INIT_A => X"000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 9,
                    WRITE_WIDTH_B => 9,
                    DOB_REG => 0,
                    INIT_B => X"000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    EN_ECC_READ => FALSE,
                    EN_ECC_WRITE => FALSE,
                    RAM_EXTENSION_A => "NONE",
                    RAM_EXTENSION_B => "NONE",
                    SIM_DEVICE => "VIRTEX6",
                    INIT_00 => X"68080F0101010168686808080108086868680808010808686868080801080801",
                    INIT_01 => X"80EF8880EF8880EF8880EF8880EF8880EF8880EF8880EF8880EF00A818481000",
                    INIT_02 => X"08D0DAD9D9C80000280080818008E80028680828B0C818482868080068082888",
                    INIT_03 => X"D9C80000002800000828000008000890E8000000280000080404002800000800",
                    INIT_04 => X"0000280000080500000028000100000828000008000890D1D1C05B5A5A0090D9",
                    INIT_05 => X"0028000A1000080B0B1000080B0B1000080B0B28000008000890E890E890E800",
                    INIT_06 => X"00908080EB908080EB9080EB0028000008000890D2D1D1C00028008008CB0000",
                    INIT_07 => X"28787848486868585828000008000890D2D1D1C0002800000801908008D8C800",
                    INIT_08 => X"2800010000000000010001000109090808000101B00028696969686859595858",
                    INIT_09 => X"0808000101B0002800010001010001000000010001000109090808000101B000",
                    INIT_0A => X"0001000100010909080800010178280001000101000100000001000100010909",
                    INIT_0B => X"A6A55959585828979696852897969685280728DCCC2800010001090908580000",
                    INIT_0C => X"7D285A595958287A797978288A728A718A718A7028017979787891919080A7A6",
                    INIT_0D => X"696968284A4949484828E808280159595858287A797978285F5E5E5D287F7E7E",
                    INIT_0E => X"E9B0E9B0E82808B0EAB0E9B0E9B0E82808B0EAB0E9B0E9B0E828100008286A6A",
                    INIT_0F => X"010909080828082808B0EAB0E9B0E9B0E82808B0EAB0E9B0E9B0E82808B0EAB0",
                    INIT_10 => X"0828696969686828018A518A518A508A50280A28010909080828010909080828",
                    INIT_11 => X"280F0E0E0D286F6F6E6E6D280109090808280109090808286969096909680868",
                    INIT_12 => X"010108080101080801010808010108080101080801010808010808280F0E0E0D",
                    INIT_13 => X"0801080801080878480108080101080801010808010108080101080801010808",
                    INIT_14 => X"0108080108080108087848010808010108080108080108087848010808010108",
                    INIT_15 => X"010808010A090901080828686868585801080868686808580108086868685858",
                    INIT_16 => X"0A010A010A010A010A010A010A010808010A010A010A010A010A010A010A010A",
                    INIT_17 => X"0A0109090109090A0108080109090109090A0109090109090A01080828010A01",
                    INIT_18 => X"0801010008010100080101000801010008010100080101080828010909010909",
                    INIT_19 => X"D9D8C81108080911080809280109595858286868682868682801010808010100",
                    INIT_1A => X"00000000000000000000000000000000000000000000000000000000000028B1",
                    INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"E6750F70776F50F3EC631D55F9FEEA063F757E3D43F9D8DBB6DB6DB39FC9C9C9",
                   INITP_01 => X"8555555555555547F04C3F0FC3F55FC00210A7C3FC3FFFFC3FFFFE1FFFF87FF0",
                   INITP_02 => X"4892244D5554AAAA913C9C9C925324A6494CCCCCCCCCCC9087F861D57F805861",
                   INITP_03 => X"00000000000000000000000000000000000000000000000311187FE666666664",
                   INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a,
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a_h(31 downto 0),
                      DOPADOP => data_out_a_h(35 downto 32), 
                        DIADI => data_in_a(31 downto 0),
                      DIPADIP => data_in_a(35 downto 32), 
                          WEA => "0000",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b,
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b_h(31 downto 0),
                      DOPBDOP => data_out_b_h(35 downto 32), 
                        DIBDI => data_in_b_h(31 downto 0),
                      DIPBDIP => data_in_b_h(35 downto 32), 
                        WEBWE => we_b,
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0',
                   CASCADEINA => '0',
                   CASCADEINB => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0');
      --
    end generate v6;
    --
    --
    akv7 : if (C_FAMILY = "7S") generate
      --
      address_a <= '0' & address(11 downto 0) & "000";
      instruction <= data_out_a_h(32) & data_out_a_h(7 downto 0) & data_out_a_l(32) & data_out_a_l(7 downto 0);
      data_in_a <= "000000000000000000000000000000000000";
      jtag_dout <= data_out_b_h(32) & data_out_b_h(7 downto 0) & data_out_b_l(32) & data_out_b_l(7 downto 0);
      --
      no_loader : if (C_JTAG_LOADER_ENABLE = 0) generate
        data_in_b_l <= "000" & data_out_b_l(32) & "000000000000000000000000" & data_out_b_l(7 downto 0);
        data_in_b_h <= "000" & data_out_b_h(32) & "000000000000000000000000" & data_out_b_h(7 downto 0);
        address_b <= "0000000000000000";
        we_b <= "00000000";
        enable_b <= '0';
        rdl <= '0';
        clk_b <= '0';
      end generate no_loader;
      --
      loader : if (C_JTAG_LOADER_ENABLE = 1) generate
        data_in_b_h <= "000" & jtag_din(17) & "000000000000000000000000" & jtag_din(16 downto 9);
        data_in_b_l <= "000" & jtag_din(8) & "000000000000000000000000" & jtag_din(7 downto 0);
        address_b <= '0' & jtag_addr(11 downto 0) & "000";
        we_b <= jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we & jtag_we;
        enable_b <= jtag_en(0);
        rdl <= rdl_bus(0);
        clk_b <= jtag_clk;
      end generate loader;
      --
      kcpsm6_rom_l: RAMB36E1
      generic map ( READ_WIDTH_A => 9,
                    WRITE_WIDTH_A => 9,
                    DOA_REG => 0,
                    INIT_A => X"000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 9,
                    WRITE_WIDTH_B => 9,
                    DOB_REG => 0,
                    INIT_B => X"000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    EN_ECC_READ => FALSE,
                    EN_ECC_WRITE => FALSE,
                    RAM_EXTENSION_A => "NONE",
                    RAM_EXTENSION_B => "NONE",
                    SIM_DEVICE => "7SERIES",
                    INIT_00 => X"0A0100E4B63945090807001528017B09080700002800C8090807040028000C35",
                    INIT_01 => X"EB0800C70700BF06009E05009604007B03006C02005801005000B70001002022",
                    INIT_02 => X"0165000000FF957000B442406E0101C7000A010048040600000A02480A030000",
                    INIT_03 => X"000095706B00B46E0300B46E0052027702D1706B00B46E0220109A00B46E0052",
                    INIT_04 => X"706B00B46E0540A9706B00B43B9F6E0400B46E005204906050400201009A9000",
                    INIT_05 => X"6B00B41ABC6E060102BC6E060101BC6E07000000B46E005208B705B204AD03DB",
                    INIT_06 => X"80DF390002DF20F701DF0A007A00B46E005210D3E0D0C0B06B00B46E07018C70",
                    INIT_07 => X"001D1C070606051B1A00B46E005220F3E0D0C0B0A400B46E043BE96E08000190",
                    INIT_08 => X"004D3575FB75AE752F7529751900000005751F3B1EC30009080706051D1C1B1A",
                    INIT_09 => X"0006751F3B50C3004D35750F0D750175AE752F7529751900000006751F3B37C3",
                    INIT_0A => X"752F752F751900000005751F3B10004D35750F0D750775AE752F752975190000",
                    INIT_0B => X"000607060504003020100000403020100000000001004D3575190000001075AE",
                    INIT_0C => X"0400131211100013121110000150015001500150003B07060504E0D0C0B00000",
                    INIT_0D => X"02010000050403020100000000190B0A0908000B0A0908000706050400070605",
                    INIT_0E => X"69E56EE5670002DB64DB6FDB69DB740001D100D1BED111D1E200A01080000403",
                    INIT_0F => X"1970696E6700000005F972F969F974F9650004EF72EF65EF61EF640003E570E5",
                    INIT_10 => X"E200040302010000190150015001500150001A00197269746500197265616400",
                    INIT_11 => X"000000000000040302010000197768613F00196F6B61790004030002BE011100",
                    INIT_12 => X"392B0000392B0002392B0000392BA002392BA000392B00012801000000BE11E2",
                    INIT_13 => X"0C2B00002801000006280002392B000C392BA102392BA100392B0001392B0002",
                    INIT_14 => X"2800A62B00102800010206280200392B00042B00002801000106280200392B00",
                    INIT_15 => X"28F4010794220028010000090807010028000009080700022800A70908070100",
                    INIT_16 => X"7407960794077207700792079028F50107760774079607940772077007920790",
                    INIT_17 => X"740740010700037C28F501074001070003740740010700037C28F40100077607",
                    INIT_18 => X"02392B2000392B3002392B3000392B4002392B4000392B000100074001070003",
                    INIT_19 => X"0000013DE204003D389C1C0019000201000009070800050600392B0010392B20",
                    INIT_1A => X"000000000000000000000000000000000000000000000000000000000000003D",
                    INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"55345B153ABB45B3B4A52D01D9D669557B3476AD174900004924926025ADADAD",
                   INITP_01 => X"505D9765D9765D88A5028A5294ABB2A968A550ABEAA04BEAA625F5531FD54DAA",
                   INITP_02 => X"5AB6AD555555AAAAB55ADADAD71B6D36DA5DDDDDDDDDDDA528A514E634772514",
                   INITP_03 => X"0000000000000000000000000000000000000000000000015545096EEEEEEEAD",
                   INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a,
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a_l(31 downto 0),
                      DOPADOP => data_out_a_l(35 downto 32), 
                        DIADI => data_in_a(31 downto 0),
                      DIPADIP => data_in_a(35 downto 32), 
                          WEA => "0000",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b,
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b_l(31 downto 0),
                      DOPBDOP => data_out_b_l(35 downto 32), 
                        DIBDI => data_in_b_l(31 downto 0),
                      DIPBDIP => data_in_b_l(35 downto 32), 
                        WEBWE => we_b,
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0',
                   CASCADEINA => '0',
                   CASCADEINB => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0');
      --
      kcpsm6_rom_h: RAMB36E1
      generic map ( READ_WIDTH_A => 9,
                    WRITE_WIDTH_A => 9,
                    DOA_REG => 0,
                    INIT_A => X"000000000",
                    RSTREG_PRIORITY_A => "REGCE",
                    SRVAL_A => X"000000000",
                    WRITE_MODE_A => "WRITE_FIRST",
                    READ_WIDTH_B => 9,
                    WRITE_WIDTH_B => 9,
                    DOB_REG => 0,
                    INIT_B => X"000000000",
                    RSTREG_PRIORITY_B => "REGCE",
                    SRVAL_B => X"000000000",
                    WRITE_MODE_B => "WRITE_FIRST",
                    INIT_FILE => "NONE",
                    SIM_COLLISION_CHECK => "ALL",
                    RAM_MODE => "TDP",
                    RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                    EN_ECC_READ => FALSE,
                    EN_ECC_WRITE => FALSE,
                    RAM_EXTENSION_A => "NONE",
                    RAM_EXTENSION_B => "NONE",
                    SIM_DEVICE => "7SERIES",
                    INIT_00 => X"68080F0101010168686808080108086868680808010808686868080801080801",
                    INIT_01 => X"80EF8880EF8880EF8880EF8880EF8880EF8880EF8880EF8880EF00A818481000",
                    INIT_02 => X"08D0DAD9D9C80000280080818008E80028680828B0C818482868080068082888",
                    INIT_03 => X"D9C80000002800000828000008000890E8000000280000080404002800000800",
                    INIT_04 => X"0000280000080500000028000100000828000008000890D1D1C05B5A5A0090D9",
                    INIT_05 => X"0028000A1000080B0B1000080B0B1000080B0B28000008000890E890E890E800",
                    INIT_06 => X"00908080EB908080EB9080EB0028000008000890D2D1D1C00028008008CB0000",
                    INIT_07 => X"28787848486868585828000008000890D2D1D1C0002800000801908008D8C800",
                    INIT_08 => X"2800010000000000010001000109090808000101B00028696969686859595858",
                    INIT_09 => X"0808000101B0002800010001010001000000010001000109090808000101B000",
                    INIT_0A => X"0001000100010909080800010178280001000101000100000001000100010909",
                    INIT_0B => X"A6A55959585828979696852897969685280728DCCC2800010001090908580000",
                    INIT_0C => X"7D285A595958287A797978288A728A718A718A7028017979787891919080A7A6",
                    INIT_0D => X"696968284A4949484828E808280159595858287A797978285F5E5E5D287F7E7E",
                    INIT_0E => X"E9B0E9B0E82808B0EAB0E9B0E9B0E82808B0EAB0E9B0E9B0E828100008286A6A",
                    INIT_0F => X"010909080828082808B0EAB0E9B0E9B0E82808B0EAB0E9B0E9B0E82808B0EAB0",
                    INIT_10 => X"0828696969686828018A518A518A508A50280A28010909080828010909080828",
                    INIT_11 => X"280F0E0E0D286F6F6E6E6D280109090808280109090808286969096909680868",
                    INIT_12 => X"010108080101080801010808010108080101080801010808010808280F0E0E0D",
                    INIT_13 => X"0801080801080878480108080101080801010808010108080101080801010808",
                    INIT_14 => X"0108080108080108087848010808010108080108080108087848010808010108",
                    INIT_15 => X"010808010A090901080828686868585801080868686808580108086868685858",
                    INIT_16 => X"0A010A010A010A010A010A010A010808010A010A010A010A010A010A010A010A",
                    INIT_17 => X"0A0109090109090A0108080109090109090A0109090109090A01080828010A01",
                    INIT_18 => X"0801010008010100080101000801010008010100080101080828010909010909",
                    INIT_19 => X"D9D8C81108080911080809280109595858286868682868682801010808010100",
                    INIT_1A => X"00000000000000000000000000000000000000000000000000000000000028B1",
                    INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
                    INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_00 => X"E6750F70776F50F3EC631D55F9FEEA063F757E3D43F9D8DBB6DB6DB39FC9C9C9",
                   INITP_01 => X"8555555555555547F04C3F0FC3F55FC00210A7C3FC3FFFFC3FFFFE1FFFF87FF0",
                   INITP_02 => X"4892244D5554AAAA913C9C9C925324A6494CCCCCCCCCCC9087F861D57F805861",
                   INITP_03 => X"00000000000000000000000000000000000000000000000311187FE666666664",
                   INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
                   INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
      port map(   ADDRARDADDR => address_a,
                      ENARDEN => enable,
                    CLKARDCLK => clk,
                        DOADO => data_out_a_h(31 downto 0),
                      DOPADOP => data_out_a_h(35 downto 32), 
                        DIADI => data_in_a(31 downto 0),
                      DIPADIP => data_in_a(35 downto 32), 
                          WEA => "0000",
                  REGCEAREGCE => '0',
                RSTRAMARSTRAM => '0',
                RSTREGARSTREG => '0',
                  ADDRBWRADDR => address_b,
                      ENBWREN => enable_b,
                    CLKBWRCLK => clk_b,
                        DOBDO => data_out_b_h(31 downto 0),
                      DOPBDOP => data_out_b_h(35 downto 32), 
                        DIBDI => data_in_b_h(31 downto 0),
                      DIPBDIP => data_in_b_h(35 downto 32), 
                        WEBWE => we_b,
                       REGCEB => '0',
                      RSTRAMB => '0',
                      RSTREGB => '0',
                   CASCADEINA => '0',
                   CASCADEINB => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0');
      --
    end generate akv7;
    --
  end generate ram_4k_generate;	              
  --
  --
  --
  --
  -- JTAG Loader
  --
  instantiate_loader : if (C_JTAG_LOADER_ENABLE = 1) generate
  --
    jtag_loader_6_inst : jtag_loader_6
    generic map(              C_FAMILY => C_FAMILY,
                       C_NUM_PICOBLAZE => 1,
                  C_JTAG_LOADER_ENABLE => C_JTAG_LOADER_ENABLE,
                 C_BRAM_MAX_ADDR_WIDTH => BRAM_ADDRESS_WIDTH,
	                  C_ADDR_WIDTH_0 => BRAM_ADDRESS_WIDTH)
    port map( picoblaze_reset => rdl_bus,
                      jtag_en => jtag_en,
                     jtag_din => jtag_din,
                    jtag_addr => jtag_addr(BRAM_ADDRESS_WIDTH-1 downto 0),
                     jtag_clk => jtag_clk,
                      jtag_we => jtag_we,
                  jtag_dout_0 => jtag_dout,
                  jtag_dout_1 => jtag_dout, -- ports 1-7 are not used
                  jtag_dout_2 => jtag_dout, -- in a 1 device debug 
                  jtag_dout_3 => jtag_dout, -- session.  However, Synplify
                  jtag_dout_4 => jtag_dout, -- etc require all ports to
                  jtag_dout_5 => jtag_dout, -- be connected
                  jtag_dout_6 => jtag_dout,
                  jtag_dout_7 => jtag_dout);
    --  
  end generate instantiate_loader;
  --
end low_level_definition;
--
--
-------------------------------------------------------------------------------------------
--
-- JTAG Loader 
--
-------------------------------------------------------------------------------------------
--
--
-- JTAG Loader 6 - Version 6.00
-- Kris Chaplin 4 February 2010
-- Ken Chapman 15 August 2011 - Revised coding style
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
library unisim;
use unisim.vcomponents.all;
--
entity jtag_loader_6 is
generic(              C_JTAG_LOADER_ENABLE : integer := 1;
                                  C_FAMILY : string := "V6";
                           C_NUM_PICOBLAZE : integer := 1;
                     C_BRAM_MAX_ADDR_WIDTH : integer := 10;
        C_PICOBLAZE_INSTRUCTION_DATA_WIDTH : integer := 18;
                              C_JTAG_CHAIN : integer := 2;
                            C_ADDR_WIDTH_0 : integer := 10;
                            C_ADDR_WIDTH_1 : integer := 10;
                            C_ADDR_WIDTH_2 : integer := 10;
                            C_ADDR_WIDTH_3 : integer := 10;
                            C_ADDR_WIDTH_4 : integer := 10;
                            C_ADDR_WIDTH_5 : integer := 10;
                            C_ADDR_WIDTH_6 : integer := 10;
                            C_ADDR_WIDTH_7 : integer := 10);
port(   picoblaze_reset : out std_logic_vector(C_NUM_PICOBLAZE-1 downto 0);
                jtag_en : out std_logic_vector(C_NUM_PICOBLAZE-1 downto 0) := (others => '0');
               jtag_din : out std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0) := (others => '0');
              jtag_addr : out std_logic_vector(C_BRAM_MAX_ADDR_WIDTH-1 downto 0) := (others => '0');
               jtag_clk : out std_logic := '0';
                jtag_we : out std_logic := '0';
            jtag_dout_0 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_1 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_2 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_3 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_4 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_5 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_6 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
            jtag_dout_7 : in  std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0));
end jtag_loader_6;
--
architecture Behavioral of jtag_loader_6 is
  --
  signal num_picoblaze       : std_logic_vector(2 downto 0);
  signal picoblaze_instruction_data_width : std_logic_vector(4 downto 0);
  --
  signal drck                : std_logic;
  signal shift_clk           : std_logic;
  signal shift_din           : std_logic;
  signal shift_dout          : std_logic;
  signal shift               : std_logic;
  signal capture             : std_logic;
  --
  signal control_reg_ce      : std_logic;
  signal bram_ce             : std_logic_vector(C_NUM_PICOBLAZE-1 downto 0);
  signal bus_zero            : std_logic_vector(C_NUM_PICOBLAZE-1 downto 0) := (others => '0');
  signal jtag_en_int         : std_logic_vector(C_NUM_PICOBLAZE-1 downto 0);
  signal jtag_en_expanded    : std_logic_vector(7 downto 0) := (others => '0');
  signal jtag_addr_int       : std_logic_vector(C_BRAM_MAX_ADDR_WIDTH-1 downto 0);
  signal jtag_din_int        : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal control_din         : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0):= (others => '0');
  signal control_dout        : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0):= (others => '0');
  signal control_dout_int    : std_logic_vector(7 downto 0):= (others => '0');
  signal bram_dout_int       : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0) := (others => '0');
  signal jtag_we_int         : std_logic;
  signal jtag_clk_int        : std_logic;
  signal bram_ce_valid       : std_logic;
  signal din_load            : std_logic;
  --
  signal jtag_dout_0_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_1_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_2_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_3_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_4_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_5_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_6_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal jtag_dout_7_masked  : std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto 0);
  signal picoblaze_reset_int : std_logic_vector(C_NUM_PICOBLAZE-1 downto 0) := (others => '0');
  --        
begin
  bus_zero <= (others => '0');
  --
  jtag_loader_gen: if (C_JTAG_LOADER_ENABLE = 1) generate
    --
    -- Insert BSCAN primitive for target device architecture.
    --
    BSCAN_SPARTAN6_gen: if (C_FAMILY="S6") generate
    begin
      BSCAN_BLOCK_inst : BSCAN_SPARTAN6
      generic map ( JTAG_CHAIN => C_JTAG_CHAIN)
      port map( CAPTURE => capture,
                   DRCK => drck,
                  RESET => open,
                RUNTEST => open,
                    SEL => bram_ce_valid,
                  SHIFT => shift,
                    TCK => open,
                    TDI => shift_din,
                    TMS => open,
                 UPDATE => jtag_clk_int,
                    TDO => shift_dout);
    end generate BSCAN_SPARTAN6_gen;   
    --
    BSCAN_VIRTEX6_gen: if (C_FAMILY="V6") generate
    begin
      BSCAN_BLOCK_inst: BSCAN_VIRTEX6
      generic map(    JTAG_CHAIN => C_JTAG_CHAIN,
                    DISABLE_JTAG => FALSE)
      port map( CAPTURE => capture,
                   DRCK => drck,
                  RESET => open,
                RUNTEST => open,
                    SEL => bram_ce_valid,
                  SHIFT => shift,
                    TCK => open,
                    TDI => shift_din,
                    TMS => open,
                 UPDATE => jtag_clk_int,
                    TDO => shift_dout);
    end generate BSCAN_VIRTEX6_gen;   
    --
    BSCAN_7SERIES_gen: if (C_FAMILY="7S") generate
    begin
      BSCAN_BLOCK_inst: BSCANE2
      generic map(    JTAG_CHAIN => C_JTAG_CHAIN,
                    DISABLE_JTAG => "FALSE")
      port map( CAPTURE => capture,
                   DRCK => drck,
                  RESET => open,
                RUNTEST => open,
                    SEL => bram_ce_valid,
                  SHIFT => shift,
                    TCK => open,
                    TDI => shift_din,
                    TMS => open,
                 UPDATE => jtag_clk_int,
                    TDO => shift_dout);
    end generate BSCAN_7SERIES_gen;   
    --
    --
    -- Insert clock buffer to ensure reliable shift operations.
    --
    upload_clock: BUFG
    port map( I => drck,
              O => shift_clk);
    --        
    --        
    --  Shift Register      
    --        
    --
    control_reg_ce_shift: process (shift_clk)
    begin
      if shift_clk'event and shift_clk = '1' then
        if (shift = '1') then
          control_reg_ce <= shift_din;
        end if;
      end if;
    end process control_reg_ce_shift;
    --        
    bram_ce_shift: process (shift_clk)
    begin
      if shift_clk'event and shift_clk='1' then  
        if (shift = '1') then
          if(C_NUM_PICOBLAZE > 1) then
            for i in 0 to C_NUM_PICOBLAZE-2 loop
              bram_ce(i+1) <= bram_ce(i);
            end loop;
          end if;
          bram_ce(0) <= control_reg_ce;
        end if;
      end if;
    end process bram_ce_shift;
    --        
    bram_we_shift: process (shift_clk)
    begin
      if shift_clk'event and shift_clk='1' then  
        if (shift = '1') then
          jtag_we_int <= bram_ce(C_NUM_PICOBLAZE-1);
        end if;
      end if;
    end process bram_we_shift;
    --        
    bram_a_shift: process (shift_clk)
    begin
      if shift_clk'event and shift_clk='1' then  
        if (shift = '1') then
          for i in 0 to C_BRAM_MAX_ADDR_WIDTH-2 loop
            jtag_addr_int(i+1) <= jtag_addr_int(i);
          end loop;
          jtag_addr_int(0) <= jtag_we_int;
        end if;
      end if;
    end process bram_a_shift;
    --        
    bram_d_shift: process (shift_clk)
    begin
      if shift_clk'event and shift_clk='1' then  
        if (din_load = '1') then
          jtag_din_int <= bram_dout_int;
         elsif (shift = '1') then
          for i in 0 to C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-2 loop
            jtag_din_int(i+1) <= jtag_din_int(i);
          end loop;
          jtag_din_int(0) <= jtag_addr_int(C_BRAM_MAX_ADDR_WIDTH-1);
        end if;
      end if;
    end process bram_d_shift;
    --
    shift_dout <= jtag_din_int(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1);
    --
    --
    din_load_select:process (bram_ce, din_load, capture, bus_zero, control_reg_ce) 
    begin
      if ( bram_ce = bus_zero ) then
        din_load <= capture and control_reg_ce;
       else
        din_load <= capture;
      end if;
    end process din_load_select;
    --
    --
    -- Control Registers 
    --
    num_picoblaze <= conv_std_logic_vector(C_NUM_PICOBLAZE-1,3);
    picoblaze_instruction_data_width <= conv_std_logic_vector(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1,5);
    --	
    control_registers: process(jtag_clk_int) 
    begin
      if (jtag_clk_int'event and jtag_clk_int = '1') then
        if (bram_ce_valid = '1') and (jtag_we_int = '0') and (control_reg_ce = '1') then
          case (jtag_addr_int(3 downto 0)) is 
            when "0000" => -- 0 = version - returns (7 downto 4) illustrating number of PB
                           --               and (3 downto 0) picoblaze instruction data width
                           control_dout_int <= num_picoblaze & picoblaze_instruction_data_width;
            when "0001" => -- 1 = PicoBlaze 0 reset / status
                           if (C_NUM_PICOBLAZE >= 1) then 
                            control_dout_int <= picoblaze_reset_int(0) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_0-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "0010" => -- 2 = PicoBlaze 1 reset / status
                           if (C_NUM_PICOBLAZE >= 2) then 
                             control_dout_int <= picoblaze_reset_int(1) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_1-1,5) );
                            else 
                             control_dout_int <= (others => '0');
                           end if;
            when "0011" => -- 3 = PicoBlaze 2 reset / status
                           if (C_NUM_PICOBLAZE >= 3) then 
                            control_dout_int <= picoblaze_reset_int(2) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_2-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "0100" => -- 4 = PicoBlaze 3 reset / status
                           if (C_NUM_PICOBLAZE >= 4) then 
                            control_dout_int <= picoblaze_reset_int(3) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_3-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "0101" => -- 5 = PicoBlaze 4 reset / status
                           if (C_NUM_PICOBLAZE >= 5) then 
                            control_dout_int <= picoblaze_reset_int(4) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_4-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "0110" => -- 6 = PicoBlaze 5 reset / status
                           if (C_NUM_PICOBLAZE >= 6) then 
                            control_dout_int <= picoblaze_reset_int(5) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_5-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "0111" => -- 7 = PicoBlaze 6 reset / status
                           if (C_NUM_PICOBLAZE >= 7) then 
                            control_dout_int <= picoblaze_reset_int(6) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_6-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "1000" => -- 8 = PicoBlaze 7 reset / status
                           if (C_NUM_PICOBLAZE >= 8) then 
                            control_dout_int <= picoblaze_reset_int(7) & "00" & (conv_std_logic_vector(C_ADDR_WIDTH_7-1,5) );
                           else 
                            control_dout_int <= (others => '0');
                           end if;
            when "1111" => control_dout_int <= conv_std_logic_vector(C_BRAM_MAX_ADDR_WIDTH -1,8);
            when others => control_dout_int <= (others => '1');
          end case;
        else 
          control_dout_int <= (others => '0');
        end if;
      end if;
    end process control_registers;
    -- 
    control_dout(C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-1 downto C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-8) <= control_dout_int;
    --
    pb_reset: process(jtag_clk_int) 
    begin
      if (jtag_clk_int'event and jtag_clk_int = '1') then
        if (bram_ce_valid = '1') and (jtag_we_int = '1') and (control_reg_ce = '1') then
          picoblaze_reset_int(C_NUM_PICOBLAZE-1 downto 0) <= control_din(C_NUM_PICOBLAZE-1 downto 0);
        end if;
      end if;
    end process pb_reset;    
    --
    --
    -- Assignments 
    --
    control_dout (C_PICOBLAZE_INSTRUCTION_DATA_WIDTH-9 downto 0) <= (others => '0') when (C_PICOBLAZE_INSTRUCTION_DATA_WIDTH > 8);
    --
    -- Qualify the blockram CS signal with bscan select output
    jtag_en_int <= bram_ce when bram_ce_valid = '1' else (others => '0');
    --      
    jtag_en_expanded(C_NUM_PICOBLAZE-1 downto 0) <= jtag_en_int;
    jtag_en_expanded(7 downto C_NUM_PICOBLAZE) <= (others => '0') when (C_NUM_PICOBLAZE < 8);
    --        
    bram_dout_int <= control_dout or jtag_dout_0_masked or jtag_dout_1_masked or jtag_dout_2_masked or jtag_dout_3_masked or jtag_dout_4_masked or jtag_dout_5_masked or jtag_dout_6_masked or jtag_dout_7_masked;
    --
    control_din <= jtag_din_int;
    --        
    jtag_dout_0_masked <= jtag_dout_0 when jtag_en_expanded(0) = '1' else (others => '0');
    jtag_dout_1_masked <= jtag_dout_1 when jtag_en_expanded(1) = '1' else (others => '0');
    jtag_dout_2_masked <= jtag_dout_2 when jtag_en_expanded(2) = '1' else (others => '0');
    jtag_dout_3_masked <= jtag_dout_3 when jtag_en_expanded(3) = '1' else (others => '0');
    jtag_dout_4_masked <= jtag_dout_4 when jtag_en_expanded(4) = '1' else (others => '0');
    jtag_dout_5_masked <= jtag_dout_5 when jtag_en_expanded(5) = '1' else (others => '0');
    jtag_dout_6_masked <= jtag_dout_6 when jtag_en_expanded(6) = '1' else (others => '0');
    jtag_dout_7_masked <= jtag_dout_7 when jtag_en_expanded(7) = '1' else (others => '0');
    --
    jtag_en <= jtag_en_int;
    jtag_din <= jtag_din_int;
    jtag_addr <= jtag_addr_int;
    jtag_clk <= jtag_clk_int;
    jtag_we <= jtag_we_int;
    picoblaze_reset <= picoblaze_reset_int;
    --        
  end generate jtag_loader_gen;
--
end Behavioral;
--
--
------------------------------------------------------------------------------------
--
-- END OF FILE command_interpreter.vhd
--
------------------------------------------------------------------------------------
