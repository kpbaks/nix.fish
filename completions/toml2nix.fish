set -l c complete -c toml2nix

$c -f # Disable file completion

$c -s h -l help
$c -s f -l force

$c -a "(__nix::complete_extensions toml)"
