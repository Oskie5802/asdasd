{ config, pkgs, lib, ... }:

{
  # --- USŁUGI GOŚCIA (SPICE) ---
  # To odpowiada za kopiowanie schowka i automatyczne dopasowanie ekranu
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
