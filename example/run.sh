#!/usr/bin/env bash

set -e

pushd zig-out/bin
HB_DEBUG=all ./example
popd
