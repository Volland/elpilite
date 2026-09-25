#!/usr/bin/env sh
# Builds Turso's sqlite3-compatible C library at the pinned revision.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REV=$(cat "$ROOT/vendor/turso.rev")
DIR="$ROOT/vendor/turso"
if [ ! -d "$DIR/.git" ]; then
  git clone https://github.com/tursodatabase/turso "$DIR"
fi
git -C "$DIR" fetch --depth 50 origin "$REV" 2>/dev/null || git -C "$DIR" fetch origin
git -C "$DIR" checkout -q "$REV"
cd "$DIR"
if command -v rustup >/dev/null 2>&1; then
  rustup toolchain install "$(sed -n 's/^channel = "\(.*\)"/\1/p' rust-toolchain.toml)" --profile minimal
  rustup run "$(sed -n 's/^channel = "\(.*\)"/\1/p' rust-toolchain.toml)" cargo build --release -p turso_sqlite3
else
  cargo build --release -p turso_sqlite3
fi
ls target/release/libturso_sqlite3.*
