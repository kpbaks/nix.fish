function toml2nix -d "convert a TOML structure to its equivalent nix representation"
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

        printf "%sconvert a TOML structure to its equivalent nix representation%s\n" (set_color --bold) $reset
        printf "\n"
        printf "%sUSAGE%s\n" $yellow $reset
        printf "\t<%stoml%s> | %stoml2nix%s     [options]\n" $cyan $reset (set_color $fish_color_command) $reset
        printf "\t%stoml2nix%s < <%stomlfile%s> [options]\n" (set_color $fish_color_command) $reset $cyan $reset
        printf "\t%stoml2nix%s <%stomlfile%s>   [options]\n" (set_color $fish_color_command) $reset $cyan $reset
        printf "\n"
        printf "%sOPTIONS%s\n" $yellow $reset
        printf "\t%s-h%s, %s--help%s show this help message\n" $green $reset $green $reset
        printf "\t%s-f%s, %s--force%s ignore that the input file does not have a .toml extension\n" $green $reset $green $reset
        printf "\n"
        printf "%sEXAMPLES%s\n" $yellow $reset
        # printf "\t%s%s\n" (printf (echo 'echo "[1, 2, 3]" | toml2nix # => [ 1 2 3 ]' | fish_indent --ansi)) $reset
        # printf "\t%s%s\n" (printf (echo 'echo \'{"a": 1, "b": 2, "c": 3}\' | toml2nix # => { a = 1; b = 2; c = 3; }' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'toml2nix < file.toml' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'toml2nix file.toml' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'toml2nix --force file.txt' | fish_indent --ansi)) $reset

        # TODO: insert footer

        return 0
    end >&2

    if isatty stdin
        if test (count $argv) -eq 0
            printf "%serror%s: no input provided\n\n" (set_color red) (set_color normal)
            eval (status function) --help
            return 2
        end

        set -l tomlfile $argv[1]
        if not test -f $tomlfile
            printf "%serror%s: file '%s' does not exist\n\n" (set_color red) (set_color normal) $tomlfile
            eval (status function) --help
            return 2
        end

        if test (path extension $tomlfile) != .toml; and not set --query _flag_force
            printf "%serror%s: file '%s' does not have a .toml extension\n\n" (set_color red) (set_color normal) $tomlfile
            eval (status function) --help
            return 2
        end

        eval (status function) <$tomlfile
        return
    end

    # Create a temporary file to store the json structure
    set -f tomlfile (command mktemp --suffix=.toml)
    # Construct nix expression
    echo "builtins.fromTOML ''" >$tomlfile
    while read line
        echo $line >>$tomlfile
    end
    echo "''" >>$tomlfile

    if isatty stdout
        # stdout is a tty, so the output is not piped to another command
        # so we can format the output, and print it nicely :)
        set -l expr "command nix eval --file $tomlfile"
        if command --query alejandra
            set -a expr " | command alejandra --quiet"
        end

        if command --query bat
            set -a expr " | command bat --language=nix --paging=never --plain"
        end

        # echo $expr | fish_indent --ansi
        eval $expr
    else
        command nix eval --file $tomlfile
    end

    command rm $tomlfile
end
