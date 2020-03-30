open! Core_kernel
external win_sleep : int -> unit = "win_sleep"

let sleep sleep_span =
  if Time_ns.Span.(sleep_span <= zero) then () 
  else win_sleep (Time_ns.Span.to_ms sleep_span |> Float.to_int)
