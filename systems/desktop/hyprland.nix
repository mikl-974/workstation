{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL          = "1";
    XDG_CURRENT_DESKTOP     = "Hyprland";
    XDG_SESSION_TYPE        = "wayland";
    # Fallback pour les VMs et machines sans curseur HW Wayland
    WLR_NO_HARDWARE_CURSORS = "1";
    # Forcer le renderer software si pas de GPU Vulkan/DRM
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    # Qt/Noctalia — software rendering fallback (EGL surface errors)
    QT_QPA_PLATFORM         = "wayland";
    QT_QUICK_BACKEND        = "software";
  };

  environment.systemPackages = with pkgs; [
    foot
    wl-clipboard
    grim
    slurp
  ];
}
