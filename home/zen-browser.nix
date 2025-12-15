{
  inputs,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs) lib stdenv;
in {
  programs.zen-browser = {
    enable = true;
    package =
      if stdenv.hostPlatform.isDarwin
      then pkgs.zen-browser
      else inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default;
    profiles.natsukium = {
      settings = {
        "extensions.autoDisableScopes" = 0;
      };
      search = {
        force = true;
        engines = {
          nix-packages = {
            name = "Nix Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          nixos-wiki = {
            name = "NixOS Wiki";
            urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
            icon = "https://wiki.nixos.org/favicon.ico";
            definedAliases = ["@nw"];
          };

          noogle = {
            name = "noogle";
            urls = [{template = "https://noogle.dev/q?term={searchTerms}";}];
            icon = "https://noogle.dev/favicon.png";
            definedAliases = ["@noogle"];
          };

          pypi = {
            name = "PyPI";
            urls = [{template = "https://pypi.org/search/?q={searchTerms}";}];
            icon = "https://pypi.org/favicon.ico";
            definedAliases = ["@pypi"];
          };
        };
      };
      extensions = {
        packages = with pkgs.firefox-addons; [
          bitwarden
          instapaper-official
          keepa
          onepassword-password-manager
          refined-github
          surfingkeys
          tampermonkey
          vimium
          wayback-machine
          zotero-connector
        ];
        # ++ (with pkgs.my-firefox-addons; [
        #   adguard-adblocker
        #   calilay
        #   kiseppe-price-chart-kindle
        # ]);
      };
    };
  };

  home.activation = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    zen-browser = let
      profiles-ini =
        if stdenv.hostPlatform.isLinux
        then "${config.xdg.configHome}/zen/profiles.ini"
        else "${config.home.homeDirectory}/Library/\"Application Support\"/zen/profiles.ini";
    in
      inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        rm ${profiles-ini}.backup
        mv ${profiles-ini} ${profiles-ini}.generate
        cat ${profiles-ini}.generate > ${profiles-ini}
        echo ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-01.svg >> ${profiles-ini}
      '';
  };
}
