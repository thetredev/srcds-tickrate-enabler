CC=gcc
CXX=g++

PLUGIN_VERSION=$(shell git describe --tags --always)

# Work around hacks in the Source engine
CFLAGS=-m32 -std=gnu++17 -fpermissive -fPIC \
	-Dstrnicmp=strncasecmp -Dstricmp=strcasecmp -D_vsnprintf=vsnprintf \
	-DPOSIX -DLINUX -D_LINUX -DGNU -DGNUC -DPLUGIN_VERSION=\"$(PLUGIN_VERSION)\"

OPTFLAGS=-O3

HL2SDK=./hl2sdk-$(ENGINE)
MMSDK=./metamod-source
source_dir = ./src

# Include Source SDK directories
INCLUDES=-I$(source_dir) -I$(HL2SDK)/public -I$(HL2SDK)/public/tier0 -I$(HL2SDK)/public/tier1 -I$(MMSDK)/core -I$(MMSDK)/core/sourcehook

# Include the folder with the Source SDK libraries
LINKFLAGS=-shared -m32 -L$(HL2SDK)/lib/public/linux

current_dir = $(shell pwd)
output_dir = ./output

all: clean mms plugin.so

mms:
	-./build-mms.sh $(ENGINE)
	-cd $(current_dir)

output:
	-mkdir -p $(output_dir)

globals.o: output $(source_dir)/globals.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/globals.o \
		-c $(source_dir)/globals.cpp

hooks.o: output $(source_dir)/hooks.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/hooks.o \
		-c $(source_dir)/hooks.cpp

plugin.o: output $(source_dir)/plugin.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/plugin.o \
		-c $(source_dir)/plugin.cpp

plugin.so: output globals.o hooks.o plugin.o
	$(CXX) \
		-o $(output_dir)/plugin.so $(LINKFLAGS) \
		$(output_dir)/globals.o \
		$(output_dir)/hooks.o \
		$(output_dir)/plugin.o \
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
