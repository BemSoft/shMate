#!/usr/bin/env bash

# shellcheck source=src/lib/shmate/dependency.sh
. "${SHMATE_SOURCE_DIR}/src/lib/shmate/dependency.sh"

readonly test_mvn_env_file="${shmate_work_dir}/mvn.env"

readonly test_artifact_group_id='io.netty'
readonly test_artifact_artifact_id='netty-transport-native-kqueue'
readonly test_artifact_version='4.1.107.Final'
readonly test_artifact_packaging='jar'
readonly test_artifact_descriptor="${test_artifact_group_id}:${test_artifact_artifact_id}:${test_artifact_version}@${test_artifact_packaging}"
readonly test_artifact_file_name="${test_artifact_artifact_id}-${test_artifact_version}.${test_artifact_packaging}"
readonly test_artifact_repo_path="io/netty/${test_artifact_artifact_id}/${test_artifact_version}/${test_artifact_file_name}"
readonly test_artifact_module_path='transport-native-kqueue'
readonly test_artifact_build_path="target/${test_artifact_file_name}"
readonly test_artifact_deploy_opts="-Dfile='${test_artifact_build_path}' -DgroupId='${test_artifact_group_id}' -DartifactId='${test_artifact_artifact_id}' -Dversion='${test_artifact_version}' -Dpackaging='${test_artifact_packaging}'"

readonly test_native_artifact_classifier='osx-x86_64'
readonly test_native_artifact_descriptor="${test_artifact_group_id}:${test_artifact_artifact_id}:${test_artifact_version}:${test_native_artifact_classifier}@${test_artifact_packaging}"
readonly test_native_artifact_file_name="${test_artifact_artifact_id}-${test_artifact_version}-${test_native_artifact_classifier}.${test_artifact_packaging}"
readonly test_native_artifact_repo_path="io/netty/${test_artifact_artifact_id}/${test_artifact_version}/${test_native_artifact_file_name}"
readonly test_native_artifact_lib_name='libnetty_transport_native_kqueue_x86_64.jnilib'
readonly test_native_artifact_build_path="target/${test_native_artifact_file_name}"
readonly test_native_artifact_deploy_opts="-Dfile='${test_native_artifact_build_path}' -DgroupId='${test_artifact_group_id}' -DartifactId='${test_artifact_artifact_id}' -Dversion='${test_artifact_version}' -Dpackaging='${test_artifact_packaging}' -Dclassifier='${test_native_artifact_classifier}'"

_test_shmate_dep_group_id() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local group_id=
    group_id=$(shmate_dep_group_id "${artifact_descriptor}")
    shmate_assert "Extracting group id from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${group_id}" = "${expected_value}"
    shmate_assert "Group id of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${group_id}\"" || return $?

    shmate_log_debug "Group id of \"${artifact_descriptor}\" is \"${group_id}\""

    return 0
}

_test_shmate_dep_artifact_id() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local artifact_id=
    artifact_id=$(shmate_dep_artifact_id "${artifact_descriptor}")
    shmate_assert "Extracting artifact id from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${artifact_id}" = "${expected_value}"
    shmate_assert "Artifact id of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${artifact_id}\"" || return $?

    shmate_log_debug "Artifact id of \"${artifact_descriptor}\" is \"${artifact_id}\""

    return 0
}

_test_shmate_dep_version() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local version=
    version=$(shmate_dep_version "${artifact_descriptor}")
    shmate_assert "Extracting version from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${version}" = "${expected_value}"
    shmate_assert "Version of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${version}\"" || return $?

    shmate_log_debug "Version of \"${artifact_descriptor}\" is \"${version}\""

    return 0
}

_test_shmate_dep_classifier() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local classifier=
    classifier=$(shmate_dep_classifier "${artifact_descriptor}")
    shmate_assert "Extracting classifier from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${classifier}" = "${expected_value}"
    shmate_assert "Classifier of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${classifier}\"" || return $?

    shmate_log_debug "Classifier of \"${artifact_descriptor}\" is \"${classifier}\""

    return 0
}

_test_shmate_dep_packaging() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local packaging=
    packaging=$(shmate_dep_packaging "${artifact_descriptor}")
    shmate_assert "Extracting packaging from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${packaging}" = "${expected_value}"
    shmate_assert "Packaging of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${packaging}\"" || return $?

    shmate_log_debug "Packaging of \"${artifact_descriptor}\" is \"${packaging}\""

    return 0
}

_test_shmate_dep_file_name() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local file_name=
    file_name=$(shmate_dep_file_name "${artifact_descriptor}")
    shmate_assert "Extracting file name from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${file_name}" = "${expected_value}"
    shmate_assert "File name of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${file_name}\"" || return $?

    shmate_log_debug "File name of \"${artifact_descriptor}\" is \"${file_name}\""

    return 0
}

_test_shmate_dep_repo_path() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local repo_path=
    repo_path=$(shmate_dep_repo_path "${artifact_descriptor}")
    shmate_assert "Extracting repository file path from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${repo_path}" = "${expected_value}"
    shmate_assert "Repository file path of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${repo_path}\"" || return $?

    shmate_log_debug "Repository file path of \"${artifact_descriptor}\" is \"${repo_path}\""

    return 0
}

_test_shmate_dep_lib_name() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local lib_name=
    lib_name=$(shmate_dep_lib_name "${artifact_descriptor}")
    shmate_assert "Extracting native library name from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${lib_name}" = "${expected_value}"
    shmate_assert "Native library name of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${lib_name}\"" || return $?

    shmate_log_debug "Native library name of \"${artifact_descriptor}\" is \"${lib_name}\""

    return 0
}

_test_shmate_dep_module_path() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local module_path=
    module_path=$(shmate_dep_module_path "${artifact_descriptor}")
    shmate_assert "Extracting module path from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${module_path}" = "${expected_value}"
    shmate_assert "Module path of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${module_path}\"" || return $?

    shmate_log_debug "Module path of \"${artifact_descriptor}\" is \"${module_path}\""

    return 0
}

_test_shmate_dep_build_path() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local build_path=
    build_path=$(shmate_dep_build_path "${artifact_descriptor}")
    shmate_assert "Extracting build path from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${build_path}" = "${expected_value}"
    shmate_assert "Build path of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but is \"${build_path}\"" || return $?

    shmate_log_debug "Build path of \"${artifact_descriptor}\" is \"${build_path}\""

    return 0
}

_test_shmate_dep_deploy_opts() {
    local artifact_descriptor="$1"
    local expected_value="$2"

    local deploy_opts=
    deploy_opts=$(shmate_dep_deploy_opts "${artifact_descriptor}")
    shmate_assert "Extracting Maven deploy options from artifact descriptor \"${artifact_descriptor}\"" || return $?

    test "${deploy_opts}" = "${expected_value}"
    shmate_assert "Maven deploy options of \"${artifact_descriptor}\" must be equal to \"${expected_value}\", but are \"${deploy_opts}\"" || return $?

    shmate_log_debug "Maven deploy options of \"${artifact_descriptor}\" are \"${deploy_opts}\""

    return 0
}

if shmate_check_tools mvn; then
    test_shmate_dep_init_env() {
        local project_dir="${SHMATE_TEST_DIR}/${SHMATE_TEST_SUITE}/project"

        shmate_dep_init_env "${project_dir}" "${test_mvn_env_file}"

        test -s "${test_mvn_env_file}"
        shmate_assert "Maven environment file \"${test_mvn_env_file}\" must not empty" || return $?

        . "${test_mvn_env_file}"

        test -n "${SHMATE_MVN_PROJECT_DIR}"
        shmate_assert "\"SHMATE_MVN_PROJECT_DIR\" variable must not be empty" || return $?

        test "${SHMATE_MVN_PROJECT_DIR}" = "${project_dir}"
        shmate_assert "\"SHMATE_MVN_PROJECT_DIR\" variable must be equal to \"${project_dir}\", but is \"${SHMATE_MVN_PROJECT_DIR}\"" || return $?

        test -n "${SHMATE_MVN_OS_NAME}"
        shmate_assert "\"SHMATE_MVN_OS_NAME\" variable must not be empty" || return $?

        test -n "${SHMATE_MVN_OS_ARCH}"
        shmate_assert "\"SHMATE_MVN_OS_ARCH\" variable must not be empty" || return $?

        test -n "${SHMATE_MVN_OS_CLASSIFIER}"
        shmate_assert "\"SHMATE_MVN_OS_CLASSIFIER\" variable must not be empty" || return $?

        shmate_log_debug "SHMATE_MVN_OS_NAME=${SHMATE_MVN_OS_NAME}"
        shmate_log_debug "SHMATE_MVN_OS_ARCH=${SHMATE_MVN_OS_ARCH}"
        shmate_log_debug "SHMATE_MVN_OS_CLASSIFIER=${SHMATE_MVN_OS_CLASSIFIER}"

        return 0
    }
fi

test_shmate_dep_group_id() {
    _test_shmate_dep_group_id "${test_artifact_descriptor}" "${test_artifact_group_id}"
}

test_shmate_dep_group_id_with_classifier() {
    _test_shmate_dep_group_id "${test_native_artifact_descriptor}" "${test_artifact_group_id}"
}

test_shmate_dep_artifact_id() {
    _test_shmate_dep_artifact_id "${test_artifact_descriptor}" "${test_artifact_artifact_id}"
}

test_shmate_dep_artifact_id_with_classifier() {
    _test_shmate_dep_artifact_id "${test_native_artifact_descriptor}" "${test_artifact_artifact_id}"
}

test_shmate_dep_version() {
    _test_shmate_dep_version "${test_artifact_descriptor}" "${test_artifact_version}"
}

test_shmate_dep_version_with_classifier() {
    _test_shmate_dep_version "${test_native_artifact_descriptor}" "${test_artifact_version}"
}

test_shmate_dep_classifier_empty() {
    _test_shmate_dep_classifier "${test_artifact_descriptor}" ''
}

test_shmate_dep_classifier() {
    _test_shmate_dep_classifier "${test_native_artifact_descriptor}" "${test_native_artifact_classifier}"
}

test_shmate_dep_packaging() {
    _test_shmate_dep_packaging "${test_artifact_descriptor}" "${test_artifact_packaging}"
}

test_shmate_dep_packaging_with_classifier() {
    _test_shmate_dep_packaging "${test_native_artifact_descriptor}" "${test_artifact_packaging}"
}

test_shmate_dep_file_name() {
    _test_shmate_dep_file_name "${test_artifact_descriptor}" "${test_artifact_file_name}"
}

test_shmate_dep_file_name_with_classifier() {
    _test_shmate_dep_file_name "${test_native_artifact_descriptor}" "${test_native_artifact_file_name}"
}

test_shmate_dep_repo_path() {
    _test_shmate_dep_repo_path "${test_artifact_descriptor}" "${test_artifact_repo_path}"
}

test_shmate_dep_repo_path_with_classifier() {
    _test_shmate_dep_repo_path "${test_native_artifact_descriptor}" "${test_native_artifact_repo_path}"
}

test_shmate_dep_lib_name_without_classifier() {
    _test_shmate_dep_lib_name "${test_artifact_descriptor}" "${test_native_artifact_lib_name}" && return 1

    return 0
}

test_shmate_dep_lib_name() {
    _test_shmate_dep_lib_name "${test_native_artifact_descriptor}" "${test_native_artifact_lib_name}"
}

test_shmate_dep_module_path_empty() {
    _test_shmate_dep_module_path "${test_artifact_descriptor}" ''
}

test_shmate_dep_module_path_empty_with_classifier() {
    _test_shmate_dep_module_path "${test_native_artifact_descriptor}" ''
}

test_shmate_dep_module_path() {
    _test_shmate_dep_module_path "${test_artifact_module_path}/${test_artifact_descriptor}" "${test_artifact_module_path}"
}

test_shmate_dep_module_path_with_classifier() {
    _test_shmate_dep_module_path "${test_artifact_module_path}/${test_native_artifact_descriptor}" "${test_artifact_module_path}"
}

test_shmate_dep_build_path_without_module() {
    _test_shmate_dep_build_path "${test_artifact_descriptor}" "${test_artifact_build_path}"
}

test_shmate_dep_build_path_without_module_with_classifier() {
    _test_shmate_dep_build_path "${test_native_artifact_descriptor}" "${test_native_artifact_build_path}"
}

test_shmate_dep_build_path_with_module() {
    _test_shmate_dep_build_path "${test_artifact_module_path}/${test_artifact_descriptor}" "${test_artifact_module_path}/${test_artifact_build_path}"
}

test_shmate_dep_build_path_with_module_with_classifier() {
    _test_shmate_dep_build_path "${test_artifact_module_path}/${test_native_artifact_descriptor}" "${test_artifact_module_path}/${test_native_artifact_build_path}"
}

test_shmate_dep_deploy_opts() {
    _test_shmate_dep_deploy_opts "${test_artifact_descriptor}" "${test_artifact_deploy_opts}"
}

test_shmate_dep_deploy_opts_with_classifier() {
    _test_shmate_dep_deploy_opts "${test_native_artifact_descriptor}" "${test_native_artifact_deploy_opts}"
}
