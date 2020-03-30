#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/threads.h>
#include <caml/gc_ctrl.h>
#include <windows.h>
#include <process.h>    /* _beginthread, _endthread */

/*
typedef struct thread_description {
 value * g 
} thread_description;

value start_thread (value closure, value arg) {

}


value create_thread(value closure, value arg) {
  // TODO handle failure
  CAMLparam2 (closure, arg);
  CAMLlocal2 (res, tmp);
  res = caml_callback_exn(closure, arg);
  CAMLreturn (Val_unit);
}
*/
