# Replace ls with eza
alias ls='eza --color=always --group-directories-first --icons'      # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'   # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'   # long format
alias lla='eza -la --color=always --group-directories-first --icons' # all files in long format
alias lt='eza -aT --color=always --group-directories-first --icons'  # tree listing
alias l.="eza -a | grep -e '^\.'"                                    # show only dotfiles

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
alias hw='hwinfo --short'        # Hardware Info
alias jctl="journalctl -p 3 -xb" # Get the error messages from journalctl
alias take="sudo chown $(whoami):$(whoami)"
alias take-r="sudo chown -hRH $(whoami):$(whoami)"
alias os="fastfetch"
alias rd="rm -rf"
alias mkdir='mkdir -p' # Always mkdir a path (this doesn't inhibit functionality to make a single dir)

# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Package Management
alias pkgi='sudo pacman -S --noconfirm --needed'                              # Install a package
alias pkgu='sudo pacman -Syu'                                                 # Update the system
alias pkgr='sudo pacman -Rnsu --noconfirm'                                    # Remove a package
alias pkgc="packages_cleanup $AUR_HELPER"                                     # Cleanup pacman
alias pkgs='pacman -Ss'                                                       # Search from a package in repositories
alias pkgq='pacman -Q | grep'                                                 # Search in installed packages
alias pkgl='pacman -Q'                                                        # List all installed packages
alias pkgif='pacman -Sii'                                                     # Show info from a package
alias mirror="sudo cachyos-rate-mirrors"                                      # Get fastest mirrors
alias big="expac -H M '%m\t%n' | sort -h | nl"                                # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'                            # List amount of -git packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl" # List recent installed packages
alias fixpacman="sudo rm /var/lib/pacman/db.lck"

# Git
alias gld='git_listdir'

# Vim
alias svim='sudo vim'
alias snvim='sudo nvim'
alias visudo='sudo visudo'
alias vienv='sudo vim /etc/environment'
alias lazyinstall='nvim --headless +"Lazy install" +q'
alias lazysync='nvim --headless +"Lazy sync" +q'
