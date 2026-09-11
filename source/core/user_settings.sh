#!/usr/bin/env bash

# >>>>>>>>>>>>>>>>>>>>>>>> Default Settings >>>>>>>>>>>>>>>>>>>>>>>>
GENERAL_LOCALE="en_US.UTF-8"
GENERAL_KB_LAYOUT="us"
GENERAL_KB_VARIANT="intl,altgr-intl"
GENERAL_TIMESTAMP_TIMEOUT=-1
GENERAL_REFLECTOR_MIRROR_COUNTRIES="US"
GENERAL_REFLECTOR_MIRROR_LIMIT=10
GENERAL_PACMAN_PARALLEL_DOWNLOADS=10
GENERAL_PACMAN_ENABLE_MULTILIB=true
GENERAL_SETUP_ZRAM=true
GENERAL_USE_SWAPFILE=true
GENERAL_USE_NVIDIA_OSS_DRIVERS=false
GENERAL_ENABLE_CACHYOS_KIT=false
WSL_ENABLE_GUI=true
WSL_ENABLE_INTEROP=true
WSL_USERNAME="archzen"
# <<<<<<<<<<<<<<<<<<<<<<<< Default Settings <<<<<<<<<<<<<<<<<<<<<<<<

declare __config_file=""
if [[ "$ARCHZEN_IS_RUNNING_FROM_BINARY" == true ]]; then
	__config_file="/etc/archzen.conf"
else
	__config_file="${PWD}/archzen.conf"
fi

if [[ ! -f "$__config_file" ]]; then
	declare __template_config
	__template_config="$(dirname "$__source_dir")/archzen.conf"
	if [[ -f "$__template_config" ]]; then
		if [[ "$ARCHZEN_IS_RUNNING_FROM_BINARY" == true && $EUID -ne 0 ]]; then
			sudo cp -f "$__template_config" "$__config_file" 2>/dev/null || true
		else
			cp -f "$__template_config" "$__config_file" 2>/dev/null || true
		fi
	else
		if [[ "$ARCHZEN_IS_RUNNING_FROM_BINARY" == true && $EUID -ne 0 ]]; then
			sudo touch "$__config_file" 2>/dev/null || true
		else
			touch "$__config_file" 2>/dev/null || true
		fi
	fi
fi

function __load_config_val() {
	declare path="$1"
	declare target_var

	target_var="$(echo "$path" | sed 's/\./_/g; s/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | tr '[:lower:]' '[:upper:]')"
	declare val

	val="$(confmgr get "$__config_file" "$path" 2>/dev/null)"
	if [[ $? -eq 0 || -n "$val" ]]; then
		eval "$target_var=\"\$val\""
	fi
}

function __reload_config() {
	if [[ -f "$__config_file" ]]; then
		__load_config_val General.Locale
		__load_config_val General.KbLayout
		__load_config_val General.KbVariant
		__load_config_val General.TimestampTimeout
		__load_config_val General.ReflectorMirrorCountries
		__load_config_val General.ReflectorMirrorLimit
		__load_config_val General.PacmanParallelDownloads
		__load_config_val General.PacmanEnableMultilib
		__load_config_val General.SetupZram
		__load_config_val General.UseSwapfile
		__load_config_val General.UseNvidiaOssDrivers
		__load_config_val General.EnableCachyosKit
		__load_config_val General.Kernel
		__load_config_val General.UserShell
		__load_config_val General.AurHelper
		__load_config_val General.Editor
		__load_config_val General.DesktopProfile
		__load_config_val General.Terminal
		__load_config_val General.Explorer
		__load_config_val General.Browser

		__load_config_val WSL.EnableGUI
		__load_config_val WSL.EnableInterop
		__load_config_val WSL.Username
		__load_config_val WSL.UserPassword
		__load_config_val WSL.RootPassword
	fi
}

__reload_config
