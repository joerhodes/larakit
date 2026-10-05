setup() {
    load 'common-setup'
    _common_setup

    TMPDIR="$(mktemp -d)"
    mkdir -p "${TMPDIR}/configs"
    cp "${TEST_FIXTURES}/docker-compose.aliases.sample" "${TMPDIR}/configs/docker-compose.aliases.yml"
    cp "${TEST_FIXTURES}/Dockerfile.sample" "${TMPDIR}/Dockerfile"

    load "${LARAKIT_LIB}/laradock"

    LKCONFIGS="${TMPDIR}/configs"
    aliasFile="${LKCONFIGS}/docker-compose.aliases.yml"
}

@test "resetAliases fails without a path" {
    run resetAliases
    assert_failure
}

@test "resetAliases creates file with empty aliases" {
    rm -f "${aliasFile}"
    run resetAliases "${TMPDIR}"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    assert [ $(yq '.services.nginx.networks.backend.aliases' "${aliasFile}") = '[]' ]
}

@test "addAlias fails without a path" {
    run addAlias
    assert_failure
}

@test "addAlias adds alias" {
    run addAlias "${TMPDIR}" "test.test"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    assert [ "$(yq '.services.nginx.networks.backend.aliases[]' "${aliasFile}")" = 'test.test' ]
}

@test "addAlias appends to existing aliases" {
    resetAliases "${TMPDIR}"
    addAlias "${TMPDIR}" "test1.test"

    run addAlias "${TMPDIR}" "test2.test"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    assert [ $(yq '.services.nginx.networks.backend.aliases[] | select(. == "test1.test")' "${aliasFile}") = 'test1.test' ]
    assert [ $(yq '.services.nginx.networks.backend.aliases[] | select(. == "test2.test")' "${aliasFile}") = 'test2.test' ]
}

@test "addAlias skips if alias already exists" {
    resetAliases "${TMPDIR}"
    addAlias "${TMPDIR}" "test1.test"

    run addAlias "${TMPDIR}" "test1.test"
    assert_success
    assert_file_exist "${aliasFile}"
    assert_file_not_empty "${aliasFile}"
    count=$(yq '.services.nginx.networks.backend.aliases[] | select(. == "test1.test")' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 1 ]
}

@test "removeAlias fails without a path" {
    run removeAlias
    assert_failure
}

@test "removeAlias always succeeds if aliases are empty" {
    resetAliases "${TMPDIR}"
    run removeAlias "${TMPDIR}" "test.test"
    assert_success
}

@test "removeAlias removes alias" {
    resetAliases "${TMPDIR}"
    addAlias "${TMPDIR}" "test1.test"
    addAlias "${TMPDIR}" "test2.test"

    run removeAlias "${TMPDIR}" "test2.test"
    assert_success
    count=$(yq '.services.nginx.networks.backend.aliases[] | select(. == "test1.test")' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 1 ]
    count=$(yq '.services.nginx.networks.backend.aliases[] | select(. == "test2.test")' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 0 ]
}

@test "removeAlias does nothing if alias does not exist" {
    resetAliases "${TMPDIR}"
    addAlias "${TMPDIR}" "test1.test"

    run removeAlias "${TMPDIR}" "test.test"
    assert_success
}

@test "removeAlias removes last alias if it is the only one" {
    resetAliases "${TMPDIR}"
    addAlias "${TMPDIR}" "test.test"

    run removeAlias "${TMPDIR}" "test.test"
    assert_success
    count=$(yq '.services.nginx.networks.backend.aliases[]' "${aliasFile}" | wc -l)
    assert [ ${count} -eq 0 ]
}

@test "injectIntoDockerfile fails without path and script" {
    run injectIntoDockerfile
    assert_failure
}

@test "injectIntoDockerfile fails if Dockerfile does not exists" {
    rm -f "${TMPDIR}/Dockerfile"

    run injectIntoDockerfile "${TMPDIR}/Dockerfile" "{ print }"
    assert_failure
}

@test "injectIntoDockerfile fails if script is empty" {
    local target="${TMPDIR}/Dockerfile"
    echo "original content" > "${target}"

    run injectIntoDockerfile "${TMPDIR}/Dockerfile" ""
    assert_failure

    run cat "${target}"
    assert_output "original content"
}

@test "injectIntoDockerfile restores backup with awk fails" {
    local target="${TMPDIR}/Dockerfile"
    echo "original content" > "${target}"

    run injectIntoDockerfile "${target}" "BEGIN { exit 1 }"
    assert_failure

    run cat "${target}"
    assert_output "original content"
}

@test "injectIntoDockerfile adds new line" {
    local target="${TMPDIR}/Dockerfile"
    printf "beginning\nmiddle\nend\n" > "${target}"

    run injectIntoDockerfile "${target}" "{ print; if (\$0 ~ /middle/) { print \"new content\"; } }"
    assert_success

    local lineCount
    lineCount=$(wc -l < "${target}" | tr -d ' ')
    assert_equal "${lineCount}" "4"

    run cat "${target}"
    assert_line --index 0 "beginning"
    assert_line --index 1 "middle"
    assert_line --index 2 "new content"
    assert_line --index 3 "end"
}

@test "injectAptCleanup fails without a path" {
    run injectAptCleanup
    assert_failure
}

@test "injectAptCleanup fails if file does not exists" {
    run injectAptCleanup "${TMPDIR}/nonexistent-file-path"
    assert_failure
}

@test "injectAptCleanup inserts APT Clean steps" {
    local target="${TMPDIR}/Dockerfile"
    printf "RUN set -xe; \\\\\n    apt-get update -yqq\n" > "${target}"

    run injectAptCleanup "${target}"
    assert_success

    local lineCount=$(wc -l < "${target}" | tr -d ' ')
    assert_equal "${lineCount}" "6"

    run cat "${target}"
    assert_line --index 0 "RUN set -xe; \\"
    assert_line --index 1 "    apt-get clean && \\"
    assert_line --index 2 "    apt-get autoclean && \\"
    assert_line --index 3 "    rm -rf /var/lib/apt/lists && \\"
    assert_line --index 4 "    apt update && \\"
    assert_line --index 5 "    apt-get update -yqq"
}

@test "injectSnippetFile fails without file paths" {
    run injectSnippetFile
    assert_failure
}

@test "injectSnippetFile fails without files" {
    local target="${TMPDIR}/Dockerfile"
    local source="${TMPDIR}/inject-snippet"

    rm -f "${target}" "${source}"

    run injectSnippetFile "${target}" "${source}"
    assert_failure

    touch "${target}"

    run injectSnippetFile "${target}" "${source}"
    assert_failure
}

@test "injectSnippetFile succeeds when snippet file is empty" {
    local target="${TMPDIR}/Dockerfile"
    local source="${TMPDIR}/inject-snippet"

    printf "" > "${source}"

    run injectSnippetFile "${target}" "${source}"
    assert_success
}

@test "injectSnippetFile updates Dockerfile" {
    local target="${TMPDIR}/Dockerfile"
    local source="${TMPDIR}/inject-snippet"

    printf "FROM base\nRUN set -xe\n# Final Touch\nUSER root\nRUN echo done\n" > "${target}"
    printf "#install a sample package\nRUN apt-get install -y sample-pkg\n" > "${source}"

    run injectSnippetFile "${target}" "${source}"
    assert_success

    local lineCount=$(wc -l < "${target}" | tr -d ' ')
    assert_equal "${lineCount}" "9"

    run cat "${target}"
    assert_line --index 0 "FROM base"
    assert_line --index 1 "RUN set -xe"
    assert_line --index 2 "# Final Touch"
    assert_line --index 3 "USER root"
    # BATS drops this blank line - cannot assert exists
    assert_line --index 4 "#install a sample package"
    assert_line --index 5 "RUN apt-get install -y sample-pkg"
    # BATS drops this blank line - cannot assert exists
    assert_line --index 6 "RUN echo done"
}
