{ opts, lib, pkgs, ... }:

{
  name = "a long option followed by a short option is considered a true flag";
  argv = [ "--foo" "-b" 42 ];
  lsc = {
    long.foo = opts.int;
    short.b = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [ { long.foo = true; } { short.b = 42; } ];
  };
}
