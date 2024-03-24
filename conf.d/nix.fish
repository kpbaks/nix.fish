function __nix::on::install --on-event nix_install
    # Set universal variables, create bindings, and other initialization logic.
end

function __nix::on::update --on-event nix_update
    # Migrate resources, print warnings, and other update logic.
end

function __nix::on::uninstall --on-event nix_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
end

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

abbr -a nh nix-hash --type sha256 --base32

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

abbr -a nsh --set-cursor 'nix shell nixpkgs#%'

if command --query home-manager
    abbr -a hm home-manager
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
end
abbr -a nosrs -f abbr_nixos_rebuild_switch

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
