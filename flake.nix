{
  description = "RISC-V Otter Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
      };

    mkProject = system:
      let
        pkgs = mkPkgs system;
        riscv = pkgs.pkgsCross.riscv32-embedded.buildPackages;
        tools = [
          riscv.gcc
          riscv.binutils
          pkgs.gnumake
          pkgs.hexdump
        ];
      in {
        devShells.default = pkgs.mkShell {
          packages = tools;
        };

        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "rv32i-program";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = tools;

          buildPhase = ''
            runHook preBuild
            make
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp build/program.elf build/program.dump build/program.bin build/program.mem $out/

            runHook postInstall
          '';
        };
      };
  in {
    devShells = forAllSystems (system: (mkProject system).devShells);
    packages = forAllSystems (system: (mkProject system).packages);
  };
}
