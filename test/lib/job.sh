#!/usr/bin/env bash

# shellcheck source=src/lib/shmate/job.sh
. "${SHMATE_SOURCE_DIR}/src/lib/shmate/job.sh"

_test_job_env() {
    test -z "${_SHMATE_PID}"
    shmate_assert "_SHMATE_PID must be empty, but is \"${_SHMATE_PID}\"" || return $?

    test -n "${_SHMATE_PID_FILE}"
    shmate_assert "_SHMATE_PID_FILE must not be empty" || return $?

    _shmate_get_pid
    local job_pid=${_SHMATE_PID}

    test ${job_pid} -ne ${parent_pid}
    shmate_assert "Parent PID ${parent_pid} and job PID ${job_pid} must not be equal" || return $?

    test -z "${_SHMATE_GUARDIAN_PID}"
    shmate_assert "_SHMATE_GUARDIAN_PID must be empty, but is \"${_SHMATE_GUARDIAN_PID}\"" || return $?

    test -n "${_SHMATE_JOB_NAME}"
    shmate_assert "_SHMATE_JOB_NAME must not be empty" || return $?

    test "${_SHMATE_JOB_NAME}" != "${parent_job_id}"
    shmate_assert "_SHMATE_JOB_NAME \"${_SHMATE_JOB_NAME}\" must not equal to parent job id \"${parent_job_id}\"" || return $?

    test -n "${_SHMATE_JOB_RUN_DIR}"
    shmate_assert "_SHMATE_JOB_RUN_DIR must not be empty" || return $?

    test "${_SHMATE_PID_FILE}" != "${parent_pidfile}"
    shmate_assert "_SHMATE_PID_FILE \"${_SHMATE_PID_FILE}\" must not equal to parent pidfile \"${parent_pidfile}\"" || return $?

    return 0
}

_test_unqualified_job() {
    _test_job_env || return $?

    shmate_log_info "Hello, I'm an unqualified job and my name is \"${_SHMATE_JOB_NAME}\""

    return 0
}

_test_qualified_job() {
    _test_job_env || return $?

    shmate_log_info "Hello, I'm a qualified job and my name is \"${_SHMATE_JOB_NAME}\""

    return 0
}

_test_unaware_job() {
    local shmate_env=
    shmate_env=$(env | shmate_filter_grep -E '^_*SHMATE_' | sort)
    shmate_assert 'Reading shMate environment' || return $?

    test -z "${shmate_env}"
    shmate_assert "shMate environment variables must be unset, but are:
${shmate_env}" || return $?

    _shmate_get_pid
    local job_pid=${_SHMATE_PID}

    test ${job_pid} -eq ${parent_pid}
    shmate_assert "Parent PID ${parent_pid} and job PID ${job_pid} must be equal" || return $?

    shmate_log_info "Hello, I'm a session job and I don't know my name"

    return 0
}

_test_guarded_job() {
    test -z "${_SHMATE_PID}"
    shmate_assert "_SHMATE_PID must be empty, but is \"${_SHMATE_PID}\"" || return $?

    test -n "${_SHMATE_PID_FILE}"
    shmate_assert "_SHMATE_PID_FILE must not be empty" || return $?

    _shmate_get_pid
    local job_pid=${_SHMATE_PID}

    test ${job_pid} -ne ${parent_pid}
    shmate_assert "Parent PID ${parent_pid} and job PID ${job_pid} must not be equal" || return $?

    test -n "${_SHMATE_GUARDIAN_PID}"
    shmate_assert "_SHMATE_GUARDIAN_PID must not be empty" || return $?

    test -n "${_SHMATE_JOB_NAME}"
    shmate_assert "_SHMATE_JOB_NAME must not be empty" || return $?

    test "${_SHMATE_JOB_NAME}" != "${parent_job_id}"
    shmate_assert "_SHMATE_JOB_NAME \"${_SHMATE_JOB_NAME}\" must not equal to parent job id \"${parent_job_id}\"" || return $?

    test -n "${_SHMATE_JOB_RUN_DIR}"
    shmate_assert "_SHMATE_JOB_RUN_DIR must not be empty" || return $?

    test "${_SHMATE_PID_FILE}" != "${parent_pidfile}"
    shmate_assert "_SHMATE_PID_FILE \"${_SHMATE_PID_FILE}\" must not equal to parent pidfile \"${parent_pidfile}\"" || return $?

    shmate_log_info "Hello, I'm a guarded job and my name is \"${_SHMATE_JOB_NAME}\""

    return 0
}

test_unqualified_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_job '' _test_unqualified_job "$@"
    shmate_wait_job
}

test_qualified_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_job 'Groupie' _test_qualified_job "$@"
    shmate_wait_job
}

test_unqualified_muted_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_muted_job '' _test_unqualified_job "$@"
    shmate_wait_job
}

test_qualified_muted_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_muted_job 'Groupie' _test_qualified_job "$@"
    shmate_wait_job
}

test_foreground_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_foreground_job '' _test_unqualified_job "$@"
    shmate_wait_job
}

test_unaware_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_unaware_job '' _test_unaware_job "$@"
    shmate_wait_job
}

test_attached_job() {
    shmate_run_job '' "${SHMATE_TEST_DIR}/${SHMATE_TEST_SUITE}/attached-job" "$@"
    shmate_wait_job
}

test_detached_job() {
    shmate_run_detached_job "${SHMATE_TEST_DIR}/${SHMATE_TEST_SUITE}/detached-job" "$@"
    shmate_wait_job
}

test_guarded_job() {
    local parent_pid=$$
    local parent_job_id=${_SHMATE_JOB_NAME}
    local parent_pidfile="${_SHMATE_PID_FILE}"

    shmate_run_guardian _test_guarded_job "$@"
}

test_attached_guarded_job() {
    shmate_run_guardian "${SHMATE_TEST_DIR}/${SHMATE_TEST_SUITE}/guarded-job" "$@"
}
