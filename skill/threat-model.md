# Day-2 Threat Model

The audit covered the bytecode. This file covers everything the bytecode can't: keys, humans, infrastructure, and governance. These are the vectors that actually drained Solana protocols in 2025–2026.

> **Mental model**: an attacker who can't find a bug in your program will attack the *authority* over your program (signers, upgrade key) or the *humans* who hold it. In 2026 this is the dominant path, not a fallback.

## 1. Signer / key compromise (highest priority)

The April 2026 Drift exploit is the canonical case: audited contracts, but attackers ran a ~6-month social-engineering campaign, compromised contributor devices, obtained multisig approvals, locked them into **durable-nonce transactions**, and executed weeks later. No on-chain monitor flagged it because the transactions were valid by design.

What to enforce:
- **No single-key authority over value or upgrades.** Ever. Use a multisig (see `authority-hardening.md`).
- **Cold signers.** Multisig signers should be hardware/cold wallets, geographically distributed, not on the same machine that has your build toolchain.
- **Durable-nonce awareness.** A pre-signed durable-nonce transaction is a time-bomb: valid until the nonce advances. Treat any unexplained nonce account tied to a privileged signer as hostile. Rotating/advancing the nonce invalidates pre-signed txns.
- **Threshold discipline.** A 2-of-3 where two keys live on the same compromised laptop is a 1-of-1. Count *independent* signers, not keys.

## 2. Supply-chain / developer-environment compromise

Drift's entry point was developer tooling: a malicious code repository plus a fake TestFlight app, exploiting a known arbitrary-code-execution window in VSCode/Cursor-class editors (Dec 2025–Feb 2026). The Web3.js npm compromise (2024) and the Parcl front-end attack are the same family.

What to enforce:
- **Pin and verify dependencies.** Lockfiles committed; no floating versions on anything that touches signing or deploys. (Defer SCA/secrets scanning to the kit's Ghost Security / Trail of Bits skills — this skill flags *that you must*, those skills do the scan.)
- **Isolate the signing environment** from the dev environment. The machine that holds a deploy key should not run untrusted editor extensions or install random TestFlight builds.
- **CI provenance.** Deploys/upgrades should run from a known CI path (e.g. the Squads program-upgrade GitHub Action) with a checksum-pinned toolchain, not an engineer's laptop.
- **Front-end integrity.** Your dApp front-end is in scope: SRI on scripts, locked build pipeline, alerting on unexpected bundle changes.

## 3. Upgrade-authority abuse

A live upgradeable program is only as safe as its upgrade authority. An attacker (or a malicious insider) who controls it can replace your audited program with anything.

What to enforce:
- Upgrade authority on a multisig **vault** with a timelock (so a malicious upgrade is visible and vetoable before it lands).
- Buffer-account hygiene: a stale write-enabled buffer owned by a hot key is an upgrade vector.
- A documented decision on eventual immutability. See `authority-hardening.md`.

## 4. Governance capture

For DAO-governed protocols: flash-loaned voting power, low-quorum proposals, or a malicious proposal that quietly changes an authority. The Mango Markets case showed governance and oracle manipulation can compound.

What to enforce:
- Proposal timelocks and execution delays.
- Quorum and vote-escrow that can't be flash-borrowed.
- Privileged parameter changes (fees, oracles, authorities) gated behind the slowest path.

## 5. Oracle / price-feed manipulation in production

Not a code bug per se — a live integration risk. Thin-liquidity markets, single-source feeds, or stale prices let an attacker move a price and drain a lending/perp protocol.

What to enforce:
- Multiple independent feeds with deviation + staleness checks (defer feed wiring to `sendai` oracle skills).
- Circuit breakers that trip on abnormal price moves (see `circuit-breakers.md`).
- Per-block / per-window caps on size so a single manipulated tick can't drain the pool.

## 6. Operational blind spots

You can't respond to what you can't see, and you can't recover what you didn't plan for.

What to enforce:
- Monitoring + alerting live *before* mainnet, not after the first incident (`monitoring.md`).
- An incident runbook committed to the repo *before* launch (`incident-response.md`, templates).
- Known contacts (SIRN, SEAL 911) saved *before* you need them (`resources.md`).

## Threat → control map

| Threat | Primary control | File |
|--------|-----------------|------|
| Single-key/signer compromise | Multisig + cold + distributed signers | authority-hardening.md |
| Durable-nonce time-bomb | Nonce hygiene, monitor privileged nonces | authority-hardening.md, monitoring.md |
| Malicious editor / supply chain | Isolated signing env, CI provenance, SCA (audit skills) | threat-model.md, audit skills |
| Malicious upgrade | Timelocked multisig upgrade authority | authority-hardening.md |
| Governance capture | Proposal timelocks, flash-loan-resistant quorum | authority-hardening.md |
| Oracle manipulation | Multi-feed + deviation/staleness + caps | circuit-breakers.md, sendai |
| Can't see the attack | Monitoring + alerts pre-launch | monitoring.md |
| Can't stop the attack | In-program pause switch | circuit-breakers.md |
| Can't recover | Runbook + contacts committed pre-launch | incident-response.md |

## Checklist

- [ ] No single key controls value, upgrades, or mint/freeze
- [ ] Multisig signers are cold, independent, and geographically distributed
- [ ] Signing environment is isolated from the dev/build environment
- [ ] Privileged nonce accounts are inventoried and monitored
- [ ] Upgrade authority is timelocked (or program is intentionally immutable)
- [ ] Governance has proposal timelocks and flash-loan-resistant quorum
- [ ] Oracle integrations have multi-feed + deviation + staleness guards
- [ ] Monitoring, runbook, and emergency contacts exist **before** mainnet
