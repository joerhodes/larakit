#!/usr/bin/env bash
#
# Install the BATS testing framework and helpers.
#
# References:
#     https://github.com/bats-core/bats-core
#     https://github.com/bats-core/bats-support
#     https://github.com/bats-core/bats-assert

LARAKIT_HOME="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BATS_HOME="${LARAKIT_HOME}/tests/bats"
BATS_HELPER="${LARAKIT_HOME}/tests/helpers"
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

# Install a bats helper under test/helpers
#     $1 - help name, ie bats-support
#     $2 - git clone url
installBatsHelper() {
    [ $# -ne 2 ] && {
        printf "invalid call to installBatsHelper!!\n"
        exit 1
    }

    module=$1
    gitUrl=$2

    [ -d "${BATS_HELPER}/${module}" ] && {
        printf "${module} already installed.\n"
        return 0
    }

    printf "Installing ${module}.\n"

    mkdir -p "${BATS_HELPER}/${module}"
    cd "${BATS_HELPER}"
    git clone -q "${gitUrl}" "${module}"
    cd "${LARAKIT_HOME}"
}

installBatsCore
installBatsHelper 'bats-support' 'https://github.com/bats-core/bats-support.git'
installBatsHelper 'bats-assert' 'https://github.com/bats-core/bats-assert.git'
installBatsHelper 'bats-file' 'https://github.com/bats-core/bats-file.git'
installBatsHelper 'bats-mock' 'https://github.com/buildkite-plugins/bats-mock.git'
