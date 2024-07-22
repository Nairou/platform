#!/usr/bin/env bash
set -euo pipefail
set -x

GLVND_REV=606f6627cf481ee6dcb32387edc010c502cdf38b

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

rm -rf src/egl
mkdir -p src/egl/EGL
mkdir -p src/egl/KHR

git_clone_rev https://gitlab.freedesktop.org/glvnd/libglvnd.git "$GLVND_REV" _egl
mv _egl/include/EGL/*.h src/egl/EGL
mv _egl/include/KHR/*.h src/egl/KHR
rm -rf _egl

