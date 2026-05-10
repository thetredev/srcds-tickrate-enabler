SHELL := /bin/bash
CC = gcc
CXX = g++

PLUGIN_VERSION := $(shell git describe --tags --always --dirty)

# Work around hacks in the Source engine
CFLAGS = -m32 -std=gnu++17 -fpermissive -fPIC \
	-Dstrnicmp=strncasecmp -Dstricmp=strcasecmp -D_vsnprintf=vsnprintf \
	-DPOSIX -DLINUX -D_LINUX -DGNU -DGNUC -DPLUGIN_VERSION=\"$(PLUGIN_VERSION)\"

CFLAGS_PLUGIN := -Wall -Wextra

OPTFLAGS = -O3 -s -fno-ident -fno-asynchronous-unwind-tables

RELEASE_ARCHIVE := srcds_tickrate_enabler-$(PLUGIN_VERSION)-linux_amd64.tar.gz
ROOT_DIR := $(shell git rev-parse --show-toplevel)

HL2SDK = hl2sdk-$(ENGINE)
HL2SDK_DIR := $(ROOT_DIR)/$(HL2SDK)

SOURCE_DIR := $(ROOT_DIR)/src
OUTPUT_DIR := $(ROOT_DIR)/output
OBJ_DIR := $(OUTPUT_DIR)/obj
ADDONS_DIR := $(OUTPUT_DIR)/addons
RELEASE_PATH := $(ADDONS_DIR)/srcds_tickrate_enabler.so

VENV_DIR := $(OUTPUT_DIR)/venv
VENV_BIN_DIR := $(VENV_DIR)/bin
VENV_PYTHON := $(VENV_BIN_DIR)/python3
VENV_PIP := $(VENV_BIN_DIR)/pip
VENV_AMBUILD := $(VENV_BIN_DIR)/ambuild

# Include Source SDK directories
INCLUDES := \
	-I$(HL2SDK_DIR)/public \
	-I$(HL2SDK_DIR)/public/tier0 \
	-I$(HL2SDK_DIR)/public/tier1 \
	-Ilib/DynoHook/include \
	-Ilib/DynoHook/exports

# Include the folder with the Source SDK libraries
LINKFLAGS := \
	-shared \
	-m32 \
	-L$(HL2SDK_DIR)/lib/public/linux \
	-L lib/DynoHook/lib

all: release

.PHONY: compile-commands
compile-commands:
	./gen-compile-commands.sh

.PHONY: init-submodules
init-submodules:
	git submodule update --init --recursive

.PHONY: clean-submodules
clean-submodules:
	git submodule status | cut -d ' ' -f 3 | xargs rm -rf

.PHONY: reinit-submodules
reinit-submodules: clean-submodules init-submodules

.PHONY: clean
clean: clean-submodules
	rm -rf $(OUTPUT_DIR)/*

.PHONY: sdk-patches
sdk-patches: reinit-submodules
	./apply-patches.sh ./patches/linux/$(CC)/$(HL2SDK) $(HL2SDK_DIR)
	./apply-patches.sh ./patches/linux/$(CC)/DynoHook DynoHook

.PHONY: objects-dir-create
objects-dir-create: compile-commands
	mkdir -p $(OBJ_DIR)

$(OBJ_DIR)/globals.o: \
		$(SOURCE_DIR)/globals/globals.h \
		$(SOURCE_DIR)/globals/globals.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/globals.o \
		-c $(SOURCE_DIR)/globals/globals.cpp

$(OBJ_DIR)/binary_utils.o: \
		$(SOURCE_DIR)/utils/binary_utils.h \
		$(SOURCE_DIR)/utils/binary_utils.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/binary_utils.o \
		-c $(SOURCE_DIR)/utils/binary_utils.cpp

$(OBJ_DIR)/io_utils.o: \
		$(SOURCE_DIR)/utils/io_utils.h \
		$(SOURCE_DIR)/utils/io_utils.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/io_utils.o \
		-c $(SOURCE_DIR)/utils/io_utils.cpp

$(OBJ_DIR)/hooks_get_tick_interval.o: sdk-patches \
		$(SOURCE_DIR)/hooks/get_tick_interval.h \
		$(SOURCE_DIR)/hooks/get_tick_interval.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/hooks_get_tick_interval.o \
		-c $(SOURCE_DIR)/hooks/get_tick_interval.cpp

$(OBJ_DIR)/hooks.o: sdk-patches \
		$(SOURCE_DIR)/hooks/hooks.h \
		$(SOURCE_DIR)/hooks/hooks.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/hooks.o \
		-c $(SOURCE_DIR)/hooks/hooks.cpp

$(OBJ_DIR)/plugin.o: sdk-patches \
		$(SOURCE_DIR)/plugin.h \
		$(SOURCE_DIR)/plugin.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/plugin.o \
		-c $(SOURCE_DIR)/plugin.cpp

$(OBJ_DIR)/plugin_exports.o: sdk-patches \
		$(SOURCE_DIR)/plugin_exports.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_PLUGIN) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/plugin_exports.o \
		-c $(SOURCE_DIR)/plugin_exports.cpp

$(OBJ_DIR): objects-dir-create \
	$(OBJ_DIR)/globals.o \
	$(OBJ_DIR)/hooks_get_tick_interval.o \
	$(OBJ_DIR)/hooks.o \
	$(OBJ_DIR)/binary_utils.o \
	$(OBJ_DIR)/io_utils.o \
	$(OBJ_DIR)/plugin.o \
	$(OBJ_DIR)/plugin_exports.o \
	$(OBJ_DIR)/plugin.o

.PHONY: objects
objects: $(OBJ_DIR)

.PHONY: dynohook-lib
dynohook-lib:
	rm -rf lib/DynoHook
	rm -rf DynoHook/build
	cmake -S DynoHook -B DynoHook/build \
	    -DCMAKE_BUILD_TYPE="Release" \
		-DCMAKE_INSTALL_PREFIX:PATH="lib/DynoHook" \
		-DCMAKE_C_FLAGS="-m32" \
		-DCMAKE_CXX_FLAGS="-m32" \
		-DCMAKE_EXE_LINKER_FLAGS="-m32" \
		-DCMAKE_SHARED_LINKER_FLAGS="-m32"
	cmake --build DynoHook/build -j$(shell nproc)
	cmake --install DynoHook/build
	rm -rf lib/DynoHook/exports
	cp -r DynoHook/build/exports lib/DynoHook/exports

# TODO: Add DynoHooks library and link it

$(ADDONS_DIR):
	mkdir -p $(ADDONS_DIR)

$(RELEASE_PATH): $(OBJ_DIR) $(ADDONS_DIR) dynohook-lib
	$(CXX) $(OPTFLAGS) -o $(RELEASE_PATH) $(LINKFLAGS) \
		$(OBJ_DIR)/*.o \
		-ltier0_srv \
		-l:tier1_i486.a \
		-l:mathlib_i486.a \
		-l:libasmjit.a \
		-l:libasmtk.a \
		-l:libZycore.a \
		-l:libZydis.a \
		-ldl

.PHONY: shared-lib
shared-lib: $(RELEASE_PATH)

.PHONY: release
release: $(RELEASE_PATH)
	cp $(ROOT_DIR)/static/srcds_tickrate_enabler.vdf $(ADDONS_DIR)
	cd $(OUTPUT_DIR) && tar czf $(RELEASE_ARCHIVE) addons
