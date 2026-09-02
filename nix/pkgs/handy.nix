{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  cmake,
  bun,
  nodejs,
  cctools,
  cargo-tauri,
  jq,
  writableTmpDirAsHomeHook,
  makeBinaryWrapper,
  swift,
  apple-sdk_26,
  onnxruntime,
  openssl,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "handy";
  version = "0.8.3";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cjpais";
    repo = "Handy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sCCtp6UAxmCAcYeOM9+RW2czATh4Geqf1H8wXNMniYc=";
  };

  cargoRoot = "src-tauri";
  cargoHash = "sha256-mvOThNqfE24iMkVBM2zYexJkQxpMMgE4PPNXKy39hSg=";

  nativeInstallInputs = [ jq ];

  postPatch = ''
    patch_json() {
      local file=$1 filter=$2
      jq "$filter" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    }

    # De-structuring the Tauri build process
    # So we can:
    # - Handle the frontend building in a fixed way.
    # - Not worry about signing
    # - And avoid the auto-updater
    patch_json "src-tauri/tauri.conf.json" '
      del(.build.beforeBuildCommand) |
      .bundle.createUpdaterArtifacts = false |
      .bundle.macOS += { signingIdentity: null, hardenedRuntime: false }
    '

    # Strip cbindgen build steps
    find "$cargoDepsCopy" -path "*/ferrous-opencc-*/build.rs" \
      -exec sed -i -e '/cbindgen::Builder::new/{:l;/write_to_file/!{N;bl};d}' {} +
  '';

  nativeBuildInputs = [
    pkg-config
    cmake
    bun
    nodejs
    cargo-tauri.hook
    jq
    writableTmpDirAsHomeHook
    rustPlatform.bindgenHook
    makeBinaryWrapper
    cctools
    swift
    apple-sdk_26
  ];

  buildInputs = [
    onnxruntime
    openssl
  ];

  ortLibLocation = "${lib.getLib onnxruntime}/lib";

  env = {
    ORT_LIB_LOCATION = "${lib.getLib onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
    SWIFTC = lib.getExe' swift "swiftc"; # Explicit so the Handy build system can avoid xcrun
  };

  preBuild = ''
    cp -R ${finalAttrs.passthru.frontendDeps}/node_modules .
    chmod -R u+w node_modules
    patchShebangs node_modules
    bun run build
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications $out/bin
    mv target/${stdenv.hostPlatform.rust.rustcTarget}/release/bundle/macos/Handy.app \
      $out/Applications/
    ln -s "$out/Applications/Handy.app/Contents/MacOS/handy" "$out/bin/handy"
    runHook postInstall
  '';

  postFixup = ''
    install_name_tool -add_rpath "${finalAttrs.env.ORT_LIB_LOCATION}" \
      "$out/Applications/Handy.app/Contents/MacOS/handy"
  '';

  preCheck = ''
    cd ${finalAttrs.cargoRoot}
    export DYLD_LIBRARY_PATH="${finalAttrs.env.ORT_LIB_LOCATION}''${DYLD_LIBRARY_PATH:+:''${DYLD_LIBRARY_PATH}}"
  '';

  # Skip broken tests, mirroring CI configuration (https://github.com/cjpais/Handy/blob/main/.github/workflows/test.yml)
  checkFlags = [
    "--skip=helpers::clamshell::tests::test_is_laptop"
    "--skip=helpers::clamshell::tests::test_clamshell_check"
  ];

  passthru = {
    # The hook and deps fetcher in https://github.com/NixOS/nixpkgs/pull/376299 should simplify this dramatically.
    frontendDeps = stdenv.mkDerivation {
      pname = "handy-frontend-deps";
      version = "0.8.3";
      inherit (finalAttrs) src;

      nativeBuildInputs = [
        bun
        writableTmpDirAsHomeHook
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild
        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
        bun install --linker=isolated --force --frozen-lockfile \
          --ignore-scripts --no-progress
        bun --bun "$PWD/.nix/scripts/normalize-install.ts"
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -R node_modules $out/
        runHook postInstall
      '';

      dontFixup = true;
      outputHash = "sha256-DQbogNBQ9izK5GPmoOudqiB2lJvct1vZI2U5lp3WFy8=";
      outputHashMode = "recursive";
    };
  };

  meta = {
    description = "Free, open source, offline speech-to-text application";
    longDescription = ''
      Handy is a macOS desktop application providing simple,
      privacy-focused speech transcription. Press a shortcut, speak, and
      have your words appear in any text field — entirely on your own
      computer, with no audio sent to the cloud.
    '';
    homepage = "https://handy.computer";
    changelog = "https://github.com/cjpais/Handy/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "handy";
    maintainers = with lib.maintainers; [ philocalyst ];
    platforms = [ "aarch64-darwin" ];
  };
})
