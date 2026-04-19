{ hostVars, ... }:
{
  imports = [
    ./disko.nix
    ../../profiles/desktop-hyprland.nix
    # ../../profiles/dev.nix
    ../../profiles/networking.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  # Boot: EFI systemd-boot — matches the disko ESP at /boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # SSH — allow password-less login from the Mac mini workstation.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  users.users.${hostVars.username} = {
    isNormalUser    = true;
    extraGroups     = [ "wheel" "docker" "networkmanager" "video" "audio" ];
    initialPassword = hostVars.initialPassword;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChLzSow66DKw6faRewb7+trs9uKDpwP5QrZy+SPa2Xy mickael@workstation"
    ];
  };

  users.users.root = {
    initialPassword = hostVars.initialPassword;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChLzSow66DKw6faRewb7+trs9uKDpwP5QrZy+SPa2Xy mickael@workstation"
    ];
  };
}
