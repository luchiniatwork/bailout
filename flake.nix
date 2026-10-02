{
  description = "bailout — the harness meant to be deleted";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # macOS ARM64, Linux x64, and Linux ARM64 only (see AGENTS.md).
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = bailout;
        bailout = pkgs.rustPlatform.buildRustPackage {
          pname = "bailout";
          version = "0.7.3";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          # Keep the 6 MB release budget honest in nix builds too.
          postInstall = ''
            size=$(wc -c < $out/bin/bailout)
            if [ "$size" -ge 6000000 ]; then
              echo "bailout exceeds the 6 MB budget ($size bytes)" >&2
              exit 1
            fi
            echo "bailout binary: $size bytes"
          '';
          meta = {
            description = "The harness meant to be deleted. Bootstrap fresh machines and repair broken coding tools.";
            homepage = "https://github.com/storozhenko98/bailout";
            license = pkgs.lib.licenses.mit;
            mainProgram = "bailout";
            platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            # Rust toolchain: build, lint, format.
            pkgs.rustc
            pkgs.cargo
            pkgs.clippy
            pkgs.rustfmt
            pkgs.rust-analyzer

            # Verification scripts (AGENTS.md): smoke.py is stdlib-only,
            # record-demo.py/render-demo.py need pillow and pyte.
            (pkgs.python3.withPackages (ps: [ ps.pillow ps.pyte ]))

            # Installer/release tooling.
            pkgs.curl
          ];
        };
      });
    };
}
