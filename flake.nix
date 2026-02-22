{
  description = "`gh` cli wrapper with MCP support packaged by nix";

  inputs = {
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    go.url = "github:amarbel-llc/eng?dir=devenvs/go";
    shell.url = "github:amarbel-llc/eng?dir=devenvs/shell";
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
          rm -f $out/go.work $out/go.work.sum
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
