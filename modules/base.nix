{ lib, pkgs, ... }: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Start reclaiming memory from user workloads before the kernel is forced
  # into a system-wide OOM situation.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
  };

  # Keep the policy in the user manager, where per-app kill preferences apply.
  systemd.slices.user.sliceConfig.ManagedOOMMemoryPressure = lib.mkForce "auto";
  systemd.slices.system.sliceConfig = {
    ManagedOOMMemoryPressureLimit = "50%";
    ManagedOOMMemoryPressureDurationSec = "10s";
  };

  systemd.user.units."slice".text = lib.mkForce ''
    [Slice]
    ManagedOOMMemoryPressure=kill
    ManagedOOMMemoryPressureLimit=50%
    ManagedOOMMemoryPressureDurationSec=10s
  '';

  # UWSM runs Hyprland in this unit; let oomd choose other app cgroups first.
  systemd.user.services."wayland-wm@" = {
    overrideStrategy = lib.mkForce "asDropin";
    serviceConfig.ManagedOOMPreference = "avoid";
  };

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      ncurses
    ];
  };

  boot = {
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.systemd.enable = true;
  };

  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  services.xserver.xkb = {
    layout = "fi,ru";
    variant = ",phonetic";
    options = "grp:alt_shift_toggle";
  };

  # lowkey i dont like this here?
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb-ce;
    enableAuth = false;
    bind_ip = "0.0.0.0";
  };

  # lowkey also annoying to have this always running in the bg
  services.redis.servers.myredis = {
    enable = true;
    port = 6379;
  };

  console.keyMap = "fi";

  services = {
    dbus.enable = true;
    fstrim.enable = true;
    gvfs.enable = true;
    power-profiles-daemon.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.extraConfig."51-rig-volume-fix" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {
                "device.name" = "alsa_card.usb-Nacon_RIG_600_PRO_R00300000003-01";
              }
            ];

            actions = {
              update-props = {
                "api.alsa.soft-mixer" = true;
                "api.alsa.ignore-dB" = true;
                "device.nick" = "RIG 600 PRO — software mixer";
              };
            };
          }
        ];
      };
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    age
    alejandra
    btop
    polkit_gnome
    curl
    fastfetch
    fd
    ffmpeg
    git
    jq
    libva-utils
    nh
    nixd
    pciutils
    ripgrep
    sbctl
    unzip
    usbutils
    wget
    vulkan-tools
  ];
}
