function flake-init -d "initialize a new nix flake project, with flake.nix and .envrc"
    set -l options h/help
    if not argparse $options -- $argv
        printf '\n'
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        set -l section_header_color (set_color yellow)

        printf '%sinitialize a new nix flake project, with flake.nix and .envrc%s\n' $bold $reset
        printf '\n'
        printf '%sUSAGE:%s %s%s%s [OPTIONS]\n' $section_header_color $reset (set_color $fish_color_command) (status function) $reset
        printf '\n'
        printf '%sOPTIONS:%s\n' $section_header_color $reset
        printf '\t%s-h%s, %s--help%s Show this help message and return\n' $option_color $reset $option_color $reset
        return 0
    end >&2


    if test -f flake.nix
        printf '%swarn%s: flake.nix file already exists in %s/\n' $yellow $reset $PWD
        return 1
    end

    set -l system x86_64-linux
    if command --query uname
        printf '%sinfo%s: found `uname` command, attempt to detect system\n' $green $reset
        set -l machine (command uname --machine)
        set -l os (command uname --operating-system)
        switch $os
            case GNU/Linux
                set os linux
            case Darwin
                set os darwin
        end
        set system $machine-$os
        printf '%sinfo%s: detected system as %s\n' $green $reset $system
    else
        printf '%swarn%s: `uname` command not found, defaulting to %s\n' $yellow $reset $system
    end

    set -l description (path basename (pwd))

    set -l native_build_inputs
    set -l build_inputs
    if test -f Cargo.toml
        set -l rust_native_build_inputs pkg-config
        set -l rust_build_inputs rustc cargo taplo bacon clippy mold sccache
        printf '%sinfo%s: detected Cargo.toml, adding rust dependencies\n' $green $reset
        for input in $rust_native_build_inputs
            if not contains -- $input $native_build_inputs
                set -a native_build_inputs $input
            end
        end
        for input in $rust_build_inputs
            if not contains -- $input $build_inputs
                set -a build_inputs $input
            end
        end
        set -l cargo_plugins expand nextest info outdated show-asm modules rr watch
        for plugin in $cargo_plugins
            if not contains  -- cargo-$plugin $build_inputs
                set -a build_inputs cargo-$plugin
            end
        end
    end

    if test -f CMakeLists.txt
        set -l cmake_native_build_inputs pkg-config
        set -l cmake_build_inputs cmake cmake-language-server ninja gcc clang mold sccache
        printf '%sinfo%s: detected CMakeLists.txt, adding C/C++ and cmake dependencies\n' $green $reset
        for input in $cmake_native_build_inputs
            if not contains -- $input $native_build_inputs
                set -a native_build_inputs $input
            end
        end
        for input in $cmake_build_inputs
            if not contains -- $input $build_inputs
                set -a build_inputs $input
            end
        end
    end

    if test -f meson.build
        set -l meson_native_build_inputs pkg-config
        set -l meson_build_inputs meson ninja gcc clang mold
        printf '%sinfo%s: detected meson.build, adding C/C++ and meson dependencies\n' $green $reset
        for input in $meson_native_build_inputs
            if not contains -- $input $native_build_inputs
                set -a native_build_inputs $input
            end
        end
        for input in $meson_build_inputs
            if not contains -- $input $build_inputs
                set -a build_inputs $input
            end
        end
    end

    echo "{
    description = \"$description\";
    inputs = {
        nixpkgs.url = \"github:NixOS/nixpkgs/nixos-unstable\";
        # flake-utils.url = \"github:numtide/flake-utils\";
    };

    outputs = { self, nixpkgs, ... }:
        let system = \"$system\";
        pkgs = import nixpkgs { inherit system; };
    in {
        formatter.\${system} = pkgs.alejandra;
        devShells.\${system}.default = pkgs.mkShell rec {
            nativeBuildInputs = with pkgs; [$native_build_inputs];
            buildInputs = with pkgs; [
                $(string split '\n' $build_inputs)
            ];

            # LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
        };
    };
}
    " >>flake.nix

    set -l cat cat
    if command --query bat
        set cat bat --plain
    end

    printf '%sinfo%s: generated the following ./flake.nix file:\n' $green $reset
    eval "command $cat flake.nix"

    set -l generated_files flake.nix

    if command --query direnv
        if not test -f .envrc
            echo "use flake" >.envrc
            set -a generated_files .envrc
            printf '%sinfo%s: generated the following .envrc file:\n' $green $reset
            eval "command $cat .envrc"
            # command cat .envrc
        else
            printf '%swarn%s: a .envrc file already exists\n' $yellow $reset
            set -l envrc_already_contains_use_flake 0
            while read line
                if string match -q 'use flake' $line
                    set envrc_already_contains_use_flake 1
                    break
                end
            end <.envrc

            if not test $envrc_already_contains_use_flake -eq 1
                echo "use flake" >>.envrc
                printf '%sinfo%s: added `use flake` to the ./.envrc file\n' $green $reset
            else
                printf '%sinfo%s: the .envrc file already contains `use flake`\n' $green $reset
            end
        end
    else
        printf '%swarn%s: direnv is not installed\n' $yellow $reset
        printf '%sinfo%s: to use direnv, install direnv and run `direnv allow`\n' $green $reset
    end

    if command git rev-parse --is-inside-work-tree 2>/dev/null >&2
        printf '%info%s: detected you are in a git repository\n' $green $reset
        command git add $generated_files
        printf '%sinfo%s: added %s to the git index, `nix` require this to work\n' $green $reset (string join ', ' $generated_files)
        if test -f .gitignore
            set -l already_ignored 0
            while read line
                if string match -q '.direnv/' $line
                    set already_ignored 1
                    break
                end
            end < .gitignore

            if not test $already_ignored -eq 1
                echo '.direnv/' >>.gitignore
                printf '%sinfo%s: added `.direnv/` to the ./.gitignore file\n' $green $reset
            else
                printf '%sinfo%s: the .gitignore file already contains `.direnv/`\n' $green $reset
            end
        else
            echo '.direnv/' >.gitignore
            printf '%sinfo%s: generated the following ./.gitignore file:\n' $green $reset
            eval "command $cat .gitignore"
        end
    end

    return 0
end
