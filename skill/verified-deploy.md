# Verified & Reproducible Deployment

Goal: anyone can prove the program running on mainnet was built from your public source, and anyone with a vulnerability can reach you. These are operational security controls, not vanity badges — without them, users can't distinguish your legitimate upgrade from an attacker's, and white-hats can't warn you before going public.

> Tooling here moves. Confirm flags against the source in `resources.md` before running anything destructive. The notes below reflect the `solana-foundation/solana-verifiable-build` (a.k.a. Ellipsis Labs `solana-verify`) workflow current as of mid-2026.

## 1. Reproducible builds with `solana-verify`

A verified build deterministically rebuilds your program in a pinned Docker image and compares the resulting hash to what's on-chain. If they match, the on-chain bytecode provably corresponds to your source at a given commit.

Install:
```bash
cargo install solana-verify
```

Compare a local build to the on-chain program (fast sanity check):
```bash
# hash of your locally built artifact
solana-verify get-executable-hash target/deploy/your_program.so

# hash of the deployed program on a cluster
solana-verify get-program-hash -u <CLUSTER_URL> <PROGRAM_ID>

# the two hashes must match
```

Verify against the public repo and write the verify data on-chain (PDA):
```bash
solana-verify verify-from-repo -u <CLUSTER_URL> \
  --program-id <PROGRAM_ID> \
  https://github.com/<org>/<repo>
```

Trigger the remote (OtterSec-operated) verification job:
```bash
# NOTE: the legacy `--remote` flag on verify-from-repo is deprecated.
# Upload the verify PDA with the program's upgrade authority first, then:
solana-verify remote submit-job \
  --program-id <PROGRAM_ID> \
  --uploader <PUBKEY_THAT_UPLOADED_THE_VERIFY_PDA>
```

The on-chain verify PDA records the program address, git URL, commit hash, and the build arguments — so anyone can re-run verification trustlessly, and explorers (Solana Explorer, SolanaFM) surface the verified status via the OtterSec API.

### Reproducibility gotchas (2026)
- For programs that don't depend on `solana-program` (SDK v3 / Pinocchio), pin the Solana CLI version in the root `Cargo.toml` so the tool selects the right build image; otherwise it falls back to `Cargo.lock`.
- Build images are pinned by digest and installer scripts are checksum-pinned — but post-install toolchain verification is still maturing. Don't treat "verified" as a complete security guarantee; it proves *source = bytecode*, not *source = safe*.
- Commit your `Cargo.lock`. A floating dependency breaks determinism.

## 2. `security.txt` — on-chain contact + audit metadata

Embed a `security.txt` in the program (via `neodyme-labs/solana-security-txt`) so a researcher who finds a bug can reach you *before* disclosing publicly. Missing contact info is how a responsible-disclosure window becomes a public exploit.

Add the dependency and macro:
```rust
use solana_security_txt::security_txt;

security_txt! {
    name: "Your Protocol",
    project_url: "https://yourprotocol.xyz",
    contacts: "email:security@yourprotocol.xyz,link:https://yourprotocol.xyz/security",
    policy: "https://github.com/your-org/your-repo/blob/main/SECURITY.md",
    // optional but recommended:
    preferred_languages: "en",
    source_code: "https://github.com/your-org/your-repo",
    source_release: "v1.2.0",         // a tag that reproduces the binary
    auditors: "Trail of Bits, OtterSec"
}
```
See [SECURITY.txt.template](../templates/SECURITY.txt.template) for a fill-in skeleton and a matching `SECURITY.md` policy stub (including a sane default bounty clause).

## 3. Deploy mechanics that bite in production

- **Devnet first, always.** Never let mainnet be the first place an instruction runs.
- **Priority fees on deploy.** Large-program deploys span many transactions; under load, some land and some don't. Set a priority fee and be ready to resume.
- **Resume a failed deploy** from its buffer rather than restarting (saves SOL and avoids orphaned buffers): use `solana program deploy --buffer <BUFFER>` to continue.
- **Reclaim/secure stale buffers.** Orphaned write-enabled buffers owned by a hot key are an upgrade-vector and waste rent — close them (`solana program close <BUFFER>`).
- **Record the deployment**: program id, commit hash, build args, verify PDA, and the upgrade authority — in the repo, so the readiness scorecard and incident runbook can reference them.

## Checklist

- [ ] `Cargo.lock` committed; build is deterministic
- [ ] On-chain program hash matches locally built hash (`get-program-hash` == `get-executable-hash`)
- [ ] Verify PDA uploaded and remote verification job submitted
- [ ] Verified status visible on an explorer
- [ ] `security.txt` embedded with a monitored contact + `SECURITY.md` policy
- [ ] `source_release` tag reproduces the deployed binary
- [ ] Deployed to devnet before mainnet
- [ ] Stale buffers closed; deployment metadata recorded in-repo
