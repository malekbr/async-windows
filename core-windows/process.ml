open! Core_kernel

module Low_level = struct
  type c_proc_info
  external caml_create_win_process : command:string -> c_proc_info = "caml_create_win_process"
  external caml_wait_win_process : c_proc_info -> unit = "caml_wait_win_process"
end
