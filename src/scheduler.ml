open! Core_kernel
open! Async_kernel


module Scheduler = Async_kernel_scheduler.Private

type t =
  { kernel_scheduler : Scheduler.t }

let create () =
  { kernel_scheduler = Scheduler.t () }

let global_scheduler = ref None

let get_global_scheduler =
  match !global_scheduler with
  | Some scheduler -> scheduler
  | None ->
      let scheduler = create () in
      global_scheduler := Some scheduler;
      scheduler

let rec run () =
  let { kernel_scheduler } = get_global_scheduler in
  Scheduler.run_cycle kernel_scheduler;
  if Scheduler.can_run_a_job kernel_scheduler then
   run ()
  else
    Scheduler.next_upcoming_event kernel_scheduler |> Option.iter ~f:(fun next_upcoming_event ->
      let now = Time_ns.now () in
      let d = Time_ns.diff next_upcoming_event now in
      Stubs.sleep d;
      run ())

module Expect_test_config = struct
  module IO = Deferred
  module IO_run = IO

  module IO_flush = struct
    include IO

    let to_run t = t
  end

  let flush () = return ()
  let run f = let (_ : unit Deferred.t) = f () in run ()
  let flushed () = true
  let upon_unreleasable_issue = Expect_test_config.upon_unreleasable_issue
end


