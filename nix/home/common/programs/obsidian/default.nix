{
  lib,
  pkgs,
  paths,
  ...
}:
{
  home.activation.configureObsidian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    OBSIDIAN_CONFIG="${paths.icloud}/Documents/_notes/.obsidian/app.json"
    if [ -d "$(dirname "$OBSIDIAN_CONFIG")" ]; then
      [ -f "$OBSIDIAN_CONFIG" ] || echo '{}' > "$OBSIDIAN_CONFIG"
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
        "$OBSIDIAN_CONFIG" \
        <(echo '{"attachmentFolderPath": "assets"}') \
        > "$OBSIDIAN_CONFIG.tmp" && mv "$OBSIDIAN_CONFIG.tmp" "$OBSIDIAN_CONFIG"
    fi
  '';
}
