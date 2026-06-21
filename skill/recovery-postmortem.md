# Recovery & Post-Mortem

The acute phase is over: the loss is stopped and traced. This file covers getting funds back where possible, making users whole, and turning the incident into durable improvements.

## 1. White-hat / fund-recovery negotiation

A large share of stolen crypto is recovered through negotiation, not law enforcement. Often the fastest path to returning user funds is to offer the attacker a white-hat bounty to return the rest.

- **Make a public, time-boxed offer**: keep an agreed percentage (commonly up to ~10% of value at risk — pre-state this in your `SECURITY.md` bounty policy) as a white-hat bounty; return the remainder by a deadline, after which full resources go to pursuit.
- **Communicate on-chain** (a signed message / transaction memo to the attacker address) and publicly, so the offer is verifiable.
- **Coordinate with responders** (SEAL/SIRN) and any forensics firm — they've run these negotiations before and can broker.
- **Keep exchanges/bridges in the loop**; pressure on off-ramps improves your negotiating position.

## 2. Reimbursement strategy

Decide and communicate how (or whether) users are made whole. Options, often combined:
- Treasury/insurance-fund reimbursement.
- Recovered funds distributed pro-rata.
- A governance-approved recovery token / claim against future revenue.
- Negotiated white-hat return passed through to users.

Be precise and honest about amounts and timelines. Over-promising during the incident (§5 of the runbook warned against this) is how a security incident becomes a trust *and* legal incident.

## 3. Root-cause analysis

With evidence preserved (war-room log, on-chain trace, compromised-host images), establish the actual vector:
- Was it code, key/signer, supply chain, governance, or oracle? (Map back to `threat-model.md`.)
- For key/supply-chain compromise (the 2026 norm), the RCA spans *off-chain*: which device, which dependency, which human path. On-chain forensics alone will miss it — Drift's RCA centered on contributor devices and a malicious editor/TestFlight vector, not the contracts.
- Engage your auditor/forensics firm for an independent read.

## 4. Blameless post-mortem

Write it, publish it (appropriately), and act on it. Use [postmortem.md.template](../templates/postmortem.md.template). A good post-mortem:
- Is **blameless** — focuses on systems and gaps, not individuals. People cooperate with forensics when they're not being hunted.
- Has a precise timeline (straight from the war-room log).
- Lists concrete, owned, dated action items — each tied to a control in this skill (add pause switch, add timelock, isolate signing env, add monitoring rule, etc.).
- Is published once disclosure is safe; transparency rebuilds trust and helps the ecosystem (this is how the rest of us learned the Drift vector).

## 5. Safe restart

- **Fix → re-audit → verify → unpause**, in that order, with full-multisig sign-off.
- Re-run the [/secops-readiness](../commands/secops-readiness.md) scorecard; the incident almost certainly exposed missing controls — close them before resuming.
- Re-deploy with a verified build (`verified-deploy.md`) so users can confirm the fixed bytecode.
- Rotate every key that could have been exposed.

## Checklist

- [ ] White-hat offer made (if applicable), time-boxed, publicly verifiable
- [ ] Responders/forensics engaged for negotiation + RCA
- [ ] Reimbursement plan decided and communicated honestly
- [ ] Root cause established across on-chain **and** off-chain surfaces
- [ ] Blameless post-mortem published with owned, dated action items
- [ ] Every action item mapped to a control in this skill
- [ ] Fix re-audited, re-verified, keys rotated
- [ ] Readiness scorecard re-run and green before unpause
- [ ] Full-multisig sign-off on restart
