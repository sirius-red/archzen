set PLUGINS_DIR "/$HOME/.config/fish/conf.d/plugins"

if test -d $PLUGINS_DIR
    for plugin in (/usr/bin/ls "$PLUGINS_DIR"/*.fish 2>/dev/null | sort)
        source "$plugin"
    end
end
