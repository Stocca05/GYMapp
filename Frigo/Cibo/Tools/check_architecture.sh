#!/usr/bin/env bash

# Verifica i confini architetturali del modulo Cibo.
set -u
set -o pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
PROJECT_ROOT="$(cd -- "${MODULE_ROOT}/../.." && pwd)"
TEST_ROOT="${PROJECT_ROOT}/FrigoTests/Cibo"
violations=0

report_violation() {
    printf 'VIOLATION: %s\n' "$1"
    violations=1
}

report_warning() {
    printf 'WARNING: %s\n' "$1"
}

swift_files_in() {
    local directory="$1"
    if [[ -d "${directory}" ]]; then
        find "${directory}" -type f -name '*.swift' -print
    fi
}

feature_swift_files() {
    if [[ -d "${MODULE_ROOT}/Features" ]]; then
        find "${MODULE_ROOT}/Features" -path "${MODULE_ROOT}/Features/Shell" -prune -o -type f -name '*.swift' -print
    fi
}

check_forbidden_imports() {
    local directory="$1"
    shift
    local imports=("$@")
    local file import_name

    while IFS= read -r file; do
        for import_name in "${imports[@]}"; do
            # Use rg -q to suppress output and just check exit code
            if rg -q --glob '*.swift' "^[[:space:]]*import[[:space:]]+${import_name}([[:space:]]|$)" "${file}"; then
                report_violation "${file#"${PROJECT_ROOT}/"} imports ${import_name}."
            fi
        done
    done < <(swift_files_in "${directory}")
}

check_domain_imports() {
    local file
    while IFS= read -r file; do
        if rg -q --glob '*.swift' '^[[:space:]]*import[[:space:]]+(?!Foundation([[:space:]]|$))' "${file}" --pcre2; then
            report_violation "${file#"${PROJECT_ROOT}/"} imports a module other than Foundation."
        fi
    done < <(swift_files_in "${MODULE_ROOT}/Domain")
}

check_feature_forbidden_imports() {
    local file import_name
    local imports=(SwiftData Vision CoreImage)

    while IFS= read -r file; do
        for import_name in "${imports[@]}"; do
            if rg -q --glob '*.swift' "^[[:space:]]*import[[:space:]]+${import_name}([[:space:]]|$)" "${file}"; then
                report_violation "${file#"${PROJECT_ROOT}/"} imports ${import_name}."
            fi
        done
    done < <(feature_swift_files)
}

check_concrete_feature_references() {
    local declaration feature_files=()

    while IFS= read -r file; do
        [[ -n "${file}" ]] && feature_files+=("${file}")
    done < <(swift_files_in "${MODULE_ROOT}/Features" | rg -v '/Features/Shell/')

    if (( ${#feature_files[@]} == 0 )); then
        return
    fi

    while IFS= read -r declaration; do
        [[ -z "${declaration}" ]] && continue
        
        # Using rg -l we get exactly the files that match without extra output
        while IFS= read -r feature_file; do
            [[ -z "${feature_file}" ]] && continue
            report_violation "${feature_file#"${PROJECT_ROOT}/"} references concrete Data/Services type ${declaration}."
        done < <(rg -l --glob '*.swift' "\\b${declaration}\\b" "${feature_files[@]}")
    done < <((swift_files_in "${MODULE_ROOT}/Data"; swift_files_in "${MODULE_ROOT}/Services") | while IFS= read -r file; do
        rg --no-filename --pcre2 -o '^\s*(?:public|internal|private)?\s*(?:final\s+)?(?:actor|class|struct|enum)\s+\K[A-Za-z_][A-Za-z0-9_]*' "${file}"
    done)
}

check_model_context_usage() {
    local file relative_path
    while IFS= read -r file; do
        relative_path="${file#"${MODULE_ROOT}/"}"
        if [[ "${relative_path}" != Data/* ]] && rg -q --glob '*.swift' '@Query\b|\bModelContext\b' "${file}"; then
            report_violation "${file#"${PROJECT_ROOT}/"} uses @Query or ModelContext outside Data/."
        fi
    done < <(swift_files_in "${MODULE_ROOT}")
}

check_banned_constructs() {
    local pattern label
    local patterns=('try!' 'as!' 'fatalError\(' 'preconditionFailure\(' 'print\(')
    local labels=('try!' 'as!' 'fatalError(' 'preconditionFailure(' 'print(')

    for ((index = 0; index < ${#patterns[@]}; index++)); do
        pattern="${patterns[index]}"
        label="${labels[index]}"
        if rg -q --glob '*.swift' "${pattern}" "${MODULE_ROOT}"; then
            report_violation "Found forbidden ${label}."
        fi
    done
}

check_force_unwrap_heuristic() {
    local file
    local force_unwrap_pattern='[[:alnum:]_\)\]\?][[:space:]]*!([[:space:]]*[,\.\)\]\}:;]|$)'

    while IFS= read -r file; do
        if rg -q --pcre2 "${force_unwrap_pattern}" "${file}"; then
            report_violation "${file#"${PROJECT_ROOT}/"} may contain a force unwrap. Review the reported expression."
        fi
    done < <(swift_files_in "${MODULE_ROOT}")
}

check_file_lengths() {
    local file lines
    while IFS= read -r file; do
        lines="$(wc -l < "${file}")"
        if (( lines > 300 )); then
            report_warning "${file#"${PROJECT_ROOT}/"} has ${lines} lines (limit: 300; ADR required)."
        fi
    done < <(swift_files_in "${MODULE_ROOT}")
}

check_domain_imports
check_forbidden_imports "${MODULE_ROOT}/Data" SwiftUI UIKit Vision CoreImage
check_feature_forbidden_imports
check_concrete_feature_references
check_model_context_usage
check_banned_constructs
check_force_unwrap_heuristic
check_file_lengths

if (( violations != 0 )); then
    printf 'Architecture checks failed.\n'
    exit 1
fi

printf 'Architecture checks passed.\n'
