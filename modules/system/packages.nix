{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core utils
    git
    wget
    curl
    vim
    nixos-rebuild
    
    # Terminal & UI Utils
    kitty
    jq # Do parowania JSONów z AI w bashu (tymczasowo)
    kdePackages.konsole
    
    # Desktop & UI
    firefox
    kdePackages.kate
    kdePackages.plasma-workspace
    kdePackages.ark
    kdePackages.gwenview
    kdePackages.krunner
    
    # Graphics & Rendering
    mesa
    libglvnd
    spice-vdagent
    kdePackages.libkscreen
  ];
  
  # Włączenie czcionek (ważne, żeby Hyprland miał ikony)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}