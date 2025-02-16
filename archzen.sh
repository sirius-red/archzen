#!/usr/bin/env bash

#########################################################################
##                                                                     ##
##                 ArchZen (Stay zen and install Arch)                 ##
##                                                                     ##
##---------------------------------------------------------------------##
## Author   : Sirius (https://github.com/sirius-red)                   ##
##                                                                     ##
## Project  : https://github.com/sirius-red/archzen                    ##
##                                                                     ##
## License  : GPL-v3                                                   ##
##                                                                     ##
## Reference: https://wiki.archlinux.org/index.php/Installation_guide) ##
##            https://github.com/sirius-red/archzen/blob/main/LICENSE) ##
##            https://www.gnu.org/licenses/gpl-3.0.html)               ##
##                                                                     ##
#########################################################################

########## EDIT THIS SETTINGS ↓ ##########

TERMINAL_FONT="ter-122b" # font in the installation terminal; use `ls /usr/share/kbd/consolefonts` to list available ones
PING_URL="google.com"    # just to test the connection before installation
MIRROR_COUNTRIES="BR,US" # use `reflector --list-countries` to list available countries
MIRROR_SERVERS_LIMIT=20  # the higher the value, the longer the reflector will take to complete its execution
PARALLEL_DOWNLOADS=10    # I don't recommend a value higher than that, but it's up to you
ENABLE_MULTILIB=false    # enable (or not) the multilib repository
ENABLE_CACHYOS_REPO=true # true | false; Setting a cachyos kernel to `KERNEL` will set this option to `true` automatically

KEYMAP="br-abnt2"            # use `localectl list-keymaps` to list available keymaps
TIMEZONE="America/Sao_Paulo" # use `timedatectl list-timezones` to list available timezones
LANGUAGES=(
	# put the system default language at the top
	# supports all languages ​​in the `/etc/locale.gen` file
	en_US.UTF-8
	pt_BR.UTF-8
)

DISK_MANAGER="cfdisk"  # cfdisk | cgdisk
DISK_DEVICE="/dev/sda" # use `lsblk` to list disks
KERNEL="linux-cachyos" # linux | linux-lts | linux-zen | linux-hardened | any cachyos kernel
FILESYSTEM="xfs"       # xfs | ext4
CPU="intel"            # intel | amd
BOOT_LOADER="grub"     # grub | systemd-boot (Experimental!)
ENABLE_DUAL_BOOT=false # true | false
ENABLE_ZRAM=true       # true | false

HOSTNAME="ArchZen"        # name by which the machine will be recognized on the network
BOOTLOADER_ID="$HOSTNAME" # UEFI entry name
USER_NAME="sirius"        # your username
USER_PASSWD="archzen"     # your password
ROOT_PASSWD="archzen"     # root user password
PASSWD_TIMEOUT=0          # number of minutes before the sudo password prompt times out, or 0 for no timeout

GPU="auto"                  # auto | nvidia | nvidia-open | nouveau | amd | intel | or leave it blank to not install
GPU_EXTRA_PACKAGES="opengl" # opengl | vulkan | both
DESKTOP_PROFILE="plasma"    # xorg | xorg-minimal | gnome | plasma | or leave it blank to not install
ENABLE_DKMS=true            # true | false; works only for nvidia, otherwise it will be ignored
ENABLE_HVA=true             # true | false; (HVA -> Hardware Video Acceleration)
FORCE_WAYLAND_SESSION=false # true | false; # works only for plasma and gnome, otherwise it will be ignored; can cause bugs in gnome and gdm with nvidia proprietary driver

TERMINAL="alacritty"      # if none is defined, the default terminal of the desktop environment chosen above will be installed
EDITOR="vim"              # any terminal editor available at https://archlinux.org/packages/ or AUR, or leave it blank to not install
BROWSER="zen-browser-bin" # any available at https://archlinux.org/packages/ or AUR, or leave it blank to not install
AUR_HELPER="paru"         # any available at https://archlinux.org/packages/ or AUR, or leave it blank to not install

INSTALL_NETWORK_PKGS=true            # true | false
INSTALL_PACKAGE_MANAGER_PKGLIST=true # true | false
INSTALL_TERMINAL_TOOLS_PKGS=true     # true | false
INSTALL_FILESYSTEM_PKGS=true         # true | false
INSTALL_BLUETOOTH_PKGLIST=true       # true | false
INSTALL_MULTIMEDIA_PKGS=true         # true | false
INSTALL_FONTS_PKGS=true              # true | false
INSTALL_AURBUILDER=true              # true | false; A helper to install packages from aur logged in as root using yay (or makepkg if yay is not installed)

ADDITIONAL_PKGLIST=(
	# packages to install from official repository after system installation
)
ADDITIONAL_AUR_PKGLIST=(
	# packages to install from aur using aurbuilder
	octopi
)

KERNEL_PARAMETERS=( # Do not change this unless you know what you are doing
	rw
	nowatchdog
	quiet
	splash
	"zswap.enabled=0"
)

########## EDIT THIS SETTINGS ↑ ##########

BASE_SYSTEM_PKGLIST=(
	base
	base-devel
	linux-firmware
	sof-firmware
	sudo
)

KERNEL_PKGLIST=(
	mkinitcpio
	"$KERNEL"
	"${KERNEL}-headers"
	"${CPU}-ucode"
)

HARDWARE_PKGLIST=(
	hwdetect
	mtools
)

NETWORK_PKGLIST=(
	networkmanager
	networkmanager-openvpn
	dhcpcd
	dnsmasq
	wpa_supplicant
	modemmanager
	usb_modeswitch
)

PACKAGE_MANAGER_PKGLIST=(
	reflector
	pkgfile
	rebuild-detector
	pacman-contrib
	# BEGIN optional dependencies from `pacman-contrib`
	diffutils
	fakeroot
	findutils
	mlocate
	perl
	# END optional dependencies from `pacman-contrib`️
)

TERMINAL_PKGLIST=(
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
)

FILESYSTEM_PKGLIST=(
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

BLUETOOTH_PKGLIST=(
	bluez
	bluez-hid2hci
	bluez-libs
	bluez-utils
)

MULTIMEDIA_PKGLIST=(
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

FONTS_PKGLIST=(
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

EXTRA_PKGLIST=()

AUR_PKGLIST=()

XORG_PKGLIST=(
	xorg
)

XORG_MINIMAL_PKGLIST=(
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

GNOME_PKGLIST=(
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
	"${TERMINAL:-gnome-terminal}"
)

PLASMA_PKGLIST=(
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
	sddm
	"${TERMINAL:-konsole}"
)

[ -d /sys/firmware/efi/efivars ] || BOOT_LOADER="grub"

[[ "$KERNEL" =~ cachyos || "$GPU" = "auto" ]] && ENABLE_CACHYOS_REPO=true

if [ -n "$BROWSER" ]; then
	if pacman -Ss "$BROWSER"; then
		EXTRA_PKGLIST+=("$BROWSER")
	else
		AUR_PKGLIST+=("$BROWSER")
	fi
fi

if [ -n "$EDITOR" ]; then
	if pacman -Ss "$EDITOR"; then
		EXTRA_PKGLIST+=("$EDITOR")
	else
		AUR_PKGLIST+=("$EDITOR")
	fi
fi

if [ -n "$AUR_HELPER" ]; then
	if pacman -Ss "$AUR_HELPER"; then
		EXTRA_PKGLIST+=("$AUR_HELPER")
	else
		AUR_PKGLIST+=("$AUR_HELPER")
	fi
fi

EXTRA_PKGLIST+=("${ADDITIONAL_PKGLIST[@]}")
AUR_PKGLIST+=("${ADDITIONAL_AUR_PKGLIST[@]}")

is_integer() {
	[[ "$1" =~ ^[0-9]+$ ]]
}

func_exists() {
	local function_name=$1
	declare -F "$function_name" &>/dev/null
}

color() {
	local color=$1
	shift
	local text=$*

	red() {
		echo -e "\033[1;31m${text}\033[0m"
	}

	green() {
		echo -e "\033[1;32m${text}\033[0m"
	}

	yellow() {
		echo -e "\033[1;33m${text}\033[0m"
	}

	blue() {
		echo -e "\033[1;34m${text}\033[0m"
	}

	purple() {
		echo -e "\033[1;35m${text}\033[0m"
	}

	cyan() {
		echo -e "\033[1;36m${text}\033[0m"
	}

	if func_exists "$color"; then
		"$color"
	elif is_integer "$color"; then
		echo -e "\033[1;${color}m${text}\033[0m"
	else
		text="Invalid color name/code: ${color}"
		red
		echo -e "Usage: $(
			text="color"
			cyan
		) $(
			text="purple something cool"
			yellow
		)"
		echo -e "       $(
			text="color"
			cyan
		) $(
			text="35 something cool"
			yellow
		)"
		exit 1
	fi
}

error() {
	echo "$(color red "[ERROR]") $1"
}

confirm() {
	while true; do
		read -r -p "$* [$(color green Y)/$(color red n)]: " yn
		case $yn in
		[Yy]*)
			echo
			return 0
			;;
		[Nn]*)
			echo
			return 1
			;;
		esac
	done
}

banner() {
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
	edge="$(color "$secondary_color" "$edge")"
	pad="$(color "$secondary_color" "$pad")"
	title="$(color "$primary_color" "$title")"
	separator="$(color "$secondary_color" "$(printf "%$((width - 4))s" | tr ' ' '-')")"

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
		echo -e "${pad} $key $(color "$primary_color" "$value") $(printf "%$((width - ${#key} - ${#value} - 7))s")${pad}"
	done
	[ "${#info_lines}" -gt 0 ] && printf "${pad}%$((width - 4))s${pad}\n"
	echo "$edge"
	echo
}

arch_chroot() {
	# function created to be used with commands that use pipe or output redirection,
	# as the `arch-chroot` command does not handle them directly
	# usage: arch_chroot <command> [param_1] [param_2] ...
	# usage with redirect: arch_chroot 'echo "something" >/path/to/file'
	# usage with variable: arch_chroot "echo \"${something}\" >/path/to/file"
	# usage with pipe: arch_chroot 'echo "something with pipe" | grep with'
	local command
	command="$(printf "%q " "$@")"
	arch-chroot "$root_mountpoint" /usr/bin/bash -c "$command"
}

add_lines_to_file() {
	local file_path="$1"
	local mode="$2"
	local add_blank_line="$3"
	shift 3
	local lines=("$@")

	if [[ "$mode" == "w" || ! -f "$file_path" ]]; then
		local file_dir=$(dirname "$file_path")

		[ -d "$file_dir" ] || mkdir -p "$file_dir"
		{
			for line in "${lines[@]}"; do
				echo "$line"
			done
		} >"$file_path"
	else
		{
			[[ "$add_blank_line" == "true" ]] && echo ""
			for line in "${lines[@]}"; do
				echo "$line"
			done
		} >>"$file_path"
	fi

	chmod 644 "$file_path"
}

define_partitions_to_exclude() {
	export EXCLUDE_PARTITIONS=()
	local partitions=("$@")

	for partition in "${partitions[@]}"; do
		[[ "$partition" =~ _$ ]] && EXCLUDE_PARTITIONS+=("$partition")
	done
}

partition_must_be_exclude() {
	local partition="$1"

	[[ "${EXCLUDE_PARTITIONS[*]}" =~ $partition ]]
}

setup_optional_partition() {
	local partition="$1"
	local format_command="${2//{partition/}/$partition}"
	local mount_command="${3//{partition/}/$partition}"

	if ! partition_must_be_exclude "$partition"; then
		[ -n "$format_command" ] && eval "$format_command"
		[ -n "$mount_command" ] && eval "$mount_command"
	fi
}

setup_pacman() {
	local pacman_conf="${1}/etc/pacman.conf"

	sed -i 's/#Color/Color/' "$pacman_conf"
	sed -i "s/#ParallelDownloads = 5/ParallelDownloads = $PARALLEL_DOWNLOADS\nILoveCandy/" "$pacman_conf"

	if [[ "$ENABLE_MULTILIB" = true ]]; then
		local line
		line=$(grep -n "\[multilib\]" "$pacman_conf" | cut -d: -f1)

		sed -i "${line}s/#//" "$pacman_conf"
		sed -i "$((line + 1))s/#//" "$pacman_conf"
	fi

	chmod 644 "$pacman_conf"
}

add_repo() {
	local type="$1" # official | custom
	local repo_name="$2"
	local repo_url="$3"
	local pacman_conf="${root_mountpoint}/etc/pacman.conf"

	if [[ $type == "official" ]]; then
		local line=$(grep -n "\[core-testing\]" "$pacman_conf" | cut -d: -f1)

		line=$((line - 1))
		sed -i "${line}i\[$repo_name\]" "$pacman_conf"
		sed -i "$((line + 1))iInclude = $repo_url\\n" "$pacman_conf"
	elif [[ $type == "custom" ]]; then
		local sig_level="$4" # optional

		add_lines_to_file "$pacman_conf" "a" true \
			"[$repo_name]" \
			"SigLevel = $sig_level" \
			"Server = $repo_url"
	else
		echo "Invalid repository type"
		return 1
	fi

}

install_cachyos_repo() {

	run_first_setup() {
		local mirror_cachyos="https://mirror.cachyos.org/repo/x86_64/cachyos"
		local cachyos_packages=(
			"${mirror_cachyos}/cachyos-keyring-20240331-1-any.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-mirrorlist-18-1-any.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-v3-mirrorlist-18-1-any.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-v4-mirrorlist-6-1-any.pkg.tar.zst"
			"${mirror_cachyos}/pacman-7.0.0.r6.gc685ae6-2-x86_64.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-ananicy-rules-1:1.0.5-1-any.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-hooks-2025.01-1-any.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-kernel-manager-1.13.9-1-x86_64.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-settings-1:1.1.8-1-any.pkg.tar.zst"
			"${mirror_cachyos}/cachyos-rate-mirrors-8-1-any.pkg.tar.zst"
			"${mirror_cachyos}/chwd-1.11.5-2-x86_64.pkg.tar.zst"
		)

		[ "$BOOT_LOADER" = "systemd-boot" ] && cachyos_packages+=("${mirror_cachyos}/systemd-boot-manager-15-1-any.pkg.tar.zst")

		arch_chroot pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
		arch_chroot pacman-key --lsign-key F3B607488DB35A47
		arch_chroot pacman -U --noconfirm "${cachyos_packages[@]}"
	}

	add_repo_from_version() {
		local version="$1"

		if [[ $version != "v2" ]]; then
			add_repo "official" "cachyos-${version}" "/etc/pacman.d/cachyos-${version}-mirrorlist"
			add_repo "official" "cachyos-core-${version}" "/etc/pacman.d/cachyos-${version}-mirrorlist"
			add_repo "official" "cachyos-extra-${version}" "/etc/pacman.d/cachyos-${version}-mirrorlist"
		fi

		add_repo "official" "cachyos" "/etc/pacman.d/cachyos-mirrorlist"
	}

	add_cachyos_repo() {
		local repo_v4=$("${root_mountpoint}/lib/ld-linux-x86-64.so.2" --help | grep supported | grep v4)
		local repo_v3=$("${root_mountpoint}/lib/ld-linux-x86-64.so.2" --help | grep supported | grep v3)
		local repo_v2=$("${root_mountpoint}/lib/ld-linux-x86-64.so.2" --help | grep supported | grep v2)

		if [[ $repo_v4 ]]; then
			add_repo_from_version "v4" && return 0
			return 1
		elif [[ $repo_v3 ]]; then
			add_repo_from_version "v3" && return 0
			return 1
		elif [[ $repo_v2 ]]; then
			add_repo_from_version "v2" && return 0
			return 1
		fi
	}

	run_first_setup || return 1
	add_cachyos_repo || return 1
	arch_chroot pacman -Syyu --noconfirm
	arch_chroot cachyos-rate-mirrors
}

enable_zram() {
	local zram_generator_conf="/etc/systemd/zram-generator.conf"
	local zram_generator_conf_lines=(
		"[zram0]"
		"zram-size = min(ram / 10, ram / 2)"
		"compression-algorithm = zstd lz4 (type=huge)"
		"swap-priority = 100"
		"fs-type = swap"
		"mount-point = /run/zram-swap"
	)

	arch_chroot pacman -S --noconfirm zram-generator
	add_lines_to_file "$zram_generator_conf" "w" false "${zram_generator_conf_lines[@]}"
}

remove_duplicates() {
	# essa função concatena p
	local items=("$@")
	local array=()

	for item in "${items[@]}"; do
		[[ ! "${array[*]}" =~ $item ]] && array+=("$item")
	done

	echo "${array[@]}"
}

convert_keymap() {
	local keymap="$1"

	if localectl list-keymaps | grep -qe "^$keymap\$"; then
		echo "$keymap" | sed -E 's/-abnt2$//;s/-nodeadkeys$//;s/-latin1$//;s/-legacy$//'
	else
		color yellow "Warning: Keymap '$keymap' is not recognized. Using default 'us'."
		echo "us"
	fi
}

set_keyboard_layout() {
	local root_dir="${1:-}"
	local layout

	if [[ -n "$KEYMAP" ]]; then
		layout=$(convert_keymap "$KEYMAP")
	else
		layout="us"
	fi

	local xorg_conf="${root_dir}/etc/X11/xorg.conf.d/00-keyboard.conf"
	local sddm_conf="${root_dir}/etc/sddm.conf.d/keyboard.conf"
	local plasma_conf="${root_dir}/etc/xdg/kxkbrc"

	if [[ -z "$DESKTOP_PROFILE" ]]; then
		color red "Error: DESKTOP_PROFILE is not set."
		color yellow "Set DESKTOP_PROFILE to 'xorg', 'plasma', or 'gnome'."
		return 1
	fi

	color cyan "Setting keyboard layout to '$layout' for '$DESKTOP_PROFILE'..."

	configure_xorg() {
		mkdir -p "$(dirname "$xorg_conf")"
		local mode="w"
		local add_blank="false"
		[[ -f "$xorg_conf" ]] && mode="a" && add_blank="true"

		color blue "Updating $xorg_conf..."
		add_lines_to_file "$xorg_conf" "$mode" "$add_blank" \
			"Section \"InputClass\"" \
			"    Identifier \"Keyboard Layout\"" \
			"    MatchIsKeyboard \"on\"" \
			"    Option \"XkbLayout\" \"$layout\"" \
			"EndSection"
	}

	configure_plasma() {
		mkdir -p "$(dirname "$sddm_conf")"
		local mode="w"
		local add_blank="false"
		[[ -f "$sddm_conf" ]] && mode="a" && add_blank="true"

		color blue "Updating $sddm_conf..."
		add_lines_to_file "$sddm_conf" "$mode" "$add_blank" \
			"[General]" \
			"InputMethod=" \
			"" \
			"[Keyboard]" \
			"Layout=$layout"

		mkdir -p "$(dirname "$plasma_conf")"
		mode="w"
		add_blank="false"
		[[ -f "$plasma_conf" ]] && mode="a" && add_blank="true"

		color blue "Updating $plasma_conf..."
		add_lines_to_file "$plasma_conf" "$mode" "$add_blank" \
			"[Layout]" \
			"LayoutList=$layout" \
			"Use=true"
	}

	configure_gnome() {
		color blue "Configuring GNOME keyboard layout..."
		for user_home in "${root_dir}/home/"*; do
			local user
			user=$(basename "$user_home")

			if id "$user" &>/dev/null; then
				sudo -u "$user" dbus-launch gsettings set org.gnome.desktop.input-sources sources "[('xkb', '$layout')]"
			fi
		done
	}

	case "$DESKTOP_PROFILE" in
	xorg)
		configure_xorg
		;;
	plasma)
		configure_xorg
		configure_plasma
		;;
	gnome)
		configure_xorg
		configure_gnome
		;;
	*)
		color red "Error: '$DESKTOP_PROFILE' is not valid. Use 'xorg', 'plasma', or 'gnome'."
		return 1
		;;
	esac

	color green "Keyboard configuration applied successfully! Reboot to ensure changes take effect."
}

umount_disks() {
	local exit_code=$1

	if [ "$exit_code" -eq 0 ]; then
		echo "Unmounting the disks..."
	else
		error "An error occurred during installation."
		echo "Unmounting the disks..."
	fi
	umount -R "$root_mountpoint"
	[ "$ENABLE_ZRAM" = false ] && swapoff "$swap_partition"
}

install() {
	########## start installation on live environment ##########
	# test connection
	echo "Check network connectivity with: ${PING_URL}..."
	if ! ping -c 1 "$PING_URL"; then
		error "Connect to the network first!"
		exit 1
	fi

	# setup pacman settings
	echo "Updating pacman.conf settings..."
	setup_pacman

	# initializes and populates GPG keys
	echo "Initializing and populating pacman keys..."
	pacman-key --init
	pacman-key --populate

	# update pacman database
	echo "Updating the pacman package list..."
	pacman -Syy --noconfirm

	# select mirrors
	echo "Configuring the reflector and raffling off mirrors..."
	local reflector_conf="/etc/xdg/reflector/reflector.conf"
	add_lines_to_file "$reflector_conf" "w" false \
		"--save /etc/pacman.d/mirrorlist" \
		"--ipv4" \
		"--ipv6" \
		"--protocol https" \
		"--country ${MIRROR_COUNTRIES}" \
		"--latest ${MIRROR_SERVERS_LIMIT}" \
		"--sort rate"
	systemctl start reflector.service

	# set keyboard layout
	echo "Loading keyboard layout: ${KEYMAP}..."
	loadkeys "$KEYMAP"

	# update the system clock
	echo "Setting the time zone to: ${TIMEZONE}..."
	timedatectl set-timezone "$TIMEZONE"

	# partition the disks
	$DISK_MANAGER "$DISK_DEVICE"
	echo -e "\n\nSet partition numbers (leave blank to use default values)\n"
	echo "Default:	BOOT ($(color cyan /dev/sda)): $(color cyan 1)"
	echo "		ROOT ($(color cyan /dev/sda)): $(color cyan 2)"
	echo "		HOME ($(color cyan /dev/sda)): $(color cyan 3)"
	echo "		SWAP ($(color cyan /dev/sda)): $(color cyan 4)"
	echo
	echo "NOTE: Specifically for the $(color purple HOME) partition, set the value \"$(color cyan _)\""
	echo "      if you didn't want to use a separate partition for it."
	echo
	read -r -p "BOOT ($(color cyan "$DISK_DEVICE")): " boot_partition_number
	read -r -p "ROOT ($(color cyan "$DISK_DEVICE")): " root_partition_number
	read -r -p "HOME ($(color cyan "$DISK_DEVICE")): " home_partition_number
	if [ "$ENABLE_ZRAM" = true ]; then
		local swap_partition_number="_"
	else
		read -r -p "SWAP ($(color cyan "$DISK_DEVICE")): " swap_partition_number
	fi
	echo -e "\n\n"
	local boot_partition="${DISK_DEVICE}${boot_partition_number:-1}"
	local root_partition="${DISK_DEVICE}${root_partition_number:-2}"
	local home_partition="${DISK_DEVICE}${home_partition_number:-3}"
	local swap_partition="${DISK_DEVICE}${swap_partition_number:-4}"
	export root_mountpoint="/mnt/archzen"
	local home_mountpoint="${root_mountpoint}/home"
	local boot_mountpoint="${root_mountpoint}/boot"

	define_partitions_to_exclude "$boot_partition" "$root_partition" "$home_partition" "$swap_partition"

	# format partitions
	echo "Formatting partitions..."
	local format
	case $FILESYSTEM in
	xfs)
		format="mkfs.xfs -f"
		;;
	ext4)
		format="mkfs.ext4"
		;;
	*)
		error "Invalid filesystem: $FILESYSTEM"
		exit 1
		;;
	esac
	$format "$root_partition"
	mkfs.fat -F 32 "$boot_partition"

	# mount partitions
	echo "Mounting partitions..."
	mount --mkdir "$root_partition" "$root_mountpoint"
	mount --mkdir "$boot_partition" "$boot_mountpoint"

	# format and mount optional partitions
	setup_optional_partition "$home_partition" "${format} {partition}" "mount --mkdir {partition} ${home_mountpoint}"
	setup_optional_partition "$swap_partition" "mkswap {partition}" "swapon {partition}"

	# install base system
	echo "Installing the base system..."
	pacstrap -K -P "$root_mountpoint" "${BASE_SYSTEM_PKGLIST[@]}"

	# install cachyos repo if true
	if [ "$ENABLE_CACHYOS_REPO" = true ]; then
		echo "Installing the CachyOS repository..."
		install_cachyos_repo
	fi

	# setup pacman on installed system
	setup_pacman $root_mountpoint
	cp /etc/pacman.d/mirrorlist "${root_mountpoint}/etc/pacman.d/mirrorlist"

	# Enable (or not) zram
	[ "$ENABLE_ZRAM" = true ] && enable_zram

	# install kernel and microcode
	echo "Installing the kernel and microcode..."
	arch_chroot pacman --needed --noconfirm -S "${KERNEL_PKGLIST[@]}"

	# install hardware packages
	echo "Installing hardware packages..."
	arch_chroot pacman --needed --noconfirm -S "${HARDWARE_PKGLIST[@]}"

	# install network packages
	if [ "$INSTALL_NETWORK_PKGS" = true ]; then
		echo "Installing network packages..."
		arch_chroot pacman --needed --noconfirm -S "${NETWORK_PKGLIST[@]}"
	fi

	# install package manager papckages
	if [ "$INSTALL_PACKAGE_MANAGER_PKGLIST" = true ]; then
		echo "Installing package manager packages..."
		arch_chroot pacman --needed --noconfirm -S "${PACKAGE_MANAGER_PKGLIST[@]}"
	fi

	# install terminal tools
	if [ "$INSTALL_TERMINAL_TOOLS_PKGS" = true ]; then
		echo "Installing terminal tools..."
		arch_chroot pacman --needed --noconfirm -S "${TERMINAL_PKGLIST[@]}"
		cp -f "$reflector_conf" "${root_mountpoint}/${reflector_conf}"
	fi

	# install filesystem packages
	if [ "$INSTALL_FILESYSTEM_PKGS" = true ]; then
		echo "Installing filesystem packages..."
		arch_chroot pacman --needed --noconfirm -S "${FILESYSTEM_PKGLIST[@]}"
	fi

	# install bluetooth packages
	if [ "$INSTALL_BLUETOOTH_PKGLIST" = true ]; then
		echo "Installing filesystem packages"
		arch_chroot pacman --needed --noconfirm -S "${BLUETOOTH_PKGLIST[@]}"
	fi

	# install multimedia packages
	if [ "$INSTALL_MULTIMEDIA_PKGS" = true ]; then
		echo "Installing multimedia packages..."
		arch_chroot pacman --needed --noconfirm -S "${MULTIMEDIA_PKGLIST[@]}"
	fi

	# install fonts
	if [ "$INSTALL_FONTS_PKGS" = true ]; then
		echo "Installing fonts..."
		arch_chroot pacman --needed --noconfirm -S "${FONTS_PKGLIST[@]}"
	fi

	# install extra packages
	if [ -n "${EXTRA_PKGLIST[*]}" ]; then
		echo "Installing extra packages..."
		if ! arch_chroot pacman --needed --noconfirm -S "${EXTRA_PKGLIST[@]}"; then
			echo "Error installing extra packages!"
		fi
	fi

	# install aur packages
	if [[ "$INSTALL_AURBUILDER" = true || -n "${AUR_PKGLIST[*]}" ]]; then
		echo "Installing AUR Builder..."
		if ! curl -L https://sirius-red.github.io/aurbuilder/install | sh -s -- --chroot "$root_mountpoint"; then
			error "Error installing AUR Builder"
		fi
		if [ -n "${AUR_PKGLIST[*]}" ]; then
			if ! aurbuilder --chroot "$root_mountpoint" install -y "${AUR_PKGLIST[@]}"; then
				error "Error installing AUR packages!"
			fi
		fi
	fi

	# set a default editor
	[ -n "$EDITOR" ] && echo "EDITOR=${EDITOR}" >>"${root_mountpoint}/etc/environment"

	# generate an fstab file
	echo "Generating the fstab file..."
	genfstab -U "$root_mountpoint" >>"${root_mountpoint}/etc/fstab"

	########### finalize system installation with chroot ##########
	# set the timezone
	echo "Setting the time zone of ${HOSTNAME} to: ${TIMEZONE}..."
	ln -sf "${root_mountpoint}/usr/share/zoneinfo/${TIMEZONE}" "${root_mountpoint}/etc/localtime"
	arch_chroot hwclock --systohc

	# set the system language
	echo "Setting the system language to: ${LANGUAGES[0]}"
	echo "Additional languages:"
	for lang in "${LANGUAGES[@]}"; do
		echo "- ${lang}"
		sed -i "s/#${lang}/${lang}/g" "${root_mountpoint}/etc/locale.gen"
	done
	arch_chroot locale-gen
	echo "LANG=${LANGUAGES[0]}" >"${root_mountpoint}/etc/locale.conf"
	echo "Setting the keyboard layout to: ${KEYMAP}"
	echo "KEYMAP=${KEYMAP}" >"${root_mountpoint}/etc/vconsole.conf"

	# setup network
	echo "Configuring the network... Hostname: ${HOSTNAME}"
	echo "${HOSTNAME}" >"${root_mountpoint}/etc/hostname"
	add_lines_to_file "${root_mountpoint}/etc/hosts" "w" false \
		"127.0.0.1    localhost" \
		"::1          localhost" \
		"127.0.0.1    ${HOSTNAME}.localdomain    ${HOSTNAME}"
	arch_chroot systemctl enable NetworkManager.service

	# create the initramfs
	echo "Creating the initramfs"
	arch_chroot mkinitcpio -P

	# user and groups management
	echo "Creating the user ${USER_NAME} and configuring the root user..."
	arch_chroot useradd --create-home --user-group --groups wheel,storage "$USER_NAME"
	chpasswd --root "$root_mountpoint" <<<"root:${ROOT_PASSWD}"
	chpasswd --root "$root_mountpoint" <<<"${USER_NAME}:${USER_PASSWD}"
	add_lines_to_file "${root_mountpoint}/etc/sudoers" "a" true \
		"Defaults insults" \
		"Defaults pwfeedback" \
		"Defaults passwd_timeout=${PASSWD_TIMEOUT}"
	add_lines_to_file "${root_mountpoint}/etc/sudoers.d/____${USER_NAME}" "w" false \
		"${USER_NAME} ALL=(ALL:ALL) ALL" \
		"%${USER_NAME} ALL=(ALL:ALL) ALL"

	# install boot loader
	echo "Installing the boot loader..."
	case $BOOT_LOADER in
	systemd-boot)
		local os_name="ArchZen Linux"
		local os_entry_name="${os_name// /}"
		# systemd-boot settings
		local sd_default=$(if [ "$ENABLE_DUAL_BOOT" = true ]; then echo "@saved"; else echo "${os_entry_name}.conf"; fi)
		local sd_timeout=3
		local sd_console_mode="max" # auto | max | keep
		local sd_editor="no"        # yes | no
		local partition_uuid=$(blkid -s UUID -o value "$root_partition")
		arch_chroot bootctl install
		add_lines_to_file "${root_mountpoint}/loader/loader.conf" "w" false \
			"default ${sd_default}" \
			"timeout ${sd_timeout}" \
			"console-mode ${sd_console_mode}" \
			"editor ${sd_editor}"
		add_lines_to_file "${root_mountpoint}/loader/entries/${os_entry_name}.conf" "w" false \
			"title   ${os_name}" \
			"options root=UUID=${partition_uuid} ${KERNEL_PARAMETERS[*]}" \
			"linux   /vmlinuz-${KERNEL}" \
			"initrd  /initramfs-${KERNEL}.img"
		add_lines_to_file "${root_mountpoint}/loader/entries/${os_entry_name}-fallback.conf" "w" false \
			"title   ${os_name} (Fallback)" \
			"options root=UUID=${partition_uuid} rw" \
			"linux   /vmlinuz-${KERNEL}" \
			"initrd  /initramfs-${KERNEL}-fallback.img"
		arch_chroot bootctl update
		;;
	grub)
		local grub_file="${root_mountpoint}/etc/default/grub"
		local current_kernel_params=("$(grep '^GRUB_CMDLINE_LINUX_DEFAULT="' <"$grub_file" | cut -d'"' -f2 | cut -d'"' -f1)")
		local kernel_params="$(remove_duplicates "${current_kernel_params[@]}" "${KERNEL_PARAMETERS[@]}")"
		boot_mountpoint="${boot_mountpoint//"$root_mountpoint"/}"
		arch_chroot pacman --noconfirm -S grub efibootmgr
		arch_chroot grub-install --target=x86_64-efi --efi-directory="$boot_mountpoint" --bootloader-id="$BOOTLOADER_ID"
		sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\".*\"/\"${kernel_params}\"/" "$grub_file"
		if [[ "$ENABLE_DUAL_BOOT" == true ]]; then
			arch_chroot pacman --noconfirm -S os-prober
			echo "GRUB_DISABLE_OS_PROBER=false" >>"$grub_file"
		fi
		arch_chroot grub-mkconfig -o /boot/grub/grub.cfg
		;;
	*)
		error "Invalid BOOT_LOADER value: ${GPU}"
		echo "No boot loader will be installed!"
		echo "Install manually after system installation is complete."
		;;
	esac

	# install gpu driver
	echo "Installing video drivers... GPU: ${GPU}"
	if [[ -n "$GPU" && "$ENABLE_CACHYOS_REPO" = true ]]; then
		case $GPU in
		auto)
			arch_chroot chwd -a
			;;
		nvidia | nvidia-open)
			arch_chroot chwd -i "${GPU}-dkms"
			;;
		nouveau | amd | intel)
			arch_chroot chwd -i "$GPU"
			;;
		*)
			error "Invalid GPU value: ${GPU}"
			echo "No GPU drivers will be installed!"
			echo "Install manually after system installation is complete."
			;;
		esac
	elif [ -n "$GPU" ]; then
		local gpu_packages driver opengl vulkan driver_hva libva_driver_name
		local gpu_packages=()
		local proceed=true
		case $GPU in
		nvidia | nvidia-open)
			# shellcheck disable=SC2001
			driver="${GPU}$(echo "${KERNEL//linux/}" | sed 's/zen\|hardened/dkms/')"
			opengl="opencl-nvidia"
			vulkan="nvidia-utils"
			driver_hva="libva-nvidia-driver"
			libva_driver_name="nvidia"
			;;
		nouveau)
			driver="xf86-video-nouveau"
			opengl="mesa"
			vulkan="vulkan-nouveau"
			driver_hva="libva-mesa-driver"
			libva_driver_name="nouveau"
			;;
		amd)
			driver="xf86-video-amdgpu"
			opengl="mesa"
			vulkan="vulkan-radeon"
			driver_hva="libva-mesa-driver"
			libva_driver_name="radeonsi"
			;;
		intel)
			driver="xf86-video-intel"
			opengl="mesa"
			vulkan="vulkan-intel"
			driver_hva="intel-media-driver"
			libva_driver_name="iHD"
			;;
		*)
			error "Invalid GPU value: ${GPU}"
			echo "No GPU drivers will be installed!"
			echo "Install manually after system installation is complete."
			proceed=false
			;;
		esac
		if [[ "$proceed" = true ]]; then
			gpu_packages+=("$driver")
			[[ "$GPU_EXTRA_PACKAGES" =~ opengl|vulkan|both && "$GPU" =~ nvidia|nvidia-open ]] && gpu_packages+=("nvidia-utils")
			[[ "$GPU_EXTRA_PACKAGES" =~ opengl|both ]] && gpu_packages+=("$opengl")
			[[ "$GPU_EXTRA_PACKAGES" =~ vulkan|both ]] && gpu_packages+=("$vulkan")
			if [[ "$ENABLE_MULTILIB" = true ]]; then
				[[ "$GPU_EXTRA_PACKAGES" =~ opengl|both ]] && gpu_packages+=("lib32-$opengl")
				[[ "$GPU_EXTRA_PACKAGES" =~ vulkan|both ]] && gpu_packages+=("lib32-$vulkan")
			fi
			if [ "$ENABLE_HVA" = true ]; then
				ENABLE_DKMS=true
				gpu_packages+=("$driver_hva")
				add_lines_to_file "${root_mountpoint}/etc/environment" "a" true \
					echo "# enable hardware video acceleration" \
					echo "LIBVA_DRIVER_NAME=${libva_driver_name}"
			fi
			if [[ "$DESKTOP_PROFILE" =~ gnome|plasma && "$FORCE_WAYLAND_SESSION" = true ]]; then
				add_lines_to_file "${root_mountpoint}/etc/environment" "a" true \
					"# force wayland session" \
					"XDG_SESSION_TYPE=wayland" \
					"WLR_NO_HARDWARE_CURSORS=1"
				if [[ "$GPU" =~ nvidia|nvidia-open ]]; then
					add_lines_to_file "${root_mountpoint}/etc/environment" "a" true \
						"# force GBM as backend" \
						"GBM_BACKEND=nvidia-drm" \
						"__GLX_VENDOR_LIBRARY_NAME=nvidia"
				fi
			else
				gpu_packages=(xorg-server "${gpu_packages[@]}")
			fi
			[[ "$GPU" =~ nvidia|nvidia-open ]] && gpu_packages+=(nvidia-settings)
			arch_chroot pacman --noconfirm -S "${gpu_packages[@]}"
			if [[ "$GPU" =~ nvidia|nvidia-open && "$ENABLE_DKMS" = true ]]; then
				sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "${root_mountpoint}/etc/mkinitcpio.conf"
				echo "options nvidia_drm modeset=1 fbdev=1" >"${root_mountpoint}/etc/modprobe.d/nvidia.conf"
				arch_chroot mkinitcpio -P
				case $BOOT_LOADER in
				systemd-bood)
					sed -i 's/^\(options\s*\)\(.*\)$/\1\2 nvidia_drm.modeset=1 nvidia_drm.fbdev=1/' "${root_mountpoint}/loader/entries/${os_entry_name}.conf"
					;;
				grub)
					sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ nvidia_drm.modeset=1 nvidia_drm.fbdev=1\"/' "${root_mountpoint}/etc/default/grub"
					arch_chroot grub-mkconfig -o /boot/grub/grub.cfg
					;;
				esac
			fi
		fi
	fi

	# install desktop profile
	echo "Installing \"${DESKTOP_PROFILE}\" desktop profile"
	local desktop_profile_installed=true
	arch_chroot pacman --noconfirm -S "${XORG_MINIMAL_PKGLIST[@]}"
	case $DESKTOP_PROFILE in
	xorg)
		arch_chroot pacman --noconfirm -S "${XORG_PKGLIST[@]}"
		;;
	xorg-minimal)
		true
		;;
	gnome)
		arch_chroot pacman --noconfirm -S "${GNOME_PKGLIST[@]}"
		arch_chroot systemctl enable gdm.service
		if [ "$FORCE_WAYLAND_SESSION" = true ]; then
			sed -i 's/#WaylandEnable=false/WaylandEnable=true/' "${root_mountpoint}/etc/gdm/custom.conf"
			cp -f "${root_mountpoint}/etc/udev/rules.d/61-gdm.rules" "${root_mountpoint}/etc/udev/rules.d/61-gdm.rules.backup"
			ln -s /dev/null "${root_mountpoint}/etc/udev/rules.d/61-gdm.rules"
		fi
		AUR_PKGLIST+=(
			nautilus-admin-gtk4
			extension-manager
		)
		;;
	plasma)
		arch_chroot pacman --noconfirm -S "${PLASMA_PKGLIST[@]}"
		arch_chroot systemctl enable sddm.service
		if [[ "${PLASMA_PKGLIST[*]}" =~ sddm ]]; then
			add_lines_to_file "/usr/lib/sddm/sddm.conf.d/general.conf" "w" false \
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
			add_lines_to_file "/etc/sddm.conf.d/01-wayland.conf" "w" false \
				'[General]' \
				'DisplayServer=wayland' \
				'GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell' \
				'' \
				'[Wayland]' \
				'CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1'
		fi
		;;
	*)
		desktop_profile_installed=false
		error "Invalid DESKTOP_PROFILE value: ${DESKTOP_PROFILE}"
		echo "No desktop environments will be installed!"
		echo "Install manually after system installation is complete."
		;;
	esac
	[[ "$desktop_profile_installed" = true ]] && set_keyboard_layout "$root_mountpoint"

	# complete installation
	umount_disks 0
	confirm "Installation complete, do you want to reboot your system now?" && reboot
}

set -e
setfont "$TERMINAL_FONT"
clear
banner "cyan" "purple" "#" \
	"ArchZen" \
	"author:{{PROJECT_AUTHOR}}" \
	"project_url:{{PROJECT_URL}}" \
	"license:{{LICENSE_NAME}}" \
	"ref:https://wiki.archlinux.org/index.php/Installation_guide" \
	"ref:{{LICENSE_URL}}" \
	"ref:https://www.gnu.org/licenses/gpl-3.0.html"
confirm "Do you want to start the installation now?" || exit
install || umount_disks 1
