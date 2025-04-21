// ========= INCLUDES =========
// Plugin
#include "globals.h"


// ========= DEFINE GLOBAL VARIABLES =========
namespace srcds::tickrate_enabler {

SourceHook::Impl::CSourceHookImpl g_SourceHook;
SourceHook::ISourceHook *g_SHPtr = &g_SourceHook;

int g_PLID = 0;
float g_cmdline_tick_interval = 0.0f;

} // namespace srcds::tickrate_enabler
