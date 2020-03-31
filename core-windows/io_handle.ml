open! Core_kernel

module Low_level = struct
  type ctype

  external caml_io_handle_read : ctype -> Bigstring.t -> pos:int -> at_most:int -> int = "caml_io_handle_read"
end

type t = { low_level : Low_level.ctype }

let read { low_level } buffer ~pos ~at_most =
  assert (pos + at_most <= Bigstring.length buffer);
  match Low_level.caml_io_handle_read low_level buffer ~pos ~at_most with
  | 0 -> `Eof
  | written when written < 0 -> raise_s [%message "Failed to read io_handle"]
  | written -> `Ok written
;;

let read_all t =
  let initial_size = 128 in
  let buffer = Bigstring.create initial_size in
  let rec read_loop buffer pos size =
    let buffer, size =
      if pos = size then
        let new_size = size * 2 in
        let new_buffer = Bigstring.create new_size in
        Bigstring.blito ~src:buffer ~dst:new_buffer ();
        new_buffer, new_size
      else buffer, size
    in
    let at_most = size - pos in
    match read t buffer ~pos ~at_most with
    | `Ok n -> read_loop buffer (pos + n) size
    | `Eof -> Bigstring.sub_shared buffer ~len:pos
  in
  read_loop buffer 0 initial_size
;;

module Private = struct
  let of_ctype low_level = { low_level }
end
