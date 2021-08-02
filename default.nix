{ lib, ... }:

{
  clap = import ./lib { inherit lib; };
}
