#!/usr/bin/env bash

# >>>>>>>>>>>>>>>>>>>>>>>> Default Settings >>>>>>>>>>>>>>>>>>>>>>>>
LOCALE="en_US.UTF-8"
KB_LAYOUT="us"
KB_VARIANT="intl,altgr-intl"
TIMESTAMP_TIMEOUT=-1
REFLECTOR_MIRROR_COUNTRIES="US"
REFLECTOR_MIRROR_LIMIT=10
PACMAN_PARALLEL_DOWNLOADS=10
PACMAN_ENABLE_MULTILIB=true
SETUP_ZRAM=true
USE_SWAPFILE=true
USE_NVIDIA_OSS_DRIVERS=false
ENABLE_CACHYOS_KIT=false
WSL_ENABLE_GUI=true
WSL_ENABLE_INTEROP=true
# <<<<<<<<<<<<<<<<<<<<<<<< Default Settings <<<<<<<<<<<<<<<<<<<<<<<<


# >>>>>>>>>>>>>>>>>>>>>>>> Load Source Files >>>>>>>>>>>>>>>>>>>>>>>>
declare __source_dir=""
__source_dir="$(dirname "${BASH_SOURCE[0]}")/source"

# shellcheck source=source/lib/confedit.sh
source "${__source_dir}/lib/confedit.sh"

# >>>>>>>>>>>>>>>>>>>>>>>> Load Configuration >>>>>>>>>>>>>>>>>>>>>>>>
declare __config_file=""
if [[ "$ARCHZEN_IS_RUNNING_FROM_BINARY" == true ]]; then
	__config_file="/etc/archzen.conf"
else
	__config_file="${PWD}/archzen.conf"
fi

if [[ ! -f "$__config_file" ]]; then
	declare __template_config
	__template_config="$(dirname "${BASH_SOURCE[0]}")/archzen.conf"
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
	declare key="$1"
	declare section="$2"
	declare target_var="${3:-$key}"
	declare val

	if val="$(__confedit get "$__config_file" "$key" "$section" 2>/dev/null)"; then
		val="${val%\"}"
		val="${val#\"}"
		val="${val%\'}"
		val="${val#\'}"
		eval "$target_var=\"\$val\""
	fi
}

if [[ -f "$__config_file" ]]; then
	__load_config_val "LOCALE" "General"
	__load_config_val "KB_LAYOUT" "General"
	__load_config_val "KB_VARIANT" "General"
	__load_config_val "TIMESTAMP_TIMEOUT" "General"
	__load_config_val "REFLECTOR_MIRROR_COUNTRIES" "General"
	__load_config_val "REFLECTOR_MIRROR_LIMIT" "General"
	__load_config_val "PACMAN_PARALLEL_DOWNLOADS" "General"
	__load_config_val "PACMAN_ENABLE_MULTILIB" "General"
	__load_config_val "SETUP_ZRAM" "General"
	__load_config_val "USE_SWAPFILE" "General"
	__load_config_val "USE_NVIDIA_OSS_DRIVERS" "General"
	__load_config_val "ENABLE_CACHYOS_KIT" "General"
	__load_config_val "KERNEL" "General"
	__load_config_val "USER_SHELL" "General"
	__load_config_val "AUR_HELPER" "General"
	__load_config_val "EDITOR" "General"
	__load_config_val "DESKTOP_PROFILE" "General"
	__load_config_val "TERMINAL" "General"
	__load_config_val "EXPLORER" "General"
	__load_config_val "BROWSER" "General"

	__load_config_val "ENABLE_GUI" "WSL" "WSL_ENABLE_GUI"
	__load_config_val "ENABLE_INTEROP" "WSL" "WSL_ENABLE_INTEROP"
fi
# <<<<<<<<<<<<<<<<<<<<<<<< Load Configuration <<<<<<<<<<<<<<<<<<<<<<<<

# shellcheck source=source/global_declarations.sh
source "${__source_dir}/global_declarations.sh"

# shellcheck source=source/lib/cli_parser.sh
source "${__source_dir}/lib/cli_parser.sh"

# shellcheck source=source/utils/string.sh
source "${__source_dir}/utils/string.sh"
# shellcheck source=source/utils/array.sh
source "${__source_dir}/utils/array.sh"

# shellcheck source=source/core/validations.sh
source "${__source_dir}/core/validations.sh"
# shellcheck source=source/core/ui_components.sh
source "${__source_dir}/core/ui_components.sh"
# shellcheck source=source/core/package_management.sh
source "${__source_dir}/core/package_management.sh"
# shellcheck source=source/core/internal_setup_steps.sh
source "${__source_dir}/core/internal_setup_steps.sh"

# shellcheck source=source/cli/actions.sh
source "${__source_dir}/cli/actions.sh"
# shellcheck source=source/cli/lifecycle_functions.sh
source "${__source_dir}/cli/lifecycle_functions.sh"

unset __source_dir
# <<<<<<<<<<<<<<<<<<<<<<<< Load Source Files <<<<<<<<<<<<<<<<<<<<<<<<


__set_global_variables "${CHDIR:-/}" "${FORCE:-false}" "${ARCHZEN_IS_RUNNING_FROM_BINARY:-false}"

if ! __is_valid_semver "$__VERSION"; then
	__error "Invalid semanthic version: $(__error_params "$__VERSION")"
	exit 1
fi

declare __script_dir, __cli_config_file
__script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
__cli_config_file="${__script_dir}/source/cli/config.yml"

if [[ "$ARCHZEN_PROCESS_ENV" == development ]]; then
	__cli_parser "$__cli_config_file" "$@"
	exit $?
fi

if __is_main_module; then
	__ensure_deps --quiet

	# Installed check (for commands other than install or help/version)
	if [[ ! "$1" =~ ^install$|^i$|^help$|^h$|^--help$|^-h$|^version$|^v$|^--version$|^-v$ || -z "$1" ]]; then
		if ! command -v archzen &>>"$__LOG_FILE"; then
			echo
			__error "The \`$(__error_params "$1")\` command is only available after the installation of ArchZen"
			__info "Runs \`$(__info_params "sudo ${__THIS_SCRIPT} install self")\` first"
			echo
			exit 1
		fi

		if ! $__ARCHZEN_IS_RUNNING_FROM_BINARY; then
			echo
			__error "Do not run the command \`$(__error_params "$1")\` through this script"
			__info "Runs \`$(__info_params "archzen $*")\`"
			echo
			exit 1
		fi
	fi

	__cli_parser "$__cli_config_file" "$@" || __EXIT_CODE=$?
	exit $__EXIT_CODE
fi
