# Fork sync, build, and deployment automation

The fork's default branch is `deploy/zh-with-perf`. The `master` branch is a
fast-forward-only mirror of `herdrdev/herdr:master`; custom changes never land
on it. The hourly workflow creates a temporary merge candidate and does not
advance the custom branch until all checks and the Linux build pass.

The workflow never opens an upstream issue or pull request. Failures are kept
in the fork's single issue named
`[automation] Upstream sync/build/deploy failed`. Repeated identical failures
update that issue in place, and a successful recovery comments and closes it.

## Repository configuration

Configure these Actions secrets:

- `HERDR_DEPLOY_SSH_KEY`: the private half of the dedicated, passphrase-free
  GitHub Actions deployment key.
- `HERDR_DEPLOY_KNOWN_HOSTS`: a pinned `known_hosts` entry for the exact host
  and port. Do not use `StrictHostKeyChecking=no`.

Configure these Actions variables:

- `HERDR_DEPLOY_HOST=sl.z123j.top`
- `HERDR_DEPLOY_PORT=38887`
- `HERDR_DEPLOY_USER=root`
- `HERDR_DEPLOY_PATH=/root/.local/bin/herdr`

Enable Issues and Actions on the fork, and allow workflows read/write
repository permissions. Set `deploy/zh-with-perf` as the default branch so the
scheduled workflow is loaded from the custom branch.

GitHub Actions failure email is an account notification preference, not a
repository file setting. The account watching this fork must enable workflow
failure notifications in GitHub's notification settings.

## Deployment invariants

Only `x86_64-unknown-linux-musl` is built. The workflow uses Rust 1.96.1, Zig
0.15.2, `ReleaseFast`, and SIMD, matching the official Linux release build.
It verifies static linking, unresolved C++ runtime symbols, binary version,
protocol, and SHA-256 before uploading anything.

The host-side deployer records workspace IDs and total Pane count before the
handoff. It atomically replaces the installed binary, requests
`server live-handoff`, then requires all of the following:

- server status is `running`;
- the version and protocol match the staged binary;
- the protocol is compatible and live handoff remains available;
- every prior workspace ID is still present;
- total Pane count did not decrease.

The only backup is `/root/.local/bin/herdr.previous`. Successful deployment
writes the full source commit to `/root/.local/bin/herdr.source-sha`. If the
handoff or acceptance checks fail, the deployer restores the previous binary
and performs a reverse live handoff when necessary. The source-state file is
updated only after all acceptance checks pass.

## Manual verification

Run **Sync upstream, build, and deploy** from the Actions tab. A no-change run
should finish before installing build tools when the source-state file already
matches the custom branch. For a full acceptance exercise, verify these cases
in a disposable fork/branch before relying on the hourly schedule:

1. clean upstream merge and deployment;
2. deliberate merge conflict (custom branch and server stay unchanged);
3. failing test/build (no deployment);
4. unavailable SSH or rejected handoff (old service remains usable);
5. two dispatches (the concurrency group serializes them).
