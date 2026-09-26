{
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  cups,
  coreutils,
  dbus,
  dpkg,
  expat,
  fetchurl,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gsettings-desktop-schemas,
  graphite2,
  gtk3,
  harfbuzz,
  lib,
  libappindicator-gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libsecret,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  makeDesktopItem,
  makeWrapper,
  nspr,
  nss,
  openssl,
  pango,
  qt5,
  qt6,
  stdenv,
  systemdLibs,
  wayland,
  wrapGAppsHook3,
  xdg-utils,
  zlib,
}:

let
  pname = "chatgpt";
  version = "26.924.22138";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
    hash = "sha256-zjuxqoLM3+MDetov2NGHeW6koNXtAx0OTsitzotwFOc=";
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "ChatGPT";
    genericName = "AI assistant";
    comment = "ChatGPT by OpenAI";
    exec = "${pname} %U";
    icon = pname;
    categories = [
      "Utility"
      "Development"
    ];
    mimeTypes = [
      "x-scheme-handler/codex"
      "text/csv"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "text/tab-separated-values"
      "application/vnd.ms-excel"
      "application/vnd.ms-excel.sheet.macroEnabled.12"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ];
    startupNotify = true;
  };

  runtimeLibraries = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    graphite2
    gtk3
    harfbuzz
    libappindicator-gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libsecret
    libusb1
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    nspr
    openssl
    pango
    stdenv.cc.cc
    systemdLibs
    wayland
    zlib
  ];

  qtLibraries = [
    qt5.qtbase
    qt6.qtbase
  ];
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = runtimeLibraries ++ [
    gsettings-desktop-schemas
    nss
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontUnpack = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    dpkg-deb -x "$src" "$out"

    mkdir -p "$out/bin" "$out/lib" "$out/share/applications"
    mv "$out/usr/lib/chatgpt" "$out/lib/chatgpt"
    substituteInPlace "$out/lib/chatgpt/codex-launcher" \
      --replace-fail 'dirname' '${coreutils}/bin/dirname' \
      --replace-fail 'readlink -f' '${coreutils}/bin/readlink -f'
    ln -s ../lib/chatgpt/codex-launcher "$out/bin/chatgpt"

    cp "${desktopItem}/share/applications/chatgpt.desktop" \
      "$out/share/applications/chatgpt.desktop"
    install -Dm644 "$out/lib/chatgpt/resources/icon-chatgpt.png" \
      "$out/share/icons/hicolor/512x512/apps/chatgpt.png"

    find "$out/lib/chatgpt" -type d \
      \( \
        -name 'android-*' \
        -o -name 'darwin-*' \
        -o -name 'win32-*' \
        -o -name '*arm*' \
        -o -name '*ia32*' \
        -o -name '*musl*' \
      \) \
      -prune -exec rm -rf {} +
    find "$out/lib/chatgpt" -type f -name '*musl*' -delete

    rm -rf "$out/usr" "$out/etc"

    addAutoPatchelfSearchPath "$out/lib/chatgpt"
    addAutoPatchelfSearchPath "${qt5.qtbase}/lib"
    addAutoPatchelfSearchPath "${qt6.qtbase}/lib"

    runHook postInstall
  '';

  autoPatchelfIgnoreMissingDeps = [
    "libc++_shared.so"
    "libc.musl-x86_64.so.1"
    "liblog.so"
  ];

  postFixup = ''
    wrapProgram "$out/lib/chatgpt/ChatGPT" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          glib
          xdg-utils
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath (runtimeLibraries ++ qtLibraries)
      }:$out/lib/chatgpt \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  meta = with lib; {
    description = "ChatGPT desktop app by OpenAI";
    homepage = "https://developers.openai.com/codex/app";
    license = licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
