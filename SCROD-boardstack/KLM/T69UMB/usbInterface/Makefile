COMPILE_FLAGS = -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB `root-config --cflags `
LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0 `root-config --glibs` 

# things we always need built:
FINAL_OBJECT_FILES = bin/target6Control_readReg bin/target6Control_writeReg bin/target6Control_writeDacReg bin/target6Control_writeDefaultDacRegs bin/target6Control_test bin/target6Control_testTrigger bin/target6Control_takeData bin/target6Control_takeAndPlotData bin/parseTarget6Data bin/target6Data_viewWaveformTree bin/target6Data_measurePedestals bin/target6Data_makeHitTree

# needed to link all:
INTERMEDIATE_OBJECT_FILES = work/generic.o work/io_interface.o work/idl_usb.o work/packet_interface.o work/target6ControlClass.o work/target6ControlClass.o work/target6DataClass.o

default :
	if [ ! -e src     ]; then mkdir     src; fi
	if [ ! -e work    ]; then mkdir    work; fi
	if [ ! -e bin     ]; then mkdir     bin; fi
	$(MAKE) intermediate all

intermediate : $(INTERMEDIATE_OBJECT_FILES)

all : $(FINAL_OBJECT_FILES)

work/%.o : src/%.cpp $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/%.cxx $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/lib/%.cpp src/lib/%.h ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

bin/target6Control_readReg  : work/target6Control_readReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_writeReg  : work/target6Control_writeReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_writeDacReg  : work/target6Control_writeDacReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_writeDefaultDacRegs  : work/target6Control_writeDefaultDacRegs.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_test  : work/target6Control_test.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_testTrigger  : work/target6Control_testTrigger.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_takeData  : work/target6Control_takeData.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_takeAndPlotData  : work/target6Control_takeAndPlotData.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/parseTarget6Data	:	work/parseTarget6Data.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Data_viewWaveformTree	:	work/target6Data_viewWaveformTree.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Data_measurePedestals	:	work/target6Data_measurePedestals.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Data_makeHitTree	:	work/target6Data_makeHitTree.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf work/* bin/*



