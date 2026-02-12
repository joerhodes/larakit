setup() {
    load 'common-setup'

    _common_setup
}

@test "Can run larakit" {
  larakit
}

@test "Larakit displays usage" {
  run larakit help
  assert_output --partial "Usage: larakit commands"
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
