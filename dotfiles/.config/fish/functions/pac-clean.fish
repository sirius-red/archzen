function pac-clean
    echo "Cleaning pacman cache..."
    sudo pacman -Scc --noconfirm 1>/dev/null
    echo "Cleaning pacman cache... Done"

    echo "Uninstalling orphans..."
    sudo pacman -Rnsu $(pacman -Qtdq) --noconfirm 1>/dev/null
    paru --clean --noconfirm 1>/dev/null
    echo "Uninstalling orphans... Done"
end
