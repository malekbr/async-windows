open! Core_kernel
open! Core_windows

let () =
  for i = 1 to 10 do 
    printf "iteration %i in lowercase\n" i;
    Out_channel.flush stdout;
    Time_stubs.sleep (Time_ns.Span.of_sec 0.1)
  done
;;
