#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/threads.h>
#include <caml/gc_ctrl.h>
#include <caml/bigarray.h>
#include <windows.h>
#include <string.h>
#include <stdio.h>
#include "shared.h"
#include "io_handle_cstubs.h"

#define Io_handle_val(v) (*((struct io_handle **) Data_custom_val(v)))

static void cleanup (io_handle* io_handle_obj) {
  safe_close_handle(&(io_handle_obj->hndl));
}

static void finalize_io_handle(value v) {
 io_handle* io_handle_obj = Io_handle_val(v);
 cleanup(io_handle_obj);
 free(io_handle_obj);
}

static struct custom_operations io_handle_ops = {
  "core.windows.io_handle",
  finalize_io_handle,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

io_handle* io_handle_wrap_and_own (HANDLE hndl) {
  io_handle* io_handle_obj = malloc(sizeof(io_handle));

  if (!io_handle_obj) {
    perror("[io_handle_wrap_and_own] failed to malloc");
    exit(1);
  }
  
  io_handle_obj->hndl = hndl;

  return io_handle_obj;
}

value caml_value_io_handle (io_handle* io_handle_obj) {
  value v_result = caml_alloc_custom(&io_handle_ops, sizeof(io_handle *), 0, 1);
  Io_handle_val(v_result) = io_handle_obj;
  return v_result;
}

// Returns null if failed
io_handle* io_handle_duplicate_handle (HANDLE hndl) {
  HANDLE target_handle = NULL;
  HANDLE current_process = GetCurrentProcess();
  BOOL success = DuplicateHandle(
      current_process,
      hndl,
      current_process,
      &target_handle,
      0,
      FALSE,
      DUPLICATE_SAME_ACCESS
  ); 

  if (success)
    return io_handle_wrap_and_own(target_handle);
  else
    return NULL;
}

static void fail_if_null (io_handle* io_handle_obj) {
  if (!io_handle_obj->hndl) {
    caml_failwith("io_handle already closed");
  }
}

CAMLprim value caml_io_handle_read (value v_io_handle, value v_buffer, value v_pos, value v_at_most) {
  CAMLparam4(v_io_handle, v_buffer, v_pos, v_at_most);
  io_handle* io_handle_obj = Io_handle_val(v_io_handle);
  fail_if_null (io_handle_obj);
  char* buffer = Caml_ba_data_val(v_buffer);
  int at_most = Int_val(v_at_most);
  char* temp_buffer = malloc(sizeof(char) * at_most); 
  int pos = Int_val(v_pos);
  caml_release_runtime_system();
  // assumes no file is opened with overlapped
  DWORD read;
  BOOL success = ReadFile(io_handle_obj->hndl, temp_buffer, at_most, &read, NULL);
  DWORD errorMessageID = GetLastError();
  // For pipes when the other pipe is closed, it just says the pipe is broken
  if (!success && errorMessageID == ERROR_BROKEN_PIPE) {
    success = TRUE;
    read = 0;
  }
  caml_acquire_runtime_system();
  int read_result;
  if (success) {
    read_result = (int) read; // capped at int because at_most is int
    memcpy(buffer + pos, temp_buffer, sizeof(char) * read_result); 
  } else {
    read_result = -1;
  }
  free (temp_buffer);
  CAMLreturn(Val_int(read_result));
}

// TODO should this be a bigstring?
CAMLprim value caml_io_handle_write (value v_io_handle, value v_string, value v_len) {
  CAMLparam3(v_io_handle, v_string, v_len);
  io_handle* io_handle_obj = Io_handle_val(v_io_handle);
  fail_if_null (io_handle_obj);
  const char* caml_string = String_val(v_string);
  int len = Int_val(v_len);
  char* buffer = malloc(sizeof(char) * len); 
  memcpy(buffer, caml_string, len);
  caml_release_runtime_system();
  // assumes no file is opened with overlapped
  DWORD written;
  BOOL success = WriteFile(io_handle_obj->hndl, buffer, len, &written, NULL);
  caml_acquire_runtime_system();
  int write_result;
  free (buffer);
  if (success && written == len) {
    write_result = 1;
  } else {
    write_result = 0;
  }
  CAMLreturn(Val_bool(write_result));
}

CAMLprim value caml_io_handle_close(value v_io_handle) {
  CAMLparam1(v_io_handle);
  io_handle* io_handle_obj = Io_handle_val(v_io_handle);
  fail_if_null (io_handle_obj);
  caml_release_runtime_system();
  cleanup(io_handle_obj);
  caml_acquire_runtime_system();
  CAMLreturn(Val_unit);
}
