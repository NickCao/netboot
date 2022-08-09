{
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  };
  outputs = { self, nixpkgs, ... }: {
    hydraJobs.netboot = self.nixosConfigurations.netboot.config.system.build.netboot;
    nixosConfigurations.netboot = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, lib, modulesPath, ... }:
          let
            build = config.system.build;
            kernelTarget = pkgs.stdenv.hostPlatform.linux-kernel.target;
          in
          {
            imports = [
              (modulesPath + "/profiles/qemu-guest.nix")
              (modulesPath + "/installer/netboot/netboot.nix")
            ];

            boot = {
              kernelPackages = pkgs.linuxPackages_latest;
              kernelParams = [ "console=ttyS0" ];
            };

            networking.firewall.enable = false;

            services = {
              udisks2.enable = false;
              openssh.enable = true;
            };

            system.build.netboot = pkgs.symlinkJoin {
              name = "netboot";
              paths = [
                build.kernel
                build.netbootRamdisk
                build.netbootIpxeScript
              ];
              postBuild = ''
                mkdir -p $out/nix-support
                echo "file ${kernelTarget} ${build.kernel}/${kernelTarget}" >> $out/nix-support/hydra-build-products
                echo "file initrd ${build.netbootRamdisk}/initrd" >> $out/nix-support/hydra-build-products
                echo "file ipxe ${build.netbootIpxeScript}/netboot.ipxe" >> $out/nix-support/hydra-build-products
              '';
            };

            documentation.nixos.enable = false;
            system.stateVersion = "21.11";
          })
      ];
    };
  };
}
