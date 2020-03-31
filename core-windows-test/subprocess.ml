open! Core_kernel
open! Core_windows

module Dsl = struct
  type t =
    | Add of t list
    | Mul of t list
    | Value of int

  let rec t_of_sexp = function
    | Sexp.Atom value -> Value (Int.of_string value)
    | List ( Atom "+" :: rest) -> List.map rest ~f:t_of_sexp |> Add
    | List ( Atom "*" :: rest) -> List.map rest ~f:t_of_sexp |> Mul
    | _ -> assert false
  ;;

  let rec eval = function
    | Add ts -> List.map ts ~f:eval |> List.fold ~init:0 ~f:( + )
    | Mul ts -> List.map ts ~f:eval |> List.fold ~init:1 ~f:( * )
    | Value v -> v
  ;;
end

let rec loop () =
  match In_channel.input_line In_channel.stdin with
  | None -> ()
  | Some line ->
      Sexp.of_string line |> Dsl.t_of_sexp |> Dsl.eval |> printf "%d\n";
      Out_channel.flush stdout;
      loop ()
;;

let () = loop ();;
