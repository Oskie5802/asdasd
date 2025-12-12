{ config, pkgs, lib, ... }:
let
  # Ścieżka do logo
  logoPath = ../../assets/light.jpeg;
  
  # Własny Plymouth theme
  customPlymouth = pkgs.stdenv.mkDerivation {
    name = "plymouth-omnios-theme";
    buildInputs = [ pkgs.imagemagick ];
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/share/plymouth/themes/omnios
      
      # Skopiuj logo - mniejsze dla lepszej wydajności w VM
      ${pkgs.imagemagick}/bin/convert \
        ${logoPath} \
        -resize 400x400 \
        -background black -gravity center -extent 1920x1080 \
        $out/share/plymouth/themes/omnios/background.png
      
      # Plik konfiguracyjny motywu
      cat > $out/share/plymouth/themes/omnios/omnios.plymouth <<EOF
[Plymouth Theme]
Name=OmniOS
Description=OmniOS Boot Theme
ModuleName=script

[script]
ImageDir=$out/share/plymouth/themes/omnios
ScriptFile=$out/share/plymouth/themes/omnios/omnios.script
EOF
      
      # Skrypt Plymouth
      cat > $out/share/plymouth/themes/omnios/omnios.script <<'EOF'
Window.GetMaxWidth = fun() { return 1920; };
Window.GetMaxHeight = fun() { return 1080; };
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

logo.image = Image("background.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);
logo.sprite.SetOpacity(1);
logo.sprite.SetZ(1000);

# Spinner pod logo
spinner_image = Image.Text("●", 1, 1, 1);
spinner.sprite = Sprite(spinner_image);
spinner.sprite.SetX(Window.GetWidth() / 2);
spinner.sprite.SetY(Window.GetHeight() / 2 + 250);

angle = 0;
fun refresh_callback() {
  logo.sprite.SetOpacity(1);
  angle = angle + 0.1;
  spinner.sprite.SetRotation(angle);
}
Plymouth.SetRefreshFunction(refresh_callback);
EOF
    '';
  };
in
{
  # Bootloader z małym timeoutem
  boot.loader.timeout = lib.mkForce 2;
  
  # Silent Boot
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  
  # KERNEL PARAMS - BEZ vga=off (to nie jest poprawny parametr)
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "systemd.show_status=false"
  ];
  
  # Plymouth
  boot.plymouth = {
    enable = true;
    theme = "omnios";
    themePackages = [ customPlymouth ];
  };
  
  # Initrd systemd
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = false;
  
  boot.initrd.systemd.settings.Manager = {
    ShowStatus = "no";
    DefaultStandardOutput = "journal";
    DefaultStandardError = "journal";
    LogLevel = "notice";
  };
  
  # Wycisz systemd
  systemd.settings.Manager = {
    ShowStatus = "no";
    DefaultStandardOutput = "journal";
    DefaultStandardError = "journal";
    LogLevel = "notice";
  };
  
  # Opóźnij SDDM dla Plymouth
  systemd.services.display-manager = {
    after = [ "plymouth-quit.service" ];
    wants = [ "plymouth-quit.service" ];
  };
  
  # Wycisz getty
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;
  
  # OS Release
  environment.etc."os-release".text = lib.mkForce ''
    NAME="OmniOS"
    ID=omnios
    PRETTY_NAME="OmniOS AI-Native"
    ANSI_COLOR="1;34"
    HOME_URL="https://omnios.ai"
  '';
}