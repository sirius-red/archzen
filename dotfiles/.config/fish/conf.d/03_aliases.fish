# Replace ls with eza
alias ls='eza --color=always --group-directories-first --icons'                       # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'                    # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'                    # long format
alias lla='eza -la --color=always --group-directories-first --icons'                  # all files in long format
alias lt='eza -aT --color=always --group-directories-first --icons'                   # tree listing
alias l.="eza -a | grep -e '^\.'"                                                     # show only dotfiles

# Common use
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='grep --color=auto -F'
alias egrep='grep --color=auto -E'
alias hw='hwinfo --short'         # Hardware Info
alias jctl="journalctl -p 3 -xb"  # Get the error messages from journalctl
alias take="sudo chown $(whoami):$(whoami)"
alias take-r="sudo chown -hRH $(whoami):$(whoami)"
alias docker="sudo docker"
alias osinfo="fastfetch"
alias rd="rm -rf"

# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Package Management
alias mirror="sudo cachyos-rate-mirrors"                                       # Get fastest mirrors
alias big="expac -H M '%m\t%n' | sort -h | nl"                                 # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'                             # List amount of -git packages
alias update='sudo pacman -Syu'                                                # Update system
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'                                # Cleanup orphaned packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"  # List recent installed packages

# Git
alias lgd='list-git-dir'

# Neovim
alias vim='nvim'
alias lazyinstall='nvim --headless +"Lazy install" +q'
alias lazysync='nvim --headless +"Lazy sync" +q'
