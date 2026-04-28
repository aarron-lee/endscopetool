{
  description = "A flake for endscopetool";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    flint.url = "github:notashelf/flint";
    flint.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
      flint,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python313;
        deps = ps: [
          (ps.opencv4.override { enableGtk3 = true; })
          ps.numpy
          ps.pillow
          ps.trio
        ];
        python-with-mypy = python.withPackages (
          ps:
          (deps ps)
          ++ [
            ps.mypy
            ps.types-pillow
          ]
        );
        endscopetool = python.pkgs.buildPythonApplication {
          pname = "endscopetool";
          version = "0.1.0";
          pyproject = true;
          src = ./.;
          nativeBuildInputs = [
            python.pkgs.setuptools
          ];
          dependencies = deps python.pkgs;
          buildInputs = [ pkgs.gtk3 ];
        };
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            mypy = {
              enable = true;
              settings = {
                binPath = "${python-with-mypy}/bin/mypy";
              };
            };
            ruff.enable = true;
            ruff-format.enable = true;
            flint = {
              enable = true;
              name = "flint";
              entry = "${flint.packages.${system}.default}/bin/flint --fail-if-multiple-versions";
              files = "flake\\.(nix|lock)$";
            };
          };
        };
      in
      {
        packages.default = endscopetool;
        apps.default = {
          type = "app";
          program = "${endscopetool}/bin/endscope";
        };
        checks = {
          inherit pre-commit-check;
        };
        formatter =
          let
            config = self.checks.${system}.pre-commit-check.config;
            script = ''
              ${pkgs.lib.getExe config.package} run --all-files --config ${config.configFile}
            '';
          in
          pkgs.writeShellScriptBin "pre-commit-run" script;
        devShells.default = pkgs.mkShell {
          inherit (pre-commit-check) shellHook;
          buildInputs = pre-commit-check.enabledPackages;
          packages = [
            pkgs.nixfmt-rfc-style
            pkgs.gtk3
            flint.packages.${system}.default
            (python.withPackages deps)
          ];
        };
      }
    );
}
