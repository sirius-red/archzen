#!/usr/bin/env bash

# Delay to reboot system automatically in seconds
declare -xi __FORCE_REBOOT_SYSTEM_TIME=5

declare -x CONFMGR_ENABLE_BACKUP=false

declare -x \
	__EXIT_CODE=0 \
	__REBOOT_SYSTEM=false \
	__MOUNT_DIR="/mnt/archinstall" \
	__FORCE_REBOOT_SYSTEM=false \
	__IS_WSL=false \
	__WSL_CONF="/etc/wsl.conf" \
	__LOG_FILE \
	__COMMAND_ARG \
	__ARCHZEN_IS_RUNNING_FROM_BINARY \
	__ROOT \
	__PWD \
	__THIS_SCRIPT \
	__QUIET \
	__ARCHINSTALL_PRESET \
	__USERNAME \
	__USERHOME \
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
	__VAR_DEPENDENCIES_INSTALED \
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
	__DEPENDENCIES \
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
	__WSL_PKGLIST \
	__WSL_GUI_PKGLIST \
	__GNOME_EXTENSIONS \
	__VSCODE_EXTENSIONS

declare -xA \
	__TYPE_ALIASES \
	__SHELL_PROFILES \
	__DEFAULT_TERMINALS \
	__DEFAULT_EXPLORERS \
	__DEFAULT_EDITORS \
	__DEFAULT_BROWSERS \
	__CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML \
	__HYPR_TEMPLATE_VALUES \
	__VSCODE_TEMPLATE_VALUES

__DEPENDENCIES=(
	base
	base-devel
	linux-firmware
	sof-firmware
	sudo
	bash
	mkinitcpio
	networkmanager
	dhcpcd
	wpa_supplicant
	reflector
	pacman-contrib
	git
	curl
	vi
	vim
	sed
	xz
	expac
	xdg-user-dirs
	jq
	go-yq
)

if grep -qi microsoft /proc/version || [ -f /etc/wsl.conf ]; then
	__IS_WSL=true
fi

if [ -z "$CPU" ]; then
	if grep -qiE "AuthenticAMD|HygonGenuine" /proc/cpuinfo 2>/dev/null; then
		CPU="amd"
	elif grep -qi "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
		CPU="intel"
	fi
fi

if [ -z "$GPU" ] && command -v lspci &>/dev/null; then
	__gpu_info="$(lspci | grep -iE 'vga|3d|display')"
	if echo "$__gpu_info" | grep -qi nvidia; then
		if echo "$__gpu_info" | grep -qiE '(GK10|GK11|GK20|GK21|GeForce GTX 6|GeForce GTX 7[0-4]|GeForce GT 6|GeForce GT 7|Quadro K|NVE)'; then
			GPU="nvidia-470xx"
		elif echo "$__gpu_info" | grep -qiE '(GF10|GF11|GeForce GTX 4|GeForce GTX 5|GeForce GT 4|GeForce GT 5|Quadro 2000|Quadro 600|NVC)'; then
			GPU="nvidia-390xx"
		elif echo "$__gpu_info" | grep -qiE '(GT2|G8|G9|GeForce 8|GeForce 9|GeForce 100|GeForce 200|GeForce 300)'; then
			GPU="nouveau"
		else
			GPU="nvidia"
			$GENERAL_USE_NVIDIA_OSS_DRIVERS && GPU+="-open"
		fi
	elif echo "$__gpu_info" | grep -qi amd; then
		GPU="amd"
	elif echo "$__gpu_info" | grep -qi intel; then
		GPU="intel"
	fi
fi

if [ -z "$__LOG_FILE" ]; then
	declare -x __LOG_FILE
	__LOG_FILE="${__ROOT}/tmp/archzen__$(date +%Y-%m-%d_%H-%M-%S).log"
fi

__USERNAME="${SUDO_USER:-$(whoami)}"
__USERHOME="$(eval echo "~${__USERNAME}")"

__SHELL_PROFILES=(
	[default]="${__USERHOME}/.profile"
	[bash]="${__USERHOME}/.bash_profile"
	[zsh]="${__USERHOME}/.zprofile"
	[fish]="${__USERHOME}/.config/fish/config.fish"
	[csh]="${__USERHOME}/.login"
	[tcsh]="${__USERHOME}/.login"
	[ksh]="${__USERHOME}/.profile"
	[mksh]="${__USERHOME}/.profile"
	[dash]="${__USERHOME}/.profile"
	[ash]="${__USERHOME}/.profile"
	[xonsh]="${__USERHOME}/.xonshrc"
	[elvish]="${__USERHOME}/.config/elvish/rc.elv"
	[nushell]="${__USERHOME}/.config/nushell/config.nu"
	[yash]="${__USERHOME}/.profile"
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

function __set_global_variables() {
	declare root="$1"
	declare force="$2"
	declare archzen_is_running_from_binary="$3"

	__check_type_alias DESKTOP_PROFILE "$GENERAL_DESKTOP_PROFILE"

	if [[ -z "$GENERAL_TERMINAL" && -n "$GENERAL_DESKTOP_PROFILE" ]]; then
		GENERAL_TERMINAL="${__DEFAULT_TERMINALS[${GENERAL_DESKTOP_PROFILE//-/_}]}"
	elif [ -z "$GENERAL_TERMINAL" ]; then
		GENERAL_TERMINAL=
	fi

	if [[ -z "$GENERAL_EXPLORER" && -n "$GENERAL_DESKTOP_PROFILE" ]]; then
		GENERAL_EXPLORER="${__DEFAULT_EXPLORERS[${GENERAL_DESKTOP_PROFILE//-/_}]}"
	elif [ -z "$GENERAL_EXPLORER" ]; then
		GENERAL_EXPLORER=
	fi

	if [[ -z "$GENERAL_EDITOR" && -n "$GENERAL_DESKTOP_PROFILE" ]]; then
		GENERAL_EDITOR="${__DEFAULT_EDITORS[${GENERAL_DESKTOP_PROFILE//-/_}]}"
	elif [ -z "$GENERAL_EDITOR" ]; then
		GENERAL_EDITOR=
	fi

	if [[ -z "$GENERAL_BROWSER" && -n "$GENERAL_DESKTOP_PROFILE" ]]; then
		GENERAL_BROWSER="${__DEFAULT_BROWSERS[${GENERAL_DESKTOP_PROFILE//-/_}]}"
	elif [ -z "$GENERAL_BROWSER" ]; then
		GENERAL_BROWSER=
	fi

	__ROOT="$root"
	__FORCE="$force"
	__ARCHZEN_IS_RUNNING_FROM_BINARY="${archzen_is_running_from_binary}"
	__PWD="$(pwd)"
	__THIS_SCRIPT="$0"
	__PWD_RESOURCES_DIR="${__PWD}/resources"
	__QUIET=false
	__ARCHINSTALL_PRESET="./resources/archinstall-preset.json"
	__AUR_HELPER_IS_INSTALLED=false
	__AUR_HELPER_BIN="$GENERAL_AUR_HELPER"
	while [[ $__AUR_HELPER_BIN =~ (-bin|-git)$ ]]; do
		__AUR_HELPER_BIN="${__AUR_HELPER_BIN/${BASH_REMATCH[0]}/}"
	done
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
	__VAR_DEPENDENCIES_INSTALED="${__ROOT}/var/lib/archzen-dependencies-installed"
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
		"archzen setup arch && rm -rf '${__FIRST_LOGIN_SCRIPT#"$__ROOT"*}' &>/dev/null"
	)

	__HYPR_TEMPLATE_VALUES=(
		[KB_LAYOUT]="$GENERAL_KB_LAYOUT"
		[KB_VARIANT]="$GENERAL_KB_VARIANT"
		[TERMINAL]="$GENERAL_TERMINAL"
		[EDITOR]="$GENERAL_EDITOR"
		[EXPLORER]="$GENERAL_EXPLORER"
		[BROWSER]="$GENERAL_BROWSER"
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

	if $GENERAL_SETUP_ZRAM; then
		__KERNEL_PARAMETERS+=("zswap.enabled=0")
		__KERNEL_FALLBACK_PARAMETERS+=("zswap.enabled=0")
	fi

	if [[ ! "$GENERAL_KERNEL" =~ cachyos && "$GPU" =~ nvidia ]]; then
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
		"${GENERAL_USER_SHELL:-bash}"
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
		fastfetch
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
		hwinfo
		inxi
		sed
		eza
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
		fish-lsp
		hadolint-bin
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
		"$GENERAL_TERMINAL"
		"$GENERAL_EDITOR"
		"$GENERAL_BROWSER"
		"$GENERAL_EXPLORER"
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

	__WSL_PKGLIST=(xdg-utils)

	__WSL_GUI_PKGLIST=(
		mesa
		vulkan-icd-loader
	)

	if $GENERAL_PACMAN_ENABLE_MULTILIB; then
		__WSL_GUI_PKGLIST+=(lib32-vulkan-icd-loader)
	fi

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
	if [[ "$GENERAL_DESKTOP_PROFILE" != hyprland || "$OS" == windows ]]; then
		__vsc_color_theme_ext='Default Themes:vscode.theme-defaults'
		__vsc_icon_theme_ext='Symbols:miguelsolorio.symbols'
		__vsc_dark_color_theme='Default Dark Modern'
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
		'Outline Map:Gerrnperl.outline-map'
		"$__vsc_icon_theme_ext"
	)

	if [[ "$__vsc_color_theme_ext" != *'vscode.theme-defaults'* ]]; then
		__VSCODE_EXTENSIONS+=(
			"$__vsc_color_theme_ext"
		)
	fi

	__VSCODE_TEMPLATE_VALUES=(
		[DARK_COLOR_THEME]="$__vsc_dark_color_theme"
		[LIGHT_COLOR_THEME]="$__vsc_light_color_theme"
		[ICON_THEME]="$__vsc_icon_theme"
		[EXTERNAL_TERMINAL]="$GENERAL_TERMINAL"
		[INTEGRATED_TERMINAL]="$GENERAL_USER_SHELL"
	)

	if [[ -n "$GENERAL_KERNEL" && "$__IS_WSL" == false ]]; then
		if [[ "$GENERAL_KERNEL" =~ cachyos && "$GENERAL_ENABLE_CACHYOS_KIT" == true ]]; then
			__CACHYOS_PKGLIST=(
				"$GENERAL_KERNEL"
				"${GENERAL_KERNEL}-headers"
				"${__CACHYOS_PKGLIST[@]}"
			)
		else
			__KERNEL_PKGLIST=(
				"$GENERAL_KERNEL"
				"${GENERAL_KERNEL}-headers"
				"${__KERNEL_PKGLIST[@]}"
			)
		fi
	fi

	if [[ -n "$CPU" && "$__IS_WSL" == false ]]; then
		__KERNEL_PKGLIST+=("${CPU}-ucode")
	fi
}
