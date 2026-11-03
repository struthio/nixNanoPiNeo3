{
	description = "NixOS for FriendlyElec NanoPi NEO3";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
	};

	outputs = { self, nixpkgs, ... }:

		let
			neo3 = nixpkgs.lib.nixosSystem {

				modules = [
					# Generic NixOS ARM64 SD image.
					"${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"

					./configuration.nix

					({ lib, pkgs, ... }: {

						# No ZFS
						boot.supportedFilesystems.zfs = lib.mkForce false;
						boot.initrd.supportedFilesystems.zfs = lib.mkForce false;

						# U-Boot, not GRUB.
						boot.loader.grub.enable = lib.mkForce false;
						boot.loader.generic-extlinux-compatible.enable = true;

						# NanoPi NEO3 device tree.
						nixpkgs.hostPlatform = "aarch64-linux";
						hardware.deviceTree = {
							enable = true;
							dtbSource = ./dtbs;
							name = "rockchip/rk3328-nanopi-neo3-rev02.dtb";
						}};

						sdImage = {
							compressImage = false;

							# Leave enough space at the beginning of the
							# SD card for U-Boot
							firmwarePartitionOffset = 32;

							# Remove RapberryPi Firmware from generic image
							populateFirmwareCommands = lib.mkForce "";
                            
							postBuildCommands = ''
								set -e

								echo "Installing NEO3 U-Boot..."

								# Write the Armbian U-Boot image at 32 KiB.
								dd if=${./u-boot/u-boot-rockchip.bin} \
									of="$img" \
									bs=32k seek=1 \
									conv=notrunc

								echo "Generating U-Boot environment..."

								# Generate environment image.
								${pkgs.buildPackages.ubootTools}/bin/mkenvimage \
									-s 0x8000 \
									-o uboot-env.bin \
									${./u-boot/neo3.env}

									# Verify its size.
									test "$(stat -c %s uboot-env.bin)" -eq 32768

									# ENV_OFFSET = 0x3F8000 = 127 * 32 KiB.
									dd if=uboot-env.bin \
										of="$img" \
										bs=32k seek=127 \
										conv=notrunc

									echo "NEO3 U-Boot and environment installed."
							'';
              
						};
					})
				];
			};
		in
		{
			nixosConfigurations.neo3 = neo3;

			# Flake output for building the SD image.
			images.neo3 = neo3.config.system.build.sdImage;
      
			# Regular NixOS system closure.
			packages.aarch64-linux.neo3 =
				neo3.config.system.build.toplevel;
		};
}
