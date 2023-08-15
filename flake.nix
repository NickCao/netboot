{
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs";
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
              (modulesPath + "/profiles/minimal.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              (modulesPath + "/installer/netboot/netboot.nix")
            ];

            boot = {
              kernelPackages = pkgs.linuxPackages_latest;
              supportedFilesystems = [ "btrfs" ];
            };

            networking.useNetworkd = true;
            networking.firewall.enable = false;

            services = {
              udisks2.enable = false;
              openssh = {
                enable = true;
                authorizedKeysFiles = [ "/run/authorized_keys" ];
              };
              getty.autologinUser = "root";
            };

            security.sudo.enable = false;

            systemd.services.process-cmdline = {
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              script = ''
                export PATH=/run/current-system/sw/bin:$PATH
                xargs -n1 -a /proc/cmdline | while read opt; do
                  if [[ $opt = sshkey=* ]]; then
                    echo "''${opt#sshkey=}" >> /run/authorized_keys
                  fi
                  if [[ $opt = script=* ]]; then
                    curl -L "''${opt#script=}" | ${pkgs.runtimeShell}
                  fi
                done
              '';
            };

            system.build.netboot = pkgs.runCommand "netboot" { } ''
              mkdir -p $out

              ln -s ${build.kernel}/${kernelTarget}         $out/${kernelTarget}
              ln -s ${build.netbootRamdisk}/initrd          $out/initrd
              ln -s ${build.netbootIpxeScript}/netboot.ipxe $out/ipxe
            '';

            zramSwap.enable = true;

            system.stateVersion = "23.05";
          })
      ];
    };
  };
}
