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

all: package

mms:
	-./build-mms.sh $(ENGINE) $(CLEAN)
	-cd $(current_dir)

globals.o: mms $(source_dir)/globals
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/globals.o \
		-c $(source_dir)/globals/globals.cpp

hook_get_tick_interval.o: mms $(source_dir)/hooks/get_tick_interval.cpp
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/hook_get_tick_interval.o \
		-c $(source_dir)/hooks/get_tick_interval.cpp

hooks.o: mms $(source_dir)/hooks/hooks.cpp
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/hooks.o \
		-c $(source_dir)/hooks/hooks.cpp

binary_utils.o: mms $(source_dir)/utils/binary_utils.cpp
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/binary_utils.o \
		-c $(source_dir)/utils/binary_utils.cpp

io_utils.o: mms $(source_dir)/utils/io_utils.cpp
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/io_utils.o \
		-c $(source_dir)/utils/io_utils.cpp

plugin.o: mms $(source_dir)/plugin.cpp
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/plugin.o \
		-c $(source_dir)/plugin.cpp

plugin_exports.o: mms $(source_dir)/plugin_exports.cpp
	-mkdir -p $(output_dir)/obj
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(output_dir)/obj/plugin_exports.o \
		-c $(source_dir)/plugin_exports.cpp

srcds_tickrate_enabler.so: globals.o hook_get_tick_interval.o hooks.o binary_utils.o io_utils.o plugin.o plugin_exports.o
	$(CXX) \
		-o $(output_dir)/srcds_tickrate_enabler.so $(LINKFLAGS) \
		$(output_dir)/obj/globals.o \
		$(output_dir)/obj/hook_get_tick_interval.o \
		$(output_dir)/obj/hooks.o \
		$(output_dir)/obj/binary_utils.o \
		$(output_dir)/obj/io_utils.o \
		$(output_dir)/obj/plugin.o \
		$(output_dir)/obj/plugin_exports.o \
		$(MMSDK)/build/core/metamod.2.$(ENGINE)/sourcehook_sourcehook*.o \
		-ltier0_srv \
		-l:tier1_i486.a \
		-l:mathlib_i486.a \
		-ldl
	-rm -rf hl2sdk-* metamod-source
	-git submodule update --init --recursive

addons: srcds_tickrate_enabler.so
	-mkdir -p $(output_dir)/addons
	-cp $(current_dir)/static/srcds_tickrate_enabler.vdf $(output_dir)/addons/
	-mv $(output_dir)/srcds_tickrate_enabler.so $(output_dir)/addons/

package: addons
	$(shell cd $(output_dir) && tar czf srcds_tickrate_enabler-$(PLUGIN_VERSION)-linux_amd64.tar.gz addons)
