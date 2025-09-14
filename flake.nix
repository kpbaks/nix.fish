{
  description = "Some abbreviations and functions to make it easier to work with the `nix` package manager, and the `NixOS` ecosystem.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter = pkgs.nixfmt-rfc-style;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          fish
          mdformat
          nurl
        ];
      };

      homeModules.default =
        { config, pkgs, ... }:
        {
          home.packages = [ pkgs.nurl ];
          programs.bat.enable = true;
          programs.fish.plugins = [
            {
              name = "nix.fish";
              # TODO: filter list to only be *.fish files
              src = ./.;
            }
          ];
        };
    };
}
