#!/usr/bin/env bash

# shellcheck disable=SC2039

if [ -z "${_SHMATE_INCLUDE_LIB_WORKDIR}" ]; then
    readonly _SHMATE_INCLUDE_LIB_WORKDIR='included'

#> >>> workdir.sh
#>
#> Library adding temporary working directory.
#>
#> >>>> Dependencies
#> * <<lib_shmate_assert>>
#>

# shellcheck source=src/lib/shmate/assert.sh
. "${SHMATE_LIB_DIR}/assert.sh"

shmate_assert_tools mktemp mkfifo || shmate_fail $?

if ${shmate_os_windows}; then
    shmate_assert_tools cygpath || shmate_fail $?
fi

#> >>>> Environment
#>
#> >>>>> SHMATE_WORK_DIR_KEEP
#>
#> Setting this to positive integer preserves temporary working directory. Useful for debugging.
#>
SHMATE_WORK_DIR_KEEP=${SHMATE_WORK_DIR_KEEP:-0}

#> >>>> Internal symbols
#>
#> .Functions
#> [%collapsible]
#> ====
#> * _shmate_lib_workdir_cleanup
_shmate_lib_workdir_cleanup() {
    if [ ${SHMATE_WORK_DIR_KEEP} -le 0 ]; then
        if [ -n "${shmate_work_dir}" ]; then
            shmate_audit rm -rf "${shmate_work_dir}"
            shmate_assert "Deleting temporary working directory \"${shmate_work_dir}\"" # Proceed anyway
        fi
    fi

    _shmate_lib_assert_cleanup "$@"
}

#> * _shmate_lib_workdir_on_exit
_shmate_lib_workdir_on_exit() {
    _shmate_lib_assert_on_exit "$@"
}

#> * _shmate_lib_workdir_on_terminate
_shmate_lib_workdir_on_terminate() {
    _shmate_lib_assert_on_terminate "$@"
}

#> ====
#>

_shmate_cleanup() {
    _shmate_lib_workdir_cleanup "$@"
}

_shmate_on_exit() {
    _shmate_lib_workdir_on_exit "$@"
}

_shmate_on_terminate() {
    _shmate_lib_workdir_on_terminate "$@"
}

#> >>>> Variables
#>
#> >>>>> shmate_work_dir
#>
#> Path to temporary working directory.
#>
shmate_work_dir=$(realpath "${TMPDIR:-/tmp}")
shmate_fail_assert "Resolving temporary directory \"${TMPDIR:-/tmp}\""

export TMPDIR="${shmate_work_dir}"

shmate_work_dir=$(mktemp -p "${TMPDIR}" -d "${0##*/}.XXXXXX")
shmate_fail_assert "Creating temporary working directory in \"${TMPDIR}\""

shmate_log_audit mkdir -p -m 0700 "${shmate_work_dir}"

chmod 0700 "${shmate_work_dir}"
shmate_fail_assert "Modding temporary working directory \"${shmate_work_dir}\""

readonly shmate_work_dir

shmate_log_debug "Using temporary working directory \"${shmate_work_dir}\""

#> >>>> Functions
#>
#> >>>>> shmate_create_tmp_dir [<dir_name>]
#>
shmate_create_tmp_dir() {
    local name="$1" # Optional

    local tmp_file=
    tmp_file=$(mktemp -p "${shmate_work_dir}" -d "${name}.XXXXXX")
    shmate_assert "Creating temporary directory \"${name}\"" || return $?

    shmate_log_audit mkdir "${tmp_file}"
    shmate_log_debug "Created temporary directory \"${tmp_file}\""

    echo "${tmp_file}"
    return 0
}

#> >>>>> shmate_create_tmp_file [<file_name>]
#>
shmate_create_tmp_file() {
    local name="$1" # Optional

    local tmp_file=
    tmp_file=$(mktemp -p "${shmate_work_dir}" "${name}.XXXXXX")
    shmate_assert "Creating temporary file \"${name}\"" || return $?

    shmate_log_audit touch "${tmp_file}"
    shmate_log_debug "Created temporary file \"${tmp_file}\""

    echo "${tmp_file}"
    return 0
}

#> >>>>> shmate_create_tmp_fifo [<fifo_name>]
#>
shmate_create_tmp_fifo() {
    local name="$1" # Optional

    local tmp_file=
    tmp_file=$(mktemp -p "${shmate_work_dir}" "${name}.XXXXXX")
    shmate_assert "Creating temporary file \"${name}\"" || return $?

    shmate_audit rm -f "${tmp_file}" && shmate_audit mkfifo "${tmp_file}"
    shmate_assert "Replacing temporary file \"${tmp_file}\" with fifo" || return $?

    shmate_log_debug "Created temporary fifo \"${tmp_file}\""

    echo "${tmp_file}"
    return 0
}

#> >>>>> shmate_platform_path <path>
#>
shmate_platform_path() {
    if ${shmate_os_windows}; then
        cygpath --windows "$1"
    else
        echo "$1"
    fi
}

#> >>>>> shmate_posix_path <path>
#>
shmate_posix_path() {
    if ${shmate_os_windows}; then
        cygpath --unix "$1"
    else
        echo "$1"
    fi
}

fi
