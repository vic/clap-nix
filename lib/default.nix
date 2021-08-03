{ lib }:
let
  ensureOption = n: v:
    let typeOfV = builtins.typeOf v;
    in if lib.isOption v then
      v
    else if lib.hasAttr typeOfV lib.types then
      lib.mkOption {
        description = n;
        type = lib.types.${typeOfV};
        default = v;
      }
    else
      throw
      "Expected ${n} to be an option declared with `lib.mkOption` but was a ${typeOfV}";

  hasPrefix = p: s: builtins.isString s && lib.hasPrefix p s;

  isDash = hasPrefix "-";

  getLong = prefix: s: long:
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

  getShort = s: short:
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

  getArg = s: argv: seen:
    let
      argvLen = lib.length argv;
      seenLen = lib.length (lib.filter (lib.hasAttr "argv") seen);
    in if argvLen == 0 || seenLen >= argvLen then
      null
    else if !(builtins.elemAt argv seenLen).check s then
      null
    else {
      path = [ "argv" ];
    };

  longAt = fst: slac: getLong "--" fst (slac.long or { });
  longNoAt = fst: slac: getLong "--no-" fst (slac.long or { });
  shortAt = fst: slac: getShort fst (slac.short or { });
  argAt = fst: slac: seen: getArg fst (slac.argv or [ ]) seen;
  commandAt = fst: slac:
    if lib.isString fst then
      lib.attrByPath [ "command" fst ] null slac
    else
      null;

  fstAt = fst: slac: seen: rec {
    long = longAt fst slac;
    longNo = longNoAt fst slac;
    short = shortAt fst slac;
    command = commandAt fst slac;
    arg = argAt fst slac seen;
    isDefined =
      lib.length (lib.filter (_: _ != null) [ long longNo short command arg ])
      > 0;
  };

  isEnabled = slac: (slac.enabled or slac.enabled.default or false) == true;

  findDefinedAtEnabled = acc: fst: slac: seen:
    if (fstAt fst slac seen).isDefined then
      acc
    else
      lib.concatMap (cmd:
        if !isEnabled slac.command.${cmd} then
          [ ]
        else
          findDefinedAtEnabled (acc ++ [ "command" cmd ]) fst
          slac.command.${cmd} seen) (lib.attrNames (slac.command or { }));

  argvAcc = acc:
    let
      parted = lib.partition (lib.hasAttr "argv") acc;
      values = map (_: _.argv) parted.right;
      argv = if lib.length values > 0 then [{ argv = values; }] else [ ];
    in argv ++ parted.wrong;

  accOpt = slac: rest: acc: argv:
    let

      len = lib.length argv;
      isEmpty = len < 1;
      hasSnd = len > 1;
      fst = lib.elemAt argv 0;
      snd = lib.elemAt argv 1;

      fstHere = fstAt fst slac acc;
      fstEnabledPath = findDefinedAtEnabled [ ] fst slac [ ];

      accAt = at: val: acc ++ [ (lib.setAttrByPath at.path val) ];

    in if isEmpty then {
      inherit rest;
      acc = argvAcc acc;
    }

    else if fst == "--" then {
      acc = argvAcc acc;
      rest = rest ++ argv;
    }

    else if fstHere.command != null then
      let sub = accOpt fstHere.command [ ] [ ] (lib.tail argv);
      in {
        rest = rest ++ sub.rest;
        acc = (argvAcc acc)
          ++ [ (lib.setAttrByPath [ "command" fst "enabled" ] true) ]
          ++ map (lib.setAttrByPath [ "command" fst ]) sub.acc;
      }

    else if !fstHere.isDefined && lib.length fstEnabledPath > 0 then
      let
        cmd = lib.attrByPath fstEnabledPath { } slac;
        sub = accOpt cmd [ ] [ ] argv;
        enabledPath = fstEnabledPath ++ [ "enabled" ];
      in {
        rest = rest ++ sub.rest;
        acc = (argvAcc acc) ++ [ (lib.setAttrByPath enabledPath true) ]
          ++ map (lib.setAttrByPath fstEnabledPath) sub.acc;
      }

    else if fstHere.arg != null then
      accOpt slac rest (accAt fstHere.arg fst) (lib.tail argv)

    else if !lib.isString fst || !isDash fst then
      accOpt slac (rest ++ [ fst ]) acc (lib.tail argv)

    else if fstHere.longNo != null then
      accOpt slac rest (accAt fstHere.longNo false) (lib.tail argv)

    else if fstHere.long != null && (lib.length argv == 1 || isDash snd) then
      accOpt slac rest (accAt fstHere.long true) (lib.tail argv)

    else if fstHere.long != null then
      accOpt slac rest (accAt fstHere.long snd) (lib.drop 2 argv)

    else if fstHere.short != null && (lib.length argv == 1 || isDash snd
      || builtins.length fstHere.short.rem > 0) then
      accOpt slac rest (accAt fstHere.short true)
      (fstHere.short.rem ++ lib.tail argv)

    else if fstHere.short != null then
      accOpt slac rest (accAt fstHere.short snd)
      (fstHere.short.rem ++ lib.drop 2 argv)

    else
      accOpt slac (rest ++ [ fst ]) acc (lib.tail argv);

  slacOptions = config: cmdPath: slac:
    let
      isCmdEnabled = lib.length cmdPath == 0
        || lib.attrByPath (cmdPath ++ [ "enabled" ]) false config;

      subOpt = at: fn:
        lib.optionalAttrs (lib.hasAttr at slac) {
          ${at} = lib.mkOption {
            description = lib.concatStringsSep " " (cmdPath ++ [ at ]);
            default = { };
            type = lib.types.submodule (args:
              lib.optionalAttrs isCmdEnabled {
                options = lib.mapAttrs fn slac.${at};
              });
          };
        };

      longOpt = subOpt "long" ensureOption;
      shortOpt = subOpt "short" ensureOption;
      commandOpt = subOpt "command" (n: v:
        {
          enabled = ensureOption n v.enabled or (lib.mkEnableOption n);
        } // slacOptions config (cmdPath ++ [ "command" n ]) v);

      argvOpt = lib.optionalAttrs (slac ? argv) {
        argv = lib.mkOption {
          description = lib.concatStringsSep " " (cmdPath ++ [ "argv" ]);
          default = [ ];
          type = lib.types.listOf (lib.types.oneOf slac.argv);
        };
      };

    in longOpt // shortOpt // commandOpt // argvOpt;

  clap = slac: argv:
    let
      result = accOpt slac [ ] [ ] argv;
      optsAcc = result.acc;
      optsSet = lib.foldl lib.recursiveUpdate { } optsAcc;
      optsMod = let
        declarations = ({ config, ... }: {
          _file = "command line options definition";
          options = slacOptions config [ ] slac;
        });
        prettyArgv = lib.generators.toPretty { multiline = false; } argv;
        definitions =
          (map (v: v // { _file = "command line arguments: ${prettyArgv}"; })
            optsAcc);
      in { imports = [ declarations ] ++ definitions; };
      opts = (lib.evalModules { modules = [ optsMod ]; }).config;
    in {
      inherit (result) rest;
      inherit optsAcc optsSet optsMod opts;
    };

in clap
