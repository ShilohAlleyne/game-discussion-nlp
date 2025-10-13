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

        py = pkgs-stable.python313;

        en_core_web_sm = py.pkgs.buildPythonPackage {
            pname = "en_core_web_sm";
            version = "3.8.0";
            format = "wheel";
            src = builtins.path {
                name = "en_core_web_sm";
                path = ./vendor/en_core_web_sm-3.8.0-py3-none-any.whl;
            };
            meta.description = "spaCy English model (en_core_web_sm)";
        };
    in
    {
        devShells.${system}.default = pkgs-stable.mkShell {
            packages = [
                # Python
                (pkgs-stable.python313.withPackages (p: with p; [
                    spacy                  # ML Lib
                    en_core_web_sm         # ML model
                    sentence-transformers
                    pandas
                    numpy
                ]))
                pkgs-stable.xdg-utils      # Opening web browser
                pkgs-stable.chromedriver
                pkgs-stable.selenium-manager
                pkgs-stable.chromium
                pkgs-stable.dotnet-sdk     # F#
                pkgs-stable.fsautocomplete # F# lsp
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
            '';
        };
    };
}
