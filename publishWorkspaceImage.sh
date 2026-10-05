#!/usr/bin/env bash

set -euo pipefail

# larakit configuration
LARAKIT_HOME="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
LARADOCK_HOME="${LARAKIT_HOME}/laradock"
BUILDER=bitbucket-builder
DOCKER_IMAGE="${LARAKIT_DOCKER_IMAGE:-yourname/laradock-workspace}"

LARAKIT_LIB="${LARAKIT_HOME}/lib"
source "${LARAKIT_LIB}/utils.bash"
source "${LARAKIT_LIB}/laradock.bash"

#
# updateWorkspace - Updates Laradock's workspace Dockerfile if needed
#
updateWorkspace() {
    local cwd=$(pwd)
    cd "$LARADOCK_HOME"
    git checkout -- workspace
    cd "$cwd"

    [ ! -f "${LARAKIT_HOME}"/configs/inject-workspace-dockerfile ] && return

    local inject=$(cat "${LARAKIT_HOME}/configs/inject-workspace-dockerfile")

    [ -z "$inject" ] && return

    injectAptCleanup "${LARADOCK_HOME}/workspace/Dockerfile"

    injectSnippetFile "${LARADOCK_HOME}/workspace/Dockerfile" "${LARAKIT_HOME}/configs/inject-workspace-dockerfile"
}

#
# getBuildArgs - Generate a string of build arg values used to build the Laradock workspace image
#     $1 - PHP version
#
getBuildArgs() {
    local version=$1

    local setting
    local variable
    local override

    local buildArgs="--build-arg PHP_VERSION=${version} --build-arg LARADOCK_PHP_VERSION=${version}"

    for setting in $(awk '/^WORKSPACE_/ { gsub(/^WORKSPACE_/, ""); print }' "${LARADOCK_HOME}/.env"); do
        [ -z "${setting}" ] && break

        variable=$(echo "${setting}" | cut -d= -f1)
        override=$(grep "^WORKSPACE_${variable}" "${LARAKIT_HOME}/configs/environment")
        [ -n "${override}" ] && setting=$(echo "${override}" | awk '{ gsub(/^WORKSPACE_/, ""); print }')

        buildArgs="${buildArgs} --build-arg ${setting}"
    done

   echo "${buildArgs}"
}

builderCleanup() {
    local exists=$(docker buildx ls | grep "${BUILDER}")
    [ -z "${exists}" ] && return 0

    echo "Removing docker builder ${BUILDER}"
    docker buildx stop ${BUILDER}
    docker buildx rm ${BUILDER}
}

# Uses the docker-container driver rather than the local machine's default
# builder, so --push works reliably regardless of each developer's Docker
# Desktop configuration (the default driver's push support depends on
# whether the containerd image store is enabled locally).
builderCreate() {
    echo "Creating docker builder ${BUILDER}"
    docker buildx create --name "${BUILDER}" --driver docker-container --bootstrap
    docker buildx use "${BUILDER}"
}

build() {
    local version=$1
    echo "Building image ${DOCKER_IMAGE}:latest-${version}"
    local buildArgs=$(getBuildArgs $version)

    docker buildx build \
        --platform linux/amd64 \
        ${buildArgs} \
        -t ${DOCKER_IMAGE}:latest-${version} \
        --push \
        "${LARADOCK_HOME}/workspace"
}

# main starts here
main() {
    local version=8.5

    builderCleanup || exit 1

    builderCreate || exit 1

    updateEnvironment "${LARAKIT_HOME}" $version || exit 1

    updateWorkspace || exit 1

    build $version || exit 1

    builderCleanup || exit 1
}

# Only run main when executed directly — allows this script to be sourced
# (e.g. by BATS tests) without triggering a build.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
