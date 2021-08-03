{ lib, ... }: {
  name = "parse empty argv with empty slac";
  argv = [ ];
  slac = { };
  expected = {
    seen = [ ];
    rest = [ ];
  };
}
