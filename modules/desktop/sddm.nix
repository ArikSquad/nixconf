{ pkgs, ... }:
let
  glass-login = pkgs.stdenvNoCC.mkDerivation {
    pname = "glass-login-sddm-theme";
    version = "1.0";
    src = ../../config/sddm/glass-login;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/sddm/themes/glass-login
      cp -r . $out/share/sddm/themes/glass-login
      runHook postInstall
    '';
  };
in
{
  fonts.packages = [ pkgs.inter ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "glass-login";
    extraPackages = with pkgs.qt6; [
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];
  };

  environment.systemPackages = [ glass-login ];
}
