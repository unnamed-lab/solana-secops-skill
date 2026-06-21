#!/usr/bin/env bash
# Run the full local test suite for solana-secops-skill.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "### 1) Structure + frontmatter + links + shell syntax"
bash "$ROOT/validate.sh" || { echo "validate.sh FAILED"; exit 1; }

echo ""
echo "### 2) Install smoke test (isolated HOME)"
TMP="$(mktemp -d)"
HOME="$TMP" bash "$ROOT/install.sh" -y >/dev/null 2>&1
test -f "$TMP/.claude/skills/solana-secops/SKILL.md" || { echo "skill not installed"; exit 1; }
test -f "$TMP/.claude/agents/incident-commander.md"   || { echo "agent not installed"; exit 1; }
test -f "$TMP/.claude/commands/incident.md"           || { echo "command not installed"; exit 1; }
test -f "$TMP/.claude/rules/pausable-program.md"       || { echo "rule not installed"; exit 1; }
echo "  PASS: install.sh placed skill, agents, commands, rules"

echo ""
echo "### 3) Idempotency (re-run install)"
HOME="$TMP" bash "$ROOT/install.sh" -y >/dev/null 2>&1
test -f "$TMP/.claude/skills/solana-secops/SKILL.md" || { echo "idempotent install broke"; exit 1; }
echo "  PASS: re-running install.sh is safe"

echo ""
echo "### 4) Project-local custom install"
PROJ="$(mktemp -d)"
( cd "$PROJ" && bash "$ROOT/install-custom.sh" --project -y >/dev/null 2>&1 )
test -f "$PROJ/.claude/skills/solana-secops/SKILL.md" || { echo "project install failed"; exit 1; }
echo "  PASS: install-custom.sh --project works"

rm -rf "$TMP" "$PROJ"
echo ""
echo "ALL TESTS PASSED"
