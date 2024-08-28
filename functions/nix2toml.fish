function nix2toml
    # TODO: use tomllib from python3.11
    # smh, apparently tomllib does not support writing toml
    # https://github.com/sclevine/yj

    set -l options h/help f/force
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    if set --query _flag_help
        set -l reset (set_color normal)
        set -l green (set_color green)
        set -l yellow (set_color yellow)
        set -l cyan (set_color cyan)

        printf "%sevaluate a nix expression and convert it to its json representation%s\n" (set_color --bold) $reset
        printf "\n"
        printf "%sUSAGE%s\n" $yellow $reset
        printf "\t<%snix%s> | %snix2json%s     [options]\n" $cyan $reset (set_color $fish_color_command) $reset
        printf "\t%snix2json%s < <%snixfile%s> [options]\n" (set_color $fish_color_command) $reset $cyan $reset
        printf "\t%snix2json%s <%snixfile%s>   [options]\n" (set_color $fish_color_command) $reset $cyan $reset
        printf "\n"
        printf "%sOPTIONS%s\n" $yellow $reset
        printf "\t%s-h%s, %s--help%s show this help message\n" $green $reset $green $reset
        printf "\t%s-f%s, %s--force%s ignore that the input file does not have a .nix extension\n" $green $reset $green $reset
        printf "\n"
        printf "%sEXAMPLES%s\n" $yellow $reset
        printf "\t%s%s\n" (printf (echo 'echo "[1 2 3]" | nix2json # => [1, 2, 3]' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'echo \'{a = 1; b = true; c = [1 2 3];}\' | nix2json # => { "a": 1, "b": true, "c": [1,2,3] }' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'nix2json < file.nix' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'nix2json file.nix' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'nix2json --force file.txt' | fish_indent --ansi)) $reset

        # TODO: insert footer

        return 0
    end

    if isatty stdin
        if test (count $argv) -eq 0
            printf "%serror%s: no input provided\n\n" (set_color red) (set_color normal)
            eval (status function) --help
            return 2
        end

        set -l nixfile $argv[1]
        if not test -f $nixfile
            printf "%serror%s: file '%s' does not exist\n\n" (set_color red) (set_color normal) $nixfile
            eval (status function) --help
            return 2
        end

        if test (path extension $nixfile) != .nix; and not set --query _flag_force
            printf "%serror%s: file '%s' does not have a .nix extension\n\n" (set_color red) (set_color normal) $nixfile
            eval (status function) --help
            return 2
        end

        eval (status function) <$nixfile
        return
    end

    # Create a temporary file to store the json structure
    set -f nixfile (command mktemp --suffix=.nix)
    while read line
        echo $line >>$nixfile
    end

    # TODO: maybe expose `--arg` to the caller
    # FIXME: not all structures can be converted to with `yq` yet, when outputting toml
    set -l expr "command nix eval --json --file $nixfile | command yq --input-format=json --output-format=toml"

    if isatty stdout
        if command --query bat
            set -a expr " | command bat --language=toml --paging=never --plain"
        end
    end

    # echo $expr | fish_indent --ansi
    eval $expr

    command rm $nixfile
end
