# Set HyDE env variables if exists
if test -f ~/.config/fish/hyde_config.fish
    source ~/.config/fish/hyde_config.fish
end

# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
    source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

if command -q nvim
    set -x EDITOR nvim
end

if command -q paru
    set -x AUR_HELPER paru
else if command -q yay
    set -x AUR_HELPER yay
end
