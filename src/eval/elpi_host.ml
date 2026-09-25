(* Embedding of ELPI with SQL cursor builtins.
   @lat: [[evaluation#EDB Builtins]]

   ELPI builtins are deterministic, so lazy enumeration of rows is obtained
   with an ELPI-level stream clause that pulls the next row from a cursor on
   backtracking:
     sql_stream C R :- sql_next C R0, (R = R0 ; sql_stream C R).
   Cursors left open by consumers that stop early are closed when the query
   ends (see [run]). *)

open Elpi.API
module Sql = Elpilite_store.Sqldl

exception Elpi_error of string

let () =
  let raise_err ?loc msg =
    let where =
      match loc with None -> "" | Some l -> Ast.Loc.show l ^ ": "
    in
    raise (Elpi_error (where ^ msg))
  in
  Setup.set_error raise_err;
  Setup.set_anomaly raise_err;
  Setup.set_type_error raise_err;
  Setup.set_warn (fun ?loc:_ _ -> ())

(* ---- SQL values as ELPI data ------------------------------------------- *)

let sqlv : Sql.value Conversion.t =
  let open AlgebraicData in
  declare
    {
      ty = Conversion.TyName "sqlv";
      doc = "A SQL value";
      pp = Sql.pp_value;
      constructors =
        [
          K ("sql_null", "NULL", N, B Sql.Null,
             M (fun ~ok ~ko -> function Sql.Null -> ok | _ -> ko ()));
          K ("sql_int", "INTEGER", A (BuiltInData.int, N),
             B (fun i -> Sql.Int (Int64.of_int i)),
             M (fun ~ok ~ko -> function Sql.Int i -> ok (Int64.to_int i) | _ -> ko ()));
          K ("sql_real", "REAL", A (BuiltInData.float, N),
             B (fun f -> Sql.Float f),
             M (fun ~ok ~ko -> function Sql.Float f -> ok f | _ -> ko ()));
          K ("sql_text", "TEXT", A (BuiltInData.string, N),
             B (fun s -> Sql.Text s),
             M (fun ~ok ~ko -> function Sql.Text s -> ok s | _ -> ko ()));
          K ("sql_blob", "BLOB (as bytes in a string)", A (BuiltInData.string, N),
             B (fun s -> Sql.Blob s),
             M (fun ~ok ~ko -> function Sql.Blob s -> ok s | _ -> ko ()));
        ];
    }
  |> ContextualConversion.(!<)

(* ---- cursors ------------------------------------------------------------ *)

type cursor = { id : int; mutable stmt : Sql.stmt option }

let cursor : cursor Conversion.t =
  OpaqueData.declare
    {
      name = "cursor";
      doc = "An open SQL cursor";
      pp = (fun fmt c -> Format.fprintf fmt "<cursor %d>" c.id);
      compare = (fun a b -> compare a.id b.id);
      hash = (fun c -> c.id);
      hconsed = false;
      constants = [];
    }

(* Per-query context: the database the builtins read from, the cursors to
   close at the end, and a row counter used to observe laziness. *)
type ctx = {
  db : Sql.db;
  mutable open_cursors : cursor list;
  mutable rows_fetched : int;
  mutable next_id : int;
}

let current : ctx option ref = ref None

let ctx () =
  match !current with
  | Some c -> c
  | None -> raise (Elpi_error "no database bound to the running query")

let close_cursor c =
  match c.stmt with
  | Some st ->
      Sql.finalize st;
      c.stmt <- None
  | None -> ()

let builtins =
  let open BuiltIn in
  let open BuiltInPredicate in
  let open BuiltInPredicate.Notation in
  declare ~file_name:"elpilite_sql.elpi"
    [
      MLData sqlv;
      MLData cursor;
      MLCode
        ( Pred
            ( "sql_open_cursor",
              In (BuiltInData.string, "SQL",
              In (BuiltInData.list sqlv, "Params",
              Out (cursor, "Cursor",
              Easy "opens a cursor over the rows of SQL with Params"))),
              fun sql params _ ~depth:_ ->
                let c = ctx () in
                let st = Sql.prepare c.db sql in
                Sql.bind st (Array.of_list params);
                let cur = { id = c.next_id; stmt = Some st } in
                c.next_id <- c.next_id + 1;
                c.open_cursors <- cur :: c.open_cursors;
                !: cur ),
          DocAbove );
      MLCode
        ( Pred
            ( "sql_next",
              In (cursor, "Cursor",
              Out (BuiltInData.list sqlv, "Row",
              Easy "fetches the next row; fails and closes the cursor when exhausted")),
              fun cur _ ~depth:_ ->
                match cur.stmt with
                | None -> raise No_clause
                | Some st ->
                    if Sql.step st then (
                      let c = ctx () in
                      c.rows_fetched <- c.rows_fetched + 1;
                      !: (Array.to_list (Sql.row st)))
                    else (
                      close_cursor cur;
                      raise No_clause) ),
          DocAbove );
      LPCode
        {|
% [sql_rows SQL Params Row] enumerates the rows of SQL lazily on backtracking.
pred sql_rows i:string, i:list sqlv, o:list sqlv.
sql_rows SQL Params Row :- sql_open_cursor SQL Params C, sql_stream C Row.

pred sql_stream i:cursor, o:list sqlv.
sql_stream C Row :- sql_next C R0, (Row = R0 ; sql_stream C Row).
|};
    ]

(* ---- running programs --------------------------------------------------- *)

let elpi = lazy (Setup.init ~builtins:[ Elpi.Builtin.std_builtins; builtins ] ())

let parse_program text =
  let elpi = Lazy.force elpi in
  let loc = Ast.Loc.initial "(program)" in
  Parse.program_from ~elpi ~loc (Lexing.from_string text)

let compile program_text =
  let elpi = Lazy.force elpi in
  Compile.program ~elpi [ parse_program program_text ]

type solution = (string * string) list (* variable name, printed term *)

type result = { solutions : solution list; rows_fetched : int }

(* Runs [goal] against [program], returning at most [max] solutions. *)
let run ~db ?(max = max_int) ?max_steps ~program goal =
  let elpi = Lazy.force elpi in
  let prog = compile program in
  let q = Compile.query prog (Parse.goal ~elpi ~loc:(Ast.Loc.initial "(goal)") ~text:goal) in
  let exe = Compile.optimize q in
  let c = { db; open_cursors = []; rows_fetched = 0; next_id = 0 } in
  current := Some c;
  let sols = ref [] in
  let print (s : unit Data.solution) =
    Data.StrMap.bindings s.assignments
    |> List.map (fun (k, t) -> (k, Format.asprintf "%a" (Pp.term s.pp_ctx) t))
  in
  Fun.protect
    ~finally:(fun () ->
      List.iter close_cursor c.open_cursors;
      current := None)
  @@ fun () ->
  (match max_steps with
  | Some max_steps -> (
      match Execute.once ~max_steps exe with
      | Execute.Success s -> sols := [ print s ]
      | Execute.Failure -> ()
      | Execute.NoMoreSteps -> raise (Elpi_error "step_limit"))
  | None ->
      Execute.loop exe
        ~more:(fun () -> List.length !sols < max)
        ~pp:(fun _ -> function
          | Execute.Success s -> sols := print s :: !sols
          | Execute.Failure | Execute.NoMoreSteps -> ()));
  { solutions = List.rev !sols; rows_fetched = c.rows_fetched }
