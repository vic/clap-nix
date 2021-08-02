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

  longAt = fst: lsc: getLong "--" fst (lsc.long or { });
  longNoAt = fst: lsc: getLong "--no-" fst (lsc.long or { });
  shortAt = fst: lsc: getShort fst (lsc.short or { });
  commandAt = fst: lsc:
    if lib.isString fst then
      lib.attrByPath [ "command" fst ] null lsc
    else
      null;

  isDefinedAt = fst: lsc:
    let
      noLong = (longAt fst lsc) == null;
      noLongNo = (longNoAt fst lsc) == null;
      noShort = (shortAt fst lsc) == null;
      noCommand = (commandAt fst lsc) == null;
    in !(noLong && noLongNo && noShort && noCommand);

  isEnabled = lsc: (lsc.enabled or lsc.enabled.default or false) == true;

  findDefinedAtEnabled = acc: fst: lsc:
    if isDefinedAt fst lsc then
      acc
    else
      lib.concatMap (cmd:
        if !isEnabled lsc.command.${cmd} then
          [ ]
        else
          findDefinedAtEnabled (acc ++ [ "command" cmd ]) fst
          lsc.command.${cmd}) (lib.attrNames (lsc.command or { }));

  accOpt = lsc: rest: acc: argv:
    let

      len = lib.length argv;
      isEmpty = len < 1;
      hasSnd = len > 1;
      fst = lib.elemAt argv 0;
      snd = lib.elemAt argv 1;

      fstLong = longAt fst lsc;
      fstLongNo = longNoAt fst lsc;
      fstShort = shortAt fst lsc;
      fstCommand = commandAt fst lsc;

      isFstNotHere = !isDefinedAt fst lsc;
      fstDefinedPath = findDefinedAtEnabled [ ] fst lsc;

      accAt = at: val: acc ++ [ (lib.setAttrByPath at.path val) ];

    in if isEmpty then {
      inherit rest acc;
    }

    else if fst == "--" then {
      inherit acc;
      rest = rest ++ argv;
    }

    else if fstCommand != null then
      let sub = accOpt fstCommand [ ] [ ] (lib.tail argv);
      in {
        rest = rest ++ sub.rest;
        acc = acc ++ [ (lib.setAttrByPath [ "command" fst "enabled" ] true) ]
          ++ map (lib.setAttrByPath [ "command" fst ]) sub.acc;
      }

    else if isFstNotHere && lib.length fstDefinedPath > 0 then
      let
        cmd = lib.attrByPath fstDefinedPath { } lsc;
        sub = accOpt cmd [ ] [ ] argv;
        enabledPath = fstDefinedPath ++ [ "enabled" ];
      in {
        rest = rest ++ sub.rest;
        acc = acc ++ [ (lib.setAttrByPath enabledPath true) ]
          ++ map (lib.setAttrByPath fstDefinedPath) sub.acc;
      }

    else if !lib.isString fst || !isDash fst then
      accOpt lsc (rest ++ [ fst ]) acc (lib.tail argv)

    else if fstLongNo != null then
      accOpt lsc rest (accAt fstLongNo false) (lib.tail argv)

    else if fstLong != null && (lib.length argv == 1 || isDash snd) then
      accOpt lsc rest (accAt fstLong true) (lib.tail argv)

    else if fstLong != null then
      accOpt lsc rest (accAt fstLong snd) (lib.drop 2 argv)

    else if fstShort != null && (lib.length argv == 1 || isDash snd
      || builtins.length fstShort.rem > 0) then
      accOpt lsc rest (accAt fstShort true) (fstShort.rem ++ lib.tail argv)

    else if fstShort != null then
      accOpt lsc rest (accAt fstShort snd) (fstShort.rem ++ lib.drop 2 argv)

    else
      accOpt lsc (rest ++ [ fst ]) acc (lib.tail argv);

  lscOptions = config: cmdPath: lsc:
    let
      isCmdEnabled = lib.length cmdPath == 0
        || lib.attrByPath (cmdPath ++ [ "enabled" ]) false config;

      subOpt = at: fn:
        if lib.hasAttr at lsc then {
          ${at} = lib.mkOption {
            description = lib.concatStringsSep " " (cmdPath ++ [ at ]);
            default = { };
            type = lib.types.submodule (args:
              if isCmdEnabled then {
                options = lib.mapAttrs fn lsc.${at};
              } else
                { });
          };
        } else
          { };

      longOpt = subOpt "long" ensureOption;
      shortOpt = subOpt "short" ensureOption;
      commandOpt = subOpt "command" (n: v:
        {
          enabled = ensureOption n v.enabled or (lib.mkEnableOption n);
        } // lscOptions config (cmdPath ++ [ "command" n ]) v);

    in longOpt // shortOpt // commandOpt;

  clap = lsc: argv:
    let
      result = accOpt lsc [ ] [ ] argv;
      optsAcc = result.acc;
      optsSet = lib.foldl lib.recursiveUpdate { } optsAcc;
      optsMod = let
        optionsModule = ({ config, ... }: {
          _file = "command line options definition";
          options = lscOptions config [ ] lsc;
        });
        prettyArgv = lib.generators.toPretty { multiline = false; } argv;
        valuesModules =
          (map (v: v // { _file = "command line arguments: ${prettyArgv}"; })
            optsAcc);
      in { imports = [ optionsModule ] ++ valuesModules; };
      opts = (lib.evalModules { modules = [ optsMod ]; }).config;
    in {
      inherit (result) rest;
      inherit optsAcc optsSet optsMod opts;
    };

in clap
