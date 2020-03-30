open! Core_kernel
open! Core_windows

let test_header = printf "\nTesting %s\n========\n\n"

let () =
  test_header "get environment";
  Environment.get_environment () |> [%sexp_of: Environment.All_environment.t] |> print_s

let () =
  test_header "process";
  let proc = Process.Low_level.caml_create_win_process ~command:"notepad.exe" in
  print_endline "Waiting";
  Process.Low_level.caml_wait_win_process proc;
  print_endline "Test complete"
;;

(* 
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
  
*)
