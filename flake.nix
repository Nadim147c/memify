{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = perSystem (pkgs: {
        default = pkgs.callPackage ./default.nix { };
      });
      devShells = perSystem (pkgs: {
        default = pkgs.mkShell {
          name = "memify";
          inputsFrom = [ (pkgs.callPackage ./default.nix { }) ];
          buildInputs = with pkgs; [
            bash
            shellcheck
          ];
        };
      });
    };
}
