function nix-store
    if not status is-interactive
        or not isatty stdout
        or test (count $argv) -eq 0
        or not contains -- --query $argv
        command nix-store $argv

    else
        command nix-store $argv | nix-store-highlight
    end
end
