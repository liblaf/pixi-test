#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

LOG_DIR=$(realpath log)
readarray -t PKGS < pkg.txt

function test-pip() {
  pkg=$1
  echo -n "pip install $pkg"
  mkdir --parents _tmp
  pushd _tmp > /dev/null
  python -m venv .venv
  .venv/bin/pip install "$pkg" > /dev/null 2> /dev/null
  popd > /dev/null
  rm --force --recursive _tmp
}

function test-pixi() {
  pkg=$1
  echo -n "pixi add --pypi $pkg"
  mkdir --parents _tmp
  cp pyproject.toml _tmp/pyproject.toml
  pushd _tmp > /dev/null
  mkdir --parents "$LOG_DIR/pixi"
  pixi -vvv add "$pkg" 2> "$LOG_DIR/pixi/$pkg.log"
  popd > /dev/null
  rm --force --recursive _tmp
}

function test-uv() {
  pkg=$1
  echo -n "uv pip install $pkg"
  mkdir --parents _tmp
  pushd _tmp > /dev/null
  uv venv > /dev/null 2> /dev/null
  uv pip install "$pkg" > /dev/null 2> /dev/null
  popd > /dev/null
  rm --force --recursive _tmp
}

function echo-result() {
  ret=$1
  if ((ret == 0)); then
    echo " ✅"
    echo -n " ✅ |" >> results.md
  else
    echo " ❌"
    echo -n " ❌ |" >> results.md
  fi
}

echo "| Package | pip | uv | pixi |" > results.md
echo "| ------- | --- | -- | ---- |" >> results.md
for pkg in "${PKGS[@]}"; do
  echo -n "| $pkg |" >> results.md
  test-pip "$pkg" && rc=$? || rc=$?
  echo-result "$rc"
  test-uv "$pkg" && rc=$? || rc=$?
  echo-result "$rc"
  test-pixi "$pkg" && rc=$? || rc=$?
  echo-result "$rc"
  echo >> results.md
done
