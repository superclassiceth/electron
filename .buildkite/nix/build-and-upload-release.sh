#!/usr/bin/env bash

# Any subsequent commands which fail will cause the shell script to exit immediately
set -euo pipefail

# When the script exits or errors out, make sure to do the cleanup
trap cleanup EXIT

# platform should be one of "linux" or "darwin"
declare platform="$1"

cleanup() {
  echo "running cleanup"

  # Try stopping Xvfb only for Linux platform
  if [[ "$platform" == "linux" ]]
  then
    # This step might fail since Xvfb might not be running
    pkill Xvfb || true
  fi
  npm run clean
}

start_xvfb() {
  # Start Xvfb only for linux platform
  if [[ "$platform" != "linux" ]]
  then
    return;
  fi

  echo "Starting Xvfb"
  export DISPLAY=:99

  # This step might fail since Xvfb might not be running
  pkill Xvfb || true
  Xvfb :99 -ac &
}

buildAndUpload() {
  local arch="$1"

  echo "Building for $platform $arch"

  echo "1. Running cleanup"
  npm run clean

  echo "2. Running bootstrap command"
  python script/bootstrap.py --target_arch="$arch"

  echo "3. Building electron in release mode"
  python script/build.py -c R

  echo "4. Creating the distribution"
  python ./script/create-dist.py

  echo "5. Uploading the artifacts"
  buildkite-agent artifact upload "dist/electron-v*-$platform-$arch.zip"
}

main() {
  start_xvfb

  buildAndUpload "x64"
}

main
