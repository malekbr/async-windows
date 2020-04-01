open! Core_kernel

module Low_level = struct
  type ctype
  external caml_create_win_process : command:string -> ctype = "caml_create_win_process"
  external caml_wait_win_process : ctype -> unit = "caml_wait_win_process"
  external caml_stdout_win_process : ctype -> Io_handle.Low_level.ctype = "caml_stdout_win_process"
  external caml_stderr_win_process : ctype -> Io_handle.Low_level.ctype = "caml_stderr_win_process"
  external caml_stdin_win_process : ctype -> Io_handle.Low_level.ctype = "caml_stdin_win_process"
  external caml_exit_code_win_process : ctype -> int = "caml_exit_code_win_process"
end

type t = 
  { low_level : Low_level.ctype
  ; stdin : Io_handle.t
  ; stdout : Io_handle.t
  ; stderr : Io_handle.t
  }
[@@deriving fields]

let create ~command =
  let low_level = Low_level.caml_create_win_process ~command in
  let stdin = Low_level.caml_stdin_win_process low_level |> Io_handle.Private.of_ctype_write in 
  let stdout = Low_level.caml_stdout_win_process low_level |> Io_handle.Private.of_ctype_read in 
  let stderr = Low_level.caml_stderr_win_process low_level |> Io_handle.Private.of_ctype_read in 
  { low_level; stdin; stdout; stderr }
;;

let wait t = Low_level.caml_wait_win_process t.low_level

let exit_code t = Low_level.caml_exit_code_win_process t.low_level
