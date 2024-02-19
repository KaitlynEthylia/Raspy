{
  description = "A ""Kernel"" for Raspberry Pi 3 that just echos back whatever was sent to it over UART, with its character count.";

  inputs = {
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, utils, ... }: utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs { inherit system; };
  in rec {
    packages.default = pkgs.stdenv.mkDerivation {
      pname = "Raspy";
      version = "0.0.0";

      src = ./.;

      buildInputs = [ pkgs.zig ];
      nativeBuildInputs = [ pkgs.qemu ];

      buildPhase = ''
        XDG_CACHE_HOME="xdg_cache" zig build
      '';

      installPhase = ''
        mkdir -p $out
        cp -r zig-out/* $out
      '';
    };

    devShells.default = packages.default.overrideAttrs (self: prev: {
      buildInputs = [
        pkgs.coreboot-toolchain.aarch64
        pkgs.zls
      ] ++ prev.buildInputs;
    });

    apps = let
      app = deps: task: {
        type = "app";
        program = toString (pkgs.writeShellApplication {
          name = "app";
          runtimeInputs = [ pkgs.zig ] ++ deps;
          text = "zig build " + task;
        }) + "/bin/app";
      };
    in {
      qemu = app [ pkgs.qemu ] "qemu";
      build = app [] "";
      default = apps.qemu;
    };
  });
}
