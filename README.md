# SRCDS Tickrate Enabler

A tickrate enabler plugin for Source Dedicated Server (SRCDS) environments for which the `-tickrate` command line parameter is ignored on startup.

Table of Contents
=================

* [Supported OS, Engines and Game Servers](#supported-os-engines-and-game-servers)
* [Acknowledgements](#acknowledgements)
* [Why yet another fork?](#why-yet-another-fork)
   * [Server Version Compatibility](#server-version-compatibility)
   * [Build Environment &amp; Infrastructure](#build-environment--infrastructure)
* [Installation](#installation)
   * [Prerequisites](#prerequisites)
   * [Plugin Installation](#plugin-installation)
* [Building From Source](#building-from-source)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

# Supported OS, Engines and Game Servers

The following engines and game servers are currently supported:
| OS | Engine | Game Server |
| --- | --- | --- |
| Linux | Source 1 | Counter-Strike: Source |

Note: anything else is untested.

# Acknowledgements

This project is a fork of https://github.com/daemon32/tickrate_enabler which is a fork of Didrole's original implementation which can be found at https://web.archive.org/web/20130507001713/http://didrole.com/tickrate_enabler/SourceCode/0.4/serverplugin_empty.cpp as of 2025-04-21.


# Why yet another fork?

## Server Version Compatibility

The two legacy projects had a specific symbol imprinted into the code. That symbol (`ServerGameDLLXYZ` where `XYZ` is 0-prefixed a number) is used to load the server's interface and hookup a function to manipulate the server's tick inverval value which is calculated from the `-tickrate` SRCDS command line argument.

This version tries to read that symbol from the server file located at `<game dir>/bin/server_srv.so` (where `game_dir` is `cstrike` for example). It is usually located at the second line of that file when read with the `strings` command (part of the GNU `binutils` package). If the symbol can't be found in that file (which is highly unlikely), then the value representing the latest version at compile time will be used.

On failure, the plugin will error out with a more verbose message unlike the legacy projects.

## Build Environment \& Infrastructure

Didrole's implementation didn't have a builtin build infrastructure, only the source code itself. daemon32's implementation has a Makefile, but using it as-is in 2025 results in many build failures, some of which require patching parts of the source code of `HL2SDK` and/or `Metamod: Source`, and others just generally don't work on a modern system probably due to differences in compiler versions (GCC 4 vs. GCC 12 for example). It also has its own SourceHook implementation and objects baked into the source tree, which is unfortunate due to how licensing is handled.

To get around these issues, I set out to achieve the following goals:
- Fork daemon32's implementation on GitHub
- Replace the baked in SourceHook stuff with Git submodules to both `HL2SDK` (`css` branch for now) and `metamod-source` (latest release tag) so there's a clear distinction between this project and those, making it much easier to handle licensing and patching/building
- Try to build the project and create patches along the way until daemon32's original source code works with the new build environment
- Fixup the Makefile to automate building from scratch

This is where I've ended up until this point:
- Patches to both `HL2SDK` and `Metamod: Source` are located under the [`patches`](patches) directory
- `make ENGINE=css` automatically cleans the submodules, patches them, builds `Metamod: Source`, and builds the SRCDS Tickrate Enabler server plugin for `Counter-Strike: Source`
- The source code is optimized and follows a modular approach, located under the [`src`](src) directory
- The plugin version is baked in automatically using `git describe` at compile time and therefore derived from the git ref or tag


# Installation

## Prerequisites

The `strings` command has to be available for the plugin to work. On Debian 12, this is done by installing GNU `binutils` like so:
```
apt-get install binutils
```

(only tested with Debian 12)

## Plugin Installation

1. Download the latest release archive from https://github.com/thetredev/srcds-tickrate-enabler/releases to your server's `addons` directory, for example `cstrike/addons`
2. Extract the archive: `tar xf <archive name>.tar.gz`
3. Restart SRCDS

# Building From Source

Perform the following steps to build the plugin from source:
1. Install package dependencies (example for Debian 12):
```
apt-get install git build-essential gcc-multilib g++-multilib lib32stdc++6 python3-venv python3-pip python3-wheel
```
2. Clone the project and change into the git root directory:
```
git clone https://github.com/thetredev/srcds-tickrate-enabler.git
cd srcds-tickrate-enabler
```
3. Run `make ENGINE=<engine>` with any of the following supported values:

| Game Server | `engine` |
| --- | --- |
| Counter-Strike: Source | `css` |

This will *always* perform a clean build for now.
