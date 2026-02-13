setup() {
    load 'common-setup'
    _common_setup

    load "${LARAKIT_LIB}/utils"
}

@test "showEnvironment fails without LARAKIT_HOME" {
  run showEnvironment
  assert_failure
}

@test "showEnvironment displays environment config" {
  run showEnvironment "${LARAKIT_HOME}"
  assert_output --partial "PHP_VERSION="
  assert_output --partial "POSTGRES_CLIENT_VERSION="
  assert_output --partial 'PHP_SERVICES="workspace php-fpm"'
}

@test "resetEnvironment fails without LARAKIT_HOME" {
  run resetEnvironment
  assert_failure
}

@test "resetEnvironment resets environment" {
  run resetEnvironment "${LARAKIT_HOME}"
  assert_success
  assert_file_exist "${LARAKIT_HOME}/configs/environment"
  assert_file_not_empty "${LARAKIT_HOME}/configs/environment"

  # restore original environment, if backup exists
  [ -f "${LARAKIT_HOME}/configs/environment.bak" ] && {
    cp "${LARAKIT_HOME}/configs/environment.bak" "${LARAKIT_HOME}/configs/environment"
  }
}

@test "updateEnvironment fails without LARAKIT_HOME" {
  run updateEnvironment
  assert_failure
}

@test "updateEnvironment updates environment" {
  hasPhpVersion=$(egrep '^PHP_VERSION' "${LARAKIT_HOME}/configs/environment" || echo '')
  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment" "${LARAKIT_HOME}/configs/environment.save"
  }

  run updateEnvironment "${LARAKIT_HOME}" 8.2
  assert_success
  assert_file_exist "${LARAKIT_HOME}/configs/environment"
  assert_file_not_empty "${LARAKIT_HOME}/configs/environment"
  assert [ "$(egrep '^PHP_VERSION' "${LARAKIT_HOME}/configs/environment")" = "PHP_VERSION=8.2" ]

  run updateEnvironment "${LARAKIT_HOME}" 8.4
  assert_success
  assert_file_exist "${LARAKIT_HOME}/configs/environment"
  assert_file_not_empty "${LARAKIT_HOME}/configs/environment"
  assert [ "$(egrep '^PHP_VERSION' "${LARAKIT_HOME}/configs/environment")" = "PHP_VERSION=8.4" ]

  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment.save" "${LARAKIT_HOME}/configs/environment"
  }
}

@test "updateEnvironment removes version specific values" {
  hasPhpVersion=$(egrep '^PHP_VERSION' "${LARAKIT_HOME}/configs/environment" || echo '')
  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment" "${LARAKIT_HOME}/configs/environment.save"
  }

  echo "PHP_FPM_BASE_IMAGE_TAG_PREFIX=20250222" >> "${LARAKIT_HOME}/configs/environment"
  echo "PHP_FPM_INSTALL_OPCACHE=false" >> "${LARAKIT_HOME}/configs/environment"

  run updateEnvironment "${LARAKIT_HOME}" 8.4
  assert_success
  assert_file_exist "${LARAKIT_HOME}/configs/environment"
  assert_file_not_empty "${LARAKIT_HOME}/configs/environment"
  refute grep '^PHP_FPM_BASE_IMAGE_TAG_PREFIX' "${LARAKIT_HOME}/configs/environment"
  refute grep '^PHP_FPM_INSTALL_OPCACHE' "${LARAKIT_HOME}/configs/environment"

  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment.save" "${LARAKIT_HOME}/configs/environment"
  }
}

@test "updateEnvironment add image tag for php version 7.4" {
  hasPhpVersion=$(egrep '^PHP_VERSION' "${LARAKIT_HOME}/configs/environment" || echo '')
  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment" "${LARAKIT_HOME}/configs/environment.save"
  }

  run updateEnvironment "${LARAKIT_HOME}" 7.4
  assert_success
  assert_file_exist "${LARAKIT_HOME}/configs/environment"
  assert_file_not_empty "${LARAKIT_HOME}/configs/environment"
  assert [ "$(egrep '^PHP_FPM_BASE_IMAGE_TAG_PREFIX' "${LARAKIT_HOME}/configs/environment")" = "PHP_FPM_BASE_IMAGE_TAG_PREFIX=20250222" ]
  refute grep '^PHP_FPM_INSTALL_OPCACHE' "${LARAKIT_HOME}/configs/environment"

  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment.save" "${LARAKIT_HOME}/configs/environment"
  }
}

@test "updateEnvironment disables opcache for php version 8.5" {
  hasPhpVersion=$(egrep '^PHP_VERSION' "${LARAKIT_HOME}/configs/environment" || echo '')
  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment" "${LARAKIT_HOME}/configs/environment.save"
  }

  run updateEnvironment "${LARAKIT_HOME}" 8.5
  assert_success
  assert_file_exist "${LARAKIT_HOME}/configs/environment"
  assert_file_not_empty "${LARAKIT_HOME}/configs/environment"
  assert [ "$(egrep '^PHP_FPM_INSTALL_OPCACHE' "${LARAKIT_HOME}/configs/environment")" = "PHP_FPM_INSTALL_OPCACHE=false" ]
  refute grep '^PHP_FPM_BASE_IMAGE_TAG_PREFIX' "${LARAKIT_HOME}/configs/environment"

  [ -n "${hasPhpVersion}" ] && {
    cp "${LARAKIT_HOME}/configs/environment.save" "${LARAKIT_HOME}/configs/environment"
  }
}

@test "checkDependency fails without arguments" {
    run checkDependency
    assert_failure
}

@test "checkDependency displays message if dependency is missing" {
    stub which \
        "foo : exit 1"

    run checkDependency foo "foo is not installed"
    assert_failure
    assert_output --partial "foo is not installed"

    unstub which
}

@test "checkDependency returns success if dependency is installed" {
    stub which \
        "foo : echo '/the/path/to/foo'"

    run checkDependency foo "foo is not installed"
    assert_success

    unstub which
}

@test "loadSshKeys finds keys already loaded" {
    stub ssh-add \
        "-l : echo 'here are some keys'"

    run loadSshKeys
    assert_success
}

@test "loadSshKeys loads keys" {
    stub ssh-add \
        "-l : echo ''" \
        "--apple-use-keychain : exit 0"

    stub sw_vers \
        "--productVersion : echo '26.3'"

    run loadSshKeys
    assert_success
    assert_output --partial "Loading SSH Keys for SSH Agent"

    unstub ssh-add
    unstub sw_vers
}
