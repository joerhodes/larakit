setup() {
    load 'common-setup'
    _common_setup

    load "${LARAKIT_LIB}/laradock"

    LKCONFIGS="${LARAKIT_HOME}/configs"
    aliasFile="${LKCONFIGS}/docker-compose.aliases.yml"
}

@test "resetAliases fails without LARAKIT_HOME" {
    run resetAliases
    assert_failure
}

@test "resetAliases creates file with empty aliases" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    run resetAliases "${LARAKIT_HOME}"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    assert [ $(yq '.services.nginx.networks.backend.aliases' "${aliasFile}") = '[]' ]

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "addAlias fails without LARAKIT_HOME" {
    run addAlias
    assert_failure
}

@test "addAlias adds alias" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    run addAlias "${LARAKIT_HOME}" "test.test"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    assert [ $(yq '.services.nginx.networks.backend.aliases[]' "${aliasFile}") = 'test.test' ]

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "addAlias appends to existing aliases" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    resetAliases "${LARAKIT_HOME}"
    addAlias "${LARAKIT_HOME}" "test1.test"

    run addAlias "${LARAKIT_HOME}" "test2.test"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    assert [ $(yq '.services.nginx.networks.backend.aliases[] | select(. == "test1.test")' "${aliasFile}") = 'test1.test' ]
    assert [ $(yq '.services.nginx.networks.backend.aliases[] | select(. == "test2.test")' "${aliasFile}") = 'test2.test' ]

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "addAlias skips if alias already exists" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    resetAliases "${LARAKIT_HOME}"
    addAlias "${LARAKIT_HOME}" "test1.test"

    run addAlias "${LARAKIT_HOME}" "test1.test"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    count=$(yq '.services.nginx.networks.backend.aliases[] | select(. == "test1.test")' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 1 ]

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "removeAlias fails without LARAKIT_HOME" {
    run removeAlias
    assert_failure
}

@test "removeAlias always succeeds if aliases are empty" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    resetAliases "${LARAKIT_HOME}"
    run removeAlias "${LARAKIT_HOME}" "test.test"
    assert_success

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "removeAlias removes alias" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    resetAliases "${LARAKIT_HOME}"
    addAlias "${LARAKIT_HOME}" "test1.test"
    addAlias "${LARAKIT_HOME}" "test2.test"

    run removeAlias "${LARAKIT_HOME}" "test2.test"
    assert_success
    count=$(yq '.services.nginx.networks.backend.aliases[] | select(. == "test1.test")' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 1 ]
    count=$(yq '.services.nginx.networks.backend.aliases[] | select(. == "test2.test")' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 0 ]

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "removeAlias does nothing if alias does not exist" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    resetAliases "${LARAKIT_HOME}"
    addAlias "${LARAKIT_HOME}" "test1.test"

    run removeAlias "${LARAKIT_HOME}" "test.test"
    assert_success

    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}

@test "removeAlias removes last alias if it is the only one" {
    [ -f "${aliasFile}" ] && {
        mv "${aliasFile}" "${aliasFile}.bak"
    }

    resetAliases "${LARAKIT_HOME}"
    addAlias "${LARAKIT_HOME}" "test.test"

    run removeAlias "${LARAKIT_HOME}" "test.test"
    assert_success
    count=$(yq '.services.nginx.networks.backend.aliases[]' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 0 ]


    [ -f "${aliasFile}.bak" ] && {
        mv "${aliasFile}.bak" "${aliasFile}"
    }
}
