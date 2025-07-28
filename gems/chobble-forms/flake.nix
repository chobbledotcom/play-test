{
  description = "EN14960 gem development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ruby_3_4
            rubyPackages_3_4.psych
          ];

          shellHook = ''
            export GEM_HOME=$PWD/.gems
            export PATH=$GEM_HOME/bin:$PATH
            export PATH=$PWD/bin:$PATH

            if [ ! -d ".gems" ]; then
              echo "Installing gems..."
              bundle install
            fi

            echo "Ruby $(ruby --version)"
          '';
        };
      }
    );
}
