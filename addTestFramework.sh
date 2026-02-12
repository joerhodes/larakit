#!/usr/bin/env bash
#
# Install the BATS testing framework and helpers.
#
# References:
#     https://github.com/bats-core/bats-core
#     https://github.com/bats-core/bats-support
#     https://github.com/bats-core/bats-assert

LARAKIT_HOME="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CURRENT_DIR="$(pwd -P)"

[ "$CURRENT_DIR" != "$LARAKIT_HOME" ] && {
  printf "\nERROR: This script must be run from %s\n" "$LARAKIT_HOME"
  exit 1
}

installBatsCore() {
    [ -f "${LARAKIT_HOME}/tests/bats/bin/bats" ] && {
        printf "bats-core already installed.\n"
        return 0
    }

    printf "Installing bats-core.\n"

    mkdir -p "${LARAKIT_HOME}/tests/bats"
    cd "${LARAKIT_HOME}/tests"
    git clone -q https://github.com/bats-core/bats-core.git bats
    cd "${LARAKIT_HOME}"
}

installBatsSupport() {
    [ -f "${LARAKIT_HOME}/tests/helpers/bats-support/load.bash" ] && {
        printf "bats-support already installed.\n"
        return 0
    }

    printf "Installing bats-support.\n"

    mkdir -p "${LARAKIT_HOME}/tests/helpers/bats-support"
    cd "${LARAKIT_HOME}/tests/helpers"
    git clone -q https://github.com/bats-core/bats-support.git bats-support
    cd "${LARAKIT_HOME}"
}

installBatsAssert() {
    [ -f "${LARAKIT_HOME}/tests/helpers/bats-assert/load.bash" ] && {
        printf "bat-assert already installed.\n"
        return 0
    }

    printf "Installing bats-assert.\n"

    mkdir -p "${LARAKIT_HOME}/tests/helpers/bats-assert"
    cd "${LARAKIT_HOME}/tests/helpers"
    git clone -q https://github.com/bats-core/bats-assert.git bats-assert
    cd "${LARAKIT_HOME}"
}

installBatsCore
installBatsSupport
installBatsAssert

