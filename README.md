# nix.fish

## Installation
```fish
fisher install kpbaks/nix.fish
```

## Abbreviations

<!-- use `__nix.fish::abbr::list` to list all abbreviations -->

```fish
abbr -a n nix
abbr -a nd nix develop --command fish
abbr -a nf nix flake
abbr -a nfc nix flake check
abbr -a nfi nix flake init
abbr -a nfmd nix flake metadata
abbr -a np nix profile
abbr -a npl nix profile list
abbr -a npi --set-cursor "nix profile install nixpkgs#%"
abbr -a npu nix profile update "'.'"
abbr -a nr nix run
abbr -a nrp nix repl
abbr -a ns -f abbr_nix_search --set-cursor
abbr -a nsh nix shell
abbr -a hm home-manager
abbr -a hms home-manager switch
abbr -a nosrs -f abbr_nixos_rebuild_switch
```
