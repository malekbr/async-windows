open! Core_kernel

module Low_level = struct
  type ctype

  external caml_io_handle_read : ctype -> Bigstring.t -> pos:int -> at_most:int -> int = "caml_io_handle_read"
  external caml_io_handle_write : ctype -> string -> len:int -> bool = "caml_io_handle_write"
  external caml_io_handle_close : ctype -> unit = "caml_io_handle_close"
end

module Read = struct
  type t =
    { low_level : Low_level.ctype
    ; mutable buffer : Bigstring.t
    ; mutable pos : int
    ; mutable eof : bool
    }

  let maybe_resize t =
    let buffer = t.buffer in
    let pos = t.pos in
    let size = Bigstring.length buffer in
    if pos = size then (
      let new_size = size * 2 in
      let new_buffer = Bigstring.create new_size in
      Bigstring.blito ~src:buffer ~dst:new_buffer ();
      t.buffer <- new_buffer)
  ;;


  let read_internal ?at_most t =
    if t.eof then `Eof
    else (
      maybe_resize t;
      let size = Bigstring.length t.buffer in
      let available = size - t.pos in
      let at_most =
        match at_most with
        | None -> available
        | Some at_most -> Int.min at_most available
      in
      match Low_level.caml_io_handle_read t.low_level t.buffer ~pos:t.pos ~at_most with
      | 0 ->
          t.eof <- true;
          `Eof
      | written when written < 0 -> raise_s [%message "Failed to read io_handle"]
      | written ->
          t.pos <- t.pos + written;
          `Ok written)
  ;;

  let consume_internal t ~len =
    let result = Bigstring.To_string.subo ~len t.buffer in
    Bigstring.blit ~src:t.buffer ~dst:t.buffer ~src_pos:len ~dst_pos:0 ~len:(t.pos - len);
    t.pos <- t.pos - len;
    result
  ;;

  let rec read_all t =
    match read_internal t with
    | `Ok _ -> read_all t
    | `Eof -> consume_internal t ~len:t.pos
  ;;

  let read_line t =
    let rec read_until_newline t from =
      match Bigstring.find '\n' t.buffer ~len:(t.pos - from) ~pos:from with
      | Some pos -> consume_internal t ~len:(pos + 1)
      | None ->
          let read_from = t.pos in
          match read_internal t with
          | `Ok _ -> read_until_newline t read_from
          | `Eof -> consume_internal t ~len:t.pos
    in
    read_until_newline t 0
  ;;

  let close t = Low_level.caml_io_handle_close t.low_level
end

module Write = struct
  type t = { low_level : Low_level.ctype }

  let write t str =
    let len = String.length str in
    if not (Low_level.caml_io_handle_write t.low_level ~len str) then
      raise_s [%message "Failed to write"]
  ;;

  let close t = Low_level.caml_io_handle_close t.low_level
end

type t =
  | Read of Read.t
  | Write of Write.t

let read_handle_exn = function
  | Read read -> read
  | Write _ -> raise_s [%message "Performing read on write handle"]
;;

let write_handle_exn = function
  | Write write -> write
  | Read _ -> raise_s [%message "Performing write on read handle"]
;;

let read_all t = read_handle_exn t |> Read.read_all
let read_line t = read_handle_exn t |> Read.read_line
let write t s = Write.write (write_handle_exn t) s

let close = function
  | Read read -> Read.close read
  | Write write -> Write.close write
;;

module Private = struct
  let of_ctype_read low_level = Read { low_level; buffer = Bigstring.create 128; pos = 0; eof = false }
  let of_ctype_write low_level = Write { low_level }
end
