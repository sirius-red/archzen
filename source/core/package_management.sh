#!/usr/bin/env bash

function __check_type_alias() {
	declare type value
	declare quiet="$__QUIET"
	declare -A flags=(
		[silent]=false
	)

	while [ $# -gt 0 ]; do
		declare arg="$1"

		if ! __starts_with "$arg" '-'; then
			if [ -z "$type" ]; then
				type="$arg"
			elif [ -z "$value" ]; then
				value="$arg"
			fi

			shift
			continue
		fi

		case "${arg##-}" in
		s) flags[silent]=true ;;
		*) ;;
		esac

		shift
	done

	__QUIET=${flags[silent]}
	if [[ -z "${__TYPE_ALIASES[$type]}" ]]; then
		__error "Invalid $(__error_params \`type\`) value in $(__error_params '`__check_type_alias()`'): $(__error_params "$type")"
	elif [[ ! "${__TYPE_ALIASES[$type]}" =~ $value ]]; then
		__error "Invalid value for variable $(__error_params "\`$type\`"): $(__error_params "$value")"
	else
		true
	fi
	__QUIET=$quiet

	return $?
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
	declare package="$1"

	if pacman -Q "$package" &>>"$__LOG_FILE"; then
		return 0
	fi

	return 1
}

function __detect_pkg_type() {
	declare package="$1"

	if pacman -Si "$package" &>>"$__LOG_FILE"; then
		echo "arch"
	elif git ls-remote "https://aur.archlinux.org/${package}.git" &>>"$__LOG_FILE"; then
		echo "aur"
	else
		echo "none"
	fi
}

function __arch_install() {
	declare -a packages=("$@")

	[ ${#packages[@]} -eq 0 ] && return 0

	pacman -S --noconfirm --needed "${packages[@]}" &>>"$__LOG_FILE"
	return $?
}

function __aur_install() {
	declare -a packages=("$@")
	declare -i exit_code=0

	[ ${#packages[@]} -eq 0 ] && return 0

	if $__AUR_HELPER_IS_INSTALLED; then
		{
			sudo -Hu "$__USERNAME" "$__AUR_HELPER_BIN" -S --noconfirm "${packages[@]}" ||
				exit_code=1
		} &>>"$__LOG_FILE"
	else
		aurbuilder install --noconfirm "${packages[@]}" &>>"$__LOG_FILE" || exit_code=1
	fi

	return $exit_code
}

function __install_package() {
	declare package="$1"
	declare installed=false
	declare proceed=true
	declare pkg_type

	if __is_installed "$package"; then
		__ALREADY_INSTALLED_PKGLIST+=("$package")
		__info "Package is already installed: $(__info_params "$package")"
		return $?
	fi

	__title "installing package $(__title_params "${package}")"

	pkg_type=$(__detect_pkg_type "$package")
	case "$pkg_type" in
	arch)
		__arch_install "$package" && installed=true
		;;
	aur)
		__aur_install "$package" && installed=true
		;;
	none)
		__NOT_EXISTS_PKGLIST+=("$package")
		__warn "Package does not exist: $(__warn_params "$package")"
		proceed=false
		;;
	*)
		__NOT_INSTALLED_PKGLIST+=("$package")
		__error "Unknown error for package: $(__error_params "$package")"
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
	declare -a pkglist=("$@")
	declare -a installed_packages=()
	declare result_text=""
	declare -a arch_pkglist=()
	declare -a aur_pkglist=()
	declare -i total_packages_count=${#pkglist[@]}
	declare -i installed_packages_count=0
	declare -i exit_code=0

	function __update_installed_packages() {
		installed_packages=()

		while IFS='' read -r pkg; do installed_packages+=("$pkg"); done < <(pacman -Qq)
	}

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((installed_packages_count += increment))

		case "$log_type" in
		title) result_text="Installed $(__title_params $installed_packages_count) of $(__title_params $total_packages_count) packages" ;;
		info) result_text="Installed $(__info_params $installed_packages_count) of $(__info_params $total_packages_count) packages" ;;
		success) result_text="Installed $(__success_params $installed_packages_count) of $(__success_params $total_packages_count) packages" ;;
		warn) result_text="Installed $(__warn_params $installed_packages_count) of $(__warn_params $total_packages_count) packages" ;;
		error) result_text="Installed $(__error_params $installed_packages_count) of $(__error_params $total_packages_count) packages" ;;
		*) result_text="Installed $(__bold $installed_packages_count) of $(__bold $total_packages_count) packages" ;;
		esac
	}

	function __init_pkglist_installation() {
		__update_result_text 0 title
		printf '%sStarting installation of %s packages.\t%s' "$(__title)" "$(__title_params "${total_packages_count}")" "$result_text"
		sleep 2
	}

	function __fetch_pkglist_data() {
		__update_installed_packages

		for pkg in "${pkglist[@]}"; do
			declare pkg_type
			declare success=false

			if [[ " ${installed_packages[*]} " == *" $pkg "* ]]; then
				__ALREADY_INSTALLED_PKGLIST+=("$pkg")
				__update_result_text 1 info
				continue
			fi

			pkg_type=$(__detect_pkg_type "$pkg")

			case "$pkg_type" in
			arch)
				arch_pkglist+=("$pkg")
				;;
			aur)
				aur_pkglist+=("$pkg")
				;;
			*)
				__NOT_INSTALLED_PKGLIST+=("$pkg")
				;;
			esac
		done
	}

	function __install_arch_pkglist() {
		__reset_line
		printf '%sInstalling arch packages.\t%s' "$(__info)" "$result_text"

		__arch_install "${arch_pkglist[@]}"
		__update_installed_packages

		for pkg in "${arch_pkglist[@]}"; do
			if [[ " ${installed_packages[*]} " == *" $pkg "* ]]; then
				__update_result_text 1 info
			else
				__NOT_INSTALLED_PKGLIST+=("$pkg")
			fi
		done
	}

	function __install_aur_pkglist() {
		__reset_line
		printf '%sInstalling aur packages.\t%s' "$(__info)" "$result_text"
		__aur_install "${aur_pkglist[@]}"

		__update_installed_packages
		for pkg in "${aur_pkglist[@]}"; do
			if [[ " ${installed_packages[*]} " == *" $pkg "* ]]; then
				__update_result_text 1 info
			else
				__NOT_INSTALLED_PKGLIST+=("$pkg")
			fi
		done
	}

	function __finalize_pkglist_installation() {
		__reset_line
		if [ $installed_packages_count -eq $total_packages_count ]; then
			__update_result_text 0 success
			printf '%s\t%s\n' "$(__success 'Packages installed successfully.')" "$result_text"
		elif [ $installed_packages_count -gt 0 ]; then
			__update_result_text 0 warn
			printf '%s\t%s\n' "$(__warn 'Packages installed with some errors.')" "$result_text"
		else
			__update_result_text 0 error
			printf '%s\t%s\n' "$(__error 'Error installing packages.')" "$result_text"
			exit_code=1
		fi
	}

	__init_pkglist_installation
	__fetch_pkglist_data
	__install_arch_pkglist
	__install_aur_pkglist
	__finalize_pkglist_installation

	return $exit_code
}

# shellcheck disable=SC2120
function __ensure_deps() {
	__is_installed_dependencies && return

	declare quiet=$__QUIET

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-q|--quiet) __QUIET=true ;;
		esac
		shift
	done

	__title "Ensuring dependencies are installed."
	__install_pkglist "${__DEPENDENCIES[@]}" &&
		touch "$__VAR_DEPENDENCIES_INSTALED"

	__QUIET=$quiet
}

function __get_line() {
	declare pattern="$1"
	declare file_path="$2"
	declare result
	declare -i line=0

	result=$(grep -n "$pattern" "$file_path" || printf 'none')

	if [[ "$result" != 'none' ]]; then
		line=$(echo "$result" | head -n 1 | cut -d ':' -f 1 | xargs)
	fi

	printf '%d' $line
}

function __add_lines_to_file() {
	declare file_path="$1"
	declare mode="$2"
	declare add_blank_line=false
	[[ "$3" == "true" ]] && add_blank_line=true
	shift 3
	declare -a lines=("$@")
	declare success=false
	declare action_word

	function __exec() {
		if [[ "$mode" == "w" ]]; then
			declare file_dir
			file_dir=$(dirname "$file_path")

			if [ -f "$file_path" ]; then
				rm -f "$file_path" &>>"$__LOG_FILE"
			elif [ ! -d "$file_dir" ]; then
				mkdir -p "$file_dir" &>>"$__LOG_FILE"
			fi

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

function __apply_template_values() {
	declare template_var="$1"
	declare file_path="$2"
	declare -a not_replaced=()

	function __replace_variables() {
		for k in $(eval 'echo ${!'"$template_var"'[@]}' 2>>"$__LOG_FILE"); do
			declare template_key template_value
			template_key="{{ARCHZEN_${k}}}"
			template_value="$(eval 'echo ${'"$template_var""[$k]}" 2>>"$__LOG_FILE")"

			if ! sed -i "s/${template_key}/${template_value}/g" "$file_path" &>>"$__LOG_FILE"; then
				not_replaced+=("$template_key")
			fi
		done
	}

	__title "Applying template values $(__title_params "$template_var") to $(__title_params "$file_path") file"

	if eval "[ \${#${template_var}[@]} -eq 0 ]"; then
		__error "Template variable $(__error_params "\$$template_var") is not defined"
		return 1
	fi

	if $proceed && ! [ -f "$file_path" ]; then
		__error "File $(__error_params "$file_path") not found"
		return 0
	fi

	if ! __replace_variables; then
		__error "Error replacing template values $(__error_params "\$$template_var") to $(__error_params "$file_path") file"
		return 1
	fi

	if [ "${#not_replaced[@]}" -eq 0 ]; then
		__success "All template values in $(__success_params "\$$template_var") were successfully replaced to the $(__success_params "$file_path") file"
	else
		declare not_replaced_str
		not_replaced_str="$(__join ', ' "${not_replaced[@]}")"

		__warn "Some template values in $(__warn_params "\$$template_var") have not been replaced in the $(__warn_params "\$$template_var") file: ${not_replaced_str}"
	fi

	return $?
}

function __takeown() {
	declare target="$1"
	declare -a args=("${__USERNAME}:${__USERNAME}" "$target")

	[ -d "$target" ] && args=(-R "${args[@]}")

	chown "${args[@]}" &>>"$__LOG_FILE"
}

function __format_script() {
	declare script_path="$1"
	shift
	declare -a options=("$@")
	declare quiet=$__QUIET

	[[ "${options[*]}" =~ --quiet|-q ]] && __QUIET=true

	__title "Formatting file: $(__title_params "$script_path")"

	if shfmt --write --indent 4 --case-indent "$script_path" &>>"$__LOG_FILE"; then
		__success "File formatted successfully: $(__success_params "$script_path")"
	else
		__warn "Error formatting file: $(__warn_params "$script_path")"
	fi

	__QUIET=$quiet

	return 0
}

function __save_script() {
	declare script_name="$1"
	declare create_symlink="$2"
	shift 2
	declare -a script_lines=("$@")
	declare script_path
	script_path="${__ARCHZEN_SCRIPTS_DIR}/${script_name}.sh"

	__add_lines_to_file "$script_path" w false "${script_lines[@]}" &>>"$__LOG_FILE" &&
		__format_script "$script_path" --quiet &&
		chmod +x "$script_path" &>>"$__LOG_FILE" &&
		{
			if [[ "$create_symlink" == true ]]; then
				ln -sf "$script_path" "${__BIN_DIR}/${script_name}" &>>"$__LOG_FILE"
			else
				true
			fi
		} &&
		return 0

	return 1
}

function __gen_bootloader_update_script() {
	declare bootloader="$1"
	[[ "$bootloader" == "auto" ]] && bootloader="$(__detect_bootloader)"

	declare script_name="${bootloader}-update"
	declare -a script_lines=(
		'#!/usr/bin/env bash'
		''
		"# shellcheck source=${__MAIN_SCRIPT_BASE_PATH}"
		"source \"${__MAIN_SCRIPT_BASE_PATH}\""
		''
		"setup_bootloader ${bootloader} false"
	)

	__title "Generating update script for $(__title_params "$bootloader"): $(__title_params "$script_name")"

	if __save_script "$script_name" true "${script_lines[@]}"; then
		__success "Successfully generated update script for $(__success_params "$bootloader"): $(__success_params "$script_name")"
	else
		__error "Error when generating update script for $(__error_params "$bootloader"): $(__error_params "$script_name")"
	fi

	return $?
}

function __setup_sdboot() {
	function __gen_entry() {
		declare entry_dir="${__ESP}/loader/entries"
		declare entry_file="${entry_dir}/${GENERAL_KERNEL}.conf"
		declare -a entry_file_lines=(
			'# Created by: ArchZen'
			"title		Arch Linux (${GENERAL_KERNEL})"
			"linux		/vmlinuz-${GENERAL_KERNEL}"
			"initrd		/${CPU}-ucode.img"
			"initrd		/initramfs-${GENERAL_KERNEL}.img"
			"options	root=PARTUUID=${__ROOT_PARTUUID} ${__KERNEL_PARAMETERS[*]}"
		)
		declare entry_file_fallback="${entry_dir}/${GENERAL_KERNEL}-fallback.conf"
		declare -a entry_file_fallback_lines=(
			'# Created by: ArchZen'
			"title		Arch Linux (${GENERAL_KERNEL}-fallback)"
			"linux		/vmlinuz-${GENERAL_KERNEL}"
			"initrd		/initramfs-${GENERAL_KERNEL}-fallback.img"
			"options	root=PARTUUID=${__ROOT_PARTUUID} ${__KERNEL_FALLBACK_PARAMETERS[*]}"
		)

		if [ ! -d "$entry_dir" ]; then
			mkdir -p "$entry_dir" &>>"$__LOG_FILE"
		fi

		__add_lines_to_file "$entry_file" w false "${entry_file_lines[@]}" &&
			__add_lines_to_file "$entry_file_fallback" w false "${entry_file_fallback_lines[@]}"
	}

	function __edit_loader() {
		declare esp_loader_conf="${__ESP}/loader/loader.conf"
		declare sd_default="$GENERAL_KERNEL"
		declare -i sd_timeout=0
		declare sd_console_mode="max" # auto | max | keep
		declare sd_editor="no"        # yes | no
		declare -a esp_loader_conf_lines=(
			"default       ${sd_default}"
			"timeout       ${sd_timeout}"
			"console-mode  ${sd_console_mode}"
			"editor        ${sd_editor}"
		)

		__add_lines_to_file "$esp_loader_conf" w false "${esp_loader_conf_lines[@]}"
	}

	__gen_entry &>>"$__LOG_FILE" &&
		__edit_loader &>>"$__LOG_FILE" &&
		return 0

	return 1
}

function __variable_file_exists() {
	$__ARCHZEN_FLAG_FORCE && return 1

	declare file="$1"

	[ -f "$file" ]
}

function __is_installed_initial_os_setup() {
	__variable_file_exists "$__VAR_INITIAL_OS_SETUP_INSTALLED"

	return $?
}

function __is_installed_dependencies() {
	__variable_file_exists "$__VAR_DEPENDENCIES_INSTALED"

	return $?
}

function __is_installed_archzen() {
	__variable_file_exists "$__VAR_ARCHZEN_INSTALLED"

	return $?
}

function __is_installed_dotfiles() {
	__variable_file_exists "$__VAR_DOTFILES_INSTALLED"

	return $?
}

function __install_gnome_extensions() {
	if ! __is_installed gnome-extensions-cli; then
		__error "Error installing Gnome extensions. $(__error_params "\`gnome-extensions-cli\`") is not installed."
		return 1
	fi

	declare -i return_code=0
	declare -i already_installed_count=0
	declare -i installed_count=0
	declare -i total_installed_count=0
	declare -i total_count=${#__GNOME_EXTENSIONS[@]}
	declare result_text=""
	declare -a gnome_ext_dirs=(
		"${__ROOT}/usr/share/gnome-shell/extensions"
		"${__USERHOME}/.local/share/gnome-shell/extensions"
	)
	declare force_restart_requirement=false
	declare -a version_fixed_extensions=()
	declare gnome_shell_version
	gnome_shell_version="$(gnome-shell --version | awk -F ' ' '{print $3}' | awk -F '.' '{print $1}')"

	function __update_result_text() {
		declare -i increment=$1
		declare log_type="$2"

		((installed_count += increment))
		((total_installed_count = installed_count + already_installed_count))

		case "$log_type" in
		title) result_text="Installed $(__title_params $total_installed_count) of $(__title_params $total_count) extensions" ;;
		info) result_text="Installed $(__info_params $total_installed_count) of $(__info_params $total_count) extensions" ;;
		success) result_text="Installed $(__success_params $total_installed_count) of $(__success_params $total_count) extensions" ;;
		warn) result_text="Installed $(__warn_params $total_installed_count) of $(__warn_params $total_count) extensions" ;;
		error) result_text="Installed $(__error_params $total_installed_count) of $(__error_params $total_count) extensions" ;;
		*) result_text="Installed $(__bold $total_installed_count) of $(__bold $total_count) extensions" ;;
		esac
	}

	printf '%s' "$(__title "Starting installation of $(__title_params $total_count) $(__bold GNOME) extensions")"
	sleep 2
	__update_result_text 0 info

	for ext in "${__GNOME_EXTENSIONS[@]}"; do
		declare name="${ext%:*}"
		declare uuid="${ext#*:}"
		declare id="${uuid%@*}"

		__reset_line
		printf '%s\t%s' "$(__info "Installing ${name}...")" "$result_text"

		if [[ -f "${gnome_ext_dirs[0]}/extension.js" || -f "${gnome_ext_dirs[1]}/extension.js" ]]; then
			((already_installed_count++))
			__update_result_text 0 info
		elif gnome-extensions-cli update --install --yes "$uuid" &>>"$__LOG_FILE"; then
			__update_result_text 1 info
		else
			__update_result_text 0 warn
			continue
		fi

		for gnome_ext_dir in "${gnome_ext_dirs[@]}"; do
			declare ext_dir="${gnome_ext_dir}/${uuid}"
			declare ext_schemas_dir="$ext_dir/schemas"
			declare ext_schema_xml="$ext_schemas_dir/org.gnome.shell.extensions.${id}.gschema.xml"
			declare ext_schema_compiled="$ext_schemas_dir/gschemas.compiled"
			declare metadata="${ext_dir}/metadata.json"
			declare metadata_tmp="${__ROOT}/tmp/${uuid}.metadata.$$.json"

			if [[ "$__VALID_CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML_INDEXES" =~ $id ]]; then
				ext_schema_xml="$ext_schemas_dir/${__CUSTOM_GNOME_EXTENSIONS_SCHEMA_XML[$id]}"
			fi

			if [[ -f "$ext_schema_xml" && ! -f "$ext_schema_compiled" ]]; then
				glib-compile-schemas "$ext_schemas_dir" &>>"$__LOG_FILE" &&
					force_restart_requirement=true
			fi

			declare jq_result
			jq_result="$(jq ".[\"shell-version\"] | index(\"${gnome_shell_version}\")" "$metadata" 2>>"$__LOG_FILE")"

			if [[ "$jq_result" == null ]]; then
				{
					jq ".[\"shell-version\"] += [\"${gnome_shell_version}\"]" "$metadata" >"$metadata_tmp" &&
						mv -f "$metadata_tmp" "$metadata" &&
						version_fixed_extensions+=("$name")
					force_restart_requirement=true
				} &>>"$__LOG_FILE"
			fi
		done

	done

	if [ -d "${gnome_ext_dirs[1]}" ]; then
		__takeown "${gnome_ext_dirs[1]}"
	fi

	__reset_line
	if [ $total_installed_count -eq $total_count ]; then
		__update_result_text 0 success
		printf '%s\t%s\n' "$(__success 'Extensions installed successfully.')" "$result_text"
	elif [ $total_installed_count -gt 0 ]; then
		__update_result_text 0 warn
		printf '%s\t%s\n' "$(__warn 'Extensions installed with some errors.')" "$result_text"
	else
		__update_result_text 0 error
		printf '%s\t%s\n' "$(__error 'Error installing extensions.')" "$result_text"
		return_code=1
	fi

	if [ ${#version_fixed_extensions[@]} -gt 0 ]; then
		__warn "The extensions below have been manually fixed for Gnome Shell version 48. Disable them if you experience any issues:"

		for ext in "${version_fixed_extensions[@]}"; do
			printf '        - %s\n' "$(__warn_params "$ext")"
		done
	fi

	if [[ "$__COMMAND_ARG" =~ desktop-profile|dp ]] &&
		{ [[ "$force_restart_requirement" == true ]] || [ $installed_count -gt 0 ]; } &&
		pgrep -x "gnome-shell" &>>"$__LOG_FILE"; then
		finish
		__warn "Gnome Shell needs to be restarted so that extensions are applied"

		if __confirm "Logout now?"; then
			for ((i = 3; i > 0; i--)); do
				__reset_line
				printf '%sLogging out in %s seconds' "$(__info)" "$i"
				sleep 1
			done

			__log ''

			{ sudo -Eu "$__USERNAME" gnome-session-quit --logout --no-prompt; } &>>"$__LOG_FILE"

			__warn "Could not restart Gnome Shell, you have to restart it manually"
			__log ''
		else
			__warn "Restart the Gnome Shell manually"
			__log ''
		fi

		exit $return_code
	fi

	return $return_code
}

function __set_sddm_settings() {
	__add_lines_to_file "${__ROOT}/usr/lib/sddm/sddm.conf.d/general.conf" "w" false \
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

	__add_lines_to_file "${__ROOT}/etc/sddm.conf.d/01-wayland.conf" "w" false \
		'[General]' \
		'DisplayServer=wayland' \
		'GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell' \
		'' \
		'[Wayland]' \
		'CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1'
}

function __enable_kernel_modules() {
	[ "${#__KERNEL_MODULES[@]}" -gt 0 ] || return

	declare mkinitcpio_conf="${__ROOT}/etc/mkinitcpio.conf"
	declare success=false

	function __exec() {
		declare current_modules updated_modules
		current_modules="$(grep "^MODULES=" "$mkinitcpio_conf" | sed 's/MODULES=(\(.*\))/\1/')"

		for mod in "${__KERNEL_MODULES[@]}"; do
			if [[ "$current_modules" =~ $mod ]]; then
				continue
			fi

			current_modules+=" $mod"
		done

		updated_modules="$(echo "$current_modules" | xargs)"

		sed -i "s/^MODULES=.*/MODULES=(${updated_modules})/" "$mkinitcpio_conf" &&
			mkinitcpio -P
	}

	declare ifs="$IFS"
	export IFS=","
	__title "Enabling kernel modules in $(__bold "$mkinitcpio_conf"): $(__title_params "${__KERNEL_MODULES[*]}")"
	export IFS="$ifs"
	__exec &>>"$__LOG_FILE" && success=true

	if $success; then
		__success "Kernel modules enabled successfully"
	else
		__error "Error enabling kernel modules"
	fi

	return $?
}

function __install_cachyos_repo() {
	declare workdir="${__ROOT}/tmp/cachyos-repo"
	declare proceed=true
	declare success=false

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

function __rate_cachyos_mirrors() {
	__title "Rating CachyOS mirrors"

	if cachyos-rate-mirrors &>>"$__LOG_FILE"; then
		__success "CachyOS mirrors were successfully rated"
	else
		__error "Error rating CachyOS mirrors"
	fi

	return $?
}

function __install_cachyos_packages() {
	__title "Installing CachyOS tools"
	__install_pkglist "${__CACHYOS_PKGLIST[@]}"
	return $?
}

function __update_system() {
	declare pkgmgr="pacman"
	$__AUR_HELPER_IS_INSTALLED && pkgmgr=$__AUR_HELPER_BIN

	__title "Updating system"

	if $pkgmgr -Syu --noconfirm &>>"$__LOG_FILE"; then
		__SYSTEM_ALREADY_UPDATED=true
		__success "System updated successfully with: $(__success_params "$pkgmgr")"
	else
		__error "Error updating system with: $(__error_params "$pkgmgr")"
	fi

	return $?
}
