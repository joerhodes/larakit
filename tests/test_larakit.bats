setup() {
  load 'helpers/bats-support/load'
  load 'helpers/bats-assert/load'

  LARAKIT_HOME="$(cd -- "$(dirname $(dirname -- "${BATS_TEST_FILENAME}"))" && pwd -P)"
  PATH="${LARAKIT_HOME}:${PATH}"
}


@test "Can run larakit" {
  larakit
}

@test "Larakit displays usage" {
  run larakit help
  assert_output --partial "Usage: larakit commands"
}

@test "Larakit displays environment config" {
  run larakit env
  assert_output --partial "PHP_VERSION="
  assert_output --partial "POSTGRES_CLIENT_VERSION="
  assert_output --partial 'PHP_SERVICES="workspace php-fpm"'
}

@test "Larakit adds and removes hostnames" {
  run larakit register bats-testing.test
  assert_success
  assert [ -f "${LARAKIT_HOME}/configs/docker-compose.aliases.yml" ]
  assert grep -q 'bats-testing.test' "${LARAKIT_HOME}/configs/docker-compose.aliases.yml"

  run larakit deregister bats-testing.test
  assert_success
  refute grep -q 'bats-testing.test' "${LARAKIT_HOME}/configs/docker-compose.aliases.yml"
}
