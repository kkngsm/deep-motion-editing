{
  description = "A Nix-based development environment for the deep-motion-editing project";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-python,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # CUDA support requires allowing unfree packages.
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # CUDA packages for deep learning
        cudaPkgs = pkgs.cudaPackages;
        pythonPkgs = nixpkgs-python.packages.${system};

      in
      {
        devShells.default = pkgs.mkShell {
          # buildInputs provides libraries and tools for the development environment.
          # Nix automatically makes libraries available, e.g., by setting LD_LIBRARY_PATH.
          buildInputs = [
            pythonPkgs."3.8"

            pkgs.gcc # これに libstdc++ が含まれます
            pkgs.zlib # libz.so.1 を提供します

            # Core development tools
            pkgs.uv
            pkgs.git

            # System libraries required by Python packages
            pkgs.ffmpeg-full # For video processing with OpenCV/PyTorch

            # CUDA Toolkit and libraries
            cudaPkgs.cudatoolkit
            cudaPkgs.cudnn
            cudaPkgs.nccl
          ];

          # The shellHook runs when you enter the environment with `nix develop`.
          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
            export UV_LINK_MODE=copy
            export UV_PYTHON_DOWNLOADS=never

            # Create a virtual environment if it doesn't exist
            if [ ! -d ".venv" ]; then
              echo "Creating uv virtual environment in ./.venv..."
              uv venv ./.venv # <-- ここを修正
            fi

            source .venv/bin/activate

            echo "Syncing Python dependencies with pyproject.toml..."
            uv sync

            echo -e "\n✅ uv virtual environment is ready and activated."
          '';
        };
      }
    );
}
