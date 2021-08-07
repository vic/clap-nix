{ opts, lib, ... }:

{
  name = "short option taking boolean ignores next arg";
  argv = [ "-a" "foo" 42 ];
  slac = { short.a = opts.bool; };
  expected = {
    rest = [ "foo" 42 ];
    seen = [{ short.a = true; }];
  };
}
