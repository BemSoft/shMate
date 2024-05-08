#!/usr/bin/env bash

# shellcheck disable=SC2039

if [ -z "${_SHMATE_INCLUDE_LIB_DEPENDENCY}" ]; then
    readonly _SHMATE_INCLUDE_LIB_DEPENDENCY='included'

#> >>> dependency.sh

#> Library for dealing with Maven style artifacts and their repositories.
#>

# shellcheck source=src/lib/shmate/assert.sh
. "${SHMATE_LIB_DIR}/assert.sh"

#> >>>> Internal symbols
#>
#> .Variables
#> [%collapsible]
#> ====
#> _shmate_dep_regex::
#> Regular expression for Gradle style artifact name optionally prefixed with module path relative to source root.
#> +
#> .Descriptor of an artifact within module
#> =====
#> ....
#> transport-native-kqueue/io.netty:netty-transport-native-kqueue:4.1.107.Final:osx-x86_64@jar
#> ....
#> =====
#>
readonly _shmate_dep_regex="(([^']*)/)?([^':@]+):([^':@]+):([^':@]+)(:([^':@]+))?(@([^':@]+))?"
#> ====
#>

#> >>>> Functions
#>
#> >>>>> shmate_dep_init_env <project_dir> <target_env_file> [<mvn_cmd>]
#>
shmate_dep_init_env() {
    local src_dir="$1"
    local src_mvn_env="$2"
    local mvn_cmd="${3:-mvn}" # Optional

    test -n "${src_dir}"
    shmate_assert 'Source directory must be specified' || return $?

    test -d "${src_dir}"
    shmate_assert "Source directory \"${src_dir}\" does not exist or is not a directory" || return $?

    shmate_log_audit_begin && \
        shmate_log_audit_command echo "SHMATE_MVN_PROJECT_DIR='${src_dir}'" && \
        shmate_log_audit_operator '>' && \
        shmate_log_audit_file "${src_mvn_env}" && \
        shmate_log_audit_end
    echo "SHMATE_MVN_PROJECT_DIR='${src_dir}'" > "${src_mvn_env}"
    shmate_assert "Creating Maven environment of \"${src_dir}\" in \"${src_mvn_env}\"" || return $?

    shmate_audit ${mvn_cmd} -f "${src_dir}" -N kr.motd.maven:os-maven-plugin:detect | sed -En \
        -e 's|.*os\.detected\.name:[[:space:]]+([^[:space:]]+).*|SHMATE_MVN_OS_NAME=\1|p' \
        -e 's|.*os\.detected\.arch:[[:space:]]+([^[:space:]]+).*|SHMATE_MVN_OS_ARCH=\1|p' \
        -e 's|.*os\.detected\.classifier:[[:space:]]+([^[:space:]]+).*|SHMATE_MVN_OS_CLASSIFIER=\1|p' \
        | head -n 3 >> "${src_mvn_env}"
    shmate_assert "Storing Maven environment of \"${src_dir}\" in \"${src_mvn_env}\"" || return $?
}

#> >>>>> shmate_dep_parse <artifact_descriptor> [<var_group_id> [<var_artifact_id> [<var_version> [<var_classifier> [<var_packaging> [<var_module_path>]]]]]]
#>
shmate_dep_parse() {
    local artifact="$1"
    shift

    test -n "${artifact}"
    shmate_assert 'Artifact must be specified' || return $?

    local var_group_id="${1:-ignored}"
    local var_artifact_id="${2:-ignored}"
    local var_version="${3:-ignored}"
    local var_classifier="${4:-ignored}"
    local var_packaging="${5:-ignored}"
    local var_module_path="${6:-ignored}"
    local ignored=

    local vars=
    vars=$(shmate_input_run "${artifact}" sed -En "s|${_shmate_dep_regex}|${var_group_id}='\\3' ${var_artifact_id}='\\4' ${var_version}='\\5' ${var_classifier}='\\7' ${var_packaging}='\\9' ${var_module_path}='\\2'|p")
    shmate_assert "Extracting variables from artifact descriptor \"${artifact}\"" || return $?

    eval "${vars}"

    if [ "${var_packaging}" != 'ignored' ]; then
        local packaging=
        eval packaging='$'${var_packaging}
        if [ -z "${packaging}" ]; then
            eval ${var_packaging}='jar'
        fi
    fi

    return 0
}

#> >>>>> shmate_dep_group_id <artifact_descriptor>
#>
shmate_dep_group_id() {
    local group_id=
    shmate_dep_parse "$1" group_id || return $?
    echo "${group_id}"
}

#> >>>>> shmate_dep_artifact_id <artifact_descriptor>
#>
shmate_dep_artifact_id() {
    local artifact_id=
    shmate_dep_parse "$1" '' artifact_id || return $?
    echo "${artifact_id}"
}

#> >>>>> shmate_dep_version <artifact_descriptor>
#>
shmate_dep_version() {
    local version=
    shmate_dep_parse "$1" '' '' version || return $?
    echo "${version}"
}

#> >>>>> shmate_dep_classifier <artifact_descriptor>
#>
shmate_dep_classifier() {
    local classifier=
    shmate_dep_parse "$1" '' '' '' classifier || return $?
    echo "${classifier}"
}

#> >>>>> shmate_dep_packaging <artifact_descriptor>
#>
shmate_dep_packaging() {
    local packaging=
    shmate_dep_parse "$1" '' '' '' '' packaging || return $?
    echo "${packaging}"
}

#> >>>>> shmate_dep_module_path <artifact_descriptor>
#>
shmate_dep_module_path() {
    local module_path=
    shmate_dep_parse "$1" '' '' '' '' '' module_path || return $?
    echo "${module_path}"
}

#> >>>>> shmate_dep_file_name <artifact_descriptor>
#>
shmate_dep_file_name() {
    local artifact="$1"

    local artifact_id= version= classifier= packaging=
    shmate_dep_parse "${artifact}" '' artifact_id version classifier packaging || return $?

    if [ -n "${classifier}" ]; then
        classifier="-${classifier}"
    fi

    echo "${artifact_id}-${version}${classifier}.${packaging}"
}

#> >>>>> shmate_dep_lib_name <artifact_descriptor>
#>
shmate_dep_lib_name() {
    local artifact="$1"

    local artifact_id= classifier=
    shmate_dep_parse "${artifact}" '' artifact_id '' classifier || return $?

    test -n "${classifier}"
    shmate_assert 'Classifier must not be empty' || return $?

    local lib_name=
    lib_name=$(echo "${artifact_id}" | tr '-' '_') || return $?

    local os_name="${classifier%%-*}"
    local os_arch="${classifier#*-}"

    test "${os_name}" != "${os_arch}"
    shmate_assert "Classifier must describe native library, but is \"${classifier}\"" || return $?

    local lib_ext=
    case "${os_name}" in
        windows)
            lib_ext='dll'
            ;;
        osx)
            lib_ext='jnilib'
            ;;
        *)
            lib_ext='so'
            ;;
    esac

    echo "lib${lib_name}_${os_arch}.${lib_ext}"
}

#> >>>>> shmate_dep_repo_path <artifact_descriptor>
#>
shmate_dep_repo_path() {
    local artifact="$1"

    local group_id= artifact_id= version= classifier= packaging=
    shmate_dep_parse "${artifact}" group_id artifact_id version classifier packaging || return $?

    if [ -n "${classifier}" ]; then
        classifier="-${classifier}"
    fi

    local group_path=
    group_path=$(echo -n "${group_id}" | tr '.' '/') || return $?

    echo "${group_path}/${artifact_id}/${version}/${artifact_id}-${version}${classifier}.${packaging}"
}

#> >>>>> shmate_dep_build_path <artifact_descriptor>
#>
shmate_dep_build_path() {
    local artifact="$1"

    local artifact_id= version= classifier= packaging= module_path=
    shmate_dep_parse "${artifact}" '' artifact_id version classifier packaging module_path || return $?

    if [ -n "${classifier}" ]; then
        classifier="-${classifier}"
    fi

    local build_path="target/${artifact_id}-${version}${classifier}.${packaging}"
    if [ -n "${module_path}" ]; then
        build_path="${module_path}/${build_path}"
    fi

    echo "${build_path}"
}

#> >>>>> shmate_dep_deploy_opts <artifact_descriptor>
#>
shmate_dep_deploy_opts() {
    local artifact="$1"

    local group_id= artifact_id= version= classifier= packaging=
    shmate_dep_parse "${artifact}" group_id artifact_id version classifier packaging || return $?

    local build_path=
    build_path=$(shmate_dep_build_path "${artifact}") || return $?

    if [ -n "${classifier}" ]; then
        classifier=" -Dclassifier='${classifier}'"
    fi

    echo "-Dfile='${build_path}' -DgroupId='${group_id}' -DartifactId='${artifact_id}' -Dversion='${version}' -Dpackaging='${packaging}'${classifier}"
}

fi
