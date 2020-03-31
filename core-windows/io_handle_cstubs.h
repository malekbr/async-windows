#ifndef __CORE_WINDOWS_HANDLE_CSTUBS__
#define __CORE_WINDOWS_HANDLE_CSTUBS__
#include <caml/mlvalues.h>
#include <caml/custom.h>
#include <windows.h>

// TODO these shouldn't be exposed?
typedef struct io_handle {
  HANDLE hndl;
} io_handle;

value caml_value_io_handle (io_handle* io_handle_obj);

io_handle* io_handle_wrap_and_own (HANDLE hndl);

// Returns null if failed
io_handle* io_handle_duplicate_handle (HANDLE hndl);

#endif

