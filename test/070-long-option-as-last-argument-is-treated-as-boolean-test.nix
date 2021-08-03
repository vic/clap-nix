{ opts, ... }:

{
  name = "long option as last argument is treated as boolean";
  argv = [ "-a" "--foo" ];
  slac = {
    short.a = opts.int;
    long.foo = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [ { short.a = true; } { long.foo = true; } ];
  };
}
