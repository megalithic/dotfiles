---
name: macos-vm-testing
description: Test macOS setup, installation, native builds, dotfile activation, and service configuration in a disposable Apple Silicon macOS VM before touching the host. Use whenever a macOS change needs execution-based validation, including mise packages, source builds, installers, launchd, and system preferences. Default to this workflow unless the user explicitly authorizes host testing. Docker Linux builds do not prove native macOS behavior.
---

# macOS VM testing

Use `macos-vm` (`~/.dotfiles/bin/macos-vm`) for native macOS validation. Read-only host inspection and ordinary platform-independent unit tests do not require a VM.

## Approval and limits

- Ask before installing Tart, downloading an image, starting virtual NAT networking, or provisioning dependencies. Explain the download size and host footprint. One explicit approval may cover the whole stated test run.
- Keep active host dotfiles, services, package dependencies, DNS, VPN, and firewall configuration untouched. VM approval does not authorize applying the tested change to the host.
- No host home-directory shares, credential forwarding, SSH-agent forwarding, clipboard, audio, or USB passthrough. Transfer only reviewed scripts, configuration, or source files needed for the test.
- Default NAT is not a hostile-code network sandbox: the guest can reach the network and host/LAN services. Do not run hostile code under this policy; stop and agree on stronger isolation.
- A VM cannot prove physical hardware, host TCC permissions, Touch ID, actual display behavior, or live host integrations. Report those limits. Ask separately before any host validation; do not silently substitute a host test.

## Tool and image

The wrapper uses mise-installed `aqua:openai/tart@2.40.1`, an app-bundle executable required for macOS virtualization entitlements. It never installs or activates tools automatically.

After approval, if missing:

```sh
mise --no-config install aqua:openai/tart@2.40.1
```

State lives in `~/.local/share/pi/macos-vms`, separate from the user's normal `~/.tart`. Automatic pruning is disabled. Do not prune unrelated caches or VMs.

Use an official non-vanilla Cirrus Labs macOS image with the Tart Guest Agent. The tested image is `ghcr.io/cirruslabs/macos-tahoe-base:latest`; its compressed download was 27.3 GB. Prefer an image digest for repeatability. Record the actual guest OS/build, architecture, image reference, and tool versions; a `latest` image tag is mutable.

## Workflow

1. Choose a unique local VM name. Clone only after provisioning approval:

   ```sh
   macos-vm create pi-proof-example ghcr.io/cirruslabs/macos-tahoe-base:latest
   ```

2. Start it in a supervised session:

   ```sh
   macos-vm run pi-proof-example
   ```

   Use `interactive_shell` dispatch mode, `handsFree.autoExitOnQuiet: false`, and a bounded timeout. The command stays running until the VM stops. Do not use quiet auto-close to determine VM readiness or test completion.

3. Check guest readiness and identity:

   ```sh
   macos-vm exec pi-proof-example /usr/bin/uname -m
   macos-vm exec pi-proof-example /usr/bin/sw_vers
   ```

   Retry guest-agent readiness only with a bounded retry count. `macos-vm status NAME` returns JSON including `State` and `Running`. Require the intended OS and native architecture before testing.

4. Run reviewed commands inside the guest. The wrapper uses `tart exec -i`: stdin, arguments, and the guest exit status are preserved; no SSH credentials are needed.

   ```sh
   macos-vm exec pi-proof-example /bin/bash -s < reviewed-test.sh
   ```

   Do not mount the repository or copy the host's full config/environment. Install dependencies inside the guest through mise, for example `mise --no-config bootstrap packages apply --yes brew:libevent`. This command still needs to be within the approved test scope.

5. Test the actual entry point and behavior, not just syntax. A source build needs a successful install, native `file`/`lipo` results, expected runtime libraries, version output, and a small real operation. Use isolated sockets/configs for service tests. Record every failure and corrected rerun; a missing binary or failed hook is not a pass.

6. Save evidence outside git under `$(pi-docs-dir docs)/`: exact tested inputs, dependency/compiler versions, complete logs, exit statuses, and observed outputs. Use `set -o pipefail` when piping through `tee`. For binary transfers, run the pipeline from a script or uncompressed shell; output-compressing tool wrappers must not process the archive bytes. Archive explicitly named outputs, not sockets or the entire guest home.

7. Stop the VM even when validation fails, then confirm `State` is `stopped`:

   ```sh
   macos-vm stop pi-proof-example
   macos-vm status pi-proof-example
   ```

   Save evidence before disposal. After approval to discard the named guest, use `trash ~/.local/share/pi/macos-vms/vms/pi-proof-example`. Do not delete or prune the image cache unless requested. Report any retained VM/cache and host tool installation.

## Verified tmux example

`references/tmux.toml` was built and runtime-tested in a macOS 26.6.2 arm64 guest with mise 2026.9.1 and Apple clang 21.0.0. The tests covered `3.8-rc3`, `master`, and full SHA `4712726062ca9f5744eb6ac0e92500d0d2767105`. Each started, queried, and stopped a server on its own socket.

Guest prerequisites: Xcode Command Line Tools and mise-managed Homebrew packages `autoconf`, `automake`, `bison`, `pkgconf`, `libevent`, `ncurses`, `utf8proc`, and `jemalloc`. RC3 refused to configure without a jemalloc choice on macOS; use the upstream-recommended `--enable-jemalloc`, not an untested omission.

Change `version` to the desired tag, `master`, or full commit SHA. `master` does not refresh an already-installed version automatically. For repeatability, resolve `refs/heads/master` to a full SHA and install that version. If a postinstall fails, mise can retain extracted sources as an installation; retry with `mise install --force tmux@REF` and verify the binary. A successful download alone proves nothing about compilation.

The Ubuntu Docker gist builds Linux binaries, including on an arm64 Mac. Do not describe its output as a native macOS executable.

## References

- https://tart.run/quick-start/
- https://github.com/openai/tart
- https://mise.jdx.dev/dev-tools/backends/http.html
- https://mise.jdx.dev/dev-tools/#tool-postinstall-commands
- https://github.com/tmux/tmux/wiki/Installing
