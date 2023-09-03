#!/bin/env bash

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

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"

apiURL=$(echo https://api.github.com/repos/$GH_OWNER/$GH_REPOSITORY/actions/runners/registration-token | tr -d '\r')

REG_TOKEN=$(curl -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GH_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "${apiURL}" | jq .token --raw-output)

echo $REG_TOKEN

cd /workspaces/nvidia_cuda/actions-runner-linux

./config.sh --unattended --url https://github.com/${GH_OWNER}/${GH_REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME}

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
