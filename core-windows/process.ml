open! Core_kernel

module Low_level = struct
  type ctype
  external caml_create_win_process : command:string -> ctype = "caml_create_win_process"
  external caml_wait_win_process : ctype -> unit = "caml_wait_win_process"
  external caml_stdout_win_process : ctype -> Io_handle.Low_level.ctype = "caml_stdout_win_process"
  external caml_stderr_win_process : ctype -> Io_handle.Low_level.ctype = "caml_stderr_win_process"
  external caml_stdin_win_process : ctype -> Io_handle.Low_level.ctype = "caml_stdin_win_process"
end


