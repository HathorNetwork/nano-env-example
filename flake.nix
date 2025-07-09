{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default =
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
          pkgs.mkShell {
            packages = with pkgs; [
              jq
              just
            ];
          };
    });
}
