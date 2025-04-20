CC=gcc
CXX=g++

# Work around hacks in the Source engine
CFLAGS=-m32 -std=gnu++17 -fpermissive -fPIC \
	-Dstrnicmp=strncasecmp -Dstricmp=strcasecmp -D_vsnprintf=vsnprintf \
	-DPOSIX -DLINUX -D_LINUX -DGNU -DGNUC

OPTFLAGS=-O3

# ******************************
# Change these to the proper
# locations for your system.
# ******************************
HL2SDK=./hl2sdk-css
MMSDK=./metamod-source

# Include Source SDK directories
INCLUDES=-I$(HL2SDK)/public -I$(HL2SDK)/public/tier0 -I$(HL2SDK)/public/tier1 -I$(MMSDK)/core -I$(MMSDK)/core/sourcehook

# Include the folder with the Source SDK libraries
LINKFLAGS=-shared -m32 -L$(HL2SDK)/lib/public/linux

current_dir = $(shell pwd)

all: clean mms serverplugin_empty.o serverplugin_empty.so

mms:
	-./build-mms.sh css
	-cd $(current_dir)

serverplugin_empty.o: mms
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) -c serverplugin_empty.cpp

serverplugin_empty.so:
	$(CXX) -o serverplugin_empty.so $(LINKFLAGS) serverplugin_empty.o $(MMSDK)/build/core/metamod.2.$(ENGINE)/sourcehook_sourcehook*.o \
	-ltier0_srv -l:tier1_i486.a -static-libstdc++ -l:mathlib_i486.a -ldl

clean:
	-rm -f *.so *.o
	-rm -rf metamod-source/build
