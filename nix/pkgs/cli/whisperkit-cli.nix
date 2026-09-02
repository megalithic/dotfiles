{
  lib,
  stdenvNoCC,
  fetchurl,
}:
# whisperkit-cli — Apple Silicon native speech recognition (Whisper)
#
# Source: https://github.com/argmaxinc/argmax-oss-swift
#
# Approach: install the official Homebrew bottle (precompiled arm64 binary).
# Why bottle vs `swift build`:
#   - SwiftPM-from-source needs network access (Package dependencies),
#     which the nix sandbox blocks.
#   - swiftpm2nix does not yet support modern SPM workspace state files
#     (errors with "Unsupported .build/workspace-state.json version").
#   - The Homebrew bottle is the same binary brew installs; sha256-pinned
#     and reproducible. This mirrors the nixpkgs `swiftlint` pattern of
#     installing a prebuilt portable archive.
#
# Bottle host: ghcr.io/v2/homebrew/core/whisperkit-cli/blobs/sha256:<digest>
# Anonymous pulls require an empty bearer token (`Authorization: Bearer QQ==`).
#
# arm64-only (matches upstream `depends_on arch: :arm64`).
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "whisperkit-cli";
  version = "1.0.0";

  src = fetchurl {
    # arm64_sequoia bottle — forward compatible with Tahoe (26.x).
    url = "https://ghcr.io/v2/homebrew/core/whisperkit-cli/blobs/sha256:bf6bc04656e3941084f5b58b007db3f7a582483a6905433dba55d07350c2b43a";
    hash = "sha256-v2vARlbjlBCE9bWLAH2z96WCSDppBUM9ulXQc1DCtDo=";
    # GHCR returns a tarball with no extension and an unfriendly filename.
    # Force a .tar.gz name so stdenv's unpack hook recognises it.
    name = "whisperkit-cli-${finalAttrs.version}-bottle.tar.gz";
    # GHCR requires an Authorization header even for anonymous pulls.
    curlOptsList = [
      "-H"
      "Authorization: Bearer QQ=="
    ];
  };

  sourceRoot = "whisperkit-cli/${finalAttrs.version}";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/zsh/site-functions $out/share/fish/vendor_completions.d $out/etc/bash_completion.d
    cp bin/whisperkit-cli $out/bin/whisperkit-cli
    chmod +x $out/bin/whisperkit-cli

    # Shell completions (mirrors brew bottle layout)
    cp share/zsh/site-functions/_whisperkit-cli $out/share/zsh/site-functions/ 2>/dev/null || true
    cp share/fish/vendor_completions.d/whisperkit-cli.fish $out/share/fish/vendor_completions.d/ 2>/dev/null || true
    cp etc/bash_completion.d/whisperkit-cli $out/etc/bash_completion.d/ 2>/dev/null || true

    runHook postInstall
  '';

  meta = {
    description = "Swift native on-device speech recognition with Whisper for Apple Silicon";
    homepage = "https://github.com/argmaxinc/argmax-oss-swift";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "whisperkit-cli";
  };
})
