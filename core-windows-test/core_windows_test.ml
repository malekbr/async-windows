open! Core_kernel
open! Core_windows

let test_header s = printf "\nTesting %s\n========\n\n" s; Out_channel.flush stdout

let () =
  test_header "get environment";
  Environment.get_environment () |> [%sexp_of: Environment.All_environment.t] |> print_s

let () =
  test_header "process";
  (* TODO not robust *)
  (* TODO test read_all *)
  let process_path = String.rsplit2_exn Sys.executable_name ~on:'\\' |> fst in
  let command = process_path ^ "\\subprocess.exe" in 
  let proc = Process.Low_level.caml_create_win_process ~command in
  let proc_stdout = Process.Low_level.caml_stdout_win_process proc |> Io_handle.Private.of_ctype_read in
  let proc_stdin = Process.Low_level.caml_stdin_win_process proc |> Io_handle.Private.of_ctype_write in
  let test input =
    printf "Testing: %s" input;
    Out_channel.flush stdout;
    Io_handle.write proc_stdin input;
    Io_handle.read_line proc_stdout |> printf "Result: %s\n";
    Out_channel.flush stdout
  in
  test "(+ 1 2)\n";
  test "(+ (* 2 3) 5)\n";
  test "5\n";
  Process.Low_level.caml_wait_win_process proc;
  (* TODO have a single io_handle per handle and close stdin *)
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
  
