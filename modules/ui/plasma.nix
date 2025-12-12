{ config, pkgs, lib, ... }:

{
  # --- DISPLAY MANAGER & DESKTOP ---
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
  };
  
  services.displayManager.autoLogin = {
    enable = true;
    user = "omnios";
  };

  services.desktopManager.plasma6.enable = true;
}
