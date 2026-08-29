{
  description = "Automatic subtitle synchronization for mpv using ffsubsync";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      mpv-auto-sub-sync = pkgs.callPackage ./package.nix {};
      default = mpv-auto-sub-sync;
    });

    overlays.default = final: _: {
      mpv-auto-sub-sync = final.callPackage ./package.nix {};
    };
  };
}
