open! Core_kernel

external caml_set_env : string -> string -> int = "caml_set_env"
external caml_unset_env : string -> int = "caml_unset_env"
external caml_get_env_string : unit-> string = "caml_get_env_string"

let getenv key = Sys.getenv_opt key

let putenv ~key ~data =
  let result = caml_set_env key data in
  if result = 0 then
    raise_s [%message "Failed to set environment variable" (key : string) (data : string)]
;;

let unsetenv key =
  let result = caml_unset_env key in
  if result = 0 then
    raise_s [%message "Failed to unset environment variable" (key : string)]
;;

module All_environment = struct
  module Entry = struct
    type t =
      | Unparsable of string
      | Pair of { key : string; data : string }
    [@@deriving sexp_of]
  end

  type t = Entry.t list [@@deriving sexp_of]
end

let get_environment () =
  caml_get_env_string () |> String.split ~on:'\x00'
  |> List.map ~f:(fun s ->
      if String.is_prefix ~prefix:"=" s then (All_environment.Entry.Unparsable s)
      else
        (match String.lsplit2 s ~on:'=' with
         | None -> Unparsable s
         | Some (key, data) -> Pair { key; data }))
;;

let%test "get for unknown variable" =
  getenv "test-for-windows-async" |> Option.is_none
;;

let%test "setting variable" =
  putenv ~key:"test-for-windows-async" ~data:"test";
  getenv "test-for-windows-async" |> [%equal: string option] (Some "test")
;;

let%test "unsetting variable" =
  putenv ~key:"test-for-windows-async" ~data:"test";
  unsetenv "test-for-windows-async"; 
  getenv "test-for-windows-async" |> Option.is_none
;;
