---
description: "Launch the incident-response runbook for a live/suspected Solana exploit: triage, generate the war-room log, print the exact pause/contain commands for the configured guardian + multisig, and draft a holding statement."
---

An incident may be active. **Move fast and contain first.** Spawn the **incident-commander** agent and follow [incident-response.md](../skill/incident-response.md) in order. This command sets up the scaffolding so the team can act, not read.

> If funds are moving, do NOT wait to finish reading. Execute Step 2 (pause) immediately, then continue.

## Step 1: Triage (one line)

Classify: **SEV-1** (funds moving / imminent risk), **SEV-2** (privileged anomaly, no confirmed loss), **SEV-3** (suspicious, no value at risk). If torn between SEV-1 and SEV-2 → **SEV-1**.

```bash
echo "INCIDENT — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Severity: ${SEV:-SEV-1}"
echo "Program: ${PROGRAM_ID:-<unset>}  Cluster: ${CLUSTER:-mainnet-beta}"
```

## Step 2: CONTAIN — print the exact pause command

Surface the real lever for this protocol. Fill in the guardian/multisig specifics; do not output a generic instruction.

```bash
# If a guardian pause instruction exists, this is the fastest lever.
# Replace with the protocol's actual pause invocation (Anchor/native client call).
echo ">>> FIRE GUARDIAN PAUSE NOW (fast path, single guardian key):"
echo "    <your-cli> pause --program $PROGRAM_ID --authority \$GUARDIAN_KEYPAIR --paused true"
echo ""
echo ">>> If NO pause switch exists, use the harshest lever you have:"
echo "    - Squads: propose+execute emergency authority change / param halt"
echo "    - Advance/close privileged durable-nonce accounts: solana advance-nonce-account <NONCE_ACCOUNT_ADDRESS> --keypair <AUTHORITY>"
echo "    - Pull liquidity / freeze (if you hold freeze authority)"
echo ""
echo ">>> Take down or banner the front-end. Public notice: investigating, DO NOT deposit."
```

## Step 3: CONVENE — generate the war-room log

Create a timestamped log from [war-room.md.template](../templates/war-room.md.template). Assign Incident Commander / Comms / Forensics / Ops.

```bash
TS=$(date -u +%Y%m%d-%H%M%S)
LOG="war-room-${TS}.md"
cp "$(dirname "$0")/../templates/war-room.md.template" "$LOG" 2>/dev/null || \
  echo "# War Room $TS" > "$LOG"
echo "Created $LOG — timestamp EVERY action and finding here."
```

## Step 4: ESCALATE — contacts to message right now

Print from [resources.md](../skill/resources.md):
- **SEAL 911** (whitehat emergency responders)
- **SIRN** (Foundation incident-response network)
- Your **auditor** + a forensics firm for serious losses
- **Exchanges/bridges**: flag attacker addresses + tx signatures to freeze off-ramps

## Step 5: TRACE

Use Helius enhanced transactions / DAS and explorers to map attacker addresses, amounts, routes. Keep the address list in the war-room log. **Preserve evidence** — do not wipe logs, chat history, or machines.

## Step 6: COMMUNICATE — draft holding statement

Generate a first statement that says only what's known: aware, paused X, do not deposit, updates to follow. No cause, no amounts, no "funds are safe" promises.

```
We are aware of unusual activity affecting <protocol> and have paused <affected functions>
as a precaution. Please do not deposit. We are coordinating with security partners and will
post updates as we learn more.
```

## Step 7: STABILIZE → hand off

Once the loss is stopped and traced, move to [recovery-postmortem.md](../skill/recovery-postmortem.md). **Do not unpause** until the vector is confirmed closed and the full multisig agrees. Then run [/secops-readiness](secops-readiness.md) to close the gaps this incident exposed.

Remember: containment before diagnosis; a human approves every irreversible action; promise nothing you can't verify.
