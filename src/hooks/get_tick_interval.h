#ifndef SRCDS_TICKRATE_ENABLER__GET_TICK_INTERVAL_H_
#define SRCDS_TICKRATE_ENABLER__GET_TICK_INTERVAL_H_


// ========= HOOK DECLARATIONS =========
namespace srcds::tickrate_enabler::hooks {

// Intercept tick interval routine via SourceHook
float get_tick_interval();

} // namespace srcds::tickrate_enabler::hooks


#endif // SRCDS_TICKRATE_ENABLER__GET_TICK_INTERVAL_H_
