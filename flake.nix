{
  description = "Odin Programming Language";

  inputs = {
    nixpkgs.url = "github:nixOS/nixpkgs/release-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      # https://ayats.org/blog/no-flake-utils
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});

      name = "odin";
      defaultBuildInputs = (
        {
          pkgs,
          additionalPkgs ? [ ],
        }:
        with pkgs;
        [
          git
          which
          clang_20
          llvmPackages_20.llvm
          llvmPackages_20.bintools
        ]
        ++ additionalPkgs
      );
    in
    {

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inherit name;
          buildInputs = defaultBuildInputs {
            inherit pkgs;
            additionalPkgs = with pkgs; [
              nixfmt-rfc-style
            ];
          };
          shellHook = ''
            CXX=clang++
            echo "Entered development environment"
          '';
        };
      });
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = name;
          version = "dev-2025-10";
          src = ./.;
          nativeBuildInputs = with pkgs; [
            makeBinaryWrapper
            which
          ];
          LLVM_CONFIG = pkgs.lib.getExe' pkgs.llvmPackages.llvm.dev "llvm-config";
          dontConfigure = true;
          buildInputs = defaultBuildInputs {
            inherit pkgs;
          };

          buildFlags = [ "release" ];
          buildPhase = ''
            CXX=clang++
            make -j16
          '';


          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.alsa-lib ];
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp odin $out/bin/odin

            mkdir -p $out/share
            cp -r {base,core,vendor,shared} $out/share

            wrapProgram $out/bin/odin \
              --prefix PATH : ${
                pkgs.lib.makeBinPath (
                  with pkgs.llvmPackages;
                  [
                    bintools
                    llvm
                    clang
                    lld
                  ]
                )
              } \
              --set-default ODIN_ROOT $out/share

            make -C "$out/share/vendor/cgltf/src/"
            make -C "$out/share/vendor/stb/src/"
            make -C "$out/share/vendor/miniaudio/src/"

            runHook postInstall
          '';
        };
      });
    };
}
