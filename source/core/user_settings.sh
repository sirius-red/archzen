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


function __reload_config() {
	if [[ -f "$__config_file" ]]; then
		confmgr get --export "$__config_file" General.Locale
		confmgr get --export "$__config_file" General.KbLayout
		confmgr get --export "$__config_file" General.KbVariant
		confmgr get --export "$__config_file" General.TimestampTimeout
		confmgr get --export "$__config_file" General.ReflectorMirrorCountries
		confmgr get --export "$__config_file" General.ReflectorMirrorLimit
		confmgr get --export "$__config_file" General.PacmanParallelDownloads
		confmgr get --export "$__config_file" General.PacmanEnableMultilib
		confmgr get --export "$__config_file" General.SetupZram
		confmgr get --export "$__config_file" General.UseSwapfile
		confmgr get --export "$__config_file" General.UseNvidiaOssDrivers
		confmgr get --export "$__config_file" General.EnableCachyosKit
		confmgr get --export "$__config_file" General.Kernel
		confmgr get --export "$__config_file" General.UserShell
		confmgr get --export "$__config_file" General.AurHelper
		confmgr get --export "$__config_file" General.Editor
		confmgr get --export "$__config_file" General.DesktopProfile
		confmgr get --export "$__config_file" General.Terminal
		confmgr get --export "$__config_file" General.Explorer
		confmgr get --export "$__config_file" General.Browser

		confmgr get --export "$__config_file" WSL.EnableGUI
		confmgr get --export "$__config_file" WSL.EnableInterop
		confmgr get --export "$__config_file" WSL.Username
		confmgr get --export "$__config_file" WSL.UserPassword
		confmgr get --export "$__config_file" WSL.RootPassword
	fi
}

__reload_config
