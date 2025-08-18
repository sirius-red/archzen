#!/usr/bin/env bash

KB_LAYOUT="us"                     # Use `grep -i 'English' /usr/share/X11/xkb/rules/base.lst` to list possible values
KB_VARIANT="intl,altgr-intl"       # Use `grep -i 'English' /usr/share/X11/xkb/rules/base.lst` to list possible values
TIMESTAMP_TIMEOUT=-1               # number of minutes before the sudo password prompt times out, or -1 for no timeout
REFLECTOR_MIRROR_COUNTRIES="BR,US" # Use `reflector --list-countries` to list available countries
REFLECTOR_MIRROR_LIMIT=10          # The higher the value, the longer the reflector will take to complete its run
PACMAN_PARALLEL_DOWNLOADS=10       # Value for Pacman's "ParallelDownloads" config option
PACMAN_ENABLE_MULTILIB=true        # Enable (or not) the multilib repository
AUR_HELPER="paru-bin"              # paru[-bin] | yay[-bin]; "aurbuilder" will use this behind the scenes for some tasks. Comment this line to use "makepkg"
SETUP_ZRAM=true                    # true | false; Improve zram settings if you enabled it in Arch installation
USE_SWAPFILE=true                  # true | false; Enables a swapfile fallback, used only if zram is unavailable or insufficient and filesystem is not btrfs
KERNEL="linux-zen"                 # Any available in the official repository or AUR; Comment this line to not install
USER_SHELL="fish"                  # Any available in the official repository or AUR; Comment this line to not change the shell; Only “fish” has customizations
CPU="intel"                        # intel | amd;
GPU="nvidia"                       # nvidia | nvidia-open | nvidia-535xx | nvidia-470xx | nvidia-390xx | nouveau | amd | intel; Comment this line to not install
DESKTOP_PROFILE="hyprland"         # xorg | xorg-minimal | gnome | plasma | hyprland; Comment this line to not install
ENABLE_CACHYOS_KIT=false           # true | false; Installs the CachyOS repository and some CachyOS tools
# EDITOR="vim"                     # Any terminal editor available in the official repository or AUR; Comment this line to not install
# EXPLORER="dolphin"               # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# BROWSER="firefox"                # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# NOTE="obsidian"                  # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# TERMINAL="kitty"                 # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default

# Delay to reboot system automatically in seconds
declare -xi __FORCE_REBOOT_SYSTEM_TIME=5

declare -x \
	__VERSION="0.0.1" \
	__EXIT_CODE=0 \
	__REBOOT_SYSTEM=false \
	__MOUNT_DIR="/mnt" \
	__FORCE_REBOOT_SYSTEM=false \
	__LOG_FILE \
	__COMMAND_ARG \
	__ARCHZEN_IS_RUNNING_FROM_BINARY \
	__ROOT \
	__PWD \
	__THIS_SCRIPT \
	__QUIET \
	__ARCHINSTALL_PRESET \
	__USER_NAME \
	__USER_HOME \
	__AUR_HELPER_BIN \
	__AUR_HELPER_IS_INSTALLED \
	__ESP \
	__ROOT_FSTYPE \
	__ROOT_BTRFS_SUBVOL \
	__ROOT_PARTUUID \
	__ARCHZEN_BASE_DIR \
	__ARCHZEN_DIR \
	__ARCHZEN_SCRIPTS_DIR \
	__ARCHZEN_RESOURCES_DIR \
	__ARCHZEN_DOTFILES_DIR \
	__ARCHZEN_GNOME_MIMEAPPS_LIST_FILE \
	__ARCHZEN_GNOME_SETTINGS_FILE \
	__MAIN_SCRIPT_BASE_PATH \
	__MAIN_SCRIPT_PATH \
	__VAR_ARCHZEN_INSTALLED \
	__VAR_DOTFILES_INSTALLED \
	__VAR_INITIAL_OS_SETUP_INSTALLED \
	__BIN_DIR \
	__FORCE \
	__SYSTEM_ALREADY_UPDATED \
	__VAR_FIRST_LOGIN_RUN \
	__FIRST_LOGIN_SCRIPT \
	__VALID_CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML_INDEXES

declare -xa \
	__INFO_MESSAGES=() \
	__WARN_MESSAGES=() \
	__SERVICES_TO_ENABLE=() \
	__USER_GROUPS=() \
	__ALREADY_INSTALLED_PKGLIST \
	__NOT_INSTALLED_PKGLIST \
	__NOT_EXISTS_PKGLIST \
	__FIRST_LOGIN_SCRIPT_LINES \
	__KERNEL_PARAMETERS \
	__KERNEL_FALLBACK_PARAMETERS \
	__KERNEL_MODULES \
	__BASE_SYSTEM_PKGLIST \
	__KERNEL_PKGLIST \
	__CACHYOS_PKGLIST \
	__FILESYSTEM_PKGLIST \
	__NETWORK_PKGLIST \
	__BLUETOOTH_PKGLIST \
	__HARDWARE_PKGLIST \
	__PACKAGE_MANAGER_PKGLIST \
	__TERMINAL_PKGLIST \
	__MULTIMEDIA_PKGLIST \
	__FONTS_PKGLIST \
	__DEVELOPMENT_PKGLIST \
	__VIRTUALIZATION_PKGLIST \
	__NVIDIA_PKGLIST \
	__NVIDIA_OPEN_PKGLIST \
	__NVIDIA_535XX_PKGLIST \
	__NVIDIA_470XX_PKGLIST \
	__NVIDIA_390XX_PKGLIST \
	__NOUVEAU_PKGLIST \
	__AMD_PKGLIST \
	__INTEL_PKGLIST \
	__XORG_PKGLIST \
	__XORG_MINIMAL_PKGLIST \
	__GNOME_PKGLIST \
	__PLASMA_PKGLIST \
	__HYPRLAND_PKGLIST \
	__DE_COMMON_PKGLIST \
	__HYDE_PACKAGE_BLACKLIST \
	__HYDE_SERVICE_BLACKLIST \
	__OTHERS_PKGLIST \
	__GNOME_EXTENSIONS \
	__VSCODE_EXTENSIONS

declare -xA \
	__TYPE_ALIASES \
	__SHELL_PROFILES \
	__DEFAULT_TERMINALS \
	__DEFAULT_EXPLORERS \
	__DEFAULT_EDITORS \
	__DEFAULT_BROWSERS \
	__DEFAULT_NOTES \
	__CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML \
	__HYPR_TEMPLATE_VALUES \
	__VSCODE_TEMPLATE_VALUES

__LOG_FILE="${__ROOT}/tmp/archzen__$(date +%Y-%m-%d_%H-%M-%S).log"
__USER_NAME="${SUDO_USER:-$(whoami)}"
__USER_HOME="$(eval echo "~${__USER_NAME}")"

__SHELL_PROFILES=(
	[default]="${__USER_HOME}/.profile"
	[bash]="${__USER_HOME}/.bash_profile"
	[zsh]="${__USER_HOME}/.zprofile"
	[fish]="${__USER_HOME}/.config/fish/config.fish"
	[csh]="${__USER_HOME}/.login"
	[tcsh]="${__USER_HOME}/.login"
	[ksh]="${__USER_HOME}/.profile"
	[mksh]="${__USER_HOME}/.profile"
	[dash]="${__USER_HOME}/.profile"
	[ash]="${__USER_HOME}/.profile"
	[xonsh]="${__USER_HOME}/.xonshrc"
	[elvish]="${__USER_HOME}/.config/elvish/rc.elv"
	[nushell]="${__USER_HOME}/.config/nushell/config.nu"
	[yash]="${__USER_HOME}/.profile"
)

# [TYPE]="possible values in a space separated format"
__TYPE_ALIASES=(
	[DESKTOP_PROFILE]="xorg xorg-minimal gnome plasma hyprland"
	[BOOTLOADER]="auto sdboot refind grub lilo"
	[BOOLEAN]="true false"
	[SHELL_PROFILES]="${!__SHELL_PROFILES[*]}"
)

__DEFAULT_TERMINALS=(
	[xorg]='xterm'
	[xorg_minimal]='xterm'
	[gnome]='gnome-terminal'
	[plasma]='konsole'
	[hyprland]='kitty'
)

__DEFAULT_EXPLORERS=(
	[xorg]='dolphin'
	[xorg_minimal]='dolphin'
	[gnome]='nautilus'
	[plasma]='dolphin'
	[hyprland]='dolphin'
)

__DEFAULT_EDITORS=(
	[xorg]='vim'
	[xorg_minimal]='vim'
	[gnome]='vim'
	[plasma]='vim'
	[hyprland]='vim'
)

__DEFAULT_BROWSERS=(
	[xorg]='firefox'
	[xorg_minimal]='firefox'
	[gnome]='firefox'
	[plasma]='firefox'
	[hyprland]='firefox'
)

__DEFAULT_NOTES=(
	[xorg]='vim'
	[xorg_minimal]='vim'
	[gnome]='obsidian'
	[plasma]='obsidian'
	[hyprland]='obsidian'
)

function __set_global_variables() {
	declare root="$1"
	declare force="$2"
	declare archzen_is_running_from_binary="$3"

	__check_type_alias DESKTOP_PROFILE "$DESKTOP_PROFILE"

	if [[ -z "$TERMINAL" ]]; then
		TERMINAL="${__DEFAULT_TERMINALS[${DESKTOP_PROFILE//-/_}]}"
	fi

	if [ -z "$EXPLORER" ]; then
		EXPLORER="${__DEFAULT_EXPLORERS[${DESKTOP_PROFILE//-/_}]}"
	fi

	if [ -z "$EDITOR" ]; then
		EDITOR="${__DEFAULT_EDITORS[${DESKTOP_PROFILE//-/_}]}"
	fi

	if [ -z "$BROWSER" ]; then
		BROWSER="${__DEFAULT_BROWSERS[${DESKTOP_PROFILE//-/_}]}"
	fi

	if [ -z "$NOTE" ]; then
		NOTE="${__DEFAULT_NOTES[${DESKTOP_PROFILE//-/_}]}"
	fi

	__ROOT="$root"
	__FORCE="$force"
	__ARCHZEN_IS_RUNNING_FROM_BINARY="${archzen_is_running_from_binary}"
	__PWD="$(pwd)"
	__THIS_SCRIPT="$0"
	__PWD_RESOURCES_DIR="${__PWD}/resources"
	__QUIET=false
	__ARCHINSTALL_PRESET="./resources/archinstall-preset.json"
	__AUR_HELPER_BIN="${AUR_HELPER/-bin/}"
	__AUR_HELPER_IS_INSTALLED=false
	__ALREADY_INSTALLED_PKGLIST=()
	__NOT_INSTALLED_PKGLIST=()
	__NOT_EXISTS_PKGLIST=()
	__ESP=$(bootctl -p 2>>"$__LOG_FILE")
	__ROOT_FSTYPE=$(findmnt -no FSTYPE "$__ROOT" 2>>"$__LOG_FILE")
	__ROOT_PARTUUID=$(findmnt -no PARTUUID "$__ROOT" 2>>"$__LOG_FILE")
	__ARCHZEN_BASE_DIR="opt/sirius-red/archzen"
	__ARCHZEN_DIR="${__ROOT}/${__ARCHZEN_BASE_DIR}"
	__ARCHZEN_SCRIPTS_DIR="${__ARCHZEN_DIR}/scripts"
	__ARCHZEN_RESOURCES_DIR="${__ARCHZEN_DIR}/resources"
	__ARCHZEN_DOTFILES_DIR="${__ARCHZEN_RESOURCES_DIR}/dotfiles"
	__ARCHZEN_GNOME_MIMEAPPS_LIST_FILE="${__ARCHZEN_DOTFILES_DIR}/!.config/mimeapps.list"
	__ARCHZEN_GNOME_SETTINGS_FILE="${__ARCHZEN_RESOURCES_DIR}/gnome-settings.conf"
	__MAIN_SCRIPT_BASE_PATH="/${__ARCHZEN_BASE_DIR}/archzen.sh"
	__MAIN_SCRIPT_PATH="${__ARCHZEN_DIR}/archzen.sh"
	__VAR_ARCHZEN_INSTALLED="${__ROOT}/var/lib/archzen-installed"
	__VAR_DOTFILES_INSTALLED="${__ROOT}/var/lib/archzen-dotfiles-installed"
	__VAR_INITIAL_OS_SETUP_INSTALLED="${__ROOT}/var/lib/archzen-initial-os-setup-installed"
	__BIN_DIR="${__ROOT}/usr/bin"
	__SYSTEM_ALREADY_UPDATED=false
	__VAR_FIRST_LOGIN_RUN="${__ROOT}/var/lib/archzen-first-login-run-executed"
	__FIRST_LOGIN_SCRIPT="${__ROOT}/etc/profile.d/${__THIS_SCRIPT}"
	__FIRST_LOGIN_SCRIPT_LINES=(
		'#!/usr/bin/env bash'
		''
		'if (( $(id -u) == 0 )); then'
		"	rm -rf '${__FIRST_LOGIN_SCRIPT#"$__ROOT"*}' &>/dev/null"
		'	exit'
		'fi'
		''
		"archzen arch && rm -rf '${__FIRST_LOGIN_SCRIPT#"$__ROOT"*}' &>/dev/null"
	)

	__HYPR_TEMPLATE_VALUES=(
		[KB_LAYOUT]="$KB_LAYOUT"
		[KB_VARIANT]="$KB_VARIANT"
		[TERMINAL]="$TERMINAL"
		[EDITOR]="$EDITOR"
		[EXPLORER]="$EXPLORER"
		[BROWSER]="$BROWSER"
		[NOTE]="$NOTE"
	)

	__KERNEL_PARAMETERS=(
		rw
		quiet
		splash
		nowatchdog
		'nmi_watchdog=0'
		'loglevel=3'
		"rootfstype=${__ROOT_FSTYPE}"
	)
	__KERNEL_FALLBACK_PARAMETERS=(
		rw
		"rootfstype=${__ROOT_FSTYPE}"
	)
	__KERNEL_MODULES=()

	if [[ "$__ROOT_FSTYPE" == btrfs ]]; then
		{ __ROOT_BTRFS_SUBVOL="$(btrfs subvolume show "$__ROOT" | grep Name | awk -F ':' '{print $2}' | xargs)"; } &>>"$__LOG_FILE"

		if [ -n "$__ROOT_BTRFS_SUBVOL" ]; then
			__KERNEL_PARAMETERS+=("rootflags=subvol=${__ROOT_BTRFS_SUBVOL}")
			__KERNEL_FALLBACK_PARAMETERS+=("rootflags=subvol=${__ROOT_BTRFS_SUBVOL}")
		fi
	fi

	if $SETUP_ZRAM; then
		__KERNEL_PARAMETERS+=("zswap.enabled=0")
		__KERNEL_FALLBACK_PARAMETERS+=("zswap.enabled=0")
	fi

	if [[ ! "$KERNEL" =~ cachyos && "$GPU" =~ nvidia ]]; then
		__KERNEL_PARAMETERS+=('nvidia-drm.modeset=1')
		__KERNEL_MODULES+=(
			nvidia
			nvidia_modeset
			nvidia_uvm
			nvidia_drm
		)
	fi

	if __is_installed "$__AUR_HELPER_BIN"; then
		__AUR_HELPER_IS_INSTALLED=true
	fi

	__BASE_SYSTEM_PKGLIST=(
		base
		base-devel
		linux-firmware
		sof-firmware
		sudo
		"${USER_SHELL:-bash}"
	)

	__KERNEL_PKGLIST=(
		mkinitcpio
	)

	__CACHYOS_PKGLIST=(
		cachyos-ananicy-rules
		cachyos-hooks
		cachyos-kernel-manager
		cachyos-settings
		cachyos-rate-mirrors
		chwd
	)

	__FILESYSTEM_PKGLIST=(
		dosfstools
		ntfs-3g
		btrfs-progs
		exfat-utils
		gptfdisk
		fuse2
		fuse3
		fuseiso
		xfsprogs
		haveged
		nfs-utils
		nilfs-utils
		ntp
		smartmontools
	)

	__NETWORK_PKGLIST=(
		networkmanager
		networkmanager-openvpn
		dhcpcd
		dnsmasq
		wpa_supplicant
		modemmanager
		usb_modeswitch
	)

	__BLUETOOTH_PKGLIST=(
		bluez
		bluez-hid2hci
		bluez-libs
		bluez-utils
	)

	__HARDWARE_PKGLIST=(
		hwdetect
		mtools
	)

	__PACKAGE_MANAGER_PKGLIST=(
		reflector
		pkgfile
		rebuild-detector
		pacman-contrib
		diffutils
		fakeroot
		findutils
		plocate
		perl
	)

	__TERMINAL_PKGLIST=(
		less
		wget
		curl
		xdg-user-dirs
		fastfetch
		vim
		neovim
		arch-install-scripts
		git
		openssh
		btop
		rsync
		ripgrep
		bash-completion
		unrar
		unzip
		xz
		hwinfo
		inxi
		sed
		eza
		expac
		man-db
		bat
	)

	__MULTIMEDIA_PKGLIST=(
		wireplumber
		pipewire-alsa
		pipewire-audio
		pipewire-pulse
		pipewire-session-manager
		gstreamer
		gst-plugins-base
		gst-plugins-good
		gst-plugin-pipewire
		gst-libav
		gst-plugin-gtk
		gst-plugin-libcamera
		gst-plugin-msdk
		gst-plugin-opencv
		gst-plugin-qml6
		gst-plugin-qmlgl
		gst-plugin-qsv
		gst-plugin-va
		gst-plugin-wpe
		gst-plugins-bad
		gst-plugins-ugly
		pipewire-docs
		pipewire-ffado
		pipewire-jack
		pipewire-roc
		pipewire-v4l2
		pipewire-x11-bell
		pipewire-zeroconf
		realtime-privileges
		rtkit
		libdvdcss
	)

	__FONTS_PKGLIST=(
		noto-fonts
		noto-fonts-cjk
		noto-fonts-extra
		ttf-joypixels
		ttf-noto-nerd
		ttf-fira-code
		ttf-firacode-nerd
		ttf-jetbrains-mono
		ttf-jetbrains-mono-nerd
		adobe-source-han-sans-cn-fonts
		adobe-source-han-sans-jp-fonts
		adobe-source-han-sans-kr-fonts
		awesome-terminal-fonts
		noto-fonts-emoji
		noto-color-emoji-fontconfig
		cantarell-fonts
		freetype2
		opendesktop-fonts
		ttf-bitstream-vera
		ttf-dejavu
		ttf-liberation
		ttf-opensans
		ttf-meslo-nerd
	)

	__DEVELOPMENT_PKGLIST=(
		bash-language-server
		shellcheck
		shfmt
		direnv
		github-cli
		fish-lsp
		hadolint-bin
		visual-studio-code-bin
	)

	__VIRTUALIZATION_PKGLIST=(
		qemu-full
		virt-manager
		edk2-ovmf
		virtio-win
	)

	__NVIDIA_COMMON_PKGLIST=(
		nvidia-utils
		nvidia-settings
		opencl-nvidia
		vulkan-icd-loader
		lib32-opencl-nvidia
		lib32-nvidia-utils
		lib32-vulkan-icd-loader
	)

	__NVIDIA_PKGLIST=(
		nvidia-dkms
		egl-wayland
		libva-nvidia-driver
		"${__NVIDIA_COMMON_PKGLIST[@]}"
	)

	__NVIDIA_OPEN_PKGLIST=(
		nvidia-open-dkms
		egl-wayland
		libva-nvidia-driver
		"${__NVIDIA_COMMON_PKGLIST[@]}"
	)

	__NVIDIA_535XX_PKGLIST=(libva-nvidia-driver)

	__NVIDIA_470XX_PKGLIST=(libva-nvidia-driver)

	__NVIDIA_390XX_PKGLIST=(libva-nvidia-driver)

	for nvpkg in nvidia-dkms "${__NVIDIA_COMMON_PKGLIST[@]}"; do
		__NVIDIA_535XX_PKGLIST+=("${nvpkg/nvidia/nvidia-535xx}")
		__NVIDIA_470XX_PKGLIST+=("${nvpkg/nvidia/nvidia-470xx}")
		__NVIDIA_390XX_PKGLIST+=("${nvpkg/nvidia/nvidia-390xx}")
	done

	__NOUVEAU_PKGLIST=(mesa xf86-video-nouveau vulkan-nouveau lib32-mesa lib32-vulkan-nouveau)

	__AMD_PKGLIST=(mesa xf86-video-amdgpu gst-plugin-va vulkan-radeon lib32-mesa lib32-vulkan-radeon)

	__INTEL_PKGLIST=(mesa xf86-video-intel gst-plugin-va vulkan-intel lib32-mesa lib32-vulkan-intel)

	__XORG_PKGLIST=(
		xorg
	)

	__XORG_MINIMAL_PKGLIST=(
		xorg-server
		xorg-xinit
		xorg-xclock
		libwnck3
		mesa-utils
		xf86-input-libinput
		xorg-xdpyinfo
		xorg-xinput
		xorg-xkill
		xorg-xrandr
	)

	__GNOME_PKGLIST=(
		xorg-server
		gdm
		gnome-backgrounds
		gnome-browser-connector
		gnome-color-manager
		gnome-control-center
		gnome-disk-utility
		gnome-keyring
		gnome-logs
		gnome-session
		gnome-settings-daemon
		gnome-shell
		gnome-system-monitor
		gnome-user-share
		gvfs
		gvfs-afc
		gvfs-dnssd
		gvfs-goa
		gvfs-google
		gvfs-gphoto2
		gvfs-mtp
		gvfs-nfs
		gvfs-onedrive
		gvfs-smb
		gvfs-wsdd
		rygel
		snapshot
		sushi
		tecla
		xdg-desktop-portal-gnome
		xdg-user-dirs-gtk
		dconf-editor
		file-roller
		gedit
		gnome-tweaks
		fwupd
		networkmanager
		power-profiles-daemon
		system-config-printer
		baobab
		evince
		gnome-calculator
		gnome-characters
		gnome-clocks
		gnome-connections
		gnome-font-viewer
		gnome-music
		gnome-remote-desktop
		gnome-shell-extensions
		gnome-user-docs
		grilo-plugins
		totem
		loupe
		yelp
		gnome-photos
		gnome-sound-recorder
		sysprof
		nautilus-admin-gtk4
		extension-manager
		gnome-extensions-cli
	)

	__PLASMA_PKGLIST=(
		xorg-server
		plasma-meta
		power-profiles-daemon
		dolphin-plugins
		kate
		ark
		colord-kde
		gwenview
		kdegraphics-thumbnailers
		spectacle
		ffmpegthumbs
		kdeconnect
		kdenetwork-filesharing
		kio-fuse
		kio-admin
		kio-extras
		kaccounts-providers
		kio-zeroconf
		krdc
		krfb
		ktorrent
		signon-kwallet-extension
		khelpcenter
		partitionmanager
		filelight
		kalk
		kcharselect
		kdialog
		kgpg
		kimageformats
		xdg-desktop-portal-gtk
		xwaylandvideobridge
		kmail
		sddm
		plasma-applet-window-buttons
		konsave
	)

	__HYPRLAND_PKGLIST=(
		hyprland
		partitionmanager
	)

	__DE_COMMON_PKGLIST=(
		"$TERMINAL"
		"$EDITOR"
		"$BROWSER"
		"$EXPLORER"
		"$NOTE"
	)

	__HYDE_PACKAGE_BLACKLIST=(
		sddm
		qt5-quickcontrols
		qt5-quickcontrols2
		qt5-graphicaleffects
	)

	__HYDE_SERVICE_BLACKLIST=(sddm)

	__OTHERS_PKGLIST=(
		kvantum
		vesktop
	)

	__GNOME_EXTENSIONS=(
		'AppIndicator and KStatusNotifierItem Support:appindicatorsupport@rgcjonas.gmail.com'
		'Blur my Shell:blur-my-shell@aunetx'
		'Compiz alike magic lamp effect:compiz-alike-magic-lamp-effect@hermes83.github.com'
		'Coverflow Alt-Tab:CoverflowAltTab@palatis.blogspot.com'
		'Dash to Dock:dash-to-dock@micxgx.gmail.com'
		'Date Menu Formatter:date-menu-formatter@marcinjakubowski.github.com'
		'Desktop Cube:desktop-cube@schneegans.github.com'
		'GSConnect:gsconnect@andyholmes.github.io'
		'Just Perfection:just-perfection-desktop@just-perfection'
		'Logo Menu:logomenu@aryan_k'
		'Media Progress:media-progress@krypion17'
		'moveclock:moveclock@kuvaus.org'
		'Night Theme Switcher:nightthemeswitcher@romainvigier.fr'
		'Order Gnome Shell extensions:order-extensions@wa4557.github.com'
		'power-profile-indicator:power-profile-indicator@laux.wtf'
		'Search Light:search-light@icedman.github.com'
	)
	__VALID_CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML_INDEXES="CoverflowAltTab gsconnect just-perfection-desktop logomenu"
	__CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML=(
		[CoverflowAltTab]="org.gnome.shell.extensions.coverflowalttab.gschema.xml"
		[gsconnect]="org.gnome.Shell.Extensions.GSConnect.gschema.xml"
		['just-perfection-desktop']="org.gnome.shell.extensions.just-perfection.gschema.xml"
		[logomenu]="org.gnome.shell.extensions.logo-menu.gschema.xml"
	)

	declare __vsc_color_theme_ext __vsc_icon_theme_ext __vsc_dark_color_theme __vsc_light_color_theme __vsc_icon_theme
	if [[ "$DESKTOP_PROFILE" != hyprland || "$OS" == windows ]]; then
		__vsc_color_theme_ext='The Astral Themes Collection:itssimmons.vscode-astral-gem-theme'
		__vsc_icon_theme_ext='Symbols:miguelsolorio.symbols'
		# __vsc_icon_theme_ext='Gruvbox Material Icons:navernoedenis.gruvbox-material-icons'
		__vsc_dark_color_theme='(Legacy) Astroid Theme'
		__vsc_light_color_theme='Default Light Modern'
		__vsc_icon_theme='symbols'
	else
		__vsc_color_theme_ext='Wallbash:TheHyDEProject.wallbash'
		__vsc_icon_theme_ext='Symbols:miguelsolorio.symbols'
		__vsc_dark_color_theme='Wallbash'
		__vsc_light_color_theme='Wallbash'
		__vsc_icon_theme='symbols'
	fi

	# {name}:{version}:{id}
	__VSCODE_EXTENSIONS=(
		'Dev Essentials Pack:SiriusRed.dev-essentials-pack'
		'Fluent Icons:miguelsolorio.fluent-icons'
		'Brazilian Portuguese - Code Spell Checker:streetsidesoftware.code-spell-checker-portuguese-brazilian'
		'Custom CSS and JS Loader:be5invis.vscode-custom-css'
		'Cline:saoudrizwan.claude-dev'
		'Comment code:starkweb-technologies.comment-code'
		'Gemini Code Assist:google.geminicodeassist'
		'Outline Map:Gerrnperl.outline-map'
		"$__vsc_color_theme_ext"
		"$__vsc_icon_theme_ext"
	)

	__VSCODE_TEMPLATE_VALUES=(
		[DARK_COLOR_THEME]="$__vsc_dark_color_theme"
		[LIGHT_COLOR_THEME]="$__vsc_light_color_theme"
		[ICON_THEME]="$__vsc_icon_theme"
		[EXTERNAL_TERMINAL]="$TERMINAL"
		[INTEGRATED_TERMINAL]="$USER_SHELL"
	)

	if [ -n "$KERNEL" ]; then
		if [[ "$KERNEL" =~ cachyos && "$ENABLE_CACHYOS_KIT" == true ]]; then
			__CACHYOS_PKGLIST=(
				"$KERNEL"
				"${KERNEL}-headers"
				"${__CACHYOS_PKGLIST[@]}"
			)
		else
			__KERNEL_PKGLIST=(
				"$KERNEL"
				"${KERNEL}-headers"
				"${__KERNEL_PKGLIST[@]}"
			)
		fi
	fi

	if [ -n "$CPU" ]; then
		__KERNEL_PKGLIST+=("${CPU}-ucode")
	fi
}

__is_valid_semver() {
	declare version="$1"

	if [[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$ ]]; then
		return 0 # válido
	else
		return 1 # inválido
	fi
}

function __is_main_module() {
	[[ "${BASH_SOURCE[0]}" == "${0}" ]]
}

function __is_integer() {
	declare value="$1"

	[[ "$value" =~ ^[0-9]+$ ]]
}

function __func_exists() {
	declare function_name=$1

	declare -F "$function_name" &>>"$__LOG_FILE"
}

function __starts_with() {
	declare string="$1"
	declare prefix="$2"

	[[ "$string" == "$prefix"* ]]
}

function __ends_with() {
	declare string="$1"
	declare suffix="$2"

	[[ "$string" == *"$suffix" ]]
}

function __to_upper() {
	declare string="$1"

	printf "%s\n" "${string^^}"
}

function __to_lower() {
	declare string="$1"

	printf "%s\n" "${string,,}"
}

function __capitalize() {
	declare string="$1"
	declare first_char rest

	first_char="${string:0:1}"
	rest="${string:1}"

	printf "%s%s\n" "$(__to_upper "$first_char")" "$(__to_lower "$rest")"
}

function __join() {
	declare separator="$1"
	declare first_element="$2"
	shift 2
	declare -a rest_elements=("$@")
	declare joined="$first_element"

	if [[ "${#rest_elements[@]}" -gt 0 ]]; then
		for element in "${rest_elements[@]}"; do
			joined+="${separator}${element}"
		done
	fi

	printf '%s' "$joined"
}

function __tab() {
	declare -i count="$1"

	for ((i = 0; i < count; i++)); do
		printf '\t'
	done
}

function __reset_line() {
	declare -i cols
	cols=$(tput cols)

	printf "\r%${cols}s\r" ""
}

function __print() {
	declare \
		text="" \
		flg_reset_line=false \
		flg_new_line=false

	while [ $# -gt 0 ]; do
		declare flag
		flag=$(echo "${1#-}" | xargs)

		if __starts_with "$1" '--'; then
			__error "$(__error_params "\`__print\`"): Invalid flag $(__error_params "\`${flag}\`")"
			return 1
		elif __starts_with "$1" '-'; then
			[[ "$1" == *r* ]] && flg_reset_line=true
			[[ "$1" == *n* ]] && flg_new_line=true
		else
			text="$1"
		fi

		shift
	done

	$flg_reset_line && {
		text="\r${text}"
		__reset_line
	}

	$flg_new_line && text+='\n'

	printf '%b' "$text"
}

function __get_color_code() {
	declare color="$1"

	case $color in
	black)
		printf "%d" 30
		;;
	bright-black)
		printf "%d" 90
		;;
	red)
		printf "%d" 31
		;;
	bright-red)
		printf "%d" 91
		;;
	green)
		printf "%d" 32
		;;
	bright-green)
		printf "%d" 92
		;;
	yellow)
		printf "%d" 33
		;;
	bright-yellow)
		printf "%d" 93
		;;
	blue)
		printf "%d" 34
		;;
	bright-blue)
		printf "%d" 94
		;;
	purple)
		printf "%d" 35
		;;
	bright-purple)
		printf "%d" 95
		;;
	cyan)
		printf "%d" 36
		;;
	bright-cyan)
		printf "%d" 96
		;;
	white)
		printf "%d" 37
		;;
	bright-white)
		printf "%d" 97
		;;
	*)
		printf "%d" 0
		;;
	esac
}

function __colorize() {
	declare -i color="$1"
	shift
	declare text="$*"
	declare is_normal_color=false
	declare is_bright_color=false

	__is_integer "$color" && {
		[[ "$color" -ge 30 && "$color" -le 37 ]] && is_normal_color=true
		[[ "$color" -ge 90 && "$color" -le 97 ]] && is_bright_color=true
	}

	if ! $is_normal_color && ! $is_bright_color; then
		declare -a valid_normal_color_codes=(
			"\033[1;30m30\033[0m"
			"\033[1;31m31\033[0m"
			"\033[1;32m32\033[0m"
			"\033[1;33m33\033[0m"
			"\033[1;34m34\033[0m"
			"\033[1;35m35\033[0m"
			"\033[1;36m36\033[0m"
			"\033[1;37m37\033[0m"
		)
		declare -a valid_bright_color_codes=(
			"\033[1;90m90\033[0m"
			"\033[1;91m91\033[0m"
			"\033[1;92m92\033[0m"
			"\033[1;93m93\033[0m"
			"\033[1;94m94\033[0m"
			"\033[1;95m95\033[0m"
			"\033[1;96m96\033[0m"
			"\033[1;97m97\033[0m"
		)

		echo -e "\033[1;31m[!!]\033[0m Invalid color code: \033[1;91m${color}\033[0m"
		(
			IFS=", "
			echo -e "     Valid color codes: ${valid_normal_color_codes[*]}"
			echo -e "                        ${valid_bright_color_codes[*]}"
		)
		exit 1
	fi

	printf "\033[1;%sm%s\033[0m" "$color" "$text"
}

function __bold() {
	declare text="$*"

	printf "\033[1m%s\033[0m" "$text"
}

function __underline() {
	declare text="$*"

	printf "\033[4m%s\033[0m" "$text"
}

function __italic() {
	declare text="$*"

	printf "\033[3m%s\033[0m" "$text"
}

function __bold_underline() {
	declare text="$*"

	printf "\033[1;4m%s\033[0m" "$text"
}

function __bold_italic() {
	declare text="$*"

	printf "\033[1;3m%s\033[0m" "$text"
}

function __bold_underline_italic() {
	declare text="$*"

	printf "\033[1;3;4m%s\033[0m" "$text"
}

function __underline_italic() {
	declare text="$*"

	printf "\033[3;4m%s\033[0m" "$text"
}

function __black() {
	declare text="$*"

	__colorize 30 "$text"
}

function __bright_black() {
	declare text="$*"

	__colorize 90 "$text"
}

function __red() {
	declare text="$*"

	__colorize 31 "$text"
}

function __bright_red() {
	declare text="$*"

	__colorize 91 "$text"
}

function __green() {
	declare text="$*"

	__colorize 32 "$text"
}

function __bright_green() {
	declare text="$*"

	__colorize 92 "$text"
}

function __yellow() {
	declare text="$*"

	__colorize 33 "$text"
}

function __bright_yellow() {
	declare text="$*"

	__colorize 93 "$text"
}

function __blue() {
	declare text="$*"

	__colorize 34 "$text"
}

function __bright_blue() {
	declare text="$*"

	__colorize 94 "$text"
}

function __purple() {
	declare text="$*"

	__colorize 35 "$text"
}

function __bright_purple() {
	declare text="$*"

	__colorize 95 "$text"
}

function __cyan() {
	declare text="$*"

	__colorize 36 "$text"
}

function __bright_cyan() {
	declare text="$*"

	__colorize 96 "$text"
}

function __white() {
	declare text="$*"

	__colorize 37 "$text"
}

function __bright_white() {
	declare text="$*"

	__colorize 97 "$text"
}

function __banner() {
	declare primary_color=$1
	declare secondary_color=$2
	declare pad=$3
	declare title=$4
	shift 4
	declare -a optional_params=("$@")
	declare author project_url license
	declare -a reference_urls=()

	# set correct color codes
	primary_color=$(__get_color_code "$primary_color")
	secondary_color=$(__get_color_code "$secondary_color")

	# parsing parameters
	for param in "${optional_params[@]}"; do
		# [[ "$param" =~ ^author: ]] && author="${param//author:/}"
		author="Sirius (https://github.com/sirius-red)"
		[[ "$param" =~ ^project_url: ]] && project_url="${param//project_url:/}"
		[[ "$param" =~ ^license: ]] && license="${param//license:/}"
		[[ "$param" =~ ^ref: ]] && reference_urls+=("${param//ref:/}")
	done

	# calculating banner width
	declare -i width=0
	declare -a info_lines=()
	[ -n "$author" ] && info_lines+=("Author    : $author")
	[ -n "$project_url" ] && info_lines+=("Project   : $project_url")
	[ -n "$license" ] && info_lines+=("License   : $license")
	if [ ${#reference_urls} -gt 0 ]; then
		info_lines+=("References: ${reference_urls[0]}")
		for url in "${reference_urls[@]:1}"; do
			info_lines+=("REF_URL:    $url")
		done
	fi

	# determine the maximum width
	for line in "${info_lines[@]}"; do
		((${#line} > width)) && width=${#line}
	done
	((${#title} > width)) && width=${#title}
	width=$((width + 8))

	# calculating padding to center the title
	declare -i title_padding=$(((width - ${#title} - 4) / 2))

	# formatting function
	declare edge
	edge=$(printf "%${width}s" | tr ' ' "$pad")
	pad="${pad}${pad}"

	# coloring
	declare separator
	edge="$(__colorize "$secondary_color" "$edge")"
	pad="$(__colorize "$secondary_color" "$pad")"
	title="$(__colorize "$primary_color" "$title")"
	separator="$(__colorize "$secondary_color" "$(printf "%$((width - 4))s" | tr ' ' '-')")"

	# formatting and displaying the banner according to the parameters passed
	echo "$edge"
	printf "${pad}%$((width - 4))s${pad}\n"
	printf "${pad}%$((title_padding + ${#title}))s%$((width - title_padding - ${#title} + 7))s${pad}\n" "$title"
	printf "${pad}%$((width - 4))s${pad}\n"
	[ "${#info_lines}" -gt 0 ] && printf "${pad}%s${pad}\n" "$separator"
	for line in "${info_lines[@]}"; do
		key="$(echo "$line" | cut -d':' -f1):"
		value="$(echo "$line" | cut -d':' -f2-)"
		if [[ "$line" =~ ^REF_URL: ]]; then
			key="${key//?/ }"
		else
			printf "${pad}%$((width - 4))s${pad}\n"
		fi
		echo -e "${pad} $key $(__colorize "$primary_color" "$value") $(printf "%$((width - ${#key} - ${#value} - 7))s")${pad}"
	done
	[ "${#info_lines}" -gt 0 ] && printf "${pad}%$((width - 4))s${pad}\n"
	echo "$edge"
	echo
}

function __log() {
	declare plain="$1"
	declare formatted="$2"

	[ -z "$formatted" ] && formatted="$plain"

	$__QUIET || printf "%s\n" "$formatted"
	[ -f "$__LOG_FILE" ] && printf "%s\n" "$plain" >>"$__LOG_FILE"
}

function __title() {
	declare message formatted
	message="$*"
	formatted="$(__purple "[#]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __title_params() {
	declare params="$*"

	__bright_purple "$params"
}

function __question() {
	declare message="$1"
	declare formatted="$2"
	declare quiet=$__QUIET
	message="[?] ${message}"
	formatted="$(__cyan "[?]") ${message}"

	__QUIET=true
	__log "$message" "$formatted"
	__QUIET=$quiet
	return 0
}

function __question_params() {
	declare params="$*"

	__bright_cyan "$params"
}

function __info() {
	declare message formatted
	message="$*"
	formatted="$(__blue "[i]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __info_params() {
	declare params="$*"

	__bright_blue "$params"
}

function __success() {
	declare message formatted
	message="$*"
	formatted="$(__green "[+]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __success_params() {
	declare params="$*"

	__bright_green "$params"
}

function __warn() {
	declare message formatted
	message="$*"
	formatted="$(__yellow "[!]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __warn_params() {
	declare params="$*"

	__bright_yellow "$params"
}

function __error() {
	declare message formatted
	message="$*"
	formatted="$(__red "[x]") ${message}"

	__log "$message" "$formatted"
	return 1
}

function __error_params() {
	declare params="$*"

	__bright_red "$params"
}

function __confirm() {
	declare question="$*"
	declare plain_question="$* [Y/n]"
	declare -i return_code=2
	declare quiet=$__QUIET
	question="${question} [$(__bright_green Y)/$(__bright_red n)]"

	while [ $return_code -eq 2 ]; do
		printf "\r%s %s: " "$(__cyan "[?]")" "$question"
		read -r -N 1 answer

		case $answer in
		[Yy]*)
			return_code=0
			;;
		[Nn]*)
			return_code=1
			;;
		esac
	done
	printf "\n"

	__QUIET=true
	plain_question="${plain_question}: ${answer}"
	question="${question}: $(__question_params "$answer")"
	__question "$plain_question" "$question"
	__QUIET=$quiet

	return $return_code
}

function __check_type_alias() {
	declare type value
	declare quiet="$__QUIET"
	declare -A flags=(
		[silent]=false
	)

	while [ $# -gt 0 ]; do
		declare arg="$1"

		if ! __starts_with "$arg" '-'; then
			if [ -z "$type" ]; then
				type="$arg"
			elif [ -z "$value" ]; then
				value="$arg"
			fi

			shift
			continue
		fi

		case "${arg##-}" in
		s) flags[silent]=true ;;
		*) ;;
		esac

		shift
	done

	__QUIET=${flags[silent]}
	if [[ -z "${__TYPE_ALIASES[$type]}" ]]; then
		__error "Invalid $(__error_params \`type\`) value in $(__error_params '`__check_type_alias()`'): $(__error_params "$type")"
	elif [[ ! "${__TYPE_ALIASES[$type]}" =~ $value ]]; then
		__error "Invalid value for variable $(__error_params "\`$type\`"): $(__error_params "$value")"
	else
		true
	fi
	__QUIET=$quiet

	return $?
}

function __detect_bootloader() {
	if bootctl status &>>"$__LOG_FILE" && bootctl status | grep -q "systemd-boot" &>>"$__LOG_FILE"; then
		printf "sdboot"
	elif [[ -d /sys/firmware/efi && -f /boot/EFI/refind/refind.conf ]]; then
		printf "refind"
	elif [[ -f /boot/grub/grub.cfg || -f /etc/grub.conf ]]; then
		printf "grub"
	elif [[ -f /etc/lilo.conf ]]; then
		printf "lilo"
	else
		printf "unknown"
	fi
}

function __is_installed() {
	declare package="$1"

	if pacman -Q "$package" &>>"$__LOG_FILE"; then
		return 0
	fi

	return 1
}

function __detect_pkg_type() {
	declare package="$1"

	if pacman -Si "$package" &>>"$__LOG_FILE"; then
		echo "arch"
	elif git ls-remote "https://aur.archlinux.org/${package}.git" &>>"$__LOG_FILE"; then
		echo "aur"
	else
		echo "none"
	fi
}

function __arch_install() {
	declare -a packages=("$@")

	[ ${#packages[@]} -eq 0 ] && return 0

	pacman -S --noconfirm --needed "${packages[@]}" &>>"$__LOG_FILE"
	return $?
}

function __aur_install() {
	declare -a packages=("$@")
	declare -i exit_code=0

	[ ${#packages[@]} -eq 0 ] && return 0

	if $__AUR_HELPER_IS_INSTALLED; then
		{
			sudo -Hu "$__USER_NAME" "$__AUR_HELPER_BIN" -S --noconfirm "${packages[@]}" ||
				exit_code=1
		} &>>"$__LOG_FILE"
	else
		aurbuilder install --noconfirm "${packages[@]}" &>>"$__LOG_FILE" || exit_code=1
	fi

	return $exit_code
}

function __install_package() {
	declare package="$1"
	declare installed=false
	declare proceed=true
	declare pkg_type

	if __is_installed "$package"; then
		__ALREADY_INSTALLED_PKGLIST+=("$package")
		__info "Package is already installed: $(__info_params "$package")"
		return $?
	fi

	__title "installing package $(__title_params "${package}")"

	pkg_type=$(__detect_pkg_type "$package")
	case "$pkg_type" in
	arch)
		__arch_install "$package" && installed=true
		;;
	aur)
		__aur_install "$package" && installed=true
		;;
	none)
		__NOT_EXISTS_PKGLIST+=("$package")
		__warn "Package not exist: $(__warn_params "$package")"
		proceed=false
		;;
	*)
		__NOT_INSTALLED_PKGLIST+=("$package")
		__error "Unkown error for package: $(__error_params "$package")"
		proceed=false
		;;
	esac

	$proceed || return 1

	if $installed; then
		__success "Package installed: $(__success_params "${package}")"
	else
		__NOT_INSTALLED_PKGLIST+=("$package")
		__warn "Package not installed: $(__warn_params "$package")"
		false >/dev/null
	fi

	return $?
}

function __install_pkglist() {
	declare -a pkglist=("$@")
	declare -a installed_packages=()
	declare result_text=""
	declare -a arch_pkglist=()
	declare -a aur_pkglist=()
	declare -i total_packages_count=${#pkglist[@]}
	declare -i installed_packages_count=0
	declare -i exit_code=0

	function __update_installed_packages() {
		installed_packages=()

		while IFS='' read -r pkg; do installed_packages+=("$pkg"); done < <(pacman -Qq)
	}

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((installed_packages_count += increment))

		case "$log_type" in
		title) result_text="Installed $(__title_params $installed_packages_count) of $(__title_params $total_packages_count) packages" ;;
		info) result_text="Installed $(__info_params $installed_packages_count) of $(__info_params $total_packages_count) packages" ;;
		success) result_text="Installed $(__success_params $installed_packages_count) of $(__success_params $total_packages_count) packages" ;;
		warn) result_text="Installed $(__warn_params $installed_packages_count) of $(__warn_params $total_packages_count) packages" ;;
		error) result_text="Installed $(__error_params $installed_packages_count) of $(__error_params $total_packages_count) packages" ;;
		*) result_text="Installed $(__bold $installed_packages_count) of $(__bold $total_packages_count) packages" ;;
		esac
	}

	function __init_pkglist_installation() {
		__update_result_text 0 title
		printf '%sStarting installation of %s packages.\t%s' "$(__title)" "$(__title_params "${total_packages_count}")" "$result_text"
		sleep 2
	}

	function __fetch_pkglist_data() {
		__update_installed_packages

		for pkg in "${pkglist[@]}"; do
			declare pkg_type
			declare success=false

			if [[ "${installed_packages[*]}" =~ $pkg ]]; then
				__ALREADY_INSTALLED_PKGLIST+=("$pkg")
				__update_result_text 1 info
				continue
			fi

			pkg_type=$(__detect_pkg_type "$pkg")

			case "$pkg_type" in
			arch)
				arch_pkglist+=("$pkg")
				;;
			aur)
				aur_pkglist+=("$pkg")
				;;
			*)
				__NOT_INSTALLED_PKGLIST+=("$pkg")
				;;
			esac
		done
	}

	function __install_arch_pkglist() {
		__reset_line
		printf '%sInstalling arch packages.\t%s' "$(__info)" "$result_text"

		__arch_install "${arch_pkglist[@]}"
		__update_installed_packages

		for pkg in "${arch_pkglist[@]}"; do
			if [[ "${installed_packages[*]}" =~ $pkg ]]; then
				__update_result_text 1 info
			else
				__NOT_INSTALLED_PKGLIST+=("$pkg")
			fi
		done
	}

	function __install_aur_pkglist() {
		__reset_line
		printf '%sInstalling aur packages.\t%s' "$(__info)" "$result_text"
		__aur_install "${aur_pkglist[@]}"

		__update_installed_packages
		for pkg in "${aur_pkglist[@]}"; do
			if [[ "${installed_packages[*]}" =~ $pkg ]]; then
				__update_result_text 1 info
			else
				__NOT_INSTALLED_PKGLIST+=("$pkg")
			fi
		done
	}

	function __finalize_pkglist_installation() {
		__reset_line
		if [ $installed_packages_count -eq $total_packages_count ]; then
			__update_result_text 0 success
			printf '%s\t%s\n' "$(__success 'Packages installed successfully.')" "$result_text"
		elif [ $installed_packages_count -gt 0 ]; then
			__update_result_text 0 warn
			printf '%s\t%s\n' "$(__warn 'Packages installed with some errors.')" "$result_text"
		else
			__update_result_text 0 error
			printf '%s\t%s\n' "$(__error 'Error installing packages.')" "$result_text"
			exit_code=1
		fi
	}

	__init_pkglist_installation
	__fetch_pkglist_data
	__install_arch_pkglist
	__install_aur_pkglist
	__finalize_pkglist_installation

	return $exit_code
}

function __get_line() {
	declare pattern="$1"
	declare file_path="$2"
	declare result
	declare -i line=0

	result=$(grep -n "$pattern" "$file_path" || printf 'none')

	if [[ "$result" != 'none' ]]; then
		line=$(echo "$result" | cut -d ':' -f 1 | xargs)
	fi

	printf '%d' $line
}

function __add_lines_to_file() {
	declare file_path="$1"
	declare mode="$2"
	declare add_blank_line=false
	[[ "$3" == "true" ]] && add_blank_line=true
	shift 3
	declare -a lines=("$@")
	declare success=false
	declare action_word

	function __exec() {
		if [[ "$mode" == "w" ]]; then
			declare file_dir
			file_dir=$(dirname "$file_path")

			if [ -f "$file_path" ]; then
				rm -f "$file_path" &>>"$__LOG_FILE"
			elif [ ! -d "$file_dir" ]; then
				mkdir -p "$file_dir" &>>"$__LOG_FILE"
			fi

			{
				for line in "${lines[@]}"; do
					printf "%s\n" "$line"
				done
			} | tee "$file_path" &&
				success=true
		else
			if [ ! -f "$file_path" ]; then
				touch "$file_path" &>>"$__LOG_FILE"
				add_blank_line=false
			fi

			{
				$add_blank_line && printf "\n"
				for line in "${lines[@]}"; do
					printf "%s\n" "$line"
				done
			} | tee -a "$file_path" &&
				success=true
		fi

		if $success; then
			chmod 644 "$file_path" && return 0

			return 1
		fi

		return 1
	}

	if [ "$mode" == "w" ]; then
		action_word="Creating"
	else
		action_word="Editing"
	fi

	__title "${action_word} file: $(__title_params "$file_path")"

	if __exec &>>"$__LOG_FILE"; then
		if [ "$mode" == "w" ]; then
			action_word="created"
		else
			action_word="edited"
		fi

		__success "File ${action_word} successfully: $(__success_params "$file_path")"
	else
		if [ "$mode" == "w" ]; then
			action_word="creating"
		else
			action_word="editing"
		fi

		__error "Error ${action_word} file: $(__error_params "$file_path")"
	fi

	return $?
}

function __apply_template_values() {
	declare template_var="$1"
	declare file_path="$2"
	declare -a not_replaced=()

	function __replace_variables() {
		for key in $(eval 'echo ${!'"$template_var"'[@]}' 2>>"$__LOG_FILE"); do
			declare template_key template_value
			template_key="{{ARCHZEN_${key}}}"
			template_value="$(eval 'echo ${'"$template_var""[$key]}" 2>>"$__LOG_FILE")"

			if ! sed -i "s/${template_key}/${template_value}/g" "$file_path" &>>"$__LOG_FILE"; then
				not_replaced+=("$template_key")
			fi
		done
	}

	__title "Applying template values $(__title_params "$template_var") to $(__title_params "$file_path") file"

	if eval "[ -z \"$$template_var\" ]"; then
		__error "Template variable $(__error_params "\$$template_var") is not defined"
		return 1
	fi

	if $proceed && ! [ -f "$file_path" ]; then
		__error "File $(__error_params "$file_path") not found"
		return 1
	fi

	if ! __replace_variables; then
		__error "Error replacing template values $(__error_params "\$$template_var") to $(__error_params "$file_path") file"
		return 1
	fi

	if [ "${#not_replaced[@]}" -eq 0 ]; then
		__success "All template values in $(__success_params "\$$template_var") were successfully replaced to the $(__success_params "$file_path") file"
	else
		declare not_replaced_str
		not_replaced_str="$(__join ', ' "${not_replaced[@]}")"

		__warn "Some template values in $(__warn_params "\$$template_var") have not been replaced in the $(__warn_params "\$$template_var") file: ${not_replaced_str}"
	fi

	return $?
}

function __takeown() {
	declare target="$1"
	declare -a args=("${__USER_NAME}:${__USER_NAME}" "$target")

	[ -d "$target" ] && args=(-R "${args[@]}")

	chown "${args[@]}" &>>"$__LOG_FILE"
}

function __format_script() {
	declare script_path="$1"
	shift
	declare -a options=("$@")
	declare quiet=$__QUIET

	[[ "${options[*]}" =~ --quiet|-q ]] && __QUIET=true

	__title "Formatting file: $(__title_params "$script_path")"

	if shfmt --write --indent 4 --case-indent "$script_path" &>>"$__LOG_FILE"; then
		__success "File formatted successfully: $(__success_params "$script_path")"
	else
		__warn "Error formatting file: $(__warn_params "$script_path")"
	fi

	__QUIET=$quiet

	return 0
}

function __save_script() {
	declare script_name="$1"
	declare create_symlink="$2"
	shift 2
	declare -a script_lines=("$@")
	declare script_path
	script_path="${__ARCHZEN_SCRIPTS_DIR}/${script_name}.sh"

	__add_lines_to_file "$script_path" w false "${script_lines[@]}" &>>"$__LOG_FILE" &&
		__format_script "$script_path" --quiet &&
		chmod +x "$script_path" &>>"$__LOG_FILE" &&
		{
			if [[ "$create_symlink" == true ]]; then
				ln -sf "$script_path" "${__BIN_DIR}/${script_name}" &>>"$__LOG_FILE"
			else
				true
			fi
		} &&
		return 0

	return 1
}

function __gen_bootloader_update_script() {
	declare bootloader="$1"
	[[ "$bootloader" == "auto" ]] && bootloader="$(__detect_bootloader)"

	declare script_name="${bootloader}-update"
	declare -a script_lines=(
		'#!/usr/bin/env bash'
		''
		"# shellcheck source=${__MAIN_SCRIPT_BASE_PATH}"
		"source \"${__MAIN_SCRIPT_BASE_PATH}\""
		''
		"setup_bootloader ${bootloader} false"
	)

	__title "Generating update script for $(__title_params "$bootloader"): $(__title_params "$script_name")"

	if __save_script "$script_name" true "${script_lines[@]}"; then
		__success "Success generated update script for $(__success_params "$bootloader"): $(__success_params "$script_name")"
	else
		__error "Error when generating update script for $(__error_params "$bootloader"): $(__error_params "$script_name")"
	fi

	return $?
}

function __setup_sdboot() {
	function __gen_entry() {
		declare entry_dir="${__ESP}/loader/entries"
		declare entry_file="${entry_dir}/${KERNEL}.conf"
		declare -a entry_file_lines=(
			'# Created by: ArchZen'
			"title		Arch Linux (${KERNEL})"
			"linux		/vmlinuz-${KERNEL}"
			"initrd		/${CPU}-ucode.img"
			"initrd		/initramfs-${KERNEL}.img"
			"options	root=PARTUUID=${__ROOT_PARTUUID} ${__KERNEL_PARAMETERS[*]}"
		)
		declare entry_file_fallback="${entry_dir}/${KERNEL}-fallback.conf"
		declare -a entry_file_fallback_lines=(
			'# Created by: ArchZen'
			"title		Arch Linux (${KERNEL}-fallback)"
			"linux		/vmlinuz-${KERNEL}"
			"initrd		/initramfs-${KERNEL}-fallback.img"
			"options	root=PARTUUID=${__ROOT_PARTUUID} ${__KERNEL_FALLBACK_PARAMETERS[*]}"
		)

		if [ ! -d "$entry_dir" ]; then
			mkdir -p "$entry_dir" &>>"$__LOG_FILE"
		fi

		__add_lines_to_file "$entry_file" w false "${entry_file_lines[@]}" &&
			__add_lines_to_file "$entry_file_fallback" w false "${entry_file_fallback_lines[@]}"
	}

	function __edit_loader() {
		declare esp_loader_conf="${__ESP}/loader/loader.conf"
		declare sd_default="$KERNEL"
		declare -i sd_timeout=0
		declare sd_console_mode="max" # auto | max | keep
		declare sd_editor="no"        # yes | no
		declare -a esp_loader_conf_lines=(
			"default       ${sd_default}"
			"timeout       ${sd_timeout}"
			"console-mode  ${sd_console_mode}"
			"editor        ${sd_editor}"
		)

		__add_lines_to_file "$esp_loader_conf" w false "${esp_loader_conf_lines[@]}"
	}

	__gen_entry &>>"$__LOG_FILE" &&
		__edit_loader &>>"$__LOG_FILE" &&
		return 0

	return 1
}

function __variable_file_exists() {
	$__FORCE && return 1

	declare file="$1"

	[ -f "$file" ]
}

function __is_installed_initial_os_setup() {
	__variable_file_exists "$__VAR_INITIAL_OS_SETUP_INSTALLED"

	return $?
}

function __is_installed_archzen() {
	__variable_file_exists "$__VAR_ARCHZEN_INSTALLED"

	return $?
}

function __is_installed_dotfiles() {
	__variable_file_exists "$__VAR_DOTFILES_INSTALLED"

	return $?
}

function __install_gnome_extensions() {
	if ! __is_installed gnome-extensions-cli; then
		__error "Error installing Gnome extensions. $(__error_params "\`gnome-extensions-cli\`") is not installed."
		return 1
	fi

	declare -i return_code=0
	declare -i already_installed_count=0
	declare -i installed_count=0
	declare -i total_installed_count=0
	declare -i total_count=${#__GNOME_EXTENSIONS[@]}
	declare result_text=""
	declare -a gnome_ext_dirs=(
		"${__ROOT}/usr/share/gnome-shell/extensions"
		"${__USER_HOME}/.local/share/gnome-shell/extensions"
	)
	declare force_restart_requirement=false
	declare -a version_fixed_extensions=()
	declare gnome_shell_version
	gnome_shell_version="$(gnome-shell --version | awk -F ' ' '{print $3}' | awk -F '.' '{print $1}')"

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((installed_count += increment))
		((total_installed_count = installed_count + already_installed_count))

		case "$log_type" in
		title) result_text="Installed $(__title_params $total_installed_count) of $(__title_params $total_count) extensions" ;;
		info) result_text="Installed $(__info_params $total_installed_count) of $(__info_params $total_count) extensions" ;;
		success) result_text="Installed $(__success_params $total_installed_count) of $(__success_params $total_count) extensions" ;;
		warn) result_text="Installed $(__warn_params $total_installed_count) of $(__warn_params $total_count) extensions" ;;
		error) result_text="Installed $(__error_params $total_installed_count) of $(__error_params $total_count) extensions" ;;
		*) result_text="Installed $(__bold $total_installed_count) of $(__bold $total_count) extensions" ;;
		esac
	}

	printf '%s' "$(__title "Starting installation of $(__title_params $total_count) $(__bold GNOME) extensions")"
	sleep 2
	__update_result_text 0 info

	for ext in "${__GNOME_EXTENSIONS[@]}"; do
		declare name="${ext%:*}"
		declare uuid="${ext#*:}"
		declare id="${uuid%@*}"

		__reset_line
		printf '%s\t%s' "$(__info "Installing ${name}...")" "$result_text"

		if [[ -f "${gnome_ext_dirs[0]}/extension.js" || -f "${gnome_ext_dirs[1]}/extension.js" ]]; then
			((already_installed_count++))
			__update_result_text 0 info
		elif gnome-extensions-cli update --install --yes "$uuid" &>>"$__LOG_FILE"; then
			__update_result_text 1 info
		else
			__update_result_text 0 warn
			continue
		fi

		for gnome_ext_dir in "${gnome_ext_dirs[@]}"; do
			declare ext_dir="${gnome_ext_dir}/${uuid}"
			declare ext_schemas_dir="$ext_dir/schemas"
			declare ext_schema_xml="$ext_schemas_dir/org.gnome.shell.extensions.${id}.gschema.xml"
			declare ext_schema_compiled="$ext_schemas_dir/gschemas.compiled"
			declare metadata="${ext_dir}/metadata.json"
			declare metadata_tmp="${__ROOT}/tmp/${uuid}.metadata.$$.json"

			if [[ "$__VALID_CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML_INDEXES" =~ $id ]]; then
				ext_schema_xml="$ext_schemas_dir/${__CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML[$id]}"
			fi

			if [[ -f "$ext_schema_xml" && ! -f "$ext_schema_compiled" ]]; then
				glib-compile-schemas "$ext_schemas_dir" &>>"$__LOG_FILE" &&
					force_restart_requirement=true
			fi

			declare jq_result
			jq_result="$(jq ".[\"shell-version\"] | index(\"${gnome_shell_version}\")" "$metadata" 2>>"$__LOG_FILE")"

			if [[ "$jq_result" == null ]]; then
				{
					jq ".[\"shell-version\"] += [\"${gnome_shell_version}\"]" "$metadata" >"$metadata_tmp" &&
						mv -f "$metadata_tmp" "$metadata" &&
						version_fixed_extensions+=("$name")
					force_restart_requirement=true
				} &>>"$__LOG_FILE"
			fi
		done

	done

	if [ -d "${gnome_ext_dirs[1]}" ]; then
		__takeown "${gnome_ext_dirs[1]}"
	fi

	__reset_line
	if [ $total_installed_count -eq $total_count ]; then
		__update_result_text 0 success
		printf '%s\t%s\n' "$(__success 'Extensions installed successfully.')" "$result_text"
	elif [ $total_installed_count -gt 0 ]; then
		__update_result_text 0 warn
		printf '%s\t%s\n' "$(__warn 'Extensions installed with some errors.')" "$result_text"
	else
		__update_result_text 0 error
		printf '%s\t%s\n' "$(__error 'Error installing extensions.')" "$result_text"
		return_code=1
	fi

	if [ ${#version_fixed_extensions[@]} -gt 0 ]; then
		__warn "The extensions below have been manually fixed for Gnome Shell version 48. Disable them if you experience any issues:"

		for ext in "${version_fixed_extensions[@]}"; do
			printf '        - %s\n' "$(__warn_params "$ext")"
		done
	fi

	if [[ "$__COMMAND_ARG" =~ desktop-profile|dp ]] &&
		{ [[ "$force_restart_requirement" == true ]] || [ $installed_count -gt 0 ]; } &&
		pgrep -x "gnome-shell" &>>"$__LOG_FILE"; then
		finish
		__warn "Gnome Shell needs to be restarted so that extensions are applied"

		if __confirm "Logout now?"; then
			for ((i = 3; i > 0; i--)); do
				__reset_line
				printf '%sLogging out in %s seconds' "$(__info)" "$i"
				sleep 1
			done

			__log ''

			{ sudo -Eu "$__USER_NAME" gnome-session-quit --logout --no-prompt; } &>>"$__LOG_FILE"

			__warn "Could not restart Gnome Shell, you have to restart it manually"
			__log ''
		else
			__warn "Restart the Gnome Shell manually"
			__log ''
		fi

		exit $return_code
	fi

	return $return_code
}

function __set_sddm_settings() {
	__add_lines_to_file "${__ROOT}/usr/lib/sddm/sddm.conf.d/general.conf" "w" false \
		'[Autologin]' \
		'Relogin=false' \
		'Session=plasma' \
		'' \
		'[General]' \
		'HaltCommand=/usr/bin/systemctl poweroff' \
		'InputMethod=qtvirtualkeyboard' \
		'Numlock=on' \
		'RebootCommand=/usr/bin/systemctl reboot' \
		'' \
		'[Theme]' \
		'Current=breeze' \
		'' \
		'[Users]' \
		'DefaultPath=/usr/local/sbin:/usr/local/bin:/usr/bin' \
		'HideShells=' \
		'HideUsers=' \
		'MaximumUid=60000' \
		'MinimumUid=1000' \
		'RememberLastSession=true' \
		'RememberLastUser=true' \
		'ReuseSession=false' \
		'' \
		'[Wayland]' \
		'EnableHiDPI=true' \
		'SessionCommand=/usr/share/sddm/scripts/wayland-session' \
		'SessionDir=/usr/share/wayland-sessions' \
		'SessionLogFile=.local/share/sddm/wayland-session.log' \
		'' \
		'[X11]' \
		'EnableHiDPI=true' \
		'MinimumVT=1' \
		'ServerArguments=-nolisten tcp' \
		'ServerPath=/usr/bin/X' \
		'SessionCommand=/usr/share/sddm/scripts/Xsession' \
		'SessionDir=/usr/share/xsessions' \
		'SessionLogFile=.local/share/sddm/xorg-session.log' \
		'UserAuthFile=.Xauthority' \
		'XauthPath=/usr/bin/xauth' \
		'XephyrPath=/usr/bin/Xephyr'

	__add_lines_to_file "${__ROOT}/etc/sddm.conf.d/01-wayland.conf" "w" false \
		'[General]' \
		'DisplayServer=wayland' \
		'GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell' \
		'' \
		'[Wayland]' \
		'CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1'
}

function __enable_kernel_modules() {
	[ "${#__KERNEL_MODULES[@]}" -gt 0 ] || return

	declare mkinitcpio_conf="${__ROOT}/etc/mkinitcpio.conf"
	declare success=false

	function __exec() {
		declare current_modules updated_modules
		current_modules="$(grep "^MODULES=" "$mkinitcpio_conf" | sed 's/MODULES=(\(.*\))/\1/')"

		for mod in "${__KERNEL_MODULES[@]}"; do
			if [[ "$current_modules" =~ $mod ]]; then
				continue
			fi

			current_modules+=" $mod"
		done

		updated_modules="$(echo "$current_modules" | xargs)"

		sed -i "s/^MODULES=.*/MODULES=(${updated_modules})/" "$mkinitcpio_conf" &&
			mkinitcpio -P
	}

	declare ifs="$IFS"
	export IFS=","
	__title "Enabling kernel modules in $(__bold "$mkinitcpio_conf"): $(__title_params "${__KERNEL_MODULES[*]}")"
	export IFS="$ifs"
	__exec &>>"$__LOG_FILE" && success=true

	if $success; then
		__success "Kernel modules enabled successfully"
	else
		__error "Error enabling kernel modules"
	fi

	return $?
}

function __install_cachyos_repo() {
	declare workdir="${__ROOT}/tmp/cachyos-repo"
	declare proceed=true
	declare success=false

	__title "Installing CachyOS repositories"

	if __is_installed cachyos-keyring && __is_installed cachyos-mirrorlist; then
		__info "CachyOS repositories already installed"
		return $?
	fi

	{
		if [ -d "$workdir" ]; then
			proceed=false

			rm -rf "$workdir" &&
				proceed=true
		fi

		$proceed &&
			cd "$(dirname "$workdir")" &&
			curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o "${workdir}.tar.xz" &&
			tar -xvf "${workdir}.tar.xz" &&
			cd "$(basename "$workdir")" &&
			yes | ./cachyos-repo.sh &&
			cd "$__PWD" &&
			rm -rf "$workdir" &&
			success=true
	} &>>"$__LOG_FILE"

	if $success; then
		__success "CachyOS repository installed successfully"
	else
		__error "Error installing CachyOS repository"
	fi

	return $?
}

function __rate_cachyos_mirrors() {
	__title "Rating CachyOS mirrors"

	if cachyos-rate-mirrors &>>"$__LOG_FILE"; then
		__success "CachyOS mirrors were successfully rated"
	else
		__error "Error rating CachyOS mirrors"
	fi

	return $?
}

function __install_cachyos_packages() {
	__title "Installing CachyOS tools"
	__install_pkglist "${__CACHYOS_PKGLIST[@]}"
	return $?
}

function __update_system() {
	declare pkgmgr="pacman"
	$__AUR_HELPER_IS_INSTALLED && pkgmgr=$__AUR_HELPER_BIN

	__title "Updating system"

	if $pkgmgr -Syu --noconfirm &>>"$__LOG_FILE"; then
		__SYSTEM_ALREADY_UPDATED=true
		__success "System updated successfully with: $(__success_params "$pkgmgr")"
	else
		__error "Error updating system with: $(__error_params "$pkgmgr")"
	fi

	return $?
}

function __show_log_msglist() {
	declare log_func="__${1}"
	shift 1
	declare msglist=("$@")

	[[ -z "${msglist[*]}" || ${#msglist[@]} -le 0 ]] && return 0

	__log ""
	for msg in "${msglist[@]}"; do
		$log_func "$msg"
	done
}

function install_archzen() {
	declare success=false
	declare script_name
	script_name="$(basename "$__MAIN_SCRIPT_PATH")"
	script_name="${script_name/.sh/}"
	declare -a bin_file_lines=(
		'#!/usr/bin/env bash'
		''
		'if [[ $EUID -eq 0 ]]; then'
		'	printf "\033[1;31m[x]\033[0m Do not run the Archzen binary with sudo"'
		'	exit 1'
		'fi'
		''
		'export ARCHZEN_IS_RUNNING_FROM_BINARY=true'
		''
		'if [[ "$1" =~ ^version$|^v$|^help$|^h$ || -z "$1" ]]; then'
		"	$__MAIN_SCRIPT_BASE_PATH \"\$@\""
		'else'
		"	sudo -E $__MAIN_SCRIPT_BASE_PATH \"\$@\""
		'fi'
	)
	declare tmp_script_dir="${__ROOT}/tmp/archzen/scripts-$$"

	__title "Installing Archzen"

	[ -d "$__ARCHZEN_SCRIPTS_DIR" ] && cp -rf "$__ARCHZEN_SCRIPTS_DIR" "$tmp_script_dir" &>>"$__LOG_FILE"
	[ -d "$__ARCHZEN_DIR" ] && rm -rf "$__ARCHZEN_DIR" &>>"$__LOG_FILE"
	mkdir -p "$__ARCHZEN_DIR" &>>"$__LOG_FILE"

	{
		[ -d "$__ARCHZEN_DIR" ] &&
			{
				if [ -d "$tmp_script_dir" ]; then
					cp -rf "$tmp_script_dir" "$__ARCHZEN_SCRIPTS_DIR" &>>"$__LOG_FILE"
				else
					true
				fi
			} &&
			cp -f "$__THIS_SCRIPT" "$__MAIN_SCRIPT_PATH" &&
			chmod +x "$__MAIN_SCRIPT_PATH" &&
			__save_script "$script_name" true "${bin_file_lines[@]}" &&
			cp -rf "$__PWD_RESOURCES_DIR" "$__ARCHZEN_RESOURCES_DIR" &&
			cp -f "${__PWD}/LICENSE" "$__ARCHZEN_DIR" &&
			touch "$__VAR_ARCHZEN_INSTALLED" &&
			success=true
	} &>>"$__LOG_FILE"

	if $success; then
		__success "ArchZen successfully installed"
	else
		__error "Error installing ArchZen"
	fi

	return $?
}

function install_archlinux() {
	if ! command -v archinstall &>>"$__LOG_FILE"; then
		__error "Executable not found in PATH: $(__error_params "archinstall")"
		return $?
	fi

	declare first_line_warn rest_lines_warn
	declare quiet="$__QUIET"
	first_line_warn="ArchZen was made for the \"Minimal\" profile, but it throws an error if you try load a config"
	rest_lines_warn="$(
		cat <<EOL
    file with the "profile_config" property set, choose it manually from the installation menu.
    Choose another profile may not interfere with the installation and the rest of the setup,
    but things can be strange in the end, since ArchZen installs the desktop environment on its own
    (if you want a diffrent profile from plasma, which is defined by default in ArchZen, set it
    in the "DESKTOP_PROFILE" variable in the "archzen.sh" file)
EOL
	)"

	__log "" ""
	__warn "$first_line_warn"
	__QUIET=true
	__log "$rest_lines_warn" "$rest_lines_warn"
	__QUIET="$quiet"
	echo "$rest_lines_warn"
	__log "" ""

	__confirm "Proceed?" || exit 0
	__log "" ""

	setup_pacman || return 1
	archinstall --advanced --config "${__ARCHINSTALL_PRESET}" || return 1

	declare current_root="$__ROOT"
	__set_global_variables "$__MOUNT_DIR" "$__FORCE" "$__ARCHZEN_IS_RUNNING_FROM_BINARY"

	install_archzen &&
		__add_lines_to_file "$__FIRST_LOGIN_SCRIPT" w false "${__FIRST_LOGIN_SCRIPT_LINES[@]}" &&
		setup_sudoers

	__set_global_variables "$current_root" "$__FORCE" "$__ARCHZEN_IS_RUNNING_FROM_BINARY"
}

function setup_sudoers() {
	function __apply_options() {
		declare sudoers="${__ROOT}/etc/sudoers"
		declare -a sudoers_options=(
			"Defaults	insults"
			"Defaults	pwfeedback"
			"Defaults	timestamp_timeout=${TIMESTAMP_TIMEOUT}"
		)

		for option in "${sudoers_options[@]}"; do
			if grep -qe "$option" "$sudoers" &>>"$__LOG_FILE"; then
				__info "Option alread exists: $(__info_params "$option")"
				continue
			fi

			if __add_lines_to_file "$sudoers" "a" false "$option"; then
				__success "Option added successfully to ${sudoers}: $(__success_params "$option")"
			else
				__error "Error adding option to ${sudoers}: $(__error_params "$option")"
			fi
		done
	}

	function __apply_user_options() {
		declare sudoers_user="${__ROOT}/etc/sudoers.d/00_${__USER_NAME}"
		declare -a sudoers_user_options=(
			"${__USER_NAME}	ALL=(ALL:ALL)	ALL"
			"%${__USER_NAME}	ALL=(ALL:ALL)	ALL"
		)

		if [ ! -f "$sudoers_user" ]; then
			__add_lines_to_file "${sudoers_user}" "w" false "${sudoers_user_options[@]}"
		else
			declare -i line_n
			line_n=$(__get_line "^${__USER_NAME} ALL=(ALL) ALL")

			if [ $line_n -gt 0 ]; then
				sed -i "${line_n}d" &>>"$__LOG_FILE"
			fi

			for option in "${sudoers_user_options[@]}"; do
				if grep -qe "$option" "$sudoers_user" &>>"$__LOG_FILE"; then
					__info "Config already defined for user ${__USER_NAME}: $(__info_params "$option")"
					continue
				fi

				if __add_lines_to_file "${sudoers_user}" "a" false "${option}"; then
					__success "Option added successfully to ${sudoers_user}: $(__success_params "$option")"
				else
					__error "Error adding option to ${sudoers_user}: $(__error_params "$option")"
				fi
			done
		fi
	}

	if [[ "$__ROOT" != "/" ]]; then
		__apply_options
		return $?
	fi

	__title "Configuring sudoers for user: $(__title_params "$__USER_NAME")"

	__apply_options
	__apply_user_options

	return $?
}

function setup_zram() {
	$SETUP_ZRAM || return 0
	zramctl &>>"$__LOG_FILE" || return 0

	function __setup_zram() {
		declare zram_generator_conf="${__ROOT}/etc/systemd/zram-generator.conf"
		declare zram_parameters_conf="${__ROOT}/etc/sysctl.d/99-vm-zram-parameters.conf"
		declare -a zram_generator_lines=(
			'# Defines the first zram unit'
			'[zram0]'
			''
			'# Defines ZRAM size to a range of at least 10% and at a 4XIMUM 50% (with a maximum limit of 16g)'
			'zram-size = max(ram / 10, min(ram / 2, 16384M))'
			''
			'# Compression algorithm'
			'compression-algorithm = zstd lz4 (type=huge)'
			''
			'# High priority to ensure that zram is used before any disk swap'
			'swap-priority = 100'
			''
			'# ZRAM Partition File System Type'
			'fs-type = swap'
		)
		declare -a zram_parameters_lines=(
			'# Avoid use of swap until really necessary'
			'vm.swappiness = 20'
			''
			'# Reserves a little RAM as "buffer" to avoid pressure under pressure'
			'vm.watermark_boost_factor = 150'
			''
			'# Sensitivity of memory pressure (the smaller, the less aggressive)'
			'vm.watermark_scale_factor = 10'
			''
			'# Exchange only one page at a time on swap (lower latency, ideal for zram)'
			'vm.page-cluster = 0'
			''
			'# Releases Pagecache more aggressively (good for builds, compilations, etc.)'
			'vm.vfs_cache_pressure = 100'
			''
			'# Prevents excessive dirty cache flushs'
			'vm.dirty_background_ratio = 5'
			'vm.dirty_ratio = 20'
		)

		__title "Configuring zram"

		__install_package zram-generator &&
			__add_lines_to_file "$zram_generator_conf" "w" false "${zram_generator_lines[@]}" &&
			__add_lines_to_file "$zram_parameters_conf" "w" false "${zram_parameters_lines[@]}" &&
			return 0

		return 1
	}

	function __setup_swapfile() {
		declare swapfile="${__ROOT}/swapfile"
		declare fstab="${__ROOT}/etc/fstab"
		declare -a fstab_lines=(
			"${swapfile} none swap pri=10 0 0"
		)
		declare proceed=false

		__title "Configuring swapfile fallback"

		if [[ "$__ROOT_FSTYPE" == "btrfs" ]]; then
			btrfs filesystem mkswapfile "$swapfile" &&
				proceed=true
		elif fallocate -l 4G "$swapfile" || dd if=/dev/zero of="$swapfile" bs=1M count=4096 status=progress; then
			chmod 600 "$swapfile" &&
				proceed=true
		fi

		[[ "$proceed" == true ]] &&
			mkswap "$swapfile" &&
			__add_lines_to_file "$fstab" "a" true "${fstab_lines[@]}" &&
			swapon "$swapfile" &&
			return 0

		return 1
	}

	if __setup_zram &>>"$__LOG_FILE"; then
		__success "Zram configured successfully"

		if [[ $USE_SWAPFILE ]]; then
			__setup_swapfile &>>"$__LOG_FILE" || __warn "Swapfile was not configured correctly"
		fi
	else
		__error "Error configuring zram"
	fi

	return $?
}

function setup_pacman() {
	declare pacman_conf="${__ROOT}/etc/pacman.conf"
	declare -i return_code=0

	function __show_title() {
		declare step="$1"

		__title "Configuring pacman: $(__title_params "$step")"
	}

	function __show_result() {
		declare status="$1"
		declare step="$2"

		case $status in
		keep)
			__info "Pacman option already configured: $(__info_params "$step")"
			;;
		changed)
			__success "Pacman option changed successfully: $(__success_params "$step")"
			;;
		unchanged)
			__error "Error changing pacman option: $(__error_params "$step")"
			;;
		*)
			__error "$(__error_params "setup_pacman()"): Unknown log status: $(__error_params "$status")"
			;;
		esac

		return $?
	}

	function __enable_colors() {
		declare status

		__show_title "Enable colors"

		if grep -qe '^Color$' "$pacman_conf" &>>"$__LOG_FILE"; then
			status="keep"
		elif sed -i 's/^#\s*Color/Color/' "$pacman_conf" &>>"$__LOG_FILE"; then
			status="changed"
		else
			status="unchanged"
		fi

		__show_result "$status" "Color"
		return $?
	}

	function __enable_i_love_candy() {
		declare status

		__show_title "Enable pacman's most important option"

		if grep -qe '^ILoveCandy$' "$pacman_conf"; then
			status="keep"
		elif sed -i '/^#\?\s*Color$/a ILoveCandy' "$pacman_conf" &>>"$__LOG_FILE"; then
			# sed -i '/^#\?\s*ILoveCandy/d' "$pacman_conf" &>>"$__LOG_FILE"
			status="changed"
		else
			status="unchanged"
		fi

		__show_result "$status" "ILoveCandy"
		return $?
	}

	function __set_parallel_downloads() {
		declare value="$1"
		declare status

		__show_title "Set value of parallel downloads"

		if grep -qe "^ParallelDownloads = ${value}$" "$pacman_conf" &>>"$__LOG_FILE"; then
			status="keep"
		elif sed -i "s/^#\?\s*\(ParallelDownloads\).*/\1 = ${value}/" "$pacman_conf" &>>"$__LOG_FILE"; then
			status="changed"
		else
			status="unchanged"
		fi

		__show_result "$status" "ParallelDownloads = ${value}"
		return $?
	}

	function __enable_multilib_repo() {
		declare status

		__show_title "Enable multilib repository"

		if grep -qe '^\[[Mm]ultilib\]$' "$pacman_conf" &>>"$__LOG_FILE"; then
			status="keep"
		else
			declare -i line
			line=$(__get_line '\[[Mm]ultilib\]' "$pacman_conf")

			if {
				[ $line -gt 0 ] &&
					sed -i "${line}s/#\s*//" "$pacman_conf" &&
					((line++)) &&
					sed -i "${line}s/#\s*//" "$pacman_conf"
			} &>>"$__LOG_FILE"; then
				status="changed"
			else
				status="unchanged"
			fi
		fi

		__show_result "$status" "[multilib]"
		return $?
	}

	function __fix_file_permissions() {
		declare status

		__title "Fix permissions: $(__title_params "$pacman_conf")"

		if [[ $(stat -c "%a" "$pacman_conf") == 644 ]]; then
			__info "Permissions already fixed: $(__info_params "$pacman_conf")"
		elif chmod 644 "$pacman_conf" &>>"$__LOG_FILE"; then
			__success "Permissions fixed successfully: $(__success_params "$pacman_conf")"
		else
			__error "Error fixing permissions: $(__error_params "$pacman_conf")"
		fi

		return $?
	}

	function __update_repo_database() {
		__title "Updating repositories database"

		if pacman -Syy &>>"$__LOG_FILE"; then
			__success "Repositories database updated successfully"
		else
			__error "Error updating repositories database"
		fi
	}

	__enable_colors || return_code=1
	__enable_i_love_candy || return_code=1
	__set_parallel_downloads "$PACMAN_PARALLEL_DOWNLOADS" || return_code=1
	$PACMAN_ENABLE_MULTILIB && { __enable_multilib_repo || return_code=1; }
	__fix_file_permissions || return_code=1
	__update_repo_database || return_code=1

	return $return_code
}

function rate_mirrors() {
	declare reflector_conf="${__ROOT}/etc/xdg/reflector/reflector.conf"
	declare -a lines=(
		"--save /etc/pacman.d/mirrorlist"
		"--ipv4"
		"--ipv6"
		"--protocol https"
		"--country ${REFLECTOR_MIRROR_COUNTRIES}"
		"--latest ${REFLECTOR_MIRROR_LIMIT}"
		"--sort rate"
	)
	declare log_data="${REFLECTOR_MIRROR_LIMIT} mirros from ${REFLECTOR_MIRROR_COUNTRIES}"

	__title "Rating mirros: $(__title_params "$log_data")"

	if __add_lines_to_file "$reflector_conf" "w" false "${lines[@]}" &&
		systemctl start reflector.service &>>"$__LOG_FILE"; then
		__success "Mirrors were successfully rated: $(__success_params "$log_data")"
	else
		__error "Error rating mirrors: $(__error_params "$log_data")"
	fi

	return $?
}

function install_aurbuilder() {
	__title "Installing aurbuilder"

	if command -v aurbuilder &>>"$__LOG_FILE"; then
		__info "Aurbuilder already installed"
	elif { curl -L https://sirius-red.github.io/aurbuilder/install | sh -s -- --quiet; } &>>"$__LOG_FILE"; then
		__success "Aurbuilder installed successfully"
	else
		__error "Error installing aurbuilder"
	fi

	return $?
}

function install_aur_helper() {
	[ -n "$AUR_HELPER" ] || return 0

	__title "Installing AUR helper: $(__title_params "$AUR_HELPER")"

	if command -v "${AUR_HELPER/-bin/}" &>>"$__LOG_FILE"; then
		__AUR_HELPER_IS_INSTALLED=true
		__info "AUR helper already installed: $(__info_params "$AUR_HELPER")"
	elif __install_package "$AUR_HELPER"; then
		__AUR_HELPER_IS_INSTALLED=true
		__success "AUR helper installed successfully: $(__success_params "$AUR_HELPER")"
	else
		__error "Error installing AUR helper: $(__error_params "$AUR_HELPER")"
	fi

	return $?
}

function install_base_packages() {
	declare proceed=true
	declare -a base_pkglist=(
		"${__KERNEL_PKGLIST[@]}"
		"${__BASE_SYSTEM_PKGLIST[@]}"
	)

	function __remove_default_kernels() {
		if [[ "$__ROOT_FSTYPE" != btrfs || -n "$__ROOT_BTRFS_SUBVOL" ]]; then
			for entry in "$__ESP"/loader/entries/*.conf; do
				declare entry_path
				declare -i line_n

				entry_path="$(realpath "$entry" 2>>"${__LOG_FILE}")"
				line_n=$(__get_line '^# Created by: ArchZen' "$entry_path")

				if [ "$line_n" -ne 1 ]; then
					rm -rf "$entry_path" &>>"$__LOG_FILE"
				fi
			done
		fi

		while read -r k; do
			[[ "$k" == "$KERNEL" ]] && continue

			if __is_installed "$k"; then
				pacman -Rnsu --noconfirm "$k" &>>"$__LOG_FILE"
			fi

			[[ "$(__detect_bootloader)" != sdboot ]] && continue

			for entry in "$__ESP"/loader/entries/*.conf; do
				grep -qe "^linux.*initramfs-${k}[-fallback].img$" "$entry" || continue
				rm -f "$entry"
			done
		done < <(jq -r '.kernels[]' "${__ARCHZEN_RESOURCES_DIR}/archinstall-preset.json" | xargs)
	}

	__title "Removing default kernels"
	__remove_default_kernels
	__title "Installing base packages"
	__install_pkglist "${base_pkglist[@]}"

	return $?
}

function enable_cachyos_kit() {
	[[ "$ENABLE_CACHYOS_KIT" == true ]] || return 0

	declare success=false

	__title "Enabling CachyOS Kit"

	__install_cachyos_repo &&
		__rate_cachyos_mirrors &&
		__update_system &&
		__install_cachyos_packages &&
		success=true

	if $success; then
		__success "CachyOS Kit successfully enabled"
	else
		__error "Error enabling CachyOS Kit"
	fi

	return $?
}

function update_system() {
	[[ "$__SYSTEM_ALREADY_UPDATED" == true ]] && return

	__update_system
	return $?
}

function setup_bootloader() {
	declare bootloader="$1"
	declare gen_scripts="${2}"

	__check_type_alias BOOTLOADER "$bootloader"
	__check_type_alias BOOLEAN "$gen_scripts"

	[[ "$bootloader" == "auto" ]] && bootloader=$(__detect_bootloader)

	function __setup_bootloader() {
		declare sb_success=false

		__title "Configuring bootloader: $(__title_params "$bootloader")"

		case $bootloader in
		sdboot)
			__setup_sdboot && sb_success=true
			;;
		refind | grub | lilo)
			__warn "$(__yellow "setup_bootloader()") not implemented yet for: $(__warn_params "$bootloader")"
			return $?
			;;
		*)
			__warn "Unknown bootloader, skipping setup..."
			return $?
			;;
		esac

		if $sb_success; then
			__success "Bootloader configured successfully: $(__success_params "$bootloader")"
		else
			__error "Error configuring bootloader: $(__error_params "$bootloader")"
		fi
	}

	function __gen_scripts() {
		[[ $gen_scripts == true ]] || return

		declare gs_success=false

		__title "Generating bootloader script for: $(__title_params "$bootloader")"
		__gen_bootloader_update_script "$bootloader" &>>"$__LOG_FILE" && gs_success=true

		if $gs_success; then
			__success "Bootloader script generated successfully for: $(__success_params "$bootloader")"
		else
			__error "Error generating bootloader script for: $(__error_params "$bootloader")"
		fi
	}

	__setup_bootloader
	[[ "$GPU" != *nvidia* ]] && __enable_kernel_modules
	__gen_scripts

	return $?
}

function setup_os() {
	declare -i return_code=0

	function __set_os_specifications() {
		declare os_release="${__ROOT}/etc/os-release"
		declare -a lines=(
			'NAME="Arch Linux"'
			'PRETTY_NAME="Arch Linux"'
			'ID=arch'
			'ID_LIKE=arch'
			'BUILD_ID=rolling'
			'ANSI_COLOR="38;2;23;147;209"'
			'HOME_URL="https://archlinux.org/"'
			'DOCUMENTATION_URL="https://wiki.archlinux.org/"'
			'SUPPORT_URL="https://bbs.archlinux.org/"'
			'BUG_REPORT_URL="https://bugs.archlinux.org/"'
			'LOGO=archlinux'
		)

		__title "Set OS specifications"

		if __add_lines_to_file "$os_release" w false "${lines[@]}"; then
			__success "OS specifications setted successfully"
		else
			__error "Error setting OS specifications"
		fi

		return $?
	}

	__set_default_shell() {
		declare proceed=true

		__title "Changing the shell to: $(__title_params "$USER_SHELL")"

		if ! __is_installed "$USER_SHELL"; then
			proceed=false

			__warn "The user-defined shell was not installed. Trying to install: $(__warn_params "$USER_SHELL")"

			if __install_package "$USER_SHELL"; then
				proceed=true

				__success "User-defined shell installed successfully: $(__success_params "$USER_SHELL")"
			else
				__error "Error installing user-defined shell: $(__error_params "$USER_SHELL")"
			fi
		fi

		$proceed || return 1

		declare shell_path
		shell_path=$(which "$USER_SHELL")

		if ! grep -qe "^${shell_path}$" "${__ROOT}/etc/shells" &>>"$__LOG_FILE"; then
			proceed=false

			__title "Adding the ${USER_SHELL} path to ${__ROOT}/etc/shells: $(__title_params "$shell_path")"

			if __add_lines_to_file "${__ROOT}/etc/shells" a false "$shell_path"; then
				proceed=true

				__success "${USER_SHELL} path added to ${__ROOT}/etc/shells: $(__success_params "$shell_path")"
			else
				__error "Error adding the ${USER_SHELL} path to ${__ROOT}/etc/shells: $(__error_params "$shell_path")"
			fi
		fi

		if $proceed && chsh -s "$(which "$USER_SHELL")" "$__USER_NAME"; then
			__success "Shell changed successfully to: $(__success_params "$USER_SHELL")"
		else
			__error "Error changing shell to: $(__error_params "$USER_SHELL")"
		fi

		return $?

	}

	__set_os_specifications || return_code=1
	[ -n "$USER_SHELL" ] && { __set_default_shell || return_code=1; }

	return $return_code
}

function install_other_packages() {
	declare -a pkglist=(
		"${__FILESYSTEM_PKGLIST[@]}"
		"${__NETWORK_PKGLIST[@]}"
		"${__BLUETOOTH_PKGLIST[@]}"
		"${__HARDWARE_PKGLIST[@]}"
		"${__PACKAGE_MANAGER_PKGLIST[@]}"
		"${__TERMINAL_PKGLIST[@]}"
		"${__DEVELOPMENT_PKGLIST[@]}"
		"${__VIRTUALIZATION_PKGLIST[@]}"
		"${__MULTIMEDIA_PKGLIST[@]}"
		"${__FONTS_PKGLIST[@]}"
		"${__OTHERS_PKGLIST[@]}"
	)

	__title "Installing all other packages"
	__install_pkglist "${pkglist[@]}"
	__is_installed virt-manager && {
		__SERVICES_TO_ENABLE+=(libvirtd)
		__USER_GROUPS+=(libvirt kvm)
	}

	return $?
}

function install_gpu_drivers() {
	[ -n "$GPU" ] || return

	declare success=false

	function __chwd() {
		__is_installed chwd || return 1
		chwd -a &>>"$__LOG_FILE"
		return $?
	}

	__title "Installing GPU drivers: $(__title_params "$GPU")"

	if __chwd; then
		success=true
	else
		case $GPU in
		nvidia) __install_pkglist "${__NVIDIA_PKGLIST[@]}" && success=true ;;
		nvidia-open) __install_pkglist "${__NVIDIA_OPEN_PKGLIST[@]}" && success=true ;;
		nvidia-535xx) __install_pkglist "${__NVIDIA_535XX_PKGLIST[@]}" && success=true ;;
		nvidia-470xx) __install_pkglist "${__NVIDIA_470XX_PKGLIST[@]}" && success=true ;;
		nvidia-390xx) __install_pkglist "${__NVIDIA_390XX_PKGLIST[@]}" && success=true ;;
		nouveau) __install_pkglist "${__NOUVEAU_PKGLIST[@]}" && success=true ;;
		amd) __install_pkglist "${__AMD_PKGLIST[@]}" && success=true ;;
		intel) __install_pkglist "${__INTEL_PKGLIST[@]}" && success=true ;;
		*)
			__error "Invalid GPU value: $(__error_params "$GPU")"
			;;
		esac
	fi

	__enable_kernel_modules

	if $success; then
		__success "GPU drivers installed successfully: $(__success_params "$GPU")"
	else
		__error "Error installing GPU drivers: $(__error_params "$GPU")"
	fi

	return $?
}

function install_desktop_profile() {
	declare displaymgr
	declare -a pkglist=()
	declare success=false
	declare is_displaymgr_service_enabled=false
	declare proceed=true
	declare -i exit_code=0

	case $DESKTOP_PROFILE in
	xorg)
		pkglist=("${__XORG_PKGLIST[@]}")
		;;
	xorg-minimal)
		pkglist+=("${__XORG_MINIMAL_PKGLIST[@]}")
		;;
	gnome)
		displaymgr="gdm"
		pkglist+=("${__GNOME_PKGLIST[@]}" "$displaymgr")

		function __setup_desktop_profile() {
			__install_gnome_extensions

			cp -f "$__ARCHZEN_GNOME_MIMEAPPS_LIST_FILE" "${__USER_HOME}/.config/mimeapps.list" &>>"$__LOG_FILE" &&
				__takeown "${__USER_HOME}/.config/mimeapps.list"
		}
		;;
	plasma)
		displaymgr="sddm"
		pkglist+=("${__PLASMA_PKGLIST[@]}" "$displaymgr")

		function __setup_desktop_profile() {
			__set_sddm_settings
		}
		;;
	hyprland)
		pkglist+=("${__HYPRLAND_PKGLIST[@]}")
		__WARN_MESSAGES+=("Hyperland automatic setup has not yet been implemented. Run $(__warn_params '`archzen hypr`') $(__error_params '>>>BEFORE<<<') the system reboot")
		;;
	*)
		proceed=false
		__error "Invalid DESKTOP_PROFILE value: $(__error_params "$DESKTOP_PROFILE")"
		;;
	esac

	if $proceed; then
		pkglist+=("${__DE_COMMON_PKGLIST[@]}")
		__title "Installing Desktop Profile: $(__title_params "$DESKTOP_PROFILE")"

		{
			if [ "${#pkglist[@]}" -gt 0 ]; then
				__install_pkglist "${pkglist[@]}"
			else
				true
			fi
		} &&
			{
				if [ -n "$displaymgr" ]; then
					systemctl enable "${displaymgr}.service" &>>"$__LOG_FILE" &&
						is_displaymgr_service_enabled=true
				fi
				true
			} &&
			{
				if __func_exists __setup_desktop_profile; then
					__setup_desktop_profile
				fi
				true
			} &&
			success=true
	fi

	if $success; then
		__success "Desktop Profile installed successfully"
	else
		__error "No desktop profile will be installed! Install manually after system installation is complete."
	fi

	exit_code=$?
	[ -n "$displaymgr" ] || return $exit_code

	if $is_displaymgr_service_enabled; then
		__success "The ${displaymgr} service was successfully enabled"
	else
		__warn "The ${displaymgr} service has not been enabled"
	fi

	return $exit_code
}

function setup_hyprland() {
	declare action="$1"
	declare hyde_dir="${__ROOT}/tmp/archzen/hyde"
	declare -i return_code=1

	function __clone_hyde_repo() {
		declare hyde_repo="https://github.com/HyDE-Project/HyDE.git"

		rm -rf "$hyde_dir" &>>"$__LOG_FILE"
		mkdir -p "$(dirname "$hyde_dir")" &>>"$__LOG_FILE"
		git clone --depth 1 "$hyde_repo" "$hyde_dir" &&
			[ -d "$hyde_dir" ] &&
			__takeown "$hyde_dir" &&
			return 0

		__error "Error cloning the $(__error_params 'HyDE Project') git repository"
		return 1
	}

	function __apply_hyde_blacklist_filter() {
		declare type="$1"
		shift
		declare -a blacklist=("$@")
		declare file

		case "$type" in
		package)
			file="$(realpath "${hyde_dir}/Scripts/pkg_core.lst" 2>>"${__LOG_FILE}")"
			;;
		service)
			file="$(realpath "${hyde_dir}/Scripts/system_ctl.lst" 2>>"${__LOG_FILE}")"
			;;
		*)
			__error "Invalid blacklist item type: $(__error_params "$type")"
			return 1
			;;
		esac

		for item in "${blacklist[@]}"; do
			declare -i line=0
			declare file_name

			line=$(__get_line "^${item}\s.*" "$file" 2>>"$__LOG_FILE")
			[ $line -eq 0 ] && line=$(__get_line "^${item}$" "$file" 2>>"$__LOG_FILE")
			file_name="$(basename "$file" 2>>"$__LOG_FILE")"

			__print "$(__info "Trying to remove the ${type} $(__info_params "$item") from $(__info_params "$file_name")")..."

			if [ ! -f "$file" ]; then
				__print -rn "$(__error "Trying to remove the ${type} $(__error_params "$item") from $(__error_params "$file_name")")... $(__error_params 'File not found!')"
			elif [ $line -gt 0 ]; then
				if sed -i "${line}d" "$file" &>>"$__LOG_FILE"; then
					__print -rn "$(__success "Trying to remove the ${type} $(__success_params "$item") from $(__success_params "$file_name")")... $(__success_params 'Success!')"
				else
					__print -rn "$(__error "Trying to remove the ${type} $(__error_params "$item") from $(__error_params "$file_name")")... $(__error_params 'Error in `sed` command!')"
				fi
			else
				__print -n " $(__info_params 'Skipped!')"
			fi
		done
	}

	function __hyde_installer() {
		declare hyde_args="-${1}"

		cd "$hyde_dir/Scripts" &&
			sudo -EHu "$__USER_NAME" ./install.sh "$hyde_args" &&
			return 0

		return 1
	}

	function __install_hyde() {
		__hyde_installer drsn && return 0

		__error "Error installing $(__error_params 'HyDE Project')"
		return 1
	}

	function __apply_hyprland_settings() {
		declare target_config_dir="${__USER_HOME}/.config"
		declare -a config_files=()
		declare success=false

		mv -f "${__ARCHZEN_DOTFILES_DIR}/.config/kitty" "${__ARCHZEN_DOTFILES_DIR}/!.config/kitty" &>>"$__LOG_FILE"
		mv -f "${__ARCHZEN_DOTFILES_DIR}/.config/fish" "${__ARCHZEN_DOTFILES_DIR}/!.config/fish" &>>"$__LOG_FILE"

		cd "${__ARCHZEN_DOTFILES_DIR}/!.config" &&
			mapfile -t config_files < <(find ./hypr ./kitty ./fish -type f -print 2>>"$__LOG_FILE")

		if __is_installed visual-studio-code-bin ||
			__is_installed code ||
			__is_installed vscodium ||
			__is_installed vscodium-bin; then
			__HYPR_TEMPLATE_VALUES[EDITOR]='code'
		fi

		for file in "${config_files[@]}"; do
			declare final_path
			final_path="$(realpath "${target_config_dir}/${file}" 2>>"${__LOG_FILE}")"

			[ -f "$file" ] || continue
			[[ "$file" =~ fish/ && -f "$final_path" ]] && continue

			cp -f --parents "$file" "$target_config_dir" &>>"$__LOG_FILE" &&
				__apply_template_values __HYPR_TEMPLATE_VALUES "$final_path"
		done && success=true

		$success && __takeown "$__USER_HOME" && return 0

		__error "Error applying $(__error_params 'Hyprland Settings')"
		return 1
	}

	function __create_hyprinit {
		declare script_name="hyprinit"
		declare -a script_lines=(
			'#!/usr/bin/env bash'
			''
			'if [[ -z "$DISPLAY" && "$(tty)" =~ /dev/tty[0-9] ]]; then'
			'	exec Hyprland'
			'fi'
		)

		__print "$(__title "Creating $(__title_params hyprinit) helper...")"

		if __save_script "$script_name" true "${script_lines[@]}" &>>"$__LOG_FILE"; then
			__print -rn "$(__success "Creating $(__success_params hyprinit) helper... $(__success_params 'Success!')")"
			return 0
		else
			__WARN_MESSAGES+=("Error creating the $(__warn_params hyprinit) helper. Runs $(__warn_params '`Hyprland`') command manually after login from TTY!")
			__print -rn "$(__error "Creating $(__error_params hyprinit) helper... $(__error_params 'Error!')")"
			return 1
		fi
	}

	function __add_hyprinit_to_shell_profile() {
		declare shell_profile="${__SHELL_PROFILES[default]}"
		declare -a script_lines=(hyprinit)
		declare success=false

		if __check_type_alias -s SHELL_PROFILES "$USER_SHELL"; then
			shell_profile="${__SHELL_PROFILES[$USER_SHELL]}"
		fi

		__print "$(__title "Adding $(__title_params hyprinit) to $(__title_params "$USER_SHELL") profile...")"

		if grep -qe 'hyprinit' "$shell_profile" &>>"$__LOG_FILE"; then
			__print -rn "$(__info "Adding $(__info_params hyprinit) to $(__info_params "$USER_SHELL") profile... $(__info_params 'Skipped!')")"
		elif ! command -v hyprinit &>>"$__LOG_FILE"; then
			__print -rn "$(__error "$(__error_params hyprinit) helper not found in $(__error_params "$__BIN_DIR")!")"
		elif __add_lines_to_file "$shell_profile" a true "${script_lines[@]}" &>>"$__LOG_FILE" && __takeown "$shell_profile"; then
			success=true
			__print -rn "$(__success "Adding $(__success_params hyprinit) to $(__success_params "$USER_SHELL") profile... $(__success_params 'Success!')")"
		else
			__print -rn "$(__error "Adding $(__error_params hyprinit) to $(__error_params "$USER_SHELL") profile... $(__error_params 'Error!')")"
		fi

		$success && return 0

		__WARN_MESSAGES+=("Error adding $(__warn_params hyprinit) helper to yout shell profile. Runs $(__warn_params '`hyprinit`') command manually after login from TTY!")
		return 1
	}

	case "$action" in
	setup)
		if __clone_hyde_repo; then
			__apply_hyde_blacklist_filter package "${__HYDE_PACKAGE_BLACKLIST[@]}"
			__apply_hyde_blacklist_filter service "${__HYDE_SERVICE_BLACKLIST[@]}"

			if __install_hyde; then
				__apply_hyprland_settings
				__create_hyprinit && __add_hyprinit_to_shell_profile
				return_code=0
				__INFO_MESSAGES+=("After starting Hyprland, run $(__info_params '`SUPER`') $(__bold +) $(__info_params '`/`') to see all the $(__info_params keybindings).")
			fi
		fi
		;;
	update)
		if __clone_hyde_repo; then
			__apply_hyde_blacklist_filter package "${__HYDE_PACKAGE_BLACKLIST[@]}"
			__apply_hyde_blacklist_filter service "${__HYDE_SERVICE_BLACKLIST[@]}"

			if __install_hyde; then
				__apply_hyprland_settings
				return_code=0
				__INFO_MESSAGES+=("After starting Hyprland, run $(__info_params '`SUPER`') $(__bold +) $(__info_params '`/`') to see all the $(__info_params keybindings).")
			fi
		fi
		;;
	init)
		if __create_hyprinit; then
			__add_hyprinit_to_shell_profile
			return_code=0
		fi
		;;
	settings)
		__clone_hyde_repo &&
			__hyde_installer rnm &&
			__apply_hyprland_settings &&
			return_code=0
		;;
	*)
		__error "$(__error_params 'setup_hyprland()'): Invalid action: $(__error_params "$action")"
		;;
	esac

	return $return_code
}

function setup_dotfiles() {
	__is_installed_archzen || install_archzen || return 1

	declare -i installed_count=0
	declare -i total_count=0
	declare -a items=()
	declare -a not_installed_items=()

	{
		if [[ "$DESKTOP_PROFILE" == hyprland ]]; then
			mv -f "${__ARCHZEN_DOTFILES_DIR}/.config/fastfetch" "${__ARCHZEN_DOTFILES_DIR}/!.config/fastfetch"
			mv -f "${__ARCHZEN_DOTFILES_DIR}/.config/kitty" "${__ARCHZEN_DOTFILES_DIR}/!.config/kitty"
			mv -f "${__ARCHZEN_DOTFILES_DIR}/.config/fish" "${__ARCHZEN_DOTFILES_DIR}/!.config/fish"
		else
			mv -f "${__ARCHZEN_DOTFILES_DIR}/!.config/fastfetch" "${__ARCHZEN_DOTFILES_DIR}/.config/fastfetch"
			mv -f "${__ARCHZEN_DOTFILES_DIR}/!.config/kitty" "${__ARCHZEN_DOTFILES_DIR}/.config/kitty"
			mv -f "${__ARCHZEN_DOTFILES_DIR}/!.config/fish" "${__ARCHZEN_DOTFILES_DIR}/.config/fish"
		fi
	} &>>"$__LOG_FILE"

	cd "$__ARCHZEN_DOTFILES_DIR" &&
		mapfile -t items < <(find . -path './!*' -prune -o -type f -print 2>>"$__LOG_FILE")
	total_count+=${#items[@]}

	for i in "${items[@]}"; do
		declare final_path="${__USER_HOME}/${i}"

		cp -f --parents "$i" "$__USER_HOME" &>>"$__LOG_FILE" &&
			__takeown "$final_path" &&
			{
				# This is necessary to be in a block without `&&` because the increment `((installed_count++))`
				# returns `1` as an exit code when made in a variable whose initial value is `0`.
				((installed_count++))
				continue
			}

		not_installed_items+=("$i")
	done

	declare result_txt="(${installed_count}/${total_count}) files"

	if [ $installed_count -eq $total_count ]; then
		__success "Dotfiles items successfully installed: $(__success_params "$result_txt")"
	elif [ $installed_count -gt 0 ]; then
		__success "Dotfiles items installation finished with some errors: $(__warn_params "$result_txt")"
	else
		__error "Error installing dotfiles: $(__error_params "$result_txt")"
	fi

	declare -i exit_code=$?

	if [ $installed_count -ne $total_count ]; then
		printf 'Dotfiles items not installed:\n%s%s' '  - ' "${not_installed_items[@]}"
	fi

	__takeown "$__USER_HOME"

	return $exit_code
}

function setup_vscode() {
	__is_installed_archzen || install_archzen || return 1

	declare code_folder
	if __is_installed visual-studio-code-bin; then
		code_folder='Code'
	elif __is_installed code; then
		code_folder='Code - OSS'
	elif __is_installed vscodium || __is_installed vscodium-bin; then
		code_folder='VSCodium'
	else
		return
	fi

	declare -i installed_extensions total_extensions applied_files total_files exit_code
	declare extensions_result_text settings_result_text

	__title "Setting up VS Code"

	function __install_extensions() {
		installed_extensions=0
		total_extensions=${#__VSCODE_EXTENSIONS[@]}
		extensions_result_text="$(__info_params "(${installed_extensions}/${total_extensions})")"

		for ext in "${__VSCODE_EXTENSIONS[@]}"; do
			declare name id
			name="$(echo "$ext" | cut -d':' -f1)"
			id="$(echo "$ext" | cut -d':' -f2)"

			__reset_line
			printf "%sInstalling %s... Installed extensions: %s" "$(__info)" "$name" "$extensions_result_text"

			{
				sudo -EHu "$__USER_NAME" code --install-extension "$id" --force &&
					((installed_extensions++))
			} &>>"$__LOG_FILE"

			extensions_result_text="$(__info_params "(${installed_extensions}/${total_extensions})")"
		done

		extensions_result_text="(${installed_extensions}/${total_extensions})"
	}

	function __apply_settings() {
		applied_files=0
		declare nsmvsc_dir="$__ARCHZEN_DOTFILES_DIR/!.config/not-so-minimal-vscode"
		declare nsmvsc_tmp_dir="${__ROOT}/tmp/not-so-minimal-vscode"
		declare -a files=()
		declare -a not_applied_files=()
		declare result_message=""

		{
			if [[ "$DESKTOP_PROFILE" != hyprland ]]; then
				[ -d "$nsmvsc_tmp_dir" ] && rm -rf "$nsmvsc_tmp_dir"
				[ -d "$nsmvsc_dir" ] && rm -rf "$nsmvsc_dir"
				git clone https://github.com/sirius-red/not-so-minimal-vscode.git "$nsmvsc_tmp_dir"
				cp -rf "$nsmvsc_tmp_dir/settings" "$nsmvsc_dir"
			fi
		} &>>"$__LOG_FILE"

		cd "$__ARCHZEN_DOTFILES_DIR/!.config" &&
			mapfile -t files < <(find './Code' './not-so-minimal-vscode' -type f -print 2>>"$__LOG_FILE")

		total_files=${#files[@]}
		settings_result_text="$(__info_params "(${applied_files}/${total_files})")"

		for f in "${files[@]}"; do
			f="${f/\/Code/\/$code_folder}"
			declare final_path="${__USER_HOME}/.config/${f}"

			__reset_line
			printf "%sApplying settings: %s" "$(__info)" "$settings_result_text"

			cp -f --parents "$f" "${__USER_HOME}/.config" &>>"$__LOG_FILE" &&
				__takeown "$final_path" &&
				{
					((applied_files++))
					settings_result_text="$(__info_params "(${applied_files}/${total_files})")"
					continue
				}

			not_applied_files+=("$f")
		done

		settings_result_text="(${applied_files}/${total_files})"
	}

	__install_extensions
	__reset_line
	__apply_settings
	__reset_line
	__apply_template_values __VSCODE_TEMPLATE_VALUES "${__USER_HOME}/.config/${code_folder}/User/settings.json"
	__takeown /opt/visual-studio-code

	if [[ $installed_extensions -eq $total_extensions && $applied_files -eq $total_files ]]; then
		result_message="$(__success)VS Code configured successfully: Extensions $(__success_params "$extensions_result_text") | Settings $(__success_params "$settings_result_text")"
		exit_code=0
	elif [[ $installed_extensions -gt 0 || $applied_files -gt 0 ]]; then
		result_message="$(__warn)VS Code configured with some errors: Extensions $(__warn_params "$extensions_result_text") | Settings $(__warn_params "$settings_result_text")"
		exit_code=0
	else
		result_message="$(__error)Error configuring VS Code: Extensions $(__error_params "$extensions_result_text") | Settings $(__error_params "$settings_result_text")"
		exit_code=1
	fi

	__reset_line
	printf "%s\n" "$result_message"
	__info "After starting the VS Code for the first time, run the command \`$(__info_params "Enable Custom CSS and JS Loader")\`"

	__takeown "$__USER_HOME"

	return $exit_code
}

function enable_services() {
	declare -i enabled_count=0
	declare -i total_count=${#__SERVICES_TO_ENABLE[@]}

	[ $total_count -eq 0 ] && return

	declare result_text=""
	declare -a not_enabled_services=()

	__title "Enabling services"

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((enabled_count += increment))
		result_text="(${enabled_count}/${total_count}) services"

		case "$log_type" in
		title) result_text="$(__title_params "$result_text")" ;;
		info) result_text="$(__info_params "$result_text")" ;;
		success) result_text="$(__success_params "$result_text")" ;;
		warn) result_text="$(__warn_params "$result_text")" ;;
		error) result_text="$(__error_params "$result_text")" ;;
		*) result_text="$(__bold "$result_text")" ;;
		esac
	}

	__update_result_text 0 info

	for service in "${__SERVICES_TO_ENABLE[@]}"; do
		__reset_line
		printf '%sEnabling service %s... %s' "$(__info)" "$service" "$result_text"

		if systemctl enable "$service" &>>"$__LOG_FILE"; then
			__update_result_text 1 info
		else
			not_enabled_services+=("$service")
			__update_result_text 0 warn
		fi
	done

	__reset_line
	if [ $enabled_count -eq $total_count ]; then
		__update_result_text 0 success
		printf '%s\t%s\n' "$(__success 'Services enabled successfully.')" "$result_text"
	elif [ $enabled_count -gt 0 ]; then
		__update_result_text 0 warn
		printf '%s\t%s\n' "$(__warn 'Services enabled with some errors.')" "$result_text"
	else
		__update_result_text 0 error
		printf '%s\t%s\n' "$(__error 'Error enabling services.')" "$result_text"
	fi

	if [ $enabled_count -ne $total_count ]; then
		printf 'Services not enabled:\n%s%s' '  - ' "${not_enabled_services[@]}"
	fi

	return $?
}

function add_user_groups() {
	declare -i added_count=0
	declare -i total_count=${#__USER_GROUPS[@]}

	[ $total_count -eq 0 ] && return

	declare result_text=""
	declare -a not_added_groups=()

	__title "Adding user to groups"

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((added_count += increment))
		result_text="(${added_count}/${total_count}) groups"

		case "$log_type" in
		title) result_text="$(__title_params "$result_text")" ;;
		info) result_text="$(__info_params "$result_text")" ;;
		success) result_text="$(__success_params "$result_text")" ;;
		warn) result_text="$(__warn_params "$result_text")" ;;
		error) result_text="$(__error_params "$result_text")" ;;
		*) result_text="$(__bold "$result_text")" ;;
		esac
	}

	__update_result_text 0 info

	for group in "${__USER_GROUPS[@]}"; do
		__reset_line
		printf '%sAdding user to group %s... %s' "$(__info)" "$group" "$result_text"

		if usermod -aG "$group" "$__USER_NAME" &>>"$__LOG_FILE"; then
			__update_result_text 1 info
		else
			not_added_groups+=("$group")
			__update_result_text 0 warn
		fi
	done

	__reset_line
	if [ $added_count -eq $total_count ]; then
		__update_result_text 0 success
		printf '%s\t%s\n' "$(__success 'User added to groups successfully.')" "$result_text"
	elif [ $added_count -gt 0 ]; then
		__update_result_text 0 warn
		printf '%s\t%s\n' "$(__warn 'User added to groups with some errors.')" "$result_text"
	else
		__update_result_text 0 error
		printf '%s\t%s\n' "$(__error 'Error adding user to groups.')" "$result_text"
	fi

	if [ $added_count -ne $total_count ]; then
		printf 'Groups not added:\n%s%s' '  - ' "${not_added_groups[@]}"
	fi

	return $?
}

function setup_archlinux() {
	if ! __is_installed_initial_os_setup; then
		setup_sudoers || return $?
		setup_zram || return $?
		setup_pacman || return $?
		rate_mirrors || return $?
		touch "$__VAR_INITIAL_OS_SETUP_INSTALLED" || return $?
	fi

	install_aurbuilder || return $?
	install_aur_helper || return $?
	install_base_packages || return $?
	enable_cachyos_kit || return $?
	update_system || return $?
	setup_bootloader auto true
	setup_os
	install_other_packages
	install_gpu_drivers
	install_desktop_profile
	setup_dotfiles
	setup_vscode
	enable_services
	add_user_groups
}

function show_help() {
	echo -e "$(
		cat <<EOL
$(show_version)

$(__bold_underline USAGE:)
$(__tab 1) $(__purple archzen) $(__bright_blue '<command>') $(__yellow '[<args> ...]')

$(__bold_underline INSTALLATION COMMANDS:)
$(__tab 1)$(__bright_blue install), $(__bright_blue i)$(__tab 2)Starts the archinstall script with a minimal preset.
$(__tab 4)$(__white '(It also installs archzen and runs all setup commands on first login)')
$(__tab 1)$(__bright_blue self-install), $(__bright_blue si)$(__tab 1)Installs Archzen on the system.
$(__tab 4)$(__white '(Some setup commands will not work if archzen is not installed)')

$(__bold_underline SETUP COMMANDS:)
$(__tab 1)$(__bright_blue arch), $(__bright_blue a)$(__tab 3)Setup an already installed Arch Linux with Archzen's customizations.
$(__tab 1)$(__bright_blue zram), $(__bright_blue z)$(__tab 3)Setup zram no system.
$(__tab 1)$(__bright_blue bootloader), $(__bright_blue b)$(__tab 2)Setup the "systemd-boot" bootloader, including hooks and scripts for update.
$(__tab 4)$(__white "(Usage: $(__purple archzen) $(__bright_blue b) $(__yellow '<bootloader>') $(__yellow '<gen_scripts>'))")
$(__tab 4)$(__white "(Bootloaders: $(__yellow "${__TYPE_ALIASES[BOOTLOADER]}"))")
$(__tab 4)$(__white "(Generate update scripts: $(__yellow "${__TYPE_ALIASES[BOOLEAN]}"))")
$(__tab 1)$(__bright_blue desktop-profile), $(__bright_blue dp)$(__tab 1)Installs the defined desktop profile.
$(__tab 4)$(__white "(Usage: $(__purple archzen) $(__bright_blue dp) $(__yellow '[desktop_profile]'))")
$(__tab 4)$(__white "(Desktop profiles: $(__yellow "${__TYPE_ALIASES[DESKTOP_PROFILE]}"))")
$(__tab 4)$(__white "(Default: $(__yellow "$DESKTOP_PROFILE"))")
$(__tab 1)$(__bright_blue hyprland), $(__bright_blue hypr)$(__tab 2)Setup Hyprland.
$(__tab 1)$(__bright_blue dotfiles), $(__bright_blue d)$(__tab 2)Copies Archzen's dotfiles to ~/.config.
$(__tab 1)$(__bright_blue vscode), $(__bright_blue vsc)$(__tab 2)Setup VS Code settings, keymaps and extensions.

$(__bold_underline UTILITIES COMMANDS:)
$(__tab 1)$(__bright_blue version), $(__bright_blue v)$(__tab 2)Show the script version.
$(__tab 1)$(__bright_blue help), $(__bright_blue h)$(__tab 3)Show this help message.

$(__bold_underline DEV COMMANDS:) $(__white '(This command is only for development!)')
$(__tab 1)$(__bright_blue func), $(__bright_blue f)$(__tab 3)Runs any existing function in the script

Made with $(__bright_red "<3"), headache, coffee and $(__bright_green weed) by $(__red Sirius Red)\n
EOL
	)"
}

function show_version() {
	echo "ArchZen $(__bright_green "v${__VERSION}")"
}

function init() {
	declare -a banner_args=(
		"bright-cyan"
		"purple"
		"#"
		"ArchZen - Stay Zen and install Arch"
		"author:Sirius Red"
		"project_url:https://github.com/sirius-red/archzen"
		"license:GPLv3"
		"ref:https://wiki.archlinux.org"
		"ref:https://www.gnu.org/licenses/gpl-3.0.html"
	)

	clear
	__banner "${banner_args[@]}"
}

function run() {
	declare command="$1"
	shift 1
	declare -a args=("$@")

	__COMMAND_ARG="$command"

	case $command in
	install | i)
		install_archlinux &&
			__REBOOT_SYSTEM=true
		;;
	self-install | si)
		install_archzen
		;;
	arch | a)
		if setup_archlinux && [[ "$DESKTOP_PROFILE" != hyprland ]]; then
			__REBOOT_SYSTEM=true
		else
			__REBOOT_SYSTEM=false
		fi
		;;
	bootloader | b)
		declare bootloader="${args[0]}"
		declare gen_scripts="${args[1]}"

		setup_bootloader "$bootloader" "$gen_scripts" &&
			__REBOOT_SYSTEM=true
		;;
	zram | z)
		SETUP_ZRAM=true

		setup_zram &&
			__REBOOT_SYSTEM=true
		;;
	desktop-profile | dp)
		declare desktop_profile="${args[0]}"

		if [ -n "$desktop_profile" ] && __check_type_alias -s DESKTOP_PROFILE "$desktop_profile"; then
			export DESKTOP_PROFILE
			DESKTOP_PROFILE="$desktop_profile"
		elif [ -n "$desktop_profile" ]; then
			__error "Invalid argument for $(__error_params "\`${command}\`"): $(__error_params "$desktop_profile")"
			return 1
		fi

		if install_desktop_profile && [[ "$DESKTOP_PROFILE" != hyprland ]]; then
			__REBOOT_SYSTEM=true
		else
			__REBOOT_SYSTEM=false
		fi
		;;
	hyprland | hypr)
		declare action="${args[0]:-setup}"

		setup_hyprland "$action" &&
			[[ "$action" == setup ]] &&
			__FORCE_REBOOT_SYSTEM=true
		;;
	dotfiles | d)
		setup_dotfiles
		;;
	vscode | vsc)
		setup_vscode
		;;
	func | f)
		if ! __func_exists "${args[0]}"; then
			__error "Function not exists: $(__error_params "${args[0]}")"
			exit 1
		fi

		"${args[@]}"
		;;
	version | v)
		show_version
		;;
	help | h)
		show_help
		;;
	*)
		__error "Unknown command: $(__error_params "$command")"
		show_help
		exit 1
		;;
	esac
}

function finish() {
	declare quiet=$__QUIET

	__QUIET=true
	__log "" ""
	__info "Packages already installed before the setup execution:"
	for package in "${__ALREADY_INSTALLED_PKGLIST[@]}"; do
		__log "	- $package" "	- $(__info_params "$package")"
	done
	__log "" ""
	__warn "Packages not installed:"
	for package in "${__NOT_INSTALLED_PKGLIST[@]}"; do
		__log "	- $package" "	- $(__warn_params "$package")"
	done
	__QUIET=$quiet

	__show_log_msglist info "${__INFO_MESSAGES[@]}"
	__show_log_msglist warn "${__WARN_MESSAGES[@]}"
	__log "" ""

	if __variable_file_exists __VAR_FIRST_LOGIN_RUN; then
		rm -rf "$(realpath "$__FIRST_LOGIN_SCRIPT" 2>>"${__LOG_FILE}")" &>>"${__LOG_FILE}"
	fi

	if $__FORCE_REBOOT_SYSTEM; then
		while [ $__FORCE_REBOOT_SYSTEM_TIME -ge 0 ]; do
			trap echo EXIT INT

			__reset_line
			printf '\r%s' "$(__warn "The system will reboot automatically in $(__warn_params $__FORCE_REBOOT_SYSTEM_TIME) seconds. Press $(__warn_params 'CTRL+C') to cancel")"

			[ $__FORCE_REBOOT_SYSTEM_TIME -eq 0 ] && reboot --force

			((__FORCE_REBOOT_SYSTEM_TIME -= 1))
			sleep 1
		done
	fi

	if $__REBOOT_SYSTEM && __confirm "A system restart is required for the changes to take effect, do you want to restart now?"; then
		reboot
	fi
}

__set_global_variables "${CHDIR:-/}" "${FORCE:-false}" "${ARCHZEN_IS_RUNNING_FROM_BINARY:-false}"

if ! __is_valid_semver "$__VERSION"; then
	__error "Invalid semanthic version: $(__error_params "$__VERSION")"
	exit 1
fi

if [[ "$ARCHZEN_PROCESS_ENV" == development ]]; then
	run "$@"
	exit $?
fi

if __is_main_module; then
	if [[ ! "$1" =~ ^install$|^i$|^self-install$|^si$|^help$|^h$|^version$|^v$ ]]; then
		if ! command -v archzen &>>"$__LOG_FILE"; then
			echo
			__error "The \`$(__error_params "$1")\` command is only available after the installation of ArchZen"
			__info "Runs \`$(__info_params "sudo ${__THIS_SCRIPT} self-install")\` first"
			echo
			exit 1
		fi

		if ! $__ARCHZEN_IS_RUNNING_FROM_BINARY; then
			echo
			__error "Do not run the command \`$(__error_params "$1")\` through this script"
			__info "Runs \`$(__info_params "archzen $*")\`"
			echo
			exit 1
		fi
	fi

	if [[ "$1" =~ ^version$|^v$|^help$|^h$ || -z "$1" ]]; then
		run "$@" || __EXIT_CODE=$?
		exit $__EXIT_CODE
	fi

	if [[ $EUID -ne 0 ]]; then
		__error "$(__error_params ArchZen) must be run as root"
		exit 1
	fi

	init || __EXIT_CODE=$?
	run "$@" || __EXIT_CODE=$?
	finish
	exit $__EXIT_CODE
fi
