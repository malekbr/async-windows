#include "shared.h"

void safe_close_handle (HANDLE* handle) {
  if (*handle) {
   CloseHandle(*handle);
   *handle = NULL;
  }
}
