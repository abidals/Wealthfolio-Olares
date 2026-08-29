# Wealthfolio — Olares App

Unofficial [Olares](https://olares.com) app package for [Wealthfolio](https://wealthfolio.app), a beautiful, private, local-first personal finance tracker (investments, net worth, spending, simulations).

Upstream app: [`wealthfolio/wealthfolio`](https://github.com/wealthfolio/wealthfolio) (AGPL-3.0) — image `wealthfolio/wealthfolio` (multi-arch: amd64/arm64), version **3.7.0**.

## What you get

- Single-container web app served behind your Olares entrance at `https://<md5-prefix>.<your-domain>`
- Portfolio data persisted on the Olares userspace Data volume (`/data` → app data dir)
- App login protected by **your own Argon2id-hashed password** (not the Olares portal gate — the entrance is public by design so MCP clients can reach it; Wealthfolio's own auth protects everything behind it)
- Optional **AI Agent Access (MCP)**: toggle `WF_MCP_ENABLED` to `true` in Settings → Applications → Manage environment variables, then create scoped, revocable tokens inside the app under *Settings → AI Agent Access*

## Prerequisites

- An Olares machine running **Olares 1.12.6+**, logged in with your Olares ID
- [`@olares/cli`](https://www.npmjs.com/package/@olares/cli) installed and logged in:
  ```sh
  npm install -g @olares/cli@latest
  olares-cli profile login --olares-id you@example.com
  ```
- A way to generate an Argon2id PHC hash (macOS: `brew install argon2`, Debian/Ubuntu: `apt install libargon2-bin` — both provide the `argon2` CLI)

## Install

1. **Generate your Wealthfolio password hash** — the app stores only an Argon2id PHC hash of your login password. Pick your own random salt (the part after `-`):
   ```sh
   printf 'your-password' | argon2 yoursalt16chars! -id -e
   # example output: $argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>
   ```

2. **Get the chart package** — download `wealthfolio-<version>.tgz` from this repo's [Releases](https://github.com/abidals/Wealthfolio-Olares/releases/latest) (or clone and build it yourself), then upload it to your Olares Local Sources:
   ```sh
   olares-cli market upload ./wealthfolio-0.0.3.tgz
   # building from source instead:
   git clone https://github.com/abidals/Wealthfolio-Olares && cd Wealthfolio-Olares
   olares-cli chart package ./wealthfolio -o .
   ```

3. **Install**, passing your hash from step 1:
   ```sh
   olares-cli market install wealthfolio -s upload --version 0.0.3 \
     --env WF_AUTH_PASSWORD_HASH='<paste-your-hash>' --watch
   ```

4. **Open the app** — find its URL in your Olares desktop (or `olares-cli settings apps list`), sign in with the password from step 1.

## Configuration (Settings → Applications → Manage environment variables)

| Variable | Default | Purpose |
|---|---|---|
| `WF_AUTH_PASSWORD_HASH` | — (required at install) | Argon2id hash of your login password. To change your password, generate a new hash and paste it here; the app restarts automatically (`applyOnChange`). The app never accepts a plaintext password. |
| `WF_MCP_ENABLED` | `false` | AI Agent Access: serves the MCP endpoint at `/mcp` on the app's URL when `true`. Tokens are created inside the app; every agent call is audit-logged. |

A signing/encryption key (`WF_SECRET_KEY`) is generated automatically per install and survives upgrades/reinstalls — nothing to do there.

## Updating the app

When upstream ships a new version: bump the image tag in `wealthfolio/templates/deployment-wealthfolio.yaml` + `appVersion` in `Chart.yaml`, bump `version` in both `Chart.yaml` and `OlaresManifest.yaml`, then:

```sh
olares-cli chart lint ./wealthfolio
olares-cli chart package ./wealthfolio -o .
olares-cli market upload ./wealthfolio-<new-version>.tgz
olares-cli market upgrade wealthfolio -s upload --version <new-version> --watch
```

Then publish the new package as a GitHub release so others get it too:

```sh
git add -A && git commit -m "bump to <upstream version>" && git push
gh release create v<new-version> ./wealthfolio-<new-version>.tgz --latest
```

Your password and data survive upgrades (the env values and the app-data volume persist).

## Repo layout

```
wealthfolio/            # the Olares Helm-style chart (OlaresManifest.yaml + templates/)
compose.yml             # upstream docker-compose reference this chart was ported from
wealthfolio-0.0.3.tgz   # pre-built chart package (what `market upload` consumes)
```

## Notes

- The app listens on `0.0.0.0:8088`; the chart wires it to a private service + public entrance and pins CORS to the app's own origin.
- MCP is fail-closed upstream: it refuses to start with MCP enabled but no password hash configured — keep your password set.
- Data lives in the per-app userspace volume; uninstalling the app removes the workload — back up your portfolio export from inside the app before uninstalling.

## License

The Wealthfolio application is AGPL-3.0 (upstream). This packaging repo carries no separate license claim on the app itself.
