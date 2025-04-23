// ========= INCLUDES =========
// HL2SDK
#include <eiface.h>
#include <tier0/icommandline.h>

// Plugin
#include "globals/globals.h"
#include "hooks/hooks.h"
#include "hooks/get_tick_interval.h"
#include "utils/binary_utils.h"
#include "utils/io_utils.h"
#include "plugin.h"


// memdbgon must be the last include file in a .cpp file!!!
// ... for some reason
#include <tier0/memdbgon.h>


// ========= PLUGIN INTERFACE DEFINITIONS =========
namespace srcds::tickrate_enabler {

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
    float cmdline_tickrate = static_cast<float>((CommandLine()->ParmValue("-tickrate", 0)));
    const float minimum_tickrate = 10.0f;

    // do not hook up anything on invalid values
    if (cmdline_tickrate < minimum_tickrate) {
        // print an error message
        Error("[%s] Requested tick rate %.1f is lower than the minimum value of %.1f.\n", m.name, cmdline_tickrate, minimum_tickrate);

        // indicate to SRCDS that the plugin couldn't load
        return false;
    }

    // get the current game dir
    const char *game_dir = CommandLine()->ParmValue("-game", "hl2"); // stolen from Metamod Source `InitMainStates`

    // get the current ServerGameDLL interface version
    const char *servergamedll_interface_version = utils::binary::get_servergamedll_interface_version(game_dir, m.name);
    m.server_game_dll = static_cast<IServerGameDLL*>(game_server_factory(servergamedll_interface_version, NULL));

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
    globals::cmdline_tick_interval = 1.0f / cmdline_tickrate;

    // hook up `get_tick_interval()` into the ServerGameDLL instance
    hooks::register_all(m.server_game_dll);

    // set version info string
    m.version_info = new char[256];
    sprintf(m.version_info, "%s by %s %s", m.name, m.author, PLUGIN_VERSION);

    // print a message
    Msg("[%s] Loaded successfully!\n", m.name);

    // indicate to SRCDS that the plugin loaded successfully
    return true;
}

// Unhook the `get_tick_interval()` from the game server DLL on unload
void Plugin::Unload(void) {
    delete [] m.version_info;
    m.version_info = NULL;

    hooks::unregister_all(m.server_game_dll);
}

// This string is returned when `plugin_print` is typed into the SRCDS console
const char *Plugin::GetPluginDescription(void) {
    return m.version_info;
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

} // namespace srcds::tickrate_enabler
