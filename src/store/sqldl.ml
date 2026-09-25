(* Runtime-loaded SQLite C API (see sqldl_stubs.c).
   @lat: [[storage#Store Signature]] *)

type value = Null | Int of int64 | Float of float | Text of string | Blob of string

type lib
type db
type stmt

external load_raw : string -> lib * string list = "sqldl_load"
external libversion : lib -> string = "sqldl_libversion"
external open_raw : lib -> string -> bool -> db = "sqldl_open"
external close : db -> unit = "sqldl_close"
external exec : db -> string -> unit = "sqldl_exec"
external prepare : db -> string -> stmt = "sqldl_prepare"
external finalize : stmt -> unit = "sqldl_finalize"
external reset : stmt -> unit = "sqldl_reset"
external bind_raw : stmt -> int -> value -> unit = "sqldl_bind"
external step : stmt -> bool = "sqldl_step"
external column_count : stmt -> int = "sqldl_column_count"
external column : stmt -> int -> value = "sqldl_column"
external changes : db -> int = "sqldl_changes"
external last_insert_rowid : db -> int64 = "sqldl_last_insert_rowid"
external autocommit : db -> bool = "sqldl_autocommit"
external load_extension : db -> string -> unit = "sqldl_load_extension"

(* Loads a backend library. Returns the library and the required symbols it
   lacks; a library with missing symbols is unusable for the engine. *)
let load path = load_raw path

let open_ ?(readonly = false) lib path = open_raw lib path readonly

(* SQL parameters are 1-based. *)
let bind stmt params = Array.iteri (fun i v -> bind_raw stmt (i + 1) v) params

let row stmt = Array.init (column_count stmt) (column stmt)

(* Lazy row sequence over a prepared statement: each [Seq] step advances the
   cursor, so a consumer that stops early never fetches later rows. The
   statement is reset when exhausted. *)
let rows stmt : value array Seq.t =
  let rec next () =
    if step stmt then Seq.Cons (row stmt, next)
    else (
      reset stmt;
      Seq.Nil)
  in
  next

let query db sql params =
  let st = prepare db sql in
  Fun.protect ~finally:(fun () -> finalize st) @@ fun () ->
  bind st params;
  List.of_seq (rows st)

let exec_params db sql params =
  let st = prepare db sql in
  Fun.protect ~finally:(fun () -> finalize st) @@ fun () ->
  bind st params;
  while step st do () done

let pp_value ppf = function
  | Null -> Format.pp_print_string ppf "NULL"
  | Int i -> Format.fprintf ppf "%Ld" i
  | Float f -> Format.fprintf ppf "%g" f
  | Text s -> Format.fprintf ppf "%S" s
  | Blob b -> Format.fprintf ppf "<blob %d>" (String.length b)
