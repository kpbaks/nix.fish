function yaml2nix -d "convert a YAML structure to its equivalent nix representation"
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

        printf "%sconvert a YAML structure to its equivalent nix representation%s\n" (set_color --bold) $reset
        printf "\n"
        printf "%sUSAGE%s\n" $yellow $reset
        printf "\t<%syaml%s> | %syaml2nix%s     [options]\n" $cyan $reset (set_color $fish_color_command) $reset
        printf "\t%syaml2nix%s < <%syamlfile%s> [options]\n" (set_color $fish_color_command) $reset $cyan $reset
        printf "\t%syaml2nix%s <%syamlfile%s>   [options]\n" (set_color $fish_color_command) $reset $cyan $reset
        printf "\n"
        printf "%sOPTIONS%s\n" $yellow $reset
        printf "\t%s-h%s, %s--help%s show this help message\n" $green $reset $green $reset
        printf "\t%s-f%s, %s--force%s ignore that the input file does not have a .yaml extension\n" $green $reset $green $reset
        printf "\n"
        printf "%sEXAMPLES%s\n" $yellow $reset
        printf "\t%s%s\n" (printf (echo 'echo "[1, 2, 3]" | yaml2nix # => [ 1 2 3 ]' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'echo \'{"a": 1, "b": 2, "c": 3}\' | yaml2nix # => { a = 1; b = 2; c = 3; }' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'yaml2nix < file.yaml' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'yaml2nix file.yaml' | fish_indent --ansi)) $reset
        printf "\t%s%s\n" (printf (echo 'yaml2nix --force file.txt' | fish_indent --ansi)) $reset

        # TODO: insert footer

        return 0
    end >&2

    if isatty stdin
        if test (count $argv) -eq 0
            printf "%serror%s: no input provided\n\n" (set_color red) (set_color normal)
            eval (status function) --help
            return 2
        end

        set -l yamlfile $argv[1]
        if not test -f $yamlfile
            printf "%serror%s: file '%s' does not exist\n\n" (set_color red) (set_color normal) $yamlfile
            eval (status function) --help
            return 2
        end

        if not contains -- (path extension $yamlfile) .yml .yaml; and not set --query _flag_force
            printf "%serror%s: file '%s' does not have a .yml or .yaml extension\n\n" (set_color red) (set_color normal) $tomlfile
            eval (status function) --help
            return 2
        end

        eval (status function) <$yamlfile
        return
    end

    if not command --query yq
        est -l reset (set_color normal)
        printf "%serror%s: %syq%s (https://mikefarah.gitbook.io/yq/) is not installed\n" (set_color red) $reset (set_color $fish_color_command) $reset
        printf "It is needed for this function to work\n"
        printf "Please install version 4.x\n"
        return 1
    end

    # Create a temporary file to store the json structure
    set -f jsonfile (command mktemp --suffix=.json)

    # Construct nix expression
    echo "builtins.fromJSON ''" >$jsonfile
    # NOTE: expect yq version to be ^4.0.0
    # yaml is read from stdin
    command yq --output-format=json \
        | while read line
        echo $line >>$jsonfile
    end
    echo "''" >>$jsonfile

    set -l expr "command nix eval --file $jsonfile"

    if isatty stdout
        # stdout is a tty, so the output is not piped to another command
        # so we can format the output, and print it nicely :)
        if command --query alejandra
            set -a expr " | command alejandra --quiet"
        end

        if command --query bat
            set -a expr " | command bat --language=nix --paging=never --plain"
        end
    end
    # echo $expr | fish_indent --ansi
    eval $expr

    command rm $jsonfile
end
