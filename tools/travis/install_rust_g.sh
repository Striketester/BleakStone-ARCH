#!/usr/bin/env bash
set -euo pipefail

source dependencies.sh

mkdir -p ~/.byond/bin
wget -O ~/.byond/bin/rust_g "https://github.com/${RUST_G_REPO}/releases/download/$RUST_G_VERSION/librust_g.so"
chmod +x ~/.byond/bin/rust_g
