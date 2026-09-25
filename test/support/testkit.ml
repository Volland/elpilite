(* Minimal test runner: named cases, equality checks, non-zero exit on failure.
   Used instead of alcotest, whose build chain (topkg/ocamlbuild) crashes on
   macOS 26 with OCaml 5.x. *)

exception Check_failed of string

let check ~pp name expected actual =
  if expected <> actual then
    raise
      (Check_failed
         (Format.asprintf "%s: expected %a, got %a" name pp expected pp actual))

let int name e a = check ~pp:Format.pp_print_int name e a
let bool name e a = check ~pp:Format.pp_print_bool name e a
let string name e a = check ~pp:(fun f -> Format.fprintf f "%S") name e a

let strings name e a =
  check
    ~pp:(fun f l -> Format.fprintf f "[%s]" (String.concat "; " (List.map (Printf.sprintf "%S") l)))
    name e a

let fail msg = raise (Check_failed msg)

type case = string * (unit -> unit)

let case name f : case = (name, f)

let run suite (groups : (string * case list) list) =
  let failures = ref 0 and total = ref 0 in
  List.iter
    (fun (group, cases) ->
      List.iter
        (fun (name, f) ->
          incr total;
          match f () with
          | () -> Printf.printf "  ok   %s / %s\n%!" group name
          | exception e ->
              incr failures;
              let msg = match e with Check_failed m -> m | e -> Printexc.to_string e in
              Printf.printf "  FAIL %s / %s: %s\n%!" group name msg)
        cases)
    groups;
  Printf.printf "%s: %d/%d passed\n%!" suite (!total - !failures) !total;
  if !failures > 0 then exit 1
