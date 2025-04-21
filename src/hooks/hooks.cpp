// ========= INCLUDES =========
// HL2SDK
#include <eiface.h>

// Metamod Source
#include <sourcehook_impl.h>

// Plugin
#include "hooks.h"
#include "../globals/globals.h"
#include "get_tick_interval.h"


// ========= HOOK IMPLEMENTATIONS =========
namespace srcds::tickrate_enabler::hooks {

int g_PLID = 0;
SourceHook::Impl::CSourceHookImpl g_SourceHook;
SourceHook::ISourceHook *g_SHPtr = &g_SourceHook;

// Declare hooks
SH_DECL_HOOK0(IServerGameDLL, GetTickInterval, const, 0, float);

void register_all(IServerGameDLL *server_game_dll) {
    SH_ADD_HOOK_STATICFUNC(IServerGameDLL, GetTickInterval, server_game_dll, get_tick_interval, false);
}

void unregister_all(IServerGameDLL *server_game_dll) {
    SH_REMOVE_HOOK_STATICFUNC(IServerGameDLL, GetTickInterval, server_game_dll, get_tick_interval, false);
}

} // namespace srcds::tickrate_enabler::hooks
