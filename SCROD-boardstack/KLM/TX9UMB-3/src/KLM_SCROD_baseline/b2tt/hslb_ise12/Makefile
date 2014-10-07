#
#  Makefile to replace the Project Navigator
#
#  M.Nakao
#

PATH:=/home/xilinx/ise12.4/ISE/bin/lin64:/home/xilinx/ise12.4/ISE/bin/lin:$(PATH)

SRC    = hslb_b2tt
NAME   = hslb_b2tt
PART   = xc5vlx50t-ff1136-1

#-- input and output
VHDL  = ../main/$(SRC).vhd $(ADD)
UCF   = ../main/$(SRC).ucf
BIT   = $(NAME).bit
ADD   = \
	../main/myregs.vhd \
	../main/mytypes.vhd \
	../b2tt/b2tt_symbols.vhd \
	../b2tt/b2tt_ddr_v5.vhd \
	../b2tt/b2tt_8b10b.vhd \
	../b2tt/b2tt_fifo.vhd \
	../b2tt/b2tt_encode.vhd \
	../b2tt/b2tt_decode.vhd \
	../b2tt/b2tt_clk_v5.vhd \
	../b2tt/b2tt.vhd

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
NGDOPT = $(ISEOPT) -dd _ngo -nt timestamp -uc $(UCF) -p $(PART)
MAPOPT1 = -w -logic_opt off -ol high -t 1 -register_duplication off -global_opt off
MAPOPT2 = -mt off -cm area -ir off -pr off -lc off -power off
MAPOPT = $(ISEOPT) -p $(PART) $(MAPOPT1) $(MAPOPT2)
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


all: $(BIT) $(TWR)

clean:
	-rm -fr _ngo _xmsgs xlnx_auto_0_xdb iseconfig xst
	-rm -f *.bgn *.bit *.bld *.dly *.drc *.lso *.ncd *.ngc *.ngd *.ngr
	-rm -f *.pad *.par *.pcf *.ptwx *.syr *.twx *.twr *.unroutes *.xpi
	-rm -f *.map *.mrp *.ngm *.psr *.xrpt *_pad.{csv,txt} *.xml *.log
	-rm -f  *.stx *.xwbt *.html
	-rm -f *~ *.bak

$(NGC): $(VHDL)
	-mkdir -p xst/projnav.tmp >/dev/null
	$(XSTCMD) $(XSTOPT) -ifn $(XSTIN) -ofn $(SYR)

$(NGD): $(NGC) $(UCF)
	$(NGDCMD) $(NGDOPT) $(NGC) $(NGD)

$(PCF): $(NGD)
	$(MAPCMD) $(MAPOPT) -o $(MAP) $(NGD) $(PCF)

$(NCD): $(PCF)
	$(PARCMD) $(PAROPT) $(MAP) $(NCD) $(PCF)
	$(RPTCMD) $(RPTOPT) -delay $(NCD)

$(BIT): $(NCD)
	$(GENCMD) $(GENOPT) -f $(UTF) $(NCD)

$(TWR): $(NCD)
	$(TRCCMD) $(TRCOPT) -xml $(NAME) $(NCD) -o $(TWR) $(PCF) -ucf $(UCF)
	grep 'Maximum frequency' $(TWR)
	grep 'failing' $(TWR)
