#ifndef SRCDS_TICKRATE_ENABLER__GLOBALS_H_
#define SRCDS_TICKRATE_ENABLER__GLOBALS_H_


// ========= INCLUDES =========
// HL2SDK
#include <eiface.h>

// Metamod Source
#include <sourcehook_impl.h>


// ========= DECLARE GLOBAL VARIABLES =========
extern IServerGameDLL *gamedll;
extern int g_PLID;
extern SourceHook::Impl::CSourceHookImpl g_SourceHook;
extern SourceHook::ISourceHook *g_SHPtr;

extern float g_cmdline_tick_interval;
extern bool g_tick_rate_hook_enabled;

extern const char *g_log_message_prefix;


#endif // SRCDS_TICKRATE_ENABLER__GLOBALS_H_
