#!/usr/bin/env bash

# shellcheck disable=SC2039

if [ -z "${_SHMATE_INCLUDE_LIB_DEPRECATED}" ]; then
    readonly _SHMATE_INCLUDE_LIB_DEPRECATED='included'

#> >>> _deprecated.sh
#>
#> Library defining all deprecated symbols in _shMate_.
#>
#> >>>> Internal symbols
#>
#> .Variables
#> [%collapsible]
#> ====
#> * _shmate_deprecated_vars
readonly _shmate_deprecated_vars=
#> * _shmate_deprecated_functions
readonly _shmate_deprecated_functions=
#> * _shmate_deprecated_vars_declared
_shmate_deprecated_vars_declared=
#> ====
#>

#> .Functions
#> [%collapsible]
#> ====
#> * _shmate_deprecated_vars_collect
_shmate_deprecated_vars_collect() {
    local var_name=
    for var_name in ${_shmate_deprecated_vars}; do
        if [ -n "${var_name+x}" ]; then
            _shmate_deprecated_vars_declared="${_shmate_deprecated_vars_declared} ${var_name}"
        fi
    done

    readonly _shmate_deprecated_vars_declared
    return 0
}

#> * _shmate_deprecated_symbols_check
_shmate_deprecated_symbols_check() {
    local symbol_name=
    for symbol_name in ${_shmate_deprecated_vars_declared}; do
        shmate_log_warning "Variable \"${symbol_name}\" has been deprecated"
    done
    for symbol_name in ${_shmate_deprecated_functions}; do
        shmate_log_warning "Function \"${symbol_name}\" has been deprecated"
    done

    return 0
}

#> ====
#>

_shmate_deprecated_vars_collect

fi
