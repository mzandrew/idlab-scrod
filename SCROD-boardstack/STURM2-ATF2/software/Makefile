#############################################################################
#Generic and Site Specific Flags
CC=g++
ROOTCINT=$(ROOTSYS)/bin/rootcint
LIBS=$(shell root-config --libs)
ROOT_INCDIR=$(shell root-config --incdir)
INC=-I${ROOT_INCDIR} -I.
WXLDFLAGS=$(shell wx-config --libs)
LDFLAGS=$(LIBS) -lCore -lCint -lRIO -lNet -lHist -lGraf -lGraf3d -lGpad -lTree -lRint -lPostscript -lMatrix -lPhysics -lz -pthread -lm -ldl -rdynamic -lusb -lGui
WXCXXFLAGS=-Wall $(shell wx-config --cxxflags)
CXXFLAGS=-Wall -O2
#############################################################################
#Now the bits we're actually compiling
LIB_OBJS      =  buildDict.o main.o USBdisplay.o STURM2_EVAL.o STURM2Data.o IDL_USB.o stdUSBl.o  
CLASS_HEADERS = USBdisplay.h STURM2_EVAL.h STURM2Data.h IDL_USB.h
#############################################################################
main: $(LIB_OBJS)
	$(CC) $(LIB_OBJS) -o $@ $(INC) $(LDFLAGS)

main.o: 
	$(CC) $(INC) main.C -c

USBdisplay.o: 
	$(CC) $(INC) USBdisplay.cxx -c

STURM2_EVAL.o: 
	$(CC) $(INC) STURM2_EVAL.cxx -c

STURM2Data.o: 
	$(CC) $(INC) STURM2Data.cxx -c

IDL_USB.o: 
	$(CC) $(INC) IDL_USB.cxx -c

stdUSBl.o: 
	$(CC) $(INC) stdUSBl.cxx -c

buildDict.o: $(CLASS_HEADERS)
	@echo "Generating dictionary ..."
	@ rm -f *Dict* 
	@ rm -f main $(LIB_OBJS)
	rootcint buildDict.cxx -c $(CLASS_HEADERS) LinkDef.h
	$(CC) $(INC) buildDict.cxx -c
#############################################################################
clean:
	@ rm -f main $(LIB_OBJS)
	@rm -f *Dict*
#############################################################################