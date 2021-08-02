{ opts, lib, pkgs, ... }:

{
  name = "last short option in combo takes the argument value";
  argv = [ "-abc" 42 ];
  lsc = {
    short.a = opts.int;
    short.b = opts.int;
    short.c = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [ { short.a = true; } { short.b = true; } { short.c = 42; } ];
  };
}
