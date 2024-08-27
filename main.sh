#!/bin/bash
# shellcheck disable=SC2164
set -o nounset

LOG_DIR=$(realpath log)
readarray -t PKGS < pkg.txt

function test-pip() {
  pkg=$1
  mkdir --parents _tmp
  pushd _tmp
  python -m venv .venv
  .venv/bin/pip install "$pkg"
  popd
  rm --force --recursive _tmp
}

function test-pixi() {
  pkg=$1
  mkdir --parents _tmp
  cp pyproject.toml _tmp/pyproject.toml
  pushd
  pixi -vvv add "$pkg" 2> "$LOG_DIR/pixi/$pkg.log"
  popd
  rm --force --recursive _tmp
}

function test-uv() {
  pkg=$1
  mkdir --parents _tmp
  pushd _tmp
  uv venv
  uv pip install "$pkg"
  popd
  rm --force --recursive _tmp
}

function echo-result() {
  ret=$1
  if ((ret == 0)); then
    echo -n " ✅ |"
  else
    echo -n " ❌ |"
  fi
}

echo "| Package | pip | uv | pixi |" > results.md
echo "| ------- | --- | -- | ---- |" >> results.md
for pkg in "${PKGS[@]}"; do
  echo -n "| $pkg |" >> results.md
  test-pip "$pkg"
  echo-result $? >> results.md
  test-uv "$pkg"
  echo-result $? >> results.md
  test-pixi "$pkg"
  echo-result $? >> results.md
  echo >> results.md
done
