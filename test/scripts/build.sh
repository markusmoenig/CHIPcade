#!/usr/bin/env bash
set -e
cargo run --quiet -- run ${1:-.}
