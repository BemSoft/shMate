#!/usr/bin/env bash

# shellcheck disable=SC2039

if [ -z "${_SHMATE_INCLUDE_LIB_ASSERT}" ]; then
    readonly _SHMATE_INCLUDE_LIB_ASSERT='included'

#> >>> assert.sh
#>
#> Base library for every other _shMate_ based library or executable needing logging or assertions.
#> Adds logging and assertion related functions. Detects color support.
#>
#> NOTE: Log messages are always printed to _stderr_.
#>
#> >>>> Dependencies
#> * <<lib_shmate_base>>
#> * <<lib_shmate_-deprecated>>
#>

# shellcheck source=src/lib/shmate/base.sh
. "${SHMATE_LIB_DIR}/base.sh"
# shellcheck source=src/lib/shmate/_deprecated.sh
. "${SHMATE_LIB_DIR}/_deprecated.sh"

#> >>>> Environment
#>
#> >>>>> SHMATE_DEBUG_LEVEL
#>
#> Integer value of current debug level. Defaults to 0.
#>
#> 0:: Print informational log messages only.
#> 1:: Print informational log messages + _AUDIT_ log messages.
#> 2:: Print informational log messages + _AUDIT_ + _DEBUG_ log messages.
#> 3:: Print informational log messages + _AUDIT_ + _DEBUG_ + _ASSERT_ log messages.
#>
#> >>>>> SHMATE_COLORS
#>
#> Integer controlling colorful logging. Not set by default i.e. auto detect.
#>
#> 0::: disabled
#> greater than 0::: enabled
#> not set::: auto detect
#>
#> >>>>> SHMATE_TIMESTAMP_FORMAT
#>
#> Timestamp format accepted by _date_ command. Defaults to `%Y-%m-%dT%H:%M:%SZ` or `%Y-%m-%dT%H:%M:%S` if <<lib_shmate_assert:SHMATE_TIMESTAMP_LOCAL>> is a positive integer.
#>
#> >>>>> SHMATE_TIMESTAMP_LOCAL
#>
#> Setting this to positive integer makes all timestamps in local time zone instead of UTC.
SHMATE_TIMESTAMP_LOCAL=${SHMATE_TIMESTAMP_LOCAL:-0}
#>
#> >>>>> SHMATE_LOG
#>
#> Path to log file. If set, console log will be duplicated to the log file.
#>
#> >>>>> SHMATE_LOG_PERMS
#>
#> Log file permissions.
#>
#> >>>>> SHMATE_LOG_ANSI_ESCAPE
#>
#> Setting this to positive integer indicates the log message contains link:https://en.wikipedia.org/wiki/ANSI_escape_code[_ANSI escape sequences_]
#> needed to be processed when logging to console or needed to be removed if logging to file. Should be used on demand as `local` variable.
#>
SHMATE_LOG_ANSI_ESCAPE=${SHMATE_LOG_ANSI_ESCAPE:-0}

#> >>>>> SHMATE_LOG_IN_PLACE
#>
#> Setting this to positive integer disables logging to file and final _CRLF_ sequence in console log is replaced with single carriage return.
#> Useful for logging progress messages. The message should be one-liner. Should be used on demand as `local` variable.
SHMATE_LOG_IN_PLACE=${SHMATE_LOG_IN_PLACE:-0}
#>

#> >>>> Debugging log levels
#>
#> ASSERT:: TODO
#> DEBUG:: TODO
#> AUDIT:: TODO
#>
#> >>>> Informational log levels
#>
#> INFO:: TODO
#> WARNING:: TODO
#> ERROR:: TODO
#> PENDING:: TODO
#> SUCCESS:: TODO
#> FAILURE:: TODO
#>

#> >>>> Internal symbols
#>
#> .Variables
#> [%collapsible]
#> ====
#> * _SHMATE_PID
#> * _SHMATE_PID_FILE
#> * _shmate_log_label_assert
_shmate_log_label_assert=
#> * _shmate_log_label_debug
_shmate_log_label_debug=
#> * _shmate_log_label_audit
_shmate_log_label_audit=
#> * _shmate_log_label_info
_shmate_log_label_info=
#> * _shmate_log_label_warning
_shmate_log_label_warning=
#> * _shmate_log_label_error
_shmate_log_label_error=
#> * _shmate_log_label_pending
_shmate_log_label_pending=
#> * _shmate_log_label_success
_shmate_log_label_success=
#> * _shmate_log_label_failure
_shmate_log_label_failure=

#> * _shmate_console_label_assert
_shmate_console_label_assert=
#> * _shmate_console_label_debug
_shmate_console_label_debug=
#> * _shmate_console_label_audit
_shmate_console_label_audit=
#> * _shmate_console_label_info
_shmate_console_label_info=
#> * _shmate_console_label_warning
_shmate_console_label_warning=
#> * _shmate_console_label_error
_shmate_console_label_error=
#> * _shmate_console_label_pending
_shmate_console_label_pending=
#> * _shmate_console_label_success
_shmate_console_label_success=
#> * _shmate_console_label_failure
_shmate_console_label_failure=

#> * _shmate_assert_message
_shmate_assert_message=
#> * _shmate_assert_message_stack
_shmate_assert_message_stack=
#> * _shmate_log_audit_format
_shmate_log_audit_format=
#> * _shmate_log_audit_args
_shmate_log_audit_args=
#> * _shmate_console_audit_format
_shmate_console_audit_format=
#> * _shmate_console_audit_args
_shmate_console_audit_args=
#> * _shmate_log_audit_separator
readonly _shmate_log_audit_separator=$(printf '\022')
#> ====
#>

#> .Functions
#> [%collapsible]
#> ====
#> * _shmate_assert_with_level
_shmate_assert_with_level() {
    _shmate_ignore_sigpipe

    local status=$?
    local log_level="$1"
    shift

    local error_code=${status}
    if _shmate_is_error_code "$1"; then
        error_code=$1
        shift
    fi

    local message="$*"
    if [ -z "${message}" ]; then
        message='Asserting successful command execution'
    fi

    if [ ${status} -gt 0 ]; then
        shmate_log_${log_level} "[${error_code}] ${message}"
        return ${error_code}
    else
        shmate_log_assert "${message}"
    fi

    return 0
}

#> * _shmate_colors
_shmate_colors() {
    local colors="$1"

    if [ -n "${colors}" ]; then
        SHMATE_COLORS="${colors}"
    fi

    if [ -z "${SHMATE_COLORS}" ]; then
        SHMATE_COLORS=0

        # Detect if stderr supports colors
        if [ -t 2 ]; then
            if shmate_check_tools tput; then
                SHMATE_COLORS=$(tput colors)
                if [ -z "${SHMATE_COLORS}" ] || [ ${SHMATE_COLORS} -lt 8 ]; then
                    SHMATE_COLORS=0
                fi
            else
                case "${TERM}" in
                    *color*)
                        SHMATE_COLORS=1
                        ;;
                esac
            fi
        fi
    fi

    _shmate_log_label_assert='ASSERT '
    _shmate_log_label_debug='DEBUG  '
    _shmate_log_label_audit='AUDIT  '
    _shmate_log_label_info='INFO   '
    _shmate_log_label_warning='WARNING'
    _shmate_log_label_error='ERROR  '
    _shmate_log_label_pending='PENDING'
    _shmate_log_label_success='SUCCESS'
    _shmate_log_label_failure='FAILURE'

    local color_off='\e[0m'

    case ${SHMATE_COLORS} in
        0)
            _shmate_console_label_assert="${_shmate_log_label_assert}"
            _shmate_console_label_debug="${_shmate_log_label_debug}"
            _shmate_console_label_audit="${_shmate_log_label_audit}"
            _shmate_console_label_info="${_shmate_log_label_info}"
            _shmate_console_label_warning="${_shmate_log_label_warning}"
            _shmate_console_label_error="${_shmate_log_label_error}"
            _shmate_console_label_pending="${_shmate_log_label_pending}"
            _shmate_console_label_success="${_shmate_log_label_success}"
            _shmate_console_label_failure="${_shmate_log_label_failure}"
            ;;
        -1)
            _shmate_log_label_assert='assert '
            _shmate_log_label_debug='debug  '
            _shmate_log_label_audit='audit  '
            _shmate_log_label_info='info   '
            _shmate_log_label_warning='warning'
            _shmate_log_label_error='error  '
            _shmate_log_label_pending='pending'
            _shmate_log_label_success='success'
            _shmate_log_label_failure='failure'

            local color_on='\e[0;37m'

            _shmate_console_label_assert="${color_on}${_shmate_log_label_assert}${color_off}"
            _shmate_console_label_debug="${color_on}${_shmate_log_label_debug}${color_off}"
            _shmate_console_label_audit="${color_on}${_shmate_log_label_audit}${color_off}"
            _shmate_console_label_info="${color_on}${_shmate_log_label_info}${color_off}"
            _shmate_console_label_warning="${color_on}${_shmate_log_label_warning}${color_off}"
            _shmate_console_label_error="${color_on}${_shmate_log_label_error}${color_off}"
            _shmate_console_label_pending="${color_on}${_shmate_log_label_pending}${color_off}"
            _shmate_console_label_success="${color_on}${_shmate_log_label_success}${color_off}"
            _shmate_console_label_failure="${color_on}${_shmate_log_label_failure}${color_off}"
            ;;
        *)
            if [ ${SHMATE_COLORS} -gt 0 ]; then
                _shmate_console_label_assert="\e[0;37m${_shmate_log_label_assert}${color_off}"
                _shmate_console_label_debug="\e[1;37m${_shmate_log_label_debug}${color_off}"
                _shmate_console_label_audit="\e[1;37m${_shmate_log_label_audit}${color_off}"
                _shmate_console_label_info="\e[1;36m${_shmate_log_label_info}${color_off}"
                _shmate_console_label_warning="\e[1;33m${_shmate_log_label_warning}${color_off}"
                _shmate_console_label_error="\e[1;31m${_shmate_log_label_error}${color_off}"
                _shmate_console_label_pending="\e[1;35m${_shmate_log_label_pending}${color_off}"
                _shmate_console_label_success="\e[1;32m${_shmate_log_label_success}${color_off}"
                _shmate_console_label_failure="\e[1;31m${_shmate_log_label_failure}${color_off}"
            else
                shmate_log_error "Invalid color scheme value \"${colors}\""
                SHMATE_COLORS=0

                _shmate_console_label_assert="${_shmate_log_label_assert}"
                _shmate_console_label_debug="${_shmate_log_label_debug}"
                _shmate_console_label_audit="${_shmate_log_label_audit}"
                _shmate_console_label_info="${_shmate_log_label_info}"
                _shmate_console_label_warning="${_shmate_log_label_warning}"
                _shmate_console_label_error="${_shmate_log_label_error}"
                _shmate_console_label_pending="${_shmate_log_label_pending}"
                _shmate_console_label_success="${_shmate_log_label_success}"
                _shmate_console_label_failure="${_shmate_log_label_failure}"
            fi
            ;;
    esac

    export SHMATE_COLORS
    return 0
}

#> * _shmate_create_log_file
_shmate_create_log_file() {
    if [ -n "${SHMATE_LOG}" ]; then
        SHMATE_LOG=$(realpath "${SHMATE_LOG}")

        mkdir -p "${SHMATE_LOG%/*}" && touch "${SHMATE_LOG}" && export SHMATE_LOG || {
            local log_file="${SHMATE_LOG}"
            unset SHMATE_LOG
            shmate_log_error "Could not open log file \"${log_file}\""
        }

        if [ -n "${SHMATE_LOG}" ] && [ -n "${SHMATE_LOG_PERMS}" ]; then
            shmate_audit chmod "${SHMATE_LOG_PERMS}" "${SHMATE_LOG}"
            shmate_assert "Setting log file permissions to \"${SHMATE_LOG_PERMS}\"" # Proceed anyway
        fi
    fi

    return 0
}

#> * _shmate_get_pid
_shmate_get_pid() {
    if [ -n "${_SHMATE_PID}" ]; then
        return 0
    fi

    if [ -z "${_SHMATE_PID_FILE}" ]; then
        _SHMATE_PID=$$
        return 0
    fi

    _SHMATE_PID=0

    local counter=5
    local pid=
    while [ ${counter} -gt 0 ]; do
        pid=$(cat "${_SHMATE_PID_FILE}")
        if [ -n "${pid}" ]; then
            _SHMATE_PID=${pid}
            break
        fi

        counter=$((counter - 1))
        sleep 1
    done

    return 0
}

#> * _shmate_ignore_sigpipe
_shmate_ignore_sigpipe() {
    local status=$?
    if [ ${status} -eq 141 ]; then
        shmate_log_debug 'Ignoring SIGPIPE'
        return 0
    fi
    return ${status}
}

#> * _shmate_is_error_code
_shmate_is_error_code() {
    shmate_is_unsigned_integer "$1"
}

#> * _shmate_log_audit_add
_shmate_log_audit_add() {
    local format="$1"
    shift

    _shmate_log_audit_format="${_shmate_log_audit_format}${format}"

    local arg=
    for arg in "$@"; do
        _shmate_log_audit_args="${_shmate_log_audit_args}${arg}${_shmate_log_audit_separator}"
    done
}

#> * _shmate_console_audit_add
_shmate_console_audit_add() {
    local format="$1"
    shift

    _shmate_console_audit_format="${_shmate_console_audit_format}${format}"

    local arg=
    for arg in "$@"; do
        _shmate_console_audit_args="${_shmate_console_audit_args}${arg}${_shmate_log_audit_separator}"
    done
}

#> * _shmate_log_audit_myself
_shmate_log_audit_myself() {
    if [ ${shmate_debug_level} -ge ${shmate_debug_level_audit} ]; then
        # Warning! Obtaining parent command name is highly platform dependent
        local parent_command=
        if $shmate_os_linux; then
            if [ ${PPID} -le 0 ]; then
                # kubectl exec sets PPID to illegal value 0
                parent_command='[kernel]'
            else
                parent_command=$(ps -p ${PPID} -o comm=) || shmate_log_warning "Could not get parent command name using \"ps -p ${PPID} -o comm=\""
            fi
        elif $shmate_os_windows; then
            parent_command=$(ps -s -p ${PPID} | tail -n +2 | cut -b 27-) || shmate_log_warning 'Could not get parent command name'
        else
            shmate_log_warning "Unsupported kernel \"${shmate_os_kernel}\""
        fi

        shmate_log_audit_begin "${parent_command}" && \
            shmate_log_audit_command "$@" && \
            shmate_log_audit_end
    fi
    return 0
}

#> * _shmate_log_message
_shmate_log_message() {
    local timestamp=
    timestamp="$(_shmate_log_timestamp)" || return $?

    local message="$*"

    _shmate_get_pid
    local pid="${_SHMATE_PID}"

    if [ ${SHMATE_LOG_ANSI_ESCAPE} -gt 0 ]; then
        message="$(echo -en "${message}x")"
        message="${message%x}"
    fi
    local crlf="${shmate_console_crlf}"
    if [ ${SHMATE_LOG_IN_PLACE} -gt 0  ]; then
        crlf='\r'
    fi
    printf "${shmate_console_format}${crlf}" "${timestamp}" "${_shmate_console_label}" "${pid}" "${message}" 1>&2

    if [ -n "${SHMATE_LOG}" -a ${SHMATE_LOG_IN_PLACE} -le 0 ]; then
        message="$*"
        if [ ${SHMATE_LOG_ANSI_ESCAPE} -gt 0 ]; then
            message="$(echo -n "${message}x" | sed -E "s/${shmate_ansi_escape_sequence_regex}//g")"
            message="${message%x}"
        fi
        printf "${shmate_log_format}${shmate_log_crlf}" "${timestamp}" "${_shmate_log_label}" "${pid}" "${message}" >> "${SHMATE_LOG}"
    fi
}

#> * _shmate_log_timestamp
if [ ${SHMATE_TIMESTAMP_LOCAL} -gt 0 ]; then
_shmate_log_timestamp() {
    date "+${shmate_timestamp_format}"
}
else
_shmate_log_timestamp() {
    date -u "+${shmate_timestamp_format}"
}
fi

#> * _shmate_lib_assert_cleanup
_shmate_lib_assert_cleanup() {
    shmate_cleanup "$@"
    shmate_log_audit_begin && shmate_log_audit_text "Exiting with code $1" && shmate_log_audit_end
}

#> * _shmate_lib_assert_on_exit
_shmate_lib_assert_on_exit() {
    shmate_log_debug "'$0' exiting with code $1"
    return $1
}

#> * _shmate_lib_assert_on_terminate
_shmate_lib_assert_on_terminate() {
    shmate_log_audit_begin && shmate_log_audit_text "Received $2 signal" && shmate_log_audit_end
    return $1
}

#> ====
#>

_shmate_cleanup() {
    _shmate_lib_assert_cleanup "$@"
}

_shmate_on_exit() {
    _shmate_lib_assert_on_exit "$@"
}

_shmate_on_terminate() {
    _shmate_lib_assert_on_terminate "$@"
}

#> >>>> Variables
#>
#> >>>>> shmate_ansi_escape_sequence_regex
#>
#> Regular expression to match link:https://en.wikipedia.org/wiki/ANSI_escape_code[_ANSI escape sequence_].
#>
readonly shmate_ansi_escape_sequence_regex="($(echo -ne '\e')|\\\\e)[^m]*m"

#> >>>>> shmate_hostname
#>
#> Fully qualified host name.
#>
shmate_hostname="${CI_SERVER_HOST}" # FIXME
if [ -z "${shmate_hostname}" ]; then
    shmate_hostname=$(hostname -f 2> /dev/null || echo 'localhost')
fi
readonly shmate_hostname

#> >>>>> shmate_debug_level_audit
#>
#> Integer value of _AUDIT_ log level.
#>
readonly shmate_debug_level_audit=1

#> >>>>> shmate_debug_level_debug
#>
#> Integer value of _DEBUG_ log level.
#>
readonly shmate_debug_level_debug=2

#> >>>>> shmate_debug_level_assert
#>
#> Integer value of _ASSERT_ log level.
#>
readonly shmate_debug_level_assert=3

#> >>>>> shmate_debug_level
#>
#> Integer value of current debug level.
#>
readonly shmate_debug_level=${SHMATE_DEBUG_LEVEL:-0}

#> >>>>> shmate_log_crlf
#>
#> Log file line ending character sequence accepted by _printf_ command.
#>
readonly shmate_log_crlf="${SHMATE_LOG_CRLF:-\n}"

#> >>>>> shmate_log_format
#>
#> Log file line format accepted by _printf_ command.
#>
readonly shmate_log_format="${SHMATE_LOG_FORMAT:-[%s] [%b] [%7d] %s}"

#> >>>>> shmate_console_crlf
#>
#> Console log line ending character sequence accepted by _printf_ command.
#>
shmate_console_crlf="${SHMATE_CONSOLE_CRLF}"
if [ -z "${shmate_console_crlf}" ]; then
    if ${shmate_os_windows}; then
        shmate_console_crlf='\r\n'
    else
        shmate_console_crlf='\n'
    fi
fi
readonly shmate_console_crlf

#> >>>>> shmate_console_format
#>
#> Console log line format accepted by _printf_ command.
#>
readonly shmate_console_format="${SHMATE_CONSOLE_FORMAT:-${shmate_log_format}}"

#> >>>>> shmate_timestamp_format
#>
#> Timestamp format accepted by _date_ command.
#>
if [ ${SHMATE_TIMESTAMP_LOCAL} -gt 0 ]; then
    shmate_timestamp_format="${SHMATE_TIMESTAMP_FORMAT:-%Y-%m-%dT%H:%M:%S}"
else
    shmate_timestamp_format="${SHMATE_TIMESTAMP_FORMAT:-%Y-%m-%dT%H:%M:%SZ}"
fi
readonly shmate_timestamp_format

#> >>>> Functions
#>

shmate_exec() {
    _shmate_cleanup 0
    shmate_audit exec "$@"
}

#> >>>>> shmate_colors_grayout
#>
#> Changes terminal color scheme to grayed out.
#>
shmate_colors_grayout() {
    _shmate_colors -1
}

#> >>>>> shmate_colors_disable
#>
#> Disables terminal colors.
#>
shmate_colors_disable() {
    _shmate_colors 0
}

#> >>>>> shmate_log_assert [<message> ...]
#>
#> Logs concatenated <messages> in _ASSERT_ level.
#>
shmate_log_assert() {
    if [ ${shmate_debug_level} -ge ${shmate_debug_level_assert} ]; then
        local _shmate_log_label="${_shmate_log_label_assert}"
        local _shmate_console_label="${_shmate_console_label_assert}"

        _shmate_log_message "$@"
    fi
    return 0
}

#> >>>>> shmate_log_debug [<message> ...]
#>
#> Logs concatenated <messages> in _DEBUG_ level.
#>
shmate_log_debug() {
    if [ ${shmate_debug_level} -ge ${shmate_debug_level_debug} ]; then
        local _shmate_log_label="${_shmate_log_label_debug}"
        local _shmate_console_label="${_shmate_console_label_debug}"

        _shmate_log_message "$@"
    fi
    return 0
}

#> >>>>> shmate_log_info [<message> ...]
#>
#> Logs concatenated <messages> in _INFO_ level.
#>
shmate_log_info() {
    local _shmate_log_label="${_shmate_log_label_info}"
    local _shmate_console_label="${_shmate_console_label_info}"

    _shmate_log_message "$@"

    return 0
}

#> >>>>> shmate_log_warning [<message> ...]
#>
#> Logs concatenated <messages> in _WARNING_ level.
#>
shmate_log_warning() {
    local _shmate_log_label="${_shmate_log_label_warning}"
    local _shmate_console_label="${_shmate_console_label_warning}"

    _shmate_log_message "$@"

    return 0
}

#> >>>>> shmate_log_warn [<message> ...]
#>
#> Alias for <<lib_shmate_assert:shmate_log_warning>>.
#>
shmate_log_warn() {
    shmate_log_warning "$@"
}

#> >>>>> shmate_log_error [<message> ...]
#>
#> Logs concatenated <messages> in _ERROR_ level.
#>
shmate_log_error() {
    local _shmate_log_label="${_shmate_log_label_error}"
    local _shmate_console_label="${_shmate_console_label_error}"

    _shmate_log_message "$@"

    return 0
}

#> >>>>> shmate_log_pending [<message> ...]
#>
#> Logs concatenated <messages> in _PENDING_ level.
#>
#> TIP: Direct use of this function should be avoided in favor of <<lib_shmate_assert:shmate_pending_assert>>.
#>
shmate_log_pending() {
    local _shmate_log_label="${_shmate_log_label_pending}"
    local _shmate_console_label="${_shmate_console_label_pending}"

    _shmate_log_message "$@"

    return 0
}

#> >>>>> shmate_log_success [<message> ...]
#>
#> Logs concatenated <messages> in _SUCCESS_ level.
#>
#> TIP: Direct use of this function should be avoided in favor of <<lib_shmate_assert:shmate_loud_assert>>.
#>
shmate_log_success() {
    local _shmate_log_label="${_shmate_log_label_success}"
    local _shmate_console_label="${_shmate_console_label_success}"

    _shmate_log_message "$@"

    return 0
}

#> >>>>> shmate_log_failure [<message> ...]
#>
#> Logs concatenated <messages> in _FAILURE_ level.
#>
shmate_log_failure() {
    local _shmate_log_label="${_shmate_log_label_failure}"
    local _shmate_console_label="${_shmate_console_label_failure}"

    _shmate_log_message "$@"

    return 0
}

#> >>>>> shmate_log_fail [<message> ...]
#>
#> Alias for <<lib_shmate_assert:shmate_log_failure>>.
#>
shmate_log_fail() {
    shmate_log_failure "$@"
}

#> >>>>> shmate_log_deprecated <since_version> <symbol_type> <symbol_name> <resolution>
#>
#> Logs deprecated symbols.
#>
shmate_log_deprecated() {
    local since_version="$1"
    local symbol_type="$2"
    local symbol_name="$3"
    local resolution="$4"

    shmate_log_warning "Deprecated ${symbol_type} '${symbol_name}' since version '${since_version}' with resolution: ${resolution}"
}

#> >>>>> shmate_log_audit <command> [<command_arg> ...]
#>
#> Logs <command> and <command_args> in _AUDIT_ level.
#>
shmate_log_audit() {
    shmate_log_audit_begin && shmate_log_audit_command "$@" && shmate_log_audit_end

    return 0
}

shmate_log_audit_begin() {
    if [ ${shmate_debug_level} -ge ${shmate_debug_level_audit} ]; then
        local command="$1"
        if [ -z "${command}" ]; then
            command="$0"
        fi

        local timestamp=
        timestamp="$(_shmate_log_timestamp)" || return $?

        local user=
        user="$(id -nu)" || return $?

        _shmate_get_pid
        local pid=${_SHMATE_PID}

        if [ -n "${SHMATE_LOG}" ]; then
            _shmate_log_audit_format="${shmate_log_format}"
            _shmate_log_audit_args="${timestamp}${_shmate_log_audit_separator}${_shmate_log_label_audit}${_shmate_log_audit_separator}${pid}${_shmate_log_audit_separator}${user}: ${command}${_shmate_log_audit_separator}"

            _shmate_log_audit_add "${shmate_log_crlf}"
            _shmate_log_audit_add '%s' '$'
        fi

        _shmate_console_audit_format="${shmate_console_format}"
        _shmate_console_audit_args="${timestamp}${_shmate_log_audit_separator}${_shmate_console_label_audit}${_shmate_log_audit_separator}${pid}${_shmate_log_audit_separator}${user}: ${command}${_shmate_log_audit_separator}"

        _shmate_console_audit_add "${shmate_console_crlf}"

        if [ ${SHMATE_COLORS} -gt 0 ]; then
            _shmate_console_audit_add '%b%s%b' '\e[1;37m' '$' '\e[0m'
        else
            _shmate_console_audit_add '%s' '$'
        fi

        return 0
    fi

    return 1
}

shmate_log_audit_text() {
    if [ -n "${SHMATE_LOG}" ]; then
        _shmate_log_audit_add ' %s' "$*"
    fi
    _shmate_console_audit_add ' %s' "$*"

    return 0
}

shmate_log_audit_command() {
    if [ -n "${SHMATE_LOG}" ]; then
        _shmate_log_audit_add ' %s' "$(shmate_quoted_echo -n "$@")"
    fi

    if [ ${SHMATE_COLORS} -gt 0 ]; then
        local command="'$1'"
        shift

        _shmate_console_audit_add ' %b%s%b %s%b' '\e[0;36m' "${command}" '\e[0;32m' "$(shmate_quoted_echo -n "$@")" '\e[0m'
    else
        _shmate_console_audit_add ' %s' "$(shmate_quoted_echo -n "$@")"
    fi

    return 0
}

shmate_log_audit_operator() {
    shmate_log_audit_text "$@"

    return $?
}

shmate_log_audit_file() {
    if [ -n "${SHMATE_LOG}" ]; then
        _shmate_log_audit_add ' %s' "$(shmate_quoted_echo -n "$@")"
    fi

    if [ ${SHMATE_COLORS} -gt 0 ]; then
        _shmate_console_audit_add ' %b%s%b' '\e[0;33m' "$(shmate_quoted_echo -n "$@")" '\e[0m'
    else
        _shmate_console_audit_add ' %s' "$(shmate_quoted_echo -n "$@")"
    fi

    return 0
}

shmate_log_audit_end() {
    local arg=
    local IFS=${_shmate_log_audit_separator}

    if [ -n "${SHMATE_LOG}" ]; then
        set --
        for arg in ${_shmate_log_audit_args}; do
            set "$@" "${arg}"
        done
        printf "${_shmate_log_audit_format}${shmate_log_crlf}" "$@" >> "${SHMATE_LOG}"
    fi

    set --
    for arg in ${_shmate_console_audit_args}; do
        set "$@" "${arg}"
    done
    printf "${_shmate_console_audit_format}${shmate_console_crlf}" "$@" 1>&2

    return 0
}

#> >>>>> shmate_audit <command> [<command_arg> ...]
#>
#> Logs <command> execution in _AUDIT_ level and runs the <command> with <command_args>.
#>
shmate_audit() {
    shmate_log_audit "$@"
    "$@"
    return $?
}

#> >>>>> shmate_fail <exit_code> [<message> ...]
#>
#> Logs concatenated <messages> in _FAILURE_ level and terminates the program with <exit_code>.
#>
shmate_fail() {
    local error_code=$1
    shift

    if [ $# -eq 0 ]; then
        set -- 'Non-zero exit code'
    fi

    if [ ${SHMATE_SUPPRESS_FAILURE_EXIT} -le 0 ]; then
        shmate_log_failure "[${error_code}]" "$@"
    fi
    shmate_exit ${error_code}
}

#> >>>>> shmate_check_tools [<optional_tool> ...]
#>
#> Checks if all the <optional_tools> are found on _PATH_. Returns non-zero value if not.
#> See <<lib_shmate_assert:shmate_assert_tools>> for loud version.
#>
shmate_check_tools() {
    local optional_tool=
    local exit_code=0

    if ${shmate_os_windows}; then
        set +o posix
    fi

    for optional_tool in "$@"; do
        if ! [ -e "$(command -v "${optional_tool}")" ]; then
            shmate_log_debug "Optional tool \"${optional_tool}\" is not found on PATH:
${PATH}"
            exit_code=$((exit_code + 1))
            break
        fi
    done || return $?

    if ${shmate_os_windows}; then
        set -o posix
    fi

    return ${exit_code}
}

#> >>>>> shmate_assert_tools [<required_tool> ...]
#>
#> Checks if all the <required_tools> are found on _PATH_. If not, logs message in _ERROR_ level and returns non-zero value.
#> See <<lib_shmate_assert:shmate_check_tools>> for silent version.
#>
shmate_assert_tools() {
    local required_tool=
    local exit_code=0

    if ${shmate_os_windows}; then
        set +o posix
    fi

    for required_tool in "$@"; do
        if ! [ -e "$(command -v "${required_tool}")" ]; then
            shmate_log_error "No \"${required_tool}\" command found. Make sure it is on PATH:
${PATH}"
            exit_code=$((exit_code + 1))
        fi
    done

    if ${shmate_os_windows}; then
        set -o posix
    fi

    return ${exit_code}
}

#> >>>>> shmate_assert [<message> ...]
#>
#> Assert successful execution (zero exit code) of the last executed command.
#> If non-zero exit code has been returned, <messages> are concatenated and logged in _ERROR_ level.
#> Returns the same exit code as the last executed command.
#>
#> [TIP]
#> ====
#> Within a function the _shmate_assert_ is best called followed by a conditional _return_.
#> [source,sh]
#> ----
#> shmate_audit mkdir -p "${dir}"
#> shmate_assert "Creating directory \"${dir}\"" || return $?
#> ----
#> ====
#>
shmate_assert() {
    _shmate_assert_with_level 'error' "$@"
}

#> >>>>> shmate_silent_assert [<message> ...]
#>
#> Same as <<lib_shmate_assert:shmate_assert>> but logs in _DEBUG_ level.
#>
shmate_silent_assert() {
    _shmate_assert_with_level 'debug' "$@"
}

#> >>>>> shmate_warning_assert [<message> ...]
#>
#> Same as <<lib_shmate_assert:shmate_assert>> but logs in _WARNING_ level.
#>
shmate_warning_assert() {
    _shmate_assert_with_level 'warning' "$@"
}

#> >>>>> shmate_pending_assert [<message> ...]
#>
#> Logs concatenated <messages> in _PENDING_ level.
#> Puts the logged message on stack, so it can be taken by <<lib_shmate_assert:shmate_loud_assert>> and <<lib_shmate_assert:shmate_fail_assert>>.
#> Must always be coupled with <<lib_shmate_assert:shmate_loud_assert>> or <<lib_shmate_assert:shmate_fail_assert>> to take logged message off stack.
#>
#> [TIP]
#> ====
#> Best used for long-running tasks.
#> [source,sh]
#> ----
#> shmate_pending_assert 'Downloading the whole Internet'
#> curl --fail '${internet_zip_url}'
#> shmate_loud_assert || return $?
#> ----
#> ====
#>
shmate_pending_assert() {
    _shmate_assert_message="$*"

    shmate_log_pending "${_shmate_assert_message}"
    _shmate_assert_message_stack="${_shmate_assert_message_stack}
${_shmate_assert_message}"

    return 0
}

#> >>>>> shmate_loud_assert [<exit_code>] [<message> ...]
#>
#> Similar to <<lib_shmate_assert:shmate_assert>>, but on successful execution of the last command logs concatenated messages in _SUCCESS_ level.
#>
#> If no <messages> are given, takes the message off stack (put there by <<lib_shmate_assert:shmate_pending_assert>>).
#> If <exit_code> is given, it overrides the returned exit code.
#>
shmate_loud_assert() {
    _shmate_ignore_sigpipe

    local status=$?
    local error_code=${status}
    if _shmate_is_error_code "$1"; then
        error_code=$1
        shift
    fi

    local message="$*"

    if [ -z "${message}" ]; then
        message="${_shmate_assert_message}"
        _shmate_assert_message_stack=$(shmate_input_run "${_shmate_assert_message_stack}" head -n -1)
        _shmate_assert_message=$(shmate_input_run "${_shmate_assert_message_stack}" tail -n 1)
    fi

    if [ ${status} -gt 0 ]; then
        shmate_log_error "[${error_code}]" "${message}"
        return ${error_code}
    else
        shmate_log_success "${message}"
    fi

    return 0
}

#> >>>>> shmate_fail_assert [<exit_code>] [<message> ...]
#>
#> If no <messages> are given behaves like <<lib_shmate_assert:shmate_loud_assert>>, otherwise behaves like <<lib_shmate_assert:shmate_assert>>.
#> If the last command failed, logs message in _FAILURE_ level and terminates the program.
#>
#> If <exit_code> is given, it overrides the returned exit code.
#>
shmate_fail_assert() {
    _shmate_ignore_sigpipe

    local status=$?
    local error_code=${status}
    if _shmate_is_error_code "$1"; then
        error_code=$1
        shift
    fi

    local message="$*"

    if [ -z "${message}" ]; then
        message="${_shmate_assert_message}"
        _shmate_assert_message_stack=$(shmate_input_run "${_shmate_assert_message_stack}" head -n -1)
        _shmate_assert_message=$(shmate_input_run "${_shmate_assert_message_stack}" tail -n 1)

        if [ ${status} -gt 0 ]; then
            if [ ${SHMATE_SUPPRESS_FAILURE_EXIT} -le 0 ]; then
                shmate_log_failure "[${error_code}]" "${message}"
            fi
            shmate_exit ${error_code}
        else
            shmate_log_success "${message}"
        fi
    elif [ ${status} -gt 0 ]; then
        if [ ${SHMATE_SUPPRESS_FAILURE_EXIT} -le 0 ]; then
            shmate_log_failure "[${error_code}]" "${message}"
        fi
        shmate_exit ${error_code}
    fi

    return 0
}

_shmate_colors
_shmate_create_log_file

_shmate_log_audit_myself "$0" "$@"

fi
