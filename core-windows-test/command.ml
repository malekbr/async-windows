open Core_kernel
open Core_windows

let interpolate i ~min ~max ~count =
    (Float.of_int i *. (max -. min) /. Float.of_int count) +. min


module Plot_params = struct
  type t =
    { from : float
    ; to_ : float
    ; count : int
    }

  let compute { from; to_; count } ~f =
    List.init count ~f:(fun i -> interpolate i ~min:from ~max:to_ ~count |> f) 
  ;;

  let param =
    let%map_open.Command
    from = flag "-from" (required float) ~doc:"<float> start of plot" and
    to_ = flag "-to" (required float) ~doc:"<float> end of plot" and
    count = flag "-count" (optional_with_default 80 int) ~doc:"<int> how many samples to take"
    in
    { from; to_; count }
  ;;
end


module Plot_type = struct
  type t =
    | Exponential of { base : float }
    | Sine of { period : float }
    | Linear of { m : float; b : float }

  let generate = function
    | Exponential { base } -> Plot_params.compute ~f:(Float.( ** ) base)
    | Sine { period } -> Plot_params.compute ~f:(fun x -> Float.sin (x *. period))
    | Linear { m; b } -> Plot_params.compute ~f:(fun x -> m *. x +. b)
  ;;

  let generate_line y values =
    "|" ^ (List.map values ~f:(fun value ->
      if Float.(value <= y) then ' ' else '*') |> String.of_char_list)
    ^ "| " ^ Float.to_string y
  ;;

  let edges ~line_count values =
    let min = List.min_elt ~compare:Float.compare values |> Option.value_exn in
    let max =  List.max_elt ~compare:Float.compare values |> Option.value_exn in
    let delta = (max -. min) /. Float.of_int line_count in
    min -. delta, max +. delta
  ;;

  let plot ~line_count values =
    let min, max = edges ~line_count values in
    List.init line_count ~f:(fun i ->
      generate_line (interpolate i ~min ~max ~count:line_count) values)
    |> List.rev
    |> List.iter ~f:print_endline
  ;;

  let plot t plot_params =
    generate t plot_params |> plot ~line_count:30
  ;;
end

let create_command plot_type = 
  Command.basic
   (let%map_open.Command
      params = Plot_params.param
      and plot_type = plot_type
    in
    fun () ->
      Plot_type.plot plot_type params)
  ;;

let exponential_command = create_command ~summary:"Exponential plot"
   Command.Param.(anon ("base" %: float) |> map ~f:(fun base -> Plot_type.Exponential { base })) 
;;

let sine_command = create_command ~summary:"Sine plot"
   Command.Param.(anon ("period" %: float) |> map ~f:(fun period -> Plot_type.Sine { period })) 
;;

let linear_command = create_command ~summary:"Linear plot"
  (let%map_open.Command
  m = anon ("slope" %: float) and
  b = flag "-value-at-0" (optional_with_default 0. float) ~doc:"<float> value at 0"
  in
  Plot_type.Linear { m; b })
;;

let () =
  Command.group
  ~summary:"plot"
  [ "linear", linear_command
  ; "sine", sine_command
  ; "exponential", exponential_command
  ]
    |> Command.run
;;
