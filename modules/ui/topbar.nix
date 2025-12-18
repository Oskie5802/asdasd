{ config, pkgs, lib, ... }:

let
  # --- Assets & Paths ---
  logoPath = ../../assets/logo-trans.png;

  # --- Aesthetics / Tokens ---
  colors = {
    bg = "rgba(255, 255, 255, 0.75)"; # Adjusted transparency
    text = "#1d1d1f"; # Mac dark grey
    accent = "#007AFF"; 
  };

  # --- Waybar Config ---
  waybarConfig = {
    layer = "top";
    position = "top";
    height = 44; # Increased height
    exclusive = true;
    passthrough = false;
    all-outputs = true;
    mode = "dock";
    anchor = [ "top" "left" "right" ];
    gtk-layer-shell = true;

    modules-left = [ "custom/logo" ];
    modules-center = [ "clock" ];
    modules-right = [ "network" "bluetooth" "custom/control" ];

    "custom/logo" = {
      format = ""; 
      tooltip = false;
      on-click = "krunner"; # Simple command
    };

    "clock" = {
      format = "{:%a %d %b   %H:%M}";
      tooltip-format = "<tt>{calendar}</tt>";
      calendar = {
        mode = "month";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        format = {
          months = "<span color='#007AFF'><b>{}</b></span>";
          days = "<span color='#000000'><b>{}</b></span>";
          weeks = "<span color='#007AFF'><b>W{}</b></span>";
          today = "<span color='#ffffff' background='#007AFF'><b>{}</b></span>";
        };
      };
      actions = {
        on-click-right = "mode";
        on-click-middle = "shift_reset";
        on-scroll-up = "shift_up";
        on-scroll-down = "shift_down";
      };
    };

    "network" = {
      format-wifi = "";
      format-ethernet = "";
      format-disconnected = "";
      tooltip-format = "{essid} ({signalStrength}%)";
      on-click = "kcmshell6 kcm_networkmanagement";
    };

    "bluetooth" = {
      format = "";
      format-disabled = ""; 
      format-connected = "";
      tooltip-format = "{controller_alias}\t{controller_address}";
      on-click = "kcmshell6 kcm_bluetooth";
    };

    "custom/control" = {
      format = "";
      tooltip = false;
      on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    };
  };

  # --- Waybar CSS ---
  waybarStyle = ''
    * {
        border: none;
        border-radius: 0;
        font-family: "SF Pro Display", "Manrope", "Inter", sans-serif;
        font-size: 14px;
        min-height: 0;
    }

    window#waybar {
        background: rgba(255, 255, 255, 0.75); /* Glassy white */
        color: #1d1d1f;
        border-bottom: 1px solid rgba(0,0,0,0.05);
        backdrop-filter: blur(20px); /* Strong blur */
    }

    #custom-logo {
        background-image: url("${logoPath}");
        background-size: 20px;
        background-repeat: no-repeat;
        background-position: center;
        padding: 0 20px; 
        margin: 4px 8px;
        color: #2c2c2e;
        font-size: 22px;
        transition: all 0.2s;
    }
    
    #custom-logo:hover {
        opacity: 0.8;
    }

    #clock {
        font-weight: 700;
        padding: 0 15px;
        color: #1d1d1f;
    }

    #network, #bluetooth, #custom-control {
        padding: 0 12px;
        margin: 4px 2px;
        color: #1d1d1f;
        border-radius: 8px;
        transition: all 0.2s;
    }
    
    #network:hover, #bluetooth:hover, #custom-control:hover, #clock:hover {
        background: rgba(0,0,0,0.05);
    }

    /* --- BEAUTIFUL CALENDAR TOOLTIP --- */
    tooltip {
        background: rgba(255, 255, 255, 0.95);
        border: 1px solid rgba(0,0,0,0.1);
        border-radius: 16px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.15);
        padding: 15px;
    }
    tooltip label {
        color: #1d1d1f; /* Force black text */
        font-family: "SF Mono", "Monospace";
    }
  '';

  # --- SwayNC Config ---
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
      "dnd" 
      "notifications"
    ];
    
    widget-config = {
      title = { text = "Control Center"; clear-all-button = true; button-text = "Clear"; };
      buttons-grid = {
        actions = [
            { label = "Wi-Fi"; command = "kcmshell6 kcm_networkmanagement"; }
            { label = "Bluetooth"; command = "kcmshell6 kcm_bluetooth"; }
            { label = "Settings"; command = "systemsettings"; }
        ];
      };
    };
  };

  # --- SwayNC CSS ---
  swayncStyle = ''
    * { 
      font-family: "SF Pro Display", "Manrope", sans-serif; 
    }
    .control-center {
      background: rgba(255, 255, 255, 0.85); /* Glassy white */
      border: 1px solid rgba(255, 255, 255, 0.5);
      border-radius: 20px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.15);
      padding: 16px;
      backdrop-filter: blur(30px);
    }
    .widget-title { color: #1d1d1f; margin-bottom: 10px; }
    .widget-title > label { font-weight: 800; font-size: 18px; }
    .widget-title > button { 
        background: #e5e5ea; color: #1d1d1f; border-radius: 12px; padding: 6px 12px; border: none; font-weight: 600;
    }
    .widget-buttons-grid > flowbox > flowboxchild > button {
      background: #e5e5ea; 
      color: #1d1d1f; 
      border-radius: 14px;
      margin: 4px; 
      min-width: 60px; min-height: 50px;
      border: none;
    }
    .widget-buttons-grid > flowbox > flowboxchild > button:hover {
      background: #d1d1d6;
    }
    .widget-volume, .widget-backlight {
      background: #f2f2f7; border-radius: 16px; padding: 12px; margin: 8px 0;
    }
    trough { background: #d1d1d6; border-radius: 6px; min-height: 6px; }
    highlight { background: #007AFF; border-radius: 6px; }
    slider { background: #fff; box-shadow: 0 2px 5px rgba(0,0,0,0.2); margin: -4px; min-width: 14px; min-height: 14px; border-radius: 50%; }
    .notification {
        background: #fff; border-radius: 14px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); color: #1d1d1f;
    }
  '';

  # Writing Config Files
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
    kdePackages.krunner 
    dbus
  ];

  environment.etc."xdg/waybar/config".source = wbConfig;
  environment.etc."xdg/waybar/style.css".source = wbStyle;
  environment.etc."xdg/swaync/config.json".source = sncConfig;
  environment.etc."xdg/swaync/style.css".source = sncStyle;

  # Autostart
  system.activationScripts.setupUI = lib.mkAfter ''
    USER_HOME="/home/omnios"
    
    cat > "$USER_HOME/start-ui.sh" <<EOF
#!/bin/sh
# Log startup
echo "Starting UI elements..." > "$USER_HOME/ui-start.log"

# Clean up
pkill waybar
pkill swaync

# Fix DBus for reliable service processing helps SwayNC
${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Start SwayNC (Control Center)
${pkgs.swaynotificationcenter}/bin/swaync > /tmp/swaync.log 2>&1 &

# Wait for services
sleep 2

# Start Waybar
${pkgs.waybar}/bin/waybar -c /etc/xdg/waybar/config -s /etc/xdg/waybar/style.css > /tmp/waybar.log 2>&1 &

echo "Done." >> "$USER_HOME/ui-start.log"
EOF

    chmod +x "$USER_HOME/start-ui.sh"
    mkdir -p "$USER_HOME/.config/autostart"
    cat > "$USER_HOME/.config/autostart/ui.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Omni UI
Exec=$USER_HOME/start-ui.sh
X-KDE-AutostartScript=true
EOF
    chown -R omnios:users "$USER_HOME"
  '';
}