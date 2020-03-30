open! Core_kernel

let threads_have_been_created = ref false

include Thread

let sexp_of_t t = [%message "thread" ~id:(id t : int)]

let create_should_raise = ref false

let create ~on_uncaught_exn f arg =
  if !create_should_raise
  then raise_s [%message "Thread.create requested to raise"];
  threads_have_been_created := true;
  let f arg : unit =
    let exit =
      match on_uncaught_exn with
      | `Print_to_stderr -> false
      | `Kill_whole_process -> true
    in
    Exn.handle_uncaught ~exit (fun () -> f arg)
  in
  create f arg
;;

