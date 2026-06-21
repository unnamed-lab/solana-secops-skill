---
description: "Render the Day-2 operational-security readiness scorecard for a Solana program/repo: verified build, upgrade & token authority, circuit breakers, monitoring, security.txt, and incident runbook."
---

You are running a **Day-2 readiness review**. Produce a scorecard across the six operational-security dimensions and, for each, report `PASS` / `MISSING` / `N/A` with the specific next action. Be concrete — show the command or file that proves each item.

Read [SKILL.md](../skill/SKILL.md) for routing and use the relevant module for each dimension. Output the filled [readiness-scorecard.md.template](../templates/readiness-scorecard.md.template).

## Step 0: Gather targets

Ask for (or detect from the repo): `PROGRAM_ID`, cluster (`devnet`/`mainnet-beta`), repo URL, and where the upgrade authority currently points. Detect program crates and Anchor usage:

```bash
echo "Day-2 Readiness Review"
echo "======================"

# Detect Rust/Anchor program(s)
if [ -f "Anchor.toml" ]; then
  echo "Anchor project detected"
  grep -E '^\s*\[programs' -A 10 Anchor.toml 2>/dev/null || true
fi
find . -name "Cargo.toml" -not -path "*/target/*" 2>/dev/null | head -20

# Lockfile committed? (reproducibility prerequisite)
if [ -f "Cargo.lock" ]; then echo "PASS: Cargo.lock present"; else echo "MISSING: commit Cargo.lock"; fi
```

## Step 1: Verified build  (see verified-deploy.md)

```bash
# Requires: cargo install solana-verify ; solana CLI
PROGRAM_ID="${PROGRAM_ID:?set PROGRAM_ID}"
CLUSTER="${CLUSTER:-mainnet-beta}"

if command -v solana-verify >/dev/null 2>&1; then
  echo "On-chain program hash:"
  solana-verify get-program-hash -u "$CLUSTER" "$PROGRAM_ID" || echo "  (could not fetch)"
  echo "Local artifact hash (build first):"
  ls target/deploy/*.so 2>/dev/null | head -1 | xargs -r solana-verify get-executable-hash || echo "  (no local .so; run a build)"
  echo "-> PASS if hashes match AND a verify PDA/remote job exists; else MISSING"
else
  echo "MISSING: install solana-verify (cargo install solana-verify)"
fi
```

## Step 2: Authority hardening  (see authority-hardening.md)

```bash
# Show the program's current upgrade authority
solana program show "$PROGRAM_ID" -u "$CLUSTER" 2>/dev/null | grep -i "Authority" \
  || echo "  (install solana CLI / check manually)"
echo "-> PASS if authority is a Squads VAULT with a timelock, or intentionally None (immutable)."
echo "-> MISSING if it is a single hot key."
```
Also confirm by inspection: mint/freeze/metadata authorities for any token, and that multisig signers are cold + independent. These can't be fully auto-detected — ask the user and record answers.

## Step 3: Circuit breakers  (see circuit-breakers.md)

```bash
# Heuristic: look for a pause gate and guardian role in the program source
echo "Searching program source for pause/guardian patterns..."
grep -rEn "paused|is_paused|guardian|whenNotPaused|SecError::Paused" \
  --include="*.rs" . 2>/dev/null | grep -v "/target/" | head -20 \
  || echo "MISSING: no pause/guardian gate found — add one before mainnet (highest priority)"
```
`PASS` only if value-moving instructions are gated by a pause flag AND a guardian-only pause path exists. A grep hit is a hint, not proof — confirm the gate actually guards withdrawals/transfers.

## Step 4: Monitoring  (see monitoring.md)

Cannot be detected from the repo. Ask:
- Are Helius (or equivalent) webhooks subscribed to the program id + vault addresses?
- Do pause/rate-limit/privileged-instruction events page on-call?
- Is the alert path tested end-to-end?
- Eligible for / integrated with Hypernative, Range, or Riverguard?

Mark `PASS` only if monitoring is live (ideally on staging) with a real 24/7 on-call.

## Step 5: security.txt  (see verified-deploy.md)

```bash
grep -rEn "security_txt!|security\.txt" --include="*.rs" . 2>/dev/null | grep -v "/target/" | head \
  || echo "MISSING: embed security.txt (neodyme-labs/solana-security-txt)"
[ -f "SECURITY.md" ] && echo "PASS: SECURITY.md policy present" || echo "MISSING: add SECURITY.md policy"
```

## Step 6: Incident runbook  (see incident-response.md)

```bash
if ls INCIDENT*.md RUNBOOK*.md docs/incident*.md 2>/dev/null | head -1 >/dev/null; then
  echo "PASS: an incident runbook file exists"
else
  echo "MISSING: commit a filled incident-runbook.md (templates/incident-runbook.md.template)"
fi
```
Confirm it contains: the exact pause command, the guardian holder, and SEAL 911 / SIRN contacts.

## Step 7: Render the scorecard

Fill [readiness-scorecard.md.template](../templates/readiness-scorecard.md.template) with each dimension's status and next action. End with the single **biggest remaining risk** and whether the protocol is launch-ready.

Decision rule: **not launch-ready** if any of {no pause switch, single-key upgrade authority, no monitoring, no runbook} is true — these are blockers, not warnings.
