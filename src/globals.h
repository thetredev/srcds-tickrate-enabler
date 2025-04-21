#ifndef SRCDS_TICKRATE_ENABLER__GLOBALS_H_
#define SRCDS_TICKRATE_ENABLER__GLOBALS_H_


// ========= INCLUDES =========
// HL2SDK
#include <eiface.h>

// Metamod Source
#include <sourcehook_impl.h>


// ========= DECLARE GLOBAL VARIABLES =========
namespace srcds::tickrate_enabler {

extern SourceHook::Impl::CSourceHookImpl g_SourceHook;
extern SourceHook::ISourceHook *g_SHPtr;

extern int g_PLID;
extern float g_cmdline_tick_interval;

} // namespace srcds::tickrate_enabler


#endif // SRCDS_TICKRATE_ENABLER__GLOBALS_H_
