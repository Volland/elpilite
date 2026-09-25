let () =
  Testkit.run "skeleton"
    [ ("version", [ Testkit.case "non-empty" (fun () ->
          Testkit.bool "version set" true (Elpilite.version <> "")) ]) ]
