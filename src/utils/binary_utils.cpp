#ifndef SRCDS_TICKRATE_ENABLER__UTILS__BINARY_H_
#define SRCDS_TICKRATE_ENABLER__UTILS__BINARY_H_

#include <cstdio>
#include <cstring>

#include "binary_utils.h"
#include "io_utils.h"


// ========= I/O UTILS DECLARATIONS =========
namespace srcds::tickrate_enabler::utils::binary {

// Ask the currently running game server about its
// imprinted ServerGameDLL interface version.
// Falls back to compile time `INTERFACEVERSION_SERVERGAMEDLL` on failure.
const char *get_servergamedll_interface_version(
    const char *game_dir,
    log_function logger, const char *log_prefix,
    const char *fallback
) {
    // construct command string `strings <game_dir>/bin/server_srv.so`
    char *so_path = new char[256];
    sprintf(so_path, "%s/bin/server_srv.so", game_dir);

    // try find the line containing the needle...
    // (this is usually the second line)
    const char *needle = "ServerGameDLL";
    const size_t needle_len = strlen(needle);

    logger("[%s] Parsing file %s for %s ...\n", log_prefix, so_path, needle);

    char *command = new char[256];
    sprintf(command, "strings %s", so_path);
    delete [] so_path;

    char *needle_line = utils::io::read_command_stdout(command, needle, needle_len);
    delete [] command;

    // evaluate the results...
    if (needle_line != NULL) {
        // truncate buffer len to the string length we're looking for
        const size_t needle_len_max = needle_len + 3; // version includes 3 chars
        needle_line[needle_len_max] = '\0';
    } else {
        // fall back to the string declared in `eiface.h`
        needle_line = const_cast<char *>(fallback);
    }

    // return what we've found
    logger("[%s] Found %s value: %s\n", log_prefix, needle, needle_line);
    return needle_line;
}

} // srcds::tickrate_enabler::utils::binary

#endif // SRCDS_TICKRATE_ENABLER__UTILS__BINARY_H_
