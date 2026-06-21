#!/usr/bin/env bash
# Validate the solana-secops-skill repo: structure, frontmatter, and
# relative-link integrity (mirrors the Solana AI Kit's test_skills.sh link check).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "== solana-secops-skill validation =="

# --- 1. Required files ---
echo "[structure]"
REQUIRED=(
  "README.md" "CLAUDE.md" "LICENSE" "install.sh" "install-custom.sh"
  "skill/SKILL.md" "skill/threat-model.md" "skill/verified-deploy.md"
  "skill/authority-hardening.md" "skill/circuit-breakers.md" "skill/monitoring.md"
  "skill/incident-response.md" "skill/recovery-postmortem.md" "skill/resources.md"
  "agents/incident-commander.md" "agents/secops-engineer.md"
  "commands/secops-readiness.md" "commands/setup-monitoring.md" "commands/incident.md"
  "rules/pausable-program.md"
  "templates/SECURITY.txt.template" "templates/incident-runbook.md.template"
  "templates/war-room.md.template" "templates/postmortem.md.template"
  "templates/readiness-scorecard.md.template"
)
for f in "${REQUIRED[@]}"; do
  [ -f "$ROOT/$f" ] && ok "exists: $f" || bad "missing: $f"
done

# --- 2. Frontmatter checks ---
echo "[frontmatter]"
fm_has() { # file, key
  awk 'NR==1 && $0=="---"{f=1;next} f && /^---$/{exit} f && $0 ~ "^"k":"{print "1";exit}' k="$2" "$1" 2>/dev/null
}
[ "$(fm_has "$ROOT/skill/SKILL.md" name)" = "1" ] && ok "SKILL.md has name" || bad "SKILL.md missing name"
[ "$(fm_has "$ROOT/skill/SKILL.md" description)" = "1" ] && ok "SKILL.md has description" || bad "SKILL.md missing description"
for a in "$ROOT"/agents/*.md; do
  n=$(basename "$a")
  [ "$(fm_has "$a" name)" = "1" ] && ok "$n has name" || bad "$n missing name"
  [ "$(fm_has "$a" model)" = "1" ] && ok "$n has model" || bad "$n missing model"
done
for c in "$ROOT"/commands/*.md; do
  n=$(basename "$c")
  [ "$(fm_has "$c" description)" = "1" ] && ok "$n has description" || bad "$n missing description"
done
[ "$(fm_has "$ROOT/rules/pausable-program.md" globs)" = "1" ] && ok "rule has globs" || bad "rule missing globs"

# --- 3. Relative-link integrity (skip http/https/mailto/anchors) ---
echo "[links]"
while IFS= read -r mdfile; do
  dir="$(dirname "$mdfile")"
  # extract ](target) links
  grep -oE '\]\([^)]+\)' "$mdfile" | sed 's/^](//; s/)$//' | while IFS= read -r link; do
    case "$link" in
      http*|mailto:*|\#*) continue ;;
    esac
    target="${link%%#*}"        # strip any #anchor
    [ -z "$target" ] && continue
    if [ ! -e "$dir/$target" ]; then
      echo "  FAIL: broken link in ${mdfile#$ROOT/} -> $link"
    fi
  done
done < <(find "$ROOT/skill" "$ROOT/agents" "$ROOT/commands" "$ROOT/rules" -name "*.md")

# Recount link failures (subshell-safe) and fold into totals
link_fail=$(
  while IFS= read -r mdfile; do
    dir="$(dirname "$mdfile")"
    grep -oE '\]\([^)]+\)' "$mdfile" | sed 's/^](//; s/)$//' | while IFS= read -r link; do
      case "$link" in http*|mailto:*|\#*) continue ;; esac
      target="${link%%#*}"; [ -z "$target" ] && continue
      [ -e "$dir/$target" ] || echo x
    done
  done < <(find "$ROOT/skill" "$ROOT/agents" "$ROOT/commands" "$ROOT/rules" -name "*.md") | grep -c x
)
if [ "$link_fail" -eq 0 ]; then ok "all relative links resolve"; else bad "$link_fail broken relative link(s)"; fi

# --- 4. Shell scripts parse ---
echo "[shell]"
for s in "$ROOT/install.sh" "$ROOT/install-custom.sh" "$ROOT/validate.sh"; do
  if bash -n "$s" 2>/dev/null; then ok "bash -n: $(basename "$s")"; else bad "bash -n failed: $(basename "$s")"; fi
done

echo ""
echo "== Summary: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
