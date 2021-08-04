{ lib, pkgs, clap, ... }:
{ name, slac, expected, argv ? [ ], fn ? (cli: argv: cli argv), skip ? null
, at ? (_: _.optsAcc), ... }:
let
  sname = lib.strings.sanitizeDerivationName name;
  cli = clap slac;
  actual = lib.pipe argv [
    (fn cli)
    (result: {
      rest = result.rest or [ ];
      seen = at result;
    })
  ];
  same = actual == expected;
  msg = label: msg:
    pkgs.stdenvNoCC.mkDerivation {
      name = sname;
      phases = [ label ];
      ${label} = ''
        echo "${msg}"
        touch $out
      '';
    };
in if lib.isString skip then
  msg "skip" skip
else if same then
  msg "ok" name
else
  pkgs.stdenvNoCC.mkDerivation {
    name = sname;
    phases = [ "fail" ];
    passAsFile = [ "prettyArgv" "prettyActual" "prettyExpected" ];
    prettyArgv = lib.generators.toPretty { multiline = false; } argv;
    prettyActual = lib.generators.toPretty { } actual;
    prettyExpected = lib.generators.toPretty { } expected;
    fail = ''
      echo -n "with argv: "
      cat $prettyArgvPath
      echo
      echo -e "diff -y EXPECTED ACTUAL"
      ${pkgs.diffutils}/bin/diff -u100 $prettyExpectedPath $prettyActualPath | ${pkgs.gitAndTools.delta}/bin/delta --no-gitconfig --side-by-side --keep-plus-minus-markers
      false
    '';
  }
