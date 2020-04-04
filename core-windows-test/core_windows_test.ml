open! Core_kernel
open! Core_windows

let printf' format =
  let result = printf format in
  Out_channel.flush stdout;
  result
;;

let test_header s = printf' "\nTesting %s\n========\n\n" s; Out_channel.flush stdout

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
  printf' "Exit code: %d\n" exit_code
;;


let () =
  test_header "process";
  (* TODO test read_all *)
  with_test_subprocess ~f:(fun proc ->
    (*
    let () = Process.stdout proc |> Obj.magic |> printf' "%d\n" in
    Out_channel.flush stdout;
    Time_stubs.sleep Time_ns.Span.second; 
    let () = raise (Invalid_argument "t") in *)
    let proc_stdout = Process.stdout proc |> File_descr.in_channel_of_descr in
    let proc_stdin = Process.stdin proc |> File_descr.out_channel_of_descr in
    let test input =
      printf' "Testing: %s" input;
      Out_channel.output_string proc_stdin input;
      Out_channel.flush proc_stdin;
      In_channel.input_line proc_stdout |> Option.value_exn |> printf' "Result: %s\n"
    in
    test "(+ 1 2)\n";
    test "(+ (* 2 3) 5)\n";
    test "5\n";
    Out_channel.close proc_stdin);
  print_endline "Test complete"
;;

let () =
  test_header "process stderr";
  with_test_subprocess ~f:(fun proc ->
    let proc_stderr = Process.stderr proc |> File_descr.in_channel_of_descr in
    let proc_stdout = Process.stdout proc |> File_descr.in_channel_of_descr in
    let proc_stdin = Process.stdin proc |> File_descr.out_channel_of_descr  in
    let stdin_input = "(+ 1 2)\n5\n(broken\n" in
    Out_channel.output_string proc_stdin stdin_input;
    Out_channel.flush proc_stdin;
    let stdout = In_channel.input_all proc_stdout in
    let stderr = In_channel.input_all proc_stderr in
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
  let mutex = Mutex.create () in
  let thread_fn i =
    Mutex.lock mutex;
    printf' "Thread %d starting\n" i;
    printf' "Thread %d sleeping for 1 second\n" i;
    Mutex.unlock mutex;
    Time_stubs.sleep Time_ns.Span.second; 
    Mutex.lock mutex;
    printf' "Thread %d woke up\n" i;
    Mutex.unlock mutex;
  in
  let threads = List.init 10 ~f:(Core_thread.create ~on_uncaught_exn:`Kill_whole_process thread_fn) in
  List.iter threads ~f:Core_thread.join;
  print_endline "Joined"
;;
  
