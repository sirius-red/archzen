#!/usr/bin/env bash

# >>>>>>>>>>>>>>>>>>>>>>>> Main Settings >>>>>>>>>>>>>>>>>>>>>>>>
LOCALE="en_US.UTF-8"               # Use `cat /usr/share/i18n/SUPPORTED | cut -d' ' -f1` to list possible values
KB_LAYOUT="us"                     # Use `grep -i 'English' /usr/share/X11/xkb/rules/base.lst` to list possible values
KB_VARIANT="intl,altgr-intl"       # Use `grep -i 'English' /usr/share/X11/xkb/rules/base.lst` to list possible values
TIMESTAMP_TIMEOUT=-1               # number of minutes before the sudo password prompt times out, or -1 for no timeout
REFLECTOR_MIRROR_COUNTRIES="BR,US" # Use `reflector --list-countries` to list available countries
REFLECTOR_MIRROR_LIMIT=10          # The higher the value, the longer the reflector will take to complete its run
PACMAN_PARALLEL_DOWNLOADS=10       # Value for Pacman's "ParallelDownloads" config option
PACMAN_ENABLE_MULTILIB=true        # Enable (or not) the multilib repository
AUR_HELPER="yay-bin"               # paru[-[bin|git]] | yay[-[bin|git]]; "aurbuilder" will use this behind the scenes for some tasks. Comment this line to use "makepkg"
SETUP_ZRAM=true                    # true | false; Improve zram settings if you enabled it in Arch installation
USE_SWAPFILE=true                  # true | false; Enables a swapfile fallback, used only if zram is unavailable or insufficient and filesystem is not btrfs
KERNEL="linux-zen"                 # Any available in the official repository or AUR; Comment this line to not install
USER_SHELL="fish"                  # Any available in the official repository or AUR; Comment this line to not change the shell; Only “fish” has customizations
USE_NVIDIA_OSS_DRIVERS=false       # true | false; Se verdadeiro, instalará os drivers open source da nvidia (`nvidia-open`) ao invés do padrão (`nvidia`)
ENABLE_CACHYOS_KIT=false           # true | false; Installs the CachyOS repository and some CachyOS tools
# DESKTOP_PROFILE="hyprland"       # xorg | xorg-minimal | gnome | plasma | hyprland; Comment this line to not install
# TERMINAL="kitty"                 # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# EDITOR="vim"                     # Any terminal editor available in the official repository or AUR; Comment this line to not install
# EXPLORER="dolphin"               # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# BROWSER="firefox"                # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# NOTE="obsidian"                  # Any available in the official repository or AUR; Comment this line to use the DESKTOP_PROFILE default
# <<<<<<<<<<<<<<<<<<<<<<<< Main Settings <<<<<<<<<<<<<<<<<<<<<<<<

# >>>>>>>>>>>>>>>>>>>>>>>> WSL Settings >>>>>>>>>>>>>>>>>>>>>>>>
# These variables will be ignored if archzen is not running on a
# WSL installation.
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
WSL_ENABLE_GUI=true     # Enables GUI in WSL
WSL_ENABLE_INTEROP=true # Enables interoperability between WSL and Windows, and GUI support in WSL
# <<<<<<<<<<<<<<<<<<<<<<<< WSL Settings <<<<<<<<<<<<<<<<<<<<<<<<


# >>>>>>>>>>>>>>>>>>>>>>>> Load Source Files >>>>>>>>>>>>>>>>>>>>>>>>
declare __source_dir=""
__source_dir="$(dirname "${BASH_SOURCE[0]}")/source"

# shellcheck source=source/global_declarations.sh
source "${__source_dir}/global_declarations.sh"

# shellcheck source=source/lib/confedit.sh
source "${__source_dir}/lib/confedit.sh"
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
