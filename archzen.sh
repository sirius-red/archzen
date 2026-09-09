#!/usr/bin/env bash


# >>>>>>>>>>>>>>>>>>>>>>>> Load Source Files >>>>>>>>>>>>>>>>>>>>>>>>
declare __source_dir=""
__source_dir="$(dirname "${BASH_SOURCE[0]}")/source"

# shellcheck source=source/lib/confmgr.sh
source "${__source_dir}/lib/confmgr.sh"

# shellcheck source=source/core/settings.sh
source "${__source_dir}/configuration.sh"

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

declare __script_dir __cli_config_file
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
