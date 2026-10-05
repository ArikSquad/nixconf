{
  appimageTools,
  fetchurl,
  lib,
  makeDesktopItem,
  makeWrapper,
  symlinkJoin,
}:

let
  pname = "t3code";
  version = "0.0.46-nightly.20261005.2689";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-dkZKFm88iJQZimzVI5F3MDVN4C+b2mYmyrnIFuyPxGo=";
  };

  app = appimageTools.wrapType2 {
    inherit pname version src;
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "T3 Code";
    genericName = "Code Editor";
    comment = "T3 Code desktop app";
    exec = "${pname} %U";
    icon = pname;
    categories = [
      "Development"
      "IDE"
    ];
    startupNotify = true;
  };
in
symlinkJoin {
  inherit pname version;
  nativeBuildInputs = [ makeWrapper ];
  paths = [
    app
    desktopItem
  ];
  postBuild = ''
    wrapProgram $out/bin/t3code --set fish_features no-query-term

    install -Dm644 ${./t3code.png} \
      $out/share/icons/hicolor/512x512/apps/t3code.png
  '';

  meta = with lib; {
    description = "T3 Code desktop app";
    homepage = "https://github.com/pingdotgg/t3code";
    license = licenses.mit;
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
  };
}
