set -l c complete -c nix2toml

$c -f # Disable file completion

$c -s h -l help
$c -s f -l force

$c -a "(__nix.fish::complete-extensions nix)"
