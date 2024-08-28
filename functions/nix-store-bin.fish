function nix-store-bin -a bin

    set -l bins
    if isatty stdin
        set bins $argv
    else
        while read line
            set -a bins $line
        end
    end

    for bin in $bins
        command -q $bin; or return 2
    end

    set -l store_paths
    for bin in $bins
        # NOTE: the `string split` command is to remove the /bin/<program> postfix of the path
        # e.g.
        # input:
        # /nix/store/p45c31p2qhwjy4vf60v2d2mw9bvvpb67-git-2.45.2/bin/git
        # output:
        # /nix/store/p45c31p2qhwjy4vf60v2d2mw9bvvpb67-git-2.45.2
        # bin
        # git
        command --search $bin | path resolve | string split / --no-empty --max=2 --right | read -l store_path

        # len('/nix/store/') == 11
        if test (string sub --start=1 --length=11 -- $store_path) != /nix/store/
            # Binary, but not in /nix/store
            # TODO: report error
            return 1
        end
        set -a store_paths $store_path
    end

    if isatty stdout
        printf '%s\n' $store_paths | nix-store-highlight
    else
        printf '%s\n' $store_paths
    end
end
