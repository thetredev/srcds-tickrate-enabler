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
source_dir = ./src
output_dir = ./output

all: clean mms build_object build_so

mms:
	-./build-mms.sh css
	-cd $(current_dir)

build_object: $(source_dir)/serverplugin_empty.cpp
	$(CXX) \
		$(CFLAGS) \
		-o $(output_dir)/serverplugin_empty.o $(OPTFLAGS) $(INCLUDES) \
		-c $(source_dir)/serverplugin_empty.cpp

build_so: build_object
	$(CXX) \
		-o $(output_dir)/serverplugin_empty.so $(LINKFLAGS) \
		$(output_dir)/serverplugin_empty.o \
		$(MMSDK)/build/core/metamod.2.$(ENGINE)/sourcehook_sourcehook*.o \
		-ltier0_srv \
		-l:tier1_i486.a \
		-l:mathlib_i486.a \
		-static-libstdc++ \
		-ldl
	-rm -rf hl2sdk-* metamod-source
	-git submodule update --init --recursive

clean:
	-rm -f output/*
	-rm -rf metamod-source/build
