function nix
    set -l red (set_color red)
    set -l green (set_color green)
    set -l reset (set_color normal)

    set -l argc (count $argv)
    if test $argc -eq 0
        _nix_fish_echo (printf "%serror: %sno subcommand specified\n" $red $reset)
        _nix_fish_echo (printf "%srunning:%s `nix --help`\n" $green $reset)
        command nix --help
    end
end
