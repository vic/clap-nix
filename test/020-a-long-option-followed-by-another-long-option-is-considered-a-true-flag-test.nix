{ opts, lib, pkgs, ... }:

{
  name =
    "a long option followed by another long option is considered a true flag";
  argv = [ "--foo" "--bar" 42 ];
  lsc = {
    long.foo = opts.int;
    long.bar = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [ { long.foo = true; } { long.bar = 42; } ];
  };
}
