#ifndef SRCDS_TICKRATE_ENABLER__HOOKS_H_
#define SRCDS_TICKRATE_ENABLER__HOOKS_H_


// ========= INCLUDES =========
// Metamod Source
//#include <sourcehook.h>


// extern int g_PLID;
// extern SourceHook::ISourceHook *g_SHPtr;


// ========= HOOK DECLARATIONS =========
namespace srcds::tickrate_enabler::hooks {

void register_all(IServerGameDLL *server_game_dll);
void unregister_all(IServerGameDLL *server_game_dll);

} // namespace srcds::tickrate_enabler::hooks


#endif // SRCDS_TICKRATE_ENABLER__HOOKS_H_
