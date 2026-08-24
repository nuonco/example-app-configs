# Install configs

Coder releases: https://github.com/coder/coder/releases

## Release channels

Coder ships two real channels — mainline (latest, cut on the first Tuesday of each month) and stable (N-1 of mainline, promoted a month later). This app's install labels mirror them.

- Current mainline: `v2.36.1`
- Current stable: `v2.35.4`
- Last 5 mainline cuts: `v2.36.1`, `v2.35.4`, `v2.34.8`, `v2.33.11`, `v2.32.10`
- Last 5 stable designations: `v2.35.4`, `v2.34.8`, `v2.33.11`, `v2.32.10`, `v2.31.14`
- `canary-mainline` / `customer-1` are pinned to `v2.33.11` — 3 releases behind current mainline, so a demo has room to bump forward (`v2.34.x` -> `v2.35.x` -> `v2.36.x`)
- `canary-stable` / `customer-2` / `customer-3` are pinned to `v2.32.10` — 3 releases behind current stable, same headroom on that track
- If 3 hops feels too short, the 4-back alternative is `v2.32.10` mainline / `v2.31.14` stable

## Bootstrap (run once before installs)

```sh
nuon apps sync
```

## Start an install

`approval_option` in the TOML controls how the install behaves on *future* deploys (e.g. an app-branch promotion). It does not affect the `nuon installs sync` command itself — that always prompts for confirmation unless you pass `-y`/`--yes` ("automatically approve diffs and workflows for synced installs"). Canary installs are `approve-all` in their config, so pass `-y` to skip the redundant local confirmation too; leave it off for the customer (`prompt`) installs so you get a chance to review the diff.

- Canary, mainline track:
  ```sh
  nuon installs sync -a coder -d installs/canary-mainline.toml -y
  ```
- Mainline customer:
  ```sh
  nuon installs sync -a coder -d installs/customer-1.toml
  ```
- Canary, stable track:
  ```sh
  nuon installs sync -a coder -d installs/canary-stable.toml -y
  ```
- Stable customers:
  ```sh
  nuon installs sync -a coder -d installs/customer-2.toml
  nuon installs sync -a coder -d installs/customer-3.toml
  ```
- Everything at once (mixes both — `-y` still applies to all files in the batch, so only use it if you're fine auto-approving the customer installs too):
  ```sh
  nuon installs sync -a coder -d installs/
  ```

## Demoing an app-branch rollout

1. Bump `release` in one or both canary install configs above (or edit `coder/inputs.toml`'s default and push through the app branch).
2. `nuon apps sync` then re-sync the canary file(s) with `-y` — deploys immediately, no local confirmation.
3. Trigger or push the app branch — canary validates, then the matching `mainline`/`stable` group pauses for approval before promoting.
