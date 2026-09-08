#!/usr/bin/env bash

function __setup_sudoers() {
	function __apply_options() {
		declare sudoers="${__ROOT}/etc/sudoers"
		declare -a sudoers_options=(
			"Defaults	insults"
			"Defaults	pwfeedback"
			"Defaults	timestamp_timeout=${GENERAL_TIMESTAMP_TIMEOUT}"
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
		declare sudoers_user="${__ROOT}/etc/sudoers.d/00_${__USERNAME}"
		declare -a sudoers_user_options=(
			"${__USERNAME}	ALL=(ALL:ALL)	ALL"
			"%${__USERNAME}	ALL=(ALL:ALL)	ALL"
		)

		if [ ! -f "$sudoers_user" ]; then
			__add_lines_to_file "${sudoers_user}" "w" false "${sudoers_user_options[@]}"
		else
			declare -i line_n
			line_n=$(__get_line "^${__USERNAME} ALL=(ALL) ALL")

			if [ $line_n -gt 0 ]; then
				sed -i "${line_n}d" &>>"$__LOG_FILE"
			fi

			for option in "${sudoers_user_options[@]}"; do
				if grep -qe "$option" "$sudoers_user" &>>"$__LOG_FILE"; then
					__info "Config already defined for user ${__USERNAME}: $(__info_params "$option")"
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

	__title "Configuring sudoers for user: $(__title_params "$__USERNAME")"

	__apply_options
	__apply_user_options

	return $?
}

function __setup_pacman() {
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
			__error "$(__error_params "__setup_pacman()"): Unknown log status: $(__error_params "$status")"
			;;
		esac

		return $?
	}

	function __enable_colors() {
		declare status

		__show_title "Enable colors"

		if __confedit exists "$pacman_conf" "Color" "options" --separator "" &>>"$__LOG_FILE"; then
			status="keep"
		elif __confedit uncomment "$pacman_conf" "Color" "options" --separator "" &>>"$__LOG_FILE" ||
			__confedit set "$pacman_conf" "Color" "" "options" --separator "" &>>"$__LOG_FILE"; then
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

		if __confedit exists "$pacman_conf" "ILoveCandy" "options" --separator "" &>>"$__LOG_FILE"; then
			status="keep"
		elif __confedit uncomment "$pacman_conf" "ILoveCandy" "options" --separator "" &>>"$__LOG_FILE" ||
			__confedit set "$pacman_conf" "ILoveCandy" "" "options" --separator "" &>>"$__LOG_FILE"; then
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

		if [[ "$(__confedit get "$pacman_conf" "ParallelDownloads" "options" 2>>"$__LOG_FILE")" == "$value" ]]; then
			status="keep"
		elif __confedit set "$pacman_conf" "ParallelDownloads" "$value" "options" &>>"$__LOG_FILE"; then
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

		if __confedit exists "$pacman_conf" "Include" "multilib" &>>"$__LOG_FILE"; then
			status="keep"
		elif __confedit set "$pacman_conf" "Include" "/etc/pacman.d/mirrorlist" "multilib" &>>"$__LOG_FILE"; then
			status="changed"
		else
			status="unchanged"
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
	__set_parallel_downloads "$GENERAL_PACMAN_PARALLEL_DOWNLOADS" || return_code=1
	$GENERAL_PACMAN_ENABLE_MULTILIB && { __enable_multilib_repo || return_code=1; }
	__fix_file_permissions || return_code=1
	__update_repo_database || return_code=1

	return $return_code
}

function __rate_mirrors() {
	if ! __is_installed reflector; then
		__error "Executable not found in PATH: $(__error_params "reflector")"
		return $?
	fi

	declare reflector_conf="${__ROOT}/etc/xdg/reflector/reflector.conf"
	declare -a lines=(
		"--save /etc/pacman.d/mirrorlist"
		"--ipv4"
		"--ipv6"
		"--protocol https"
		"--country ${GENERAL_REFLECTOR_MIRROR_COUNTRIES}"
		"--latest ${GENERAL_REFLECTOR_MIRROR_LIMIT}"
		"--sort rate"
	)
	declare log_data="${GENERAL_REFLECTOR_MIRROR_LIMIT} mirros from ${GENERAL_REFLECTOR_MIRROR_COUNTRIES}"

	__title "Rating mirros: $(__title_params "$log_data")"

	if __add_lines_to_file "$reflector_conf" "w" false "${lines[@]}" &&
		systemctl start reflector.service &>>"$__LOG_FILE"; then
		__success "Mirrors were successfully rated: $(__success_params "$log_data")"
	else
		__error "Error rating mirrors: $(__error_params "$log_data")"
	fi

	return $?
}

function __setup_locale() {
	declare curr_locale
	declare locale_gen="${__ROOT}/etc/locale.gen"
	declare success=false

	curr_locale="$(localectl status 2>>"$__LOG_FILE" | grep -e 'LANG=' | cut -d'=' -f2)"

	__title "Configuring locale: $(__title_params "$GENERAL_LOCALE")"

	if [[ "$GENERAL_LOCALE" == "$curr_locale" ]]; then
		__info "Locale is already configured: $(__info_params "$GENERAL_LOCALE")"
		return 0
	fi

	__confedit uncomment "$locale_gen" "$GENERAL_LOCALE" --format conf --separator ' ' &>>"$__LOG_FILE"

	if locale-gen &>>"$__LOG_FILE" &&
		localectl set-locale LANG="$GENERAL_LOCALE" &>>"$__LOG_FILE"; then
		success=true
	fi

	if $success; then
		__success "Locale configured successfully: $(__success_params "$GENERAL_LOCALE")"
		return 0
	else
		__error "Error configuring locale: $(__error_params "$GENERAL_LOCALE")"
		return 1
	fi
}

function __setup_user_dirs() {
	if ! __is_installed xdg-user-dirs; then
		__warn "The package \"xdg-user-dirs\" is not installed\n    Installs  with \`pacman -S xdg-user-dirs\`"
		return 0
	fi

	declare -a pairs=(
		"DESKTOP=desktop"
		"DOCUMENTS=documents"
		"DOWNLOAD=downloads"
		"MUSIC=music"
		"PICTURES=pictures"
		"PROJECTS=projects"
		"PUBLICSHARE=public"
		"TEMPLATES=templates"
		"VIDEOS=videos"
	)
	declare -i updated_count=0
	declare -i total_count=${#pairs[@]}
	declare -i exit_code=0
	declare result_text=""
	declare -a not_updated_dirs=()

	__title "Setting up user directories"

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((updated_count += increment))
		result_text="(${updated_count}/${total_count}) directories"

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

	for pair in "${pairs[@]}"; do
		declare dir="${pair%=*}"
		declare path="${__USERHOME}/${pair#*=}"

		__reset_line
		printf '%sSetting user directory %s... %s' "$(__info)" "$dir" "$result_text"

		if mkdir -p "$path" &>>"$__LOG_FILE" &&
			sudo -EHu "$__USERNAME" xdg-user-dirs-update --force --set "$dir" "$path" | tee -a "$__LOG_FILE" &&
			__takeown "$path"; then
			__update_result_text 1 info
		else
			not_updated_dirs+=("$dir")
			__update_result_text 0 warn
		fi
	done

	sudo -EHu "$__USERNAME" xdg-user-dirs-update | tee -a "$__LOG_FILE"

	__reset_line
	if [ $updated_count -eq $total_count ]; then
		__update_result_text 0 success
		printf '%s\t%s\n' "$(__success 'User directories configured successfully.')" "$result_text"
		exit_code=0
	elif [ $updated_count -gt 0 ]; then
		__update_result_text 0 warn
		printf '%s\t%s\n' "$(__warn 'User directories configured with some errors.')" "$result_text"
		exit_code=0
	else
		__update_result_text 0 error
		printf '%s\t%s\n' "$(__error 'Error configuring user directories.')" "$result_text"
		exit_code=1
	fi

	if [ $updated_count -ne $total_count ]; then
		printf 'Directories not configured:\n%s%s' '  - ' "${not_updated_dirs[@]}"
	fi

	[ -f "${__USERHOME}/.config/user-dirs.dirs" ] && __takeown "${__USERHOME}/.config/user-dirs.dirs"

	return $exit_code
}

function __install_aurbuilder() {
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

function __install_aur_helper() {
	[ -n "$GENERAL_AUR_HELPER" ] || return 0

	__title "Installing AUR helper: $(__title_params "$GENERAL_AUR_HELPER")"

	if command -v "${GENERAL_AUR_HELPER/-bin/}" &>>"$__LOG_FILE"; then
		__AUR_HELPER_IS_INSTALLED=true
		__info "AUR helper already installed: $(__info_params "$GENERAL_AUR_HELPER")"
	elif __install_package "$GENERAL_AUR_HELPER"; then
		__AUR_HELPER_IS_INSTALLED=true
		__success "AUR helper installed successfully: $(__success_params "$GENERAL_AUR_HELPER")"
	else
		__error "Error installing AUR helper: $(__error_params "$GENERAL_AUR_HELPER")"
	fi

	return $?
}

function __install_base_packages() {
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
			[[ "$k" == "$GENERAL_KERNEL" ]] && continue

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

	if [[ -n "$GENERAL_KERNEL" && "$__IS_WSL" == false ]]; then
		__title "Removing default kernels"
		__remove_default_kernels
	fi

	__title "Installing base packages"
	__install_pkglist "${base_pkglist[@]}"

	return $?
}

function __enable_cachyos_kit() {
	[[ "$GENERAL_ENABLE_CACHYOS_KIT" == true ]] || return 0

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

function __setup_os() {
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

		__title "Changing the shell to: $(__title_params "$GENERAL_USER_SHELL")"

		if ! __is_installed "$GENERAL_USER_SHELL"; then
			proceed=false

			__warn "The user-defined shell was not installed. Trying to install: $(__warn_params "$GENERAL_USER_SHELL")"

			if __install_package "$GENERAL_USER_SHELL"; then
				proceed=true

				__success "User-defined shell installed successfully: $(__success_params "$GENERAL_USER_SHELL")"
			else
				__error "Error installing user-defined shell: $(__error_params "$GENERAL_USER_SHELL")"
			fi
		fi

		$proceed || return 1

		declare shell_path
		shell_path=$(which "$GENERAL_USER_SHELL")

		if ! grep -qe "^${shell_path}$" "${__ROOT}/etc/shells" &>>"$__LOG_FILE"; then
			proceed=false

			__title "Adding the ${GENERAL_USER_SHELL} path to ${__ROOT}/etc/shells: $(__title_params "$shell_path")"

			if __add_lines_to_file "${__ROOT}/etc/shells" a false "$shell_path"; then
				proceed=true

				__success "${GENERAL_USER_SHELL} path added to ${__ROOT}/etc/shells: $(__success_params "$shell_path")"
			else
				__error "Error adding the ${GENERAL_USER_SHELL} path to ${__ROOT}/etc/shells: $(__error_params "$shell_path")"
			fi
		fi

		if $proceed && chsh -s "$(which "$GENERAL_USER_SHELL")" "$__USERNAME"; then
			__success "Shell changed successfully to: $(__success_params "$GENERAL_USER_SHELL")"
		else
			__error "Error changing shell to: $(__error_params "$GENERAL_USER_SHELL")"
		fi

		return $?

	}

	__set_os_specifications || return_code=1
	[ -n "$GENERAL_USER_SHELL" ] && { __set_default_shell || return_code=1; }

	return $return_code
}

function __install_other_packages() {
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

function __install_gpu_drivers() {
	$__IS_WSL && return 0
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

# shellcheck disable=SC2120
function __setup_hyprland() {
	declare action="${1:-setup}"

	for arg in "$@"; do
		if [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
			export FORCE=true
			declare -gx __FORCE=true
		elif [[ -n "$arg" && "$arg" != -* ]]; then
			action="$arg"
		fi
	done

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
		declare file file_name

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

		file_name="$(basename "$file")"

		for item in "${blacklist[@]}"; do
			declare -i line=0
			[ -f "$file" ] && line=$(__get_line "^${item}$" "$file")
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
			sudo -EHu "$__USERNAME" ./install.sh "$hyde_args" &&
			return 0

		return 1
	}

	function __install_hyde() {
		__hyde_installer drsn && return 0

		__error "Error installing $(__error_params 'HyDE Project')"
		return 1
	}

	function __apply_hyprland_settings() {
		declare target_config_dir="${__USERHOME}/.config"
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

		$success && __takeown "$__USERHOME" && return 0

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

		if __check_type_alias -s SHELL_PROFILES "$GENERAL_USER_SHELL"; then
			shell_profile="${__SHELL_PROFILES[$GENERAL_USER_SHELL]}"
		fi

		__print "$(__title "Adding $(__title_params hyprinit) to $(__title_params "$GENERAL_USER_SHELL") profile...")"

		if grep -qe 'hyprinit' "$shell_profile" &>>"$__LOG_FILE"; then
			__print -rn "$(__info "Adding $(__info_params hyprinit) to $(__info_params "$GENERAL_USER_SHELL") profile... $(__info_params 'Skipped!')")"
		elif ! command -v hyprinit &>>"$__LOG_FILE"; then
			__print -rn "$(__error "$(__error_params hyprinit) helper not found in $(__error_params "$__BIN_DIR")!")"
		elif __add_lines_to_file "$shell_profile" a true "${script_lines[@]}" &>>"$__LOG_FILE" && __takeown "$shell_profile"; then
			success=true
			__print -rn "$(__success "Adding $(__success_params hyprinit) to $(__success_params "$GENERAL_USER_SHELL") profile... $(__success_params 'Success!')")"
		else
			__print -rn "$(__error "Adding $(__error_params hyprinit) to $(__error_params "$GENERAL_USER_SHELL") profile... $(__error_params 'Error!')")"
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
				[[ "$__IS_WSL" == false ]] && __create_hyprinit && __add_hyprinit_to_shell_profile
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
		__error "$(__error_params '__setup_hyprland()'): Invalid action: $(__error_params "$action")"
		;;
	esac

	return $return_code
}

function __enable_services() {
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

		if systemctl enable "${service}.service" &>>"$__LOG_FILE"; then
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
		printf 'Services not enabled:\n'
		for srv in "${not_enabled_services[@]}"; do
			printf '  - %s\n' "$srv"
		done
		return 1
	fi

	return 0
}

function __add_user_groups() {
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

		if usermod -aG "$group" "$__USERNAME" &>>"$__LOG_FILE"; then
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
		printf 'Groups not added:\n'
		for grp in "${not_added_groups[@]}"; do
			printf '  - %s\n' "$grp"
		done
		return 1
	fi

	return 0
}
