#!/usr/bin/env bash

PASSWD_TIMEOUT=0                   # number of minutes before the sudo password prompt times out, or 0 for no timeout
REFLECTOR_MIRROR_COUNTRIES="BR,US" # Use `reflector --list-countries` to list available countries
REFLECTOR_MIRROR_LIMIT=10          # The higher the value, the longer the reflector will take to complete its run
PACMAN_PARALLEL_DOWNLOADS=10       # Value for Pacman's "ParallelDownloads" config option
PACMAN_ENABLE_MULTILIB=true        # Enable (or not) the multilib repository
AUR_HELPER="paru"                  # paru[-bin] | yay[-bin]; "aurbuilder" will use this behind the scenes. Comment this line to use "makepkg"
SETUP_ZRAM=true                    # true | false; Improve zram settings if you enabled it in Arch installation
KERNEL="linux-cachyos"             # linux | linux-lts | linux-zen | linux-hardened | any cachyos kernel; Comment this line to not install
USER_SHELL="fish"                  # Any available in the official repository or AUR; Comment this line to not change the shell; Only “fish” has customizations
CPU="intel"                        # intel | amd; Comment this line to not install
GPU="nvidia-open"                  # auto | nvidia | nvidia-open | nouveau | amd | intel; Comment this line to not install
DESKTOP_PROFILE="plasma"           # xorg | xorg-minimal | gnome | plasma; Comment this line to not install
TERMINAL="alacritty"               # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
EDITOR="vim"                       # Any available in the official repository or AUR; Comment this line to not install
BROWSER="zen-browser-bin"          # Any available in the official repository or AUR; Comment this line to not install
KERNEL_PARAMETERS=(
	nowatchdog
	quiet
	splash
)
KERNEL_FALLBACK_PARAMETERS=()

__VERSION="1.0.0"
__PWD="$(pwd)"
__THIS_SCRIPT="$0"
__QUIET=false
__LOG_FILE="/tmp/archzen__$(date +%Y-%m-%d_%H-%M-%S).log"
__USER_NAME="${SUDO_USER:-$(whoami)}"
__USER_HOME=$(eval echo "~${__USER_NAME}")
__AUR_HELPER_BIN="${AUR_HELPER/-bin/}"
__AUR_HELPER_IS_INSTALLED=false
__ALREADY_INSTALLED_PKGLIST=()
__NOT_INSTALLED_PKGLIST=()
__NOT_EXISTS_PKGLIST=()
__ESP=$(bootctl -p)
__ROOT="/"
__ROOT_FSTYPE=$(findmnt -no FSTYPE "$__ROOT")
__ARCHZEN_DIR="/opt/sirius-red/archzen"
__ARCHZEN_DOTFILES_DIR="${__ARCHZEN_DIR}/dotfiles"
__MAIN_SCRIPT_PATH="${__ARCHZEN_DIR}/archzen.sh"
__ARCHZEN_INSTALLED_VAR='/var/lib/archzen-installed'
__DOTFILES_INSTALLED_VAR='/var/lib/archzen-dotfiles-installed'
__BIN_DIR="/usr/bin"
__REBOOT_SYSTEM=false
__EXIT_CODE=0

if $SETUP_ZRAM; then
	KERNEL_PARAMETERS+=("zswap.enabled=0")
	KERNEL_FALLBACK_PARAMETERS+=("zswap.enabled=0")
fi

if [[ $__ROOT_FSTYPE == "xfs" ]]; then
	KERNEL_PARAMETERS+=("rootfstype=xfs")
	KERNEL_FALLBACK_PARAMETERS+=("rootfstype=xfs")
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
	mlocate
	perl
)

__TERMINAL_PKGLIST=(
	less
	wget
	curl
	xdg-user-dirs
	fastfetch
	vi
	arch-install-scripts
	git
	mold
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
	hadolint
)

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
	"${TERMINAL:-xterm}"
)

__GNOME_PKGLIST=(
	xorg-server
	gdm
	gnome-backgrounds
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
	nautilus
	rygel
	snapshot
	sushi
	tecla
	tracker3-miners
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
	"${TERMINAL:-gnome-terminal}"
)

__PLASMA_PKGLIST=(
	xorg-server
	plasma-meta
	power-profiles-daemon
	dolphin
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
	plasma-applet-window-buttons
	kmail
	konsave
	sddm
	"${TERMINAL:-konsole}"
)

# {name}:{version}:{id}
__VSCODE_EXTENSIONS=("Dev Essentials Pack:3.1.0:SiriusRed.dev-essentials-pack")

__OTHERS_PKGLIST=()

if [ -n "$KERNEL" ]; then
	if [[ "$KERNEL" =~ cachyos ]]; then
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

if [ -n "$EDITOR" ]; then
	__TERMINAL_PKGLIST+=("$EDITOR")
fi

if [ -n "$BROWSER" ]; then
	__OTHERS_PKGLIST+=("$BROWSER")
fi

function __is_main_module() {
	[[ "${BASH_SOURCE[0]}" == "${0}" ]]
}

function __is_integer() {
	local value="$1"

	[[ "$value" =~ ^[0-9]+$ ]]
}

function __func_exists() {
	local function_name=$1

	declare -F "$function_name" &>>"$__LOG_FILE"
}

function __tab() {
	local count="$1"

	for ((i = 0; i < count; i++)); do
		printf '\t'
	done
}

function __get_color_code() {
	local color="$1"

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
	local color="$1"
	shift
	local text="$*"
	local is_normal_color=false
	local is_bright_color=false

	__is_integer "$color" && {
		[[ "$color" -ge 30 && "$color" -le 37 ]] && is_normal_color=true
		[[ "$color" -ge 90 && "$color" -le 97 ]] && is_bright_color=true
	}

	if ! $is_normal_color && ! $is_bright_color; then
		local valid_normal_color_codes=(
			"\033[1;30m30\033[0m"
			"\033[1;31m31\033[0m"
			"\033[1;32m32\033[0m"
			"\033[1;33m33\033[0m"
			"\033[1;34m34\033[0m"
			"\033[1;35m35\033[0m"
			"\033[1;36m36\033[0m"
			"\033[1;37m37\033[0m"
		)
		local valid_bright_color_codes=(
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
	local text="$*"

	printf "\033[1m%s\033[0m" "$text"
}

function __underline() {
	local text="$*"

	printf "\033[4m%s\033[0m" "$text"
}

function __italic() {
	local text="$*"

	printf "\033[3m%s\033[0m" "$text"
}

function __bold_underline() {
	local text="$*"

	printf "\033[1;4m%s\033[0m" "$text"
}

function __bold_italic() {
	local text="$*"

	printf "\033[1;3m%s\033[0m" "$text"
}

function __bold_underline_italic() {
	local text="$*"

	printf "\033[1;3;4m%s\033[0m" "$text"
}

function __underline_italic() {
	local text="$*"

	printf "\033[3;4m%s\033[0m" "$text"
}

function __black() {
	local text="$*"

	__colorize 30 "$text"
}

function _bright_black() {
	local text="$*"

	__colorize 90 "$text"
}

function __red() {
	local text="$*"

	__colorize 31 "$text"
}

function __bright_red() {
	local text="$*"

	__colorize 91 "$text"
}

function __green() {
	local text="$*"

	__colorize 32 "$text"
}

function __bright_green() {
	local text="$*"

	__colorize 92 "$text"
}

function __yellow() {
	local text="$*"

	__colorize 33 "$text"
}

function __bright_yellow() {
	local text="$*"

	__colorize 93 "$text"
}

function __blue() {
	local text="$*"

	__colorize 34 "$text"
}

function __bright_blue() {
	local text="$*"

	__colorize 94 "$text"
}

function __purple() {
	local text="$*"

	__colorize 35 "$text"
}

function __bright_purple() {
	local text="$*"

	__colorize 95 "$text"
}

function __cyan() {
	local text="$*"

	__colorize 36 "$text"
}

function __bright_cyan() {
	local text="$*"

	__colorize 96 "$text"
}

function __white() {
	local text="$*"

	__colorize 37 "$text"
}

function __bright_white() {
	local text="$*"

	__colorize 97 "$text"
}

function __banner() {
	local primary_color=$1
	local secondary_color=$2
	local pad=$3
	local title=$4
	shift 4
	local optional_params=("$@")
	local author
	local project_url
	local license
	local reference_urls=()

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
	local width=0
	local info_lines=()
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
	local title_padding=$(((width - ${#title} - 4) / 2))

	# formatting function
	local edge
	edge=$(printf "%${width}s" | tr ' ' "$pad")
	pad="${pad}${pad}"

	# coloring
	local separator
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
	local plain="$1"
	local formatted="$2"

	$__QUIET || printf "%s\n" "$formatted"
	printf "%s\n" "$plain" >>"$__LOG_FILE"
}

function __title() {
	local message formatted
	message="$*"
	formatted="$(__purple "[#]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __title_params() {
	local params="$*"

	__bright_purple "$params"
}

function __question() {
	local message="$1"
	local formatted="$2"
	local quiet=$__QUIET
	message="[?] ${message}"
	formatted="$(__cyan "[?]") ${message}"

	__QUIET=true
	__log "$message" "$formatted"
	__QUIET=$quiet
	return 0
}

function __question_params() {
	local params="$*"

	__bright_cyan "$params"
}

function __info() {
	local message formatted
	message="$*"
	formatted="$(__blue "[i]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __info_params() {
	local params="$*"

	__bright_blue "$params"
}

function __success() {
	local message formatted
	message="$*"
	formatted="$(__green "[+]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __success_params() {
	local params="$*"

	__bright_green "$params"
}

function __warn() {
	local message formatted
	message="$*"
	formatted="$(__yellow "[!]") ${message}"

	__log "$message" "$formatted"
	return 0
}

function __warn_params() {
	local params="$*"

	__bright_yellow "$params"
}

function __error() {
	local message formatted
	message="$*"
	formatted="$(__red "[x]") ${message}"

	__log "$message" "$formatted"
	return 1
}

function __error_params() {
	local params="$*"

	__bright_red "$params"
}

function __confirm() {
	local question="$*"
	local plain_question="$* [Y/n]"
	local return_code=2
	local quiet=$__QUIET
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
	local package="$1"

	pacman -Q "$package" &>>"$__LOG_FILE" && return 0

	return 1
}

function __detect_pkg_type() {
	local package="$1"

	if pacman -Ss "$package" &>>"$__LOG_FILE"; then
		echo "arch"
	elif git ls-remote "https://aur.archlinux.org/${package}.git" &>>"$__LOG_FILE"; then
		echo "aur"
	else
		echo "none"
	fi
}

function __pacman_install() {
	local packages=("$@")

	[ ${#packages[@]} -eq 0 ] && return 0

	mold --run pacman -S --noconfirm --needed "${packages[@]}" &>>"$__LOG_FILE"
	return $?
}

function __aur_install() {
	local packages=("$@")

	[ ${#packages[@]} -eq 0 ] && return 0

	if $__AUR_HELPER_IS_INSTALLED; then
		mold --run "$__AUR_HELPER_BIN" -S --noconfirm "${packages[@]}" &>>"$__LOG_FILE"
	else
		aurbuilder install --noconfirm "${packages[@]}" &>>"$__LOG_FILE"
	fi

	return $?
}

function __install_package() {
	local package="$1"
	local installed=false
	local proceed=true
	local pkg_type

	if __is_installed "$package"; then
		__ALREADY_INSTALLED_PKGLIST+=("$package")
		__info "Package is already installed: $(__info_params "$package")"
		return $?
	fi

	__title "installing package $(__title_params "${package}")"

	pkg_type=$(__detect_pkg_type "$package")
	case "$pkg_type" in
	arch)
		__pacman_install "$package" && installed=true
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
	local raw_pkglist=("$@")
	local arch_packages=()
	local aur_packages=()
	local arch_packages_count
	local aur_packages_count
	local installed_packages_count
	local total_packages_count
	local installed_packages_string
	local installed_packages_text

	__title "Fetching package list data"

	if {
		for pkg in "${raw_pkglist[@]}"; do
			local pkg_type

			if __is_installed "$pkg"; then
				__ALREADY_INSTALLED_PKGLIST+=("$pkg")

				__info "Package is already installed: $(__info_params "$pkg")"
				continue
			fi

			pkg_type=$(__detect_pkg_type "$pkg")
			case "$pkg_type" in
			arch)
				arch_packages+=("$pkg")
				;;
			aur)
				aur_packages+=("$pkg")
				;;
			none)
				__NOT_EXISTS_PKGLIST+=("$pkg")
				__warn "Package not exist: $(__warn_params "$pkg")"
				;;
			*)
				__NOT_INSTALLED_PKGLIST+=("$pkg")
				__error "Unkown error for package: $(__error_params "$pkg")"
				;;
			esac
		done
	} then
		__success "Package list data fetched successfully"
	else
		__error "Error fetching package list data"
		return $?
	fi

	arch_packages_count=${#arch_packages[@]}
	aur_packages_count=${#aur_packages[@]}
	total_packages_count=$((arch_packages_count + aur_packages_count))
	__title "Starting package list installation: $(__title_params "${total_packages_count} Packages")"

	__pacman_install "${arch_packages[@]}"
	__aur_install "${aur_packages[@]}"

	installed_packages_string=''
	while IFS='' read -r line; do installed_packages_string+=" $line"; done < <(pacman -Qq)

	installed_packages_count=0
	for pkg in "${arch_packages[@]}" "${aur_packages[@]}"; do
		if [[ "$installed_packages_string" =~ $pkg ]]; then
			((installed_packages_count++))

			__success "Package installed: $(__success_params "$pkg")"
			continue
		fi

		__NOT_INSTALLED_PKGLIST+=("$pkg")

		__warn "Package not installed: $(__warn_params "$pkg")"
	done

	installed_packages_text="${installed_packages_count}/${total_packages_count} package(s) installed"

	if [ $installed_packages_count -eq $total_packages_count ]; then
		__success "Package list installation finished successfully: $(__success_params "$installed_packages_text")"
	elif [ $installed_packages_count -gt 0 ]; then
		__warn "Package list installation finished with some errors: $(__warn_params "$installed_packages_text")"
	else
		__error "Package list installation finished with error: $(__error_params "$installed_packages_text")"
	fi

	return $?
}

function __get_line() {
	local pattern="$1"
	local file_path="$2"
	local line

	line=$(grep -n "$pattern" "$file_path" || printf -1)

	if [[ "$line" == -1 ]]; then
		printf "%s" "$line"
	else
		printf "%s" "$line" | cut -d ':' -f 1
	fi
}

function __add_lines_to_file() {
	local file_path="$1"
	local mode="$2"
	local add_blank_line=false
	[[ "$3" == "true" ]] && add_blank_line=true
	shift 3
	local lines=("$@")
	local success=false
	local action_word

	function __exec() {
		if [[ "$mode" == "w" ]]; then
			local file_dir
			file_dir=$(dirname "$file_path")

			[ -f "$file_path" ] && rm -f "$file_path" &>>"$__LOG_FILE"
			[ -d "$file_dir" ] || mkdir -p "$file_dir"

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

function __format_script() {
	local script_path="$1"
	shift
	local options=("$@")
	local quiet=$__QUIET

	[[ "${options[*]}" =~ --quiet|-q ]] && __QUIET=true

	__title "Formatting file: $(__title_params "$script_path")"

	if shfmt --write --indent 4 --case-indent "$script_path" &>>"$__LOG_FILE"; then
		__success "File formatted successfully: $(__success_params "$script_path")"
	else
		__error "Error formatting file: $(__error_params "$script_path")"
	fi

	__QUIET=$quiet

	return $?
}

function __save_script() {
	local script_path="$1"
	shift 1
	local script_lines=("$@")
	local script_dir
	script_dir="$(dirname "$script_path")"

	[ -d "$script_dir" ] || mkdir -p "$script_dir"
	__archzen_is_installed || install_archzen || return $?
	[ -f "$script_path" ] && rm -f "$script_path"

	__add_lines_to_file "$script_path" w false "${script_lines[@]}" &>>"$__LOG_FILE" &&
		__format_script "$script_path" --quiet &&
		chmod +x "$script_path" &>>"$__LOG_FILE" &&
		ln -sf "$script_path" "/usr/bin/${script_name/.sh/}" &>>"$__LOG_FILE" &&
		return 0

	return 1
}

function __gen_bootloader_update_script() {
	local bootloader="$1"
	[[ "$bootloader" == "auto" ]] && bootloader="$(__detect_bootloader)"

	local script_name="${bootloader}-update.sh"
	local script_dir="${__ARCHZEN_DIR}"
	local script_path="${script_dir}/${script_name}"
	local script_lines=(
		'#!/usr/bin/env bash'
		''
		"# shellcheck source=${__MAIN_SCRIPT_PATH}"
		"source \"${__MAIN_SCRIPT_PATH}\""
		''
		"setup_bootloader ${bootloader} false"
	)

	__title "Generating update script for $(__title_params "$bootloader"): $(__title_params "$script_path")"

	if __save_script "$script_path" "${script_lines[@]}"; then
		__success "Success generated update script for $(__success_params "$bootloader"): $(__success_params "$script_path")"
	else
		__error "Error when generating update script for $(__error_params "$bootloader"): $(__error_params "$script_path")"
	fi

	return $?
}

function __setup_sdboot() {
	__install_package systemd-boot-manager || return 1

	function __gen_entries() {
		local esp_loader_entries="${__ESP}/loader/entries"
		local sdboot_manage_conf="/etc/sdboot-manage.conf"
		local sdboot_manage_conf_lines=(
			"LINUX_OPTIONS=\"${KERNEL_PARAMETERS[*]}\""
			"LINUX_FALLBACK_OPTIONS=\"${KERNEL_FALLBACK_PARAMETERS[*]}\""
			"DISABLE_FALLBACK=\"no\""
			"DEFAULT_ENTRY=\"manual\""
			"ENTRY_ROOT=\"${KERNEL}\""
			"ENTRY_TITLE=\"${KERNEL}\""
			"ENTRY_APPEND_KVER=\"no\""
			"REMOVE_EXISTING=\"yes\""
			"OVERWRITE_EXISTING=\"yes\""
			"REMOVE_OBSOLETE=\"yes\""
		)

		[ -f "$sdboot_manage_conf" ] && mv "$sdboot_manage_conf" "${sdboot_manage_conf}.old" &>>"$__LOG_FILE"

		__add_lines_to_file "$sdboot_manage_conf" w false "${sdboot_manage_conf_lines[@]}" &&
			sdboot-manage --esp-path="$__ESP" --config="$sdboot_manage_conf" gen &&
			sed -i "s/^title.*/title$(__tab 1)Arch Linux (${KERNEL})/" "${esp_loader_entries}/${KERNEL}.conf" &&
			sed -i "s/^title.*/title$(__tab 1)Arch Linux (${KERNEL}-fallback)/" "${esp_loader_entries}/${KERNEL}-fallback.conf"

	}

	function __edit_loader_conf() {
		local esp_loader_conf="${__ESP}/loader/loader.conf"
		local sd_default="@saved"
		local sd_timeout=0
		local sd_console_mode="max" # auto | max | keep
		local sd_editor="no"        # yes | no
		if [ -n "$KERNEL" ]; then
			sd_default="${KERNEL}.conf"
			sd_timeout=3
		fi
		local esp_loader_conf_lines=(
			"default       ${sd_default}"
			"timeout       ${sd_timeout}"
			"console-mode  ${sd_console_mode}"
			"editor        ${sd_editor}"
		)

		__add_lines_to_file "$esp_loader_conf" w false "${esp_loader_conf_lines[@]}"
	}

	__gen_entries &>>"$__LOG_FILE" &&
		__edit_loader_conf &>>"$__LOG_FILE" &&
		return 0

	return 1
}

function __variable_file_exists() {
	local file="$1"

	ls "$file" &>>"$__LOG_FILE" || return $?

	return 0
}

function __archzen_is_installed() {
	__variable_file_exists "$__ARCHZEN_INSTALLED_VAR"

	return $?
}

function __dotfiles_is_installed() {
	__variable_file_exists "$__DOTFILES_INSTALLED_VAR"

	return $?
}

function install_archzen() {
	local success=false
	local script_name
	script_name="$(basename "$__MAIN_SCRIPT_PATH")"
	script_name="${script_name/.sh/}"

	__title "Installing Archzen"

	{
		{ [ -d "$__ARCHZEN_DIR" ] && rm -rf "$__ARCHZEN_DIR"; } &&
			mkdir -p "$__ARCHZEN_DIR" &&
			cp -f "$__THIS_SCRIPT" "${__ROOT}/$__MAIN_SCRIPT_PATH" &&
			cp -rf "${__PWD}/dotfiles" "${__ROOT}/${__ARCHZEN_DOTFILES_DIR}" &&
			chmod +x "${__ROOT}/$__MAIN_SCRIPT_PATH" &&
			ln -sf "${__ROOT}/$__MAIN_SCRIPT_PATH" "${__ROOT}/usr/bin/${script_name}" &&
			touch "$__ARCHZEN_INSTALLED_VAR" &&
			success=true
	} &>>"$__LOG_FILE" || false

	if $success; then
		__success "ArchZen successfully installed"
	else
		__error "Error installing ArchZen"
	fi

	return $?
}

function install_archlinux() {
	local root="$__ROOT"
	local first_run_script="/mnt/archinstall/etc/profile.d/${__THIS_SCRIPT}"
	local first_run_script_lines=(
		'#!/usr/bin/env bash'
		''
		'sudo archzen setup'
		'sudo rm -- "$0"'
	)

	if ! command -v archinstall; then
		__error "Executable not found in PATH: $(__error_params "archinstall")"
		return $?
	fi

	archinstall --advanced --config ./archinstall.config.json

	__ROOT='/mnt/archinstall'
	{ __archzen_is_installed || install_archzen; } &&
		__add_lines_to_file "$first_run_script" w false "${first_run_script_lines[@]}"
	__ROOT="$root"
}

function setup_sudoers() {
	local sudoers="/etc/sudoers"
	local sudoers_user="/etc/sudoers.d/00_${__USER_NAME}"
	local sudoers_options=(
		"Defaults insults"
		"Defaults pwfeedback"
		"Defaults passwd_timeout=${PASSWD_TIMEOUT}"
	)
	local sudoers_user_options=(
		"${__USER_NAME} ALL=(ALL:ALL) ALL"
		"%${__USER_NAME} ALL=(ALL:ALL) ALL"
	)

	__title "Configuring sudoers for user: $(__title_params "$__USER_NAME")"

	for option in "${sudoers_options[@]}"; do
		if grep -qe "$option" "$sudoers" &>>"$__LOG_FILE"; then
			__info "Option alread exists: $(__info_params "$option")"
			continue
		fi

		if __add_lines_to_file "$sudoers" "a" true "$option"; then
			__success "Option added successfully to ${sudoers}: $(__success_params "$option")"
		else
			__error "Error adding option to ${sudoers}: $(__error_params "$option")"
		fi
	done

	if [ ! -f "$sudoers_user" ]; then
		__add_lines_to_file "${sudoers_user}" "w" false "${sudoers_user_options[@]}"
	else
		for option in "${sudoers_user_options[@]}"; do
			if grep -qe "$option" "$sudoers_user" &>>"$__LOG_FILE"; then
				__info "Config already defined for user ${__USER_NAME}: $(__info_params "$option")"
				continue
			fi

			if __add_lines_to_file "${sudoers_user}" "a" true "${option}"; then
				__success "Option added successfully to ${sudoers_user}: $(__success_params "$option")"
			else
				__error "Error adding option to ${sudoers_user}: $(__error_params "$option")"
			fi
		done
	fi

	return $?
}

function setup_zram() {
	$SETUP_ZRAM || return 0
	zramctl &>>"$__LOG_FILE" || return 0

	local success=false
	local fstab="/etc/fstab"
	local fstab_lines=(
		'/swapfile none swap sw 0 0'
	)
	local zram_generator_conf="/etc/systemd/zram-generator.conf"
	local zram_generator_lines=(
		'# Defines the first zram unit'
		'[zram0]'
		''
		'# Defines ZRAM size to a range of at least 10% and at a 4XIMUM 50% (with a maximum limit of 16g) of the total RAM)'
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
	local zram_parameters_conf="/etc/sysctl.d/99-vm-zram-parameters.conf"
	local zram_parameters_lines=(
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

	__install_package zram-generator &>>"$__LOG_FILE" &&
		fallocate -l 4G /swapfile &&
		chmod 600 /swapfile &&
		mkswap /swapfile &&
		__add_lines_to_file "$fstab" "a" true "${fstab_lines[@]}" &&
		swapon /swapfile &&
		__add_lines_to_file "$zram_generator_conf" "w" false "${zram_generator_lines[@]}" &&
		__add_lines_to_file "$zram_parameters_conf" "w" false "${zram_parameters_lines[@]}" &&
		success=true

	if $success; then
		__success "Zram configured successfully"
	else
		__error "Error configuring zram"
	fi

	return $?
}

function setup_pacman() {
	local pacman_conf="/etc/pacman.conf"
	local return_code=0

	function __show_title() {
		local step="$1"

		__title "Configuring pacman: $(__title_params "$step")"
	}

	function __show_result() {
		local status="$1"
		local step="$2"

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
		local status

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
		local status

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
		local value="$1"
		local status

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
		local status

		__show_title "Enable multilib repository"

		if grep -qe '^\[[Mm]ultilib\]$' "$pacman_conf" &>>"$__LOG_FILE"; then
			status="keep"
		else
			local line
			line=$(__get_line '\[[Mm]ultilib\]' "$pacman_conf")

			if {
				[ "$line" -gt 0 ] &&
					sed -i "${line}s/#\s*//" "$pacman_conf" &&
					((multilib_l++)) &&
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
		local status

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

	__enable_colors || return_code=1
	__enable_i_love_candy || return_code=1
	__set_parallel_downloads "$PACMAN_PARALLEL_DOWNLOADS" || return_code=1
	$PACMAN_ENABLE_MULTILIB && { __enable_multilib_repo || return_code=1; }
	__fix_file_permissions || return_code=1

	return $return_code
}

function rate_mirrors() {
	local reflector_conf="/etc/xdg/reflector/reflector.conf"
	local lines=(
		"--save /etc/pacman.d/mirrorlist"
		"--ipv4"
		"--ipv6"
		"--protocol https"
		"--country ${REFLECTOR_MIRROR_COUNTRIES}"
		"--latest ${REFLECTOR_MIRROR_LIMIT}"
		"--sort rate"
	)
	local log_data="${REFLECTOR_MIRROR_LIMIT} mirros from ${REFLECTOR_MIRROR_COUNTRIES}"

	__title "Rating mirros: $(__title_params "$log_data")"

	if __add_lines_to_file "$reflector_conf" "w" false "${lines[@]}" && systemctl start reflector.service &>>"$__LOG_FILE"; then
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
	elif curl -L https://sirius-red.github.io/aurbuilder/install | sh -s -- --quiet; then
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
	local proceed=true
	local base_pkglist=(
		"${__KERNEL_PKGLIST[@]}"
		"${__BASE_SYSTEM_PKGLIST[@]}"
	)

	__title "Installing base packages"

	if __install_pkglist "${base_pkglist[@]}"; then
		__success "Base packages installed successfully"
	else
		__error "Error installing base packages"
	fi

	return $?
}

function install_cachyos_repo() {
	local workdir="/tmp/cachyos-repo"
	local proceed=true
	local success=false

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

function update_system() {
	local pkgmgr="pacman"
	$__AUR_HELPER_IS_INSTALLED && pkgmgr=$__AUR_HELPER_BIN

	__title "Updating system"

	if mold --run "$pkgmgr" -Syu --noconfirm &>>"$__LOG_FILE"; then
		__success "System updated successfully with: $(__success_params "$pkgmgr")"
	else
		__error "Error updating system with: $(__error_params "$pkgmgr")"
	fi

	return $?
}

function install_cachyos_packages() {
	__title "Installing CachyOS tools"

	if __install_pkglist "${__CACHYOS_PKGLIST[@]}"; then
		__success "CachyOS packages installed successfully"
	else
		__error "Error installing CachyOS packages"
	fi

	return $?
}

function rate_cachyos_mirrors() {
	__title "Rating CachyOS mirrors"

	if cachyos-rate-mirrors &>>"$__LOG_FILE"; then
		__success "CachyOS mirrors were successfully rated"
	else
		__error "Error rating CachyOS mirrors"
	fi

	return $?
}

function install_packages() {
	local proceed=true
	local pkglist=(
		"${__FILESYSTEM_PKGLIST[@]}"
		"${__NETWORK_PKGLIST[@]}"
		"${__BLUETOOTH_PKGLIST[@]}"
		"${__HARDWARE_PKGLIST[@]}"
		"${__PACKAGE_MANAGER_PKGLIST[@]}"
		"${__TERMINAL_PKGLIST[@]}"
		"${__DEVELOPMENT_PKGLIST[@]}"
		"${__MULTIMEDIA_PKGLIST[@]}"
		"${__FONTS_PKGLIST[@]}"
	)

	__title "Installing packages"

	if __install_pkglist "${base_pkglist[@]}"; then
		__success "Packages installed successfully"
	else
		__error "Error installing packages"
	fi

	return $?
}

function install_gpu_drivers() {
	local success=false

	__title "Install GPU drivers: $(__title_params "$GPU")"

	case $GPU in
	auto)
		chwd -a &>>"$__LOG_FILE"
		success=true
		;;
	nvidia | nvidia-open)
		chwd -i "${GPU}-dkms" &>>"$__LOG_FILE"
		success=true
		;;
	nouveau | amd | intel)
		chwd -i "$GPU" &>>"$__LOG_FILE"
		success=true
		;;
	*)
		__error "Invalid GPU value: $(__error_params "$GPU")"
		;;
	esac

	if $success; then
		__success "GPU drivers installed successfully: $(__success_params "$GPU")"
	else
		__error "Error installing GPU drivers: $(__error_params "$GPU")"
	fi

	return $?
}

function install_desktop_profile() {
	local displaymgr pkglist
	local success=false
	local proceed=true

	case $DESKTOP_PROFILE in
	xorg)
		pkglist=("${__XORG_PKGLIST[@]}")
		;;
	xorg-minimal)
		pkglist=("${__XORG_MINIMAL_PKGLIST[@]}")
		;;
	gnome)
		displaymgr="gdm"
		pkglist=("${__GNOME_PKGLIST[@]}" "$displaymgr")
		;;
	plasma)
		displaymgr="sddm"
		pkglist=("${__PLASMA_PKGLIST[@]}" "$displaymgr")

		function __setup_desktop_profile() {
			__add_lines_to_file "/usr/lib/sddm/sddm.conf.d/general.conf" "w" false \
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

			__add_lines_to_file "/etc/sddm.conf.d/01-wayland.conf" "w" false \
				'[General]' \
				'DisplayServer=wayland' \
				'GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell' \
				'' \
				'[Wayland]' \
				'CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1'
		}
		;;
	*)
		proceed=false
		__error "Invalid DESKTOP_PROFILE value: $(__error_params "$DESKTOP_PROFILE")"
		;;
	esac

	$proceed &&
		__install_pkglist "${pkglist[@]}" &&
		{
			if [ -n "$displaymgr" ]; then
				systemctl enable "${displaymgr}.service"
			else
				true
			fi
		} &&
		{
			if __func_exists __setup_desktop_profile; then
				__setup_desktop_profile
			else
				true
			fi
		} &&
		success=true

	if $success; then
		__success "Desktop Profile installed successfully"
	else
		__error "No desktop profile will be installed! Install manually after system installation is complete."
	fi

	return $?
}

function setup_dotfiles() {
	local success=false

	__title "Copying dotfiles to: $(__title_params "$__USER_HOME")"

	{
		cp -rf "${__ROOT}/${__ARCHZEN_DOTFILES_DIR}" "${__ROOT}/tmp/dotfiles" &&
			chown -R "$__USER_NAME":"$__USER_NAME" "${__ROOT}/tmp/dotfiles" &&
			cd "${__ROOT}/tmp/dotfiles" &&
			find . -exec cp -rf --parents "{}" "$__USER_HOME" \; &&
			cd - &&
			rm -rf "${__ROOT}/tmp/dotfiles" &&
			touch "$__DOTFILES_INSTALLED_VAR" &&
			success=true
	} &>>"${__LOG_FILE}"

	if $success; then
		__success "Dotfiles successfully copied to: $(__success_params "$__USER_HOME")"
	else
		__error "Error copying dotfiles to: $(__error_params "$__USER_HOME")"
	fi

	return $?
}

function setup_vscode() {
	__is_installed visual-studio-code-bin || return 0

	local success=true
	local installed_ext=0

	__title "Setting up VS Code"

	if ! __dotfiles_is_installed; then
		success=false
		{
			mkdir -p "${__ROOT}/tmp/vscode-dotfiles/.config" &&
				cp -rf "${__ROOT}/${__ARCHZEN_DOTFILES_DIR}/.config/Code" "${__ROOT}/tmp/vscode-dotfiles/.config/Code" &&
				chown -R "$__USER_NAME":"$__USER_NAME" "${__ROOT}/tmp/vscode-dotfiles" &&
				cd "${__ROOT}/tmp/vscode-dotfiles" &&
				find . -exec cp -rf --parents "{}" "$__USER_HOME" \; &&
				cd - &&
				rm -rf "${__ROOT}/tmp/vscode-dotfiles" &&
				success=true
		} &>>"${__LOG_FILE}"
	fi

	if $success; then
		{
			for ext in "${__VSCODE_EXTENSIONS[@]}"; do
				local name version id
				name="$(echo "$ext" | cut -d':' -f1)"
				version="$(echo "$ext" | cut -d':' -f2)"
				id="$(echo "$ext" | cut -d':' -f3)"

				if sudo -u "$__USER_NAME" code --install-extension "$id"; then
					((installed_ext++))
					printf 'VS Code extension "%s v%s" installed successfully' "$name" "$version"
				else
					printf 'Error installing VS Code extension "%s v%s"' "$name" "$version"
				fi
			done
		} &>>"${__LOG_FILE}"
	fi

	local installed_ext_msg="${installed_ext}/${#__VSCODE_EXTENSIONS[@]}"

	if $success && [ $installed_ext -eq "${#__VSCODE_EXTENSIONS[@]}" ]; then
		__success "VS Code configured successfully. Installed extensions: $(__success_params "$installed_ext_msg")"
	elif $success; then
		__warn "VS Code configured with some errors. Installed extensions: $(__warn_params "$installed_ext_msg")"
	else
		__error "Error configuring VS Code. Installed extensions: $(__error_params "$installed_ext_msg")"
	fi

	return $?
}

function setup_bootloader() {
	local bootloader="$1"
	local gen_scripts="${2:-true}"
	local success=false
	[[ "$bootloader" == "auto" ]] && bootloader=$(__detect_bootloader)

	__title "Configuring bootloader: $(__title_params "$bootloader")"

	case $bootloader in
	sdboot)
		__setup_sdboot && success=true
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

	if $gen_scripts; then
		success=false

		__gen_bootloader_update_script "$bootloader" &&
			success=true
	fi

	if $success; then
		__success "Bootloader configured successfully: $(__success_params "$bootloader")"
	else
		__error "Error configuring bootloader: $(__error_params "$bootloader")"
	fi

	return $?
}

function setup_os() {
	local return_code=0

	function __set_os_specifications() {
		local os_release="/etc/os-release"
		local lines=(
			'NAME="Arch Linux"'
			'PRETTY_NAME="Arch Linux"'
			'ID=arch'
			# 			'ID_LIKE=arch'
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
		local proceed=true

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

		local shell_path
		shell_path=$(which "$USER_SHELL")

		if ! grep -qe "^${shell_path}$" "/etc/shells" &>>"$__LOG_FILE"; then
			proceed=false

			__title "Adding the ${USER_SHELL} path to /etc/shells: $(__title_params "$shell_path")"

			if __add_lines_to_file "/etc/shells" a false "$shell_path"; then
				proceed=true

				__success "${USER_SHELL} path added to /etc/shells: $(__success_params "$shell_path")"
			else
				__error "Error adding the ${USER_SHELL} path to /etc/shells: $(__error_params "$shell_path")"
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

function setup_archlinux() {
	setup_sudoers
	setup_zram
	setup_pacman
	rate_mirrors
	install_aurbuilder || return $?
	install_aur_helper || return $?
	install_base_packages || return $?
	install_cachyos_repo || return $?
	update_system || return $?
	install_cachyos_packages || return $?
	rate_cachyos_mirrors
	install_packages
	install_gpu_drivers
	install_desktop_profile
	setup_dotfiles
	setup_bootloader auto
	setup_os
}

function show_help() {
	echo -e "$(
		cat <<EOL
$(show_version)

$(__bold_underline USAGE:)
$(__tab 1) $(__purple archzen) $(__bright_blue '<command>')

$(__bold_underline INSTALLATION COMMANDS:)
$(__tab 1)$(__bright_blue install), $(__bright_blue i)$(__tab 2)Starts the archinstall script with a minimal preset.
$(__tab 4)$(__white '(It also installs archzen and runs all setup commands on first login)')
$(__tab 1)$(__bright_blue self-install), $(__bright_blue si)$(__tab 1)Installs Archzen on the system.
$(__tab 4)$(__white '(Some setup commands will not work if archzen is not installed)')

$(__bold_underline SETUP COMMANDS:)
$(__tab 1)$(__bright_blue arch), $(__bright_blue a)$(__tab 3)Setup an already installed Arch Linux with Archzen's customizations.
$(__tab 1)$(__bright_blue sdboot), $(__bright_blue sdb)$(__tab 2)Setup the "systemd-boot" bootloader, including hooks and scripts for update.
$(__tab 1)$(__bright_blue zram), $(__bright_blue z)$(__tab 3)Setup zram no system.
$(__tab 1)$(__bright_blue dotfiles), $(__bright_blue d)$(__tab 2)Copies Archzen's dotfiles to ~/.config.
$(__tab 1)$(__bright_blue vscode), $(__bright_blue vsc)$(__tab 2)Setup VS Code settings, keymaps and extensions.

$(__bold_underline UTILITIES COMMANDS:)
$(__tab 1)$(__bright_blue version), $(__bright_blue v)$(__tab 2)Show the script version.
$(__tab 1)$(__bright_blue help), $(__bright_blue h)$(__tab 3)Show this help message.

Made with $(__bright_red "<3"), headache, coffee and $(__bright_green weed) by $(__red Sirius Red)\n
EOL
	)"
}

function show_version() {
	echo "ArchZen $(__bright_green "v${__VERSION}")"
}

function init() {
	function __show_banner() {
		local banner_args=(
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

	__show_banner
	__confirm "Do you want to start the now?" || exit 0
	__show_banner
}

function run() {
	local action="$1"

	case $action in
	install | i)
		install_archlinux
		__REBOOT_SYSTEM=true
		;;
	self-install | si)
		install_archzen
		;;
	arch | a)
		setup_archlinux
		__REBOOT_SYSTEM=true
		;;
	sdboot | sdb)
		setup_bootloader sdboot
		__REBOOT_SYSTEM=true
		;;
	zram | z)
		SETUP_ZRAM=true
		setup_zram
		__REBOOT_SYSTEM=true
		;;
	dotfiles | d)
		setup_dotfiles
		;;
	vscode | vsc)
		setup_vscode
		;;
	version | v)
		show_version
		;;
	help | h)
		show_help
		;;
	*)
		__error "Unknown action: $(__error_params "$action")"
		show_help
		exit 1
		;;
	esac
}

function finish() {
	local quiet=$__QUIET

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

	__log "" ""
	__info "Verbose log at: $(__info_params "$__LOG_FILE")"
	__log "" ""

	if $__REBOOT_SYSTEM && __confirm "A system restart is required for the changes to take effect, do you want to restart now?"; then
		reboot
	fi

	exit $__EXIT_CODE
}

if __is_main_module; then
	if [[ "$1" =~ ^version$|^v$|^help$|^h$ || -z "$1" ]]; then
		run "$1" || __EXIT_CODE=$?
		exit $__EXIT_CODE
	fi

	if [[ $EUID -ne 0 ]]; then
		__error "$(__error_params "$__THIS_SCRIPT") must be run as root"
		exit 1
	fi

	init || __EXIT_CODE=$?
	run "$1" || __EXIT_CODE=$?
	finish
fi
