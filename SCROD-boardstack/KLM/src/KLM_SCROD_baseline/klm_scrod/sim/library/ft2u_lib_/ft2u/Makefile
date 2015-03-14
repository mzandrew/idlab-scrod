#
#  Makefile to replace ISE GUI
#
#  M.Nakao
#

ISE = /home/xilinx/ise12.4/ISE

PATH:=$(ISE)/bin/lin64:$(ISE)/bin/lin:$(PATH)

SRC  = ft2u
NAME = ft2u
PART = xc5vlx30-ff676-1

#-- input and output
VHDL = $(SRC).vhd $(ADD)
UCF  = $(SRC).ucf
BIT  = $(NAME).bit
NGDDIR = -sd coregen
ADD  = m_encode.vhd o_decode.vhd m_collect.vhd m_gentrig.vhd $(ADD1)
ADD1 = b2tt_8b10b.vhd b2tt_symbols.vhd $(ADD2)
ADD2 = tt_blink.vhd tt_dump.vhd tt_ictrl.vhd $(ADD3)
ADD3 = tt_ioswitch.vhd tt_jitterspi.vhd tt_regs.vhd tt_utime.vhd $(ADD4)
ADD4 = tt_types.vhd tt_oack.vhd b2tt_ddr_v5.vhd tt_orsv.vhd tt_otrg.vhd $(ADD5)
ADD5 = m_dumtrig.vhd m_genbusy.vhd tt_aux.vhd x_encode.vhd tt_oclk.vhd $(ADD6)
ADD6 = m_fifo.vhd m_count.vhd x_decode.vhd m_pipeline.vhd tt_tlu.vhd $(ADD7)
ADD7 = tt_phasedet.vhd m_trgdelay.vhd m_jtag.vhd

#-- commands
XSTCMD = xst
NGDCMD = ngdbuild
MAPCMD = map
PARCMD = par
RPTCMD = reportgen
TRCCMD = trce
GENCMD = bitgen

#-- command options
ISEOPT = -intstyle ise
XSTOPT = $(ISEOPT)
NGDOPT = $(ISEOPT) -dd _ngo $(NGDDIR) -nt timestamp -uc $(UCF) -p $(PART)
MAPOPT1 = -w -logic_opt off -ol high -xe n -t 1 -register_duplication off
MAPOPT2 = -global_opt speed -equivalent_register_removal on -mt off
MAPOPT3 = -cm balanced -ir off -pr b -lc auto -power off
MAPOPT = $(ISEOPT) -p $(PART) $(MAPOPT1) $(MAPOPT2) $(MAPOPT3)
PAROPT = $(ISEOPT) -w -ol high -mt off
TRCOPT = $(ISEOPT) -v 3 -s 1 -n 3 -fastpaths
GENOPT = $(ISEOPT)
RPTOPT = $(ISEOPT)


#-- intermediate files
NGC   = $(NAME).ngc
XSTIN = $(NAME).xst
NGD   = $(NAME).ngd
MAP   = $(NAME)_map.ncd
NCD   = $(NAME).ncd
PCF   = $(NAME).pcf
TWR   = $(NAME).twr
NPL   = $(NAME).npl
UTF   = $(NAME).ut

#-- log files
SYR   = $(NAME).syr
BLD   = $(NAME).bld
MRP   = $(NAME).mrp


all: $(BIT)

backup:
	@-sh latest.sh

clean:
	-rm -fr _ngo _xmsgs xlnx_auto_0_xdb iseconfig xst
	-rm -f *.bgn *.bld *.dly *.drc *.lso *.ncd *.ngc *.ngd *.ngr
	-rm -f *.pad *.par *.pcf *.ptwx *.syr *.twx *.unroutes *.xpi
	-rm -f *.map *.mrp *.ngm *.psr *.xrpt *_pad.{csv,txt} *.xml *.log
	-rm -f  *.stx *.xwbt *.html *.cmd_log
	-rm -f *~ *.bak

$(BIT): $(VHDL) $(UCF)
	-mkdir -p xst/projnav.tmp >/dev/null
	$(XSTCMD) $(XSTOPT) -ifn $(XSTIN) -ofn $(SYR)
	$(NGDCMD) $(NGDOPT) $(NGC) $(NGD)
	$(MAPCMD) $(MAPOPT) -o $(MAP) $(NGD) $(PCF)
	$(PARCMD) $(PAROPT) $(MAP) $(NCD) $(PCF)
	$(RPTCMD) $(RPTOPT) -delay $(NCD)
	$(GENCMD) $(GENOPT) -f $(UTF) $(NCD)
	$(TRCCMD) $(TRCOPT) -xml $(NAME) $(NCD) -o $(TWR) $(PCF) -ucf $(UCF)
	grep 'Maximum frequency' $(TWR)
	grep 'failing' $(TWR)

# $(NGC): $(VHDL)
# 	-mkdir -p xst/projnav.tmp >/dev/null
# 	$(XSTCMD) $(XSTOPT) -ifn $(XSTIN) -ofn $(SYR)
# 
# $(NGD): $(NGC) $(UCF)
# 	$(NGDCMD) $(NGDOPT) $(NGC) $(NGD)
# 
# $(PCF): $(NGD)
# 	$(MAPCMD) $(MAPOPT) -o $(MAP) $(NGD) $(PCF)
# 
# $(NCD): $(PCF)
# 	$(PARCMD) $(PAROPT) $(MAP) $(NCD) $(PCF)
# 	$(RPTCMD) $(RPTOPT) -delay $(NCD)
# 
# $(BIT): $(NCD)
# 	$(GENCMD) $(GENOPT) -f $(UTF) $(NCD)
# 
# $(TWR): $(NCD)
# 	$(TRCCMD) $(TRCOPT) -xml $(NAME) $(NCD) -o $(TWR) $(PCF) -ucf $(UCF)
# 	grep 'Maximum frequency' $(TWR)
# 	grep 'failing' $(TWR)
