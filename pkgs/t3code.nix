{
  appimageTools,
  fetchurl,
  lib,
  makeDesktopItem,
  symlinkJoin,
}:

let
  pname = "t3code";
  version = "0.0.41-preview.20260914.1693";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-wdbOUO1M6ZulavCJs66xJuPavVvy9wXPqD9W5FQcg5I=";
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
  paths = [
    app
    desktopItem
  ];
  postBuild = ''
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
