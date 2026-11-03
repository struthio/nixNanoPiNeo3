{ pkgs, ... }:
{
	networking.hostName = "neo3";
	networking.useDHCP = true;

	time.timeZone = "Europe/Warsaw";

	nixpkgs.config.allowUnfree = true;

	services.openssh = {
		enable = true;

		settings = {
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = "no";
		};
	};

	networking.firewall.allowedTCPPorts = [ 22 ];

	users.users.admin = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];

		openssh.authorizedKeys.keys = [
			"--PUBLIC-SSH-KEY-HERE--"
		];
	};

	security.sudo.wheelNeedsPassword = false;
  
	environment.systemPackages = with pkgs; [ 
		mc
	];

	boot.kernelParams = lib.mkForce [
		"console=ttyS2,1500000n8"
		"console=tty0"
	];
	#systemd.services."serial-getty@ttyS2".enable = true;

	nix.settings.experimental-features = [
		"nix-command"
		"flakes"
	];

	zramSwap.enable = true;

	system.stateVersion = "26.05";
}

