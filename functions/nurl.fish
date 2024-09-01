function nurl
    if status is-interactive; and isatty stdout; and command -q bat; and test (count $argv) -eq 0
        set -l clipboard (fish_clipboard_paste)

        if string match --regex --quiet '^https://git(hub|lab).com/.+' -- $clipboard
            set -l tmpf (command mktemp)
            command nurl $clipboard 2>$tmpf | fish_clipboard_copy
            set -l reset (set_color normal)
            set -l dim (set_color --dim)

            printf '%sRun this command:%s\n' $dim $reset
            string sub --start=2 <$tmpf | fish_indent --ansi
            echo
            printf "%sOr paste this into your {flake,configuration}.nix%s\n" $dim $reset
            fish_clipboard_paste | command bat --plain --language=nix
            echo
            printf "%sIt has been copied to your clipboard ;)%s\n" $dim $reset
            command rm $tmpf
        end
    else
        command nurl $argv
    end
end
