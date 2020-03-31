open! Core_kernel
open! Core_windows

let test_header s = printf "\nTesting %s\n========\n\n" s; Out_channel.flush stdout

let () =
  test_header "get environment";
  Environment.get_environment () |> [%sexp_of: Environment.All_environment.t] |> print_s

let () =
  test_header "process";
  (* TODO not robust *)
  let process_path = String.rsplit2_exn Sys.executable_name ~on:'\\' |> fst in
  let command = process_path ^ "\\subprocess.exe" in 
  let proc = Process.Low_level.caml_create_win_process ~command in
  let io_handle = Process.Low_level.caml_stdout_win_process proc |> Io_handle.Private.of_ctype in
  let result = Io_handle.read_all io_handle |> Bigstring.to_string in
  print_endline "Subprocess output uppercased";
  print_endline (String.uppercase result);
  Process.Low_level.caml_wait_win_process proc;
  print_endline "Test complete"
;;

let () =
  test_header "threads";
  let thread_fn i =
    printf "Thread %d starting\n" i;
    Out_channel.flush stdout;
    printf "Thread %d sleeping for 1 second\n" i;
    Out_channel.flush stdout;
    Time_stubs.sleep Time_ns.Span.second; 
    printf "Thread %d woke up\n" i;
    Out_channel.flush stdout;
  in
  let threads = List.init 10 ~f:(Core_thread.create ~on_uncaught_exn:`Kill_whole_process thread_fn) in
  List.iter threads ~f:Core_thread.join;
  print_endline "Joined"
;;
  
