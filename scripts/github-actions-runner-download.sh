#!/usr/bin/env bash

set -e

load_dotenv() {
    env_file="/run/secrets/mysecret"
    # Check if the .env file exists
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
        echo "Environment variables loaded from $env_file"
    else
        echo "Error: $env_file not found."
    fi
}

load_dotenv

# curl -o actions-runner-linux-x64-2.308.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.308.0/actions-runner-linux-x64-2.308.0.tar.gz
verify_signature() {
    local filePath=$1
    local sigStr=$2
    echo "${sigStr}  ${filePath}" | shasum -a 256 -c
    local status=$?
    return "${status}"
}

get_version() {
  local versionStr
  versionStr=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GH_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)
  echo "$versionStr"
}

get_sha() {
    architecture=$(dpkg --print-architecture)
    case "${architecture}" in
        amd64) architectureStr=x64 ;;
        *)
            echo "Github actions-ru nner does not support machine architecture '$architecture'. Please use an x86-64 or ARM64 machine."
            exit 1
    esac
    local shaStr=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GH_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/actions/runner/releases/latest | jq -r .body  | grep -oE "<!-- BEGIN SHA linux-$architectureStr -->([[:xdigit:]]+)<!-- END SHA linux-$architectureStr -->" | sed -E "s/<!-- BEGIN SHA linux-$architectureStr -->([[:xdigit:]]+)<!-- END SHA linux-$architectureStr -->/\1/")
    echo "$shaStr"
}

install() {
    versionStr=$(get_version)
    architecture=$(dpkg --print-architecture)

    local scriptPath="actions-runner-linux"
    local scriptZipFile="actions-runner-linux.tar.gz"
    local scriptSigStr=$(get_sha)

    case "${architecture}" in
        amd64) architectureStr=x64 ;;
        *)
            echo "Github actions-ru nner does not support machine architecture '$architecture'. Please use an x86-64 or ARM64 machine."
            exit 1
    esac
    local scriptUrl=https://github.com/actions/runner/releases/download/${versionStr}/actions-runner-linux-${architectureStr}-${versionStr#v}.tar.gz
    curl -o "$scriptZipFile" -L "$scriptUrl"

    verify_signature "$scriptZipFile" "$scriptSigStr"

    mkdir -p ./"$scriptPath"
    tar xzfv "$scriptZipFile" -C ./"$scriptPath"
    # ./"$scriptPath"/bin/installdependencies.sh
    echo "Done!"
}

install
