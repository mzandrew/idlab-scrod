COMPILE_FLAGS = -g -gdwarf-2 -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB -I.
LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0 -lpthread

APPS = bin/KlmRegisterWrite bin/KlmRegisterRead bin/KlmAsicWrite bin/KlmConfigure bin/KlmToFile bin/KlmTestTriggers bin/KlmTestTriggersFineTune bin/KlmDACstep01 bin/KlmTestTriggers3 bin/KlmTestTriggers4 bin/KlmTestHVDACSingleChannelTriggers bin/KlmTestReadMPPCcurrents01 bin/KlmTestReadTemperature01 bin/KlmTestSetHVDACs
OBJECT_FILES = base/KlmSystem.o base/DetectorInterface.o base/UsbInterface.o base/ScrodPacket.o base/KlmModule.o base/tinyxml2.o base/KlmConsumer.o base/KlmFile.o base/CopperInterface.o

all : $(APPS)

base/%.o : base/%.cpp;
	g++ $(COMPILE_FLAGS) -c $< -o $@

tools/%.o : tools/%.cpp;
	g++ $(COMPILE_FLAGS) -c $< -o $@

bin/KlmRegisterWrite : tools/KlmRegisterWrite.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmRegisterRead : tools/KlmRegisterRead.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmAsicWrite : tools/KlmAsicWrite.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmConfigure : tools/KlmConfigure.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

#bin/KlmSoftRecord : tools/KlmSoftRecord.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmToFile : tools/KlmToFile.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmTestTriggers   : tools/KlmTestTriggers.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmTestTriggersFineTune : tools/KlmTestTriggersFineTune.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmDACstep01 : tools/KlmDACstep01.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmTestTriggers3 : tools/KlmTestTriggers3.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmTestTriggers4 : tools/KlmTestTriggers4.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmTestHVDACSingleChannelTriggers : tools/KlmTestHVDACSingleChannelTriggers.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@
bin/KlmTestReadMPPCcurrents01 : tools/KlmTestReadMPPCcurrents01.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@
bin/KlmTestReadTemperature01 : tools/KlmTestReadTemperature01.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@
bin/KlmTestSetHVDACs : tools/KlmTestSetHVDACs.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf base/*.o bin/* tools/*.o
