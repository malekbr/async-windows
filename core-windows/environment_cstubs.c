#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <windows.h>
#include <string.h>
#include <stdio.h>

CAMLprim value caml_set_env(value name, value val) {
  CAMLparam2 (name, val);
  CAMLlocal1 (result);
  const char* c_name = String_val(name);
  const char* c_val = String_val(val);
  int c_result = SetEnvironmentVariable(c_name, c_val);
  result = Val_int(c_result);
  CAMLreturn(result);
}

CAMLprim value caml_unset_env(value name) {
  CAMLparam1(name);
  CAMLlocal1(result);
  const char* c_name = String_val(name);
  int c_result = SetEnvironmentVariable(c_name, NULL);
  result = Val_int(c_result);
  CAMLreturn(result);
}

CAMLprim value caml_get_env_string(value unit) {
  CAMLparam1 (unit);
  CAMLlocal1(result);
  char* env = GetEnvironmentStrings();
  if (!env)
    caml_failwith("Failed to get environment string");
  int length = 0;
  char* env_point = env;
  while(*env_point) {
    int current_len = strlen(env_point);
    env_point += current_len + 1;
    length += current_len + 1;
  }
  result = caml_alloc_initialized_string((length == 0) ? 0 : length - 1, env);
  FreeEnvironmentStrings(env);
  CAMLreturn(result);
}
