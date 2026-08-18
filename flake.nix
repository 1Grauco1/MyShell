{
  description = "G_ant Shell - A modern, modular desktop shell for Hyprland built with Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.${system} or (import nixpkgs { inherit system; });
          qsPkg = quickshell.packages.${system}.default;
          pythonEnv = pkgs.python3.withPackages (ps: with ps; [ pillow ijson psutil requests ]);
          runtimeDeps = with pkgs; [
            qsPkg
            pythonEnv
            bash
            coreutils
            curl
            git
            jq
            gnugrep
            gawk
            procps
            psmisc
            findutils
            ffmpeg
            playerctl
            wireplumber
            networkmanager
            bluez
            libnotify
            xdg-user-dirs
          ];
        in
        {
          default = self.packages.${system}.g_ant-shell;

          g_ant-shell = pkgs.stdenv.mkDerivation {
            pname = "g_ant-shell";
            version = "0.1.0";

            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/g_ant-shell $out/bin
              cp -r . $out/share/g_ant-shell

              makeWrapper $out/share/g_ant-shell/launch.sh $out/bin/g_ant-shell \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set G_ANT_ROOT "$out/share/g_ant-shell"

              makeWrapper $out/share/g_ant-shell/launch.sh $out/bin/g_ant-launch \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps} \
                --set G_ANT_ROOT "$out/share/g_ant-shell"

              runHook postInstall
            '';
          };
        }
      );

      homeManagerModules.default = self.homeManagerModules.g_ant-shell;
      
      homeManagerModules.g_ant-shell = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.g_ant-shell;
          system = pkgs.stdenv.hostPlatform.system;
        in
        {
          options.programs.g_ant-shell = {
            enable = lib.mkEnableOption "G_ant Shell for Hyprland";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${system}.g_ant-shell;
              description = "The g_ant-shell package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
            
            # Automatically copy/sync g_ant-shell files to ~/.config/quickshell
            home.activation.copyG_antShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              $DRY_RUN_CMD mkdir -p $HOME/.config/quickshell
              $DRY_RUN_CMD cp -rL --no-preserve=mode ${cfg.package}/share/g_ant-shell/* $HOME/.config/quickshell/
            '';
          };
        };
    };
}
