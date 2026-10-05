{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

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

  dolphinWithArk = pkgs.symlinkJoin {
    name = "dolphin-with-ark";
    paths = [ pkgs.kdePackages.dolphin ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/dolphin" \
        --prefix QT_PLUGIN_PATH : "${pkgs.kdePackages.ark}/lib/qt-6/plugins"
    '';
  };

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

  opencodeNpm = pkgs.writeShellScriptBin "npm" ''
    install_command=false
    global_install=false
    opencode_package=false

    for argument in "$@"; do
      case "$argument" in
        install|i) install_command=true ;;
        --global|-g) global_install=true ;;
        opencode-ai|opencode-ai@*) opencode_package=true ;;
      esac
    done

    if [ "$install_command" = true ] && [ "$global_install" = true ] && [ "$opencode_package" = true ]; then
      NPM_CONFIG_IGNORE_SCRIPTS=true exec ${pkgs.nodejs_24}/bin/npm "$@"
    fi

    exec ${pkgs.nodejs_24}/bin/npm "$@"
  '';

  opencodeLauncher = pkgs.writeShellScript "opencode-local" ''
    export PATH="${opencodeNpm}/bin:$PATH"

    opencode_package="${config.home.homeDirectory}/.npm-global/lib/node_modules/opencode-ai/node_modules"
    if ${pkgs.gnugrep}/bin/grep -qw avx2 /proc/cpuinfo; then
      npm_opencode="$opencode_package/opencode-linux-x64/bin/opencode"
      npm_opencode_fallback="$opencode_package/opencode-linux-x64-baseline/bin/opencode"
    else
      npm_opencode="$opencode_package/opencode-linux-x64-baseline/bin/opencode"
      npm_opencode_fallback="$opencode_package/opencode-linux-x64/bin/opencode"
    fi

    for candidate in "$npm_opencode" "$npm_opencode_fallback"; do
      if [ -x "$candidate" ]; then
        exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
          --library-path ${pkgs.glibc}/lib \
          "$candidate" "$@"
      fi
    done
    exec ${pkgs.opencode}/bin/opencode "$@"
  '';

in {
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default
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
        zed-editor
        adw-gtk3
        papirus-icon-theme
        qtengine
        dolphinWithArk
        kdePackages.ark
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

  programs.spicetify = {
    enable = true;
    wayland = true;

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      fullAppDisplay
      shuffle
      volumePercentage
    ];
  };

  home.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";

  # Keep Qt's platform theme plugin discoverable for Qt 6 applications.
  # Caelestia generates the matching dark palette in ~/.config/qtengine.
  home.sessionSearchVariables.QT_PLUGIN_PATH = ["${pkgs.qtengine}/lib/qt-6/plugins"];

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  xdg.configFile = {
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixdots/config/nvim";
      recursive = false;
    };
    "clangd/config.yaml".text = ''
      If:
        PathMatch: '.*\.(cc|cpp|cxx|hh|hpp|hxx)$'
      CompileFlags:
        Compiler: /etc/profiles/per-user/${username}/bin/g++
        BuiltinHeaders: QueryDriver
      Diagnostics:
        ClangTidy:
          Add: ['bugprone-*', 'clang-analyzer-*', 'performance-*']
          FastCheckFilter: Loose
        UnusedIncludes: Strict
        MissingIncludes: None
    '';
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
      llvmPackages_23.clang-tools
      stylua
    ];
  };
}
