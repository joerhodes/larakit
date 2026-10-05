#
# laradock related functions to support larakit
#

[ -n "${LARAKIT_LARADOCK_LOADED:-}" ] && return
LARAKIT_LARADOCK_LOADED=1

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${LIB_DIR}/utils.bash"

#
# resetAliases - Resets the docker-compose.aliases.yml
#    $1 - Directory for Larakit Home
#
resetAliases() {
    [ $# -ne 1 ] && return 1

    local ymlFile="${1}/configs/docker-compose.aliases.yml"

    yq --exit-status --null-input '.services.nginx.networks.backend.aliases = []'  > "${ymlFile}"
}

#
# addAlias - Adds a hostname alias to the docker-compose.aliases.yml file
#    $1 - Directory for Larakit Home
#    $2 - New hostname to add
#
addAlias() {
    [ $# -ne 2 ] && return 1
    [ -z "${2}" ] && return 1

    local ymlFile="${1}/configs/docker-compose.aliases.yml"
    local NEWHOST="${2}"

    [ ! -f "${ymlFile}" ] && {
        resetAliases "${1}"
    }

    local count=$(NEWHOST="${NEWHOST}" yq '.services.nginx.networks.backend.aliases[] | select(. == strenv(NEWHOST))' "${ymlFile}" | wc -l)
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
    [ -z "${2}" ] && return 1

    local ymlFile="${1}/configs/docker-compose.aliases.yml"
    local HOST="${2}"

    local count=$(yq '.services.nginx.networks.backend.aliases[]' "${ymlFile}" | wc -l)
    [ $count -eq 0 ] && return 0

    HOST="${HOST}" yq --exit-status -i 'del(.services.nginx.networks.backend.aliases[] | select(. == strenv(HOST)))' "${ymlFile}"
}

#
# injectIntoDockerfile - Inject a script into a Dockerfile using awk
#     $1 - Dockerfile path
#     $2 - AWK script to handle the injection
#
injectIntoDockerfile() {
    [ $# -ne 2 ] && return 1

    local dockerfilePath="$1"
    local awkScript="$2"

    [ -f "${dockerfilePath}" ] || return 1
    [ -z "${awkScript}" ] && return 1

    backupFile "${dockerfilePath}" || return 1
    local dockerfileBackup="${dockerfilePath}.bak"

    awk "${awkScript}" "${dockerfileBackup}" > "${dockerfilePath}" ||{
        restoreBackup "${dockerfilePath}"
        return 1
    }

    removeBackup "${dockerfilePath}"
}

#
# injectAptCleanup - Update a Dockerfile to refresh the APT cache and ensure current OS package list is available
#     #1 - Dockerfile path
#
injectAptCleanup() {
    [ $# -ne 1 ] && return 1

    local dockerfilePath="$1"

    [ -f "${dockerfilePath}" ] || return 1

    local script="
        BEGIN { atStart=1; }
        {
            if (atStart && (\$0 ~ /apt-get update -yqq/)) {
                print \"    apt-get clean && \\\\\";
                print \"    apt-get autoclean && \\\\\";
                print \"    rm -rf /var/lib/apt/lists && \\\\\";
                print \"    apt update && \\\\\";
                atStart=0;
            }
            print;
        }
    "

    injectIntoDockerfile "${dockerfilePath}" "${script}"
}

#
# injectSnippetFile - Update a Dockerfile with the contents of a snippet file.
#     $1 - Dockerfile path
#     $2 - Snippet file path
#
injectSnippetFile() {
    [ $# -ne 2 ] && return 1

    local dockerfilePath="${1}"
    local snippetPath="${2}"

    [ -f "${dockerfilePath}" ] || return 1
    [ -f "${snippetPath}" ] || return 1

    # make sure there is something to inject
    local snippetLength=$(wc -c < "${snippetPath}" | tr -d ' ')
    [ $snippetLength -ne 0 ] || return 0

    local script="
        BEGIN { nearEnd=0; }
        /Final Touch/ { nearEnd=1; }
        {
            if (!nearEnd || (\$0 !~ /USER root/)) {
                print;
            } else {
                print;
                print \"\";
                system(\"cat '${snippetPath}'\");
                print \"\";
            }
        }
    "

    injectIntoDockerfile "${dockerfilePath}" "${script}"
}
