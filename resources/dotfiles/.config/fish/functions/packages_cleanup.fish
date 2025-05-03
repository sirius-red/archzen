function packages_cleanup -a aurhelper
    argparse n/noconfirm -- $argv
    or return

    set -f clean_cmd_args -Scc
    set -f orphans_cmd_args -Rnsu
    set -f aur_orphans_cmd_args --clean

    if set -qf _flag_noconfirm
        set -fa clean_cmd_args --noconfirm
        set -fa orphans_cmd_args --noconfirm
        set -fa aur_orphans_cmd_args --noconfirm
    end

    set -fa orphans_cmd_args (pacman -Qtdq)

    # Cleaning cache...
    sudo pacman $clean_cmd_args
    __packages_cleanup_aurhelper_run $aurhelper $clean_cmd_args

    # Uninstalling orphans...
    sudo pacman $orphans_cmd_args
    __packages_cleanup_aurhelper_run $aurhelper $aur_orphans_cmd_args
end

function __packages_cleanup_aurhelper_run
    test -n "$argv[1]"
    and not string match -q -- '[->]*' $argv[1]
    or return

    if command -q $argv[1]
        $argv
    end
end
