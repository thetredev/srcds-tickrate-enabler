// ========= INCLUDES =========
// Plugin
#include "globals.h"


// ========= DEFINE GLOBAL VARIABLES =========
IServerGameDLL *gamedll = NULL;
int g_PLID = 0;
SourceHook::Impl::CSourceHookImpl g_SourceHook;
SourceHook::ISourceHook *g_SHPtr = &g_SourceHook;

float g_cmdline_tick_interval = 0.0f;
bool g_tick_rate_hook_enabled = false;
