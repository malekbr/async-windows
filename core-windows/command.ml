open! Core_kernel 

module Command = Core_kernel.Command

include (Command
         : (module type of struct include Command end
           with module Shape := Command.Shape
           with module Deprecated := Command.Deprecated))

module Path = Private.Path

[@@@ocaml.warning "-27"]

module For_unix = Private.For_unix (struct
    module Signal = struct
      type t
    end
    module Thread = Core_thread
    module Time = struct
      include Time
      let sexp_of_t t = Sexp.Atom (to_string t)
    end
    module Unix = struct
			module File_descr = struct
				type t = |
		end

			module Exit = struct
				type error = [ `Exit_non_zero of int ]
				type t = (unit, error) Result.t
			end

			module Exit_or_signal = struct
				type error =
					[ Exit.error
				| `Signal of Signal.t
				]

				type t = (unit, error) Result.t
			end

				let getpid () = assert false
		let close ?restart:_ _file_descr = assert false
		let open_process_in _str = assert false
		let close_process_in _in_channel = assert false
		let in_channel_of_descr _file_descr = assert false
		let putenv = Environment.putenv
		let unsetenv = Environment.unsetenv
		let unsafe_getenv = Environment.getenv

		type env =
			[ `Replace of (string * string) list
			| `Extend of (string * string) list
			| `Override of (string * string option) list
			| `Replace_raw of string list
					]

		let exec
			~prog
			~argv
			?use_path
			?env
			() =
				assert false
				;;

		module Process_info = struct
			type t =
				{ pid : Pid.t
				; stdin : File_descr.t
				; stdout : File_descr.t
				; stderr : File_descr.t
				}
			end

			let create_process_env
			 ?working_dir
			 ?prog_search_path
			 ?argv0
			 ~prog
			 ~args
			 ~env
			 () = assert false

			type wait_on =
				[ `Any
			| `Group of Pid.t
			| `My_group
			| `Pid of Pid.t
			]

			let wait ?restart _wait_on = assert false

		end
		module Version_util = struct
			let version = "[VERSION]"
			let reprint_build_info (_ : Time.t -> Sexp.t) = "[BUILD INFO]"
		end
  end)

let run = For_unix.run
let shape = For_unix.shape

module Deprecated = struct
  include Command.Deprecated
  let run = For_unix.deprecated_run
end

module Shape = struct
  include Command.Shape
  let help_text = For_unix.help_for_shape
end
