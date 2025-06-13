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
            jq
          ];

          # Use bundler to manage Rails version instead of Nix
          shellHook = ''
            export GEM_HOME=$PWD/.gems
            export PATH=$GEM_HOME/bin:$PATH
            
            # Add bin directory to PATH for easy access to scripts
            export PATH=$PWD/bin:$PATH
            
            echo "Installing dependencies from Gemfile..."
            gem install bundler
            bundle install
            echo "Ruby $(ruby --version) with Rails $(rails --version)"
            echo ""
            echo "Custom scripts available (without bin/ prefix):"
            echo "  rspec-find     - Find first failing test with details"
            echo "  rspec-memory   - Run tests with memory profiling"
            echo "  rspec-quick    - Run tests quickly with in-memory DB"
            echo "  rspec-quicker  - Run tests in parallel with fail-fast"
            echo "  rspec-replace  - Test replacements for broken tests"
            echo "  test-memory    - Run tests with memory analysis"
          '';
        };
      }
    );
}
