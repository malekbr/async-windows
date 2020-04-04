open! Unix
open! Core_kernel

module Low_level = struct
  type ctype
  external caml_create_win_process : command:string -> ctype = "caml_create_win_process"
  external caml_wait_win_process : ctype -> unit = "caml_wait_win_process"
  external caml_stdout_win_process : ctype -> file_descr = "caml_stdout_win_process"
  external caml_stderr_win_process : ctype -> file_descr = "caml_stderr_win_process"
  external caml_stdin_win_process : ctype -> file_descr = "caml_stdin_win_process"
  external caml_exit_code_win_process : ctype -> int = "caml_exit_code_win_process"
end

type t = 
  { low_level : Low_level.ctype
  ; stdin : file_descr
  ; stdout : file_descr
  ; stderr : file_descr
  }
[@@deriving fields]

let create ~command =
  let low_level = Low_level.caml_create_win_process ~command in
  let stdin = Low_level.caml_stdin_win_process low_level in 
  let stdout = Low_level.caml_stdout_win_process low_level in 
  let stderr = Low_level.caml_stderr_win_process low_level in 
  { low_level; stdin; stdout; stderr }
;;

let wait t = Low_level.caml_wait_win_process t.low_level

let exit_code t = Low_level.caml_exit_code_win_process t.low_level
