{ ... }:

{
  name = "non options are collected in rest";
  argv = [ "hello" 42 true ];
  slac = { };
  expected = {
    rest = [ "hello" 42 true ];
    seen = [ ];
  };
}
