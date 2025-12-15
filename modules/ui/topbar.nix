{ config, pkgs, lib, ... }:

let
  # Minimalist Color Palette (Mac-like / Dark Mode)
  colors = {
    bg = "rgba(30, 30, 46, 0.95)";
    fg = "#cdd6f4";
    accent = "#89b4fa";
    surface = "#313244";
    border = "#45475a";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
  };

  # --- Waybar Configuration ---
  waybarConfig = {
    layer = "top";
    position = "top";
    height = 34;
    margin-top = 6;
    margin-left = 10;
    margin-right = 10;
    spacing = 4;

    modules-left = [ "custom/logo" ];
    modules-center = [ "clock" ];
    modules-right = [ "group/status" "custom/control" ];

    "custom/logo" = {
      format = "    ";
      tooltip = false;
      on-click = "${pkgs.kdePackages.krunner}/bin/krunner";
    };

    "clock" = {
      format = "{:%a %d %b  %H:%M}";
      tooltip-format = "<tt><small>{calendar}</small></tt>";
      calendar = {
        mode = "year";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        format = {
          months = "<span color='#ffead3'><b>{}</b></span>";
          days = "<span color='#ecc6d9'><b>{}</b></span>";
          weeks = "<span color='#99ffdd'><b>W{}</b></span>";
          weekdays = "<span color='#ffcc66'><b>{}</b></span>";
          today = "<span color='#ff6699'><b><u>{}</u></b></span>";
        };
      };
    };

    "group/status" = {
      orientation = "horizontal";
      modules = [ "network" "bluetooth" "battery" ];
    };

    "network" = {
      format-wifi = "";
      format-ethernet = "";
      format-disconnected = "";
      format-linked = "";
      tooltip-format = "{essid} ({signalStrength}%)";
      on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    };

    "bluetooth" = {
      format = "";
      format-disabled = "";
      format-connected = "";
      tooltip-format = "{controller_alias}\t{controller_address}";
      on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    };

    "battery" = {
      states = {
        warning = 30;
        critical = 15;
      };
      format = "{icon}";
      format-charging = "";
      format-plugged = "";
      format-icons = ["" "" "" "" ""];
      tooltip-format = "{capacity}% - {time}";
    };

    "custom/control" = {
      format = "  ";
      tooltip = false;
      on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    };
  };

  # --- Waybar CSS ---
  waybarStyle = ''
    * {
      font-family: "Inter", "Font Awesome 6 Free", sans-serif;
      font-size: 14px;
      font-weight: 600;
    }

    window#waybar {
      background: transparent;
    }

    .modules-left, .modules-center, .modules-right {
      background: ${colors.bg};
      border: 1px solid ${colors.border};
      border-radius: 12px;
      padding: 2px 10px;
    }

    .modules-right {
      padding: 2px 5px;
    }

    #custom-logo {
      color: ${colors.accent};
      font-size: 16px;
      padding-right: 10px;
    }

    #clock {
      color: ${colors.fg};
    }

    #network, #bluetooth, #battery {
      color: ${colors.fg};
      padding: 0 8px;
    }

    #custom-control {
      color: ${colors.bg};
      background: ${colors.accent};
      border-radius: 8px;
      padding: 2px 10px;
      margin-left: 8px;
    }
  '';

  # --- SwayNC Configuration (Control Center) ---
  swayncConfig = {
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    control-center-layer = "top";
    control-center-margin-top = 10;
    control-center-margin-bottom = 10;
    control-center-margin-right = 10;
    control-center-margin-left = 10;
    
    widgets = [
      "title"
      "buttons-grid"
      "volume"
      "backlight"
      "mpris"
      "dnd"
    ];
    
    widget-config = {
      title = {
        text = "Control Center";
        clear-all-button = true;
        button-text = "Clear All";
      };
      
      buttons-grid = {
        actions = [
          { label = "Wi-Fi"; command = "kcmshell6 kcm_networkmanagement"; type = "toggle"; }
          { label = "Bluetooth"; command = "kcmshell6 kcm_bluetooth"; type = "toggle"; }
          { label = "Settings"; command = "systemsettings"; }
          { label = "Display"; command = "kcmshell6 kcm_kscreen"; }
          { label = "Power"; command = "kcmshell6 powerdevilprofilesconfig"; }
        ];
      };
      
      volume = { label = "Volume"; };
      backlight = { label = "Brightness"; };
    };
  };

  # --- SwayNC CSS ---
  swayncStyle = ''
    * {
      font-family: "Inter", sans-serif;
    }

    .control-center {
      background: ${colors.bg};
      border: 1px solid ${colors.border};
      border-radius: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      padding: 16px;
    }

    .widget-title {
      color: ${colors.fg};
      font-size: 18px;
      font-weight: bold;
      margin-bottom: 12px;
    }

    .widget-title > button {
      background: ${colors.surface};
      color: ${colors.fg};
      border: none;
      border-radius: 8px;
      padding: 6px 12px;
      font-size: 12px;
    }

    .widget-buttons-grid {
      background: ${colors.surface};
      border-radius: 12px;
      padding: 8px;
      margin-bottom: 12px;
    }

    .widget-buttons-grid > flowbox > flowboxchild > button {
      background: ${colors.bg};
      color: ${colors.fg};
      border-radius: 8px;
      margin: 4px;
      padding: 12px;
      border: 1px solid ${colors.border};
      font-weight: 600;
    }
    
    .widget-buttons-grid > flowbox > flowboxchild > button:hover {
      background: ${colors.accent};
      color: ${colors.bg};
    }

    .widget-volume, .widget-backlight {
      background: ${colors.surface};
      border-radius: 12px;
      padding: 12px;
      margin-bottom: 8px;
    }

    .widget-volume > box > label, .widget-backlight > box > label {
      color: ${colors.fg};
      font-weight: 600;
    }

    trough {
      background: ${colors.bg};
      border-radius: 6px;
      min-height: 8px;
    }

    highlight {
      background: ${colors.accent};
      border-radius: 6px;
    }

    slider {
      background: ${colors.fg};
      border-radius: 50%;
      min-height: 16px;
      min-width: 16px;
    }

    .widget-mpris {
      background: ${colors.surface};
      border-radius: 12px;
      padding: 12px;
      color: ${colors.fg};
    }
  '';

  wbConfig = pkgs.writeText "waybar-config" (builtins.toJSON waybarConfig);
  wbStyle = pkgs.writeText "waybar-style" waybarStyle;
  sncConfig = pkgs.writeText "swaync-config" (builtins.toJSON swayncConfig);
  sncStyle = pkgs.writeText "swaync-style" swayncStyle;

in
{
  environment.systemPackages = with pkgs; [ 
    waybar 
    swaynotificationcenter 
    font-awesome 
    libnotify 
    networkmanagerapplet # Useful for tray
  ];

  environment.etc."xdg/waybar/config".source = wbConfig;
  environment.etc."xdg/waybar/style.css".source = wbStyle;
  environment.etc."xdg/swaync/config.json".source = sncConfig;
  environment.etc."xdg/swaync/style.css".source = sncStyle;

  # Autostart (Metoda Systemd dla pewności)
  system.activationScripts.setupUI = lib.mkAfter ''
    USER_HOME="/home/omnios"
    # Skrypt restartujący usługi UI
    cat > "$USER_HOME/start-ui.sh" <<EOF
#!/bin/sh
pkill waybar
pkill swaync
${pkgs.swaynotificationcenter}/bin/swaync &
sleep 1
${pkgs.waybar}/bin/waybar &
EOF
    chmod +x "$USER_HOME/start-ui.sh"
    
    # Dodajemy do autostartu
    mkdir -p "$USER_HOME/.config/autostart"
    cat > "$USER_HOME/.config/autostart/ui.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=UI
Exec=$USER_HOME/start-ui.sh
X-KDE-AutostartScript=true
EOF
    chown -R omnios:users "$USER_HOME"
  '';
}