{ lib, ... }:
# Some predefined mkOption types for tests.
rec {
  # A type that only validates if given the exact same value as x
  typs = { val = x: lib.types.addCheck lib.types.anything (y: y == x); };

  opts = {
    bool = lib.mkOption { type = lib.types.bool; };

    int = lib.mkOption { type = lib.types.int; };
    zero = lib.mkOption {
      type = lib.types.int;
      default = 0;
    };

    val = x: lib.mkOption { type = typs.val x; };

    defaultTrue = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    defaultFalse = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    str = lib.mkOption { type = lib.types.str; };
  };

}
