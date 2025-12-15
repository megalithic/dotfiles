# mkApp/extract.nix - Extract-based installation method
#
# Extracts DMG/ZIP/TBZ/PKG contents into nix store.
# This is the original mkCask behavior.
{
  pkgs,
  lib ? pkgs.lib,
  stdenvNoCC ? pkgs.stdenvNoCC,
  ...
}: {
  pname,
  version,
  url,
  sha256,
  appName ? "${pname}.app",
  desc ? null,
  homepage ? null,
  artifactType ? "app", # "app", "pkg", or "binary"
  binaries ? [],
  requireSystemApplicationsFolder ? false,
  copyToApplications ? false,
}: let
  # Detect artifact type based on URL if not specified
  detectedType =
    if lib.strings.hasSuffix ".pkg" url
    then "pkg"
    else artifactType;

  isPkg = detectedType == "pkg";
  isApp = detectedType == "app";
  isBinary = detectedType == "binary";
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname version;

    src = pkgs.fetchurl {
      inherit url sha256;
    };

    nativeBuildInputs = with pkgs;
      [
        undmg
        unzip
        gzip
        bzip2
        _7zz
        file
        makeWrapper
        fd
        ripgrep
      ]
      ++ lib.lists.optional isPkg (
        with pkgs; [
          xar
          cpio
          gnused
          pbzx
        ]
      );

    unpackPhase =
      if isPkg
      then ''
        echo "Extracting PKG installer..."
        xar -xf $src

        extract_payload() {
          local payload="$1"
          if head -c 4 "$payload" | rg -q "pbzx"; then
            echo "  (using pbzx decompression)"
            pbzx - < "$payload" | cpio -i 2>/dev/null || true
          else
            echo "  (using gzip decompression)"
            zcat "$payload" | cpio -i 2>/dev/null || true
          fi
        }

        for pkg in $(cat Distribution 2>/dev/null | rg -o "#.+\.pkg" 2>/dev/null | sed -e "s/^#//" -e "s/$/\/Payload/" || echo "*.pkg/Payload"); do
          if [ -f "$pkg" ]; then
            echo "Extracting payload: $pkg"
            extract_payload "$pkg"
          fi
        done

        for pkgfile in *.pkg; do
          if [ -d "$pkgfile" ] && [ -f "$pkgfile/Payload" ]; then
            echo "Extracting payload from $pkgfile"
            extract_payload "$pkgfile/Payload"
          fi
        done
      ''
      else if isApp
      then ''
        echo "Extracting application archive..."
        case "$src" in
          *.dmg)
            echo "Extracting DMG..."
            7zz x -snld $src
            ;;
          *.zip)
            echo "Extracting ZIP..."
            unzip -q $src
            ;;
          *.tbz|*.tar.bz2)
            echo "Extracting tar.bz2..."
            tar -xjf $src
            ;;
          *.tgz|*.tar.gz)
            echo "Extracting tar.gz..."
            tar -xzf $src
            ;;
          *.7z)
            echo "Extracting 7zip..."
            7zz x -snld $src
            ;;
          *)
            if 7zz x -snld $src >/dev/null 2>&1; then
              echo "Extracted with 7zip successfully"
            elif unzip -q $src 2>/dev/null; then
              echo "Extracted ZIP successfully"
            elif tar -xjf $src 2>/dev/null; then
              echo "Extracted tar.bz2 successfully"
            elif tar -xzf $src 2>/dev/null; then
              echo "Extracted tar.gz successfully"
            elif undmg $src 2>/dev/null; then
              echo "Extracted DMG successfully"
            else
              echo "Warning: Failed to extract archive, trying to continue..."
            fi
            ;;
        esac

        # Handle nested DMG extraction (some DMGs extract to a subdirectory)
        # If appName isn't in root but exists nested, move it up
        if [[ ! -d "${appName}" ]]; then
          echo "App not in root, searching for nested .app..."
          # fd: -d 2 = max depth 2, -t d = type directory, -g = glob pattern, -1 = first match only
          nested_app=$(fd -d 2 -t d -g "${appName}" . 2>/dev/null | head -1)
          if [[ -n "$nested_app" && -d "$nested_app" ]]; then
            echo "Found nested app at: $nested_app"
            mv "$nested_app" .
            echo "Moved ${appName} to root"
          fi
        fi
      ''
      else if isBinary
      then ''
        echo "Processing binary artifact..."
        if [ "$(file --mime-type -b "$src")" == "application/gzip" ]; then
          echo "Decompressing gzipped binary..."
          gunzip $src -c > ${lib.lists.elemAt binaries 0}
        elif [ "$(file --mime-type -b "$src")" == "application/x-mach-binary" ]; then
          echo "Copying Mach-O binary..."
          cp $src ${lib.lists.elemAt binaries 0}
        else
          echo "Copying binary as-is..."
          cp $src ${lib.lists.elemAt binaries 0}
        fi
      ''
      else "";

    sourceRoot = lib.strings.optionalString isApp appName;

    dontPatchShebangs = true;
    dontFixup = true;

    installPhase =
      if isPkg
      then ''
        echo "Installing PKG contents..."

        if [ -d "Applications" ]; then
          echo "Installing to Applications..."
          mkdir -p $out/Applications
          cp -R Applications/* $out/Applications/
        fi

        if [ -n "$(fd -d 1 -t d '\.app$' . 2>/dev/null || true)" ]; then
          echo "Installing app bundles..."
          mkdir -p $out/Applications
          cp -R *.app $out/Applications/ 2>/dev/null || true
        fi

        if [ -d "Resources" ]; then
          echo "Installing Resources..."
          mkdir -p $out/Resources
          cp -R Resources/* $out/Resources/
        fi

        if [ -d "Library" ]; then
          echo "Installing Library items..."
          mkdir -p $out/Library
          cp -R Library/* $out/Library/
        fi
      ''
      else if isApp
      then ''
        runHook preInstall

        echo "Installing application bundle for ${finalAttrs.sourceRoot}..."
        mkdir -p "$out/Applications/${finalAttrs.sourceRoot}"
        cp -R . "$out/Applications/${finalAttrs.sourceRoot}"

        mkdir -p $out/bin

        appBaseName="${lib.strings.removeSuffix ".app" appName}"
        if [[ -e "$out/Applications/${finalAttrs.sourceRoot}/Contents/MacOS/$appBaseName" ]]; then
          echo "Creating wrapper for $appBaseName..."
          makeWrapper "$out/Applications/${finalAttrs.sourceRoot}/Contents/MacOS/$appBaseName" $out/bin/${pname}
        elif [[ -e "$out/Applications/${finalAttrs.sourceRoot}/Contents/MacOS/${pname}" ]]; then
          echo "Creating wrapper for ${pname}..."
          makeWrapper "$out/Applications/${finalAttrs.sourceRoot}/Contents/MacOS/${pname}" $out/bin/${pname}
        else
          echo "Note: Could not find main executable for wrapper"
        fi

        runHook postInstall
      ''
      else if (isBinary && !isApp)
      then ''
        echo "Installing binary..."
        mkdir -p $out/bin
        install -Dm755 ./* $out/bin/
      ''
      else ''
        echo "Installing via fallback..."
        runHook preInstall
        mkdir -p $out/Applications
        mv *.app $out/Applications
        runHook postInstall
      '';

    postInstall = lib.optionalString (isApp || isPkg) ''
      echo "Removing quarantine attributes..."

      if [ -d "$out/Applications" ]; then
        for app in $(fd -t d -e app . "$out/Applications" 2>/dev/null || true); do
          xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
        done
      fi

      if [ -d "$out/Library" ]; then
        xattr -dr com.apple.quarantine "$out/Library" 2>/dev/null || true
      fi
    '';

    passthru = lib.optionalAttrs requireSystemApplicationsFolder {
      inherit appName;
      needsSystemApplicationsFolder = true;
      inherit copyToApplications;
      installMethod = "extract";
    };

    meta = {
      description = if desc != null then desc else "macOS application";
      homepage = if homepage != null then homepage else "";
      platforms = lib.platforms.darwin;
      mainProgram =
        if (isBinary && !isApp)
        then (lib.lists.elemAt binaries 0)
        else pname;
    };
  })
