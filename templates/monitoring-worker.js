/**
 * Cloudflare Worker for Helius Webhook Monitoring with HMAC Signature Verification
 * 
 * To deploy:
 * 1. Run: npx wrangler deploy
 * 2. Add Secrets to Wrangler:
 *    wrangler secret put HELIUS_WEBHOOK_SECRET
 *    wrangler secret put ALERTS_WEBHOOK_URL
 *    (Optional) wrangler secret put GUARDIAN_KEYPAIR
 */

export default {
  async fetch(request, env, ctx) {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    try {
      const signature = request.headers.get("x-helius-signature");
      if (!signature) {
        return new Response("Unauthorized: Missing signature header", { status: 401 });
      }

      // Read raw body text for signature verification
      const rawBody = await request.text();

      // Verify HMAC-SHA256 signature from Helius
      const isSignatureValid = await verifyHeliusSignature(
        rawBody,
        signature,
        env.HELIUS_WEBHOOK_SECRET
      );

      if (!isSignatureValid) {
        return new Response("Forbidden: Invalid webhook signature", { status: 403 });
      }

      // Parse payload
      const txs = JSON.parse(rawBody);
      if (!Array.isArray(txs)) {
        return new Response("OK", { status: 200 });
      }

      // Process enhanced transactions in background to keep response fast (<100ms)
      ctx.waitUntil(processTransactions(txs, env));

      return new Response("OK", { status: 200 });
    } catch (err) {
      console.error("Error processing webhook:", err);
      return new Response(`Internal Server Error: ${err.message}`, { status: 500 });
    }
  }
};

/**
 * Verifies Helius HMAC-SHA256 webhook signature
 */
async function verifyHeliusSignature(rawBody, headerSignature, secret) {
  if (!secret) {
    console.error("Missing HELIUS_WEBHOOK_SECRET env/secret");
    return false;
  }
  
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"]
  );

  // Convert hex signature header to Uint8Array
  const signatureBytes = new Uint8Array(
    headerSignature.match(/.{1,2}/g).map(byte => parseInt(byte, 16))
  );

  return await crypto.subtle.verify(
    "HMAC",
    key,
    signatureBytes,
    encoder.encode(rawBody)
  );
}

/**
 * Evaluates rules against enhanced transactions
 */
async function processTransactions(txs, env) {
  for (const tx of txs) {
    let alertTriggered = false;
    let severity = "INFO";
    let alertReason = "";

    // 1. Check for Program State / Configuration modification (e.g. Pause/Authority change)
    if (tx.instructions) {
      for (const ix of tx.instructions) {
        // Look for typical administrative instructions matching your program
        if (ix.name === "setPause" || ix.name === "set_pause" || ix.name === "togglePause") {
          alertTriggered = true;
          severity = "SEV-1";
          alertReason = `Pause switch toggled by ${ix.accounts[0]}`;
        }
        if (ix.name === "setUpgradeAuthority" || ix.name === "set_authority") {
          alertTriggered = true;
          severity = "SEV-1";
          alertReason = `Upgrade authority modification proposed/executed. New authority: ${ix.accounts[1]}`;
        }
      }
    }

    // 2. Check for Large Outflows on Configured Vault Addresses
    // Update these addresses to match your program's token vaults
    const WATCHED_VAULTS = ["VaultAddress111111111111111111111111111111"];
    const LARGE_OUTFLOW_THRESHOLD_USD = 50000; // $50,000 USD

    if (tx.tokenTransfers) {
      for (const transfer of tx.tokenTransfers) {
        if (WATCHED_VAULTS.includes(transfer.fromUserAccount)) {
          // Simplistic calculation: token amount * generic multiplier. 
          // For production, resolve actual token price feed or token metadata.
          const transferValueUSD = transfer.tokenAmount; // Adjust decimals
          if (transferValueUSD >= LARGE_OUTFLOW_THRESHOLD_USD) {
            alertTriggered = true;
            severity = "SEV-1";
            alertReason = `Large Token Outflow: Transferred ${transfer.tokenAmount} ${transfer.mint} from vault ($${transferValueUSD} USD equivalent). Tx: ${tx.signature}`;
          }
        }
      }
    }

    // 3. Dispatch alert if triggered
    if (alertTriggered) {
      await sendAlert(env.ALERTS_WEBHOOK_URL, {
        signature: tx.signature,
        timestamp: new Date(tx.timestamp * 1000).toISOString(),
        severity,
        reason: alertReason,
        explorerUrl: `https://solscan.io/tx/${tx.signature}`
      });

      // Optional: If SEV-1 alert, trigger the automated circuit breaker (pause switch)
      // if (severity === "SEV-1" && env.GUARDIAN_KEYPAIR) {
      //   await triggerAutoPause(tx.signature, env);
      // }
    }
  }
}

/**
 * Sends Discord/Slack webhook alert
 */
async function sendAlert(webhookUrl, alertInfo) {
  if (!webhookUrl) {
    console.warn("ALERTS_WEBHOOK_URL not configured");
    return;
  }

  const payload = {
    content: `🚨 **[${alertInfo.severity}] Solana Security Alert** 🚨\n**Reason**: ${alertInfo.reason}\n**Time**: ${alertInfo.timestamp}\n**Tx**: [${alertInfo.signature}](${alertInfo.explorerUrl})`
  };

  await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
}

/**
 * Optional: automated trigger for the guardian pause switch using @solana/web3.js
 */
// async function triggerAutoPause(triggerTx, env) {
//   // Load Web3 SDK dynamically or bundle it in worker package.
//   // Construct transaction calling set_pause(true) signed by GUARDIAN_KEYPAIR.
//   // Submit to Helius RPC and confirm. Log outcome to alert webhook.
// }
