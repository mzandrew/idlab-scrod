COMPILE_FLAGS = -g -gdwarf-2 -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB -I.
LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0

APPS = bin/KlmRegisterWrite bin/KlmRegisterRead bin/KlmAsicWrite bin/KlmConfigure
OBJECT_FILES = base/KlmSystem.o base/DetectorInterface.o base/UsbInterface.o base/ScrodPacket.o base/KlmModule.o base/tinyxml2.o

all : $(APPS)

base/%.o : base/%.cpp;
	g++ $(COMPILE_FLAGS) -c $< -o $@

tools/%.o : tools/%.cpp;
	g++ $(COMPILE_FLAGS) -c $< -o $@

bin/KlmRegisterWrite : tools/KlmRegisterWrite.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmRegisterRead : tools/KlmRegisterRead.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmAsicWrite : tools/KlmAsicWrite.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/KlmConfigure : tools/KlmConfigure.o $(OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf base/*.o bin/* tools/*.o
