// ========= INCLUDES =========
#include <cstddef>
#include <cstdio>
#include <cstring>

#include "io_utils.h"


// ========= I/O UTILS IMPLEMENTATION =========
namespace srcds::tickrate_enabler::utils::io {

char *find_stdout_line(FILE *f, const char *needle, const size_t needle_len) {
    // read the file stream line by line
    size_t line_count = 0;
    char *line = NULL;

    while (getline(&line, &line_count, f) > 0) {
        // return the current line if it starts with the `needle` string
        if (strncmp(line, needle, needle_len) == 0) {
            return line;
        }
    }

    // cleanup any leftover allocated memory
    if (line != NULL) {
        delete line;
    }

    // indicate that nothing was found
    return NULL;
}

char *read_command_stdout(const char *command, const char *needle, const size_t needle_len) {
    // open the file for reading
    FILE *bin = popen(command, "r");

    // parse the file (haystack) for the needle
    char *line = find_stdout_line(bin, needle, needle_len);

    // close the file stream
    pclose(bin);

    // return the line
    return line;
}

} // namespace srcds::tickrate_enabler::utils::io
