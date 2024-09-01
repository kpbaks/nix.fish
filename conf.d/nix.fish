# function __nix::on::install --on-event nix_install
#     # Set universal variables, create bindings, and other initialization logic.
# end

# function __nix::on::update --on-event nix_update
#     # Migrate resources, print warnings, and other update logic.
# end

# function __nix::on::uninstall --on-event nix_uninstall
#     # Erase "private" functions, variables, bindings, and other uninstall logic.
# end

function __nix::abbr::list
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

abbr -a nr nix run
abbr -a nrp nix repl

function abbr_nix_search
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

abbr -a ns -f abbr_nix_search --set-cursor

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

    echo "nix shell nixpkgs#$package%"
end

# abbr -a nsh --set-cursor 'nix shell nixpkgs#%'
abbr -a nsh --set-cursor --function __abbr_nix_shell
# NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#warp-terminal
abbr -a nshi --set-cursor 'NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#%'

if command --query home-manager
    # --extra-experimental-features "nix-command flakes"
    function __abbr_home_manager
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
    abbr -a hm -f __abbr_home_manager
    set -l hm_switch_args --cores "(math (nproc) - 1)" --print-build-logs
    abbr -a hms home-manager switch $hm_switch_args
    abbr -a hmsf home-manager switch $hm_switch_args --flake .
end

# nixos
function abbr_nixos_rebuild_switch
    if test (command id --user) -ne 0
        # Not root user, so prefix with sudo
        printf "sudo "
    end
    printf "nixos-rebuild switch\n"
    # TODO: expand to this if the current dir has a flake.nix and configuration.nix
    # nixos-rebuild switch --use-remote-sudo --flake .
end
# TODO: change abbr
abbr -a nosrs -f abbr_nixos_rebuild_switch


abbr -a nsq nix-store --query
abbr -a nsq nix-store --query

# used by `./completions/*.fish`
function __nix::complete_extensions
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

function __nix::hooks::update-flake --on-variable PWD
    test -f flake.lock; or return 0

    set -l mtime (path mtime flake.lock)
    set -l now (command date '+%s')
    set -l duration (math "$now - $mtime")
    test $duration -ge 604800; or return 0 # 60 * 60 * 24 * 7

    set -l reset (set_color normal)
    set -l blue (set_color blue)
    printf '%s[nix.fish]%s %s%s%s/flake.lock has not been modified in over a week!\n' $blue $reset (set_color green) $PWD $reset
    printf '%s[nix.fish]%s run %s%s to update the lock file\n' $blue $reset (printf (echo "nix flake update" | fish_indent --ansi)) $reset
end
