# Incident Response Runbook

This is the file you open when something is wrong in production. Read top-to-bottom and act in order. **Containment beats diagnosis** — stop the loss first, understand it later.

> If you are reading this for the first time *during* an incident, jump to §1 now. Then come back and, after this is over, commit a filled-in [incident-runbook.md.template](../templates/incident-runbook.md.template) and the contacts from `resources.md` to your repo so next time is faster.

This runbook mirrors what live Solana protocols actually did in 2026 incidents: suspend the protocol, stand up a war room, remove compromised signers, flag attacker addresses to exchanges/bridges, and engage the incident-response network.

## Severity triage (10 seconds)

- **SEV-1** — funds are moving or provably at imminent risk. → Full runbook, immediately.
- **SEV-2** — privileged anomaly (unexpected upgrade, multisig change, suspicious nonce) but no confirmed loss yet. → Pause if in doubt, then investigate.
- **SEV-3** — degraded/suspicious, no value at risk. → Investigate, monitor.

When unsure between SEV-1 and SEV-2: **treat as SEV-1.** A precautionary pause costs you uptime; a missed exploit costs user funds.

## §1. CONTAIN (first minutes)

1. **Pause.** Fire the guardian pause for the affected path (see `circuit-breakers.md`; the `/incident` command surfaces the exact command). If you have no pause switch, go straight to the harshest lever you do have (e.g. multisig-yank an authority, advance a durable nonce, pull liquidity) — and write a post-mortem action item to add a pause switch.
2. **Halt the front-end / deposits.** Take down or banner the dApp to stop new user funds flowing in. Public notice: "investigating unusual activity; do not deposit."
3. **Freeze what you can.** If you hold a freeze authority relevant to the exploited asset, use it. Remove compromised signers from the multisig if signer compromise is suspected.
4. **Invalidate pre-signed transactions.** If a durable-nonce/pre-signed-txn vector is suspected, advance/close the relevant nonce accounts immediately using `solana advance-nonce-account <NONCE_ACCOUNT> --keypair <AUTHORITY>` (see CLI details in [authority-hardening.md](authority-hardening.md)).

Do these in parallel if you have the people. The order above is by leverage if you're solo.

## §2. CONVENE the war room (first ~10 minutes)

5. Open a dedicated, access-controlled channel. Start the [war-room.md.template](../templates/war-room.md.template) log — **timestamp every action and finding**. This log is your post-mortem, your forensic record, and your comms source of truth.
6. Assign roles: **Incident Commander** (decides, owns the runbook), **Comms** (external statements), **Forensics** (on-chain tracing), **Ops** (executes multisig/guardian actions). One person can hold several under duress, but name them explicitly.
7. The `incident-commander` agent can drive this: it walks the runbook, keeps the log, and drafts statements — but a human IC owns every irreversible decision.

## §3. ESCALATE (call for help — you are not alone)

8. **SEAL 911** — the crypto security emergency hotline; reaches whitehat responders fast.
9. **Solana Incident Response Network (SIRN)** — the Foundation's membership network of security firms (Asymmetric Research, OtterSec, Neodyme, Squads, ZeroShadow) for coordinated, round-the-clock response. If you're STRIDE-covered, your monitoring partner is already a contact.
10. **Your auditor** and, for serious losses, an incident-forensics firm (Mandiant-class).
11. **Exchanges & bridges** — flag attacker addresses to major CEXes and bridge operators to freeze/slow off-ramping. Provide addresses + tx signatures. SEAL/SIRN can amplify and route these.

Have these contacts saved *before* the incident (`resources.md`); searching for the hotline mid-drain wastes the minutes that matter.

## §4. CONTAIN further / trace (next hour)

12. **Trace the flow.** Map attacker addresses, amounts, and routes (use Helius enhanced transactions / DAS; explorers; tracing partners). Maintain the address list in the war-room log.
13. **Identify the vector** enough to be sure your pause actually stopped it. If the exploit can route around your pause, widen the pause (global) — do not assume.
14. **Preserve evidence.** Do not wipe logs, Telegram/Discord history, or compromised machines; forensics needs them. (Attackers often scrub their own trail at execution — yours is what's left.)

## §5. COMMUNICATE

15. **Acknowledge fast, commit to nothing you don't know.** First statement: we're aware, we've paused X, do not deposit, more soon. Use the holding statement the `incident-commander` drafts; don't speculate on cause or amounts.
16. **Cadence.** Regular updates even when the update is "still investigating." Silence breeds panic and rumor.
17. **Coordinate disclosure** with responders — premature technical detail can help copycats or tip off the attacker about your containment.

## §6. STABILIZE → hand off to recovery

18. Once the loss is stopped and traced, you are out of the acute phase. Move to `recovery-postmortem.md` for white-hat negotiation, reimbursement strategy, and the blameless post-mortem.
19. **Do not unpause** until you've confirmed the vector is closed (often requires a fix + re-audit) and the full multisig agrees. Unpausing into an open hole is a second incident.

## Anti-patterns (do NOT)

- Don't diagnose before containing. Every minute of root-causing while funds drain is pure loss.
- Don't act solo on irreversible calls if you can avoid it — but don't wait for perfect consensus to *pause*.
- Don't make promises ("all funds are safe", "we'll reimburse 100%") before you know.
- Don't delete evidence in a panic.
- Don't unpause early to "restore confidence."

## Quick command reference

The `/incident` command generates a fresh war-room log, fills the holding statement, and prints the exact pause/contain commands for *your* configured guardian + multisig. Run it first thing.

## Pre-incident checklist (do this BEFORE you ever need this file)

- [ ] Pause switch exists and the exact command is in the runbook
- [ ] Guardian key holder reachable 24/7
- [ ] Filled-in incident-runbook committed to the repo
- [ ] SEAL 911 + SIRN + auditor contacts saved and reachable
- [ ] War-room channel + roles pre-agreed
- [ ] Front-end take-down/banner procedure documented
- [ ] A tabletop drill run at least once (simulate a SEV-1)
