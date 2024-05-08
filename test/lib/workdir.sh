#!/usr/bin/env bash

# shellcheck source=src/lib/shmate/workdir.sh
. "${SHMATE_SOURCE_DIR}/src/lib/shmate/workdir.sh"

_test_path_in_work_dir() {
    local path="$1"

    local is_in_work_dir=false
    case "${path}" in
        "${shmate_work_dir}/"*)
            is_in_work_dir=true
            ;;
    esac

    ${is_in_work_dir}
    shmate_assert "Path \"${path}\" must be within working directory \"${shmate_work_dir}\"" || return $?

    return 0
}

_test_directory() {
    local path="$1"
    local found_path=

    test -n "${path}"
    shmate_assert 'Path must not be empty' || return $?

    test -d "${path}"
    shmate_assert "Path \"${path}\" must be a directory" || return $?

    _test_path_in_work_dir "${path}" || return $?

    found_path=$(shmate_audit find "${path}" -maxdepth 0 -perm -u=rwx) || return $?
    test "${found_path}" = "${path}"
    shmate_assert "Path \"${path}\" must have all user permissions" || return $?

    found_path=$(shmate_audit find "${path}" -maxdepth 0 -empty) || return $?
    test "${found_path}" = "${path}"
    shmate_assert "Directory \"${path}\" must be empty" || return $?

    return 0
}

_test_file() {
    local path="$1"
    local found_path=

    test -n "${path}"
    shmate_assert 'Path must not be empty' || return $?

    test -f "${path}"
    shmate_assert "Path \"${path}\" must be a file" || return $?

    _test_path_in_work_dir "${path}" || return $?

    found_path=$(shmate_audit find "${path}" -maxdepth 0 -perm -u=rw) || return $?
    test "${found_path}" = "${path}"
    shmate_assert "Path \"${path}\" must have read/write user permissions" || return $?

    test ! -s "${path}"
    shmate_assert "File \"${path}\" must be empty" || return $?

    return 0
}

_test_fifo() {
    local path="$1"
    local found_path=

    test -n "${path}"
    shmate_assert 'Path must not be empty' || return $?

    found_path=$(shmate_audit find "${path}" -maxdepth 0 -type p) || return $?
    test "${found_path}" = "${path}"
    shmate_assert "Path \"${path}\" must be a fifo" || return $?

    _test_path_in_work_dir "${path}" || return $?

    found_path=$(shmate_audit find "${path}" -maxdepth 0 -perm -u=rw) || return $?
    test "${found_path}" = "${path}"
    shmate_assert "Path \"${path}\" must have read/write user permissions" || return $?

    return 0
}

test_shmate_work_dir() {
    local found_dir=

    test -n "${shmate_work_dir}"
    shmate_assert "\"shmate_work_dir\" global variable must not be empty" || return $?

    test -d "${shmate_work_dir}"
    shmate_assert "Path \"${shmate_work_dir}\" must be a directory" || return $?

    found_dir=$(shmate_audit find "${shmate_work_dir}" -maxdepth 0 ! -perm +g=rwx) || return $?
    test "${found_dir}" = "${shmate_work_dir}"
    shmate_assert "Working directory \"${shmate_work_dir}\" must not have any group permissions" || return $?

    found_dir=$(shmate_audit find "${shmate_work_dir}" -maxdepth 0 ! -perm +o=rwx) || return $?
    test "${found_dir}" = "${shmate_work_dir}"
    shmate_assert "Working directory \"${shmate_work_dir}\" must not have any other user permissions" || return $?

    found_dir=$(shmate_audit find "${shmate_work_dir}" -maxdepth 0 -perm -u=rwx) || return $?
    test "${found_dir}" = "${shmate_work_dir}"
    shmate_assert "Working directory \"${shmate_work_dir}\" must have all user permissions" || return $?

    return 0
}

test_shmate_create_tmp_dir() {
    local name='foobar'
    local tmp_dir_1= tmp_dir_2=

    tmp_dir_1=$(shmate_create_tmp_dir "${name}")
    shmate_assert "Creating first temporary directory \"${name}\"" || return $?

    _test_directory "${tmp_dir_1}" || return $?

    tmp_dir_2=$(shmate_create_tmp_dir "${name}")
    shmate_assert "Creating second temporary directory \"${name}\"" || return $?

    _test_directory "${tmp_dir_2}" || return $?

    test "${tmp_dir_1}" != "${tmp_dir_2}"
    shmate_assert "First directory path \"${tmp_dir_1}\" must not equal to second directory path \"${tmp_dir_2}\"" || return $?

    return 0
}

test_shmate_create_tmp_file() {
    local name='foobar'
    local tmp_file_1= tmp_file_2=

    tmp_file_1=$(shmate_create_tmp_file "${name}")
    shmate_assert "Creating first temporary file \"${name}\"" || return $?

    _test_file "${tmp_file_1}" || return $?

    tmp_file_2=$(shmate_create_tmp_file "${name}")
    shmate_assert "Creating second temporary file \"${name}\"" || return $?

    _test_file "${tmp_file_2}" || return $?

    test "${tmp_file_1}" != "${tmp_file_2}"
    shmate_assert "First file path \"${tmp_file_1}\" must not equal to second file path \"${tmp_file_2}\"" || return $?

    return 0
}

test_shmate_create_tmp_fifo() {
    local name='foobar'
    local tmp_fifo_1= tmp_fifo_2=

    tmp_fifo_1=$(shmate_create_tmp_fifo "${name}")
    shmate_assert "Creating first temporary fifo \"${name}\"" || return $?

    _test_fifo "${tmp_fifo_1}" || return $?

    tmp_fifo_2=$(shmate_create_tmp_fifo "${name}")
    shmate_assert "Creating second temporary fifo \"${name}\"" || return $?

    _test_fifo "${tmp_fifo_2}" || return $?

    test "${tmp_fifo_1}" != "${tmp_fifo_2}"
    shmate_assert "First fifo path \"${tmp_fifo_1}\" must not equal to second fifo path \"${tmp_fifo_2}\"" || return $?

    return 0
}
