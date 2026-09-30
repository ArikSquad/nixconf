{ lib, pkgs, username, ... }:
let
  namespace = "app-vpn";
  interface = "wg-app-vpn";
  profile = "/etc/wireguard/app-vpn.conf";
  telegramDesktop = pkgs.telegram-desktop;

  telegramDesktopWrapped = pkgs.symlinkJoin {
    name = "telegram-desktop-vpn";
    paths = [ telegramDesktop ];
    nativeBuildInputs = [ pkgs.coreutils pkgs.gnused ];
    postBuild = ''
      mkdir -p "$out/libexec"
      mv "$out/bin/Telegram" "$out/libexec/Telegram"
      cat > "$out/bin/Telegram" <<'EOF'
      #!/bin/sh
      exec /run/wrappers/bin/app-vpn-launch "$@"
      EOF
      chmod 0555 "$out/bin/Telegram"
      ln -s Telegram "$out/bin/telegram-desktop"

      for service in "$out"/share/dbus-1/services/*.service; do
        [ -e "$service" ] || continue
        if [ -L "$service" ]; then
          cp -L "$service" "$service.tmp"
          mv "$service.tmp" "$service"
        fi
        sed -i "s|${telegramDesktop}|$out|g" "$service"
      done
    '';
  };

  appVpnHelper = pkgs.stdenv.mkDerivation {
    pname = "app-vpn-launcher";
    version = "1.0.0";
    src = ../../pkgs/app-vpn-launch.c;
    dontUnpack = true;

    buildPhase = ''
      $CC -O2 -Wall -Wextra \
        -DAPP_BIN='"${telegramDesktopWrapped}/libexec/Telegram"' \
        -DAPP_USER='"${username}"' \
        -o app-vpn-launch "$src"
    '';

    installPhase = ''
      install -Dm755 app-vpn-launch "$out/bin/app-vpn-launch"
    '';
  };

  startTunnel = pkgs.writeShellApplication {
    name = "app-vpn-start";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      gnused
      iproute2
      nftables
      wireguard-tools
    ];
    text = ''
      set -euo pipefail

      netns=${lib.escapeShellArg namespace}
      iface=${lib.escapeShellArg interface}
      config="$CREDENTIALS_DIRECTORY/proton.conf"

      cleanup_on_error() {
        result=$?
        if [ "$result" -ne 0 ]; then
          if [ -e "/run/netns/$netns" ]; then
            while IFS= read -r pid; do
              kill "$pid" 2>/dev/null || true
            done < <(ip netns pids "$netns" 2>/dev/null || true)
            ip netns del "$netns" 2>/dev/null || true
          fi
          ip link delete "$iface" 2>/dev/null || true
          rm -f /run/app-vpn/resolv.conf
        fi
        exit "$result"
      }
      trap cleanup_on_error EXIT

      # Remove a stale instance left behind by an interrupted service stop.
      if [ -e "/run/netns/$netns" ]; then
        while IFS= read -r pid; do
          kill "$pid" 2>/dev/null || true
        done < <(ip netns pids "$netns" 2>/dev/null || true)
        ip netns del "$netns"
      fi
      ip link delete "$iface" 2>/dev/null || true

      ip netns add "$netns"
      ip link add "$iface" type wireguard
      wg setconf "$iface" <(wg-quick strip "$config")
      ip link set "$iface" netns "$netns"
      ip -n "$netns" link set lo up

      addresses="$(awk -F= '
        /^\[Peer\]/ { exit }
        /^[[:space:]]*Address[[:space:]]*=/ {
          sub(/^[^=]*=/, "")
          gsub(/^[[:space:]]+|[[:space:]]+$/, "")
          print
        }
      ' "$config" | tr ',' '\n')"
      if [ -z "$(printf '%s' "$addresses" | tr -d '[:space:]')" ]; then
        echo "app-vpn: Proton profile has no Interface Address" >&2
        exit 1
      fi

      while IFS= read -r address; do
        address="$(printf '%s' "$address" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        [ -z "$address" ] || ip -n "$netns" address add "$address" dev "$iface"
      done <<< "$addresses"

      mtu="$(awk -F= '
        /^\[Peer\]/ { exit }
        /^[[:space:]]*MTU[[:space:]]*=/ {
          sub(/^[^=]*=/, "")
          gsub(/^[[:space:]]+|[[:space:]]+$/, "")
          print
          exit
        }
      ' "$config")"
      [ -z "$mtu" ] || ip -n "$netns" link set "$iface" mtu "$mtu"

      allowed_ips="$(ip netns exec "$netns" wg show "$iface" allowed-ips | awk '
        {
          sub(/^[^[:space:]]+[[:space:]]+/, "")
          gsub(/,/, " ")
          count = split($0, routes, /[[:space:]]+/)
          for (i = 1; i <= count; i++) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", routes[i])
            if (routes[i] != "") print routes[i]
          }
        }
      ')"
      printf '%s\n' "$allowed_ips" | grep -Fxq '0.0.0.0/0' || {
        echo "app-vpn: active WireGuard peer must include AllowedIPs = 0.0.0.0/0; active routes:" >&2
        printf '  %s\n' "$allowed_ips" >&2
        exit 1
      }
      printf '%s\n' "$allowed_ips" | grep -Fxq '::/0' || {
        echo "app-vpn: active WireGuard peer must include AllowedIPs = ::/0; active routes:" >&2
        printf '  %s\n' "$allowed_ips" >&2
        exit 1
      }

      ip -n "$netns" link set "$iface" up
      ip -n "$netns" route replace default dev "$iface"
      ip -n "$netns" -6 route replace default dev "$iface"

      dns_servers="$(awk -F= '
        /^\[Peer\]/ { exit }
        /^[[:space:]]*DNS[[:space:]]*=/ {
          sub(/^[^=]*=/, "")
          gsub(/^[[:space:]]+|[[:space:]]+$/, "")
          print
        }
      ' "$config" | head -n 1 | tr ',' '\n')"
      if [ -z "$(printf '%s' "$dns_servers" | tr -d '[:space:]')" ]; then
        echo "app-vpn: Proton profile has no Interface DNS server" >&2
        exit 1
      fi
      : > /run/app-vpn/resolv.conf
      while IFS= read -r dns; do
        dns="$(printf '%s' "$dns" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        [ -z "$dns" ] || printf 'nameserver %s\n' "$dns" >> /run/app-vpn/resolv.conf
      done <<< "$dns_servers"
      chmod 0644 /run/app-vpn/resolv.conf

      ip netns exec "$netns" nft -f - <<EOF
      table inet app_vpn {
        chain output {
          type filter hook output priority 0; policy drop;
          oifname "lo" accept
          oifname "$iface" accept
        }
      }
      EOF

      trap - EXIT
    '';
  };

  stopTunnel = pkgs.writeShellApplication {
    name = "app-vpn-stop";
    runtimeInputs = with pkgs; [ coreutils iproute2 ];
    text = ''
      set -euo pipefail
      netns=${lib.escapeShellArg namespace}
      iface=${lib.escapeShellArg interface}

      if [ -e "/run/netns/$netns" ]; then
        while IFS= read -r pid; do
          kill "$pid" 2>/dev/null || true
        done < <(ip netns pids "$netns" 2>/dev/null || true)
        ip netns del "$netns" 2>/dev/null || true
      fi
      ip link delete "$iface" 2>/dev/null || true
      rm -f /run/app-vpn/resolv.conf
    '';
  };
in
{
  boot.kernelModules = [ "wireguard" ];

  systemd.tmpfiles.rules = [
    "d /etc/wireguard 0700 root root - -"
  ];

  systemd.services.app-vpn = {
    description = "Private WireGuard network namespace for the selected application via Proton VPN";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = profile;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "app-vpn";
      RuntimeDirectoryMode = "0755";
      LoadCredential = [ "proton.conf:${profile}" ];
      ExecStart = lib.getExe startTunnel;
      ExecStop = lib.getExe stopTunnel;
    };
  };

  security.wrappers.app-vpn-launch = {
    source = "${appVpnHelper}/bin/app-vpn-launch";
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
  };

  home-manager.users.${username} = {
    home.packages = [ telegramDesktopWrapped ];

    home.file.".local/share/applications/org.telegram.desktop.desktop".text = ''
      [Desktop Entry]
      Name=Telegram
      Comment=Telegram Desktop through the app VPN
      Exec=/run/wrappers/bin/app-vpn-launch %u
      TryExec=/run/wrappers/bin/app-vpn-launch
      Icon=org.telegram.desktop
      Terminal=false
      Type=Application
      Categories=Network;InstantMessaging;
      StartupNotify=true
      StartupWMClass=TelegramDesktop
      DBusActivatable=false
      MimeType=x-scheme-handler/tg;
    '';
  };
}
