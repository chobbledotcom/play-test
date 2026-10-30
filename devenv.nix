{ pkgs, ... }:

{
  # Rails loads .env itself; devenv must not inject it into the shell
  dotenv.disableHint = true;

  packages = with pkgs; [
    actionlint
    cmake
    gh
    jq
    libyaml
    nodejs
    openssl
    pkg-config
    python3
    rubyPackages_3_4.openssl
    rubyPackages_3_4.psych
    rubyPackages_3_4.ruby-vips
    rubyPackages_3_4.rugged
    ruby_3_4
    sqlite
    yamlfix
    yamllint
  ];

  # Use bundler to manage Rails version instead of Nix
  enterShell = ''
    export GEM_HOME="$DEVENV_ROOT/.gems"
    export PATH="$GEM_HOME/bin:$DEVENV_ROOT/bin:$PATH"

    echo "Ruby $(ruby --version) with Rails $(rails --version)"
    echo ""
    echo "Scripts available:"
    echo "  init           - Initialize project (submodules, bundle, .env)"
    echo "  rspec-find     - Find first failing test with details"
    echo "  rspec-memory   - Run tests with memory profiling"
    echo "  rspec-quick    - Run tests quickly with in-memory DB"
    echo "  rspec-quicker  - Run tests in parallel with fail-fast"
    echo "  rspec-replace  - Test replacements for broken tests"
    echo "  test-memory    - Run tests with memory analysis"
    echo "  find           - Run ripgrep for a string, useful dirs only"
    echo "  flay           - Run structural duplicate detection on codebase"
    echo "  grade-code     - Grade source and spec files against the house rules with Jev"
    echo "  jscpd          - Run copy-paste detection on codebase"
    echo "  update-chobble - Update chobble-forms and en14960 gems"
  '';
}
