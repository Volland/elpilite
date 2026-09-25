(* Locating and loading storage backend libraries.
   @lat: [[storage#Store Signature#Turso Backend]] *)

type kind = Turso | Sqlite

let name = function Turso -> "turso" | Sqlite -> "sqlite"

let ext = if Sys.os_type = "Unix" && Sys.file_exists "/System/Library" then "dylib" else "so"

(* Candidate library paths, in priority order. Environment variables win so
   CI and packaged builds can point anywhere. *)
let candidates = function
  | Turso ->
      (match Sys.getenv_opt "ELPILITE_TURSO_LIB" with Some p -> [ p ] | None -> [])
      @ [
          "vendor/turso/target/release/libturso_sqlite3." ^ ext;
          "../vendor/turso/target/release/libturso_sqlite3." ^ ext;
          "../../vendor/turso/target/release/libturso_sqlite3." ^ ext;
          "../../../vendor/turso/target/release/libturso_sqlite3." ^ ext;
        ]
  | Sqlite ->
      (match Sys.getenv_opt "ELPILITE_SQLITE_LIB" with Some p -> [ p ] | None -> [])
      @ [
          "/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib";
          "/usr/local/opt/sqlite/lib/libsqlite3.dylib";
          "/usr/lib/x86_64-linux-gnu/libsqlite3.so.0";
          "/usr/lib/aarch64-linux-gnu/libsqlite3.so.0";
          "/usr/lib/libsqlite3.so.0";
          "/usr/lib/libsqlite3.dylib";
        ]

exception Backend_unavailable of kind * string

let loaded : (kind * Sqldl.lib) list ref = ref []

(* Loads (once per process) the library for [kind]. Fails if no candidate
   exists or if required symbols are missing. *)
let lib kind =
  match List.assoc_opt kind !loaded with
  | Some l -> l
  | None -> (
      match List.find_opt Sys.file_exists (candidates kind) with
      | None ->
          raise
            (Backend_unavailable
               (kind, "library not found; tried " ^ String.concat ", " (candidates kind)))
      | Some path ->
          let l, missing = Sqldl.load path in
          if missing <> [] then
            raise
              (Backend_unavailable
                 (kind, "missing symbols: " ^ String.concat ", " missing));
          loaded := (kind, l) :: !loaded;
          l)

let available kind = match lib kind with _ -> true | exception Backend_unavailable _ -> false

let open_ ?readonly kind path = Sqldl.open_ ?readonly (lib kind) path
