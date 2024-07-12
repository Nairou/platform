{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.hello

    # keep this line if you use bash
    pkgs.bashInteractive
  ];

  packages = with pkgs; [
    gdb
    #libglvnd.dev
    wayland-scanner.dev
    #libxkbcommon.dev
    #xorg.libX11
    #xorg.libxcb
    #xorg.xorgproto
    zig
  ];

  shellHook = ''
    zig version
    '';
}

# Remember to run `lorri init` for a new project

