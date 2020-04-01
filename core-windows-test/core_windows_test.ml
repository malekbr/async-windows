open! Core_kernel
open! Core_windows

let test_header s = printf "\nTesting %s\n========\n\n" s; Out_channel.flush stdout

let () =
  test_header "get environment";
  Environment.get_environment () |> [%sexp_of: Environment.All_environment.t] |> print_s

let with_test_subprocess ~f =
  (* TODO not robust add path utils *)
  let process_path = String.rsplit2_exn Sys.executable_name ~on:'\\' |> fst in
  let command = process_path ^ "\\subprocess.exe" in 
  let proc = Process.create ~command in
  f proc;
  Process.wait proc;
  let exit_code = Process.exit_code proc in
  printf "Exit code: %d\n" exit_code;
  Out_channel.flush stdout
;;


let () =
  test_header "process";
  (* TODO test read_all *)
  with_test_subprocess ~f:(fun proc ->
    let proc_stdout = Process.stdout proc in
    let proc_stdin = Process.stdin proc in
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
    Io_handle.close proc_stdin);
  print_endline "Test complete"
;;

let () =
  test_header "process stderr";
  with_test_subprocess ~f:(fun proc ->
    let proc_stderr = Process.stderr proc in
    let proc_stdout = Process.stdout proc in
    let proc_stdin = Process.stdin proc in
    let stdin_input = "(+ 1 2)\n5\n(broken\n" in
    Io_handle.write proc_stdin stdin_input;
    let stdout = Io_handle.read_all proc_stdout in
    let stderr = Io_handle.read_all proc_stderr in
    Process.wait proc;
    print_endline "STDIN:";
    print_endline stdin_input;
    print_endline "STDOUT:";
    print_endline stdout;
    print_endline "STDERR:";
    print_endline stderr);
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
  
