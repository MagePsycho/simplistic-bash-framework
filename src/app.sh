#!/usr/bin/env bash

#
# Script to ...
#
# @author   Raj KB <magepsycho@gmail.com>
# @website  https://www.magepsycho.com
# @version  1.0.0

# Exit on error. Append "|| true" if you expect an error.
#set -o errexit
# Exit on error inside any functions or subshells.
#set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
#set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
#set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

################################################################################
# CORE FUNCTIONS - Do not edit
################################################################################
#
# VARIABLES
#
_bold=$(tput bold)
_italic="\e[3m"
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_black=$(tput setaf 0)
_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)
_white=$(tput setaf 7)

#
# HEADERS & LOGGING
#
function _debug()
{
    if [[ "$DEBUG" -eq 1 ]]; then
        "$@"
    fi
}

function _header()
{
    printf '\n%s%s==========  %s  ==========%s\n' "$_bold" "$_purple" "$@" "$_reset"
}

function _arrow()
{
    printf '➜ %s\n' "$@"
}

function _success()
{
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _warning()
{
    printf '%s➜ %s%s\n' "$_tan" "$@" "$_reset"
}

function _underline()
{
    printf '%s%s%s%s\n' "$_underline" "$_bold" "$@" "$_reset"
}

function _bold()
{
    printf '%s%s%s\n' "$_bold" "$@" "$_reset"
}

function _note()
{
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

function _die()
{
    _error "$@"
    exit 1
}

function _safeExit()
{
    exit 0
}

#
# UTILITY HELPER
#
function _seekValue()
{
    local _msg="${_green}$1${_reset}"
    local _readDefaultValue="$2"
    READVALUE=
    if [[ "${_readDefaultValue}" ]]; then
        _msg="${_msg} ${_white}[${_reset}${_green}${_readDefaultValue}${_reset}${_white}]${_reset}"
    else
        _msg="${_msg} ${_white}[${_reset} ${_white}]${_reset}"
    fi

    _msg="${_msg}: "
    printf "%s\n➜ " "$_msg"
    read READVALUE

    # Inline input
    #_msg="${_msg}: "
    #read -r -p "$_msg" READVALUE

    if [[ $READVALUE = [Nn] ]]; then
        READVALUE=''
        return
    fi
    if [[ -z "${READVALUE}" ]] && [[ "${_readDefaultValue}" ]]; then
        READVALUE=${_readDefaultValue}
    fi
}

function _seekConfirmation()
{
    read -r -p "${_bold}${1:-Are you sure? [y/N]}${_reset} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            retval=0
            ;;
        *)
            retval=1
            ;;
    esac
    return $retval
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed()
{
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

function _typeExists()
{
    if type "$1" >/dev/null; then
        return 0
    fi
    return 1
}

function _isOs()
{
    if [[ "${OSTYPE}" == $1* ]]; then
      return 0
    fi
    return 1
}

function _isOsDebian()
{
    [[ -f /etc/debian_version ]]
}

function _checkRootUser()
{
    #if [ "$(id -u)" != "0" ]; then
    if [[ "$(whoami)" != 'root' ]]; then
        echo "You have no permission to run $0 as non-root user. Use sudo"
        exit 1;
    fi
}

function _semVerToInt() {
  local _semVer
  _semVer="${1:?No version number supplied}"
  _semVer="${_semVer//[^0-9.]/}"
  # shellcheck disable=SC2086
  set -- ${_semVer//./ }
  printf -- '%d%02d%02d' "${1}" "${2:-0}" "${3:-0}"
}

function _selfUpdate()
{
    local _tmpFile _newVersion
    _tmpFile=$(mktemp -p "" "XXXXX.sh")
    curl -s -L "$SCRIPT_URL" > "$_tmpFile" || _die "Couldn't download the file"
    _newVersion=$(awk -F'[="]' '/^VERSION=/{print $3}' "$_tmpFile")
    if [[ "$(_semVerToInt $VERSION)" < "$(_semVerToInt $_newVersion)" ]]; then
        printf "Updating script \e[31;1m%s\e[0m -> \e[32;1m%s\e[0m\n" "$VERSION" "$_newVersion"
        printf "(Run command: %s --version to check the version)" "$(basename "$0")"
        mv -v "$_tmpFile" "$ABS_SCRIPT_PATH" || _die "Unable to update the script"
        # rm "$_tmpFile" || _die "Unable to clean the temp file: $_tmpFile"
        # @todo make use of trap
        # trap "rm -f $_tmpFile" EXIT
    else
         _arrow "Already the latest version."
    fi
    exit 1
}

function _printPoweredBy()
{
    local _mpAscii
    _mpAscii='
   __  ___              ___               __
  /  |/  /__ ____ ____ / _ \___ __ ______/ /  ___
 / /|_/ / _ `/ _ `/ -_) ___(_-</ // / __/ _ \/ _ \
/_/  /_/\_,_/\_, /\__/_/  /___/\_, /\__/_//_/\___/
            /___/             /___/
'
    cat <<EOF
${_green}
Powered By:
$_mpAscii

 >> Store: ${_reset}${_underline}${_blue}https://www.magepsycho.com${_reset}${_reset}${_green}
 >> Blog:  ${_reset}${_underline}${_blue}https://blog.magepsycho.com${_reset}${_reset}${_green}

################################################################
${_reset}
EOF
}

################################################################################
# SCRIPT FUNCTIONS
################################################################################
function _printVersion()
{
    echo "Version $VERSION"
}

function _printVersionAndExit()
{
    _printVersion
    exit 1
}

function _printUsage()
{
    cat <<EOF
$(basename "$0") [OPTION]...

Script to ...
Version $VERSION

    Options:
        -d,     --debug            Enable the debug mode (set -x)
        -v,     --version          Output version information and exit
        -u,     --update           Self-update the script from Git repository
                --self-update      Self-update the script from Git repository

    Examples:
        $(basename "$0") [--debug] [--version] [--self-update] [--help]
EOF
    _printPoweredBy
    exit 1
}

function checkCmdDependencies()
{
    # Add dependencies here...
    local _dependencies=()
    local _depMissing
    local _depCounter=0
    for dependency in "${_dependencies[@]}"; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            _depCounter=$(( _depCounter + 1 ))
            _depMissing="${_depMissing} ${dependency}"
        fi
    done
    if [[ "${_depCounter}" -gt 0 ]]; then
      _die "Could not find the following dependencies:${_depMissing}"
    fi
}

function processArgs()
{
    # Parse Arguments
    for arg in "$@"
    do
        case $arg in
            --debug)
                DEBUG=1
                set -o xtrace
            ;;
            -v|--version)
                _printVersionAndExit
            ;;
            -h|--help)
                _printUsage
            ;;
            -u|--update|--self-update)
                _selfUpdate
            ;;
            *)
                #_printUsage
            ;;
        esac
    done

    validateArgs
    sanitizeArgs
}

function initDefaultArgs()
{
    INSTALL_DIR=$(pwd)
}

function loadConfigValues()
{
    # Load config if exists in home(~/)
    if [[ -f "${HOME}/${CONFIG_FILE}" ]]; then
        source "${HOME}/${CONFIG_FILE}"
    fi

    # Load config if exists in project (./)
    if [[ -f "${INSTALL_DIR}/${CONFIG_FILE}" ]]; then
        source "${INSTALL_DIR}/${CONFIG_FILE}"
    fi
}

function sanitizeArgs()
{
    # Perform parameter sanitizations here...
    :
}

function validateArgs()
{
    ERROR_COUNT=0

    # Perform validations here...
    :

    #echo "$ERROR_COUNT"
    [[ "$ERROR_COUNT" -gt 0 ]] && exit 1
}

function processMain()
{
    # Process main operation here
    :
}

function printSuccessMessage()
{
    _success "Action has been successfully performed."

    echo "################################################################"
    echo " >> ...           : ..."
    echo "################################################################"
    _printPoweredBy
}

################################################################################
# Main
################################################################################
export LC_CTYPE=C
export LANG=C

DEBUG=0
_debug set -x
VERSION="1.0.0"
CONFIG_FILE=".bash-app.conf"
SCRIPT_URL='https://raw.githubusercontent.com/MagePsycho/simplistic-bash-framework/main/src/app.sh'
SCRIPT_LOCATION="${BASH_SOURCE[@]}"
ABS_SCRIPT_PATH=$(readlink -f "$SCRIPT_LOCATION")
INSTALL_DIR=

function main()
{
    checkCmdDependencies

    [[ $# -lt 1 ]] && _printUsage

    initDefaultArgs
    loadConfigValues

    processArgs "$@"

    processMain

    printSuccessMessage

    exit 0
}

main "$@"

_debug set +x
