{
  description = "Some abbreviations and functions to make it easier to work with the `nix` package manager, and the `NixOS` ecosystem.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            fish
            mdformat
            nurl
          ];
        };
      }
    )
    // {
      homeModules.default =
        { config, pkgs, ... }:
        {

          home.packages = with pkgs; [
            nurl
            # TODO: ponder or ask someone if this is the "right" way of ensuring `bat` is in $PATH
            config.programs.bat.package
          ];
          programs.fish.plugins = {
            name = "nix.fish";
            # TODO: filter list to only be *.fish files
            src = ./.;
          };
        };
    };
}
