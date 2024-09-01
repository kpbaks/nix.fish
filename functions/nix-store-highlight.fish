function nix-store-highlight -d "read from stdin, and highlight every substring looking like a /nix/store/ path"
    # set -l nixos_logo_light_blue (set_color '#7EB3DB')
    # set -l nixos_logo_dark_blue (set_color '#5274B9')
    # set -l github_nix_lang_color (set_color '#5274B9')
    set -l nixos_logo_light_blue '#7EB3DB'
    set -l nixos_logo_dark_blue '#5274B9'
    set -l github_nix_lang_color '#8180F9'
    set -l reset (set_color normal)

    # if isatty stdin; or not isatty stdout
    if isatty stdin
        printf '%serror%s: stdin must be a pipe, not a tty, and stdout must be a tty\n' (set_color red) $reset >&2
        return 2
    end
    # /nix/store/p45c31p2qhwjy4vf60v2d2mw9bvvpb67-git-2.45.2/
    # FIXME: also handle paths to `home-manager-path` and `system-path`
    # /nix/store/xs8dic4gm6hd3bjg5w7qnbk77a8kix9z-home-manager-path
    # /nix/store/yvd95hfvd36mfw990v9696245brv8ih5-home-manager-path
    # /nix/store/yzj2ib08rdf38lzbdb8p0256sfdl7igs-home-manager-path
    # /nix/store/z1jvk8133r3crd71cj9l8b8ci3kvwj4x-system-path
    # /nix/store/zq8cq1r5xda9gj87cgg5kwlry3019d9d-home-manager-path
    # set -l regexp_system_path '/nix/store/(\\w{32})-([a-zA-Z0-9+-]+)-system-path/?'
    # set -l system_path_replacement 

    # set -l regexp '/nix/store/(\\w{32})-(^[/]+)/?'
    # command cat | string match --regex --groups-only $regexp | while read hash drv
    #     switch $drv
    #         case home-manager-path
    #         case system-path
    #         case '*'
    #     end
    # end

    set -l regexp '/nix/store/(\\w{32})-([a-zA-Z0-9+-]+)-([0-9][a-zA-Z0-9.+-]*)/?'
    set -l replacement "$(set_color $github_nix_lang_color)/nix/store/$reset$(set_color --dim)\$1$reset-$(set_color $nixos_logo_light_blue)\$2$reset-$(set_color $nixos_logo_dark_blue)\$3$reset/"

    command cat | string replace --regex $regexp $replacement

    # while read line # read stdin
    #     if string match --regex --groups-only "$regexp" | read hash drv version_
    #         echo $hash
    #         echo $drv
    #         echo $version_
    #     else
    #         echo $line
    #     end
    # end
end
