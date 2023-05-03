#!/bin/bash

ORGANIZATION=$ORGANIZATION
REPO_NAME=$REPO_NAME
ACCESS_TOKEN=$ACCESS_TOKEN
RUNNER_NAME=$RUNNER_NAME
LABELS=$LABELS

REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/repos/${ORGANIZATION}/${REPO_NAME}/actions/runners/registration-token | jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh \
    --url "https://github.com/${ORGANIZATION}/${REPO_NAME}" \
    --token ${REG_TOKEN} \
    --name "${RUNNER_NAME}" \
    --labels "${LABELS}" \
    --unattended

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
