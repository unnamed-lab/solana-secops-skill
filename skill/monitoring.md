# Monitoring & Detection

You cannot respond to what you cannot see. Monitoring must be live **before** mainnet, not stood up after the first incident. This file: what to watch, at what threshold, and how to wire it using infra the Solana AI Kit already ships (the Helius MCP) plus the free ecosystem tools.

> Honest limit: monitoring catches *anomalous on-chain activity*. It did **not** catch Drift, because those transactions were valid by design. Monitoring is necessary, not sufficient — pair it with circuit breakers and authority hardening.

## What to monitor (by priority)

| Signal | Why it matters | Alert threshold (tune to your protocol) |
|--------|----------------|------------------------------------------|
| Large / fast outflows from program vaults | The direct exploit signature | Single tx > X% of TVL, or outflow velocity > N/window |
| Rate-limit / pause events emitted | Your own circuit breaker tripped | Any occurrence → page immediately |
| Privileged instruction calls (upgrade, set-authority, set-admin) | Authority abuse / malicious upgrade | Any occurrence not matching a known multisig proposal |
| Multisig config changes (signers, threshold, timelock) | Signer-set tampering | Any change → page |
| Durable-nonce account advances on privileged nonces | Pre-signed-txn execution (Drift vector) | Any unexplained advance |
| New program upgrade / buffer set on your program id | Unexpected deploy | Any occurrence |
| Oracle price deviation / staleness | Manipulation precursor | Deviation > X% or age > Y sec |
| TVL drop velocity | Aggregate exploit indicator | Drop > X% in window |
| Failed-tx spikes on your program | Probing / griefing | Rate > baseline × N |

## Wiring it with Helius (already in the kit's MCP)

The kit ships the Helius MCP (RPC, DAS, webhooks, priority fees, enhanced transactions). Use it to:
- **Webhooks**: subscribe to your program id and vault addresses; route enhanced-transaction payloads to an endpoint that evaluates the thresholds above and pages on-call.
- **Enhanced transactions**: human-readable parsing so an alert says "withdraw 1.2M USDC from vault" not a raw blob.
- **Priority-fee data**: detect fee spikes that often accompany an attack landing.

See [/setup-monitoring](../commands/setup-monitoring.md) to scaffold a webhook + alert-rule config and an on-call checklist.

Minimal alerting loop (shape, not a product):
1. Helius webhook → your handler (a Cloudflare Worker fits; see the kit's `cloudflare` skill).
   > [!IMPORTANT]
   > **Webhook Signature Verification**: You MUST verify the `X-Helius-Signature` header (HMAC-SHA256) on your webhook endpoint using your Helius Webhook Secret. Without verification, anyone can trigger spoofed alerts or DOS your protocol via the auto-pause handler. See the complete, secure template in [monitoring-worker.js](../templates/monitoring-worker.js).
2. Handler evaluates rules → on trip, fan out to PagerDuty/Telegram/Slack **and** post into the war-room channel.
3. The same handler can be authorized to call the guardian **pause** for the highest-severity rules (auto-circuit-breaker) — gate this carefully; a false positive that pauses the protocol is a DoS you did to yourself.

## Free ecosystem tools (use them; they're funded)

As of 2026 the Solana Foundation makes several monitoring/defense tools available to ecosystem projects at no cost:
- **Hypernative** — ecosystem-wide threat detection; can flag and help prevent malicious transactions before they execute.
- **Range Security** — real-time monitoring.
- **Neodyme Riverguard** — attack simulation / pre-incident pressure-testing.

For larger protocols, the Foundation's STRIDE program adds funded opsec + active threat monitoring (TVL-gated). Don't rebuild what these give you — integrate them and add protocol-specific rules on top.

## On-call basics

- Define severities (SEV-1 = funds at risk/draining; SEV-2 = privileged anomaly; SEV-3 = degraded).
- A real human reachable 24/7 for SEV-1, with the guardian pause one command away.
- Test the alert path end-to-end (fire a synthetic event) — an alert nobody receives is worse than none because it breeds false confidence.
- Keep dashboards for the slow signals (TVL, outflow trend) and pages for the fast ones.

## Checklist

- [ ] Webhooks subscribed to program id + all vault/authority addresses
- [ ] Alert rules defined for every high-priority signal with tuned thresholds
- [ ] Pause/rate-limit events page immediately
- [ ] Privileged-instruction + multisig-config changes page immediately
- [ ] Privileged durable-nonce accounts monitored
- [ ] Oracle deviation/staleness monitored (if applicable)
- [ ] Hypernative / Range / Riverguard integrated where eligible
- [ ] 24/7 on-call with one-command guardian pause
- [ ] Alert path tested end-to-end with a synthetic event
- [ ] Monitoring live on devnet/staging before mainnet
