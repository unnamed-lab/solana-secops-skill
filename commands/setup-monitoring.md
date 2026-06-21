---
description: "Scaffold on-chain monitoring for a Solana program: Helius webhook + alert-rule config for outflows, pause/rate-limit events, privileged-instruction and multisig-config changes, plus an on-call checklist."
---

You are scaffolding production monitoring. Read [monitoring.md](../skill/monitoring.md) for the signals and thresholds. Produce: (1) a webhook subscription plan, (2) an alert-rules config the user can drop into their handler, and (3) an on-call checklist. Use the Helius MCP that the Solana AI Kit already ships.

## Step 0: Inputs

Gather: `PROGRAM_ID`, all vault/authority addresses to watch, the multisig (Squads) address, any privileged durable-nonce accounts, oracle accounts (if applicable), and the alert sink (PagerDuty / Telegram / Slack webhook URL).

```bash
echo "Monitoring setup for $PROGRAM_ID"
echo "Watch addresses:"; printf '  - %s\n' "${WATCH_ADDRESSES[@]:-<add vault/authority addresses>}"
```

## Step 1: Webhook subscription (Helius)

Subscribe to the program id and every value-holding / authority address. Prefer enhanced transactions for human-readable payloads. If using the kit's Helius MCP, drive it through Claude; otherwise the REST shape is:

```bash
# Illustrative — confirm current Helius webhook API in resources.md before use.
curl -s -X POST "https://api.helius.xyz/v0/webhooks?api-key=$HELIUS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "webhookURL": "'"$ALERT_HANDLER_URL"'",
    "transactionTypes": ["ANY"],
    "accountAddresses": ['"$(printf '"%s",' "${WATCH_ADDRESSES[@]}" | sed 's/,$//')"'],
    "webhookType": "enhanced"
  }'
```

## Step 2: Alert rules config

Emit a rules file the user's handler evaluates per incoming transaction. Tune thresholds to their TVL.

```json
{
  "rules": [
    { "id": "large-outflow",      "severity": "SEV-1", "when": "outflow_pct_tvl > 5",            "action": "page+warroom" },
    { "id": "outflow-velocity",   "severity": "SEV-1", "when": "outflow_in_window > WINDOW_CAP",  "action": "page+warroom" },
    { "id": "pause-or-ratelimit", "severity": "SEV-1", "when": "event in [PauseToggled, RateLimited]", "action": "page+warroom" },
    { "id": "privileged-ix",      "severity": "SEV-2", "when": "ix in [upgrade, set_authority, set_admin] AND NOT known_multisig_proposal", "action": "page" },
    { "id": "multisig-config",    "severity": "SEV-2", "when": "squads_config_changed",            "action": "page" },
    { "id": "nonce-advance",      "severity": "SEV-2", "when": "privileged_nonce_advanced",        "action": "page" },
    { "id": "new-deploy",         "severity": "SEV-2", "when": "program_upgraded OR buffer_set",   "action": "page" },
    { "id": "oracle-deviation",   "severity": "SEV-2", "when": "price_deviation_pct > 10 OR price_age_sec > 60", "action": "page" },
    { "id": "tvl-drop",           "severity": "SEV-1", "when": "tvl_drop_pct_window > 10",         "action": "page+warroom" },
    { "id": "failed-tx-spike",    "severity": "SEV-3", "when": "failed_tx_rate > baseline * 5",    "action": "notify" }
  ],
  "notes": "Highest-severity rules MAY trigger an automated guardian pause. Gate carefully: a false positive pause is a self-inflicted DoS. Start in alert-only mode, graduate to auto-pause after tuning."
}
```

## Step 3: Handler skeleton (optional — Cloudflare Worker fits; see kit's cloudflare skill)

A minimal handler: receive webhook → evaluate rules → fan out to the alert sink AND the war-room channel → (optionally, for SEV-1) call the guardian pause. Keep the auto-pause behind a feature flag until thresholds are trustworthy.

## Step 4: Free ecosystem tools

Recommend integrating, where eligible: **Hypernative** (threat detection), **Range** (real-time monitoring), **Riverguard** (attack simulation). For larger TVL, point to the Foundation's STRIDE program. Don't rebuild what these provide — layer protocol-specific rules on top. (Links in [resources.md](../skill/resources.md).)

## Step 5: On-call checklist

- [ ] Webhooks live and receiving (fire a synthetic tx to confirm end-to-end)
- [ ] Alert sink reaches a human 24/7 for SEV-1
- [ ] Guardian pause is one command away from on-call
- [ ] War-room channel auto-posts on SEV-1
- [ ] Dashboards for slow signals (TVL, outflow trend)
- [ ] Runbook ([incident-response.md](../skill/incident-response.md)) linked from the alert message
- [ ] Monitoring proven on staging before mainnet

Deliver the subscription plan, the rules file, and the checklist. Flag the single most important missing signal for this protocol.
