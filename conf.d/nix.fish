function __nix.fish::on::install --on-event nix_install
    # Set universal variables, create bindings, and other initialization logic.
end

function __nix.fish::on::update --on-event nix_update
    # Migrate resources, print warnings, and other update logic.
end

function __nix.fish::on::uninstall --on-event nix_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
end

function __nix.fish::abbr::list
    string match --entire --regex "^\s*abbr -a" <(status filename) | fish_indent --ansi
end

abbr -a n nix
abbr -a nd nix develop --command fish
abbr -a nf nix flake
abbr -a nfc nix flake check
abbr -a nfi nix flake init
abbr -a nfmd nix flake metadata

abbr -a np nix profile
abbr -a npl nix profile list
abbr -a npi --set-cursor "nix profile install nixpkgs#%"
abbr -a npu nix profile update "'.'"

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

abbr -a nsh nix shell

if command --query home-manager
    abbr -a hm home-manager
    abbr -a hms home-manager switch
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
