{
    description = "Natural language models for game discussion";

    inputs = {
        core.url = "git+file:///home/shiloh/.config/flakes/core";
    };

    outputs = { self, core }:
    let
        system = "x86_64-linux";
        pkgs-stable = core.packages.${system}.pkgs-stable;
        pkgs-unstable = core.packages.${system}.pkgs-unstable;
    in
    {
        devShells.${system}.default = pkgs-stable.mkShell {
            packages = [
                # Python
                (pkgs-stable.python313.withPackages (p: with p; [
                    sentence-transformers  # ML model for lang analysis
                    pandas                 # Data manipulation
                    numpy                  # Data manipulation
                    pip                    # Python package manger
                    kaleido                # Plotly images saving engine
                ]))
                pkgs-stable.xdg-utils        # Opening web browser
                pkgs-stable.chromedriver     # Interacting with web browser automatically
                pkgs-stable.selenium-manager # Interacting with web browser automatically
                pkgs-stable.chromium         # chrome itself
                pkgs-stable.dotnet-sdk       # F#
                pkgs-stable.fsautocomplete   # F# lsp
            ];

            env.LD_LIBRARY_PATH = pkgs-stable.lib.makeLibraryPath [
                pkgs-stable.stdenv.cc.cc.lib
                pkgs-stable.libz
            ];

            shellHook = ''
                # Epose the location to these bins for webscraping
                export CHROMEDRIVER_PATH=$(which chromedriver)
                export CHROME_PATH=$(which chrome)

                # Force PATH to use only the devshell's Python
                export PYTHONNOUSERSITE=1

                # Force PATH to prioritize devshell Python
                export PATH="$(dirname $(which python3)):$PATH"

                # Alias python to python3 for consistency
                alias python=python3

                echo "Using Python from: $(which python3)"

                # Install Bertopic via pip
                # Bertopic isn't a nix packages, but we can still have a 
                # declaritive version of it using .env
                if [ ! -d ".venv" ]; then
                    python -m venv .venv
                    source .venv/bin/activate
                    pip install --upgrade pip
                    pip install bertopic
                    pip install kaleido
                    echo "Virtualenv created and bertopic installed"
                else
                    source .venv/bin/activate
                    echo "Virtualenv activated"
                fi
            '';
        };
    };
}
