#
# Utility function to support larakit
#

[ -n "${LARAKIT_UTILS_LOADED:-}" ] && return
LARAKIT_UTILS_LOADED=1

# backupFile - moves filePath to filePath.bak, for use before an in-place edit
#   $1 - path to file
backupFile() {
    local filePath="$1"
    local backupPath="${filePath}.bak"

    [ -f "${filePath}" ] || return 1
    mv "${filePath}" "${backupPath}"
}

# restoreBackup - moves filePath.bak back over filePath (used on a failed edit)
restoreBackup() {
    local filePath="$1"
    mv "${filePath}.bak" "${filePath}"
}

# removeBackup - discards filePath.bak after a successful edit
removeBackup() {
    local filePath="$1"
    rm -f "${filePath}.bak"
}
#
# showEnvironment - Displays the contents of the configs/environment files
#    $1 - Directory for Larakit Home
#
showEnvironment() {
    [ $# -ne 1 ] && return 1

    cat "${1}/configs/environment"
}

#
# resetEnvironment - Resets the environment to known configuration
#     $1 - Directory for Larakit home
#
resetEnvironment() {
    [ $# -ne 1 ] && return 1

    local envFile="${1}/configs/environment"
    [ -f "${envFile}" ] && { backupFile "${envFile}" || return 1; }

    {
        printf "# This file overrides the features enabled in the various Laradock containers.\n"
        printf "# So changing any value or adding values requires that the containers be rebuilt.\n"
        printf "#\n"
        printf "# The following command will remove all laradock workspace containers to force a rebuild.\n"
        printf "#\n"
        printf "# docker rmi \$(docker images laradock_workspace\* --format '{{.Repository}}:{{.Tag}}')\n"
        printf "#\n"
        printf "# NOTE:\n"
        printf "#     If PHP needs more memory in the php-fpm container, \n"
        printf "#     add LARAVEL_MEMORY_LIMIT with the value needed.\n"
        printf "#\n"
        printf "APP_CODE_PATH_HOST=\"%s\"\n" "${APP_CODE_PATH_HOST:-~/Sites}"
        printf "WORKSPACE_INSTALL_AST=false\n"
        printf "WORKSPACE_INSTALL_DOCKER_CLIENT=true\n"
        printf "WORKSPACE_INSTALL_IMAGEMAGICK=true\n"
        printf "WORKSPACE_INSTALL_LDAP=true\n"
        printf "WORKSPACE_INSTALL_PCOV=true\n"
        printf "WORKSPACE_INSTALL_SOAP=true\n"
        printf "WORKSPACE_INSTALL_SSHPASS=true\n"
        printf "WORKSPACE_INSTALL_WORKSPACE_SSH=true\n"
        printf "WORKSPACE_INSTALL_PHPREDIS=true\n"
        printf "WORKSPACE_INSTALL_PG_CLIENT=true\n"
        printf "PHP_FPM_INSTALL_AST=false\n"
        printf "PHP_FPM_INSTALL_IMAGEMAGICK=true\n"
        printf "PHP_FPM_INSTALL_LDAP=false\n"
        printf "PHP_FPM_INSTALL_PGSQL=true\n"
        printf "PHP_FPM_INSTALL_SSHPASS=true\n"
        printf "PHP_FPM_INSTALL_SOAP=true\n"
        printf "PHP_FPM_INSTALL_PHPREDIS=true\n"
        printf "POSTGRES_CLIENT_VERSION=17\n"
        printf "PHP_VERSION=%s\n" "8.5"
        printf "DEFAULT_SERVICES=\"%s\"\n" "${DEFAULT_SERVICES:-nginx redis}"
        printf "PHP_SERVICES=\"%s\"\n" "${PHP_SERVICES:-workspace php-fpm}"
    } > "${envFile}" || { restoreBackup "${envFile}"; return 1; }
}

#
# updateEnvironment - Update the PHP_VERSION value in the environment
#     $1 - Directory for Larakit home
#     $2 - New PHP version value
#
updateEnvironment() {
    [ $# -ne 2 ] && return 1

    local larakitHome="$1"
    local phpVersion="$2"

    local envFile="${larakitHome}/configs/environment"
    local bakFile="${envFile}.bak"  # Keep name in sync with the backupFile method

    backupFile "${envFile}" || return 1
    sed -e "s/PHP_VERSION=.*/PHP_VERSION=${phpVersion}/" \
        -e "/PHP_FPM_BASE_IMAGE_TAG/d" \
        -e "/PHP_FPM_INSTALL_OPCACHE/d" \
    "${bakFile}" > "${envFile}" ||{ restoreBackup "${envFile}"; return 1; }

    # PHP 7.4 requires pinning to an older base image tag; without it, the image pull fails.
    [ "${phpVersion}" = "7.4" ] && {
        echo "PHP_FPM_BASE_IMAGE_TAG_PREFIX=20250222" >> "${envFile}" || { restoreBackup "${envFile}" ; return 1; }
    }

    # New PHP releases sometimes ship with opcache install/build issues that get
    # fixed upstream later. If 8.5's build starts failing, try disabling opcache
    # install as a workaround; safe to remove once upstream fixes land.
    [ "${phpVersion}" = "8.5" ] && {
        echo "PHP_FPM_INSTALL_OPCACHE=false" >> "${envFile}"  || { restoreBackup "${envFile}"; return 1; }
    }

    removeBackup "${envFile}"
}

#
# checkDependency - Check if a system command is available
#     $1 - Command to check for
#     $2 - Message if command is not found
#
checkDependency() {
    [ $# -ne 2 ] && return 1

    local dependency=$1
    local message=$2

    command -v "${dependency}" >/dev/null 2>&1 || {
        printf "\n%s\n" "${message}"
        return 1
    }

    return 0
}

#
# loadSshKeys - Loads the user's SSH keys into the SSH agent
#
loadSshKeys() {
    local keys=$(ssh-add -l)
    [ -n "${keys}" ] && return 0

    printf "\nLoading SSH Keys for SSH Agent\n"
    local macOsVersion=$(sw_vers --productVersion)

    [ -z "${macOsVersion}" ] && return 1

    local options='-K'
    [ ${macOsVersion:0:2} -ge 12 ] && options='--apple-use-keychain'

    ssh-add $options
}
