#!/usr/bin/env bash

# shellcheck disable=SC2120
function action_exec_func() {
	declare func_name=""
	declare -a extra_args=()

	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		elif [[ -z "$func_name" ]]; then
			func_name="$arg"
		else
			extra_args+=("$arg")
		fi
	done

	if [[ -z "$func_name" ]]; then
		__error "Function name required"
		return 1
	fi

	if ! __func_exists "$func_name"; then
		__error "Function not exists: $(__error_params "$func_name")"
		return 1
	fi

	"$func_name" "${extra_args[@]}"
}

# shellcheck disable=SC2120
function action_install_archzen() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

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
		'if [[ "$1" =~ ^version$|^v$|^--version$|^-v$|^help$|^h$|^--help$|^-h$ || -z "$1" || ( "$1" =~ ^install$|^i$ && "$2" =~ ^self$|^s$ ) ]]; then'
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
			{ [[ -f "${__PWD}/archzen.yml" ]] && cp -f "${__PWD}/archzen.yml" "$__ARCHZEN_DIR"; true; } &&
			{ [[ -f "${__PWD}/archzen.json" ]] && cp -f "${__PWD}/archzen.json" "$__ARCHZEN_DIR"; true; } &&
			{ [[ -f "${__PWD}/archzen.conf" ]] && cp -f "${__PWD}/archzen.conf" "$__ARCHZEN_DIR"; true; } &&
			{ [[ -f "${__PWD}/archzen.conf" ]] && cp -f "${__PWD}/archzen.conf" "${__ROOT}/etc/archzen.conf"; true; } &&
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

# shellcheck disable=SC2120
function action_install_archlinux() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

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
    in the "GENERAL_DESKTOP_PROFILE" variable in the "archzen.sh" file)
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

	__setup_pacman || return 1
	archinstall --advanced --config "${__ARCHINSTALL_PRESET}" || return 1

	declare current_root="$__ROOT"
	__set_global_variables "$__MOUNT_DIR" "$__FORCE" "$__ARCHZEN_IS_RUNNING_FROM_BINARY"

	action_install_archzen &&
		__add_lines_to_file "$__FIRST_LOGIN_SCRIPT" w false "${__FIRST_LOGIN_SCRIPT_LINES[@]}" &&
		__setup_sudoers

	__set_global_variables "$current_root" "$__FORCE" "$__ARCHZEN_IS_RUNNING_FROM_BINARY"
}

# shellcheck disable=SC2120
function action_setup_zram() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

	$GENERAL_SETUP_ZRAM || return 0
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

		if [[ $GENERAL_USE_SWAPFILE ]]; then
			__setup_swapfile &>>"$__LOG_FILE" || __warn "Swapfile was not configured correctly"
		fi
	else
		__error "Error configuring zram"
	fi

	return $?
}

# shellcheck disable=SC2120
function action_setup_bootloader() {
	$__IS_WSL && return

	declare bootloader="${1:-auto}"
	declare gen_scripts="${2:-true}"

	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

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

# shellcheck disable=SC2120
function action_setup_wsl() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

	$__IS_WSL || return 0

	declare -i return_code=0

	__title "Configuring WSL"

	function __set_default_user() {
		[ -n "$__USERNAME" ] || return 0

		__title "Setting default WSL user: $(__title_params "$__USERNAME")"

		if __confedit set "$__WSL_CONF" default "$__USERNAME" user --create &>>"$__LOG_FILE"; then
			__success "Default WSL user configured successfully: $(__success_params "$__USERNAME")"
			return 0
		else
			__error "Error setting default WSL user: $(__error_params "$__USERNAME")"
			return 1
		fi
	}

	function __setup_wsl_gui() {
		$WSL_ENABLE_GUI || return 0

		declare -i exit_code=0
		declare v='d3d12'
		declare env_file="${__ROOT}/etc/environment"

		__title "Configuring WSL GUI support"

		if [ ${#__WSL_GUI_PKGLIST[@]} -gt 0 ]; then
			__install_pkglist "${__WSL_GUI_PKGLIST[@]}" || exit_code=1
		fi

		for k in GALLIUM_DRIVER LIBVA_DRIVER_NAME; do
			if __confedit set "$env_file" "$k" "$v" --format conf --create &>>"$__LOG_FILE"; then
				__success "Environment variable configured successfully: $(__success_params "${k}=${v}")"
			else
				__error "Error setting environment variable: $(__error_params "${k}=${v}")"
				exit_code=1
			fi
		done

		return $exit_code
	}

	function __setup_wsl_interop() {
		__title "Configuring WSL interop"

		if __confedit set "$__WSL_CONF" enabled "$WSL_ENABLE_INTEROP" interop --create &>>"$__LOG_FILE"; then
			__success "WSL interop configured successfully: $(__success_params "enabled=${WSL_ENABLE_INTEROP}")"
			return 0
		else
			__error "Error configuring WSL interop: $(__error_params "enabled=${WSL_ENABLE_INTEROP}")"
			return 1
		fi
	}

	__set_default_user || return_code=1
	__setup_wsl_gui || return_code=1
	__setup_wsl_interop || return_code=1

	return $return_code
}

# shellcheck disable=SC2120
function action_install_desktop_profile() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		elif [[ -n "$arg" && "$arg" != -* ]]; then
			export GENERAL_DESKTOP_PROFILE="$arg"
		fi
	done

	declare displaymgr
	declare -a pkglist=()
	declare success=false
	declare is_displaymgr_service_enabled=false
	declare proceed=true
	declare -i exit_code=0

	case $GENERAL_DESKTOP_PROFILE in
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

			cp -f "$__ARCHZEN_GNOME_MIMEAPPS_LIST_FILE" "${__USERHOME}/.config/mimeapps.list" &>>"$__LOG_FILE" &&
				__takeown "${__USERHOME}/.config/mimeapps.list"
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

		function __setup_desktop_profile() {
			__setup_hyprland setup
		}
		;;
	*)
		proceed=false
		__error "Invalid DESKTOP_PROFILE value: $(__error_params "$GENERAL_DESKTOP_PROFILE")"
		;;
	esac

	if $proceed; then
		pkglist+=("${__DE_COMMON_PKGLIST[@]}")
		__title "Installing Desktop Profile: $(__title_params "$GENERAL_DESKTOP_PROFILE")"

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

# shellcheck disable=SC2120
function action_setup_dotfiles() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

	__is_installed_archzen || action_install_archzen || return 1

	declare -i installed_count=0
	declare -i total_count=0
	declare -a items=()
	declare -a not_installed_items=()

	{
		if [[ "$GENERAL_DESKTOP_PROFILE" == hyprland ]]; then
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
		declare final_path="${__USERHOME}/${i}"

		cp -f --parents "$i" "$__USERHOME" &>>"$__LOG_FILE" &&
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

	__takeown "$__USERHOME"

	return $exit_code
}

# shellcheck disable=SC2120
function action_setup_vscode() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

	__is_installed_archzen || action_install_archzen || return 1

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
				sudo -EHu "$__USERNAME" code --install-extension "$id" --force &&
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
			if [[ "$GENERAL_DESKTOP_PROFILE" != hyprland ]]; then
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
			declare final_path="${__USERHOME}/.config/${f}"

			__reset_line
			printf "%sApplying settings: %s" "$(__info)" "$settings_result_text"

			cp -f --parents "$f" "${__USERHOME}/.config" &>>"$__LOG_FILE" &&
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
	__apply_template_values __VSCODE_TEMPLATE_VALUES "${__USERHOME}/.config/${code_folder}/User/settings.json"
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

	__takeown "$__USERHOME"

	return $exit_code
}

# shellcheck disable=SC2120
function action_setup_archlinux() {
	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		fi
	done

	if ! __is_installed_initial_os_setup; then
		__setup_sudoers || return $?
		action_setup_zram || return $?
		__setup_pacman || return $?
		__rate_mirrors || return $?
		__setup_locale
		__setup_user_dirs
		touch "$__VAR_INITIAL_OS_SETUP_INSTALLED" || return $?
	fi

	__install_aurbuilder || return $?
	__install_aur_helper || return $?
	__install_base_packages || return $?
	__enable_cachyos_kit || return $?
	__update_system || return $?
	action_setup_bootloader auto true
	action_setup_wsl
	__setup_os
	__install_other_packages
	__install_gpu_drivers
	action_install_desktop_profile
	action_setup_dotfiles
	action_setup_vscode
	__enable_services
	__add_user_groups
}
