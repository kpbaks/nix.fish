function flake-inputs -d "Parse ./flake.nix and list the names of all inputs"
    if not test -r flake.nix
        printf '%serror%s: %s/flake.nix does not exist.\n' (set_color red) (set_color normal) $PWD
        return 2
    end

    # nix flake metadata --json | command jaq --raw-output '.locks.nodes.root.inputs[]'

    # TODO: grab '.locked.lastModified' for each, and convert to relative duration, that gets 
    # more and more red the longer back it has been since it has been updated

    set -l jq_program_file (command mktemp --suffix .jq)
    echo '
def url:
  if .type == "github"
  then "https://github.com/\(.owner)/\(.repo)"
  else .url
  end
; 

# input `nix flake metadata --json`

.locks.nodes
| .root.inputs as $inputs
| to_entries
| .[]
| select(.key | in($inputs))
| [.key, (.value.original | url), .locked.lastModified]
| @csv
    ' >$jq_program_file

    set -l reset (set_color normal)
    set -l blue (set_color blue)
    set -l dim (set_color --dim)


    set -l inputs
    set -l urls
    set -l last_modified_unix_timestamps

    nix flake metadata --json \
        | command jq --raw-output --from-file $jq_program_file \
        | string replace --all '"' '' \
        | while read --delimiter , input url last_modified
        set -a inputs $input
        set -a urls $url
        set -a last_modified_unix_timestamps $last_modified
    end
    # defer pls
    command rm $jq_program_file

    if not isatty stdout
        for i in (seq (count $inputs))
            echo "$inputs[$i] $urls[$i]"
        end
    else
        if set -q KITTY_PID
            for i in (seq (count $inputs))
                # TODO: have this be the hyperlink
                if string match --regex --groups-only '^https://github.com/([^/]+)/([^/]+)' $urls[$i] | read --line owner repo
                end
                printf "\e]8;;"
                printf '%s' $urls[$i]
                printf '\e\\'
                printf '%s%s%s' $blue $inputs[$i] $reset
                printf '\e]8;;\e\\'
                printf '\n'
            end
        else
            for i in (seq (count $inputs))
                printf '%s%s%s %s->%s %s%s%s\n' $blue $inputs[$i] $reset $dim $reset (set_color blue --underline) $urls[$i] $reset
            end
        end
        echo
        printf '%s HINT %s\n' (set_color --background '#000000' '#8180F9') $reset
        printf '%sto update a single input%s\n' $dim $reset
        printf '\t'
        echo 'nix flake lock --update-input $input' | fish_indent --ansi
        printf '%sand to update all inputs%s\n' $dim $reset
        printf '\t'
        echo 'nix flake update' | fish_indent --ansi


        # TODO: add a hint to show this command
        # nix flake show github:pjones/plasma-manager
        # github:pjones/plasma-manager
    end
end
