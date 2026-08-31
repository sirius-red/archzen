# @fish-lsp-disable 2002

# Replace ls with eza
alias ls='eza --color=always --group-directories-first --icons=always' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons=always' # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons=always' # long format
alias lla='eza -la --color=always --group-directories-first --icons=always' # all files in long format
alias lt='eza -aT --color=always --group-directories-first --icons=always' # tree listing
alias l.="eza -a | grep -e '^\.'" # show only dotfiles

# Dir navigation shortcuts
abbr .. 'cd ..'
abbr .2 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Common use
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias tarnow='tar -acf'
alias untar='tar -zxvf'
alias wget='wget -c'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='grep --color=auto -F'
alias egrep='grep --color=auto -E'
alias hw='hwinfo --short' # Hardware Info
alias jctl="journalctl -p 3 -xb" # Get the error messages from journalctl
alias take="chown $(whoami):$(whoami)"
alias take-r="chown -hRH $(whoami):$(whoami)"
alias os="fastfetch"
alias rd="rm -rf"
alias mkdir='mkdir -p' # Always mkdir a path (this doesn't inhibit functionality to make a single dir)

# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Package Management
alias pkgi='pacman -S --noconfirm --needed' # Install a package
alias pkgu='pacman -Syu' # Update the system
alias pkgr='pacman -Rnsu --noconfirm' # Remove a package
alias pkgc="packages_cleanup $AUR_HELPER" # Cleanup pacman
alias pkgs='pacman -Ss' # Search from a package in repositories
alias pkgq='pacman -Q | grep' # Search in installed packages
alias pkgl='pacman -Q' # List all installed packages
alias pkgif='pacman -Sii' # Show info from a package
alias pkglg='pacman-list-groups' # List all groups
alias big="expac -H M '%m\t%n' | sort -h | nl" # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl" # List recent installed packages
alias fixpacman="rm /var/lib/pacman/db.lck"

# Git
alias gld='git_listdir'

# Vim
alias svim='vim'
alias snvim='nvim'
alias visudo='visudo'
alias vienv='vim /etc/environment'
alias lazyinstall='nvim --headless +"Lazy install" +q'
alias lazysync='nvim --headless +"Lazy sync" +q'

# Apps and services
alias pieces='pieces-os && pieces-for-developers'
alias snap-start='systemctl start snapd.apparmor.service && systemctl start snapd.socket'
alias snap-stop='systemctl stop snapd.apparmor.service && systemctl stop snapd.socket'

# pacboy aliases
if type -q pacboy
    alias pb='pacboy'
    alias pbf='pb find'
    alias pbs='pb sync'
end
