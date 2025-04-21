// ========= INCLUDES =========
// Plugin
#include "plugin.h"


// ========= PLUGIN INTERFACE EXPORTS =========
namespace srcds::tickrate_enabler::exports {

// Expose plugin interface singleton to SRCDS
Plugin plugin_instance;
EXPOSE_SINGLE_INTERFACE_GLOBALVAR(
    Plugin, IServerPluginCallbacks, INTERFACEVERSION_ISERVERPLUGINCALLBACKS, plugin_instance
);

} // namespace srcds::tickrate_enabler
