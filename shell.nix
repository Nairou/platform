{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    libglvnd.dev
    libxkbcommon.dev
    wayland

    # keep this line if you use bash
    bashInteractive
  ];

  packages = with pkgs; [
    autoconf
    automake
    gdb
    gnumake
    python3
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
