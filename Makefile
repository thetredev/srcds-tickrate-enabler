SHELL := /bin/bash
CC = gcc
CXX = g++

PLUGIN_VERSION := $(shell git describe --tags --always)

# Work around hacks in the Source engine
CFLAGS = -m32 -std=gnu++17 -fpermissive -fPIC \
	-Dstrnicmp=strncasecmp -Dstricmp=strcasecmp -D_vsnprintf=vsnprintf \
	-DPOSIX -DLINUX -D_LINUX -DGNU -DGNUC -DPLUGIN_VERSION=\"$(PLUGIN_VERSION)\"

OPTFLAGS = -O3

RELEASE_ARCHIVE := srcds_tickrate_enabler-$(PLUGIN_VERSION)-linux_amd64.tar.gz
ROOT_DIR := $(shell git rev-parse --show-toplevel)

HL2SDK = hl2sdk-$(ENGINE)
HL2SDK_DIR := $(ROOT_DIR)/$(HL2SDK)

MMSDK = metamod-source
MMSDK_DIR := $(ROOT_DIR)/$(MMSDK)

SOURCE_DIR := $(ROOT_DIR)/src
OUTPUT_DIR := $(ROOT_DIR)/output
OBJ_DIR := $(OUTPUT_DIR)/obj
ADDONS_DIR := $(OUTPUT_DIR)/addons
RELEASE_PATH := $(ADDONS_DIR)/srcds_tickrate_enabler.so

MMS_BUILD_DIR := $(OUTPUT_DIR)/$(MMSDK)

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
	-I$(MMSDK_DIR)/core \
	-I$(MMSDK_DIR)/core/sourcehook

# Include the folder with the Source SDK libraries
LINKFLAGS := -shared -m32 -L$(HL2SDK_DIR)/lib/public/linux

all: release

.PHONY: clean-submodules
clean-submodules:
	git submodule status | cut -d ' ' -f 3 | xargs rm -rf
	git submodule update --init --recursive

.PHONY: clean
clean: clean-submodules
	rm -rf $(OUTPUT_DIR)/*

.PHONY: sdk-patches
sdk-patches: clean-submodules
	./apply-patches.sh ./patches/linux/$(CC)/$(HL2SDK) $(HL2SDK_DIR)
	./apply-patches.sh ./patches/linux/$(CC)/metamod-source $(MMSDK_DIR)

.PHONY: objects-dir-create
objects-dir-create:
	mkdir -p $(OBJ_DIR)

$(OBJ_DIR)/globals.o: \
		$(SOURCE_DIR)/globals/globals.h \
		$(SOURCE_DIR)/globals/globals.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/globals.o \
		-c $(SOURCE_DIR)/globals/globals.cpp

$(OBJ_DIR)/hooks_get_tick_interval.o: sdk-patches \
		$(SOURCE_DIR)/hooks/get_tick_interval.h \
		$(SOURCE_DIR)/hooks/get_tick_interval.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/hooks_get_tick_interval.o \
		-c $(SOURCE_DIR)/hooks/get_tick_interval.cpp

$(OBJ_DIR)/hooks.o: sdk-patches \
		$(SOURCE_DIR)/hooks/hooks.h \
		$(SOURCE_DIR)/hooks/hooks.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/hooks.o \
		-c $(SOURCE_DIR)/hooks/hooks.cpp

$(OBJ_DIR)/binary_utils.o: sdk-patches \
		$(SOURCE_DIR)/utils/binary_utils.h \
		$(SOURCE_DIR)/utils/binary_utils.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/binary_utils.o \
		-c $(SOURCE_DIR)/utils/binary_utils.cpp

$(OBJ_DIR)/io_utils.o: \
		$(SOURCE_DIR)/utils/io_utils.h \
		$(SOURCE_DIR)/utils/io_utils.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/io_utils.o \
		-c $(SOURCE_DIR)/utils/io_utils.cpp

$(OBJ_DIR)/plugin.o: sdk-patches \
		$(SOURCE_DIR)/plugin.h \
		$(SOURCE_DIR)/plugin.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
		-o $(OBJ_DIR)/plugin.o \
		-c $(SOURCE_DIR)/plugin.cpp

$(OBJ_DIR)/plugin_exports.o: sdk-patches \
		$(SOURCE_DIR)/plugin_exports.cpp
	$(CXX) $(CFLAGS) $(OPTFLAGS) $(INCLUDES) \
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

.PHONY: mms-configure
mms-configure: sdk-patches
	python3 -m venv $(VENV_DIR)
	$(VENV_PIP) install wheel
	test -d $(OUTPUT_DIR)/ambuild-git || git clone https://github.com/alliedmodders/ambuild $(OUTPUT_DIR)/ambuild-git
	$(VENV_PIP) install $(OUTPUT_DIR)/ambuild-git

	mkdir -p $(MMS_BUILD_DIR)
	cd $(MMS_BUILD_DIR) && $(VENV_PYTHON) $(MMSDK_DIR)/configure.py --sdks $(ENGINE)

.PHONY: mms-build
mms-build: mms-configure
	cd $(MMS_BUILD_DIR) && $(VENV_AMBUILD)
	mkdir -p $(OBJ_DIR)
	mv $(MMS_BUILD_DIR)/core/metamod.2.$(ENGINE)/sourcehook_sourcehook*.o $(OBJ_DIR)

$(OBJ_DIR)/sourcehook*.o: $(OBJ_DIR) mms-build

$(ADDONS_DIR):
	mkdir -p $(ADDONS_DIR)

$(RELEASE_PATH): $(OBJ_DIR) $(ADDONS_DIR) $(OBJ_DIR)/sourcehook*.o
	$(CXX) -o $(RELEASE_PATH) $(LINKFLAGS) \
		$(OBJ_DIR)/*.o \
		-ltier0_srv \
		-l:tier1_i486.a \
		-l:mathlib_i486.a \
		-ldl

.PHONY: release
release: $(RELEASE_PATH)
	cp $(ROOT_DIR)/static/srcds_tickrate_enabler.vdf $(ADDONS_DIR)
	cd $(OUTPUT_DIR) && tar czf $(RELEASE_ARCHIVE) addons
