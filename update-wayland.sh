#!/usr/bin/env bash
set -euo pipefail
set -x

WAYLAND_REV=edb943dc6464697ba13d7df277aef277721764b7
PROTOCOLS_REV=e1d61ce9402ebd996d758c43f167e6280c1a3568

# `git clone --depth 1` but at a specific revision
git_clone_rev() {
    repo=$1
    rev=$2
    dir=$3

    rm -rf "$dir"
    mkdir "$dir"
    pushd "$dir"
    git init -q
    git fetch "$repo" "$rev" --depth 1
    git checkout -q FETCH_HEAD
    popd
}

rm -rf src/wayland
mkdir src/wayland

git_clone_rev https://gitlab.freedesktop.org/wayland/wayland.git "$WAYLAND_REV" _wayland

# install/generate headers as per https://gitlab.freedesktop.org/wayland/wayland/-/blob/main/src/meson.build
mv _wayland/src/wayland{-util,-server{,-core},-client{,-core}}.h src/wayland
mv _wayland/egl/wayland-{egl,egl-backend,egl-core}.h src/wayland

# generate version header
version=$(grep -o '\bversion:\s'\''[^'\'']*' _wayland/meson.build | cut -d \' -f 2)
parts=(${version//./ })
sed \
    -e "s/@WAYLAND_VERSION@/$version/" \
    -e "s/@WAYLAND_VERSION_MAJOR@/${parts[0]}/" \
    -e "s/@WAYLAND_VERSION_MINOR@/${parts[1]}/" \
    -e "s/@WAYLAND_VERSION_MICRO@/${parts[2]}/" \
    _wayland/src/wayland-version.h.in > src/wayland/wayland-version.h

git_clone_rev https://gitlab.freedesktop.org/wayland/wayland-protocols.git "$PROTOCOLS_REV" _protocols

generate_wayland_protocol() {
    xml=$1
    out_name=$2

    wayland-scanner client-header "$xml" "src/wayland/$out_name-client-protocol.h"
    wayland-scanner private-code "$xml" "src/wayland/$out_name-protocol.c"
}

generate_wayland_protocol _wayland/protocol/wayland.xml wayland
generate_wayland_protocol _protocols/stable/xdg-shell/xdg-shell.xml xdg-shell
#generate_wayland_protocol _protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml xdg-decoration
#generate_wayland_protocol _protocols/stable/viewporter/viewporter.xml viewporter
#generate_wayland_protocol _protocols/unstable/relative-pointer/relative-pointer-unstable-v1.xml relative-pointer-unstable-v1
#generate_wayland_protocol _protocols/unstable/pointer-constraints/pointer-constraints-unstable-v1.xml pointer-constraints-unstable-v1
#generate_wayland_protocol _protocols/unstable/idle-inhibit/idle-inhibit-unstable-v1.xml idle-inhibit-unstable-v1

rm -rf _wayland _protocols
