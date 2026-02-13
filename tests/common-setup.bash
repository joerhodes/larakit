_common_setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
    load 'helpers/bats-file/load'
    load 'helpers/bats-mock/stub'

    # get the directory for LARAKIT_HOME
    LARAKIT_HOME="$(cd -- "$(dirname $(dirname -- "${BATS_TEST_FILENAME}"))" && pwd -P)"
    LARAKIT_LIB="${LARAKIT_HOME}/lib"

    # make sure larakit is in the path
    PATH="${LARAKIT_HOME}:${PATH}"
}
