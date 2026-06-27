# litellm-gateway

Self-hosted [LiteLLM](https://github.com/BerriAI/litellm) AI gateway that lets a small
group share **one** upstream Claude key (the `cc.freemodel.dev` reseller) without anyone
seeing the real key. Each peer gets their own revocable key with a budget and rate limits;
you get an admin dashboard with per-person usage.

```
Peer's Claude Code ──(their virtual key)──▶ LiteLLM on Render ──(real key)──▶ cc.freemodel.dev
                                                  │
                                                  ▼  Postgres: keys, users, budgets, spend
```

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | LiteLLM image, pinned to a stable SemVer tag |
| `config.yaml` | Wildcard route forwarding all models to `cc.freemodel.dev` |
| `render.yaml` | One-shot Render Blueprint (web service + Postgres) |
| `gen-key.sh` | Mint a per-peer virtual key via the admin API |
| `peer-settings.example.json` | Template `~/.claude/settings.json` to hand each peer |

## Deploy (one time)

0. **Rotate your freemodel key** so the old (leaked) one is dead. Keep the new one handy.
1. Push this folder to a Git repo (GitHub/GitLab).
2. Render → **New → Blueprint** → select the repo. It creates the web service + Postgres.
3. When prompted, enter:
   - `FREEMODEL_KEY` = the **rotated** freemodel key.
   - `LITELLM_MASTER_KEY` = an admin token you choose, starting with `sk-` (e.g. `sk-admin-<random>`).
   - `LITELLM_SALT_KEY` is auto-generated — **leave it; never change it after first deploy.**
4. Wait for the deploy, then open `https://<your-app>.onrender.com/ui/` and log in:
   username `admin`, password = your `LITELLM_MASTER_KEY`.

> Heads-up: the `starter` web plan sleeps when idle, so the first request after a lull
> takes ~30–60s to wake. Bump the plan if that's annoying.

## Add a peer

Either click **Virtual Keys → + Create** in the dashboard, or:

```bash
PROXY=https://<your-app>.onrender.com MASTER_KEY=sk-admin-... \
  ./gen-key.sh alice 20 100 40000     # name, $budget/30d, rpm, tpm
```

Set **both** `rpm` and `tpm` — one agentic Claude Code turn can be 10–20k tokens, so a
request cap alone won't protect you. Revoke/disable anytime in the dashboard; other peers
are unaffected.

Hand the peer a `~/.claude/settings.json` based on `peer-settings.example.json`, with
`ANTHROPIC_API_KEY` set to **their** key.

## Verify

```bash
curl https://<app>.onrender.com/health/liveliness          # -> {"status":"healthy"...}

curl -X POST https://<app>.onrender.com/v1/messages \
  -H "x-api-key: <a-test-virtual-key>" \
  -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-5","max_tokens":50,"messages":[{"role":"user","content":"hi"}]}'
```

Then point a test Claude Code at the proxy and confirm spend shows up under that key in
`/ui/`. To prove enforcement: set `rpm=2` on a key, fire 3 quick calls → the 3rd is
rate-limited; disable the key → calls rejected.

## Notes / caveats

- **$ budgets are approximate.** LiteLLM prices usage off Anthropic's *public* rates, which
  may differ from what freemodel bills you. RPM/TPM limits, expiry, and enable/disable are
  exact — rely on those for hard control.
- **Exact rate limits under load** need Redis. Uncomment the keyvalue service + `REDIS_URL`
  in `render.yaml` to add it.
- **If Claude Code hits an endpoint the unified `/v1/messages` route doesn't cover**
  (e.g. token counting / model listing 404s), add a `pass_through_endpoints` entry in
  `config.yaml` targeting `https://cc.freemodel.dev` and point peers at
  `https://<app>.onrender.com/anthropic` instead. See LiteLLM's Anthropic passthrough docs.
- **Bumping LiteLLM:** change the tag in `Dockerfile` deliberately; check the release notes.
