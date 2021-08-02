{ lib, ... }:
# Some predefined mkOption types for tests.
{
  int = lib.mkOption { type = lib.types.int; };
  zero = lib.mkOption {
    type = lib.types.int;
    default = 0;
  };
}
