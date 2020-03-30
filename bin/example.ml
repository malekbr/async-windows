open! Core_kernel
open! Async_kernel
open! Async_windows

let () =
  don't_wait_for (
    Time_ns.now () |> Time_ns.to_string |> print_endline;
    let%map () = Clock_ns.after (Time_ns.Span.of_sec 1.) in
    Time_ns.now () |> Time_ns.to_string |> print_endline)
;;

let () = Scheduler.run () 
