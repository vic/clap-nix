{ lib, ... }: {
  name = "parse empty argv with empty lsc";
  argv = [ ];
  lsc = { };
  expected = {
    seen = [ ];
    rest = [ ];
  };
}
