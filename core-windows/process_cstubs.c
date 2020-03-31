#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/threads.h>
#include <caml/gc_ctrl.h>
#include <windows.h>
#include <string.h>
#include <stdio.h>
#include "io_handle_cstubs.h"

typedef struct proc_info {
  PROCESS_INFORMATION process_information;
  STARTUPINFO startup_info;
  HANDLE proc_stdin;
  HANDLE proc_stdout;
  HANDLE proc_stderr;
  int cleaned;
} proc_info;

static void cleanup_handle(HANDLE* hndl) {
  if (*hndl) {
    CloseHandle(*hndl);
    hndl = NULL;
  }
}

static void cleanup (proc_info* proc_info) {
  if (!proc_info->cleaned) {
   // TODO add null checks and get rid of cleaned
   // TODO single handle for stdin/stdout/stderr, drop the pipes
   cleanup_handle(&(proc_info->process_information.hProcess));
   cleanup_handle(&(proc_info->process_information.hThread));
   cleanup_handle(&(proc_info->proc_stdin));
   cleanup_handle(&(proc_info->proc_stdout));
   cleanup_handle(&(proc_info->proc_stderr));
   proc_info->cleaned = 1;
  }
}

#define Proc_info_val(v) (*((struct proc_info **) Data_custom_val(v)))

static void finalize_proc_info(value v) {
 proc_info* proc_info = Proc_info_val(v);
 cleanup(proc_info);
 free(proc_info);
}

static struct custom_operations proc_info_ops = {
  "core.windows.proc_info",
  finalize_proc_info,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static void setup_pipe (HANDLE* rd, HANDLE* wr, SECURITY_ATTRIBUTES *attributes) {
    if ( ! CreatePipe(rd, wr, attributes, 0) ) {
      // TODO catch error, free already allocated, and return
      perror ("Failed to create pipe");
      exit (1);
    }
}

static void set_parent_handle(HANDLE hndl) {
   if ( ! SetHandleInformation(hndl, HANDLE_FLAG_INHERIT, 0) ) {
      // TODO catch error, free already allocated, and return
      perror ("Failed to set handle to parent");
      exit (1);
    }
}

static void setup_handles(proc_info * proc_info_obj) {
  SECURITY_ATTRIBUTES saAttr; 

  // Set the bInheritHandle flag so pipe handles are inherited. 

  saAttr.nLength = sizeof(SECURITY_ATTRIBUTES); 
  saAttr.bInheritHandle = TRUE; 
  saAttr.lpSecurityDescriptor = NULL; 

  HANDLE child_stdin = NULL;
  HANDLE child_stdout = NULL;
  HANDLE child_stderr = NULL;

  setup_pipe(&child_stdin, &(proc_info_obj->proc_stdin), &saAttr);
  setup_pipe(&(proc_info_obj->proc_stdout), &child_stdout, &saAttr);
  setup_pipe(&(proc_info_obj->proc_stderr), &child_stderr, &saAttr);

  set_parent_handle(proc_info_obj->proc_stdin);
  set_parent_handle(proc_info_obj->proc_stdout);
  set_parent_handle(proc_info_obj->proc_stderr);

  STARTUPINFO* startup_info = &(proc_info_obj->startup_info);
  startup_info->cb = sizeof(STARTUPINFO); 
  startup_info->hStdInput = child_stdin;
  startup_info->hStdOutput = child_stdout;
  startup_info->hStdError = child_stderr;
  startup_info->dwFlags |= STARTF_USESTDHANDLES;
}

static void close_child_handles (proc_info * proc_info_obj) {
  STARTUPINFO* startup_info = &(proc_info_obj->startup_info);
  CloseHandle(startup_info->hStdInput);
  CloseHandle(startup_info->hStdOutput);
  CloseHandle(startup_info->hStdError);
}

// TODO environment
// command is space separated quoted
CAMLprim value caml_create_win_process(value v_command) {
  CAMLparam1(v_command);
  CAMLlocal1(v_proc_info);
  const char* command_c = String_val(v_command);
  char* command = malloc (strlen(command_c) * sizeof(char));
  strcpy(command, command_c);

  caml_release_runtime_system();

  proc_info* proc_info_obj = malloc(sizeof(proc_info));
  memset(proc_info_obj, 0, sizeof(proc_info));
  setup_handles(proc_info_obj);

  BOOL success = CreateProcess(NULL,
      command,
      NULL,
      NULL,
      TRUE,
      0,
      NULL,
      NULL,
      &(proc_info_obj->startup_info),
      &(proc_info_obj->process_information));

  // TODO clean up pipes on fail 
  close_child_handles(proc_info_obj);

  free(command);

  caml_acquire_runtime_system();

  if ( ! success ) {
    LPSTR messageBuffer = NULL;
    DWORD errorMessageID = GetLastError();
    FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                   NULL,
                   errorMessageID,
                   MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                   (LPSTR)&messageBuffer,
                   0,
                   NULL);
    // TODO memory leak, call LocalFree
    caml_failwith(messageBuffer);
  }
  

  v_proc_info = caml_alloc_custom(&proc_info_ops, sizeof(struct proc_info *), 0, 1);
  Proc_info_val(v_proc_info) = proc_info_obj;
  CAMLreturn(v_proc_info); 
}

CAMLprim value caml_wait_win_process(value v_proc_info) {
  CAMLparam1(v_proc_info);
  proc_info * proc_info_obj = Proc_info_val(v_proc_info);
  caml_release_runtime_system();
  WaitForSingleObject( proc_info_obj->process_information.hProcess, INFINITE );
  caml_acquire_runtime_system();
  CAMLreturn(Val_unit); 
}

// TODO unify
CAMLprim value caml_stdout_win_process(value v_proc_info)  {
  CAMLparam1(v_proc_info);
  CAMLlocal1(v_result);
  proc_info * proc_info_obj = Proc_info_val(v_proc_info);
  caml_release_runtime_system();
  io_handle* io_handle_obj = io_handle_duplicate_handle(proc_info_obj->proc_stdout);
  caml_acquire_runtime_system();
  v_result =  caml_value_io_handle(io_handle_obj);
  CAMLreturn(v_result);
}

CAMLprim value caml_stderr_win_process(value v_proc_info)  {
  CAMLparam1(v_proc_info);
  CAMLlocal1(v_result);
  proc_info * proc_info_obj = Proc_info_val(v_proc_info);
  caml_release_runtime_system();
  io_handle* io_handle_obj = io_handle_duplicate_handle(proc_info_obj->proc_stderr);
  caml_acquire_runtime_system();
  v_result =  caml_value_io_handle(io_handle_obj);
  CAMLreturn(v_result);
}

CAMLprim value caml_stdin_win_process(value v_proc_info)  {
  CAMLparam1(v_proc_info);
  CAMLlocal1(v_result);
  proc_info * proc_info_obj = Proc_info_val(v_proc_info);
  caml_release_runtime_system();
  io_handle* io_handle_obj = io_handle_duplicate_handle(proc_info_obj->proc_stdin);
  caml_acquire_runtime_system();
  v_result =  caml_value_io_handle(io_handle_obj);
  CAMLreturn(v_result);
}
