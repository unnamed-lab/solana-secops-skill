---
globs:
  - "**/*.rs"
exclude:
  - "**/target/**"
---

# Operational-Safety Rules for Solana Programs

These rules are the Day-2 complement to the kit's `rust.md` code-style rules. They exist so a program is *operable and defensible in production*, not just correct. When writing or reviewing a value-handling Solana program, enforce the following. Full rationale: [circuit-breakers.md](../skill/circuit-breakers.md), [authority-hardening.md](../skill/authority-hardening.md).

## 1. Every value-moving instruction must be pausable

Any instruction that moves tokens/SOL or changes balances (deposit, withdraw, swap, borrow, claim, liquidate) must check a pause flag at the top.

```rust
require!(!ctx.accounts.config.paused, SecError::Paused);
// fine-grained where it helps:
require!(!ctx.accounts.config.withdrawals_paused, SecError::WithdrawalsPaused);
```

A program that cannot be paused cannot be defended during an incident. Flag the absence of a pause gate on value-moving instructions as a launch blocker, not a style nit.

## 2. Separate `guardian` (pause) from `admin` (everything else)

- `admin` = the multisig vault (Squads): upgrades, config, unpause.
- `guardian` = a low-privilege key that can **only** pause.
- A compromised guardian must be capable of at most a denial-of-service (an unwanted pause), never a loss. Never give the guardian fund-moving or upgrade power.

## 3. Explicit authority checks, fast-pause / slow-unpause

- Pausing: allow `guardian` OR `admin`, no timelock.
- Unpausing and any config/authority change: `admin` only (and behind the multisig timelock off-chain).

```rust
require!(signer == cfg.guardian || signer == cfg.admin, SecError::Unauthorized); // pause
require!(signer == cfg.admin, SecError::Unauthorized);                            // unpause/config
```

## 4. Rate-limit / cap outflows with checked math

Bound value-out per time window so one bad tick can't drain the protocol. Always use checked arithmetic (overflow is silent in release builds).

```rust
cfg.window_outflow = cfg.window_outflow.checked_add(amount).ok_or(SecError::Overflow)?;
require!(cfg.window_outflow <= cfg.window_cap, SecError::RateLimited);
```

## 5. Emit events for everything monitorable

Pause toggles, rate-limit trips, and privileged actions must emit events so off-chain monitoring (`monitoring.md`) can alert on them.

```rust
emit!(PauseToggled { paused, by: signer });
```

## 6. Don't ship a single-key authority

Authority over upgrades, mint, or freeze must resolve to a multisig (or be `None`). A hardcoded single-pubkey admin in a value-handling program is a finding — recommend Squads + timelock.

---

When reviewing a diff that touches these areas and a control is missing, say so plainly and point to the relevant skill file. These are operational blockers, and catching them at code-review time is far cheaper than catching them at incident time.
