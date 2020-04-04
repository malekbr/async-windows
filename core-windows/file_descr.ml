open! Unix
open! Core_kernel

type t = file_descr

let in_channel_of_descr = in_channel_of_descr
let out_channel_of_descr = out_channel_of_descr
