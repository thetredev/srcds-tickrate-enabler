#ifndef SRCDS_TICKRATE_ENABLER__UTILS__BINARY_H_
#define SRCDS_TICKRATE_ENABLER__UTILS__BINARY_H_


// ========= I/O UTILS DECLARATIONS =========
namespace srcds::tickrate_enabler::utils::binary {

// Ask the currently running game server about its
// imprinted ServerGameDLL interface version.
// Falls back to compile time `INTERFACEVERSION_SERVERGAMEDLL` on failure.
const char *get_servergamedll_interface_version(const char *game_dir, const char *log_prefix);

} // srcds::tickrate_enabler::utils::binary

#endif // SRCDS_TICKRATE_ENABLER__UTILS__BINARY_H_
