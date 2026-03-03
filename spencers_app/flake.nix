{
  description = "RPII Utility - WinForms inspection app running on NixOS via Wine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.dotnet-sdk_9
          pkgs.wineWowPackages.stagingFull
          pkgs.winetricks
        ];

        shellHook = ''
          export DOTNET_CLI_TELEMETRY_OPTOUT=1
          export DOTNET_NOLOGO=1
          export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/rpii-utility/wine"
          export WINEDEBUG=-all
          mkdir -p "$WINEPREFIX"

          echo ""
          echo "=== RPII Utility (NixOS) ==="
          echo ""
          echo "  ./build.sh          Build the Windows exe from Linux"
          echo "  ./build.sh run      Build and launch via Wine"
          echo "  ./build.sh install  Install .desktop entry for app launcher"
          echo ""
        '';
      };
    };
}
