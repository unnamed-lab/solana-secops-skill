# Authority Hardening

Every privileged key over a live program is an attack surface (see `threat-model.md` §1, §3). This file is the policy layer: which authorities exist, who should hold them, and how to make malicious use slow and visible. It scopes *what to do and why*; for raw Squads SDK/CLI calls, defer to the Squads docs in `resources.md`.

## The authorities you must inventory

| Authority | Controls | If compromised |
|-----------|----------|----------------|
| Program upgrade authority | Replacing program bytecode | Attacker ships malicious program |
| Token mint authority | Creating new supply | Infinite mint / dilution |
| Token freeze authority | Freezing holder accounts | Censorship / lockup |
| Metadata update authority | Token/NFT metadata | Spoofing, phishing |
| Protocol admin / config | Fees, params, oracle sources | Parameter attack, drain |
| Guardian / pause authority | Emergency pause | (Designed to be reachable — see below) |

List each, find who holds it today, and move it to the right home below.

## 1. Move upgrade authority to a multisig

Squads V4 is the de-facto standard (secures >$10B; formally verified; supports timelocks, spending limits, roles, sub-accounts).

Transfer upgrade authority to the Squads **vault** address:
```bash
# CRITICAL: the new authority is the Squads VAULT address (the PDA that holds
# assets/authority), NOT the multisig account/config PDA. Passing the wrong one
# is a common, hard-to-undo footgun.
solana program set-upgrade-authority <PROGRAM_ID> \
  --new-upgrade-authority <SQUADS_VAULT_ADDRESS>
```

For CI-driven upgrades through the multisig, use the official action `Squads-Protocol/squads-v4-program-upgrade` (initializes the upgrade as a multisig proposal from your pipeline) instead of handing a deploy key to a human.

## 2. Add a timelock

A timelock inserts a delay between proposing a privileged action and executing it. This is the single most important governance control: it turns a silent malicious upgrade into a **visible, vetoable** event, and it's what monitoring watches for.

- Set the timelock on the Squads multisig config to a window long enough for your team + community to react (commonly hours to a few days, sized to your risk).
- The timelock should cover upgrades and authority/param changes — the slow, dangerous path.
- The **pause** path is the deliberate exception: it must be *fast* (see `circuit-breakers.md`). Don't timelock the kill switch.

## 3. Spending limits & roles

- **Spending limits**: let routine, small operational transfers happen without full threshold, while anything large requires full approval. Reduces signing fatigue without widening blast radius.
- **Roles**: separate proposer / voter / executor. The machine that *proposes* from CI should not also be able to single-handedly *execute*.

## 4. Token authority handling

- A token whose mint authority is a single hot key is a rug waiting to happen — hold it in the multisig (or burn it / set to `None` if supply is fixed).
- Decide explicitly on freeze authority: holding it enables censorship/compliance actions but is itself a liability; many fixed-supply tokens set it to `None`.
- Metadata update authority on the multisig prevents metadata-spoofing phishing.

## 5. Durable-nonce hygiene

Durable nonces enable valid-forever pre-signed transactions — the Drift execution mechanism. If your ops use nonce accounts:
- Inventory every nonce account tied to a privileged signer.
- Monitor them (see `monitoring.md`); an unexplained advance or a pre-signed txn against one is a red flag.
- Advancing/closing a nonce invalidates anything pre-signed against it — a containment lever during an incident.

## 6. The immutability decision

Making a program immutable (set upgrade authority to `None`) removes the upgrade attack surface entirely — but also removes your ability to patch. This is a real trade-off, not a default.

| Choose immutable when | Keep upgradeable (timelocked multisig) when |
|-----------------------|----------------------------------------------|
| Program is small, audited, formally verified, and stable | Protocol is evolving, integrates external systems |
| Logic is final (e.g. a token, a simple vault) | You need to patch oracle/param/feature logic |
| Maximum trust signal matters | You can defend the upgrade key well |

If upgradeable, the upgrade key **must** be a timelocked multisig. "Upgradeable + single hot key" is the worst of both worlds.

## Checklist

- [ ] Every privileged authority inventoried with current holder
- [ ] Upgrade authority on a Squads **vault** (not the multisig PDA) — or intentionally `None`
- [ ] Timelock set on upgrades/param changes (pause path intentionally exempt)
- [ ] Multisig signers cold, independent, geographically distributed
- [ ] Roles separated (CI proposes; humans execute)
- [ ] Mint authority in multisig or `None`; freeze authority decision documented
- [ ] Metadata update authority in multisig
- [ ] Privileged nonce accounts inventoried + monitored
- [ ] Immutability decision made and written down
