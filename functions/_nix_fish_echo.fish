function _nix_fish_echo
    set -l nix_color (set_color "#7e7eff") # taken from nix's color in gitbus programming language bar
    set -l normal (set_color normal)
    set -l prefix (printf "%s[nix.fish]%s" $nix_color $normal)
    echo "$prefix $argv"
end
