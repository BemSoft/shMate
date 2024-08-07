#!/usr/bin/env bash

# shellcheck disable=SC2039

if [ -z "${_SHMATE_INCLUDE_LIB_BASE}" ]; then
    readonly _SHMATE_INCLUDE_LIB_BASE='included'

#> >>> base.sh
#>
#> Base library for every other _shMate_ based library or executable.
#> Sets required global settings and adds most common functions, particularly cleanup on exit.
#>
#> >>>> Shell options
#> * posix
#> * pipefail
#> * noglob
#>
set -o pipefail -o posix -o noglob

#> >>>> Environment
#>
#> >>>>> SHMATE_INSTALL_DIR
#>
#> Path to directory where _shMate_ is installed.
#> Must be set, unless all of `SHMATE_BIN_DIR`, `SHMATE_CONF_DIR`, `SHMATE_LIB_DIR` are set.
#>

#> >>>>> SHMATE_BIN_DIR
#>
#> Path to directory containing _shMate_ executable files. Defaults to `${SHMATE_INSTALL_DIR}/bin`.
#>
if [ -z "${SHMATE_BIN_DIR}" ]; then
    export SHMATE_BIN_DIR="${SHMATE_INSTALL_DIR}/bin"
fi

#> >>>>> SHMATE_CONF_DIR
#>
#> Path to directory containing _shMate_ configuration files. Defaults to `${SHMATE_INSTALL_DIR}/etc/shmate`.
#>
if [ -z "${SHMATE_CONF_DIR}" ]; then
    export SHMATE_CONF_DIR="${SHMATE_INSTALL_DIR}/etc/shmate"
fi

#> >>>>> SHMATE_LIB_DIR
#>
#> Path to directory containing _shMate_ library files. Defaults to `${SHMATE_INSTALL_DIR}/lib/shmate`.
#>
if [ -z "${SHMATE_LIB_DIR}" ]; then
    export SHMATE_LIB_DIR="${SHMATE_INSTALL_DIR}/lib/shmate"
fi

#> >>>>> SHMATE_CURRENT_TIMESTAMP
#>
#> Setting this to nonempty string makes <<lib_shmate_base:shmate_current_timestamp>> print this value instead of actual timestamp.
#>

#> >>>> Internal symbols
#>
#> .Variables
#> [%collapsible]
#> ====
#> * _shmate_handled_signals
readonly _shmate_handled_signals='ABRT ALRM BUS FPE HUP ILL INT QUIT SEGV SYS TERM TRAP USR1 USR2 VTALRM XCPU XFSZ'
#> * _shmate_is_termination_ignored
_shmate_is_termination_ignored=false
#> ====
#>

#> .Functions
#> [%collapsible]
#> ====
#> * _shmate_cleanup
_shmate_cleanup() {
    shmate_cleanup "$@"
}

#> * _shmate_on_exit
_shmate_on_exit() {
    return $1
}

#> * _shmate_on_terminate
_shmate_on_terminate() {
    return $1
}

#> * _shmate_terminate
_shmate_terminate() {
    local signal="$1"
    local exit_code=

    exit_code=$(kill -l "${signal}") || exit_code=127
    exit_code=$((exit_code + 128))

    _shmate_on_terminate ${exit_code} "${signal}"
    shmate_on_terminate $? "${signal}" || exit $?

    _shmate_is_termination_ignored=true

    return 0
}

#> * _shmate_trap_signal
_shmate_trap_signal() {
    local handler="$1"
    shift

    local signal
    for signal in "$@"; do
        trap "${handler} ${signal}" "${signal}"
    done

    return 0
}

#> * _shmate_ignore_signal
_shmate_ignore_signal() {
    trap '' "$@"
}

#> ====
#>

#> >>>> Variables
#>
#> >>>>> shmate_os_kernel
#>
#> Kernel version, useful to detect platform.
#>
shmate_os_kernel="$(uname -s)"

#> >>>>> shmate_os_linux
#>
#> _true_ if run on Linux platform.
#>
shmate_os_linux=false

#> >>>>> shmate_os_bsd
#>
#> _true_ if run on BSD platform.
#>
shmate_os_bsd=false

#> >>>>> shmate_os_windows
#>
#> _true_ if run on Windows platform.
#>
shmate_os_windows=false

case "${shmate_os_kernel}" in
    Linux*)
        shmate_os_linux=true
        ;;
    *BSD|Darwin)
        shmate_os_bsd=true
        ;;
    CYGWIN*|MINGW*)
        shmate_os_windows=true
        export MSYS=winsymlinks:nativestrict # This will enable symbolic links in MinGW (Git for Windows)
        ;;
esac

readonly shmate_os_kernel shmate_os_linux shmate_os_windows

#> >>>>> shmate_function_main
#>
#> Function name used by <<lib_shmate_base:shmate_main>>. Defaults to `main`.
#> It is highly recommended to use the default whenever possible.
#>
readonly shmate_function_main="${shmate_function_main:-main}"

#> >>>>> shmate_function_help
#>
#> Function name or prefix used by <<lib_shmate_base:shmate_exit_help>>. Defaults to `help`.
#> It is highly recommended to use the default whenever possible.
#>
readonly shmate_function_help="${shmate_function_help:-help}"

#> >>>>> shmate_function_task
#>
#> Function prefix used by <<lib_shmate_base:shmate_task>>. Defaults to `task`.
#> It is highly recommended to use the default whenever possible.
#>
readonly shmate_function_task="${shmate_function_task:-task}"

#> >>>>> shmate_getopts_option
#>
#> Variable set by <<lib_shmate_base:shmate_getopts>> function. Contains name of the option currently being processed.
#>

#> >>>>> shmate_getopts_task
#>
#> Variable set by <<lib_shmate_base:shmate_task>> function. Contains name of the task currently being processed.
#>

#> >>>> Functions
#>
#> >>>>> shmate_cleanup <exit_code>
#>
#> Handler called just before exit. It should never be called manually, but can be implemented in caller's script.
#>
#> It may or may not have access to _stdin_, _stdout_, _stderr_ depending on the platform.
#>
shmate_cleanup() {
:
}

#> >>>>> shmate_on_exit <exit_code>
#>
#> Handler called just before <<lib_shmate_base:shmate_cleanup>>, but not upon receiving signal. It should never be called manually, but can be implemented in caller's script.
#> The returned value is passed to <<lib_shmate_base:shmate_cleanup>> and is the final exit code of the script (in most cases returning unaltered <exit_code> is desired).
#>
#> It does have access to _stdin_, _stdout_, _stderr_.
#>
shmate_on_exit() {
    return $1
}

#> >>>>> shmate_on_terminate <exit_code> <signal_name>
#>
#> Handler called just before <<lib_shmate_base:shmate_cleanup>> after receiving terminating signal (e.g. HUP, TERM, USR2). It should never be called manually, but can be implemented in caller's script.
#> The non-zero return value is passed to <<lib_shmate_base:shmate_cleanup>> and is the final exit code of the script (in most cases returning unaltered <exit_code> is desired).
#> The zero return value means the signal has been handled. To exit program with zero 'exit 0' must be called explicitly.
#>
#> It does have access to _stdin_, _stdout_, _stderr_.
#>
shmate_on_terminate() {
    return $1
}

#> >>>>> shmate_exit [<exit_code>]
#>
#> Exits with given <exit_code> or zero if not specified. Must always be used instead of plain _exit_. Calls <<lib_shmate_base:shmate_on_exit>> and <<lib_shmate_base:shmate_cleanup>> handlers.
#>
shmate_exit() {
    local exit_code="$1"
    if [ -z "${exit_code}" ]; then
        exit_code=0
    fi

    _shmate_on_exit ${exit_code}
    shmate_on_exit $?
    exit $?
}

#> >>>>> shmate_exit_help [<exit_code>]
#>
#> Prints help message end exits with given <exit_code> or zero if not specified.
#> The message is printed to stdout on zero <exit_code> or stderr otherwise.
#> The `help` function printing the message must be defined beforehand.
#> If <<lib_shmate_base:shmate_getopts_task>> is set, i.e. <<lib_shmate_base:shmate_task>> function has been called
#> beforehand, the `help_${shmate_getopts_task}` function is used instead of `help`.
#>
#> Help function prefix can be changed by setting <<lib_shmate_base:shmate_function_help>> variable before including the library.
#>
shmate_exit_help() {
    local exit_code="$1"

    if [ -z "${exit_code}" ]; then
        exit_code=0
    fi

    local handler=
    if [ -n "${shmate_getopts_task}" ]; then
        handler=$(shmate_find_handler "${shmate_getopts_task}" "${shmate_function_help}") || shmate_exit $?
    else
        handler="${shmate_function_help}"
    fi

    if [ ${exit_code} -ne 0 ]; then
        ${handler} ${exit_code} 1>&2
        shmate_fail ${exit_code}
    fi

    ${handler} ${exit_code}
    shmate_exit ${exit_code}
}

#> >>>>> shmate_log_error [<message> ...]
#>
#> Prints concatenated <messages> to _stderr_.
#>
shmate_log_error() {
    echo "$*" 1>&2
}

#> >>>>> shmate_fail <exit_code> [<message> ...]
#>
#> Prints concatenated <messages> to _stderr_ and terminates the program with <exit_code>.
#>
shmate_fail() {
    local error_code=$1
    shift

    if [ $# -eq 0 ]; then
        set -- 'Non-zero exit code'
    fi

    echo "[${error_code}] $*" 1>&2
    shmate_exit ${error_code}
}

#> >>>>> shmate_exec <command> [<command_arg> ...]
#>
#> Like ordinary `exec`, but calls <<lib_shmate_base:shmate_cleanup>> handler beforehand.
#>
shmate_exec() {
    _shmate_cleanup 0
    exec "$@"
}

#> >>>>> shmate_getopts <option_string> [<arg> ...]
#>
#> Similar to ordinary `getopts`, but it always uses the <<lib_shmate_base:shmate_getopts_option>> variable to store
#> current option name.
#> Automatically adds `-h` option handler and uses <<lib_shmate_base:shmate_exit_help>> if `-h` option is given or if
#> options are invalid.
#>
#> IMPORTANT: Like ordinary `getopts` the function returns `false` only if all options are processed, i.e. first non-option argument
#> is detected or there are no more arguments. It is therefore recommended to `shift` remaining arguments by `OPTIND - 1`
#> like in the following examples.
#>
#> .No options except help
#> ====
#> [,sh]
#> ----
#> shmate_getopts '' "$@" <1>
#> shift $((OPTIND - 1)) <2>
#> ----
#> <1> Empty <option_string> means no options except `-h` are valid.
#> <2> Shift the arguments so the first positional parameter `$1` denotes the first non-option argument, if there is any.
#> ====
#>
#> .Change current directory
#> ====
#> [,sh]
#> ----
#> while shmate_getopts 'C:' "$@"; do <1>
#>     case "${shmate_getopts_option}" in <2>
#>        C) <3>
#>            if [ -n "${OPTARG}" ]; then
#>                cd "${OPTARG}" || return $?
#>            fi
#>            ;;
#>     esac
#> done
#> shift $((OPTIND - 1)) <4>
#> ----
#> <1> `C:` as <option_string> means only `-h` option (flag) and `-C` option with argument are valid.
#> <2> Use predefined <<lib_shmate_base:shmate_getopts_option>> variable holding name of the currently processed option.
#> <3> Action to be taken when `-C` option is found. The option's argument is stored in `OPTARG` variable.
#> <4> Shift the arguments so the first positional parameter `$1` denotes the first non-option argument, if there is any.
#> ====
#>
#> .Sample script `greet`
#> [%collapsible]
#> ====
#> [,sh]
#> ----
#> include::{base-dir}/test/example/greet[]
#> ----
#> ====
#>
shmate_getopts() {
    local option_string="$1"
    shift

    local status=
    getopts ":${option_string}h" shmate_getopts_option
    status=$?
    if [ ${status} -eq 0 ]; then
        case "${shmate_getopts_option}" in
            h)
                shmate_exit_help 0
                ;;
            '?')
                shmate_log_error "$0: Illegal option \"-${OPTARG}\""
                shmate_exit_help 1
                ;;
            ':')
                shmate_log_error "$0: Option \"-${OPTARG}\" requires and argument"
                shmate_exit_help 1
                ;;
        esac
    fi

    return ${status}
}

#> >>>>> shmate_main [<arg> ...]
#>
#> Recommended entry point for all scripts using _shMate_ library.
#> Calls the `main` function defined in the calling script.
#> Must be used in the last not empty line in the calling script.
#>
#> Main function name can be changed by setting <<lib_shmate_base:shmate_function_main>> variable before including the library.
#>
#> .Sample script `greet`
#> [%collapsible]
#> ====
#> [,sh]
#> ----
#> include::{base-dir}/test/example/greet[]
#> ----
#> ====
#>
#> .Sample script `crude`
#> [%collapsible]
#> ====
#> [,sh]
#> ----
#> include::{base-dir}/test/example/crude[]
#> ----
#> ====
#>
shmate_main() {
    local OPTARG= OPTIND=1 shmate_getopts_option= shmate_getopts_task=
    "${shmate_function_main}" "$@" || shmate_fail $?
    shmate_exit 0
}

#> >>>>> shmate_task <task> [<task_arg> ...]
#>
#> Delegates execution of <task> to function `task_<task>`. The function `task_<task>` must be defined beforehand.
#> All <task_args> are passed along to the task function.
#>
#> Task function prefix can be changed by setting <<lib_shmate_base:shmate_function_task>> variable before including the library.
#>
#> .Sample script `crude`
#> [%collapsible]
#> ====
#> [,sh]
#> ----
#> include::{base-dir}/test/example/crude[]
#> ----
#> ====
#>
shmate_task() {
    shmate_getopts_task="$1"
    shift 1

    if [ -z "${shmate_getopts_task}" ]; then
        shmate_log_error "$0: Task must be specified"
        shmate_exit_help 1
    fi

    local handler=
    handler=$(shmate_find_handler "${shmate_getopts_task}" "${shmate_function_task}") || {
        shmate_log_error "$0: Illegal task \"${shmate_getopts_task}\""
        shmate_getopts_task=
        shmate_exit_help 1
    }

    readonly shmate_getopts_task
    OPTIND=1
    ${handler} "$@"
}

#> >>>>> shmate_find_handler <name> <prefix> [<suffix>]
#>
#> Converts the <name> to lowercase and converts non-word characters to underscores.
#> Then checks if function <prefix>_<name>_<suffix> (or <prefix>_<name> if <suffix> is not given) exists.
#> Prints the function's name if found. Returns non-zero otherwise.
#>
shmate_find_handler() {
    local name="$1"
    local prefix="$2"
    local suffix="$3" # optional

    prefix="${prefix}_"
    if [ -n "${suffix}" ]; then
        suffix="_${suffix}"
    fi

    name=$(echo -n "${name}" | tr '[:upper:]' '[:lower:]' | tr -Cs '[:alnum:]' '_')
    name="${prefix}${name}${suffix}"

    local handler=
    handler=$(command -v "${name}") || return $?

    if [ "${name}" != "${handler}" ]; then
        return 2
    fi

    echo "${handler}"

    return 0
}

#> >>>>> shmate_quoted_echo [-ne] [<string> ...]
#>
#> Just like ordinary _echo_ but adds single quotes for every argument. Multiple flags must be specified as single option i.e. '-ne', not '-n' '-e'.
#>
shmate_quoted_echo() {
    local flags="$1"
    case "${flags}" in
        -*)
            shift
            ;;
        *)
            flags=
            ;;
    esac

    if [ $# -le 0 ]; then
        echo ${flags}
        return $?
    fi

    local quoted_string="'$1'"
    shift

    if [ $# -gt 0 ]; then
        quoted_string="${quoted_string}$(printf " '%s'" "$@")"
    fi
    echo ${flags} "${quoted_string}"

    return 0
}

#> >>>>> shmate_filter_grep [<grep_arg> ...]
#>
#> Just like ordinary _grep_ but ignoring error if no lines were found (never returns 1). Useful for filtering and simpler than _sed_ for this purpose.
#>
shmate_filter_grep() {
    local exit_code=

    grep "$@"

    exit_code=$?
    if [ ${exit_code} -eq 1 ]; then
        return 0
    fi

    return ${exit_code}
}

#> >>>>> shmate_string_cat [<string> ...]
#>
#> Prints every <string> in separate line. If <string> equals '-' prints stdin instead. '-' can only be used once.
#>
shmate_string_cat() {
    for string in "$@"; do
        if [ "${string}" = '-' ]; then
            cat || return $?
        else
            echo "${string}"
        fi
    done || return $?

    return 0
}

#> >>>>> shmate_string_cat_buf [<string> ...]
#>
#> Like ordinary <<lib_shmate_base:shmate_string_cat>>, but all <strings> and the whole stdin (if '-' is provided) are buffered and then printed as one.
#>
shmate_string_cat_buf() {
    local buffer=
    for string in "$@"; do
        if [ "${string}" = '-' ]; then
            buffer="${buffer}$(cat)
" || return $?
        else
            buffer="${buffer}${string}
"
        fi
    done || return $?

    echo -n "${buffer}"

    return 0
}

#> >>>>> shmate_stream_cat [<string> ...]
#>
#> Prints every <string> as is, i.e., one after another. If <string> equals '-' prints stdin instead. '-' can only be used once.
#>
shmate_stream_cat() {
    for string in "$@"; do
        if [ "${string}" = '-' ]; then
            cat || return $?
        else
            echo -n "${string}"
        fi
    done || return $?

    return 0
}

#> >>>>> shmate_input_run <input_string> <command> [<command_arg> ...]
#>
#> Executes <command> with <command_args> providing <input_string> to command as stdin.
#>
#> CAUTION: The input for <command> will always contain an extra _LF_ (newline). If this is a concern `echo -n` can be used instead.
#>
shmate_input_run() {
    local input="$1"
    shift

    "$@" << EOF
${input}
EOF

    return $?
}

#> >>>>> shmate_contains [<string> ...]
#>
#> Reads every line of input and returns success if all the given <strings> are equal to at least one of the lines.
#>
shmate_contains() {
    local input=
    local expected=

    input=$(shmate_filter_list "$@" | sort) || return $?
    expected=$(shmate_string_cat "$@" | sort) || return $?

    test "${input}" = "${expected}"
    return $?
}

#> >>>>> shmate_filter_list [<string> ...]
#>
#> Reads every line of input and prints only lines equal to any of the given <strings>.
#>
shmate_filter_list() {
    local input=
    local expected=

    local IFS='
'
    while read -r input; do
        for expected in "$@"; do
            if [ "${input}" = "${expected}" ]; then
                echo "${input}"
                break
            fi
        done || return $?
    done || return $?

    return 0
}

#> >>>>> shmate_filter_out_list [<string> ...]
#>
#> Reads every line of input and prints only lines NOT equal to all the given <strings>.
#>
shmate_filter_out_list() {
    local input=
    local not_expected=

    local IFS='
'
    while read -r input; do
        for not_expected in "$@"; do
            if [ "${input}" = "${not_expected}" ]; then
                continue 2
            fi
        done || return $?
        echo "${input}"
    done || return $?

    return 0
}

#> >>>>> shmate_invert_list
#>
#> Reads all lines of input and prints them in inverse order.
#>
shmate_invert_list() {
    local input=
    local output=

    local IFS='
'
    while read -r input; do
        output="${input}
${output}"
    done || return $?

    echo -n "${output}"

    return 0
}

#> >>>>> shmate_iso_day <date> [<days>]
#>
#> Converts <date> to ISO 8601 date. If given, adds <days> to the date, e.g., '+1' '-23'.
#> Requires Linux `date` command.
#>
shmate_iso_day() {
    local value="$1"
    local days="$2" # '+n' or '-n'

    # Linux specific
    if [ -n "${days}" ]; then
        value="${value} ${days}day"
    fi
    date -I -d "${value}"

    return $?
}

#> >>>>> shmate_time_interval <date1> <date2>
#>
#> Calculates interval in seconds between two dates. Arguments can be in any format understood by 'date', although
#> ISO 8601 is recommended. Requires Linux `date` command.
#>
shmate_time_interval() {
    local date1="$1"
    local date2="$2"

    # Linux specific
    date1=$(date +%s -d "${date1}") || return $?
    date2=$(date +%s -d "${date2}") || return $?

    echo $((date2 - date1))

    return $?
}

#> >>>>> shmate_day_interval <date1> <date2>
#>
#> Calculates interval in days between two dates. Arguments can be in any format understood by 'date', although
#> ISO 8601 is recommended. Requires Linux `date` command.
#>
shmate_day_interval() {
    local interval=
    interval=$(shmate_time_interval "$1" "$2") || return $?

    echo $((interval / 86400))

    return $?
}

#> >>>>> shmate_dotenv [<file_path>]
#>
#> Reads _dotenv_ file (or stdin) as single line of key=value pairs. Useful to export variables from _dotenv_ file.
#> To export all variables from not empty trusted '.env' dotenv file call:
#>
#>     eval "export $(shmate_dotenv '.env')"
#>
shmate_dotenv() {
    local dotenv_file="$1"
    if [ -z "${dotenv_file}" ]; then
        dotenv_file='-'
    fi
    grep -v '^(#|$)' "${dotenv_file}" | tr '\n' ' '

    return $?
}

#> >>>>> shmate_has_one_line <string>
#>
#> Checks if <string> has at most one line of text.
#>
shmate_has_one_line() {
    local NL='
'

    case "$1" in
        *"${NL}"*)
            return 1
            ;;
    esac

    return 0
}

#> >>>>> shmate_current_timestamp
#>
#> Prints current UTC timestamp in ISO 8601 format. Output can be fixed with `SHMATE_CURRENT_TIMESTAMP`.
#>
shmate_current_timestamp() {
    if [ -n "${SHMATE_CURRENT_TIMESTAMP}" ]; then
        echo "${SHMATE_CURRENT_TIMESTAMP}"
    else
        date -uIseconds
    fi

    return $?
}

#> >>>>> shmate_is_unsigned_integer <string>
#>
#> Returns success only if <string> is not negative integer.
#>
shmate_is_unsigned_integer() {
    case $1 in
        ''|*[!0-9]*)
            return 1
        ;;
        *)
            return 0
        ;;
    esac
}

trap '_shmate_cleanup $?' EXIT
_shmate_trap_signal _shmate_terminate ${_shmate_handled_signals}

fi
