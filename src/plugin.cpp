// ========= INCLUDES =========
// HL2SDK
#include <eiface.h>
#include <tier0/icommandline.h>

// Metamod Source
#include <sourcehook/sourcehook_impl.h>

// Plugin
#include "globals.h"
#include "plugin.h"
#include "hooks.h"


// memdbgon must be the last include file in a .cpp file!!!
// ... for some reason
#include <tier0/memdbgon.h>


// ========= PLUGIN INTERFACE DEFINITIONS =========
// Expose plugin interface singleton
Plugin g_Plugin;
EXPOSE_SINGLE_INTERFACE_GLOBALVAR(
    Plugin, IServerPluginCallbacks, INTERFACEVERSION_ISERVERPLUGINCALLBACKS, g_Plugin
);

// Declare plugin hooks
SH_DECL_HOOK0(IServerGameDLL, GetTickInterval, const, 0, float);


// ========= PLUGIN INTERFACE IMPLEMENTATION =========
// public c'tor
Plugin::Plugin() : Plugin{0} {}

// public d'tor
Plugin::~Plugin() {}

// private c'tor
Plugin::Plugin(int client_command_index) : Plugin{PluginData {
    .client_command_index = client_command_index
}} {}

// private c'tor
Plugin::Plugin(const PluginData &data) : m {data} {}


// Ask the currently running game server about its
// imprinted ServerGameDLL interface version.
// Falls back to compile time `INTERFACEVERSION_SERVERGAMEDLL` on failure.
const char *get_servergamedll_interface_version() {
    // TODO: do not hardcode game dir `cstrike` here
    FILE *bin = popen("strings cstrike/bin/server_srv.so", "r");

    const char *needle = "ServerGameDLL";
    const size_t needle_len = strlen(needle);

    char *buffer = NULL;
    size_t out_count = 0;

    bool found = false;

    while (getline(&buffer, &out_count, bin) > 0) {
        if (strncmp(buffer, needle, needle_len) == 0) {
            found = true;
            break;
        }
    }

    pclose(bin);

    if (found) {
        const size_t needle_len_max = needle_len + 3; // version includes 3 chars

        // truncate buffer len to the string length we're looking for
        buffer[needle_len_max] = '\0';
    } else {
        free(buffer);
        buffer = (char *)INTERFACEVERSION_SERVERGAMEDLL;
    }

    return buffer;
}


// Hook the `get_tick_interval()` into the game server DLL on load
bool Plugin::Load(CreateInterfaceFn interface_factory, CreateInterfaceFn game_server_factory) {
    const char *servergamedll_interface_version = get_servergamedll_interface_version();
    gamedll = (IServerGameDLL*)game_server_factory(servergamedll_interface_version, NULL);

    if (!gamedll)
    {
        Warning("Failed to get a pointer on ServerGameDLL.\n");
        return false;
    }

    float cmdline_tickrate = (float)(CommandLine()->ParmValue("-tickrate", 0));

    if (cmdline_tickrate > 10.0f) {
        g_cmdline_tick_interval = 1.0f / cmdline_tickrate;
    } else {
        g_cmdline_tick_interval = DEFAULT_TICK_INTERVAL;
    }

    SH_ADD_HOOK_STATICFUNC(IServerGameDLL, GetTickInterval, gamedll, get_tick_interval, false);
    return true;
}

// Unhook the `get_tick_interval()` from the game server DLL on unload
void Plugin::Unload(void) {
    SH_REMOVE_HOOK_STATICFUNC(IServerGameDLL, GetTickInterval, gamedll, get_tick_interval, false);
}

// This string is returned when `plugin_print` is typed into the SRCDS console
const char *Plugin::GetPluginDescription(void) {
    return "TickrateEnabler2025 by thetredev";
}

// ========= PLUGIN INTERFACE STUB =========
// These are required, but the stub implementations are fine
// for this plugin's use case. Defined here to make the plugin compile.
int Plugin::GetCommandIndex() {
    return m.client_command_index;
}

void Plugin::SetCommandClient(int index) {
    m.client_command_index = index;
}

PLUGIN_RESULT Plugin::ClientConnect(bool *, edict_t *, const char *, const char *, char *, int) {
    return PLUGIN_CONTINUE;
}

PLUGIN_RESULT Plugin::ClientCommand(edict_t *, const CCommand &) {
    return PLUGIN_CONTINUE;
}

PLUGIN_RESULT Plugin::NetworkIDValidated(const char *, const char *) {
    return PLUGIN_CONTINUE;
}

// These are optional. Defined here to make the plugin compile.
void Plugin::Pause(void) {}
void Plugin::UnPause(void) {}
void Plugin::LevelInit(const char *) {}
void Plugin::ServerActivate(edict_t *, int, int) {}
void Plugin::LevelShutdown(void) {}
void Plugin::ClientActive(edict_t *) {}
void Plugin::ClientDisconnect(edict_t *) {}
void Plugin::ClientPutInServer(edict_t *, const char *) {}
void Plugin::ClientSettingsChanged(edict_t *) {}
void Plugin::OnQueryCvarValueFinished(QueryCvarCookie_t, edict_t *, EQueryCvarValueStatus, const char *, const char *) {}
void Plugin::OnEdictAllocated(edict_t *) {}
void Plugin::OnEdictFreed(const edict_t *) {}
void Plugin::FireGameEvent(KeyValues *) {}
void Plugin::GameFrame(bool) {}
