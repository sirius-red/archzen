set PLUGINS_DIR "$HOME/.config/fish/plugins"

if test -d $PLUGINS_DIR
    for plugin in (/usr/bin/ls "$PLUGINS_DIR"/*.fish 2>/dev/null | sort)
        source "$plugin"
    end
end
