function clearnvim --argument nvim_appname
    rm -rf ~/.config/$nvim_appname
    rm -rf ~/.local/share/$nvim_appname
    rm -rf ~/.local/state/$nvim_appname
    rm -rf ~/.cache/$nvim_appname
end
