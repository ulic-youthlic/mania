{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane = {
      url = "github:ipetkov/crane";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
    };
    nix-filter = {
      url = "github:numtide/nix-filter";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      rust-overlay,
      crane,
      advisory-db,
      nix-filter,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        pkgs = import nixpkgs {
          localSystem = { inherit system; };
          overlays = [
            (import rust-overlay)
            self.overlays.default
          ];
        };
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
        src =
          with nix-filter.lib;
          filter {
            root = ./.;
            name = "source";
            include = [
              ./mania-codec
              ./mania
              ./mania-macros
              ./examples
              ./.cargo/config.toml
              ./Cargo.toml
              ./Cargo.lock
            ];
            exclude = [
              (matchExt "md")
              (matchExt "mp3")
            ];
          };
        env =
          let
            inherit (pkgs) lib libclang;
            version = lib.getVersion libclang;
            majorVersion = lib.versions.major version;
          in
          {
            BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${libclang.lib}/lib/clang/${majorVersion}/include";
            LIBCLANG_PATH = lib.makeLibraryPath [ libclang.lib ];
          };
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        commonArgs = {
          inherit env cargoArtifacts;
          inherit src;
          pname = "mania";
          strictDeps = true;
          buildInputs = with pkgs; [
            libclang.lib
            openssl.dev
          ];
          nativeBuildInputs = with pkgs; [
            protobuf
            pkg-config
          ];
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;
        packages = {
          mania = craneLib.buildPackage (
            commonArgs
            // {
              inherit cargoArtifacts;
              cargoExtraArgs = ''
                --example mania_multi_login
              '';
              postInstall = ''
                mkdir -p $out/bin

                cp ./target/release/examples/mania_multi_login $out/bin/mania
              '';
            }
          );
          default = self.packages."${system}".mania;
        };
        checks = {
          inherit (self.packages."${system}") mania;
          audit = craneLib.cargoAudit (commonArgs // { inherit advisory-db; });
          clippy = craneLib.cargoClippy (
            commonArgs // { cargoClippyExtraArgs = "--all-targets -- --deny warnings"; }
          );
          fmt = treefmtEval.config.build.check self;
          doc = craneLib.cargoDoc commonArgs;
          test = craneLib.cargoTest (commonArgs // { src = ./.; });
        };
        devShells.default = craneLib.devShell {
          env = env // {
            RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          };
          checks = self.checks.${system};
          packages = with pkgs; [
            # dev
            rust-analyzer
            cargo-flamegraph
            cargo-tarpaulin
            lldb

            # fmt
            nixfmt-rfc-style
            just
            shfmt
            typos
            shellcheck
            dprint
          ];
          shellHook = '''';
        };
      }
    )
    // {
      overlays.default = final: prev: { inherit (self.packages."${final.system}") mania; };
    };
}
