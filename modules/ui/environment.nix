{ config, pkgs, lib, ... }:

{
  # --- ZMIENNE ŚRODOWISKOWE (FIX DLA KURSORA I GRAFIKI) ---
  environment.sessionVariables = {
    # Wymusza renderowanie programowe (skoro nie mamy GL)
    LIBGL_ALWAYS_SOFTWARE = "1";
    
    # --- FIX DLA NIEWIDOCZNEGO KURSORA ---
    # Wyłącza Atomic Mode Setting w KWin. Często naprawia kursor na virtio-vga/gpu
    KWIN_DRM_NO_AMS = "1"; 
    # Alternatywny fix, jeśli powyższy nie zadziała (można mieć oba)
    WLR_NO_HARDWARE_CURSORS = "1";
    
    # Wymusza backend Wayland dla Qt
    QT_QPA_PLATFORM = "wayland";
  };
}
