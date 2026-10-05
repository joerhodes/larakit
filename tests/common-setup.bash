_common_setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
    load 'helpers/bats-file/load'
    load 'helpers/bats-mock/stub'

    # get the directory for LARAKIT_HOME
    LARAKIT_HOME="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")/.." && pwd -P)"
    LARAKIT_LIB="${LARAKIT_HOME}/lib"
    TEST_FIXTURES="${LARAKIT_HOME}/tests/fixtures"

    # make sure larakit is in the path
    PATH="${LARAKIT_HOME}:${PATH}"
}
