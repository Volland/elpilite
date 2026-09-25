(* M0 build spike: both backends load, ELPI runs goals over SQL cursors, and
   row enumeration is lazy. *)

open Elpilite_store
module Host = Elpilite_eval.Elpi_host

let tmp_db () = Filename.temp_file "elpilite_m0_" ".db"

let with_db kind f =
  let path = tmp_db () in
  Sys.remove path;
  let db = Backend.open_ kind path in
  Fun.protect ~finally:(fun () -> Sqldl.close db) (fun () -> f db)

let setup db n =
  Sqldl.exec db "CREATE TABLE t (x INTEGER, name TEXT)";
  Sqldl.exec db "BEGIN";
  for i = 1 to n do
    Sqldl.exec_params db "INSERT INTO t VALUES (?, ?)"
      [| Sqldl.Int (Int64.of_int i); Sqldl.Text (Printf.sprintf "n%d" i) |]
  done;
  Sqldl.exec db "COMMIT"

let program = {|
pred small o:int.
small X :- sql_rows "SELECT x FROM t WHERE x < 6" [] [sql_int X], X > 2.
|}

let tests kind =
  let name = Backend.name kind in
  [
    Testkit.case (name ^ ": raw SQL round-trip") (fun () ->
        with_db kind @@ fun db ->
        setup db 10;
        let rows = Sqldl.query db "SELECT count(*), sum(x) FROM t" [||] in
        Testkit.strings "count,sum" [ "10"; "55" ]
          (List.concat_map
             (fun r -> Array.to_list (Array.map (Format.asprintf "%a" Sqldl.pp_value) r))
             rows));
    Testkit.case (name ^ ": ELPI goal over cursor") (fun () ->
        with_db kind @@ fun db ->
        setup db 10;
        let r = Host.run ~db ~program "small X" in
        Testkit.strings "X in 3..5" [ "3"; "4"; "5" ]
          (List.map (fun s -> List.assoc "X" s) r.solutions));
    Testkit.case (name ^ ": enumeration is lazy") (fun () ->
        with_db kind @@ fun db ->
        setup db 1000;
        let r = Host.run ~db ~max:1 ~program:"" {|sql_rows "SELECT x FROM t" [] R|} in
        Testkit.int "one solution" 1 (List.length r.solutions);
        Testkit.int "one row fetched" 1 r.rows_fetched);
    Testkit.case (name ^ ": full enumeration") (fun () ->
        with_db kind @@ fun db ->
        setup db 1000;
        let r = Host.run ~db ~program:"" {|sql_rows "SELECT x FROM t" [] R|} in
        Testkit.int "all rows" 1000 (List.length r.solutions));
    Testkit.case (name ^ ": parameters and text") (fun () ->
        with_db kind @@ fun db ->
        setup db 10;
        let r =
          Host.run ~db ~program:""
            {|sql_rows "SELECT name FROM t WHERE x = ?" [sql_int 7] [sql_text N]|}
        in
        Testkit.strings "name" [ "n7" ]
          (List.map (fun s -> List.assoc "N" s) r.solutions));
  ]

let () =
  let kinds = List.filter Backend.available [ Backend.Turso; Backend.Sqlite ] in
  if not (List.mem Backend.Turso kinds) then
    prerr_endline "warning: Turso backend not available (build vendor/turso)";
  Testkit.run "m0" (List.map (fun k -> (Backend.name k, tests k)) kinds)
