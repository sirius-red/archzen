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
PING_URL="archlinux.org" # just to test the connection before installation
MIRROR_COUNTRIES="BR,US" # use `reflector --list-countries` to list available countries
MIRROR_SERVERS_LIMIT=20  # the higher the value, the longer the reflector will take to complete its execution
PARALLEL_DOWNLOADS=20    # I don't recommend a value higher than that, but it's up to you
ENABLE_MULTILIB=false    # enable (or not) the multilib repository

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
KERNEL="linux"         # linux | linux-lts | linux-zen | linux-hardened
ENABLE_DUAL_BOOT=false # true | false
CPU="intel"            # intel | amd

HOSTNAME="ArchZen"        # name by which the machine will be recognized on the network
BOOTLOADER_ID="$HOSTNAME" # UEFI entry name
USER_NAME="archzen"       # your username
USER_PASSWD="archzen"     # your password
ROOT_PASSWD="archzen"     # root user password
PASSWD_TIMEOUT=0          # number of minutes before the sudo password prompt times out, or 0 for no timeout

GPU="nvidia"                # nvidia | nvidia-opensource | amdgpu | intel | or leave it blank to not install
GPU_EXTRA_PACKAGES="opengl" # opengl | vulkan | both
ENABLE_DKMS=true            # true | false; only for nvidia
DESKTOP_PROFILE="plasma"    # xorg | xorg-minimal | gnome | plasma | or leave it blank to not install

EDITOR="vim"       # any available at https://archlinux.org/packages/ (I recommend a terminal-based one), or leave it blank to not install
BROWSER=""         # any available at https://archlinux.org/packages/, or leave it blank to not install

INSTALL_AURBUILDER=true # true | false; A helper to install packages from aur logged in as root using yay or makepkg

########## EDIT THIS SETTINGS ↑ ##########

BASE_SYSTEM_PKGLIST=(
	# system
	base
	base-devel
	sudo
	linux-firmware
	"$KERNEL"
	"${KERNEL}-headers"
	"${CPU}-ucode"
	# network
	networkmanager
	openssh
	# tools
	less
	wget
	curl
	reflector
	xdg-user-dirs
	neofetch
	vi
	# filesystems
	dosfstools
	ntfs-3g
	btrfs-progs
	exfat-utils
	gptfdisk
	fuse2
	fuse3
	fuseiso
	# generic drivers
	xf86-input-libinput
	# audio/video
	gstreamer
	gst-plugin-gtk
	gst-plugin-libcamera
	gst-plugin-msdk
	gst-plugin-opencv
	gst-plugin-pipewire
	gst-plugin-qml6
	gst-plugin-qmlgl
	gst-plugin-qsv
	gst-plugin-va
	gst-plugin-wpe
	gst-plugins-bad
	gst-plugins-base
	gst-plugins-good
	gst-plugins-ugly
	wireplumber
	gst-plugin-pipewire
	pipewire-alsa
	pipewire-audio
	pipewire-docs
	pipewire-ffado
	pipewire-jack
	pipewire-jack-client
	pipewire-pulse
	pipewire-roc
	pipewire-session-manager
	pipewire-v4l2
	pipewire-x11-bell
	pipewire-zeroconf
	realtime-privileges
 	rtkit
	# fonts
	noto-fonts
	noto-fonts-cjk
	noto-fonts-emoji
	noto-fonts-extra
	ttf-noto-nerd
	ttf-fira-code
 	ttf-firacode-nerd
  	ttf-jetbrains-mono
  	ttf-jetbrains-mono-nerd
)

[ -n "$EDITOR" ] && BASE_SYSTEM_PKGLIST+=("$EDITOR")
[ -n "$BROWSER" ] && BASE_SYSTEM_PKGLIST+=("$BROWSER")

XORG_PKGLIST=(
	xorg
)

XORG_MINIMAL_PKGLIST=(
	xorg-server
	xorg-xinit
	xorg-xclock
	xterm
	htop
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
	gnome-terminal
	gnome-tweaks
	fwupd
	networkmanager
	openssh
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
	yelp
	gnome-photos
	gnome-sound-recorder
	sysprof
)

PLASMA_PKGLIST=(
	plasma-meta
	power-profiles-daemon
	konsole
	dolphin
	dolphin-plugins
	kate
	ark
	colord-kde
	gwenview
	kdegraphics-thumbnailers
	spectacle
	dragon
	elisa
	ffmpegthumbs
	kmix
	kdeconnect
	kdenetwork-filesharing
	kio-fuse
	kio-admin
	kio-extras
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
)

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

print_error() {
	local message=$1
	echo -e "Error in $(color red "${BASH_SOURCE[1]}") at line $(color red "${BASH_LINENO[0]}"): $(color red "$message")"
}

yesno() {
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

install() {
	########## start installation on live environment ##########
	# test connection
	echo "Check network connectivity with: ${PING_URL}..."
	if ! ping -c 1 "$PING_URL"; then
		print_error "Connect to the network first!"
		exit 1
	fi

	# setup pacman settings
	echo "Updating pacman.conf settings..."
	local pacman_conf="/etc/pacman.conf"
	sed -i 's/#Color/Color/' "$pacman_conf"
	sed -i "s/#ParallelDownloads = 5/ParallelDownloads = $PARALLEL_DOWNLOADS\nILoveCandy/" "$pacman_conf"
	if [[ "$ENABLE_MULTILIB" = true ]]; then
		local line
		line=$(grep -n "\[multilib\]" "$pacman_conf" | cut -d: -f1)
		sed -i "${line}s/#//" "$pacman_conf"
		sed -i "$((line + 1))s/#//" "$pacman_conf"
	fi

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
	[ -e "$reflector_conf" ] && rm "$reflector_conf"
	{
		echo "--save /etc/pacman.d/mirrorlist"
		echo "--ipv4"
		echo "--ipv6"
		echo "--protocol https"
		echo "--country ${MIRROR_COUNTRIES}"
		echo "--latest ${MIRROR_SERVERS_LIMIT}"
		echo "--sort rate"
	} >"$reflector_conf"
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
	echo "NOTE: Specifically for the $(color purple HOME) partition, set the value $(color cyan 0) if you didn't want to use a separate partition for it."
	echo
	read -r -p "BOOT ($(color cyan "$DISK_DEVICE")): " boot_partition_number
	read -r -p "ROOT ($(color cyan "$DISK_DEVICE")): " root_partition_number
	read -r -p "HOME ($(color cyan "$DISK_DEVICE")): " home_partition_number
	read -r -p "SWAP ($(color cyan "$DISK_DEVICE")): " swap_partition_number
	echo -e "\n\n"
	local boot_partition="${DISK_DEVICE}${boot_partition_number:-1}"
	local root_partition="${DISK_DEVICE}${root_partition_number:-2}"
	local home_partition="${DISK_DEVICE}${home_partition_number:-3}"
	local swap_partition="${DISK_DEVICE}${swap_partition_number:-4}"
	export root_mountpoint="/mnt/archzen"
	local home_mountpoint="${root_mountpoint}/home"
	local boot_mountpoint="${root_mountpoint}/boot"

	# format partitions
	mkfs.ext4 "$root_partition"
	mkfs.fat -F 32 "$boot_partition"
	[[ ! "$home_partition" =~ 0$ ]] && mkfs.ext4 "$home_partition"
	mkswap "$swap_partition"

	# mount partitions
	mount --mkdir "$root_partition" "$root_mountpoint"
	mount --mkdir "$boot_partition" "$boot_mountpoint"
	[[ ! "$home_partition" =~ 0$ ]] && mount --mkdir "$home_partition" "$home_mountpoint"
	swapon "$swap_partition"

	# install base system
	echo "Installing the base system..."
	pacstrap -K -P "$root_mountpoint" "${BASE_SYSTEM_PKGLIST[@]}"
	cp -f "$reflector_conf" "${root_mountpoint}/${reflector_conf}"

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
	{
		echo "127.0.0.1    localhost"
		echo "::1          localhost"
		echo "127.0.0.1    ${HOSTNAME}.localdomain    ${HOSTNAME}"
	} >>"${root_mountpoint}/etc/hosts"
	arch_chroot systemctl enable NetworkManager.service

	# create the initramfs
	echo "Creating the initramfs"
	arch_chroot mkinitcpio -P

	# user and groups management
	echo "Creating the user ${USER_NAME} and configuring the root user..."
	arch_chroot useradd --create-home --user-group --groups wheel,storage "$USER_NAME"
	chpasswd --root "$root_mountpoint" <<<"root:${ROOT_PASSWD}"
	chpasswd --root "$root_mountpoint" <<<"${USER_NAME}:${USER_PASSWD}"
	{
		echo "Defaults insults"
		echo "Defaults pwfeedback"
		echo "Defaults passwd_timeout=${PASSWD_TIMEOUT}"
	} >>"${root_mountpoint}/etc/sudoers"
	{
		echo "${USER_NAME} ALL=(ALL:ALL) ALL"
		echo "%${USER_NAME} ALL=(ALL:ALL) ALL"
	} >>"${root_mountpoint}/etc/sudoers.d/____${USER_NAME}"

	# sets the default editor if it is not blank
	[ -n "$EDITOR" ] && echo "EDITOR=${EDITOR}" >>"${root_mountpoint}/etc/environment"

	# install bootloader (grub)
	echo "Installing the boot loader..."
	boot_mountpoint="${boot_mountpoint//"$root_mountpoint"/}"
	pacstrap "$root_mountpoint" grub efibootmgr
	arch_chroot grub-install --target=x86_64-efi --efi-directory="$boot_mountpoint" --bootloader-id="$BOOTLOADER_ID"
	if [[ "$ENABLE_DUAL_BOOT" == true ]]; then
		pacstrap "$root_mountpoint" os-prober
		echo "GRUB_DISABLE_OS_PROBER=false" >>"${root_mountpoint}/etc/default/grub"
	fi
	arch_chroot grub-mkconfig -o /boot/grub/grub.cfg

	# install gpu driver
	echo "Installing video drivers... GPU: ${GPU}"
	if [ -n "$GPU" ]; then
		local driver opengl vulkan gpu_packages
		local gpu_packages=(xorg-server xorg-xinit)
		local proceed=true
		case $GPU in
		nvidia)
			# shellcheck disable=SC2001
			driver="nvidia$(echo "${KERNEL//linux/}" | sed 's/zen\|hardened/dkms/')"
			opengl="nvidia-utils"
			vulkan="nvidia-utils"
			;;
		amdgpu | intel | nvidia-opensource)
			driver="xf86-video-${GPU//nvidia-opensource/nouveau}"
			opengl="mesa"
			vulkan="vulkan-${GPU//amdgpu/radeon}"
			ENABLE_DKMS=false
			;;
		*)
			print_error "Invalid GPU value: ${GPU}"
			echo "No GPU drivers will be installed!"
			echo "Install manually after system installation is complete."
			ENABLE_DKMS=false
			proceed=false
			;;
		esac
		if [[ "$proceed" = true ]]; then
			gpu_packages+=("$driver")
			[[ "$GPU_EXTRA_PACKAGES" =~ opengl|both ]] && gpu_packages+=("$opengl")
			[[ "$GPU_EXTRA_PACKAGES" =~ vulkan|both ]] && gpu_packages+=("$vulkan")
			if [[ "$ENABLE_MULTILIB" = true ]]; then
				[[ "$GPU_EXTRA_PACKAGES" =~ opengl|both ]] && gpu_packages+=("lib32-$opengl")
				[[ "$GPU_EXTRA_PACKAGES" =~ vulkan|both ]] && gpu_packages+=("lib32-$vulkan")
			fi
			pacstrap "$root_mountpoint" "${gpu_packages[@]}"
		fi
		if [[ "$ENABLE_DKMS" = true ]]; then
			sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "${root_mountpoint}/etc/mkinitcpio.conf"
			sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ nvidia_drm.modeset=1\"/' "${root_mountpoint}/etc/default/grub"
			arch_chroot mkinitcpio -P
			arch_chroot grub-mkconfig -o /boot/grub/grub.cfg
		fi
	fi

	# install desktop profile
	echo "Installing the desktop profile... PROFILE: ${DESKTOP_PROFILE}"
	case $DESKTOP_PROFILE in
	xorg)
		pacstrap "$root_mountpoint" "${XORG_PKGLIST[@]}"
		;;
	xorg-minimal)
		pacstrap "$root_mountpoint" "${XORG_MINIMAL_PKGLIST[@]}"
		;;
	gnome)
		pacstrap "$root_mountpoint" "${GNOME_PKGLIST[@]}"
		arch_chroot systemctl enable gdm.service
		[[ "$ENABLE_DKMS" = true ]] && ln -s /dev/null "${root_mountpoint}/etc/udev/rules.d/61-gdm.rules"
		;;
	plasma)
		pacstrap "$root_mountpoint" "${PLASMA_PKGLIST[@]}"
		arch_chroot systemctl enable sddm.service
		;;
	*)
		print_error "Invalid DESKTOP_PROFILE value: ${DESKTOP_PROFILE}"
		echo "No desktop environments will be installed!"
		echo "Install manually after system installation is complete."
		;;
	esac

	install_aurbuilder() {
		curl -L https://sirius-red.github.io/aurbuilder/install | sh -s -- --chroot "$root_mountpoint"
		arch_chroot aurbuilder self create
	}

	[[ "$EXPERIMENTAL_INSTALL_AURBUILDER" = true || -n "${EXPERIMENTAL_AUR_PKGLIST[*]}" ]] && install_aurbuilder

	[ -n "${EXPERIMENTAL_AUR_PKGLIST[*]}" ] && arch_chroot aurbuilder "${EXPERIMENTAL_AUR_PKGLIST[@]}"

	# umount disks and reboot
	echo "Unmounting the disks..."
	umount -R "$root_mountpoint"
	swapoff "$swap_partition"

	yesno "Installation complete, do you want to reboot your system now?" && reboot
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
yesno "Do you want to start the installation now?" && install
