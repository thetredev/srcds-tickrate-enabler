#ifndef SRCDS_TICKRATE_ENABLER__UTILS__IO_H_
#define SRCDS_TICKRATE_ENABLER__UTILS__IO_H_


// ========= I/O UTILS DECLARATIONS =========
namespace srcds::tickrate_enabler::utils::io {

char *find_stdout_line(FILE *f, const char *needle, const size_t needle_len);
char *read_command_stdout(const char *command, const char *needle, const size_t needle_len);

} // namespace srcds::tickrate_enabler::utils::io


#endif // SRCDS_TICKRATE_ENABLER__UTILS__IO_H_
