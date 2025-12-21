{ pkgs, lib, ... }:

let
  # Zakładamy, że masz plik bg.png w folderze assets obok folderu modules
  # Struktura: /twoj-projekt/assets/bg.png
  # Dostosuj ścieżkę ../../../assets/bg.png zależnie od tego gdzie leży ten plik względem theme.nix
  wallPath = ../../assets/wallpaper.png; 
in
{
  # 1. Kopiowanie tapety do systemu
  environment.etc."backgrounds/omnios-bg.png".source = wallPath;
  
  # 2. Ustawienia SDDM (Ekran logowania)
  services.displayManager.sddm.settings = {
      Theme = {
          Current = "breeze";
          # SDDM musi mieć dostęp do pliku, /etc/backgrounds jest bezpieczne
          Background = "/etc/backgrounds/omnios-bg.png";
      };
  };

  # 3. Globalny motyw (opcjonalnie, przygotowanie pod Dark Mode)
  environment.systemPackages = with pkgs; [
    kdePackages.breeze
    kdePackages.breeze-icons
  ];
}