// ========= INCLUDES =========
// C++/std
#include <filesystem>

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
Plugin g_plugin;
EXPOSE_SINGLE_INTERFACE_GLOBALVAR(
    Plugin, IServerPluginCallbacks, INTERFACEVERSION_ISERVERPLUGINCALLBACKS, g_plugin
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
    .client_command_index = client_command_index,
    .server_game_dll = NULL,
    .version_info = NULL
}} {}

// private c'tor
Plugin::Plugin(const PluginData &data) : m {data} {}


// Hook the `get_tick_interval()` into the game server DLL on load
bool Plugin::Load(CreateInterfaceFn interface_factory, CreateInterfaceFn game_server_factory) {
    // get cmdline parameter `-tickrate` value
    float cmdline_tickrate = (float)(CommandLine()->ParmValue("-tickrate", 0));

    // do not hook up anything on invalid values
    if (cmdline_tickrate < 10.0f) {
        // print an error message
        Error("[%s] Requested tick rate %s is lower than the minimum value of 10.\n", m.name);

        // indicate to SRCDS that the plugin couldn't load
        return false;
    }

    // get the current game dir
    const char *game_dir = CommandLine()->ParmValue("-game", "hl2"); // stolen from Metamod Source `InitMainStates`

    // get the current ServerGameDLL interface version
    const char *servergamedll_interface_version = get_servergamedll_interface_version(game_dir);
    m.server_game_dll = (IServerGameDLL*)game_server_factory(servergamedll_interface_version, NULL);

    // abort if we couldn't find a reference to the current ServerGameDLL instance
    if (!m.server_game_dll)
    {
        // print an error message
        Error(
            "[%s] Failed to get a pointer on ServerGameDLL. Expected: %s, Got: NULL\n",
            m.name, servergamedll_interface_version
        );

        // indicate to SRCDS that the plugin couldn't load
        return false;
    }

    // otherwise, calculate the tick interval for the tick rate requested via srcds cmdline
    g_cmdline_tick_interval = 1.0f / cmdline_tickrate;

    // hook up `get_tick_interval()` into the ServerGameDLL instance
    SH_ADD_HOOK_STATICFUNC(IServerGameDLL, GetTickInterval, m.server_game_dll, get_tick_interval, false);

    // set version info string
    m.version_info = (char *)malloc(256);
    sprintf(m.version_info, "%s by %s %s", m.name, m.author, PLUGIN_VERSION);

    // print a message
    Msg("[%s] Loaded successfully!\n", m.name);

    // indicate to SRCDS that the plugin loaded successfully
    return true;
}

// Unhook the `get_tick_interval()` from the game server DLL on unload
void Plugin::Unload(void) {
    free(m.version_info);
    m.version_info = NULL;

    SH_REMOVE_HOOK_STATICFUNC(IServerGameDLL, GetTickInterval, m.server_game_dll, get_tick_interval, false);
}

// This string is returned when `plugin_print` is typed into the SRCDS console
const char *Plugin::GetPluginDescription(void) {
    return m.version_info;
}

// Ask the currently running game server about its
// imprinted ServerGameDLL interface version.
// Falls back to compile time `INTERFACEVERSION_SERVERGAMEDLL` on failure.
const char *Plugin::get_servergamedll_interface_version(const char *game_dir) {
    // construct command string `strings <game_dir>/bin/server_srv.so`
    std::filesystem::path server_srv_so_buffer {game_dir};
    server_srv_so_buffer /= "bin/server_srv.so";
    const char *server_srv_so = server_srv_so_buffer.c_str();

    // try find the line containing the needle...
    // (this is usually the second line)
    const char *needle = "ServerGameDLL";
    const size_t needle_len = strlen(needle);

    Msg("[%s] Parsing file %s for %s ...\n", m.name, server_srv_so, needle);

    char *buffer = NULL;
    size_t out_count = 0;

    bool found = false;

    std::string command {"strings"};
    command += " ";
    command += server_srv_so;

    FILE *bin = popen(command.data(), "r");

    while (getline(&buffer, &out_count, bin) > 0) {
        if (strncmp(buffer, needle, needle_len) == 0) {
            found = true;
            break;
        }
    }

    // close the .so file
    pclose(bin);

    // evaluate the results...
    if (found) {
        // truncate buffer len to the string length we're looking for
        const size_t needle_len_max = needle_len + 3; // version includes 3 chars
        buffer[needle_len_max] = '\0';
    } else {
        // free the memory allocated by getline()
        // as we're not using it anymore
        free(buffer);

        // fall back to the string declared in `eiface.h`
        buffer = (char *)INTERFACEVERSION_SERVERGAMEDLL;
    }

    // return what we've found
    Msg("[%s] Found %s value: %s\n", m.name, needle, buffer);
    return buffer;
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
