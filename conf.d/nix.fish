status is-interactive; or return

function _nix_abbr_list
    string match --entire --regex "^\s*abbr -a" <(status filename) | fish_indent --ansi
end

abbr -a n nix
abbr -a nb nix build
abbr -a nd nix develop --command fish
abbr -a ne nix eval
abbr -a nef nix eval --file
abbr -a nej nix eval --json
abbr -a nejf nix eval --json --file

abbr -a nf nix flake
abbr -a nfu nix flake update
abbr -a nfc nix flake check
abbr -a nfi nix flake init
abbr -a nfmd nix flake metadata

command -q nh
or abbr -a nh nix-hash --type sha256 --base32

abbr -a np nix profile
abbr -a npl nix profile list
abbr -a npi --set-cursor "nix profile install nixpkgs#%"
abbr -a npl nix profile list
abbr -a npr nix profile remove
abbr -a npu nix profile upgrade "'.'"
abbr -a nps --set-cursor 'nix profile list | string match "*%*"'

function _abbr_nix_run
    set -l args
    if test -f flake.lock
        set -a args --reference-lock-file flake.lock
    end

    echo "nix run $args"
end
abbr -a nr nix run

abbr -a nrp nix repl

function _abbr_nix_search
    printf "nix search --json nixpkgs %%"
    if command --query fx
        printf " | fx"
    else if command --query jq
        printf " | jq '.' --color-output"
        if command --query less
            printf " | less -R --tilde --quit-if-one-screen"
        end
    end
    printf "\n"
end

abbr -a ns -f _abbr_nix_search --set-cursor

function __abbr_nix_shell
    # if command -q ,
    #     # Look for the last invocation of `,`, if any
    #     # If there is one then suggest that one
    #     set -n lookback_n 10
    #     for i in (seq $lookback_n)
    #         set -l job $history[$i]
    #         for cmd in (string split '|' -- $job)
    #             set -l program (string split ' ' -f 1 -- $cmd)
    #             if test $program = ,

    #             end
    #         end
    #     end
    # end

    set -l output nix shell
    # set -l output nix shell --impure
    # NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#gitbutler
    # if not set -q NIXPKGS_ALLOW_UNFREE
    #     set -p output NIXPKGS_ALLOW_UNFREE=1
    # else if test $NIXPKGS_ALLOW_UNFREE -eq 0
    #     set -p output NIXPKGS_ALLOW_UNFREE=1
    # end

    set -a output "nixpkgs#$package%"

    echo $output
end

# abbr -a nsh --set-cursor 'nix shell nixpkgs#%'
abbr -a nsh --set-cursor --function __abbr_nix_shell
# NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#warp-terminal
# gitbutler
function _abbr_nix_shell
    set -l prefix
    switch $argv[1]
        case nsh
        case nshi
            printf 'NIXPKGS_ALLOW_UNFREE=1'
    end
    # 'NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#%'

    # TODO: check if experimental-features = nix-command flakes is set
    echo "nix shell"
end

abbr -a nix_shell --regex "nshi?" --function _abbr_nix_shell
# abbr -a nshi --set-cursor 'NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#%'

if command --query home-manager
    # --extra-experimental-features "nix-command flakes"
    function _abbr_home_manager
        set -l postfix
        if test -r /etc/nix/nix.conf
            set -l experimental_features

            string match --regex --groups-only 'experimental-features = (.+)' </etc/nix/nix.conf \
                | string split ' ' \
                | while read --line feature
                set -a experimental_features $feature
            end

            contains -- nix-command $experimental_features
            and contains -- flakes $experimental_features
            or set -a postfix --extra-experimental-features '"nix-command flakes"'
        end

        echo "home-manager $postfix"
    end
    # abbr -a hm home-manager
    abbr -a hm -f _abbr_home_manager
    set -l hm_switch_args --cores "(math (nproc) - 1)" --print-build-logs
    abbr -a hms home-manager switch $hm_switch_args
    abbr -a hmsf home-manager switch $hm_switch_args --flake .
end

# nixos
function _abbr_nixos_rebuild_switch
    if test (command id --user) -ne 0
        # Not root user, so prefix with sudo
        printf "sudo "
    end
    printf "nixos-rebuild switch\n"
    # TODO: expand to this if the current dir has a flake.nix and configuration.nix
    # nixos-rebuild switch --use-remote-sudo --flake .
end
# TODO: change abbr
abbr -a nosrs -f _abbr_nixos_rebuild_switch

abbr -a nsq nix-store --query
abbr -a nsq nix-store --query

# https://github.com/viperML/nh
if command --query nh
    # TODO: detect if $NH_FLAKE has been set
    abbr -a nhos "nh os switch"
    abbr -a nhhs "nh home switch"
    abbr -a nhous "nh os switch --update"
    abbr -a nhhus "nh home switch --update"
end

# used by `./completions/*.fish`
function _nix_complete_extensions
    if test $PWD = $HOME
        set -f files * .*
        for f in $files
            # test -f $f; or continue
            for ext in $argv
                if test (path extension $f) = .$ext
                    echo $f
                    break
                end
            end
        end
    else if command --query fd
        set -l extensions (printf " -e %s" $argv)
        eval command fd --hidden $extensions
    else if command --query find
        set -l filters (printf " -name '*%s'" $argv)
        set -l filters (string replace --regex --all '(.+)' -- '-name "*.$1"' $argv | string join " -o ")

        eval command find . -type f \( $filters \)
    else
        set -f files ** .*
        for f in $files
            # test -f $f; or continue
            for ext in $argv
                if test (path extension $f) = .$ext
                    echo $f
                    break
                end
            end
        end
    end
end

function _nix_hooks_remind_update_flake --on-variable PWD
    test -f flake.lock; or return 0
    command -q jq; or return 0

    # Use the mtime of the flake.lock file coarsely estimate the last time
    # an input was updated.
    set -l mtime (path mtime flake.lock)
    set -l now (command date '+%s')
    set -l time_since_flake_lock_modification (math "$now - $mtime")
    set -l 1week 604800 # 60 * 60 * 24 * 7
    set -l should_be_updated_after $1week
    test $time_since_flake_lock_modification -ge $should_be_updated_after; or return 0

    set -l nc (set_color normal)
    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l bold (set_color --bold)
    set -l datetime_strftime "%a, %b, %Y-%m-%d %H:%M:%S"
    set -l datetime_color (set_color --dim --italics)
    # TODO: print the exact time since last update
    printf '%s[nix.fish]%s %s%s%s/flake.lock%s has not been modified in over a week! %s%s%s\n' $blue $nc $bold (set_color $fish_color_valid_path) $PWD $nc $datetime_color (command date -d "@$(math $now - $time_since_flake_lock_modification)" +$datetime_strftime) $nc
    # printf '%s[nix.fish]%s run %s%s to update all inputs in the lock file\n' $blue $nc (printf (echo "nix flake update" | fish_indent --ansi)) $nc
    printf '           Run %s%s%s to update all inputs in the lock file.\n' $bold (printf (echo "nix flake update" | fish_indent --ansi)) $nc

    # TODO: make an estimate whether you are the owner of the repo, or if it is a fork

    # TODO: print a guage to show the relative difference since each input has been updated
    # jq 'nodes | map(.locked.lastModified)' <flake.lock
    # TODO: print each input as a hyperlink to its remote
    set -l inputs (command jq --raw-output '.nodes.root.inputs | keys | join("\n")' <flake.lock)
    test (count $inputs) -gt 0; or return 0

    printf "           The following inputs should be updated:\n"

    set -l inputs_that_should_be_updated
    set -l time
    for input in $inputs
        # NOTE: wrap $input in "" to handle input names with "-" in them e.g. "flake-utils"
        set -l last_modified (command jq ".nodes.\"$input\".locked.lastModified" <flake.lock)
        set -l time_since_modification (math "$now - $last_modified")
        test $time_since_modification -ge $should_be_updated_after; or continue
        set -a inputs_that_should_be_updated $input
        set -a time $time_since_modification
    end

    set -l max_width (math "max($(string length $inputs_that_should_be_updated | string join ',')) + 1")
    for i in (seq (count $inputs_that_should_be_updated))
        # TODO: format as flake url
        set -l input $inputs_that_should_be_updated[$i]
        set -l time_since_modification $time[$i]
        printf "           - %s%-*s%s %s%s%s\n" $bold $max_width "$input:" $nc $datetime_color (command date -d "@$(math $now - $time_since_modification)" +$datetime_strftime) $nc
    end
end

# TODO: override `type` to inspect output, and apply `nix-store-highlight` to it.
