---
name: solana-secops
description: "Day-2 operational security and incident response for live Solana protocols. Covers verified/reproducible deployment, upgrade- and signer-authority hardening (Squads V4, timelocks, durable-nonce risk), in-program circuit breakers (pause/guardian/rate-limit patterns), on-chain monitoring and detection (Helius webhooks, ecosystem tools), a step-by-step incident-response runbook, and recovery/post-mortem workflows. Use AFTER code is written/audited — when shipping to mainnet, operating a live program, or responding to an active exploit. Complements pre-launch audit skills (Trail of Bits, Ghost Security, safe-solana-builder); this is the operational layer they do not cover. For program code patterns and audits, delegates to solana-dev-skill and the security audit skills."
user-invocable: true
---

# Solana SecOps Skill — Operational Security & Incident Response

> **Scope**: This is the **Day-2** skill. The Solana AI Kit covers building and *pre-launch* security in depth. This skill owns everything *after* the audit passes: verified deployment, authority hardening, monitoring, and what to do when you are being exploited at 3am.
>
> **Complements (does not replace)**: `solana-dev-skill` (program/client patterns), Trail of Bits / Ghost Security / safe-solana-builder (code-level audits), QEDGen (formal verification). Those answer *"is the code correct?"* This skill answers *"is the live system defensible, observable, and recoverable?"*

## Why This Skill Exists

The most expensive Solana failures of 2026 were **not** code bugs. The April 2026 Drift exploit (~$285M) passed its audits — the loss came from compromised contributor devices, multisig signer hygiene, and durable-nonce abuse: the gap between on-chain correctness and off-chain operational trust. Audits and formal verification do not cover that gap. Operations does.

The 2026 ecosystem standard (Solana Foundation STRIDE program + Solana Incident Response Network) now expects three operational pillars on every serious deployment: **verified builds**, **circuit breakers (timelocked multisig pause)**, and **autonomous monitoring**. This skill operationalizes all three, plus the incident runbook and recovery process that sit on top of them.

## What This Skill Is For

Use this skill when the user asks for any of:

### Shipping to mainnet safely
- Reproducible / verified builds (`solana-verify`, on-chain verify PDA, OtterSec API)
- `security.txt` (on-chain contact + audit metadata) and program metadata
- A pre-mainnet **Day-2 readiness review** before flipping to prod

### Hardening a live deployment
- Moving upgrade authority to a multisig (Squads V4) with a timelock
- Signer-set hygiene, cold-signer policy, durable-nonce risk
- Deciding when/whether to make a program immutable
- Mint / freeze / metadata authority handling for tokens

### Defense-in-depth in the program itself
- Pause switches, `guardian` roles, withdrawal & rate limits
- Designing fast-pause / slow-unpause so you *can* respond to an incident

### Watching production
- Helius webhooks + anomaly alerts, what to monitor and at what thresholds
- Wiring free ecosystem monitoring (Hypernative, Range, Riverguard)

### Responding to an active incident
- The detect → pause → war-room → contain → escalate → comms → forensics runbook
- Who to call (SEAL 911, SIRN), how to flag attacker addresses to exchanges/bridges

### Recovering afterwards
- White-hat negotiation, reimbursement strategy, blameless post-mortem

### Delegate to other skills
- Program correctness / vulnerability classes → `solana-dev-skill` → `security.md`, and the audit skills (Trail of Bits, Ghost Security, safe-solana-builder)
- DeFi protocol integration details → `sendai` / `jupiter` skills
- Squads SDK call-level integration → see [authority-hardening.md](authority-hardening.md) (this skill scopes the *policy*; defer raw SDK calls to Squads docs)

## Operating Principles (Opinionated)

1. **Audited ≠ safe.** Treat every live program as already targeted. Plan for *when*, not *if*.
2. **You cannot respond to what you cannot pause.** A pause switch you ship on day-1 is the cheapest insurance you will ever buy. Add it before launch or you have no lever during an incident.
3. **Fast to pause, slow to unpause.** Pausing should need one trusted signer (the guardian). Unpausing and upgrading should need the full multisig + timelock.
4. **Verifiability is a security control, not a vanity badge.** If users can't reproduce your binary from source, they can't tell your upgrade from an attacker's.
5. **Keys are the attack surface.** In 2026, the dominant exploit vector is the human/key layer (social engineering, malicious editor extensions, signer compromise), not the bytecode. Harden signers accordingly.
6. **During an incident, containment beats diagnosis.** Stop the bleeding first; root-cause later. The runbook order is deliberate.

## Operating Procedure

### 1. Classify the request by lifecycle stage

| Stage | User is asking about... | Skill file(s) |
|-------|-------------------------|---------------|
| Threat framing | "what could go wrong in prod", risk model | [threat-model.md](threat-model.md) |
| Pre-mainnet | verified build, security.txt, readiness | [verified-deploy.md](verified-deploy.md) |
| Pre-mainnet | upgrade/mint authority, multisig, timelock | [authority-hardening.md](authority-hardening.md) |
| Design-time | pause switch, guardian, rate limits | [circuit-breakers.md](circuit-breakers.md) |
| Live | monitoring, alerts, detection | [monitoring.md](monitoring.md) |
| **Active incident** | "we're being exploited", "funds draining" | [incident-response.md](incident-response.md) |
| Aftermath | reimbursement, white-hat, post-mortem | [recovery-postmortem.md](recovery-postmortem.md) |

### 2. If an incident is active, STOP routing and open the runbook

If the user's message indicates an **active or suspected live exploit** (funds moving, anomalous withdrawals, "we think we're hacked"), do not deliberate over which file to read. Go straight to [incident-response.md](incident-response.md), spawn the **incident-commander** agent, and follow the runbook top-to-bottom. Containment first.

### 3. Pick the right agent

| Task | Agent | Model |
|------|-------|-------|
| Active incident orchestration | incident-commander | opus |
| Readiness review, hardening, monitoring setup | secops-engineer | sonnet |

### 4. Default to checklists, not prose

Every module ends in a copy-pasteable checklist. When advising, produce the checklist state ("done / missing / N/A"), not a lecture. The [/secops-readiness](../commands/secops-readiness.md) command renders the full scorecard.

### 5. Verify every command before recommending it

CLI surfaces here change (e.g. `solana-verify` deprecated `--remote` in favor of the upload-PDA + `remote submit-job` flow; Squads upgrade authority must point at the **vault** address, not the multisig PDA). When unsure of a current flag, say so and link the source in [resources.md](resources.md) rather than inventing one.

---

## Progressive Disclosure (Read When Needed)

### Operational Security
- [threat-model.md](threat-model.md) — Day-2 threat catalog: key/signer compromise, supply-chain (malicious editor/TestFlight), durable-nonce abuse, governance capture, oracle manipulation in prod
- [verified-deploy.md](verified-deploy.md) — Reproducible builds, `solana-verify`, on-chain verify PDA, OtterSec verification API, `security.txt`, program metadata
- [authority-hardening.md](authority-hardening.md) — Upgrade authority → Squads V4 vault, timelocks, spending limits, immutability decision, token mint/freeze authority, durable-nonce hygiene

### Defense-in-Depth (program design)
- [circuit-breakers.md](circuit-breakers.md) — Pause/guardian/rate-limit patterns, fast-pause/slow-unpause, reference Anchor snippet

### Run & Respond
- [monitoring.md](monitoring.md) — Helius webhooks, what+thresholds to alert on, Hypernative / Range / Riverguard, on-call setup
- [incident-response.md](incident-response.md) — The runbook: detect → pause → war-room → contain → escalate → comms → forensics
- [recovery-postmortem.md](recovery-postmortem.md) — White-hat negotiation, reimbursement, blameless post-mortem

### Reference
- [resources.md](resources.md) — SIRN / SEAL 911 contacts, tools, primary-source links (kept source-of-truth first)

### Templates (copy into the user's repo)
- [SECURITY.txt.template](../templates/SECURITY.txt.template) — on-chain `security.txt` skeleton
- [incident-runbook.md.template](../templates/incident-runbook.md.template) — fill-in runbook to commit to the repo *before* launch
- [war-room.md.template](../templates/war-room.md.template) — live incident log
- [postmortem.md.template](../templates/postmortem.md.template) — blameless post-incident report
- [readiness-scorecard.md.template](../templates/readiness-scorecard.md.template) — Day-2 readiness scorecard
- [monitoring-worker.js](../templates/monitoring-worker.js) — Cloudflare Worker Helius webhook alert handler

---

## Task Routing Guide

| User asks about... | Primary skill file(s) |
|--------------------|-----------------------|
| "Is my deploy verifiable?" | verified-deploy.md |
| Reproducible build mismatch | verified-deploy.md |
| `security.txt` / on-chain contact | verified-deploy.md |
| Move upgrade authority to multisig | authority-hardening.md |
| Squads timelock / spending limits | authority-hardening.md |
| Should I make my program immutable? | authority-hardening.md |
| Mint / freeze authority for my token | authority-hardening.md |
| Durable nonce risk | authority-hardening.md, threat-model.md |
| Add a pause switch / kill switch | circuit-breakers.md |
| Guardian role design | circuit-breakers.md |
| Withdrawal / rate limits | circuit-breakers.md |
| Set up monitoring / alerts | monitoring.md |
| Helius webhooks | monitoring.md |
| Free Solana security monitoring | monitoring.md, resources.md |
| **"We're being exploited right now"** | incident-response.md |
| How do I pause/contain an attack | incident-response.md |
| Who do I call during a hack | incident-response.md, resources.md |
| Flag attacker addresses to exchanges | incident-response.md |
| White-hat / bounty negotiation | recovery-postmortem.md |
| Reimbursement plan | recovery-postmortem.md |
| Post-mortem report | recovery-postmortem.md |
| Pre-launch security checklist | verified-deploy.md → /secops-readiness |
| Program vulnerability classes | solana-dev → security.md, audit skills |

---

## Commands

| Command | Description |
|---------|-------------|
| /secops-readiness | Render the Day-2 readiness scorecard for a repo/program (verified build, authority, pause, monitoring, security.txt, runbook) |
| /setup-monitoring | Scaffold Helius webhook + alert-rule config and an on-call checklist |
| /incident | Launch the incident-response runbook; generate the war-room log and holding statements |

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| **incident-commander** | Orchestrates an active-incident response; walks the runbook, refuses to skip containment, drafts war-room + comms | opus |
| **secops-engineer** | Readiness reviews, authority hardening, verified-deploy setup, monitoring wiring | sonnet |
