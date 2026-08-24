#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMAL_ROOT="$ROOT/formal"
MODE="${1:---all}"

fail() {
    printf 'formal-check: %s\n' "$1" >&2
    exit 1
}

for tool in awk lake rg tee; do
    command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

case "$ROOT/" in
    /tmp/*|/private/tmp/*|/var/tmp/*)
        fail "project execution from an operating-system temporary directory is prohibited"
        ;;
esac

build_formal_project() {
    (
        cd "$FORMAL_ROOT"
        lake clean
        lake build
    )
}

audit_formal_project() {
    if rg -n --glob '*.lean' \
        '(^|[^[:alnum:]_])(sorry|admit|unsafe|native_decide|implemented_by|extern|opaque|partial)([^[:alnum:]_]|$)|^[[:space:]]*(axiom|constant)[[:space:]]+([[:alnum:]_.]+[[:space:]]*:|\()' \
        "$FORMAL_ROOT/StrategyInnovation" "$FORMAL_ROOT/StrategyInnovation.lean"; then
        fail "prohibited Lean placeholder, evaluator, declaration, or proof-critical marker found"
    fi

    local axiom_log="$FORMAL_ROOT/.lake/axiom-audit.log"
    (
        cd "$FORMAL_ROOT"
        lake env lean StrategyInnovation/Audit/AxiomAudit.lean
    ) 2>&1 | tee "$axiom_log"
    (
        cd "$FORMAL_ROOT"
        lake env lean StrategyInnovation/Audit/ManuscriptLint.lean
    )

    awk '
        function audit_axiom_list(line, count, item) {
            sub(/^.*depends on axioms: \[/, "", line)
            sub(/\].*$/, "", line)
            gsub(/[[:space:]]/, "", line)
            count = split(line, names, ",")
            for (item = 1; item <= count; item += 1) {
                if (names[item] != "propext" &&
                    names[item] != "Classical.choice" &&
                    names[item] != "Quot.sound") {
                    print "unexpected axiom dependency: " names[item] > "/dev/stderr"
                    bad = 1
                }
            }
        }
        /depends on axioms:/ {
            audited += 1
            axiom_record = $0
            if ($0 ~ /\]/) {
                audit_axiom_list(axiom_record)
            } else {
                collecting = 1
            }
            next
        }
        collecting {
            axiom_record = axiom_record " " $0
            if ($0 ~ /\]/) {
                audit_axiom_list(axiom_record)
                collecting = 0
            }
            next
        }
        /does not depend on any axioms/ { audited += 1 }
        END {
            if (collecting) {
                print "unterminated axiom dependency report" > "/dev/stderr"
                exit 3
            }
            if (audited == 0) {
                print "axiom audit produced no dependency reports" > "/dev/stderr"
                exit 2
            }
            if (bad) exit 1
        }
    ' "$axiom_log" || fail "Lean axiom audit contains an unapproved dependency"

    local expected_reports
    local actual_reports
    expected_reports="$(rg -c '^#print axioms ' "$FORMAL_ROOT/StrategyInnovation/Audit/AxiomAudit.lean")"
    actual_reports="$(awk '/depends on axioms:|does not depend on any axioms/ { count += 1 } END { print count + 0 }' "$axiom_log")"
    [[ "$actual_reports" == "$expected_reports" ]] ||
        fail "axiom audit returned $actual_reports reports; expected $expected_reports"
    printf 'Lean axiom audit passed: %s declarations; only propext, Classical.choice, Quot.sound, or fewer.\n' \
        "$actual_reports"
}

case "$MODE" in
    --all)
        build_formal_project
        audit_formal_project
        ;;
    --build)
        build_formal_project
        ;;
    --audit)
        audit_formal_project
        ;;
    *)
        fail "usage: formal_check.sh [--all|--build|--audit]"
        ;;
esac
