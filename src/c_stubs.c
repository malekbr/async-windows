#include <synchapi.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/threads.h>
#include <caml/gc_ctrl.h>

CAMLprim value win_sleep(value duration) {
  CAMLparam1 (duration);
  DWORD duration_ms = Int_val(duration);
  caml_release_runtime_system();
  Sleep(duration_ms);
  caml_acquire_runtime_system();
  CAMLreturn (Val_unit);
}
