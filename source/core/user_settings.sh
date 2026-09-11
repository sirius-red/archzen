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

if [[ -z "$__ARCHZEN_FLAG_CONFIG" ]]; then
	if [[ -f "$HOME/.archzen.conf" ]]; then
		__ARCHZEN_FLAG_CONFIG="$HOME/.archzen.conf"
	else
		__ARCHZEN_FLAG_CONFIG="/etc/archzen.conf"
	fi
fi
declare -gx __ARCHZEN_FLAG_CONFIG

if [[ ! -f "$__ARCHZEN_FLAG_CONFIG" ]]; then
	declare __template_config
	__template_config="$(dirname "$__source_dir")/archzen.conf"
	if [[ -f "$__template_config" ]]; then
		if [[ "$ARCHZEN_IS_RUNNING_FROM_BINARY" == true && $EUID -ne 0 ]]; then
			sudo cp -f "$__template_config" "$__ARCHZEN_FLAG_CONFIG" 2>/dev/null || true
		else
			cp -f "$__template_config" "$__ARCHZEN_FLAG_CONFIG" 2>/dev/null || true
		fi
	else
		if [[ "$ARCHZEN_IS_RUNNING_FROM_BINARY" == true && $EUID -ne 0 ]]; then
			sudo touch "$__ARCHZEN_FLAG_CONFIG" 2>/dev/null || true
		else
			touch "$__ARCHZEN_FLAG_CONFIG" 2>/dev/null || true
		fi
	fi
fi

function __reload_config() {
	if [[ -f "$__ARCHZEN_FLAG_CONFIG" ]]; then
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.Locale
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.KbLayout
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.KbVariant
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.TimestampTimeout
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.ReflectorMirrorCountries
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.ReflectorMirrorLimit
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.PacmanParallelDownloads
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.PacmanEnableMultilib
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.SetupZram
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.UseSwapfile
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.UseNvidiaOssDrivers
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.EnableCachyosKit
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.Kernel
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.UserShell
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.AurHelper
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.Editor
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.DesktopProfile
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.Terminal
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.Explorer
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" General.Browser

		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" WSL.EnableGUI
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" WSL.EnableInterop
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" WSL.Username
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" WSL.UserPassword
		confmgr get --export "$__ARCHZEN_FLAG_CONFIG" WSL.RootPassword
	fi
}

__reload_config
