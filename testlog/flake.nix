{
  description = "Test Logger development environment";

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
            rubyPackages_3_4.ruby-vips
            rubyPackages_3_4.psych
            sqlite
            nodejs
            imagemagick
          ];

          # Use bundler to manage Rails version instead of Nix
          shellHook = ''
            export GEM_HOME=$PWD/.gems
            export PATH=$GEM_HOME/bin:$PATH
            echo "Installing dependencies from Gemfile..."
            gem install bundler
            bundle install
            echo "Ruby $(ruby --version) with Rails $(rails --version)"
          '';
        };
      }
    );
}
