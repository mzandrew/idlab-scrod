COMPILE_FLAGS = -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB `root-config --cflags `
LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0 `root-config --glibs` 

# things we always need built:
FINAL_OBJECT_FILES = bin/irs3BControl_initialize bin/irs3BControl_readReg bin/irs3BControl_writeReg bin/irs3BControl_takeData bin/irs3BControl_recordData bin/irs3BControl_writeData bin/irs3BControl_routeCal bin/irs3BControl_test bin/irs3BControl_readTemps bin/irs3BControl_configureSampRateVoltage bin/irs3BControl_measureTriggerThresholds bin/irs3BControl_takeHardwareTriggers bin/irs3BControl_setCalibrations

# needed to link all:
INTERMEDIATE_OBJECT_FILES = work/generic.o work/io_interface.o work/idl_usb.o work/packet_interface.o work/irs3BControlClass.o work/irs3BDataClass.o

default :
	if [ ! -e src     ]; then mkdir     src; fi
	if [ ! -e work    ]; then mkdir    work; fi
	if [ ! -e bin     ]; then mkdir     bin; fi
	$(MAKE) intermediate all

intermediate : $(INTERMEDIATE_OBJECT_FILES)

all : $(FINAL_OBJECT_FILES)

work/%.o : src/%.cpp $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/lib/%.cpp src/lib/%.h ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

bin/irs3BControl_initialize  : work/irs3BControl_initialize.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_readReg  : work/irs3BControl_readReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_writeReg  : work/irs3BControl_writeReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_routeCal  : work/irs3BControl_routeCal.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_takeData  : work/irs3BControl_takeData.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_takeHardwareTriggers  : work/irs3BControl_takeHardwareTriggers.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_recordData  : work/irs3BControl_recordData.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_writeData  : work/irs3BControl_writeData.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_test  : work/irs3BControl_test.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_readTemps  : work/irs3BControl_readTemps.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_configureSampRateVoltage : work/irs3BControl_configureSampRateVoltage.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_measureTriggerThresholds : work/irs3BControl_measureTriggerThresholds.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/irs3BControl_setCalibrations : work/irs3BControl_setCalibrations.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf work/* bin/*
