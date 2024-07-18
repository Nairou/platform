{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.hello

    # keep this line if you use bash
    pkgs.bashInteractive
  ];

  packages = with pkgs; [
    autoconf
    automake
    gdb
    gnumake
    python3
    #libglvnd.dev
    libxkbcommon.dev
    wayland-scanner.dev
    #xorg.libX11
    #xorg.libxcb
    #xorg.xorgproto
    zig
  ];

  shellHook = ''
    # Doesn't work with lorri
    echo Zig $(zig version)
    '';
}

# Remember to run `lorri init` for a new project

