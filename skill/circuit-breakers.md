# Circuit Breakers (Pause / Guardian / Rate Limits)

This is the one Day-2 control that must be built into the **program at design time**. You cannot bolt on a pause switch during an incident. If you ship without one, your only lever during an exploit is a timelocked upgrade — far too slow while funds drain.

The 2026 audit standard explicitly checks for this: "is there a functional multisig with a timelocked **pause** mechanism?" This file shows the pattern; wire it in before launch.

## Principle: fast to pause, slow to unpause

| Action | Who | Speed | Why |
|--------|-----|-------|-----|
| **Pause** | a single `guardian` key | Immediate, no timelock | During an exploit, seconds matter. One trusted signer must be able to stop the bleeding. |
| **Unpause** | full multisig | Slow, deliberate | Resuming a protocol mid-incident is high-stakes; it needs consensus. |
| **Upgrade** | full multisig + timelock | Slowest | Code change is the most dangerous action. |

A guardian that can *only pause* (never move funds, never upgrade) is low-risk to keep "hot" — a compromised guardian can at worst cause a denial-of-service (an unwarranted pause), not a loss. That asymmetry is the whole design.

## What to make pausable

- All value-moving instructions (deposit, withdraw, swap, borrow, liquidate, claim).
- Prefer **fine-grained** flags (pause withdrawals independently of deposits) so you can halt the exploited path without freezing everything.
- Leave genuinely safe read-only paths unpaused.

## Reference pattern (Anchor)

> Illustrative reference, not a drop-in library. Adapt names/space to your program and test under LiteSVM/Mollusk (see `solana-dev-skill` → testing). The point is the *shape*: a config gate, a guardian-only pause, a multisig-only unpause.

```rust
use anchor_lang::prelude::*;

#[account]
pub struct ProtocolConfig {
    pub admin: Pubkey,        // the multisig vault (Squads): unpause, config, upgrades
    pub guardian: Pubkey,     // low-privilege hot key: can ONLY pause
    pub paused: bool,         // global kill switch
    pub withdrawals_paused: bool, // fine-grained example
    pub bump: u8,
}

#[error_code]
pub enum SecError {
    #[msg("Protocol is paused")]
    Paused,
    #[msg("Withdrawals are paused")]
    WithdrawalsPaused,
    #[msg("Unauthorized")]
    Unauthorized,
}

// Guardian OR admin can pause. Fast path, no timelock.
pub fn set_pause(ctx: Context<SetPause>, paused: bool) -> Result<()> {
    let cfg = &mut ctx.accounts.config;
    let signer = ctx.accounts.authority.key();
    require!(
        signer == cfg.guardian || signer == cfg.admin,
        SecError::Unauthorized
    );
    cfg.paused = paused;
    emit!(PauseToggled { paused, by: signer });
    Ok(())
}

// Only admin (the multisig) can clear withdrawal pause. Slow, deliberate path.
pub fn set_withdrawals_paused(ctx: Context<AdminOnly>, paused: bool) -> Result<()> {
    require!(
        ctx.accounts.authority.key() == ctx.accounts.config.admin,
        SecError::Unauthorized
    );
    ctx.accounts.config.withdrawals_paused = paused;
    Ok(())
}

// Gate every value-moving instruction at the top.
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    let cfg = &ctx.accounts.config;
    require!(!cfg.paused, SecError::Paused);
    require!(!cfg.withdrawals_paused, SecError::WithdrawalsPaused);
    // ... rate-limit check (below) ...
    // ... withdrawal logic ...
    Ok(())
}

#[event]
pub struct PauseToggled { pub paused: bool, pub by: Pubkey }
```

The matching `#[derive(Accounts)]` contexts load `ProtocolConfig` (typically a PDA) and a `Signer` `authority`; keep `admin` pointed at the Squads vault and `guardian` at the low-privilege hot key.

## Rate limits & withdrawal caps

A pause stops everything; a rate limit bounds the damage *before* anyone notices. Cap value-out per window so a single manipulated tick or a slow drain can't exceed a threshold without tripping.

Pattern: store `window_start: i64`, `window_outflow: u64`, `window_cap: u64` in config (or per-vault). On each outflow:
1. If `now - window_start > WINDOW`, reset `window_start = now`, `window_outflow = 0`.
2. `window_outflow = window_outflow.checked_add(amount).ok_or(overflow)?`.
3. `require!(window_outflow <= window_cap, RateLimited)`.

Tie an alert (see `monitoring.md`) to the rate-limit event so a trip pages on-call even if it didn't fully stop the attack.

## Guardian-key operations

- Guardian is a hot key by design — keep it on a monitored, isolated signer.
- Put the guardian pause action behind a one-command runbook entry (see `incident-response.md` and `/incident`) so anyone on-call can fire it under pressure without fumbling CLI syntax.
- Rotate the guardian key on contributor turnover.

## Checklist

- [ ] Config account holds `admin` (multisig vault) and `guardian` (low-priv hot key)
- [ ] Global `paused` flag gates all value-moving instructions
- [ ] Fine-grained pause for high-risk paths (e.g. withdrawals)
- [ ] Guardian can pause but cannot move funds or upgrade
- [ ] Unpause requires the full multisig (no timelock-bypass)
- [ ] Per-window outflow rate limit with overflow-checked math
- [ ] Pause + rate-limit events emitted and wired to alerts
- [ ] One-command pause documented in the incident runbook
- [ ] Pause path covered by LiteSVM/Mollusk tests
