#!/usr/bin/env bash

function __show_version() {
	echo "ArchZen $(__bright_green "v${__VERSION}")"
}

function __init() {
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
	if __func_exists __reload_config; then
		__reload_config
	fi
	__banner "${banner_args[@]}"
	__ensure_deps
}

function __finish() {
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

	if __variable_file_exists "$__VAR_FIRST_LOGIN_RUN"; then
		rm -rf "$(realpath "$__FIRST_LOGIN_SCRIPT" 2>>"${__LOG_FILE}")" &>>"${__LOG_FILE}"
	fi

	if $__FORCE_REBOOT_SYSTEM; then
		while [ $__FORCE_REBOOT_SYSTEM_TIME -ge 0 ]; do
			trap 'exit 1' INT

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
