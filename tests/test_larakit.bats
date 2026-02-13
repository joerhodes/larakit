setup() {
    load 'common-setup'

    _common_setup
}

@test "Can run larakit" {
  larakit
}

@test "Larakit displays usage" {
  run larakit help
  assert_success
  assert_output --partial "Usage: larakit commands"
  assert_output --partial "switch version"
  assert_output --partial "Switch to PHP version: 5.6, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5"
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
