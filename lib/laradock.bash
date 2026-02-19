#!/usr/bin/env bash
#
# laradock related functions to support larakit
#

#
# resetAlias - Reset set the docker-compose.aliases.yml
#    $1 - Directory for Larakit Home
#
resetAliases() {
    [ $# -ne 1 ] && return 1

    ymlFile="${1}/configs/docker-compose.aliases.yml"

    yq --exit-status --null-input '.services.nginx.networks.backend.aliases = []'  > "${ymlFile}"
}

#
# addAlias - Adds a hostname alias to the docker-compose.aliases.yml file
#    $1 - Directory for Larakit Home
#    $2 - New hostname to add
#
addAlias() {
    [ $# -ne 2 ] && return 1

    ymlFile="${1}/configs/docker-compose.aliases.yml"
    NEWHOST="${2}"

    [ ! -f "${ymlFile}" ] && {
        resetAliases "${1}"
    }

    count=$(NEWHOST="${NEWHOST}" yq '.services.nginx.networks.backend.aliases[] | select(. == strenv(NEWHOST))' "${ymlFile}" | wc -l)
    [ $count -gt 0 ] && return 0

    NEWHOST="${NEWHOST}" yq --exit-status -i '.services.nginx.networks.backend.aliases += strenv(NEWHOST)' "${ymlFile}"
}

#
# removeAlias - Removes a hostname alias from the docker-compose.aliases.yml file
#    $1 - Directory for Larakit Home
#    $2 - New hostname to add
#
removeAlias() {
    [ $# -ne 2 ] && return 1

    ymlFile="${1}/configs/docker-compose.aliases.yml"
    HOST="${2}"

    count=$(yq '.services.nginx.networks.backend.aliases[]' "${ymlFile}" | wc -l)
    [ $count -eq 0 ] && return 0

    HOST="${HOST}" yq --exit-status -i 'del(.services.nginx.networks.backend.aliases[] | select(. == strenv(HOST)))' "${ymlFile}"
}
