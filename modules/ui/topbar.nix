{ config, pkgs, lib, ... }:

let
  # Kolory - SOLIDNE (Bez przezroczystości dla wydajności)
  colors = {
    barBg = "#ffffff";      # Czysta biel (nie rgba)
    text = "#000000";
    ccBg = "#1e1e2e";       # Ciemne menu
    ccWidget = "#313244";
    accent = "#3b82f6";
    white = "#ffffff";
  };

  # Waybar Config
  waybarConfig = {
    layer = "overlay";
    position = "top";
    height = 36;
    
    # KLUCZOWE USTAWIENIA
    exclusive = false;          # Rezerwuje miejsce (okna nie wchodzą pod pasek)
    passthrough = true;       # Kliknięcia nie przechodzą przez pasek
    anchor = [ "top" "left" "right" ]; # Wyraźne zakotwiczenie (pomaga w obliczeniach)
    
    # Opcjonalnie: margines w konfiguracji (nie CSS), aby wymusić większą strefę
    # margin-bottom = 0; 

    modules-left = [ "custom/omni" "wlr/taskbar" ];
    modules-center = [ "clock" ];
    modules-right = [ "custom/control" ];
    
    # ... reszta Twojej konfiguracji bez zmian ...
    "custom/omni" = {
      format = "Omni"; 
      on-click = "${pkgs.kdePackages.krunner}/bin/krunner";
      tooltip = false;
    };
    
    # UWAGA: wlr/taskbar może nie działać idealnie na KDE (KWin). 
    # Jeśli pasek znika lub miga, usuń ten moduł.
    "wlr/taskbar" = {
      format = "{icon}";
      icon-size = 18;
      on-click = "activate";
      tooltip = true;
      ignore-list = [ "Waybar" "Swaync" ];
    };

    "clock" = {
      format = "{:%a %d %b  %H:%M}";
    };

    "custom/control" = {
      format = "          "; 
      tooltip = false;
      on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    };
  };

  # Styl CSS - Premium Glassmorphism
  waybarStyle = ''
    * {
        border: none;
        border-radius: 0;
        font-family: "Manrope", "Inter", sans-serif;
        font-size: 14px;
    }
    window#waybar {
        background: rgba(255, 255, 255, 0.7);
        color: #1d1d1f;
        border-bottom: 1px solid rgba(0, 0, 0, 0.05);
        transition: all 0.3s ease;
    }
    #custom-omni {
        font-weight: 800;
        padding: 0 15px;
        margin: 4px 10px;
        background: rgba(0, 0, 0, 0.05);
        border-radius: 10px;
        font-size: 13px;
    }
    #clock {
        font-weight: 600;
        color: #1d1d1f;
    }
    #custom-control {
        background: rgba(0, 0, 0, 0.05);
        border-radius: 10px;
        padding: 0 12px;
        margin: 4px 10px;
        color: #1d1d1f;
        font-size: 12px;
    }
    #taskbar button {
        padding: 0 10px;
        margin: 4px 2px;
        border-radius: 8px;
        transition: all 0.2s;
    }
    #taskbar button:hover {
        background: rgba(0, 0, 0, 0.1);
    }
    #taskbar button.active {
        background: rgba(0, 0, 0, 0.05);
        border-bottom: 2px solid #3b82f6;
    }
  '';

  # Control Center Config (SwayNC) - Bez zmian, bo jest ok
  swayncConfig = {
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    control-center-layer = "top";
    control-center-margin-top = 10;
    control-center-margin-bottom = 10;
    control-center-margin-right = 10;
    control-center-margin-left = 10;
    widgets = [ "title" "buttons-grid" "volume" "backlight" "dnd" ];
    widget-config = {
      title = { text = "Omni Control"; clear-all-button = true; button-text = "Clear"; };
      buttons-grid = {
        actions = [
            { label = "Wi-Fi"; command = "kcmshell6 kcm_networkmanagement"; }
            { label = "Bluetooth"; command = "kcmshell6 kcm_bluetooth"; }
            { label = "Settings"; command = "systemsettings"; }
            { label = "Display"; command = "kcmshell6 kcm_kscreen"; }
            { label = "Power"; command = "kcmshell6 powerdevilprofilesconfig"; }
        ];
      };
    };
  };

  swayncStyle = ''
    * { font-family: "Inter", sans-serif; }
    .control-center {
      background: ${colors.ccBg};
      border: 1px solid ${colors.ccWidget};
      border-radius: 16px;
      padding: 12px;
    }
    .widget-title { color: ${colors.white}; font-weight: bold; margin-bottom: 8px; }
    .widget-title > button { background: ${colors.ccWidget}; color: #ccc; border: none; border-radius: 6px; padding: 4px 10px; }
    .widget-buttons-grid > flowbox > flowboxchild > button {
      background: ${colors.accent}; color: ${colors.white}; border-radius: 10px; margin: 3px; padding: 12px; border: none; min-width: 80px;
    }
    .widget-volume, .widget-backlight { background: ${colors.ccWidget}; border-radius: 12px; padding: 10px; margin: 5px 0; }
    trough { background: #45475a; border-radius: 6px; min-height: 6px; }
    highlight { background: ${colors.white}; border-radius: 6px; }
    slider { background: ${colors.white}; }
  '';

  wbConfig = pkgs.writeText "waybar-config" (builtins.toJSON waybarConfig);
  wbStyle = pkgs.writeText "waybar-style" waybarStyle;
  sncConfig = pkgs.writeText "swaync-config" (builtins.toJSON swayncConfig);
  sncStyle = pkgs.writeText "swaync-style" swayncStyle;

in
{
  environment.systemPackages = with pkgs; [ waybar swaynotificationcenter font-awesome libnotify ];

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