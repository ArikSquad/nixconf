{
  inputs,
  username,
  hostname,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/boot/limine.nix
    ../../modules/boot/plymouth.nix
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/programs/fish.nix
    ../../modules/programs/helium.nix
    ../../modules/programs/steam.nix
    ../../modules/programs/app-vpn.nix
  ];

  networking = {
    hostName = hostname;
    firewall.allowedTCPPorts = [ 3773 ];
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # ???
  };

  hardware.amdgpu.opencl.enable = true;

  services.xserver.videoDrivers = [ "amdgpu" ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "audio"
      "input"
      "docker"
    ];
  };

  system.stateVersion = "26.05";
}
