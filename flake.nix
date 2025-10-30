{
    description = "Natural language models for game discussion";

    inputs = {
        nixpkgs-stable.url                                   = "github:NixOS/nixpkgs";
        nixpkgs-unstable.url                                 = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url                                      = "github:numtide/flake-utils";

        # Core pyproject-nix ecosystem tools
        pyproject-nix.url                                    = "github:pyproject-nix/pyproject.nix";
        uv2nix.url                                           = "github:pyproject-nix/uv2nix";
        pyproject-build-systems.url                          = "github:pyproject-nix/build-system-pkgs";

        # Ensure consistent dependencies between these tools
        pyproject-nix.inputs.nixpkgs.follows                 = "nixpkgs-unstable";
        uv2nix.inputs.nixpkgs.follows                        = "nixpkgs-unstable";
        pyproject-build-systems.inputs.nixpkgs.follows       = "nixpkgs-unstable";
        uv2nix.inputs.pyproject-nix.follows                  = "pyproject-nix";
        pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
    };

    outputs = { self, nixpkgs-stable, nixpkgs-unstable, flake-utils, uv2nix, pyproject-nix, pyproject-build-systems, ... }:
    flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs-stable = import nixpkgs-unstable { 
                inherit system; 
                config = {
                    allowUnfree = true;
                };
            };
            python = pkgs-stable.python312;

            # Load workspace from pyproject.toml + uv.lock
            workspace = uv2nix.lib.workspace.loadWorkspace {
                workspaceRoot = self;
            };

            # Generate overlay from uv.lock
            uvLockedOverlay = workspace.mkPyprojectOverlay {
                sourcePreference = "wheel";
            };

            # Make sure that the tbb package is available as a project dependency 
            # via an overlay
            tbbOverlay = final: prev: {
                numba = prev.numba.overrideAttrs (old: {
                    buildInputs = (old.buildInputs or []) ++ [ pkgs-stable.tbb ];
                    propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ [ pkgs-stable.tbb ];
                });
            };

            # Use a pre-packaged torch as a dependency
            torchOverlay = final: prev: {
                torch = pkgs-stable.libtorch-bin;
            };

            # Resolve file name collisions between dependencies by removing duplicate files
            collisionPatchOverlay = final: prev: {
                choreographer = prev.choreographer.overrideAttrs (old: {
                    postInstall = (old.postInstall or "") + ''
                        rm -f $out/lib/python3.12/site-packages/tests/test_placeholder.py
                        rm -f $out/lib/python3.12/site-packages/tests/conftest.py
                    '';
                });
            };

            # Compose overlays into pythonSet
            pythonSet = (
                pkgs-stable.callPackage pyproject-nix.build.packages { inherit python; }
            ).overrideScope (nixpkgs-unstable.lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                uvLockedOverlay
                tbbOverlay
                torchOverlay
                collisionPatchOverlay
            ]);

            # Access project metadata AFTER overlays are applied
            projectNameInToml = "game-discussion-nlp";
            thisProjectAsNixPkg = pythonSet.${projectNameInToml};

            # Create virtualenv from resolved deps
            appPythonEnv = pythonSet.mkVirtualEnv
                (thisProjectAsNixPkg.pname + "-env")
                workspace.deps.default;
        in
        {
            devShells.default = pkgs-stable.mkShell {
                packages = [
                    # Python
                    appPythonEnv
                    pkgs-stable.uv
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

                    # # Force PATH to use only the devshell's Python
                    # export PYTHONNOUSERSITE=1
                    #
                    # # Force PATH to prioritize devshell Python
                    # export PATH="$(dirname $(which python3)):$PATH"
                    #
                    # # Alias python to python3 for consistency
                    # alias python=python3
                    #
                    # echo "Using Python from: $(which python3)"
                    #
                    # # Install Bertopic via pip
                    # # Bertopic isn't a nix packages, but we can still have a 
                    # # declaritive version of it using .env
                    # if [ ! -d ".venv" ]; then
                    #     python -m venv .venv
                    #     source .venv/bin/activate
                    #     pip install --upgrade pip
                    #     pip install bertopic
                    #     pip install kaleido
                    #     echo "Virtualenv created and bertopic installed"
                    # else
                    #     source .venv/bin/activate
                    #     echo "Virtualenv activated"
                    # fi
                '';
            };
        }
    );
}
