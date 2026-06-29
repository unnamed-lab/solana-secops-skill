# Solana SecOps Skill

**Day-2 operational security & incident response for live Solana protocols — the layer the Solana AI Kit is missing.**

> Your code passed the audit. Now what? This skill owns everything *after* the audit: verified deployment, authority hardening, in-program circuit breakers, production monitoring, a battle-tested incident-response runbook, and recovery/post-mortem tooling.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## The problem it solves

The most expensive Solana failures of 2026 were **not** code bugs. The April 2026 Drift exploit (~$285M) passed its audits — the loss came from compromised contributor devices, multisig signer hygiene, and durable-nonce abuse: the gap between on-chain correctness and off-chain operational trust. Audits and formal verification do not cover that gap.

The Solana AI Kit is deep on **building** and **pre-launch security** (Trail of Bits, Ghost Security, safe-solana-builder, QEDGen formal verification, the defending-code harness). It has almost nothing on the **Day-2** lifecycle: ship-to-mainnet safety, running a live program, and responding to an active exploit. This skill fills that gap.

It operationalizes the three pillars the 2026 ecosystem standard (Solana Foundation's STRIDE program + Solana Incident Response Network) now expects on every serious deployment — **verified builds, circuit breakers, and monitoring** — and adds the incident runbook and recovery process on top.

## What it does

| Stage | Module | You get |
|-------|--------|---------|
| Threat framing | `threat-model.md` | Day-2 risk catalog: signer/key compromise, supply-chain (malicious editor/TestFlight), durable-nonce abuse, governance capture, oracle manipulation |
| Ship safely | `verified-deploy.md` | `solana-verify` reproducible builds, on-chain verify PDA, `security.txt`, deploy mechanics |
| Harden | `authority-hardening.md` | Upgrade authority -> Squads V4 vault + timelock, mint/freeze authority, immutability decision, durable-nonce hygiene |
| Defend (design-time) | `circuit-breakers.md` | Pause/guardian/rate-limit patterns, fast-pause/slow-unpause, reference Anchor snippet |
| Watch | `monitoring.md` | Helius webhooks + alert thresholds, Hypernative/Range/Riverguard, on-call |
| **Respond** | `incident-response.md` | The runbook: detect -> pause -> war-room -> contain -> escalate (SEAL 911/SIRN) -> comms -> forensics |
| Recover | `recovery-postmortem.md` | White-hat negotiation, reimbursement, blameless post-mortem |

Plus **2 agents** (`incident-commander` for live incidents, `secops-engineer` for proactive hardening), **3 commands** (`/secops-readiness`, `/setup-monitoring`, `/incident`), an auto-loading **rule** that enforces pause/guardian/rate-limit patterns on Rust programs, and **5 templates** (security.txt, incident runbook, war-room log, post-mortem, readiness scorecard) to commit into your repo.

## Why it's structured this way

- **Progressive disclosure**: `skill/SKILL.md` is a router; modules load only when the task needs them (token-efficient, matches the kit's design).
- **Cross-domain by design**: spans program design (pause switches), DevOps (CI signing, monitoring), security (threat model, key hygiene), and ops/comms/legal (the incident war-room).
- **Complements, never duplicates**: code-level vulnerability classes stay with `solana-dev-skill` and the audit skills; Squads SDK details stay with Squads docs. This skill is the connective operational layer that orchestrates them.

## Install

### Unix / macOS (Bash)

#### Standard (personal, all projects)
```bash
git clone https://github.com/unnamed-lab/solana-secops-skill
cd solana-secops-skill
./install.sh           # interactive; -y for non-interactive
```
Installs to `~/.claude/`: skill -> `skills/solana-secops/`, agents, commands, rules.

#### Project-local
```bash
./install-custom.sh --project    # installs to ./.claude in the current repo
# or:  ./install-custom.sh --path /path/to/project
```

### Windows (PowerShell)

#### Standard (personal, all projects)
```powershell
git clone https://github.com/unnamed-lab/solana-secops-skill
cd solana-secops-skill
powershell -File .\install.ps1
```

#### Project-local
```powershell
powershell -File .\install.ps1 -Project
# or: powershell -File .\install.ps1 -Path C:\path\to\project
```

### As part of the Solana AI Kit
This repo mirrors the kit's skill shape and is designed to be added as a submodule (`ext/secops`) with its routing registered in the kit's `SKILL.md` hub. See `SUBMISSION.md` for the PR plan.

### Companion
Install [`solana-dev-skill`](https://github.com/solana-foundation/solana-dev-skill) for the code-level patterns this skill defers to.

## Try it

```
"Run a Day-2 readiness review on my program"
"Move my upgrade authority to a Squads multisig with a timelock"
"Add a guardian pause switch to my Anchor program"
"Set up Helius monitoring for my vaults"
"We think we're being exploited"        # launches the incident runbook
```

## Validate / test

```bash
./validate.sh        # structure, frontmatter, relative-link integrity, shell syntax
bash tests/run_all.sh   # + install smoke test, idempotency, project-local install
```

## License

MIT — see [LICENSE](LICENSE). Built for the Solana AI Kit (`solanabr/solana-ai-kit`).
