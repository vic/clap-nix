# clap.nix - Command Line Argument Processing in Nix.
#
# This function provides a way to read GNU style command line options
# into an nix attribute set.
#
# The `clap` function takes two arguments:
#
#   - `lsc`      A tree of `{ long; short; commands }` where
#                `long` and `short` are attribute sets of nix options
#                (ie, those created with lib.types.mkOption)
#
#                And `commands` is an attribute set of subcommands,
#                each of them specifying their own long, short and commands.
#
#   - `argv`     A list of strings representing the command line to parse.
#
#
# The result of the `clap` function is an attribute set having:
#
#  {
#    rest       An list of command line arguments not handled by clap.
#    optsAcc    A list of attribute sets one for each option, eg
#               having a `hello` long option and a subcommand `baz` with an iner `foo` long option:
#               and called with argv: `--hello world baz --foo bar`
#
#               [
#                  { long  = { hello = "world";  }; }
#                  { command = { baz =  { long = { foo = "bar"; };  }; }; }
#               ]
#
#    optsSet    A single attribute set equivalent to merging all of optsAcc.
#
#    optsMod    Evaluates a module with lsc as options and optsAcc as config modules.
#
#               The purpose of `optsAcc` being an array of attributes is that you can later use
#               with `lib.evalModules` if you need any option to be accumulative (as per its lib.type.mkOption merge function).
#               otherwise if you dont' need config resolution, you can just reduce them into a single
#               attribute like: `lib.foldLeft lib.recursiveUpdate {} acc`.
#
#  }
#
#
# See default.nix for higher level functions.
#
# Long options have a double dash before them.
#
#    `--foo bar` is a long option `foo` taking the `bar` value
#
# Hoewever if a long option is followed by another long option, it's inferred to
# be a boolean flag. eg.
#
#    `--foo --bar baz` the `bar` option takes the `baz` value and `foo` takes `true`.
#
# Also, if a long option is prefixed with `--no-` is inferred to be a boolean option:
#
#    `--no-surprises foo` the `surprises` option takes `false` even if followed by the `foo` value.
#
# Short options have a single dash before them.
#
# `-abc foo` is interpreted as `-a -b -c foo`, because of this, `a`, `b` are considered
# boolean `true` values and `c` takes the value `foo`.

{ lib }:
let
  accOpt = lib.fix (accOpt:
    lsc@{ long ? { }, short ? { }, command ? { } }:
    rest: acc: argv:
    let

      len = lib.length argv;
      isEmpty = len < 1;
      hasSnd = len > 1;
      fst = lib.elemAt argv 0;
      snd = lib.elemAt argv 1;

      hasPrefix = p: s: builtins.isString s && lib.hasPrefix p s;

      isDash = hasPrefix "-";

      getLong = prefix: s:
        let
          str = lib.removePrefix prefix s;
          path = lib.splitString "." str;
          opt = lib.attrByPath [ str ] (lib.attrByPath path null long) long;
        in if !hasPrefix prefix s then
          null
        else if opt == null then
          null
        else {
          inherit str opt;
          path = [ "long" ] ++ path;
        };

      fstLong = getLong "--" fst;
      fstLongNo = getLong "--no-" fst;

      getShort = s:
        let
          str = builtins.substring 1 1 s;
          rem = builtins.substring 2 (builtins.stringLength s) s;
          opt = lib.attrByPath [ str ] null short;
        in if !hasPrefix "-" s || hasPrefix "--" s then
          null
        else if opt == null then
          null
        else {
          inherit str opt;
          rem = if builtins.stringLength rem == 0 then [ ] else [ "-${rem}" ];
          path = [ "short" str ];
        };

      fstShort = getShort fst;

      accAt = at: val: acc ++ [ (lib.setAttrByPath at.path val) ];

    in if isEmpty then {
      inherit rest acc;
    }

    else if fst == "--" then {
      inherit acc;
      rest = rest ++ argv;
    }

    else if lib.isString fst && lib.hasAttr fst command then
      let sub = accOpt (lib.getAttr fst command) [ ] [ ] (lib.tail argv);
      in {
        rest = rest ++ sub.rest;
        acc = acc ++ map (lib.setAttrByPath [ "command" fst ]) sub.acc;
      }

    else if !isDash fst then
      accOpt lsc (rest ++ [ fst ]) acc (lib.tail argv)

    else if fstLongNo != null then
      accOpt lsc rest (accAt fstLongNo false) (lib.tail argv)

    else if fstLong != null && isDash snd then
      accOpt lsc rest (accAt fstLong true) (lib.tail argv)

    else if fstLong != null then
      accOpt lsc rest (accAt fstLong snd) (lib.drop 2 argv)

    else if fstShort != null
    && (isDash snd || builtins.length fstShort.rem > 0) then
      accOpt lsc rest (accAt fstShort true) (fstShort.rem ++ lib.tail argv)

    else if fstShort != null then
      accOpt lsc rest (accAt fstShort snd) (fstShort.rem ++ lib.drop 2 argv)

    else
      accOpt lsc (rest ++ [ fst ]) acc (lib.tail argv));

  clap = lsc: argv:
    let
      result = accOpt lsc [ ] [ ] argv;
      optsAcc = result.acc;
      optsSet = lib.foldl lib.recursiveUpdate { } optsAcc;
      optsMod =
        (lib.evalModules { modules = [{ options = lsc; }] ++ optsAcc; }).config;
    in {
      inherit (result) rest;
      inherit optsAcc optsSet optsMod;
    };

in clap
