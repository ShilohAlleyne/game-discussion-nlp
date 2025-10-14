{
    description = "Natural language models for game discussion";

    inputs = {
        core.url = "git+file:///home/shiloh/.config/flakes/core";
        poetry2nix.url = "github:nix-community/poetry2nix";
    };

    outputs = { self, core, poetry2nix }:
    let
        system = "x86_64-linux";
        pkgs-stable = core.packages.${system}.pkgs-stable;
        pkgs-unstable = core.packages.${system}.pkgs-unstable;
        p2n = poetry2nix.lib.mkPoetry2Nix { inherit pkgs-stable; };

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
                pkgs-stable.chromedriver
                pkgs-stable.chromium
                pkgs-stable.dotnet-sdk
                pkgs-stable.fsautocomplete
            ];

            inputsFrom = [
                p2n.mkPoetryEnv {
                    projectDir = ./.;
                    python = pkgs-stable.python311;
                }
            ];

            shellHook = ''
                export CHROMEDRIVER_PATH=$(which chromedriver)
                export CHROME_PATH=$(which chromium)
            echo "Poetry2nix shell ready"
            '';
        };
    };
}
