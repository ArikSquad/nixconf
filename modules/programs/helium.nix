{ inputs, ... }: {
  imports = [
    inputs.helium.nixosModules.default
  ];

  programs.helium = {
    enable = true;
    flags = [
      "--ozone-platform-hint=auto"
      "--enable-wayland-ime"
      "--enable-features=TouchpadOverscrollHistoryNavigation"
    ];
    policies = {
      BrowserSignin = 0;
      DnsOverHttpsMode = "automatic";
      PasswordManagerEnabled = false;
      SyncDisabled = true;
    };
  };
}
