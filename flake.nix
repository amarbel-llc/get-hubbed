{
  description = "`gh` cli wrapper with MCP support packaged by nix";

  inputs = {
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    go.url = "github:friedenberg/eng?dir=devenvs/go";
    shell.url = "github:friedenberg/eng?dir=devenvs/shell";
    purse-first = {
      url = "github:amarbel-llc/purse-first";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      go,
      shell,
      nixpkgs-master,
      purse-first,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            go.overlays.default
          ];
        };

        version = "0.1.0";

        get-hubbed-src = pkgs.runCommand "get-hubbed-src" { } ''
          cp -r ${./.} $out
          chmod -R u+w $out
          mkdir -p $out/deps
          cp -r ${purse-first.lib.goSrc} $out/deps/purse-first
        '';

        get_hubbed = pkgs.buildGoApplication {
          pname = "get-hubbed";
          inherit version;
          pwd = get-hubbed-src;
          src = get-hubbed-src;
          modules = ./gomod2nix.toml;
          subPackages = [ "cmd/get-hubbed" ];

          postInstall = ''
            $out/bin/get-hubbed generate-plugin $out/share/purse-first
          '';

          meta = with pkgs.lib; {
            description = "`gh` cli wrapper with MCP support packaged by nix";
            homepage = "https://github.com/friedenberg/get-hubbed";
            license = licenses.mit;
          };
        };
      in
      {
        packages = {
          default = get_hubbed;
          inherit get_hubbed;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
          ];

          inputsFrom = [
            go.devShells.${system}.default
            shell.devShells.${system}.default
          ];

          shellHook = ''
            echo "get-hubbed - dev environment"
          '';
        };

        apps.default = {
          type = "app";
          program = "${get_hubbed}/bin/get-hubbed";
        };
      }
    );
}
