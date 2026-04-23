{ lib, ... }:
{
  # This profile models a concrete target running inside a VM.
  #
  # It intentionally does not choose:
  # - the target disk
  # - the disko layout
  # - the bootloader itself
  # - hypervisor-specific guest tooling
  #
  # Those concerns remain either:
  # - target-specific (`targets/hosts/<name>/`)
  # - or operator-local (`targets/hosts/<name>/vars.nix`)
  options.workstation.machine.virtualMachine.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    readOnly = true;
    description = ''
      Whether this concrete target explicitly models a virtual-machine context.
      This becomes true by importing modules/profiles/virtual-machine.nix.
    '';
  };

  config = {
    workstation.machine.virtualMachine.enable = true;

    # EFI in VMs is often provided by the hypervisor firmware image rather than
    # by persistent firmware variables on a real machine. Keep the host free to
    # override this if a specific VM environment really supports touching them.
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;

    # Small runtime marker useful for post-install inspection inside the guest.
    environment.etc."workstation/machine-context".text = "virtual-machine\n";
  };
}
