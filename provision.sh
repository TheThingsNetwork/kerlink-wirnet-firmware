#!/usr/bin/env bash
if ((BASH_VERSINFO[0] < 4))
then 
  printf "Your bash version '${BASH_VERSION}' is too low, please update to at least version '4.0.0' and rerun the script\n" >&2
  exit 1 
fi

set -e -o pipefail

uplinkPort=1700
downlinkPort=1700

userDir="/mnt/fsuser-1"
dotaName="dota.tar.gz"

updateAndRetryFmt="please update gateway firmware to at least version '%s' and rerun the script"

function printUsage {
    printf "Usage: $0 GATEWAY-ADDRESS STACK-ADDRESS\n" >&2
}

if [[ $# -ne 2 ]] ; then
    printf "${0} takes exactly 2 arguments, got %d\n" $# >&2
    printUsage
    exit 1
fi

if [[ -z ${1} ]]; then
    printf 'Gateway address must be set\n' >&2
    printUsage
    exit 1
fi

if [[ -z ${2} ]]; then
    printf 'Stack address must be set\n' >&2
    printUsage
    exit 1
fi


# setLorafwdKey uses ${1} to set ${2} to ${3} in Lorafwd config.
function setLorafwdKey {
    ${1} "sed -i 's/^#\?[[:space:]]*${2}[[:space:]]*=.*/${2} = ${3//\//\\/}/' '${userDir}/lorafwd/etc/lorafwd.toml'"
}

# setLorafwdKeyQuoted is like setLorafwdKey, but surrounds ${3} by quotes.
function setLorafwdKeyQuoted {
    setLorafwdKey "${1}" "${2}" "\"${3}\""
}

function sshExec {
    ${1} "sh -l -c '${2}'"
}

# firmwareVersion uses ${1} to get version and stores it in ${2}.
function firmwareVersion {
    local fsVer
    fsVer=$(sshExec "${1}" 'get_version -u' | grep 'FILESYSTEM_VER' | cut -d '=' -f 2)

    local -n ret=$2
    case "${fsVer}" in
        "2011.08-g2d24f64")
            ret="1.2"
            return 0
            ;;
        "2011.08-g5e758a0")
            ret="2.1"
            return 0
            ;;
        "2011.08-gdbb0f32")
            ret="2.2"
            return 0
            ;;
        "2011.08-g7431b51")
            ret="2.3.3"
            return 0
            ;;
        "2016.05")
            ret="3.0"
            return 0
            ;;
        "2016.05v1.5")
            ret="3.1"
            return 0
            ;;
        "2016.05v1.9")
            ret="3.2"
            return 0
            ;;
        "2016.05v1.10")
            ret="3.3"
            return 0
            ;;
        "2016.05v1.13")
            ret="3.6"
            return 0
            ;;
        *)
            printf "Unknown FILESYSTEM_VER '${fsVer}', ${updateAndRetryFmt}\n" "3.0" >&2
            return 1
    esac
}

function isUp {
    ping -q -c 1 "${gatewayAddr}" > /dev/null 
}

sshParams="-o ConnectTimeout=1"

# pushAndReboot downloads ${2}, checks that it's sha256sum matches ${3} and if it does, pushes it to root@${1}:${userDir}/dota/dota.tar.gz via `scp`, performs a reboot of ${1} via `ssh` and waits until ${1} boots up. 
function pushAndReboot {
    local gatewayAddr=${1}
    local url=${2}
    local sha256=${3}

    local tmpDir
    tmpDir="$(mktemp -d)"
    pushd "${tmpDir}" > /dev/null

    local gatewayPath="${userDir}/dota/${dotaName}"
    local localPath="${tmpDir}/${dotaName}"

    local err
    set +e

    printf "Downloading firmware from '${url}' to '${localPath}' locally...\n" >&2
    err=$(curl -fsSLJo "${dotaName}" "${url}" 2>&1)
    if [[ $? -ne 0 ]]; then
        printf "Firmware download failed:'\n" >&2
        printf "${err}\n" >&2
        set -e
        return 1
    fi

    err=$(printf "${sha256}  ${dotaName}" | sha256sum -c 2>&1)
    if [[ $? -ne 0 ]]; then
        printf "Checksum matching failed:\n" >&2
        printf "${err}\n" >&2
        set -e
        return 1
    fi
    set -e

    printf "Pushing '${localPath}' to '${gatewayPath}'...\n" >&2
    set +e
    err=$(scp ${sshParams} "${localPath}" "root@${gatewayAddr}:${gatewayPath}" 2>&1)
    if [[ $? -ne 0 ]]; then
        printf "Firmware push failed:\n" >&2
        printf "${err}\n" >&2
        set -e
        return 1
    fi
    set -e

    local sshCmd="ssh ${sshParams} root@${gatewayAddr}"

    local ans
    read -r -n 1 -p "Firmware successfully pushed, reboot gateway to start update?[y/n]" ans
    printf '\n' >&2
    if [[ ! "${ans}" = "y" ]]; then
        local updateNote="note, that unless '${gatewayPath}' is removed, a gateway reboot will trigger firmware update"

        read -r -n 1 -p "Network update aborted, remove pushed firmware ('${gatewayPath}')?[y/n]" ans
        printf '\n' >&2
        if [[ ! "${ans}" = "y" ]]; then
            printf "Please manually reboot the gateway to start update and rerun the script\n" >&2
            printf "${updateNote^}\n" >&2
            return 1
        fi

        set +e
        err=$(${sshCmd} "rm -f ${gatewayPath}" 2>&1)
        if [[ $? -ne 0 ]]; then
            printf "Firmware removal failed:\n" >&2
            printf "${err}\n" >&2
            printf "${updateNote^}\n" >&2
            set -e
            return 1
        fi
        set -e
        return 1
    fi

    set +e
    err=$(sshExec "${sshCmd}" 'reboot' 2>&1)
    if [[ $? -ne 0 ]]; then
        printf "Reboot failed:\n" >&2
        printf "${err}\n" >&2
        set -e
        return 1
    fi
    set -e

    printf "Waiting for ${gatewayAddr} to reboot..." >&2
    # Wait for shutdown
    while isUp "${gatewayAddr}"; do printf '.' >&2 && sleep 1; done
    printf "[down]" >&2
    # Wait for boot
    until isUp "${gatewayAddr}" ; do printf '.' >&2 && sleep 1; done
    printf '\n' >&2 

    popd > /dev/null
    rm -rf "${tmpDir}"

    return 0
}

function isCPFInstalled {
    local -n ret=$1
    local configPath="${userDir}/lorafwd/etc/lorafwd.toml"
    set +e
    err=$(${sshCmd} "test -f ${configPath}" 2>&1)
    if [[ $? -ne 0 ]]; then
        if [[ -n "${err}" ]]; then
            printf "Testing if '${configPath}' exists on gateway failed:\n" >&2
            printf "${err}\n" >&2
            set -e
            return 1
        fi
        set -e
        ret=0
        return 0
    fi
    set -e
    ret=1
    return 0
}

function provision {
    local gatewayAddr="${1}"
    local stackAddr="${2}"

    local sshCmd="ssh ${sshParams} root@${gatewayAddr}"

    local -i cpfInstalled
    isCPFInstalled cpfInstalled
    if [[ ${cpfInstalled} -eq 0 ]]; then
        local ans
        read -r -n 1 -p "CPF is not installed, attempt CPF '1.1.6' installation?[y/n]" ans
        printf '\n' >&2
        if [[ ! "${ans}" = "y" ]]; then
            printf "CPF installation aborted, please install CPF and rerun the script\n" >&2
            return 1
        fi

        local fwVer
        firmwareVersion "${sshCmd}" fwVer

        case "${fwVer}" in
            [0-2].* )
                printf "Gateway firmware version '${fwVer}' is too low, ${updateAndRetryFmt}\n" "3.0" >&2
                return 1
                ;;
            3.[0-5] | 3.[0-5].* )
                read -r -n 1 -p "Gateway firmware version is '${fwVer}', which is lower than '3.6' required by CPF, attempt firmware update to '3.6'?[y/n]" ans
                printf '\n' >&2
                if [[ ! "${ans}" = "y" ]]; then
                    printf "Firmware update aborted, ${updateAndRetryFmt}\n" '3.6' >&2
                    return 1
                fi

                pushAndReboot   "${gatewayAddr}" \
                                "https://github.com/TheThingsNetwork/kerlink-station-firmware/releases/download/wirnet-3.6/fwupgrade_wirmav2_wirnet_v3.6.tar.gz" \
                                "63c606af73f983fcb9122086099acf01c5498ff92a06bc76a78b6e0bcdf269ba"
                
                ssh-keygen -R "${gatewayAddr}"

                firmwareVersion "${sshCmd}" fwVer
                if [[ ! "${fwVer}" = 3.6 ]]; then
                    printf "Firmware update failed, gateway firmware version is '${fwVer}', ${updateAndRetryFmt}\n" "3.6" >&2
                    return 1
                fi

                pushAndReboot   "${gatewayAddr}" \
                                "https://github.com/TheThingsNetwork/kerlink-station-firmware/releases/download/wirnet-3.6/custo_knetd-4.12.tar.gz" \
                                "503aa5336ed5ee3b674a682dfae4f3964038b00e7380e3ee7b1505b01a9678cb"
                ;;
        esac

        pushAndReboot   "${gatewayAddr}" \
                        "https://github.com/TheThingsNetwork/kerlink-station-firmware/releases/download/cpf-1.1.6/dota_cpf_1.1.6-1.tar.gz" \
                        "df442b0dbfffe1cb878ae1471c44498454e99fc09044f08e1c51941a27e08f8c"

        isCPFInstalled cpfInstalled
        if [[ ${cpfInstalled} -eq 0 ]]; then
            printf "CPF installation failed, please install CPF and rerun the script\n" >&2
            return 1
        fi
    fi

    printf "Setting LNS address to ${stackAddr}...\n" >&2
    setLorafwdKeyQuoted "${sshCmd}" "node" "${stackAddr}"

    printf "Setting LNS uplink port to ${uplinkPort}...\n" >&2
    setLorafwdKey "${sshCmd}" "service.uplink" "${uplinkPort}"

    printf "Setting LNS downlink port to ${downlinkPort}...\n" >&2
    setLorafwdKey "${sshCmd}" "service.downlink" "${downlinkPort}"
}

provision "${1}" "${2}"
