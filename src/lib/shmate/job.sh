#!/usr/bin/env bash

# shellcheck disable=SC2039

if [ -z "${_SHMATE_INCLUDE_LIB_JOB}" ]; then
    readonly _SHMATE_INCLUDE_LIB_JOB='included'

#> >>> job.sh
#>
#> Library adding temporary working directory.
#>
#> >>>> Dependencies
#> * <<lib_shmate_workdir>>
#>

# shellcheck source=src/lib/shmate/workdir.sh
. "${SHMATE_LIB_DIR}/workdir.sh"

shmate_assert_tools find ps || shmate_fail $?

if ${shmate_os_windows}; then
    shmate_assert_tools taskkill || shmate_fail $?
else
    shmate_assert_tools pgrep xargs || shmate_fail $?
fi

#> >>>> Environment
#>
#> >>>>> SHMATE_TERMINATION_TIMEOUT
#>
#> Wait at least this number of seconds for graceful termination before **KILL**ing descendant processes. Defaults to 10 seconds.
#>
SHMATE_TERMINATION_TIMEOUT=${SHMATE_TERMINATION_TIMEOUT:-10}

#> >>>> Internal symbols
#>
#> .Variables
#> [%collapsible]
#> ====
#> * _SHMATE_JOB_NAME
#> * _SHMATE_JOB_RUN_DIR
_SHMATE_JOB_RUN_DIR=
#> * _shmate_job_ignored_signals
readonly _shmate_job_ignored_signals='INT'
#> ====
#>

#> .Functions
#> [%collapsible]
#> ====
#> * _shmate_job_prepare
_shmate_job_prepare() {
    local job_type="$1"
    local job_group_name="$2"
    shift 2

    local job_group_path=
    if [ -n "${job_group_name}" ]; then
        job_group_path="/${job_group_name}"
    fi

    _shmate_new_job_run_dir="${shmate_work_dir}/.run/job${job_group_path}"
    if ! [ -d "${_shmate_new_job_run_dir}" ]; then
        shmate_audit mkdir -p "${_shmate_new_job_run_dir}" || return $?
    fi

    _shmate_new_job_run_dir="$(env TMPDIR="${_shmate_new_job_run_dir}" mktemp -dt ".XXXXX")" || return $?

    _shmate_new_job_pidfile="${_shmate_new_job_run_dir}/.pid"
    shmate_audit touch "${_shmate_new_job_pidfile}"
    shmate_assert "Creating job pidfile \"${_shmate_new_job_pidfile}\"" || return $?

    shmate_log_debug "Created job pidfile \"${_shmate_new_job_pidfile}\""

    _shmate_new_job_id="${_shmate_new_job_run_dir##*/.}"
    if [ -n "${job_group_name}" ]; then
        _shmate_new_job_id="${job_group_name}.${_shmate_new_job_id}"
    fi

    return 0
}

#> * _shmate_job_confirm
_shmate_job_confirm() {
    local new_job_status=$?
    local new_job_pid=$!

    local job_type="$1"
    local job_group_name="$2"
    shift 2

    local job_name="$1"

    if [ ${new_job_status} -ne 0 ]; then
        shmate_log_error "[${new_job_status}] Running ${job_type} job \"${job_name}\""
        return ${new_job_status}
    fi

    local job_group_path=
    if [ -n "${job_group_name}" ]; then
        job_group_path="/${job_group_name}"
    fi

    local run_dir="${shmate_work_dir}/.run/pid${job_group_path}"
    if ! [ -d "${run_dir}" ]; then
        shmate_audit mkdir -p "${run_dir}" || return $?
    fi

    local job_pidfile="${run_dir}/${new_job_pid}.pid"
    shmate_log_audit_begin && \
        shmate_log_audit_command echo ${new_job_pid} && \
        shmate_log_audit_operator '>' && \
        shmate_log_audit_file "${job_pidfile}" && \
        shmate_log_audit_end
    echo ${new_job_pid} > "${job_pidfile}"
    shmate_assert "Storing pid ${new_job_pid} in pidfile \"${job_pidfile}\"" || return $?

    if [ -n "${_shmate_new_job_pidfile}" ]; then
        shmate_log_audit_begin && \
            shmate_log_audit_command echo ${new_job_pid} && \
            shmate_log_audit_operator '>' && \
            shmate_log_audit_file "${_shmate_new_job_pidfile}" && \
            shmate_log_audit_end
        echo ${new_job_pid} > "${_shmate_new_job_pidfile}"
        shmate_assert "Storing pid ${new_job_pid} in pidfile \"${_shmate_new_job_pidfile}\"" || return $?

        shmate_log_debug "Running ${job_type} job \"${job_name}\" with PID ${new_job_pid} and pidfile \"${_shmate_new_job_pidfile}\""
    else
        shmate_log_debug "Running ${job_type} job \"${job_name}\" with PID ${new_job_pid} without pidfile"
    fi

    return 0
}

#> * _shmate_job_run
_shmate_job_run() {
    export _SHMATE_GUARDIAN_PID _SHMATE_PID_FILE="${_shmate_new_job_pidfile}" _SHMATE_JOB_NAME="${_shmate_new_job_id}" _SHMATE_JOB_RUN_DIR="${_shmate_new_job_run_dir}"
    unset _SHMATE_PID

    trap '_shmate_cleanup_job $?' EXIT
    _shmate_ignore_signal ${_shmate_job_ignored_signals}

    if [ $# -gt 0 ]; then
        "$@" 0<&0
        exit $?
    fi

    return 0
}

#> * _shmate_job_unset_env
_shmate_job_unset_env() {
    unset _SHMATE_GUARDIAN_PID _SHMATE_JOB_NAME _SHMATE_JOB_RUN_DIR _SHMATE_PID_FILE _SHMATE_PID

    if [ $# -gt 0 ]; then
        "$@" 0<&0
        exit $?
    fi

    return 0
}

#> * _shmate_lib_job_cleanup
_shmate_lib_job_cleanup() {
    test -z "${_SHMATE_JOB_RUN_DIR}"
    shmate_assert 'Ordinary cleanup handler must not be called by job process'

    if [ -n "${_SHMATE_GUARDIAN_PID}" ]; then
        if [ -z "${_SHMATE_JOB_NAME}" ]; then
            local job_pidlist=$(shmate_collect_job_group_pids)

            if ! ${shmate_os_windows}; then
                local descendants_pidlist=$(shmate_collect_descendant_pids $$)
                shmate_kill_job TERM ${job_pidlist} ${descendants_pidlist}
            else
                shmate_kill_job TERM ${job_pidlist}
            fi
        fi
    else
        local job_pidlist=$(shmate_collect_job_group_pids)
        shmate_kill_job TERM ${job_pidlist}
    fi

    _shmate_lib_workdir_cleanup "$@"
}

#> * _shmate_lib_job_cleanup_job
_shmate_lib_job_cleanup_job() {
    test -n "${_SHMATE_JOB_RUN_DIR}"
    shmate_assert 'Job cleanup handler must not be called by ordinary process'

    if [ -n "${_SHMATE_JOB_RUN_DIR}" -a -d "${_SHMATE_JOB_RUN_DIR}" ]; then
        shmate_log_audit_begin && \
            shmate_log_audit_command echo "$1" && \
            shmate_log_audit_operator '>' && \
            shmate_log_audit_file "${_SHMATE_JOB_RUN_DIR}/.exit-code" && \
            shmate_log_audit_end
        echo "$1" > "${_SHMATE_JOB_RUN_DIR}/.exit-code"
    fi

    shmate_cleanup_job "$@"
    shmate_log_audit_begin && shmate_log_audit_text "Job \"${_SHMATE_JOB_NAME}\" exiting with code $1" && shmate_log_audit_end
}

#> * _shmate_lib_job_on_exit
_shmate_lib_job_on_exit() {
    _shmate_lib_workdir_on_exit "$@"
}

#> * _shmate_lib_job_on_terminate
_shmate_lib_job_on_terminate() {
    _shmate_lib_workdir_on_terminate "$@"
}

#> * _shmate_cleanup_job
_shmate_cleanup_job() {
    _shmate_lib_job_cleanup_job "$@"
}

#> ====
#>

_shmate_cleanup() {
    _shmate_lib_job_cleanup "$@"
}

_shmate_on_exit() {
    _shmate_lib_job_on_exit "$@"
}

_shmate_on_terminate() {
    _shmate_lib_job_on_terminate "$@"
}

#> >>>> Functions
#>
#> >>>>> shmate_cleanup_job <exit_code>
#>
shmate_cleanup_job() {
:
}

#> >>>>> shmate_collect_descendant_pids [<pid> ...]
#>
shmate_collect_descendant_pids() {
    if [ $# -le 0 ]; then
        return 0
    fi

    local child_pidlist=
    if ! ${shmate_os_windows}; then
        local parent_pidlist_csv=
        local pid=
        for pid in "$@"; do
            parent_pidlist_csv="${parent_pidlist_csv},${pid}"
        done
        parent_pidlist_csv="${parent_pidlist_csv#,}"

        child_pidlist=$(shmate_audit pgrep -P "${parent_pidlist_csv}")
        shmate_silent_assert "Collecting children of PIDs $*"
    fi

    if [ -n "${child_pidlist}" ]; then
        shmate_collect_descendant_pids ${child_pidlist} || return ?
        echo ${child_pidlist}
    fi

    return 0
}

#> >>>>> shmate_collect_job_group_pids [<job_group_name> ...]
#>
shmate_collect_job_group_pids() {
    if [ $# -eq 0 ]; then
        set -- ''
    fi

    local job_group_name=
    local run_dir=
    local parent_pidlist=
    local child_pidlist

    for job_group_name in "$@"; do
        run_dir="${shmate_work_dir}/.run/pid/${job_group_name}"
        if [ -n "${shmate_work_dir}" -a -d "${run_dir}" ]; then
            parent_pidlist=`find -L "${run_dir}" -mindepth 1 -type f -name '*.pid' | while read -r pid_file; do
                cat "${pid_file}"
                shmate_silent_assert "Reading PID file \"${pid_file}\"" || continue
            done`
            shmate_assert 'Collecting jobs' || continue

            shmate_collect_descendant_pids ${parent_pidlist} || return $?
            echo ${parent_pidlist}
        fi
    done
}

#> >>>>> shmate_kill_job <signal_name> [<pid> ...]
#>
shmate_kill_job() {
    local signal_name="$1"
    shift

    if [ $# -le 0 ]; then
        shmate_log_debug 'No processes exterminated because of empty PID list'
        return 0
    fi

    shmate_log_debug "Sending ${signal_name} to PIDs $*"

    kill -s "${signal_name}" "$@" > /dev/null 2>&1
    shmate_silent_assert "Error sending ${signal_name} to PIDs $*"

    sleep 1

    local counter=${SHMATE_TERMINATION_TIMEOUT}
    while [ ${counter} -gt 0 ] && shmate_audit ps -p "$@" > /dev/null 2>&1; do
        sleep 1
        counter=$((counter - 1))
    done || return $?

    if [ ${counter} -le 0 ]; then
        if ${shmate_os_windows}; then
            local pid=
            local winpid=
            for pid in "$@"; do
                winpid=$(ps -l -p ${pid} | tail -n +2 | tr -s '[:space:]' '\t' | cut -f 5)
                if [ -n "${winpid}" ]; then
                    shmate_log_debug "Terminating job with PID ${pid} (WINPID ${winpid}) and its children"
                    shmate_audit taskkill /T /PID ${winpid}
                    if [ $? -ne 0 -o $? -ne 128 ]; then
                        shmate_log_debug "Killing job with PID ${pid} (WINPID ${winpid}) and its children"
                        shmate_audit taskkill /F /T /PID ${winpid}
                    fi
                else
                    shmate_log_debug "Job with PID ${pid} seems to have already been terminated"
                fi
            done
        else
            shmate_log_debug "Sending KILL to PIDs $@"

            kill -s KILL "$@" > /dev/null 2>&1
            shmate_silent_assert "Sending KILL to PIDs $@"

            shmate_log_debug "Killed PIDs $@"
        fi
    else
        shmate_log_debug "Terminated PIDs $@ with ${signal_name}"
    fi

    return 0
}

#> >>>>> shmate_kill_job_group <signal_name> [<job_group_name> ...]
#>
shmate_kill_job_group() {
    local signal_name="$1"
    shift

    local mindepth=1
    if [ $# -le 0 ]; then
        set -- ''
        mindepth=2 # Kill only qualified jobs
    fi

    local job_group_name=
    local run_dir=
    local parent_pidlist=
    local child_pidlist=
    local job_group_descriptor=

    for job_group_name in "$@"; do
        run_dir="${shmate_work_dir}/.run/pid/${job_group_name}"
        if [ -n "${shmate_work_dir}" -a -d "${run_dir}" ]; then
            parent_pidlist=`find -L "${run_dir}" -mindepth ${mindepth} -type f -name '*.pid' | while read -r pid_file; do
                cat "${pid_file}"
                shmate_silent_assert "Reading PID file \"${pid_file}\"" || continue

                shmate_audit rm -f "${pid_file}"
                shmate_silent_assert "Removing PID file \"${pid_file}\""
            done`
            shmate_assert 'Collecting jobs' || continue

            child_pidlist=$(shmate_collect_descendant_pids ${parent_pidlist})
            shmate_assert 'Collecting descendants' || continue

            if [ -n "${job_group_name}" ]; then
                job_group_descriptor="job group \"${job_group_name}\""
            else
                job_group_descriptor='all jobs'
            fi
            shmate_kill_job "${signal_name}" ${child_pidlist} ${parent_pidlist}
            shmate_assert "Terminating ${job_group_descriptor} with \"${signal_name}\"" || continue
        fi
    done
}

# TODO: Usefulness of this function is questionable as is its name and signature.

##> >>>>> shmate_annihilate_pids <parent_signal_name> <child_signal_name>
##>
#shmate_annihilate_pids() {
    #local parent_signal="$1"
    #local child_signal="$2"
    #shift 2

    #if [ -z "${parent_signal}" ]; then
        #parent_signal='TERM'
    #fi

    #if [ -z "${child_signal}" ]; then
        #child_signal="${parent_signal}"
    #fi

    #local parent_pidlist=
    #parent_pidlist=$(xargs)
    #shmate_assert 'Collecting parent PIDs' || return $?

    #if [ -z "${parent_pidlist}" ]; then
        #shmate_log_debug 'No processes annihilated because of empty PID list'
        #return 0
    #fi

    #local child_pidlist=
    #if ! ${shmate_os_windows}; then
        #local parent_pidlist_csv=
        #parent_pidlist_csv=$(echo -n "${parent_pidlist}" | tr '[:space:]' ',')
        #shmate_assert 'Collecting parent PIDs as comma separated values' || return $?

        #child_pidlist=$(shmate_audit pgrep -P "${parent_pidlist_csv}")
        #shmate_silent_assert "Collecting children of PIDs ${parent_pidlist}"
    #fi

    #shmate_kill_job "${parent_signal}" ${parent_pidlist} || return $?

    #if [ -n "${child_pidlist}" ]; then
        #child_pidlist=$(shmate_collect_descendant_pids ${child_pidlist}) || return $?
        #shmate_kill_job "${child_signal}" ${child_pidlist} || return $?
    #fi

    #return 0
#}

#> >>>>> shmate_run_qualified_job <job_group_name> [<command> [<command_arg> ...]]
#>
shmate_run_qualified_job() {
    local job_group_name="$1"
    shift

    local job_type='unqualified'
    if [ -n "${job_group_name}" ]; then
        job_type='qualified'
    fi

    _shmate_job_prepare "${job_type}" "${job_group_name}" "$@" || return $?
    _shmate_job_run "$@" 1>&2 0<&0 &
    _shmate_job_confirm "${job_type}" "${job_group_name}" "$@" || return $?

    return 0
}

#> >>>>> shmate_run_job [<command> [<command_arg> ...]]
#>
shmate_run_job() {
    shmate_run_qualified_job '' "$@"
}

#> >>>>> shmate_run_qualified_muted_job <job_group_name> [<command> [<command_arg> ...]]
#>
shmate_run_qualified_muted_job() {
    local job_group_name="$1"
    shift

    local job_type='unqualified muted'
    if [ -n "${job_group_name}" ]; then
        job_type='qualified muted'
    fi

    _shmate_job_prepare "${job_type}" "${job_group_name}" "$@" || return $?
    _shmate_job_run "$@" > /dev/null 2>&1 0<&0 &
    _shmate_job_confirm "${job_type}" "${job_group_name}" "$@" || return $?

    return 0
}

#> >>>>> shmate_run_muted_job [<command> [<command_arg> ...]]
#>
shmate_run_muted_job() {
    shmate_run_qualified_muted_job '' "$@"
}

#> >>>>> shmate_run_foreground_job [<command> [<command_arg> ...]]
#>
shmate_run_foreground_job() {
    local job_type='foreground'

    _shmate_job_prepare "${job_type}" '' "$@" || return $?
    _shmate_job_run "$@" 0<&0 &
    _shmate_job_confirm "${job_type}" '' "$@" || return $?

    return 0
}

#> >>>>> shmate_run_session_job [<command> [<command_arg> ...]]
#>
shmate_run_session_job() {
    local job_type='session'

    _shmate_job_prepare "${job_type}" '' "$@" || return $?
    _shmate_job_unset_env "$@" 1>&2 0<&0 &
    _shmate_job_confirm "${job_type}" '' "$@" || return $?

    return 0
}

#> >>>>> shmate_run_detached_job [<command> [<command_arg> ...]]
#>
if shmate_check_tools setsid; then
    shmate_run_detached_job() {
        _shmate_job_unset_env setsid "$@" > /dev/null 2>&1 0<&0 &
        shmate_log_audit_begin && shmate_log_audit_text "Running detached job \"$1\" with PID $!" && shmate_log_audit_end
    }
fi

#> >>>>> shmate_write_job <fifo_path> [<command> [<command_arg> ...]]
#>
shmate_write_job() {
    local path="$1"
    shift

    local run_dir="${shmate_work_dir}/.run/pid"
    shmate_audit mkdir -p "${run_dir}"

    if [ $# -gt 0 ]; then
        shmate_log_audit_begin && \
            shmate_log_audit_command "$@" && \
            shmate_log_audit_operator '>' && \
            shmate_log_audit_file "${path}" && \
            shmate_log_audit_end
        "$@" > "${path}" 0<&0 &
    else
        shmate_log_audit_begin && \
            shmate_log_audit_command cat && \
            shmate_log_audit_operator '>' && \
            shmate_log_audit_file "${path}" && \
            shmate_log_audit_end
        cat > "${path}" 0<&0 &
    fi
    shmate_assert "Running asynchronous write to file \"${path}\"" || return $?

    shmate_log_debug "Running asynchronous write to file \"${path}\" - job \"$1\" with PID $! and pidfile \"${run_dir}/$!.pid\""

    shmate_log_audit_begin && \
        shmate_log_audit_command echo "$!" && \
        shmate_log_audit_operator '>' && \
        shmate_log_audit_file "${run_dir}/$!.pid" && \
        shmate_log_audit_end
    echo "$!" > "${run_dir}/$!.pid"
    shmate_assert "Creating pidfile \"${run_dir}/$!.pid\"" || return $?

    return 0
}

#> >>>>> shmate_read_job <fifo_path> [<command> [<command_arg> ...]]
#>
shmate_read_job() {
    local path="$1"
    shift

    local run_dir="${shmate_work_dir}/.run/pid"
    shmate_audit mkdir -p "${run_dir}"

    if [ $# -gt 0 ]; then
        shmate_log_audit_begin && \
            shmate_log_audit_command "$@" && \
            shmate_log_audit_operator '<' && \
            shmate_log_audit_file "${path}" && \
            shmate_log_audit_end
        "$@" < "${path}" &
    else
        shmate_audit cat "${path}" &
    fi
    shmate_assert "Running asynchronous read from file \"${path}\"" || return $?

    shmate_log_debug "Running asynchronous read from file \"${path}\" - job \"$1\" with PID $! and pidfile \"${run_dir}/$!.pid\""

    shmate_log_audit_begin && \
        shmate_log_audit_command echo "$!" && \
        shmate_log_audit_operator '>' && \
        shmate_log_audit_file "${run_dir}/$!.pid" && \
        shmate_log_audit_end
    echo "$!" > "${run_dir}/$!.pid"
    shmate_assert "Creating pidfile \"${run_dir}/$!.pid\"" || return $?

    return 0
}

#> >>>>> shmate_read_stderr_job <fifo_path> [<command> [<command_arg> ...]]
#>
shmate_read_stderr_job() {
    local path="$1"
    shift

    local run_dir="${shmate_work_dir}/.run/pid"
    shmate_audit mkdir -p "${run_dir}"

    if [ $# -gt 0 ]; then
        shmate_log_audit_begin && \
            shmate_log_audit_command "$@" && \
            shmate_log_audit_operator '<' && \
            shmate_log_audit_file "${path}" && \
            shmate_log_audit_end
        "$@" < "${path}" 1>&2 &
    else
        shmate_audit cat "${path}" 1>&2 &
    fi
    shmate_assert "Running asynchronous read from log \"${path}\"" || return $?

    shmate_log_debug "Running asynchronous read from log \"${path}\" - job \"$1\" with PID $! and pidfile \"${run_dir}/$!.pid\""

    shmate_log_audit_begin && \
        shmate_log_audit_command echo "$!" && \
        shmate_log_audit_operator '>' && \
        shmate_log_audit_file "${run_dir}/$!.pid" && \
        shmate_log_audit_end
    echo "$!" > "${run_dir}/$!.pid"
    shmate_assert "Creating pidfile \"${run_dir}/$!.pid\"" || return $?

    return 0
}

#> >>>>> shmate_wait_job [<pid>]
#>
shmate_wait_job() {
    local pid=$1 # Optional
    local exit_code=

    if [ -z "${pid}" ]; then
        pid=$!
    fi

    shmate_log_debug "Waiting for PID ${pid}"

    while true; do
        wait ${pid}
        exit_code=$?
        if ${_shmate_is_termination_ignored}; then
            _shmate_is_termination_ignored=false
            continue
        fi
        shmate_log_debug "Waiting for PID ${pid} finished with status ${exit_code}"
        break
    done

    local run_dir="${shmate_work_dir}/.run/pid"
    if [ -n "${shmate_work_dir}" -a -d "${run_dir}" ]; then
        find -L "${run_dir}" -mindepth 1 -type f -name "${pid}.pid" | while read -r pid_file; do
            shmate_audit rm "${pid_file}" && shmate_log_debug "Removed pidfile \"${pid_file}\"" || shmate_log_warning "Cannot remove pidfile \"${pid_file}\""
        done
    fi

    return ${exit_code}
}

#> >>>>> shmate_wait_job_group [<job_group_name> ...]
#>
shmate_wait_job_group() {
    local mindepth=1
    if [ $# -le 0 ]; then
        set -- ''
        mindepth=2 # Wait only for qualified jobs
    fi

    local job_group_name=
    local run_dir=
    local pids=
    local exit_code=0

    if [ -n "${shmate_work_dir}" ]; then
        for job_group_name in "$@"; do
            run_dir="${shmate_work_dir}/.run/pid/${job_group_name}"
            if [ -d "${run_dir}" ]; then
                pids="${pids} $(find -L "${run_dir}" -mindepth ${mindepth} -type f -name '*.pid' -exec cat {} \; | xargs)"
                shmate_assert 'Reading job PIDs' || return $?
            fi
        done
        pids="${pids# }"
    fi

    shmate_log_debug "Waiting for multiple PIDs${pids}"

    if [ -n "${pids}" ]; then
        while true; do
            wait ${pids}
            exit_code=$?
            if ${_shmate_is_termination_ignored}; then
                _shmate_is_termination_ignored=false
                continue
            fi
            shmate_log_debug "Waiting for PIDs${pids} finished with status ${exit_code}"
            break
        done

        if [ -n "${shmate_work_dir}" ]; then
            for job_group_name in "$@"; do
                run_dir="${shmate_work_dir}/.run/pid/${job_group_name}"
                if [ -d "${run_dir}" ]; then
                    find -L "${run_dir}" -mindepth ${mindepth} -type f -name '*.pid' -delete
                    shmate_warning_assert "Cannot remove pidfiles from directory \"${run_dir}\""
                fi
            done
        fi

        if [ ${exit_code} -eq 0 -a -n "${shmate_work_dir}" -a -d "${shmate_work_dir}/.run/job" ]; then
            for job_group_name in "$@"; do
                run_dir="${shmate_work_dir}/.run/job/${job_group_name}"
                if [ -d "${run_dir}" ]; then
                    local job_exit_code=
                    job_exit_code=`find -L "${run_dir}" -mindepth ${mindepth} -type f -name '.exit-code' -exec cat {} \; | sort -un | tail -n 1`
                    shmate_warning_assert "Cannot retrieve exit codes from directory \"${run_dir}\""

                    if [ -n "${job_exit_code}" ]; then
                        exit_code=${job_exit_code}
                        break
                    fi
                fi
            done
        fi
    fi

    return ${exit_code}
}

#> >>>>> shmate_run_guardian <command> [<command_arg> ...]
#>
#> Runs <command> with <command_args> as guarded job running in foreground. If calling process is not already
#> a job it becomes the guardian. The guardian is responsible for immediate graceful termination of all descendant
#> processes upon exit including termination caused by signal.
#>
#> Useful to run long-term tasks. Does not work in _Windows_ falling back to just running the <command>.
#>
shmate_run_guardian() {
    if ! ${shmate_os_windows} && [ -z "${_SHMATE_JOB_NAME}" ]; then
        _shmate_get_pid
        _SHMATE_GUARDIAN_PID=${_SHMATE_PID}
        shmate_run_foreground_job "$@" || return $?
        shmate_wait_job
    else
        "$@"
    fi

    return $?
}

#> >>>>> shmate_nap <seconds>
#>
shmate_nap() {
    if [ $# -le 0 ]; then
        return 0
    fi

    local seconds=$1
    if [ ${seconds} -le 0 ]; then
        return 0
    fi

    shmate_log_audit sleep ${seconds}
    sleep ${seconds} > /dev/null 2>&1 0<&0 &
    shmate_wait_job
    shmate_silent_assert 'Sleep interrupted' || return $?

    return 0
}

fi
