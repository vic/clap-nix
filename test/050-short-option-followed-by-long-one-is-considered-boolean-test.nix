{ opts, lib, ... }:

{
  name = "short option followed by long one is considered boolean";
  argv = [ "-a" "--foo" 42 ];
  slac = {
    short.a = opts.int;
    long.foo = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [ { short.a = true; } { long.foo = 42; } ];
  };
}
