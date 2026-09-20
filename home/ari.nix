{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  nativeLibraries = with pkgs; [
    glib
    gtk3
    at-spi2-core
    pango
    harfbuzz
    cairo
    gdk-pixbuf
    webkitgtk_4_1
    libsoup_3
    openssl
  ];

  nativeLibraryClosure = pkgs.lib.closePropagation nativeLibraries;

  pkgConfigPath = pkgs.lib.concatStringsSep ":" [
    (pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" nativeLibraryClosure)
    (pkgs.lib.makeSearchPathOutput "out" "lib/pkgconfig" nativeLibraryClosure)
    (pkgs.lib.makeSearchPathOutput "dev" "share/pkgconfig" nativeLibraryClosure)
    (pkgs.lib.makeSearchPathOutput "out" "share/pkgconfig" nativeLibraryClosure)
  ];

  #davinci-resolve-base = pkgs.davinci-resolve;

  #davinci-resolve-fontconfig = pkgs.writeText "davinci-resolve-fontconfig.conf" ''
  #  <?xml version="1.0"?>
  #  <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
  #  <fontconfig>
  #    <include>/etc/fonts/fonts.conf</include>
  #    <dir>/usr/share/fonts</dir>
  #  </fontconfig>
  #'';

  #davinci-resolve = pkgs.symlinkJoin {
  #  name = "davinci-resolve";
  #  paths = [
  #    (pkgs.buildFHSEnv (
  #      lib.removeAttrs davinci-resolve-base.passthru.args [ "passthru" ]
  #      // {
  #        targetPkgs = fhsPkgs:
  #          (davinci-resolve-base.passthru.args.targetPkgs fhsPkgs) ++ [ pkgs.mojangles ];
  #        extraBwrapArgs =
  #          (davinci-resolve-base.passthru.args.extraBwrapArgs or [ ])
  #          ++ [ "--setenv FONTCONFIG_FILE ${davinci-resolve-fontconfig}" ];
  #      }
  #    ))
  #  ];
  #  nativeBuildInputs = [ pkgs.makeWrapper ];
  #  postBuild = ''
  #    wrapProgram "$out/bin/davinci-resolve" \
  #      --set QT_QPA_PLATFORM xcb
  #  '';
  #};

  screenshot-select = pkgs.writeShellApplication {
    name = "screenshot-select";
    runtimeInputs = with pkgs; [
      coreutils
      grim
      hyprland
      jq
      libnotify
      slurp
      wl-clipboard
    ];
    text = ''
      windows="$(
        hyprctl clients -j |
          jq -r '.[] | select(.mapped) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
      )"

      geometry="$(slurp -d <<< "$windows")" || exit 0

      screenshot_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$screenshot_dir"
      destination="$screenshot_dir/$(date +%Y-%m-%d_%H-%M-%S).png"

      grim -g "$geometry" - | tee "$destination" | wl-copy
      notify-send -a screenshot-select -i "$destination" "Screenshot captured" \
        "Saved to $destination and copied to the clipboard"
    '';
  };

  # The npm build is newer than nixpkgs' OpenCode package. Run it with the
  # NixOS glibc loader so the newer client can be used without enabling
  # nix-ld system-wide.
  opencodeLauncher = pkgs.writeShellScript "opencode-local" ''
    npm_opencode="${config.home.homeDirectory}/.npm-global/lib/node_modules/opencode-ai/bin/opencode.exe"
    if [ -x "$npm_opencode" ]; then
      exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
        --library-path ${pkgs.glibc}/lib \
        "$npm_opencode" "$@"
    fi
    exec ${pkgs.opencode}/bin/opencode "$@"
  '';

in {
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
    packages =
      (with pkgs; [
        bat
        eza
        fzf
        gitui
        lazygit
        mojangles
        nerd-fonts.caskaydia-cove
        ripgrep
        starship
        tree
        zoxide
        xdg-terminal-exec
        screenshot-select

        # dev tools
        nodejs_24
        jdk25
        bun

        # C/C++ dev
        cmake
        gcc
        gnumake
        ninja

        # go
        go

        # GitHub CLI
        gh

        # ai slopfest
        opencode

        # Rust dev
        cargo
        cargo-tauri
        clippy
        rust-analyzer
        rustc
        rustfmt
        glib
        pkg-config
        gtk3
        at-spi2-core
        gdk-pixbuf
        pango
        cairo
        webkitgtk_4_1
        libsoup_3
        openssl

        # aseprite
        aseprite

        # nix
        nixfmt

        # desktop apps
        # davinci-resolve
        ghostty
        google-chrome
        termius
        vesktop
        adw-gtk3
        papirus-icon-theme
        qtengine
        kdePackages.dolphin
        jetbrains-toolbox
        prismlauncher
        chatgpt
        t3code
        # mongodb-compass

        # games
        osu-lazer-bin
      ])
      ++ nativeLibraries;

    sessionVariables = {
      TERMINAL = "ghostty";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
      PKG_CONFIG_PATH = pkgConfigPath;
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.npm-global/bin"
    ];
  };

  home.file.".local/bin/opencode".source = opencodeLauncher;
  # npm puts its global bin directory ahead of the Nix profile in some
  # existing shells; keep that command name NixOS-compatible too.
  home.file.".npm-global/bin/opencode" = {
    source = opencodeLauncher;
    force = true;
  };

  home.file.".config/fish/functions/opencode.fish".text = ''
    function opencode
      command ${config.home.homeDirectory}/.local/bin/opencode $argv
    end
  '';

  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';

  # Resolve runs in an FHS environment and scans the standard user font path.
  home.file.".local/share/fonts/Mojangles.ttf".source = "${pkgs.mojangles}/share/fonts/truetype/Mojangles.ttf";

  #home.file.".local/share/applications/davinci-resolve.desktop".text = ''
  #  [Desktop Entry]
  #  Name=DaVinci Resolve
  #  GenericName=Video Editor
  #  Exec=${davinci-resolve}/bin/davinci-resolve %U
  #  Icon=davinci-resolve
  #  Terminal=false
  #  Type=Application
  #  Categories=AudioVideo;AudioVideoEditing;Video;Graphics;
  #  StartupNotify=true
  #  StartupWMClass=resolve
  #'';

  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };

  home.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";

  # Keep Qt's platform theme plugin discoverable for Qt 6 applications.
  # Caelestia generates the matching dark palette in ~/.config/qtengine.
  home.sessionSearchVariables.QT_PLUGIN_PATH = ["${pkgs.qtengine}/lib/qt-6/plugins"];

  programs.home-manager.enable = true;
  programs.spicetify.enable = true;
  fonts.fontconfig.enable = true;

  xdg.configFile = {
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixdots/config/nvim";
      recursive = false;
    };
    "xdg-terminals.list".text = ''
      com.mitchellh.ghostty.desktop
    '';
    "caelestia/hypr-user.lua" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixdots/config/caelestia/hypr-user.lua";
      recursive = false; # it's a file
      force = true;
    };
    "caelestia/hypr-vars.lua" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixdots/config/caelestia/hypr-vars.lua";
      recursive = false;
      force = true;
    };
  };

  home.pointerCursor = {
    enable = true;
    package = pkgs.whitesur-cursors;
    name = "WhiteSur-cursors";
    size = 24;

    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  programs.caelestia = {
    enable = true;
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.caelestia-island;
    cli.enable = true;
    systemd = {
      # Hyprland starts Caelestia from its startup hook in
      # ~/.config/hypr/hyprland/execs.lua. Do not start a second shell here.
      enable = false;
      target = "graphical-session.target";
    };
    settings = {
      general.apps.explorer = [
        "dolphin"
      ];
      general.apps.terminal = [
        "ghostty"
      ];
      appearance.transparency.enabled = true;
      paths.wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
    };
    cli.settings.theme = {
      enableGtk = true;
      enableQt = true;
    };
  };

  programs.git = {
    enable = true;
    package = pkgs.git.override {withLibsecret = true;};
    settings = {
      user = {
        name = "ArikSquad";
        email = "75741608+ArikSquad@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      credential.helper = "libsecret";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    sideloadInitLua = true;
    extraPackages = with pkgs; [
      lua-language-server
      nil
      nixd
      bash-language-server
      stylua
    ];
  };
}
