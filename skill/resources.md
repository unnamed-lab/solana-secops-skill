# Resources (Source-of-Truth First)

Primary sources only. When a CLI flag or contact here looks stale, the linked source wins over this file — verify before running destructive commands.

## Emergency contacts (save these BEFORE an incident)

- **SEAL 911** — crypto security emergency hotline / whitehat responder network: https://securityalliance.org (SEAL 911 Telegram bot linked there)
- **Solana Incident Response Network (SIRN)** — Foundation incident-response network (Asymmetric Research, OtterSec, Neodyme, Squads, ZeroShadow): https://solana.com/news/solana-ecosystem-security
- **Solana Foundation security overview (STRIDE + SIRN + free tools)**: https://solana.com/news/solana-ecosystem-security

## Verified / reproducible builds

- solana-verify (Solana Foundation): https://github.com/solana-foundation/solana-verifiable-build
- solana-verify (Ellipsis Labs upstream): https://github.com/Ellipsis-Labs/solana-verifiable-build
- Verified builds guide (official docs): https://solana.com/docs/programs/verified-builds
- security.txt for Solana programs (Neodyme): https://github.com/neodyme-labs/solana-security-txt

## Authority / multisig

- Squads V4 program + SDKs: https://github.com/Squads-Protocol/v4
- Squads docs: https://docs.squads.so
- Squads V4 program-upgrade GitHub Action: https://github.com/Squads-Protocol/squads-v4-program-upgrade
- Solana CLI program authority docs: https://solana.com/docs/programs/deploying

## Monitoring & detection

- Helius (RPC, DAS, webhooks, enhanced txns) — already in the kit's MCP: https://www.helius.dev
- Hypernative (ecosystem threat detection, free to eligible projects): https://www.hypernative.io
- Range Security (real-time monitoring): https://www.range.org
- Neodyme Riverguard (attack simulation): https://neodyme.io

## Program security (defer code-level audits here)

- Solana program security best practices: https://solana.com/docs/programs/security
- Helius "Hitchhiker's Guide to Solana Program Security": https://www.helius.dev/blog/a-hitchhikers-guide-to-solana-program-security
- (In-kit) Trail of Bits, Ghost Security, safe-solana-builder, QEDGen formal verification skills

## Incident references / learning

- Solana hacks history (Helius): https://www.helius.dev/blog/solana-hacks
- Solana network status / incident history: https://status.solana.com/history

## Related skills in the kit

- `solana-dev-skill` (core program/client/security patterns): https://github.com/solana-foundation/solana-dev-skill
- This skill **extends** the kit's pre-launch security coverage into Day-2 operations; it does not duplicate code-level audit content.
