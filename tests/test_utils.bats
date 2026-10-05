setup() {
    load 'common-setup'
    _common_setup

    TMPDIR="$(mktemp -d)"
    cp "${TEST_FIXTURES}/Dockerfile.sample" "${TMPDIR}/Dockerfile"
    cp "${TEST_FIXTURES}/inject-snippet.sample" "${TMPDIR}/inject-snippet"
    mkdir -p "${TMPDIR}/configs"
    cp "${TEST_FIXTURES}/environment.sample" "${TMPDIR}/configs/environment"

    load "${LARAKIT_LIB}/utils"
}

teardown() {
    rm -rf "${TMPDIR}"
}

@test "backupFile fails when the source file does not exist" {
    run backupFile "${TMPDIR}/does-not-exist"
    assert_failure
}

@test "backupFile fails when the directory is not writable" {
    local target="${TMPDIR}/Dockerfile"
    touch "${target}"
    chmod 555 "${TMPDIR}"

    run backupFile "${target}"
    assert_failure

    chmod 755 "${TMPDIR}"   # restore so teardown can remove TMP
}

@test "restoreBackup returns original file content after a failed edit" {
    local target="${TMPDIR}/Dockerfile"
    echo "original content" > "${target}"
    backupFile "${target}"

    restoreBackup "${target}"

    run cat "${target}"
    assert_output "original content"
}

@test "removeBackup remote the backup file" {
    local target="${TMPDIR}/Dockerfile"
    echo "original content" > "${target}"
    backupFile "${target}"
    assert_file_exists "${target}.bak"

    removeBackup "${target}"
    assert_file_not_exists "${target}.bak"
}

@test "showEnvironment fails without a path" {
    run showEnvironment
    assert_failure
}

@test "showEnvironment displays environment config" {
    run showEnvironment "${TMPDIR}"
    assert_output --partial "PHP_VERSION="
    assert_output --partial "POSTGRES_CLIENT_VERSION="
    assert_output --partial 'PHP_SERVICES="workspace php-fpm"'
}

@test "resetEnvironment fails without a path" {
    run resetEnvironment
    assert_failure
}

@test "resetEnvironment creates a new file" {
    rm -f "${TMPDIR}/configs/environment"
    run resetEnvironment "${TMPDIR}"
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
}

@test "resetEnvironment resets the environment file" {
    echo "bad contents" > "${TMPDIR}/configs/environment"
    run resetEnvironment "${TMPDIR}"
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
    refute [ "$(grep 'bad contents' "${TMPDIR}/configs/environment")" = "bad contents"]
}

@test "updateEnvironment fails without a path" {
    run updateEnvironment
    assert_failure
}

@test "updateEnvironment updates environment" {
    run updateEnvironment "${TMPDIR}" 8.2
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
    assert [ "$(egrep '^PHP_VERSION' "${TMPDIR}/configs/environment")" = "PHP_VERSION=8.2" ]

    run updateEnvironment "${TMPDIR}" 8.4
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
    assert [ "$(egrep '^PHP_VERSION' "${TMPDIR}/configs/environment")" = "PHP_VERSION=8.4" ]
}

@test "updateEnvironment removes version specific values" {
    echo "PHP_FPM_BASE_IMAGE_TAG_PREFIX=20250222" >> "${TMPDIR}/configs/environment"
    echo "PHP_FPM_INSTALL_OPCACHE=false" >> "${TMPDIR}/configs/environment"

    run updateEnvironment "${TMPDIR}" 8.4
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
    refute grep '^PHP_FPM_BASE_IMAGE_TAG_PREFIX' "${TMPDIR}/configs/environment"
    refute grep '^PHP_FPM_INSTALL_OPCACHE' "${TMPDIR}/configs/environment"
}

@test "updateEnvironment add image tag for php version 7.4" {
    run updateEnvironment "${TMPDIR}" 7.4
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
    assert [ "$(egrep '^PHP_FPM_BASE_IMAGE_TAG_PREFIX' "${TMPDIR}/configs/environment")" = "PHP_FPM_BASE_IMAGE_TAG_PREFIX=20250222" ]
    refute grep '^PHP_FPM_INSTALL_OPCACHE' "${TMPDIR}/configs/environment"
}

@test "updateEnvironment disables opcache for php version 8.5" {
    run updateEnvironment "${TMPDIR}" 8.5
    assert_success
    assert_file_exist "${TMPDIR}/configs/environment"
    assert_file_not_empty "${TMPDIR}/configs/environment"
    assert [ "$(egrep '^PHP_FPM_INSTALL_OPCACHE' "${TMPDIR}/configs/environment")" = "PHP_FPM_INSTALL_OPCACHE=false" ]
    refute grep '^PHP_FPM_BASE_IMAGE_TAG_PREFIX' "${TMPDIR}/configs/environment"
}

@test "checkDependency fails without arguments" {
    run checkDependency
    assert_failure
}

@test "checkDependency displays message if dependency is missing" {
    run checkDependency not-a-real-command-zzz "not-a-real-command-zzz is not installed"
    assert_failure
    assert_output --partial "not-a-real-command-zzz is not installed"
}

@test "checkDependency returns success if dependency is installed" {
    run checkDependency ls "ls is not installed"
    assert_success
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
